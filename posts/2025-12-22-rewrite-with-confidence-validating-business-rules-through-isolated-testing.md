---
created_at: 2025-12-22 21:04:19 +0100
author: Szymon Fiedler
tags: [ruby, rails, legacy]
publish: true
---

# Rewrite with Confidence: Validating Business Rules Through Isolated Testing

A few months back, our team at Arkency faced a challenge that many Rails developers might recognize. We needed to implement a new flow at [Lemonade](https://www.lemonade.com) that would eventually replace a legacy process — but with three major constraints that couldn't be compromised: user experience, cost efficiency, and avoiding technical debt.

<!-- more -->

The stakes were high. Any discrepancies between systems would impact customers and potentially create legal issues in the insurance domain. We had just three months to understand, replicate, and improve a complex flow that had evolved organically over years. And we needed to break free from obsolete data structures while preserving essential business rules embedded in a codebase with over 1 million lines of code.

Traditional approaches wouldn't work. Full test coverage would take months we didn't have. What we needed was a methodology to systematically identify, isolate, and verify each business rule independently of its implementation.

We needed a way to rewrite with confidence.

## The Context: Insurtech at Scale

If you had asked me three years ago if insurtech could be exciting, I would have probably laughed. But it can be.

Lemonade is an innovative insurance company that hit $1 billion in premiums just 10 years after founding. It took other well-established insurance brands 40–60 years to reach that milestone. Even companies like Microsoft, Netflix, Salesforce, and Tesla needed more time to achieve that.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">What a thrill for <a href="https://twitter.com/Lemonade_Inc?ref_src=twsrc%5Etfw">@lemonade_inc</a> to be in the 𝘛𝘳𝘦𝘴 𝘊𝘰𝘮𝘮𝘢𝘴 Club! I’m not particularly moved by a car “with doors that open like 𝘵𝘩𝘪𝘴 👐”, but I’m definitely exhilarated by the ride so far, and can’t wait for our <a href="https://twitter.com/hashtag/Next10X?src=hash&amp;ref_src=twsrc%5Etfw">#Next10X</a>! 🙌🏻🚀🎉 <a href="https://t.co/HKpgfyFO7Y">https://t.co/HKpgfyFO7Y</a></p>&mdash; Daniel Schreiber (@daschreiber) <a href="https://twitter.com/daschreiber/status/1904512746571345965?ref_src=twsrc%5Etfw">March 25, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

When we joined Lemonade three years ago, their Director of Engineering shared a story that perfectly illustrated the stakes of our work. They once had an issue with roof coverage in one of their product lines and had to hire a legal team for a six-month sprint to fix things. The legal costs exceeded the entire IT budget.

We couldn't break things. We had to be 100% sure that the new flow provided the same outcome.

## The Architecture: A Rails Monolith Under Transformation

Lemonade used a Rails monolith as their foundation — my favorite architecture. There's no coincidence they became successful. Over the past few years, they've been transforming to a microservices architecture, with new product lines released using their internal framework. But all home and renters insurance is still handled within the Rails monolith.

Our scope was clear: implement a new quote flow for HO4 (renters insurance) in the US that would produce identical underwriting results to the legacy system.

## Understanding the Problem

### The God Model

Like many mature Rails applications, the system had a Quote model that accumulated responsibilities over time:

```ruby
class Quote < ApplicationRecord
  serialize :data
  serialize :answers
  
  enum :status,
       {
         pending: 'pending',
         stubbed: 'stubbed',
         bindable: 'bindable',
         uw_declined: 'uw_declined',
       },
       default: 'pending'
end
```

The business raised a valid point: "We don't want `pending` and `stubbed` Quotes in the system." Pending represented abandoned quotes with no value. Stubbed meant the system couldn't make a risk assessment, usually due to third-party issues. This data model pollution required filtering at different levels:

```ruby
class Quote < ApplicationRecord
  scope :not_pending, lambda do 
    where.not(status: :pending)
  end
end
```

We all have such excluding scopes in our apps — don't pretend you don't.

This was especially problematic for the Data Science team. Without filtering these quotes, their models would be far from accurate.

### The Data Complexity

The Quote model contained two serialized columns with deeply nested data. Here's just a glimpse of what we were dealing with:

```yaml
data:
  :locale:
    :region: US
    :language: en
  :client_uuid: 30a1377e-5f06-4e6f-878b-41564c2e1221
  :user_logged_in: false
  :flags:
    - :send_pdf_sample_docs
    - :tenant_pet_damage_activated
  # ... and dozens more attributes
```

The `answers` hash was even more complex, containing everything from address components to user preferences to tracking data.

### Why Traditional Approaches Failed

We initially tried static analysis to figure out which Quote attributes were necessary for the underwriting process. We quickly realized this was impossible — too many branches in the code. Imagine: every US state has its own regulations affecting insurance products. Multiply this by product editions that change over time due to legal concerns or business needs. We also share the data model and flow with home insurance.

Then we tried using `Module#prepend` to instrument Quote accessors and track which data was involved. This gave us better overview but was still overwhelming.

And we hadn't even touched the HTTP communication part — all the first-party and third-party calls required for underwriting, coverage selection, deductible calculation, and premium determination.

### What About Other Approaches?

We considered several alternatives before settling on our solution.

**Shadow traffic** was an interesting option. This technique involves routing live production traffic to both the existing backend and a new shadow backend simultaneously. The shadow backend processes requests without affecting users, while comparison mechanisms validate behavior. Tools like [nginx plugins](https://nginx.org/en/docs/http/ngx_http_mirror_module.html) or [Zalando's Skipper](https://github.com/zalando/skipper) can handle this elegantly.

However, shadow traffic came with significant drawbacks for our use case:
* Substantial infrastructure work and ongoing costs
* Potential compliance issues using production data in non-production environments
* Need to implement complex comparison mechanisms
* Difficulty avoiding side effects when dealing with stateful operations and third-party APIs

The infrastructure overhead alone would have consumed a significant portion of our three-month deadline.

## The Solution: Testing on Production

Here's where we took an unconventional approach. Instead of trying to replicate production conditions in a test environment, we decided to test directly on production — but safely.

### The Brave New Flow

The key architectural change was simple but profound: instead of creating a Quote at the beginning of the flow and updating it on every step, we'd receive all the data gathered by the frontend client and perform our task at the very end.

This meant:
- No more `pending` quotes
- No more `stubbed` quotes  
- Only `bindable` or `uw_declined` as final states
- Much cleaner data model

### Implementing the Sampling Mechanism

We built a sampling system using Ruby's `prepend` to non-invasively inject our verification code:

```ruby
class RentersUsQuoteSampler
  module AroundFilter
    def run_prepare_for_preview(quote)
      if RentersUsQuoteSampler.conditions_met_for_sampling?(quote)
        RentersUsQuoteSampler.sampled(quote) { super }
      else
        super
      end
    end
  end
end
```

This allowed us to intercept the underwriting process for specific quotes without affecting the normal flow.

### What We Sampled

For each qualifying quote, we captured:

1. **Quote state before underwriting** - The raw quote data as it entered the process
2. **Quote state after underwriting** - The complete quote with pricing, deductible, and coverage
3. **Address data** - All location information
4. **HTTP interactions** - Every external API call made during the process

```ruby
class RentersUsQuoteSampler  
  def self.sampled(quote)
    address = Address.lemonade.find_by(quote_id: quote.id)
    before_quote = to_sample(quote)

    TyphoeusRecorder.start_recording
    begin
      result = yield
      typhoeus_requests = TyphoeusRecorder.recorded_requests
    ensure
      TyphoeusRecorder.stop_recording
    end

    Record.create!(
      quote_before: before_quote,
      address: to_sample(address),
      quote_after: to_sample(quote),
      typhoeus_requests: typhoeus_requests,
    )
    result
  rescue => e
    ::Sentry.capture_exception(e, hint: { ignore_exclusions: true })
  end
end
```

### Recording HTTP Interactions

Lemonade used Typhoeus as the HTTP client for microservices and third-party communication. Fortunately, Typhoeus provides a callback system:

```ruby
class RentersUsQuoteSampler  
  module TyphoeusRecorder
    RECORD_PROC = ->(response) do
      @@typhoeus_requests.merge!(serialize_request(response))
    end

    def self.start_recording
      @@typhoeus_requests = {}
      ::Typhoeus.on_complete(&RECORD_PROC)
    end

    def self.stop_recording
      ::Typhoeus.on_complete.delete(RECORD_PROC)
      @@typhoeus_requests = nil
    end
    
    def self.serialize_request(response)
      {
        {
          base_url: response.request.base_url,
          params: response.request.options[:params],
          method: response.request.options[:method],
          body: response.request.options[:body],
        } => { 
          code: response.code,
          body: response.body,
        },
      }
    end
  end
end
```

This gave us perfect request-response pairs to use as stubs during verification.

## The Verification Process

Sampling and verification were separate processes, allowing us to:
- Collect samples from production continuously
- Run verification asynchronously
- Re-run verification after code fixes
- Iterate until we achieved parity

### Leaving No Trace

The critical requirement was not polluting production with duplicate quotes:

```ruby
class RentersUsQuoteDtoVerifier
  def with_rollback
    ActiveRecord::Base.transaction do
      yield
      raise ActiveRecord::Rollback
    end
  end
end
```

But there was a gotcha: background jobs. We needed to ensure no jobs were scheduled within our rolled-back transaction.

### After Commit Handling

This feature became built-in to Rails 7.2, but we weren't there yet. Fortunately, one of the best things about working at Arkency is that if you need a solution, there's a good chance we've solved it before — like in [RailsEventStore](https://github.com/RailsEventStore/rails_event_store/blob/92e0f920f7c11707ffe1c06f3e855827221fb77c/rails_event_store/lib/rails_event_store/after_commit_async_dispatcher.rb#L4) or [our blog posts from 9 years before Rails introduced it](https://blog.arkency.com/2015/10/run-it-in-background-job-after-commit/).

```ruby
module AfterCommitRunner
  def self.call(&schedule_proc)
    transaction = ActiveRecord::Base.connection.current_transaction

    if transaction.joinable?
      transaction.add_record(async_record(schedule_proc))
    else
      schedule_proc.call
    end
  end

  def self.async_record(schedule_proc)
    AsyncRecord.new(schedule_proc)
  end

  class AsyncRecord
    def initialize(schedule_proc)
      @schedule_proc = schedule_proc
    end

    def committed!(*) = schedule_proc.call
    def rolledback!(*) = nil
    def before_committed!() = nil

    attr_reader :schedule_proc
  end
end
```

This allowed us to queue jobs only after successful commits, not within rolled-back transactions.

### HTTP Stubbing Strategy

We needed to stub all external HTTP calls to avoid:
- Mutating state in other microservices
- Making expensive third-party API calls
- Affecting external systems (like credit scores)
- Rate limiting issues

First, we blocked all Typhoeus requests:

```ruby
def with_http_stubs_mechanism
  callback = ->(req) do
    req.block_connection = true
    req
  end
  Typhoeus.before.prepend(callback)
  yield
ensure
  Typhoeus.before.delete(callback)
  Typhoeus::Expectation.clear
end
```

Then we used our recorded requests as stubs:

```ruby
def with_common_http_stubs
  http_stubs.each do |req, res|
    Typhoeus
      .stub(req[:base_url], req[:params])
      .and_return(Typhoeus::Response.new(**res))
  end
  
  yield
end
```

### Handling Edge Cases

Some libraries used `net/http` directly, which wasn't easy to stub. For AWS S3 clients, we used Ruby's metaprogramming capabilities:

```ruby
def with_no_verisk_persistence
  old_const = Storage::IamS3Resource
  no_writes_iam_resource = Class.new do
    extend old_const

    def self.put(*) = 'http://example.org'
    def self.presigned_url(*) = 'http://example.org'
  end
  Storage.send(:remove_const, :IamS3Resource)
  Storage.const_set(:IamS3Resource, no_writes_iam_resource)
  yield
ensure
  Storage.send(:remove_const, :IamS3Resource)
  Storage.const_set(:IamS3Resource, old_const)
end
```

This allowed us to override behavior while still downloading resources from S3 (assuming GETs don't mutate state).

### The Complete Verification Flow

Putting it all together:

```ruby
def sample_remake
  sample_remake = nil

  with_rollback do
    with_http_stubs_mechanism do
      with_common_http_stubs do
        with_bouncer_stubs do
          with_census_block_stubs do
            with_no_segment do
              with_no_verisk_persistence do
                with_no_promises do
                  with_no_impressions do
                    remake = mk_quote
                    Chat::Quote.run_prepare_for_preview(remake)
                    sample_remake = RentersUsQuoteSampler.to_sample(remake)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
  
  sample_remake
end
```

Yes, the nesting looks deep, but each wrapper handled a specific concern. We could experiment safely as many times as needed.

### Comparing Results

We used the `super_diff` gem to identify discrepancies:

```ruby
def verify 
  tuple_to_compare.reduce(:==)
end

def diff
  SuperDiff.diff(*tuple_to_compare)
end
```

Example output when things didn't match:

```ruby
{
-  "status" => "bindable",
+  "status" => "pending",
   "product" => "iso",
   "form" => "ho4",
-  "edition" => "E240716",
+  "edition" => "E240618",
   # ...
}
```

This worked beautifully for nested structures, which was crucial for our case.

## The Results

After implementing this methodology, we achieved:

1. **Fewer questions asked** - Simplified the customer flow
2. **Cleaner data model** - Eliminated obsolete quote states
3. **Identical outcomes** - 100% parity with legacy underwriting
4. **Confidence to ship** - No surprises in production

The project leader shared across the organization:

> "This is part of one of the best releases I have ever experienced."

There was even a panic moment when he reached out on a Friday evening before both our ski vacations — but it was just to thank the team for the exceptional release quality.

## Key Takeaways

This approach worked because we:

1. **Separated collection from verification** — Continuous sampling with async verification
2. **Treated production as the specification** — No need to replicate complex environments
3. **Isolated tests from side effects** — Transaction rollbacks and HTTP stubbing
4. **Iterated until perfect** — Fixed issues and re-verified until parity achieved
5. **Leveraged Ruby's strengths** — Metaprogramming made complex stubbing manageable

The methodology is applicable beyond insurance or quote systems. Anytime you need to rewrite complex business logic while ensuring behavioral parity, consider:

- Can you sample real production behavior?
- Can you replay it safely in isolation?
- Can you compare results programmatically?
- Can you iterate until perfect?

When refactoring mission-critical business logic, traditional testing might not be enough. Sometimes the best test suite is production itself — as long as you can verify without breaking things.

## Prefer watching?

This post is based on author’s conference talk delivered at [wroclove.rb 2025 in Wrocław, Poland](https://2025.wrocloverb.com) and [EuRuKo 2025 in Viana do Castelo, Portugal](2025.euruko.org).

<iframe width="560" height="315" src="https://www.youtube.com/embed/OnoOHE6qFX4?si=busQb8WPl1j-CCUz" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

---

*This methodology emerged from real-world necessity at [Lemonade](https://clutch.co/go-to-review/deb08080-1847-4a21-af3b-1e92009311cd/365955). We're grateful for their trust in letting us solve this challenge and share the solution with the Ruby community.*

