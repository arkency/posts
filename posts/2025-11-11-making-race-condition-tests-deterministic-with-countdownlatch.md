---
created_at: 2025-11-11 20:07:06 +0100
author: Łukasz Reszke
tags: ['rails', 'race conditions', 'testing', 'event sourcing', 'projection']
publish: false
---

# Making race condition tests deterministic with CountDownLatch

During pair programming we wanted to use advisory lock to prevent race conditions during implementation of order splitting feature. 
One of the obvious question that can be ask during such session is:
"How do we know this lock is really needed?"

The answer seemed simple: Write a test that FAILS without the lock and PASSES with it.

Easier said than done.

<!-- more -->

## The code we wanted to test

```ruby
def perform(event)
when OrderSplitIntoTwo
  source_order_id = event.data[:source_order_id]
  target_order_id = event.data[:target_order_id]

  ApplicationRecord.with_advisory_lock('transfer_items', source_order_id) do
    items = projection.items_in_order(source_order_id) # calculates which items should be transferred
    transfer(items.take(2), source_order_id, target_order_id)
  end
end
```

The lock protects against this scenario: two threads read the same projection state, then both transfer the same items to
different orders. Without the lock, items can end up in multiple orders simultaneously.

But how do you prove this lock is necessary with a test?

Attempt 1: Just run threads concurrently

```ruby
it 'prevents duplicate transfers' do
threads = [
  Thread.new { subject.perform(split_event_1) },
  Thread.new { subject.perform(split_event_2) }
]
threads.each(&:join)

items_in_target_1 = order_items(target_order_1_id)
items_in_target_2 = order_items(target_order_2_id)

expect(items_in_target_1 & items_in_target_2).to be_empty
end
```

This test didn't fail. It simply didn't match the right timing for the race condition to take a place. 
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

`Concurrent::CountDownLatch` gives us exactly this synchronization primitive:

```ruby
it 'fails without advisory lock, proving it is needed' do
sync_latch = Concurrent::CountDownLatch.new(2)

shared_projection = OrderItemsProjection.new
original_method = shared_projection.method(:items_in_order)

# Intercept projection reads to synchronize both threads
allow(shared_projection).to receive(:items_in_order) do |order_id|
  items = original_method.call(order_id)

  # Both threads meet here after reading
  sync_latch.count_down
  sync_latch.wait(1)

  items
end

subject_1 = TransferItems.new
subject_2 = TransferItems.new

# Inject controlled projection via the seam
allow(subject_1).to receive(:projection).and_return(shared_projection)
allow(subject_2).to receive(:projection).and_return(shared_projection)

barrier = Concurrent::CyclicBarrier.new(2)
results = Concurrent::Array.new

threads = [
  Thread.new { barrier.wait; subject_1.perform(split_event_1); results << :success_1 },
  Thread.new { barrier.wait; subject_2.perform(split_event_2); results << :success_2 }
]

threads.each(&:join)

items_in_target_1 = order_items(target_order_1_id)
items_in_target_2 = order_items(target_order_2_id)

expect(results.size).to eq(2) # make sure both threads finished what they had to do
expect(items_in_target_1 & items_in_target_2).to be_empty # the desired business state
end
```

## How CountDownLatch synchronizes threads

The latch starts with a count of 2. Here's what happens:
* In Thread 1 we read items that will be transferred - Latch Count is 2
* `count_down` is called - Latch count drops to 1
* `wait` blocks the Thread from continuing
* When Thread 2 calls count_down, it brings the latch to 0, which simultaneously unblocks both threads. 
* They both proceed with identical projection state and race to perform transfers.

This makes the race condition deterministic and reproducible.

## Why this pattern works

Without changing a single line of production code, we:

1. Found a seam - the projection method that returns a projection instance
2. Changed method implementation by stubbing it
3. Injected synchronization logic - CountDownLatch coordination
4. Made the race deterministic - both threads guaranteed to see the same state

The production code remains clean. No test hooks, no debug flags, no conditional logic.

## The proof

Comment out the advisory lock:

```ruby
# ApplicationRecord.with_advisory_lock('transfer_items', source_order_id) do
items = projection.items_in_order(source_order_id)
transfer(items.take(2), source_order_id, target_order_id)
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
slightly modify it to expose the race condition. CountDownLatch is one of the ways in which
you coordinate threads to reproduce race condition.

This pattern works for any projection-based race condition. Find your seam (usually dependency injection or method
extraction), inject synchronization, and prove your concurrency protection actually works.
