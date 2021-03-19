---
created_at: 2021-03-19 17:37:56 +0100
author: Szymon Fiedler
tags: ["activeadmin", "rails", "legacy", "ddd", "read model"]
publish: true
---

# Use ActiveAdmin like a boss

ActiveAdmin is widely used administration framework in Rails applications. This post explains how to hook more sophiscicated domain logic into it.

<!-- more -->

An ActiveAdmin resource can be generated to perform CRUD operations on the application's models. However, there are scenarios where:

- business logic is no longer a part of the model and it lives somewhere else, eg. service, aggregate
- it is not desired to remove the data, but instead set a status, eg. "Cancelled"
- admin need super powers which are not living in the ActiveRecord model (like in the first item)

Taking this into account, classic CRUD approach is simply not enough. Below, there's a short example extracted from sample [Order management app](https://github.com/RailsEventStore/cqrs-es-sample-with-res)

```ruby
ActiveAdmin.register Order do
  controller { actions :show, :index, :cancel }

  member_action :cancel, method: %i[post] do
    command_bus.(
      Ordering::CancelOrder.new(order_id: Order.find(params[:id]).uid),
    )
    redirect_to admin_orders_path, notice: 'Order cancelled!'
  end

  action_item :cancel,
              only: %i[show],
              if: proc { 'Submitted' == resource.state } do
    link_to 'Cancel order',
            cancel_admin_order_path,
            method: :post,
            class: 'button',
            data: {
              confirm: 'Do you really want to hurt me?',
            }
  end
end
```

What's happening here:

- `controller { actions :show, :index, :cancel }` — only certain actions are allowed, no _destroy_, _create_ nor _update_
- custom `cancel` action is defined, which invokes `Ordering::CancelOrder.new` command. In effect, we call a [`cancel` method on `Order` aggregate](https://github.com/RailsEventStore/cqrs-es-sample-with-res/blob/af0c89831328f6f0a707797e2e660e538899585b/ordering/lib/ordering/order.rb#L44-L48) and read model [is being updated accordingly](https://github.com/RailsEventStore/cqrs-es-sample-with-res/blob/af0c89831328f6f0a707797e2e660e538899585b/app/read_models/orders/on_order_cancelled.rb#L1-L9)
- to display a button to perform action `action_item` block is used; the button is rendered only when operation is available to perform — not all the _Orders_ are cancellable. [It's also a good pattern to not present to user operations which can't be performed](https://stories.justinewin.com/disabled-buttons-dont-have-to-suck-10da0bb6d37e)

One can say — _but it's just a status column update_. Nope, that tiny column update is a result of business operation taking specific constraints into account. Moreover, data remain consistent because there's no longer a possibility to "just" update the column or many of them.
That updated column is a representation in read model which is <q>not meant to deliver domain behaviour, only data for display</q> — _Implementing Domain-Driven Design, Vaughn Vernon_.

I find this useful, especially if one wants to avoid multiple checks and conditions (eg. IF statements) in code to determine whether certain actor (admin in our scenario) is capable of doing certain operation.
