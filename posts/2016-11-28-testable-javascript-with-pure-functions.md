---
title: "Testable Javascript with pure functions"
created_at: 2016-11-28 20:11:51 +0200
kind: article
publish: true
author: Anton Paisov
tags: [ 'javascript', 'testing', 'mocha', 'testing']
newsletter: :skip
---

What if I told you that covering javascript code with tests can be easy and pleasant experience?

There’s one simple rule you need to follow in order to achieve that: **keep your functions pure** or in other words **keep your code side-effect free**.
And all of a sudden you don’t need to mock anything, or emulate browser, or do any other not logic related stuff.

<!-- more -->

_Breaking news: this rule applies to other areas of programming too :)_


So, imagine we have a task: implement a mechanism that calculates ticket fees.

Let’s write the logic first:

```javascript
export function feeAmount(fees) {
  return (price, include) => {
    const startingFee = fees.startingFee;
    const maximumFee  = fees.maximumFee;
    const percentage  = parseFloat(fees.percentage);

    if (price === 0) {
      return 0;
    }

    const coreFeeableSum = include ? ((price - startingFee) / (1 + percentage)) : price;
    const currentFee = coreFeeableSum * percentage + startingFee;

    if (maximumFee && (currentFee > maximumFee)) {
      return maximumFee;
    }

    return Math.round(currentFee);
  };
}

export function amountWithFee(feeAmountFn) {
  return (price, include) => {
    const feeAmountAdd = include ? 0 : feeAmountFn(price, include);
    return price + feeAmountAdd;
  };
}
```

Now let’s have some tests for it (I’m using [mocha](https://www.npmjs.com/package/mocha) and [assert](https://www.npmjs.com/package/assert)):

```javascript
import { describe, it } from 'mocha';
import { feeAmount, amountWithFee } from '../src/calculations';
import assert from 'assert';

const fees = {
  percentage: 0.035,
  startingFee: 349,
  maximumFee: 5399
};

const feeAmountFn = feeAmount(fees);
const amountWithFeeFn = amountWithFee(feeAmountFn);

describe("feeAmount", () => {
  it("calculates fee NOT included", () => {
    assert.equal(feeAmountFn(15000, false), 874);
  });

  it("calculates fee included", () => {
    assert.equal(feeAmountFn(15000, true), 844);
  });

  it("returns maximum fee", () => {
    assert.equal(feeAmountFn(200000, false), 5399);
  });

  it("returns maximum fee", () => {
    assert.equal(feeAmountFn(200000, true), 5399);
  });
});

describe("amountWithFee", () => {
  it("calculates amount with fee NOT included", () => {
    assert.equal(amountWithFeeFn(15000, false), 15874);
  });

  it("calculates amount with maximum fee", () => {
    assert.equal(amountWithFeeFn(200000, false), 205399);
  });
});
```

And now just import these functions where you will actually use them.

And to give you a full picture, here's how this logic may look when author doesn't care about logic testability:

```javascript
feeAmount() {
  const price       = this.state.price;
  const startingFee = this.props.fees.startingFee;
  const maximumFee  = this.props.fees.maximumFee;
  const percentage  = parseFloat(this.props.fees.percentage);

  if (price === 0) {
    return 0;
  }

  const coreFeeableSum = include ? ((price - startingFee) / (1 + percentage)) : price;
  const currentFee = coreFeeableSum * percentage + startingFee;

  if (maximumFee && (currentFee > maximumFee)) {
    return maximumFee;
  }

  return Math.round(currentFee);
}

amountWithFee() {
  if (this.state.include) {
    return this.state.price;
  } else {
    return this.feeAmount() + this.state.price;
  }
}
```

As you probably noticed this version comes from a method in React.js component
and relies on `state` and `props` from that component. But the calculations
have nothing to do with the UI logic. So it's better to keep them outside
the component and test separately. We don't need (or want) React to check our
math.

_If you want to learn more about testable javascript code with pure functions, be sure to check [this page](http://redux.js.org/docs/recipes/WritingTests.html)._

_We also have [Approaches to testing React components - an overview](http://reactkungfu.com/2015/07/approaches-to-testing-react-components-an-overview/) post._
