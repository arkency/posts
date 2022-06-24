---
created_at: 2022-06-08 21:16:18 +0200
author: Łukasz Reszke
tags: ['mutant', 'value object', 'eql? vs equal? vs ==', 'ddd', 'ruby' ]
publish: true
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

    protected attr_reader :iso_code

    def initialize(iso_code)
      raise unless SUPPORTED_COUNTRIES.include?(iso_code.to_s.upcase)
      @iso_code = iso_code
    end

    def to_s
      iso_code.to_s
    end

    def eql?(other)
      other.instance_of?(Country) && iso_code.eql?(other.iso_code)
    end

    alias == eql?

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
 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  other.instance_of?(Country)
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  iso_code.eql?(other.iso_code)
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  other.instance_of?(Country) || iso_code.eql?(other.iso_code)
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  other && iso_code.eql?(other.iso_code)
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  true && iso_code.eql?(other.iso_code)
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  Country && iso_code.eql?(other.iso_code)
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  self.instance_of?(Country) && iso_code.eql?(other.iso_code)
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  other.instance_of?(Country) && iso_code
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  other.instance_of?(Country) && true
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  other.instance_of?(Country) && other.iso_code
 end

 def eql?(other)
-  other.instance_of?(Country) && iso_code.eql?(other.iso_code)
+  other.instance_of?(Country) && iso_code.eql?(self.iso_code)
 end

 def hash
-  iso_code.hash
+  raise
 end

 def hash
-  iso_code.hash
+  super
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

 def hash
-  iso_code.hash
+  self.hash
 end
```
The `-` sign symbolizes removed line of code. The `+` sign symbolizes line of code introduced by mutant. So even though there are tests that look quite good, the result is poor. This causes false sense of security. 

This is the summarized score that we'll start with:
```
Integration:     minitest
Jobs:            1
Includes:        ["test"]
Requires:        ["./config/environment", "./test/support/mutant"]
Subjects:        4
Total-Tests:     523
Selected-Tests:  4
Tests/Subject:   1.00 avg
Mutations:       72
Results:         72
Kills:           55
Alive:           17
Timeouts:        0
Runtime:         26.23s
Killtime:        23.41s
Overhead:        12.09%
Mutations/s:     2.74
Coverage:        76.39%
```

Let's increase that coverage!

_This is a good point in time to copy the code and try to increase it's mutant coverage_ 😉

## Heal the code
At a first glance it looks like our test suite is not complete. Let's try to increase mutant coverage by adding missing tests.

```ruby
    def test_values_equality
      refute Country.new(Country::PL).eql? Country.new(Country::NO)
      refute Country.new("PL").eql? "PL"
    end
```

So in this test we expect that

* `Country` objects of two different countries are not equal
* Value object is not the same thing as simple string

All right so this test removes most of the problems. Actually, there is 6 more issues left:

```ruby
 def hash
-  iso_code.hash
+  raise
 end

 def hash
-  iso_code.hash
+  super
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

 def hash
-  iso_code.hash
+  self.hash
 end
```

How can we kill those mutants?

## Making hash method more robust

```ruby
  def hash
    Country.hash ^ iso_code.hash
  end
```

And run mutant again

```ruby
 def hash
-  Country.hash ^ iso_code.hash
+  raise
 end

 def hash
-  Country.hash ^ iso_code.hash
+  super
 end

 def hash
-  Country.hash ^ iso_code.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  nil
 end

 def hash
-  Country.hash ^ iso_code.hash
+  Country.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  nil ^ iso_code.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  Country ^ iso_code.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  self.hash ^ iso_code.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  iso_code.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  Country.hash ^ nil
 end

 def hash
-  Country.hash ^ iso_code.hash
+  Country.hash ^ iso_code
 end

 def hash
-  Country.hash ^ iso_code.hash
+  Country.hash ^ self.hash
 end
```

Well... not good, not bad. Different mutants were injected in the code. Still, there are some survivors. 

Step back. What are we trying to achieve?

We're trying to design Value Object.

Two Value Objects are equal when:
- they have the same hash values, we have such a test
- when their classes are the same

Once again it looks like we are missing some tests.

Let's write a test that will check if the hash value of two value objects are equal.

```ruby
  def test_hash_equality
    assert Country.new(Country::PL).hash.eql? Country.new(Country::PL).hash
  end
```

And now let's run mutant and see the results.
```ruby
 def hash
-  Country.hash ^ iso_code.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  nil
 end

 def hash
-  Country.hash ^ iso_code.hash
+  Country.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  nil ^ iso_code.hash
 end

 def hash
-  Country.hash ^ iso_code.hash
+  iso_code.hash
 end
```

So what is mutant trying to tell us?

If you're following along, modify the hash method to one of the suggestions and see what happens. Yep. The tests are still passing! And they shouldn't be, right?

I think we're missing a test to make sure the modification that we just did would be detected if the `hash` method was changed. Specifically I mean the step that we just did, so adding the class of the Value Object to the equation. 

Let's fix this by extending the hash_equality test case by few negative scenarios testing the hash method.

```ruby
  def test_hash_equality
    assert Country.new(Country::PL).hash.eql? Country.new(Country::PL).hash

    # new cases below
    assert_not_equal Country.new(:PL).hash, (Country.hash ^ "NO".hash)
    assert_not_equal Country.new(:PL).hash, (Country.hash ^ "PL".hash)
    assert_not_equal Country.new(:PL).hash, (Country.new(:NO).hash)
    refute Country.new(Country::PL).hash == "PL".hash
  end
```

Now after running the mutant we're good :)

```
Integration:     minitest
Jobs:            1
Includes:        ["test"]
Requires:        ["./config/environment", "./test/support/mutant"]
Subjects:        4
Total-Tests:     525
Selected-Tests:  6
Tests/Subject:   1.50 avg
Mutations:       78
Results:         78
Kills:           78
Alive:           0
Timeouts:        0
Runtime:         37.15s
Killtime:        33.76s
Overhead:        10.03%
Mutations/s:     2.10
Coverage:        100.00%
```

# Why did we use `eql?` instead of `==`
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

In general, it's better to use `.eql?` method for the Value Object if you want to make sure that there's no hash colision.

# What about equal?
Why isn't the `equal?` method also aliased to the `eql?` operator? The reason is the fact that the `equal?` method checks the identity of the object.
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

Besides that, overwriting `equal?` is not recommended.

# Final Value Object
```ruby
class Country
  SUPPORTED_COUNTRIES = [PL = "PL", NO = "NO"].freeze

  protected attr_reader :iso_code

  def initialize(iso_code)
    raise unless SUPPORTED_COUNTRIES.include?(iso_code.to_s.upcase)
    @iso_code = iso_code
  end

  def to_s
    iso_code.to_s
  end

  def eql?(other)
    other.instance_of?(Country) && iso_code.eql?(other.iso_code)
  end

  alias == eql?

  def hash
    Country.hash ^ iso_code.hash
  end
end
```

