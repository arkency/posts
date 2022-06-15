---
created_at: 2022-06-08 21:16:18 +0200
author: Łukasz Reszke
tags: ['mutant', 'value object', 'eql? vs equal? vs ==', 'ddd', 'ruby' ]
publish: false
---

# Which one to use? eql? vs equal? vs == ? Mutant Driven Development of Country Value Object

Recently after introducing a new value object to a project I ran mutant to verify my test coverage quite early. It turned out that I missed a few places when it comes to tests, but also technical design of production code. In this post, I'll show you my development process for the Country Value Object.

When you think about Value Object it's important to get the difference between `eql?`, `equal?` and `==` operators. Those differences were quite important in the class design process.

## What is Value Object?
So long story short, a value object is an object whose equality is based on its value, not its identity.

## Code sample

This is a simple country object. Its purpose is to protect the application from using countries that are not supported.

```ruby
  class Country
    SUPPORTED_COUNTRIES = [PL = "PL", NO = "NO"].freeze

    private attr_reader :iso_code

    def initialize(iso_code)
      raise unless SUPPORTED_COUNTRIES.include?(iso_code.to_s.upcase)
      @iso_code = iso_code
    end

    def to_s
      iso_code.to_s
    end

    def ==(other)
      other.class === self && other.hash == hash
    end

    alias eql? ==

    def hash
      iso_code.hash
    end
  end
```

Besides that, as you can see in the tests below, no matter how we use the country object, we want it to always get the proper value of the country's iso code.

```ruby
  class CountryTest < TestCase
    cover Country

    def test_returns_no
      assert_equal "NO", Country.new("NO").to_s
      assert_equal "NO", Country.new(:NO).to_s
      assert_equal "NO", Country.new(Country::NO).to_s
    end

    def test_returns_pl
      assert_equal "PL", Country.new("PL").to_s
      assert_equal "PL", Country.new(:PL).to_s
      assert_equal "PL", Country.new(Country::PL).to_s
    end

    def test_equality
      assert Country.new(Country::PL).eql? Country.new(Country::PL)
      assert Country.new(Country::NO).eql? Country.new(Country::NO)

      assert Country.new(Country::PL) == Country.new(Country::PL)
      assert Country.new(Country::NO) == Country.new(Country::NO)
    end

    def test_only_supported_countries_allowed
      assert_raises { Country.new("NL") }
      assert_raises { Country.new("ger") }
      assert_nothing_raised { Country.new("pl") }
    end
  end
```

This is our starting point. Looks ok, doesn't it? Before finishing the job of designing this class, let's run mutant tests and verify the results.


# Let's kill some mutants
We'll focus on increasing the mutant coverage of equality-related methods. 

Let's look at result of first `bundle exec mutant run`

```ruby
 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self || other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class && other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  self.class === self && other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  self && other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && other.hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && self.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && other.hash.eql?(hash)
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && other.hash.equal?(hash)
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && hash
 end

 def hash
-  iso_code.hash
 end

 def hash
-  iso_code.hash
+  nil
 end

 def hash
-  iso_code.hash
+  iso_code
 end
 ```
The `-` sign symbolizes removed line of code. The `+` sign symbolizes line of code introduced by mutant. So even though there are tests that look quite good, the result is poor. This causes false sense of security. Let's increase that coverage!

_This is a good point in time to copy the code and try to increase it's mutant coverage_ 😉

## Heal the code
At a first glance it looks like our test suite is not complete. Let's try to increase mutant coverage by adding missing tests.

```ruby
    def test_values_equality
      refute Country.new(Country::PL) == Country.new(Country::NO)
      refute Country.new("PL") == "PL"
    end
```

So in this test we expect that

* `Country` objects of two different countries are not equal
* Value object is not the same thing as simple string

All right so this test removes most of the problems. Actually, there are 3 more issues left:

```ruby
 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && other.hash.equal?(hash)
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && other.hash.eql?(hash)
 end

 def hash
-  iso_code.hash
+  iso_code
 end
```

## Making hash method more robust
Inspired by Robert in [this blog post](https://blog.arkency.com/relative-testing-vs-absolute-testing/), let's modify the hash method.

```ruby
 def hash
    iso_code.hash ^ BIG_VALUE
 end

 private

 BIG_VALUE = 0b111111100100000010010010110011101011000101010111001101100110000
 private_constant :BIG_VALUE
```

And run mutant again

```ruby
 def ==(other)
-  other.class === self && other.hash == hash
+  other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class && other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  self.class === self && other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  self && other.hash == hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && other.hash.eql?(hash)
 end

 def hash
-  iso_code.hash ^ BIG_VALUE
+  iso_code.hash
 end
```

Well... not good, not bad. Different mutants were injected in the code. Still, there are some survivors.

Let's focus on the `==` method mutations. What's going on here?
```ruby
  def ==(other)
    other.class === self && other.hash == hash
  end
```
Seems like we miss the test to make sure that modification of this code (for example changing it to one of the mutant's suggestions) will cause the test to fail. We're designing Value Objects. Two Value Objects are equal when:
- they have the same hash values, we have such a test
- when their classes are the same

We miss the latter one. Let's fix this by adding the test
```ruby
  def test_equality_between_two_different_types_of_objects
    foo =
      Struct.new(:iso_code) do
        def hash
          iso_code.hash ^ 0b111111100100000010010010110011101011000101010111001101100110000
        end
      end
    assert_not_equal Country.new(Country::PL), foo.new("PL")
    end
```

After re-running mutant, there are two more issues to deal with:
```ruby
 def hash
-  iso_code.hash ^ BIG_VALUE
+  iso_code.hash
 end

 def ==(other)
-  other.class === self && other.hash == hash
+  other.class === self && other.hash.eql?(hash)
 end
```

## Let's deal with the hash survivor

The one of two survivors is killed by changing `==` to `eql?`
```ruby
    def ==(other)
      other.class === self && other.hash.eql?(hash)
    end
```

But... why?

# The difference between `==` and `eql?`
The `==` operator compares two objects based on their value. For example
```ruby
1 == 1 # true
1 == 1.0 # true
1.hash == 1.0.hash #false
```

For simple class:

```ruby
    class Klass
      attr_accessor :code

      def initialize(code)
        @code = code
      end
    end
```
The test fails
```ruby
    def test_klass
      assert Klass.new("a") == Klass.new("a")
    end
```

The `eql?` method compares two objects based on their hash.

```ruby
2.eql? 2 # true
2.eql? 2.0 # false
```

Couldn't we just do it like this...?
```ruby
    def test_klass
      assert Klass.new("a").eql? Klass.new("a")
    end
```
Nope.

Two objects with the same value. But! The hash is different. When the `hash` method is not overwritten, it's based on the object's identity. So it's something that we don't want when we think about Value Objects.

## So why did mutant complain about the `==` operator?
Mutant complained about the `==` operator because it 'knew' that underneath it calls `.inspect` on the `hash`, which leads to value comparison and not into hash comparison, which is important for us when we think about Value Objects.

# Kill the last one
Let's deal with the last one.
```ruby
 def hash
-  iso_code.hash ^ BIG_VALUE
+  iso_code.hash
 end
```
You probably know already, but I'll just write it for sake of completeness. We're missing some test cases. Let's add one last test for the hash method, which will actually document why we used the `BIG VALUE` from Robert's post.

```ruby
  def test_hash
    refute Country.new(Country::PL).hash == "PL".hash
  end
```

# And boom!
Here we go. 100% mutant coverage.
```
Mutations:       76
Results:         76
Kills:           76
Alive:           0
Timeouts:        0
Runtime:         22.91s
Killtime:        19.67s
Overhead:        16.51%
Mutations/s:     3.32
Coverage:        100.00%
```

# What about equal?
Why isn't the `equal?` method also aliased to the `==` operator? The reason is the fact that the `equal?` method checks the identity of the object.
Let's look at an example.

```ruby
    def test_equality
      first = "a"
      second = "a"

      assert first.equal? second 
    end
```
The test fails. Check the identity of those two objects, they're different.
`first.__id__ != second.__id__`


# Final Value Object
```ruby
class Country
  SUPPORTED_COUNTRIES = [PL = "PL", NO = "NO"].freeze

  private attr_reader :iso_code

  def initialize(iso_code)
    raise unless SUPPORTED_COUNTRIES.include?(iso_code.to_s.upcase)
    @iso_code = iso_code
  end

  def to_s
    iso_code.to_s
  end

  def ==(other)
    other.class === self && other.hash.eql?(hash)
  end

  alias eql? ==

  def hash
    iso_code.hash ^ BIG_VALUE
  end

  private

  BIG_VALUE = 0b111111100100000010010010110011101011000101010111001101100110000
  private_constant :BIG_VALUE
end
```


