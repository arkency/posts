---
title: "JavaScript objects philosophy"
created_at: 2012-10-12 11:30:38 +0200
kind: article
publish: true
author: "Jan Filipowski"
newsletter: :react_books
tags: [ 'javascript', 'oop' ]
---

As a web programmer you use JS from time to time or on daily basis. You probably know how to create and use objects, but don't feel that approach is natural. It's awful JS, right? No, it's you and your lack of knowledge. Let's see what object orientation in JavaScript mean.

<!-- more -->

## What is object?

In terms of JS, object is collection of key-value pairs, where key have to be string. Value doesn't have any type constraints, so it can store primitives, objects or functions (in that context we call them "methods"). Variables and object fields store only reference to object. Objects can be compared only in terms of reference identity.

## How to create object?

There are many ways to create objects in JavaScript, so let's name some of them.

### Object literal

```javascript
var dog = {
  name: "Jose",
  woof: function() {
    console.log("woof woof")
  }
}
```

It explicitly creates dog object with *name* field and *woof* method. Basic concept here is many times in your app there is no need for many objects with same data structure and behaviour, but rather one object with its data and behaviour. *Object orientation* reveals on instances, not classes. If you feel better with it you can call that it's **real** object orientation.

### Object.create method

```javascript
var cat = Object.create()
cat.name = "David"
cat.meow = function() {
  console.log("meow meow")
}
```

[Object.create](https://developer.mozilla.org/en-US/docs/JavaScript/Reference/Global_Objects/Object/create) instantiate empty cat object -- without any field. If you'd pass object as *create*'s parameter it'd become prototype of created object. More on prototypes later, so let's focus on *cat*. We add its data and behaviour by assigning values and functions to its not-yet-existing fields. Of course in runtime you can change both field value to new values (or functions) and even remove field.

### Constructor function

```javascript
function Owl(name) {
  this.name = name;
  this.hoohoo = function() {
    console.log("hoo hoo")
  }
}

var owl = new Owl("Albert")
```

First of all what is Owl? As you see it's a function, but kind of special. It's called constructor, because it constructs new objects with defined data and behaviour. You must be warned - in this example each object constructed with Owl will have different hoohoo method, because it's defined as part of construction. Later we'll figure out how to share methods.

That's the first way to differentiate class of objects - if you created object with constructor you can say, that object is it's instance 

```javascript
owl instanceof Owl //=> true
```

But remember - owl is not instance of Owl class, but rather owl is instantiated by Owl constructor.

## Prototypical inheritance

In JS inheritance base on objects, so object *a* can inherit data and behaviour form object *b* and then object *b* is called prototype of object *a*. Of course *b* can also have prototype, so each object has chain of prototypes. Ok, let's see example.

```javascript
var protoCat = {
  name: "Tom",
  meow: function() {
    return this.name + ": meow meow"
  }
}
// 1
var cat = Object.create(protoCat)
console.log(cat.name) // Tom
console.log(cat.meow()) // Tom: meow meow

// 2
protoCat.name = "Proto"
console.log(cat.name) // Proto
console.log(cat.meow()) // Proto: meow meow

// 3
cat.name = "Silly Cat"
console.log(cat.name) // Silly Cat
console.log(protoCat.name) // Proto
console.log(cat.meow()) // Silly Cat: meow meow

// 4
cat.meow = function() {
  return this.name + ": woof woof"
}
console.log(cat.meow()) // Silly Cat: woof woof
console.log(protoCat.meow()) // Proto: meow meow
```

As you see in this example protoCat's fields are fallback for cat's one - if cat doesn't have field interpreter looks for it in prototype, and then recursively in prototype's prototype... If that field is function it also passes right object - on which method was invoked - as this. And if found method uses object's field interpreter start searching from original object.

So prototype defines default data and behaviour of objects that inherits from it and that's the way to share and reuse common behaviours. The biggest difference here is that you don't inherit from class of instances, but just instance, so if you'd change prototype field in runtime, all object's that inherits from it will be affected unless they override that field.

### Common prototype for constructed objects

I showed you how to create object with prototype with *Object.create*. You can also assign common prototype for objects created by constructor:

```javascript
var animal = {
  woof: function() {
    return this.name + ": woof woof"
  }
}

function Owl(name) {
  this.name = name
}
Owl.prototype = animal

var owl = new Owl("Albert")
console.log(owl.woof()) // Albert: woof woof
```

*Owl.prototype = animal* means, you want each of constructed object to have animal as prototype. Of course prototype can be also created with constructor:

```javascript
function Animal() {
  //...
}

function Owl() {
  //...
}
Owl.prototype = new Animal()
var owl = new Owl()
```

In that case owl object is both instance of Owl and Animal in terms of ```instanceof``` operator. Why ```owl instanceof Animal```? Suppose that we remove all Owl-specific fields - how would owl behave like? Animal, of course, so that's the answer.

## Ending words

Prototype-based inheritance is emanation of inability to create perfect taxonomy of objects in terms class-based inheritance. As software engineer you probably know that there's no way to create perfect class inheritance tree, that won't be affected by change of your knowledge about domain. Prototype-based object orientation is no better, but simplicize meaning of object - it doesn't have to have type, class - it's just container for data and behaviour, which have meaning in current context - for our knowledge of problem domain. Please remember: when you are thinking about prototype-based object orientation you should focus on easy-to-create objects, not prototype-inheritance, which is just consequence.

I hope that now you **feel** JavaScript object orientation, but if you still feel uncertain about object-oriented programming in JS write a comment or [ping me on Twitter](https://twitter.com/janfilipowski).

