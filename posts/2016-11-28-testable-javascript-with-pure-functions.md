---
title: "Testable Javascript with pure functions"
created_at: 2016-11-28 20:11:51 +0200
kind: article
publish: false
author: Anton Paisov
tags: [ 'javascript', 'testing', 'mocha' ]
newsletter: :skip
---

What if I told you that covering javascript code with tests can be easy and pleasant experience?

There’s one simple rule you need to follow in order to achieve that: **keep the logic stateless**.
And all of a sudden you don’t need to mock anything, or emulate browser, or do any other not logic related stuff.

<!-- more -->

_Breaking news: this rule applies to other areas of programming too :)_


So, imagine we have a task: implement a mechanism for displaying ticket fees.

Let’s write the logic first:

```
#!javascript
export function feeAmount(fees) {
  return (statePrice, include) => {
    const price       = parseFloat(statePrice);
    const percentage  = parseFloat(fees.percentage);
    const startingFee = parseFloat(fees.startingFee);
    const maximumFee  = parseFloat(fees.maximumFee);

    if (statePrice === 0) {
      return 0.0;
    }

    const coreFeeableSum = include ? ((price - startingFee) / (1 + percentage)) : price;
    const currentFee = coreFeeableSum * percentage + startingFee;

    if (maximumFee && (currentFee > maximumFee)) {
      return maximumFee;
    }

    return currentFee;
  };
}

export function amountWithFee(feeAmountFn) {
  return (price, include) => {
    const feeAmountAdd = include ? 0 : feeAmountFn(price, include);
    return price + feeAmountAdd;
  };
}
```

_Notice that we’re doing functional [currying](https://en.wikipedia.org/wiki/Currying) here, it’s really handy when you need to pass same calculations into different functions, for example._

Now let’s have some tests for it (I’m using [mocha](https://www.npmjs.com/package/mocha) and [assert](https://www.npmjs.com/package/assert)):

```
#!javascript
import { describe, it } from 'mocha';
import { feeAmount, amountWithFee } from '../src/calculations';
import assert from 'assert';

const fees = {
  percentage: 0.035,
  starting_fee: 3.49,
  maximum_fee: 53.99
};

const feeAmountFn = feeAmount(fees);
const amountWithFeeFn = amountWithFee(feeAmountFn);
const organizerRevenueFn = organizerRevenue(feeAmountFn);

describe("feeAmount", () => {
  it("calculates fee NOT included", () => {
    assert.equal(feeAmountFn(150, false).toFixed(2), 8.74);
  });

  it("calculates fee included", () => {
    assert.equal(feeAmountFn(150, true).toFixed(2), 8.44);
  });

  it("returns maximum_fee", () => {
    assert.equal(feeAmountFn(2000, false).toFixed(2), 53.99);
  });

  it("returns maximum_fee", () => {
    assert.equal(feeAmountFn(2000, true).toFixed(2), 53.99);
  });
});

describe("amountWithFee", () => {
  it("calculates amount with fee NOT included", () => {
    assert.equal(amountWithFeeFn(150, false).toFixed(2), 158.74);
  });

  it("calculates amount with maximum_fee", () => {
    assert.equal(amountWithFeeFn(2000, false).toFixed(2), 2053.99);
  });
});
```

And now just import these functions where you will actually use them.

_If you want to learn more about testable javascript code with pure functions, be sure to check [this page](http://redux.js.org/docs/recipes/WritingTests.html)._

_We also have [Approaches to testing React components - an overview](http://reactkungfu.com/2015/07/approaches-to-testing-react-components-an-overview/) post._
