---
title: "JavaScript objects philosophy"
created_at: 2012-10-10 15:41:38 +0200
kind: article
publish: false
author: Jan Filipowski
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

It explicitly creates dog object with ```name``` field and ```woof``` method. Basic concept here is many times in your app there is no need for many objects with same data structure and behaviour, but rather one object with its data and behaviour. *Object orientation* reveals on instances, not classes. If you feel better with it you can call that it's **real** object orientation.

### Object.create method

```javascript
var cat = Object.create()
cat.name = "David"
cat.miau = function() {
  console.log("miau miau")
}
```

Object.create instantiate empty cat object -- without any field. If you'd pass object as ```create```'s parameter it'd become created object prototype. More on prototypes later, so let's focus on ```cat```. We add its data and behaviour by assigning values and functions to its not-yet-existing fields. Of course in runtime you can change both field value to new values (or functions) and even remove field.

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


