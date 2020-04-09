---
title: "Use ES2015 with Rails today - what & how"
created_at: 2016-06-15 15:56:22 +0200
kind: article
publish: true
newsletter: skip
tags: [ 'rails', 'react' ]
author: Marcin Grzywaczewski
img: "frontend-friendly-rails/ffr-cover.png"
---

> This is a content which was previously published as a mailing campaign in the [Arkency Newsletter](http://eepurl.com/LnL3b). This promotes our new book - _Frontend Friendly Rails_ which is available on sale now. Use **`FF_RAILS_BLOG`** to get 40% discount on the book, which you can [buy here](https://arkency.dpdcart.com/cart/add?product_id=133328&method_id=142386).

ECMAScript 2015 is the new standard of JavaScript, popularised mostly by communities around [React.js](https://facebook.github.io/react/) view library. While Angular people chose [TypeScript](https://www.typescriptlang.org/) for their language of choice and Ember is (mostly) unopinionated about it, React people tend to use ES2015 extensively.

<!-- more -->

ECMAScript 2015 is the new standard of JavaScript. Just like Ruby has version 2 or 1.8, ECMAScript 2015 is the new version of the language. It’ll be supported by every browser soon. Right now it’s not, but you can still use it today thanks to so-called _transpilers_ or _source-to-source compilers_ that understand new syntax and transforms it into the old standard of JS.

Since it’s hard to chase all JavaScript novelties if you don’t sit in it, it’s understandable that ES2015 can be a new thing to you. I’d like to present you what you can gain by using it today and what’s the best way to do it with Rails.

## ECMAScript 2015 is the ’more familiar’ JavaScript

ES2015 is an evolution, not revolution - it adds features to the language. Old JavaScript code is automatically ES2015 code - no changes needed. Just like Ruby 1.9 code is automatically Ruby 2.0 code.

One of the most common struggles people have with JavaScript is its ‘unfamiliarity’. JavaScript is object-oriented, but in a different way than most language - it’s object model is based on _prototypes_, not _classes_. This is nor simpler nor more complex model of object orientation - just different. In fact, it has the same capabilities that classical ‘class’ object model has.

To aid developers migrating from languages like Ruby, C# or C++, ECMAScript 2015 provides a support of classes you already know and love. Compare:

```javascript
// Old JavaScript, using prototypes
function Vehicle() {}
Vehicle.prototype.drive = function
  drive(speed) {
    console.log("Whopping " + speed + " kilometres!");
  };
function Car() {}
// Inheritance:
Car.prototype = new Vehicle();
Car.prototype.nitroBoostDrive = function
  nitroBoostDrive(speed) {
    this.drive(speed * 10);
  };
Car.prototype.constructor = Car;
```

To:

```javascript
class Vehicle {
  drive(speed) {
    // BTW. You can interpolate strings in new JS!
    console.log(`Whopping ${speed} kilometres!`);
  }
}

class Car extends Vehicle {
  nitroBoostDrive(speed) {
    this.drive(speed * 10);
  }
}
```

Much familiar syntax is a great addition to the language. You can stick with it if you want, or learn the underlying prototype model later - it usually pays off and makes some ‘weird’ edges of JavaScript much more understandable (like the concept of context in functions).

Other problem people tend to had with JavaScript is a visibility of variables and the concept of _hoisting_.

Old variables in JavaScript has the _function scope_ - that means whenever you’ll define them they’ll be bound to the scope of a function. Consider this:

```javascript
function weirdJavascript(n) {
  if (n % 2 == 0) {
    var f = 3;
  }
  else {
    var f = 5;
  }
  console.log(f);
}
```

In most languages `console.log(f)` would throw an error since `f` is undefined. But since JS variables tend to be scoped in a _function scope_ and there is a concept of _hoisting_, the function behaves more like this function:

```javascript
function weirdJavascript(n) {
  var f;
  if (n % 2 == 0) {
    f = 3;
  }
  else {
    f = 5;
  }
  console.log(f);
}
```

This breaks familiarity with other languages you know. It is because most languages use so-called _block scope_ - so variable is visible in the block it is defined and nowhere else.

ES2015 fixes this by introducing a new type of variables which are _block scoped_ - say hello to `let` and `const`:

```javascript
function familiarJavascript(n) {
  if (n % 2 == 0) {
    let f = 3;
  }
  else {
    let f = 5;
  }
  // Uncaught ReferenceError: f is not defined.
  console.log(f);
}
```

The difference between `let` and `const` is that if you define `const`, you can’t change it later (because it is _constant_):

```javascript
function constantJavascript(n) {
  const result = n + 1;
  if (n % 2 == 0) {
    // Uncaught TypeError: Assignment to constant variable.
    result += 1;
  }
  return result;
}
```

Such additions to the language are making JavaScript more friendly and familiar to developers coming from Ruby and other languages. This is a great thing because, well, no matter you like it or not, we all end up writing JS eventually… Aren’t we? :)

## ECMAScript 2015 is the ‘unsucked’ JavaScript

JavaScript is burdened by its past - and certain unhappy decisions made that you must live with.

One of the most annoying is the concept of default context. If you forget to use `var`, `let` or `const` in an assignment to the variable, you’ll define a global variable:

```javascript
f = 3;
window.f; // 3
```

That’s unexpected and it _sucks_. It allows you to create global variables by an accident - or shadow existing global functions with accidental values. Ouch!

There is a concept of _strict mode_ in JavaScript. It breaks backwards compatibility in favor of providing better defaults - like fixing this default context issue.

Fortunately, since most people tend to forget to switch _strict mode_ on, certain ES2015 features like _classes_ or _modules_ enable it by default. Also tooling behind transpiration today are producing “ES2015 modules” by default so strict mode is enabled for free - you don’t need to remember about adding it by yourself.

Next thing, coming from the way how JavaScript works under the hood is the idea of _context binding_ to functions. If you write  a class in Ruby, no matter how you call the method, the context (`self` or `@`) will be the object from which you called this method.

This is not the case in JavaScript. Due to its prototypical nature, they decided to compute the context when a function is called. This is not necessarily a bug (for me it’s a feature), but it is very surprising to many:

```
var incrementor = {
  x: 1,
  increment: function increment() {
    this.x = this.x + 1;
  }
};

incrementor.increment();
incrementor.x; // 2
var fn = incrementor.increment;
fn();
incrementor.x; // 2 ?!
window.x; // NaN
```

In this case calling `fn` set the context to default one - so `window`. Since `window.x` is `undefined` and the number is added here, the result is `NaN`.

Specifying context works [different than in most languages](http://reactkungfu.com/2015/07/why-and-how-to-bind-methods-in-your-react-component-classes/) that are using _lexical binding_ of context.

This is also the reason of the pattern you may often see in jQuery code:

```javascript
var counter = {
  count: 0,
  setCount: function setCount(newCount) {
    this.count = newCount;
  },
  countFriends: function countFriends() {
    /*
    $(".friend").each(function iterateFriends() {
      // ERROR! each set its own context here.
      this.setCount(this.count + 1);
    });
    */

    var that = this;
    $(".friend").each(function iterateFriends() {
      that.setCount(that.count + 1);
    });
  }
};
```

This `that` pattern is because context is not lexical scoped. This is powerful concept, really, but often you just want to refer to the lexical context, no matter what.

Fortunately, ES2015 provides lexical-scoped functions, being also a very handy shorthand for defining functions in place - the feature is called ‘arrow functions’:

```javascript
var counter = {
  count: 0,
  setCount: function setCount(newCount) {
    this.count = newCount;
  },
  countFriends: function doSomething() {
    // Arrow function has lexical 'this'. No 'that' necessary!
    $(".friend").each(() => {
      this.setCount(this.count + 1);
    });
  }
};
```

Not only it’s more concise than `function` syntax (which comes in handy if you don’t care about the context at all), but also provides a nice feature of having a lexical context. This has tremendous effect on typical frontend code that is being written - making it easier to read, more concise and less surprising.

## ECMAScript 2015 is the ’more convenient’ JavaScript

Arrow functions are one thing that is making writing typical code in JavaScript less tedious. But there are more features that are making writing code more pleasant.

First feature that was lacking for a long time is _string interpolation_. ES2015 provides it by wrapping your string content with backticks:

```javascript
var answer = 42;
var output = `answer to the ultimate question of life the universe and everything is ${answer}`;

var multiline = `Multiline strings?
Not a problem.`;
```

Unpacking objects and arrays is so common operation that ES2015 provides a special syntax for it called _destructuring_. Just see it in action to see how useful it is:

```javascript
const object = {
  x: 1,
  y: 2,
  foo: {
    bar: 3
  }
};

// Extract 'x' and 'y' fields from object
// and make variables x and y.
const { x, y } = object;
console.log(x); // 1
console.log(y); // 2
// The same, but first and second variables are created.
const { x: first, y: second } = object;
console.log(x); // 1
console.log(y); // 2

// Nested destructuring. `bar` variable will be created.
const { foo: { bar } } = object;
console.log(bar); // 3

// Nested restructuring with returning the whole object too.
const { foo: { bar: baz }, foo } = object;
console.log(foo); // { bar: 3 }
console.log(bad); // 3

// What about arrays?

const arr = [{ a: 1, b: 2 }, { c: 3, d: 4 }];
const [obj1, obj2] = arr;
console.log(obj1); // { a: 1, b: 2 }
console.log(obj2); // { c: 3, d: 4 }

// Combo!
const [{ a }, { d }] = arr;
console.log(a); // 1
console.log(d); // 2

const arr2 = [1, 2, 3];
// You can use spread operator (three dots):
const [firstNum, ...restNumbers] = arr2;
console.log(firstNum); // 1
console.log(restNumbers); // [2, 3]

// You can use object destructuring
// in function arguments list too:
function sumObj({ a, b }) {
  return a + b;
}

// If your arrow function body is an expression, just skip
// brackets and enjoy implicit return.
const multiplyObj = ({ a, b }) => a * b;
sumObj({ a: 2, b: 2 }); // 4
multiplyObj({ a: 2, b: 2 }); // 4
```

Looking innocent, this saves you a lot of tedious writing.

There is also a change to defining functions. You can supply default arguments and use spread operator to work with variadic functions:

```javascript
function addTwo(a = 0, b) {
  return a + b;
}

function sumAll(...elements) {
  return elements.reduce(
    (partialResult, elem) => partialResult + elem,
    0);
}

addTwo(2); // 2
addTwo(2, 2); // 4
sumAll(1, 2, 3, 4, 5); // 15
```

The last addition that is extremely useful is _enhanced object notation_. It’s better to see it by an example:

```javascript
const x = 2, y = 3, itsMe = "hello";

const enhancedObj = {
  methodInPlace(y) { // Method in place
    return this.x + y;
  },
  x, // It's so common to make assignment in object like x: x
     // there is a shorthand for this.
  y,
  // Computed properties are possible.
  [itsMe.toUpperCase()]: "Can you hear me?"
};

/*
{ methodInPlace: function methodInPlace() {
    return this.x + y;
  },
  x: 2,
  y: 3,
  "HELLO": "Can you hear me?"
}
*/
```

There are many more. Those are only that I’m using in my day-to-day work, making my work more pleasant. There are generators, iterators, new `for` syntax and so on. That being said, there is a lot of sugar added to JavaScript - a sugar which makes you way more productive once you master it.

## ECMAScript 2015 is the ’modular’ JavaScript

Last, but not least. Before ES2015 JavaScript had no syntax for building modules. There were technologies and standards that allowed your code to be modular (CommonJS, RequireJS…). But with ES2015 modules became first-class citizens, having its own syntax. It allows your code to hide implicit details of implementation, relying only on the public API. Not to mention it makes your dependency control way easier:

```javascript
// moduleA.js

const moduleState = {
  timesCalled: 0
};

function moduleFunction() {
  moduleState.timesCalled += 1;
  if (moduleState.timesCalled > 10) {
    console.log("Why are you calling me in " +
                "the middle of the night?");
  }
}

export default callModuleFunction;
```

```javascript
// moduleB
import moduleAFunction from './moduleA';

for (let i = 0; i < 15; ++i) {
  moduleAFunction();
}

// Prints the message 5 times.
```

You can use destructuring, make default or name imports:

```
// moduleA.js

function foo() { /* ... */ }
function baz() { /* ... */ }

export default {
  foo,
  baz,
  answer: 42
};

export const bar = () => { /* ... */ }
export const abc = () => { /* ... */ }
```

```
import { foo, baz, answer }, * as lib from './moduleA';

lib.bar();
lib.abc();

foo();
baz();
answer;
```

This allows you to structure your code way better and with concise syntax. Previous solutions like using [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression) was quite verbose - here you have nice syntax and (soon) native support for modularization of your code.

## I want it! How can I use it?

As you can see, ES2015 brings much into the table. Not only it’s more convenient to use, but also comes with many great opportunities (better stdlib, modularization, TCO after being implemented by browsers natively) for today and future.

Unfortunately, having all of it with Rails is not that super-easy.

First of all, Sprockets will support ES2015 starting from version 4. If you have a new version of Rails, you’re probably using version 3, which only has an experimental support. Even with this support, load system of Sprockets kinda doubles your work if you want modularise your code.

What’s more, this technology is developing in a very rapid pace, so tooling is constantly evolving and the best of tools are available on Node.js-based stacks.

Does it mean we’re doomed and we can’t use this stuff?

Of course we can. You can use experimental support in Sprockets if you want or use many gems that are trying to add the support for it. But the most robust solution for me is to add a separate, Webpack-based stack. There is [SurviveJS](https://survivejs.com/) book about it (grab it - it’s cool!), which is also teaching React.js which is quite cool technology. There are also many articles in the web.

In fact, for me it’s so important I’ve made a big chapter about it in my “Frontend-friendly Rails” book. It seems people are struggling with it, so I’ve decided to make a step-by-step process of constructing the whole stack from zero to a complete solution.

And you can buy it now.

## “Frontend-friendly Rails” is live!

<a href="https://arkency.dpdcart.com/cart/add?product_id=133328&method_id=142386">
  <%= img_fit("frontend-friendly-rails/ffr-cover.png") %>
</a>
<a href="http://blog.arkency.com/assets/misc/frontend-friendly-rails/ff-rails-sample.pdf" style="display: block; margin: 1em 0; text-align: center; font-size: 1.5em">Download the free chapter</a>

Finally I managed to write this book :). It’s a set of good practices and techniques I’ve worked during my work on couple of projects I’ve worked so far. This book is about making Rails more friendly to your frontend, making it easier and faster to write, as well as more powerful and maintainable.

I had tons of fun writing it and I’m using those techniques in my day to day work. I hope you’ll find it useful too in your projects - hours of development in Arkency proved me those are battle-tested solutions to real problems.

It’s the beta version of the book. If you buy it now, you’ll get all updates for free.

**Just enter `FF_RAILS_BLOG` as a coupon code to get 40% discount for this book**. The original price is $49 and you’ll get it for less than $30!

Book has 97 pages of exclusive content now + bonus chapters, so it’s 154 pages in total. If you don’t like it, we have an eternal no-questions-asked refund policy - just drop us an e-mail and you’ll get refunded.

<a href="https://arkency.dpdcart.com/cart/add?product_id=133328&method_id=142386" style="display: block; margin: 1em 0; text-align: center; font-size: 2em;">Click here to buy the book!</a>
<a href="http://blog.arkency.com/assets/misc/frontend-friendly-rails/ff-rails-sample.pdf" style="display: block; margin: 1em 0; text-align: center; font-size: 1.5em">Download the free chapter</a>

The following topics are covered in the book:

* Switch your Rails application to frontend-generated UUIDs - a step-by-step, database-agnostic, test-driven solution you can use with legacy applications too. It’ll allow you to _free_ your frontend code from being tightly coupled to the backend with every data change.
* Setup the Cross-Origin Sharing (CORS) - the description of the problem as well as the solution described. Useful if you want to host frontend on a different host than your backend.
* Prepare JSON API endpoints for your API - JSON API allows you to have very robust response format for your endpoints which will serve you well and you won’t need to think about it. That’ll allow you to focus what’s more important - which is doing your business logic right.
* Create a living API - beyond request-response cycle - this is a chapter about adding real-time support to make your frontend even more user friendly. The solution presented is made using the Pusher library, but the way of doing it is tool-agnostic. I also present cool technique to make the real-time support as maintainable as possible.
* Consequences of frontend decisions - level up your knowledge and understanding of shaping your frontend, knowing consequences of your decision. More theoretical (but code-based) chapter which will improve your thinking about designing frontend code.
* A complete overview of creating modern assets pipeline - the last chapters are about creating the assets pipeline from scratch. You’ll learn what tools you’ll use, what their responsibilities are and how to configure it in a step-by-step manner. After you finish, you’ll have the stack with ES2015 support, CoffeeScript support for legacy compatibility, testing stack and production builds.

I’m available to you for all questions about this book. Just drop me a comment I’ll try to clarify everything you may need to make a decision whether this book is a good choice for you or not.

Techniques I’ve described in the book made my work better and allowed me to write better Rails API applications. I hope you’ll find the book as useful as I’m finding those techniques.

<a href="https://arkency.dpdcart.com/cart/add?product_id=133328&method_id=142386" style="display: block; margin: 1em 0; text-align: center; font-size: 2em;">Click here to buy the book!</a>
<a href="http://blog.arkency.com/assets/misc/frontend-friendly-rails/ff-rails-sample.pdf" style="display: block; margin: 1em 0; text-align: center; font-size: 1.5em">Download the free chapter</a>

## Listen to the podcast

Is listening a your kind of consuming content? You can grab a 30-minute podcast where we discuss what you can find inside the book and what were our motives to write it:

<audio controls="">
  <source id="mp3-source" src="http://rails-refactoring.com/podcast/rails-refactoring.com_06.mp3" type="audio/mpeg">
</audio>

You can also download it in the [mp3 format](http://rails-refactoring.com/podcast/rails-refactoring.com_06.mp3) and [see the shownotes here](http://rails-refactoring.com/podcast/).
