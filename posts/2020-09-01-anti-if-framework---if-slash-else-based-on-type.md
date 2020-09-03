---
title: Anti-IF framework - if/else based on type
created_at: 2020-09-03T06:59:09.318Z
author: Andrzej Krzywda
tags: []
publish: true
---

I have to admit that I'm a bit crazy when it comes to IF statements. 

I know that they're the foundation of programming. I know that it's impossible to completely eliminate them. Still, I know we can do better than if/else-driven development. 

IEDD - If/Else Driven Development

To me IEDD is all about emotions.

The fear of adding new classes.
The pain of changing the existing nested IFs code structure.
The shame of adding Yet Another IF.
The challenge of adding a new feature with a minimal number of keystrokes.
The hope of not getting caught on code review.

YAI - Yet Another IF


## My goal is to help you improve the design of the if/else based codebases. 

Yes, that probably means creating new method, extracting new object. It might be a bit OOP. If that's not your taste and you're fine with if/else then this may not be for you. 

**Here is one "framework" that I came up with:**

1. test coverage
2. transform conditions to make the if/else be based on the type
2a. use algebry and De Morgan’s laws
3. create objects per type
4. use factories to create objects
5. use polymorphism

The second point might be the most challenging in the case of a big and ugly nested if/else.

Let's look at this example:


```ruby
def update_quality
    @items.each do |item|
      if ! item.name.eql? "Aged Brie" and ! item.name.eql? "Backstage passes to a TAFKAL80ETC concert"
        if item.quality > 0
          if ! item.name.eql? "Sulfuras, Hand of Ragnaros"
            item.quality = item.quality - 1
          end
        end
      else
        if item.quality < 50
          item.quality = item.quality + 1
          if item.name.eql? "Backstage passes to a TAFKAL80ETC concert"
            if item.sell_in < 11
              if item.quality < 50
                item.quality = item.quality + 1
              end
            end
            if item.sell_in < 6
              if item.quality < 50
                item.quality = item.quality + 1
              end
            end
          end
        end
      end
      if ! item.name.eql? "Sulfuras, Hand of Ragnaros"
        item.sell_in = item.sell_in - 1
      end
      if item.sell_in < 0
        if ! item.name.eql? "Aged Brie"
          if ! item.name.eql?("Backstage passes to a TAFKAL80ETC concert")
            if item.quality > 0
              if ! item.name.eql?("Sulfuras, Hand of Ragnaros")
                item.quality = item.quality - 1
              end
            end
          else
            item.quality = item.quality - item.quality
          end
        else
          if item.quality < 50
            item.quality = item.quality + 1
          end
        end
      end
    end
  end
```


Let's just focus on what we see here. No emotions, no blaming, no asking - who did that and why.

We can see a complex nested if/else statements structure. It seems to be about products and their quality and when should they be sold.

Assuming you have a good testing coverage (I recommend mutation testing tools) you could feel safe to refactor this.

But I don't believe in refactoring without a bigger vision. This code is point A, where is your point B? What is your destination?

In the "framework" as expressed above, we're targeting a design where we have an object per each behaviour, per each type.

What can bring us one step closer to that? Refactoring the conditions so that the dominant if/else structure is all about type and only about type. Additionally, there should be no type check embedded inside.

This can be the result:


```ruby
def update_quality
    @items.each do |item|

      if generic?(item)
        item.quality = item.quality - 1 if item.quality > 0
        item.sell_in = item.sell_in - 1

        if item.sell_in < 0 && item.quality > 0
          item.quality = item.quality - 1
        end
      elsif sulfuras?(item)

      elsif concert_pass?(item)
        item.quality = item.quality + 1
        if item.sell_in < 11
          if item.quality < 50
            item.quality = item.quality + 1
          end
        end
        if item.sell_in < 6
          if item.quality < 50
            item.quality = item.quality + 1
          end
        end
        item.sell_in = item.sell_in - 1
        if item.sell_in < 0
          item.quality = item.quality - item.quality
        end
      else # aged_brie?(item)
        item.quality = item.quality + 1 if item.quality < 50
        item.sell_in = item.sell_in - 1
        if item.sell_in < 0
          if item.quality < 50
            item.quality = item.quality + 1
          end
        end
      end
    end
  end
```


The code does the same. All tests pass and I have 100% mutation coverage.

I'm claiming this as an improvement. Why? Because now it's easier to get to our destination.

```ruby
def update_quality
    @items.each do |item|

      if generic?(item)
        Generic.new(item.sell_in, item.quality).tap do |product|
          product.update
          export_to_item(product, item)
        end
      elsif sulfuras?(item)
      elsif concert_pass?(item)
        ConcertPass.new(item.sell_in, item.quality).tap do |product|
          product.update
          export_to_item(product, item)
        end
      else
        AgedBrie.new(item.sell_in, item.quality).tap do |product|
          product.update
          export_to_item(product, item)
        end
      end
    end

  end
```

```ruby
class Generic
    attr_accessor :sell_in

    def initialize(sell_in, quality)
      @sell_in = sell_in
      @quality = Quality.new(quality)
    end

    def quality
      @quality.amount
    end

    def update
      @quality.decrease
      self.sell_in = sell_in - 1
      if sell_in < 0
        @quality.decrease
      end
    end
  end
  
  class ConcertPass
    attr_accessor :sell_in

    def initialize(sell_in, quality)
      @sell_in = sell_in
      @quality = Quality.new(quality)
    end

    def quality
      @quality.amount
    end

    def update
      @quality.increase
      if sell_in < 11
        @quality.increase
      end
      if sell_in < 6
        @quality.increase
      end
      self.sell_in = sell_in - 1
      if sell_in < 0
        @quality.reset
      end
    end
  end
```

## Refactoring to this was easy.

I have extracted the classes responsible for each behaviour. They still contain if's but they're now better encapsulated. This code is still not perfect. The factory logic is screaming to us to make a factory method or a factory class. But those are optional. 

We've managed to conquer the main issue here - the nested if statements.

**If you liked this example, you will enjoy the free training on Wednesday, September 15th, 7pm CEST:
https://arkency.com/anti-ifs/ - see all the details**
