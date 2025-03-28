---
created_at: 2025-03-26 14:01:00 +0100
author: Mirosław Pragłowski
tags: ['database', 'design', 'performance', 'active record']
publish: true
---

# Implementing an Inventory Module in Ruby on Rails: Handling Concurrency with Database Locks and SKIP LOCKED

When implementing an inventory module in a Ruby on Rails application, ensuring consistency in stock levels is crucial. 
If multiple users try to purchase the same item simultaneously, concurrency issues can lead to overselling.

In this post, we'll explore two approaches to handling inventory management:
* Using a simple counter with database locks to prevent race conditions.
* Improving performance using `SKIP LOCKED` for efficient inventory allocation.

<!-- more -->

## Basic Inventory Management with Row Locks

A straightforward approach to managing inventory is using database locks to prevent concurrent updates. Here's a simple implementation:

```ruby
OutOfStock = Class.new(StandardError)

class Inventory < ActiveRecord::Base
  def reserve!(quantity)
    with_lock do
      raise OutOfStock if self.available < quantity
      self.available -= quantity
      self.save!
    end
  end
end
```
Here, `with_lock` applies a row-level lock (`SELECT ... FOR UPDATE` under the hood), ensuring that only one transaction can modify the stock at a time. This prevents overselling but can cause performance bottlenecks under high concurrency due to contention on the locked rows.

### Performance Issues

If multiple transactions attempt to update the same record, they must wait for the lock to be released.
High contention can lead to deadlocks and slow performance. This approach may not scale well when handling a large volume of transactions.
It might cause reliability issues under heavy load. Imagine your system in promoted by some social media influencer with
huge number of followers... and all the them want to get limited number of the same product. 
We have had such a case in one of our projects :) 

## Optimizing with SKIP LOCKED

To improve performance, we can use `SKIP LOCKED`, which allows us to select an available inventory item without blocking other queries waiting for a lock. This technique is useful for queue-like processing where we want to allocate items efficiently.

## Improved Implementation:

```ruby
OutOfStock = Class.new(StandardError)

class Inventory < ActiveRecord::Base
  has_many :items, class_name: 'InventoryItem', foreign_key: :inventory_id

  def reserve!(quantity)
    items_to_take = self.items.where(status: 'free')
      .lock('FOR UPDATE SKIP LOCKED')
      .limit(quantity)
    raise OutOfStock if items_to_take.length < quantity
    items_to_take.update_all(status: 'reserved')
  end
end
class InventoryItem < ActiveRecord::Base
  validates :status, inclusion: {in: %w[free reserved]}
end
```

### Why This is Better:

* Avoids lock contention: Instead of blocking on a locked row, `SKIP LOCKED` simply moves to the next available row.

* Improves throughput: Transactions don’t have to wait for locks to be released.

* More scalable: Useful in high-concurrency environments where thousands of transactions are processed simultaneously.

## Performance Comparison

When using `with_lock`, transactions can get stuck waiting for the lock to be released, leading to high contention and possible timeouts in a high-traffic system. In contrast, `SKIP LOCKED` ensures that transactions immediately move to the next available row, preventing delays and improving response times. The results below shows better system performance, reduced lock wait times (no lock timeout errors), and a more efficient allocation of inventory resources:

```
Starting  LockingInventory: 1000 times trying to reserve product 928
Before    LockingInventory:         For 928, available: 100, reserved: 0
Done 1000 requests using 100 workers, with ~10 requests per worker
After     LockingInventory:         For 928, available: 0, reserved: 100
{ActiveRecord::LockWaitTimeout => 880, OutOfStock => 20}
Starting  NonLockingInventory: 1000 times trying to reserve product 2935
Before    NonLockingInventory:         For 2935, available: 100, reserved: 0
Done 1000 requests using 100 workers, with ~10 requests per worker
After     NonLockingInventory:         For 2935, available: 0, reserved: 100
{OutOfStock => 900}
                               user     system      total        real
Using LockingInventory     2.422339   0.339037   2.761376 ( 13.163827)
Using NonLockingInventory  0.362705   0.091984   0.454689 (  1.375855)
```

This test simulate the significant workload, 1000 requests trying to reserve the same product (100 available items) at the same time (using 100 workers, each handling around 10 requests). Each worker (thread) utilises its own database connection from the connection pool. The results are:

* both inventories do not allow overselling

* the non-locking inventory implementation is significantly faster (no waiting for locks)

* the locking inventory reports some out of stock reservations, but as soon as locks starts to kick in the lock timeout error is raised

The sample code is [available here](https://gist.github.com/mpraglowski/5779da7cd3881e3210800df6fe905a05).

## Drawbacks of SKIP LOCKED solution

While `SKIP LOCKED` improves concurrency and throughput, it introduces some challenges:

First: more complex inventory management. Instead of maintaining a single counter for stock levels, 
inventory must be managed at the item level, requiring the creation of individual inventory records in the necessary quantity.

No single counter for stock visibility might also be an issue. Since stock is distributed across multiple rows, 
efficiently querying the total stock count becomes more complex. This can be mitigated by asynchronously updating a summary counter. 
A background job, for example, could periodically aggregate stock levels and update a summary counter to provide accurate stock visibility.

## Conclusion

Using `with_lock` provides a safe way to manage inventory but suffers from performance issues under high load. 
By leveraging `SKIP LOCKED`, we can significantly improve concurrency and system efficiency, ensuring a smooth inventory management experience.

If you're building a high-traffic e-commerce platform or a similar system, optimising database interactions using `SKIP LOCKED` can help maintain performance while ensuring inventory integrity.
