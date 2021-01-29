---
title: Deployment Decision Matrix
created_at: 2021-01-29T19:45:27.471Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Deployment Decision Matrix

To CD or to not CD.

## Questions to as yourself, factors to take into account

* running e2e tests on prod vs staging
* factor: how accurately staging env mimics prod (and how much confidence it gives)
* factor: how much effor it costs to maintain staging env
* factor: how flaky tests on staging are (how often a failure on staging indicates an actual failure on prod)
* should (e2e) tests on staging block deployment? a backdoor for deployment?
* how long it takes to fix an issue encountered after deployment
* risk of CD vs risk of no CD (deploying other ppls changes, batching changes, time delay (loosing context what i've been doing))
* production tests
* "also, when it comes to assessing the risk of breaking stuff when moving towards CD, it’s worth stating that we’re not necessarily increasing the risk, because currently the risk also exists — if someone promotes to prod 3 days worth of dev changes, anything can happen; I’d say moving towards CD can even decrease risk here"
* "i’d say the typical problem in current deployment is that when deploying stuff to prod you often need to do something, like set up an env var on prod or setup a 3rd party service or sth — when I’m deploying someone else’s changes batched with mine, I never know if I’m not missing something, we can either always prepare such changes upfront (cannot test them then) or list them in a doc, but how reliable is that"
* "when I can deploy only my changes right away, then I can easily take care of everything needed on prod"

<!--


Whatever solution is going to be introduced it’s worth taking into account several more factors:
• Time needed to quickly deploy a fix to production. If we make running e2e tests (cypress) mandatory before every merge or deploy, it will be indeed safer, but never perfectly safe. So when a bug still makes it through, we want to be able to fix issue quickly and not have to go through the whole CI flow with e2e tests which may be flaky. So it’s good to just have a backdoor to deploy to prod without otherwise mandatory checks.
• The cost of setting up and maintaining dedicated QA envs.
• Limited assurance gained from testing on dedicated QA envs since they’re not actually production.
• Development “tax” related to not being able to merge to master quickly. This can invisibly slow down development (when PRs dependent on each other) and can encourage longer living divergent branches (higher chance of conflict) or obese change sets (difficult to review by teammates). That’s even more relevant because backend development in most cases doesn’t affect the product catalog, which is the main area where the bugs are critical to fix ASAP.

Random (partial) solution ideas:
• Running e2e tests before every deploy sounds fine, but preferably not before every merge, to avoid incurring aforementioned development tax.
• Feature flags can replace dedicated QA envs in a lot of cases, with the added benefit of testing on actual production.
• Staging can just be a separate environment, brought to use when needed — not a mandatory step on the way to deployment as it is now.
• Production tests / smoke tests — triggered post deploy. They can bring a lot of assurance since they run on actual production, but it should be a secondary measure because it happens post factum. More here: https://blog.arkency.com/2017/01/run-your-tests-on-production/
• It’s worth nothing that not a lot of backend changes should bring such disruption as last incident (which was btw handled very well). It’s mostly when working with product catalog, particularly when changing GraphQL schema (our defacto contract with FE). So we should just be particularly cautious when changing the schema, to introduce backwards compatible change. It’s not easy to miss because the tests won’t pass without running a rake task.


-->
