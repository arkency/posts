---
created_at: 2025-11-11 20:07:06 +0100
author: Łukasz Reszke
tags: ['rails', 'race conditions', 'testing', 'event sourcing', 'projection']
publish: false
---

# Making race condition tests deterministic with Concurrent::CyclicBarrier and seam

During pair programming we wanted to use advisory lock to prevent race conditions during implementation of order splitting feature. 
One of the obvious question that can be ask during such session is:
"How do we know this lock is really needed?"

The answer seemed simple: Write a test that FAILS without the lock and PASSES with it.

Easier said than done.

<!-- more -->

## The code we wanted to test

The important bit of this code is the projection that could be called at almost the same time,
causing items to be transferred into two different target orders. 


```ruby
def perform(event)
when OrderSplitIntoTwo
  source_order_id = event.data[:source_order_id]
  target_order_id = event.data[:target_order_id]

  ApplicationRecord.with_advisory_lock('transfer_items', source_order_id) do
    items = projection.items_in_order(source_order_id) # calculates which items should be transferred
    transfer(items, source_order_id, target_order_id)
  end
end
```

The lock protects against this scenario: two threads read the same projection state, then both transfer the same items to
different orders. Without the lock, items can end up in multiple orders simultaneously.

But how do you prove this lock is necessary with a test?

Attempt 1: Run threads concurrently using `Concurrent::CyclicBarrier` to synchronize them

```ruby
it 'prevents duplicate transfers' do
barrier = Concurrent::CyclicBarrier.new(2)

threads = [
  Thread.new do 
    barrier.wait(1); 
    subject.perform(split_event_1) 
  end,
  Thread.new do 
    barrier.wait(1); 
    subject.perform(split_event_2) 
  end,
]

threads.each(&:join)

items_in_target_1 = order_items(target_order_1_id)
items_in_target_2 = order_items(target_order_2_id)

expect(items_in_target_1 & items_in_target_2).to be_empty
end
```

`Concurrent::CyclicBarrier` is an amazing class for race condition testing. Usually I would start with this
simple approach and usually get the result that I need. However, this test didn't fail. 
It simply didn't match the right timing for the race condition to take a place. 
Although, its not always a bad direction to do it this way. Depends on the code that is tested. 

Adding sleep statements makes it worse - slower and flaky. There's nothing more frustrating than random failures 
in CI. I didn't want to go this direction.

## The insight: We have a seam. Lets use it.

Ok. Let me explain. A concept of seam was explained by from Michael Feathers' in his famous book "Working Effectively with Legacy Code".

"A seam is a place where you can alter behavior in your program without editing in that place."

Looking at our code, the seam is the projection method:

```ruby
def projection
@projection ||= OrderItemsProjection.new
end
```

This method is our enabling point. In tests, we can replace this projection with a controlled version that synchronizes
threads - without changing production code.

## The solution: Exploit the seam to inject synchronization

Here's the key insight: the race happens when both threads READ the same projection state, then both try to WRITE
transfers. We need both threads to:

1. Read the projection
2. Wait for each other (synchronization point)
3. Then race to perform transfers

`Concurrent::CyclicBarrier` gives us exactly this synchronization primitive:

```ruby
it 'fails without advisory lock, proving it is needed' do
barrier = Concurrent::CyclicBarrier.new(2)

shared_projection = OrderItemsProjection.new
original_method = shared_projection.method(:items_in_order)

# Intercept projection reads to synchronize both threads
allow(shared_projection).to receive(:items_in_order) do |order_id|
  items = original_method.call(order_id)

  # Both threads meet here after reading
  barrier.wait(1)

  items
end

subject_1 = TransferItems.new
subject_2 = TransferItems.new

# Inject controlled projection via the seam
allow(subject_1).to receive(:projection).and_return(shared_projection)
allow(subject_2).to receive(:projection).and_return(shared_projection)

results = Concurrent::Array.new

threads = [
  Thread.new { subject_1.perform(split_event_1); results << :success_1 },
  Thread.new { subject_2.perform(split_event_2); results << :success_2 }
]

threads.each(&:join)

items_in_target_1 = order_items(target_order_1_id)
items_in_target_2 = order_items(target_order_2_id)

expect(results.size).to eq(2) # make sure both threads finished what they had to do
expect(items_in_target_1 & items_in_target_2).to be_empty # the desired business state
end
```

## One more word about tested scenario

In this specific case the race condition was related to transferring items between orders.
Calculating proper target_id and moving those items ONCE was essential.

However, there are different cases in which this pattern could be helpful. You might want to test
concurrent database writes. Then, you have to keep in mind to decorate your test with `uses_transaction`.
The `uses_transaction` method prevents wrapping specified test in transaction. Therefore, keep in mind that you have
to take care about cleanup on your own.

```ruby
uses_transaction('to prove advisory lock is needed')
it 'prevents duplicate transfers' do
barrier = Concurrent::CyclicBarrier.new(2)

threads = [
  Thread.new do 
    barrier.wait(1); 
    subject.perform(split_event_1) 
  end,
  Thread.new do 
    barrier.wait(1); 
    subject.perform(split_event_2) 
  end,
]

threads.each(&:join)

items_in_target_1 = order_items(target_order_1_id)
items_in_target_2 = order_items(target_order_2_id)

expect(items_in_target_1 & items_in_target_2).to be_empty
end
```


## How CyclicBarrier synchronizes threads

The barrier is initialized with a count of 2 (the number of threads we want to synchronize). Here's what happens:
* Thread 1 reads items that will be transferred
* Thread 1 calls `wait(1)` and blocks, waiting for the other thread
* Thread 2 reads items that will be transferred
* Thread 2 calls `wait(1)` - the barrier count is now satisfied
* Both threads are released simultaneously and proceed with identical projection state
* They race to perform transfers

This makes the race condition deterministic and reproducible.

## Why this pattern works

Without changing a single line of production code, we:

1. Found a seam - the projection method that returns a projection instance
2. Changed method implementation by stubbing it
3. Injected synchronization logic - CyclicBarrier coordination
4. Made the race deterministic - both threads guaranteed to see the same state

The production code remains clean. No test hooks, no debug flags, no conditional logic.

## The proof

Comment out the advisory lock:

```ruby
# ApplicationRecord.with_advisory_lock('transfer_items', source_order_id) do
items = projection.items_in_order(source_order_id)
transfer(items, source_order_id, target_order_id)
# end

```
Run the test:

```
Failure/Error: expect(items_in_target_1 & items_in_target_2).to be_empty
expected: []
     got: ["item_A", "item_B"]
(items appeared in both target orders - race condition detected!)
```

Perfect. The test proves the lock is necessary.

## The takeaway

Testing race conditions might force you to synchronize the code that is tested.
I don't like to modify my production code to achieve that state. Instead, I prefer to
slightly modify it to expose the race condition. CyclicBarrier is one of the ways in which
you coordinate threads to reproduce race condition.

This pattern works for any projection-based race condition. Find your seam (usually dependency injection or method
extraction), inject synchronization, and prove your concurrency protection actually works.
