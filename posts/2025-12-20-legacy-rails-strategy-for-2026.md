---
created_at: 2025-12-20 17:30:00 +0100
author: Andrzej Krzywda
tags: ['rails', 'legacy', 'refactoring', 'mutation testing']
publish: false
---

# Legacy Rails strategy for 2026 (AI trends included)

Most Rails applications eventually become legacy. Not because they're old, but because they lack tests. Whether your Rails app is 10 years old or built last month with AI-generated code, the challenge is the same: how to maintain and evolve it safely.

<!-- more -->

## What you'll learn in this post

- [What is legacy code?](#what_is_legacy_code_)
- [Rule #1: NEVER be tempted to do a rewrite](#rule__1__never_be_tempted_to_do_a_rewrite)
- [Rule #2: NEVER change existing behavior](#rule__2__never_change_existing_behavior)
- [The overall strategy](#the_overall_strategy)
- [The consequence: Test coverage that checks current behavior](#the_consequence__test_coverage_that_checks_current_behavior)
- [Rails metaprogramming makes everything riskier](#rails_metaprogramming_makes_everything_riskier)
- [Refactoring: Kent Beck, Fowler and Feathers](#refactoring__kent_beck__fowler_and_feathers)
- [Safe refactoring: Always stay on green](#safe_refactoring__always_stay_on_green)
- [AI's role: Generating test coverage](#ai__39_s_role__generating_test_coverage)
- [Mutant: Ensuring 100% coverage in scope](#mutant__ensuring_100__coverage_in_scope)
- [Rails upgrades as part of legacy work](#rails_upgrades_as_part_of_legacy_work)
- [Experimental trends worth exploring in 2026](#experimental_trends_worth_exploring_in_2026)

## What is legacy code?

Michael Feathers defines legacy code as code without tests.

Previously, code became legacy over months or years as developers left, tests were never written, and documentation disappeared.

**Now? We can create Rails legacy code in an hour with generative AI.** AI generates working code fast, but with no tests, no documentation, and no one fully understanding it.

You paste AI-generated code into your Rails app, it works, and you ship it. Congratulations, you just created legacy code.

## Rule #1: NEVER be tempted to do a rewrite

This is the golden rule. The temptation is always there: "Let's rewrite it from scratch" or "This time we'll do it right."

Don't do it.

Rewrites fail because they take longer than expected, the business logic accumulated over years gets lost, edge cases are forgotten, and the new system never reaches feature parity.

Keep the monolith and improve it incrementally.

## Rule #2: NEVER change existing behavior

Even if something looks like a bug or the code seems wrong, don't change it. What seems wrong might be a business requirement that someone depends on.

But how do you ensure new code preserves behavior when rules are implicit and scattered across a million lines of code?
This year, both at wroclove.rb and EuRuKo, [Szymon Fiedler](https://blog.arkency.com/authors/szymon-fiedler/) shared [our solution from the Lemonade project](https://clutch.co/go-to-review/deb08080-1847-4a21-af3b-1e92009311cd/365955): treat the existing system as the specification. We built a snapshot-based verifier that records Quote state and HTTP interactions from production, replays the new implementation in isolated transactions with stubbed responses, compares outcomes, and rolls back.

This let us validate thousands of real-world scenarios systematically. We rewrote a complex insurance underwriting flow in three months, discovered dozens of obsolete attributes, and achieved 100% behavioral parity — all without breaking production.

The lesson: you don't need to understand every business rule to rewrite safely. You need a reliable way to verify behavior hasn't changed.

<iframe style="width:100%; height: 400px;" src="https://www.youtube.com/embed/OnoOHE6qFX4" frameborder="0" allowfullscreen></iframe>

## The overall strategy

Here is our legacy Rails strategy at Arkency:

1. **Add new tests** - Use AI to generate integration tests. Use Mutant to verify unit test quality.
2. **Ensure with Mutant** - 100% mutation coverage in the scope you're changing.
3. **Refactor towards modularization** - Create seams around the code you're changing.

You don't need to modularize your entire application. That's overwhelming and often impossible.

You only need to modularize **the area where you're making changes right now.**

Michael Feathers calls this a "seam"—a place in the code where you can alter behavior without editing in that place. A seam is a boundary that lets you:
- Test the code in isolation
- Change implementation without touching callers
- Work on a well-defined module instead of the entire monolith

When you need to add a feature or fix a bug in a tangled 800-line controller, don't refactor the whole controller. Instead:
- Extract just the part you need to change
- Create a clear boundary around it (a module, a service object, a facade)
- Add tests for that boundary
- Make your change inside the seam
- Leave the rest of the controller alone

This is incremental modularization. Over time, you create islands of well-tested, modular code in a sea of legacy. Each seam makes the next change easier.

### Why modularization matters more than ever

AI coding assistants excel at refactoring small, well-bounded modules. They struggle with large, tangled classes.

I've proven this extensively while working on an e-commerce project. AI handled refactoring and adding features to modular code remarkably well. When each module has clear boundaries and single responsibility, AI can understand the context, suggest accurate changes, and maintain consistency.

But throw AI at a 500-line controller with mixed concerns? It hallucinates. It breaks things. It misses edge cases.

This means modularization isn't just good practice anymore—it's a force multiplier for AI-assisted development. The return on investment for breaking up your monolith just increased significantly.

Your legacy Rails app will benefit twice: once from better architecture, and again from AI being able to actually help you maintain and extend it.

## The consequence: Test coverage that checks current behavior

If we never change behavior, we need tests that precisely verify what the current behavior actually is, not what we think it should be.

```ruby
# Bad: Testing what we think it should do
def test_calculates_discount_correctly
  order = Order.new(subtotal: 100.00, discount_rate: 0.15)
  assert_equal(85.00, order.total)
end

# Good: Testing what it actually does
def test_calculates_total_with_current_rounding
  order = Order.new(subtotal: 100.00, discount_rate: 0.15)
  # Current behavior: rounds incorrectly to 2 decimals before calculation
  # Should be 85.00, but current implementation gives 84.99
  assert_equal(84.99, order.total)
end
```

The second test documents the actual behavior, even if it seems wrong.

### Rails metaprogramming makes everything riskier

Rails codebases are special. Metaprogramming is everywhere—in Rails itself, in gems, in your application code. Methods are defined dynamically. Callbacks are registered at runtime. Gems monkey-patch core classes.

This means you cannot be sure that renaming a method is safe. A method name might be referenced as a string somewhere. A gem might `send` that method name dynamically. A callback might use `method_missing` to intercept it.

```ruby
# This looks safe to rename
def calculate_shipping
  # ...
end

# But somewhere in a gem or initializer:
send("calculate_#{params[:type]}")  # Calls calculate_shipping when type=shipping

# Or in a callback:
after_save :calculate_shipping  # String reference
```

Unit tests won't catch these issues. Integration tests and end-to-end tests will, because they exercise the full Rails stack with all its metaprogramming magic active.

This is why integration tests are critical for legacy Rails applications.

## Refactoring: Kent Beck, Fowler and Feathers

Kent Beck and Martin Fowler defined refactoring as changing the structure of code without changing its behavior.

Michael Feathers' ["Working Effectively with Legacy Code"](https://www.amazon.com/Working-Effectively-Legacy-Michael-Feathers/dp/0131177052) teaches us to add tests before any change, creating a safety net before refactoring.

Kent Beck's ["Tidy First?"](https://www.oreilly.com/library/view/tidy-first/9781098151232/) introduces another concept: make small tidying refactorings before the actual change, cleaning up just enough to make the real change easier—not too much, just enough.

The sequence matters:

1. Write characterization tests (tests that capture current behavior)
2. Ensure all tests pass
3. Tidy first (small, safe refactorings)
4. Make the actual change
5. Ensure all tests still pass

No behavior change at any step.

```ruby
# Step 1: Characterization test
class OrderTest < Minitest::Test
  def test_calculates_total_with_current_discount_logic
    order = Order.new(items: [item1, item2], coupon: coupon)
    # Capture current behavior, whatever it is
    assert_equal(156.78, order.total)
  end
end

# Step 2: Refactor the internals
class Order
  def total
    # Extract method, rename variables, introduce value objects
    # The result must remain 156.78
    calculate_subtotal - apply_discount(discount_amount)
  end
end
```

## Safe refactoring: Always stay on green

Martin Fowler's ["Refactoring"](https://martinfowler.com/books/refactoring.html) book teaches techniques that keep tests passing throughout the process. One powerful technique: duplicate the method being changed.

Here's how it works:

```ruby
# Original method (messy, but working)
class Order
  def calculate_price
    result = 0
    items.each do |item|
      result += item.price
      if item.discount?
        result -= item.price * 0.1
      end
      if coupon_code.present?
        result -= result * 0.05
      end
    end
    result
  end
end
```

**Step 1**: Duplicate the method with a new name

```ruby
class Order
  def calculate_price
    # Keep the old implementation untouched
    result = 0
    items.each do |item|
      result += item.price
      if item.discount?
        result -= item.price * 0.1
      end
      if coupon_code.present?
        result -= result * 0.05
      end
    end
    result
  end

  def calculate_price_new
    # New, cleaner implementation
    subtotal = items.sum(&:price)
    subtotal_with_discounts = apply_item_discounts(subtotal)
    apply_coupon_discount(subtotal_with_discounts)
  end

  private

  def apply_item_discounts(subtotal)
    discount = items.select(&:discount?).sum { |item| item.price * 0.1 }
    subtotal - discount
  end

  def apply_coupon_discount(amount)
    coupon_code.present? ? amount * 0.95 : amount
  end
end
```

Tests still pass because both methods exist, so there's no risk.

**Step 2**: Add test for the new method

```ruby
def test_calculates_price_with_new_implementation
  order = Order.new(items: items, coupon_code: "SAVE5")
  # Must match the old implementation exactly
  assert_equal(order.calculate_price, order.calculate_price_new)
end
```

**Step 3**: Switch callers one by one

```ruby
class OrdersController < ApplicationController
  def show
    @total = @order.calculate_price_new  # Changed this line
  end
end
```

Tests still pass, so you can deploy, monitor, and repeat for other callers.

**Step 4**: When all callers switched, remove the old method

```ruby
class Order
  def calculate_price
    # Rename calculate_price_new to calculate_price
    subtotal = items.sum(&:price)
    subtotal_with_discounts = apply_item_discounts(subtotal)
    apply_coupon_discount(subtotal_with_discounts)
  end

  # Old method deleted
end
```

## AI's role: Generating test coverage

AI is good at generating integration tests by looking at controllers to generate request specs and analyzing service objects to generate unit tests. Use AI to build the safety net faster.

```ruby
# AI can generate tests like these efficiently
class OrdersApiTest < ActionDispatch::IntegrationTest
  def test_creates_order_with_valid_params
    post "/api/orders", params: valid_params
    assert_equal(:created, response.status)
    assert(json_response["order_id"].present?)
  end

  def test_returns_error_for_missing_product
    post "/api/orders", params: params_without_product
    assert_equal(:unprocessable_entity, response.status)
  end
end
```

AI helps you get to high coverage quickly, then you verify the quality with Mutant.

In practice, I've used Claude Code with a simple instruction: "Add tests for this class until you achieve 100% Mutant coverage." The AI runs Mutant, sees which mutations survive, adds tests to kill those mutations, and repeats until it hits 100%.

Minimal human interaction needed. The AI handles the tedious work of covering edge cases and achieving full mutation coverage. It's basically free—you get comprehensive test coverage while you work on something else.

## Mutant: Ensuring 100% coverage in scope

[Mutant](https://github.com/mbj/mutant) is our tool at Arkency for ensuring test quality in Ruby through mutation testing. We [recently partnered](https://x.com/andrzejkrzywda/status/1978074785084030981?s=20) with Mutant's creator, Markus Schirp, to bring mutation testing to more Rails teams.

**Pricing note:** Standard Mutant subscription is $90/month. Through our partnership, we can offer flexible pricing for teams. If you need enterprise pricing or want to discuss options, [contact me](mailto:andrzej@arkency.com).

Mutant works by changing your code slightly and checking if tests catch the change.

```ruby
# Your code
def apply_discount(amount)
  amount * 0.9
end

# Mutant changes it to:
def apply_discount(amount)
  amount * 0.8  # Changed 0.9 to 0.8
end

# If your tests don't fail, you have a gap
```

### Why 95% isn't good enough

Here's a real example of a mutation that slips through "good enough" coverage:

```ruby
class RefundPolicy
  def can_refund?(order)
    return false if order.shipped_at.present?
    return false if order.created_at < 30.days.ago
    true
  end
end

# Your test (seems comprehensive)
def test_can_refund_recent_unshipped_order
  order = Order.new(created_at: 1.day.ago, shipped_at: nil)
  assert(RefundPolicy.new.can_refund?(order))
end

def test_cannot_refund_shipped_order
  order = Order.new(created_at: 1.day.ago, shipped_at: Time.current)
  refute(RefundPolicy.new.can_refund?(order))
end
```

These tests pass. Code coverage shows 100%. But Mutant finds this surviving mutation:

```ruby
def can_refund?(order)
  return false if order.shipped_at.present?
  return false if order.created_at < 30.days.ago
  false  # Changed true to false - tests still pass!
end
```

Your tests never verify that recent, unshipped orders CAN be refunded when both conditions are false. In production, this mutation means no refunds are processed. Customer service gets flooded. Revenue lost.

This is why we don't accept 95%.

At Arkency, we require 100% Mutant coverage in the scope we're changing. Anything below 100% is unnecessary risk.

Run Mutant on the class you're about to refactor:

```bash
bundle exec mutant run --include lib --require your_app \
  --use minitest -- 'YourApp::Order'
```

If Mutant score is not 100%, write more tests before refactoring.

## Rails upgrades as part of legacy work

Rails upgrades are part of the strategy. [Piotr Jurewicz wrote about smooth Rails upgrades](https://blog.arkency.com/smooth-ruby-and-rails-upgrades/). Key points:

- Reduce dependencies before upgrading
- Move by each minor version
- Deploy after each step
- Monitor for issues

### Reduce gem dependencies first

Legacy Rails apps accumulate gems over years. Each gem adds complexity during upgrades. Some gems are no longer needed—Rails absorbed their functionality.

Common gems you can remove:
- **aasm** - Rails has enums since 4.1
- **activerecord-import** - Rails 6.0 added insert_all/upsert_all
- **timecop** - Rails 4.1 added ActiveSupport::Testing::TimeHelpers
- **marginalia** - Rails 7.0 includes query logging
- **attr_encrypted** - Rails 7.0 added ActiveRecord::Encryption
- **request_store** - Rails 5.2 added ActiveSupport::CurrentAttributes

Fewer dependencies = easier upgrades. Each removed gem is one less thing to maintain, update, and debug.

[Read the full list of 5 gems you no longer need with Rails](https://blog.arkency.com/5-gems-you-no-longer-need-with-rails/).

<iframe style="width:100%; height: 400px;" src="https://www.youtube.com/embed/di4Z2cc12ak?si=v4kEGN_nvpzJ8Wlj" frameborder="0" allowfullscreen></iframe>

## Experimental trends worth exploring in 2026

The AI landscape for legacy code is evolving fast. Thoughtworks published an experimental approach worth watching: [Blackbox reverse engineering with AI](https://www.thoughtworks.com/insights/blog/generative-ai/blackbox-reverse-engineering-ai-rebuild-application-without-accessing-code).

Their technique uses AI to analyze:
- **UI interactions** - Capturing user flows by recording browser sessions
- **Database traffic** - Understanding data patterns from query logs
- **Network traffic** - Analyzing API calls and responses

The idea: document behavior without reading all the code. Feed recordings to AI, get test scaffolds and behavior documentation back.

For legacy Rails applications, you could:
- Record HTTP requests and responses in production (sanitized)
- Capture database queries during key user flows
- Feed this data to AI for test generation and documentation

We haven't battle-tested this at Arkency yet, but the approach is promising. In 2026, we might see tools that make this practical for everyday legacy work.

Worth keeping an eye on.

## Need help?

If you're struggling with legacy Rails, Arkency can help. Check our [Legacy Rails Rescue service](https://arkency.com/legacy-rails-rescue/) or [contact us](https://arkency.com/hire-us/).

At Arkency, we have experience with applications of various sizes. From small monoliths to large-scale systems with extracted microservices.

