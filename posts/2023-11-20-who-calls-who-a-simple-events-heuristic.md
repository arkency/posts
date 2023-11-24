---
created_at: 2023-11-20 09:46:34 +0100
author: Tomasz Stolarczyk
tags: ['commands', 'events', 'context mapping', 'bounded contexts']
publish: true
---

# Who calls who? — a simple events heuristic

When integrating two components, you may wonder who should own the commands and events you want to use for communication. Today, I will show you a simple heuristic that may help you make this decision. The heuristic relies on the **frequency of change** in components. Before using it, we should visualize relationships between those components. Context Mapping is a perfect tool for that, as it shows how changes in one Bounded Context affect others (there is an excellent resource about the concept itself [here](https://github.com/ddd-crew/context-mapping)).

And now, without further ado, let's jump into an example. Let's assume that we have two components: _Registration_ and _Payment_. _Registration_ component changes a lot (green dots below mean a single change), as it has some rules that can change. On the other hand, _Payment_ component rarely changes.

<img src="<%= src_original("who-calls-who-a-simple-events-heuristic/frequency_of_change_01.jpg") %>" width="100%">

Now let's assume we decided to communicate between those components using commands/events (interfaces) from the _Registration_:

<img src="<%= src_original("who-calls-who-a-simple-events-heuristic/frequency_of_change_02.jpg") %>" width="100%">

It means that by doing that, we also defined the upstream-downstream relationship between those components, where _Registration_ is an upstream:

<img src="<%= src_original("who-calls-who-a-simple-events-heuristic/frequency_of_change_03.jpg") %>" width="100%">

It also means there is a bigger chance that changes in the _Registration_ will cause some changes in _Payment_. There is a higher coupling between those two components. To make it looser, we should change the direction of the upstream-downstream relationship. We can do it by simply using commands/events from _Payment_ like this:

<img src="<%= src_original("who-calls-who-a-simple-events-heuristic/frequency_of_change_04.jpg") %>" width="100%">

It's worth noticing how the names of interfaces changed based on which component was the upstream — such an experiment can sometimes impact how we see things.

You can use the described heuristic to fix some relationships or to create them wisely if you integrate new Bounded Contexts. Of course, there are always more nuances, like, for example, changes in model vs. changes in contracts, but that can be a topic for a different story 😉