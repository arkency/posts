---
created_at: 2026-02-05 13:02:35 +0100
author: Szymon Fiedler
tags: [ruby, rails, time, timezone]
publish: true
---

# The timezone bug that hid in plain sight for months

We recently fixed a bug in a financial platform's data sync that had been silently causing inconsistencies for months. The bug was elegant in its simplicity: checking DST status for "now" when converting historical dates.

<!-- more -->

## The broken code

I found this while debugging a different sync issue — the real bug turned out to be hiding in a helper method I wasn't even looking at.

```ruby
def self.date_to_utc(value, timezone_key)
  offset = Time.now.in_time_zone(TIMEZONE_MAP.fetch(timezone_key)).formatted_offset
  Time.new(*value.to_s.split('-').map(&:to_i), 0, 0, 0, offset).utc
end
```

Looks reasonable, right? Get the timezone offset, create a `Time` object, convert to UTC.

The problem: `Time.now.in_time_zone().formatted_offset` gets the offset for **right now**, then applies it to any date being converted.

## Why this breaks

Run this in December (EST, UTC-5):

```ruby
date_to_utc(Date.new(2023, 6, 20), :eastern)
# Gets -05:00 offset, but June 20 should be EDT (-04:00)
# Result: off by one hour
```

Run the same code in June (EDT, UTC-4):

```ruby
date_to_utc(Date.new(2023, 6, 20), :eastern)
# Gets -04:00 offset, correct for June
# Result: works fine
```

Same input, different output depending on when you run it. Your tests pass in summer, fail in winter. Data syncs would occasionally miss records or pull wrong date ranges, depending on DST periods.

## The fix

```ruby
def self.date_to_utc(value, timezone_key)
  tz = ActiveSupport::TimeZone[TIMEZONE_MAP.fetch(timezone_key)]
  tz.local(value.year, value.month, value.day, 0, 0, 0).utc
end
```

`ActiveSupport::TimeZone#local` handles DST correctly for the specific date being converted. June dates always get EDT, January dates always get EST, regardless of when the code runs.

## The test that exposed it

Before touching the implementation, I wrote a test to confirm my suspicion — and it failed immediately.

```ruby
it 'produces consistent results regardless of system timezone' do
  date = Date.new(2023, 6, 20)
  expected = Time.new(2023, 6, 20, 4, 0, 0, 'UTC')

  %w[UTC Asia/Tokyo America/Los_Angeles].each do |tz|
    Time.use_zone(tz) do
      expect(described_class.date_to_utc(date, :eastern)).to eq(expected)
    end
  end
end
```

This test runs the same conversion in UTC, Tokyo, and LA timezones. The old implementation would produce different results depending on system timezone and time of year.

## Impact

We caught this before it caused visible production issues, but the potential impact for a financial data integration was significant: off-by-one-hour shifts during DST transitions could cause missed records in date-range queries and validation mismatches between systems.

## Lessons
1. Never use `Time.now` for calculations on other dates. If you need timezone info for a specific date, use that date.
2. Test with explicit timezone manipulation. Don't rely on your system's timezone matching production.
3. DST transitions are sneaky. A bug that manifests only during certain months can survive code review and testing.
4. Know your tools: [`ActiveSupport::TimeZone`](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html)

