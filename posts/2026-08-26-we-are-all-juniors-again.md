---
created_at: 2026-08-26 16:40:52 +0200
author: Tomasz Stolarczyk
tags: ['lifestyle', 'motivation', 'ai', 'juniors', 'seniors', 'ai-native', 'Dreyfus', 'skill']
publish: false
---

# We are all juniors again

A long, long time ago, when [Akinator](https://en.akinator.com/) was the peak of "advanced AI" on the internet, before services became micro, and deployments meant sending a file directly from a local computer via FTP to a server, I was introduced to the Dreyfus Skill Model. As a junior dev back then, I liked it because it explained why my senior and architect colleagues could sometimes make impactful decisions intuitively, while I, on the contrary, was expecting step-by-step instructions on how to convert HTML form input into a database row.

In short, the Dreyfus Skill Model describes that when learning a new skill, a learner goes through 5 stages to acquire it:
1. Novice. We need/expect step-by-step instructions and rules here, and we have problems in situations that don't follow them.
2. Advanced beginner. We start to recognize some situation-specific nuances and use our experience instead of just rules.
3. Competent. We consciously define goals and priorities and plan our actions according to the situation.
4. Proficient. We intuitively recognize what the situation requires but consciously decide how to respond.
5. Expert. We intuitively understand the situation and respond without consciously considering each step.

I'm pretty sure that depending on how long you've been in IT, you may find yourself in one of those stages.

And now, getting back to AI and especially coding agents and support for the whole SDLC, it's another skill, whether we want it or not, that we at least should know how to deal with. The good news is that whether you are a 20-, 30-, or 40-year veteran in the industry, or just joining, we are pretty much on the same level. This allows us not to know things, to experiment, to ask questions, to copy what works, and to change our views and opinions every week. This is what novices/beginners do, and I definitely feel I'm in those phases again. And I'm pretty sure that's not only me.

Surprisingly often, when digging deeper into those "high-level AI concepts", conversations end up on something like "well, I have a skill/MD", or "I have a nice prompt that does the job". And that's totally fine, as we are all learning how to use those tools and what works in the whole SDLC. What I'm trying to highlight is that instead of hearing about "10x productivity increase", "building another harness", "running a swarm of agents", or "AI changing someone's life", I would actually want to hear how it's done. With details. And those details may be a single line of text in CLAUDE.md or a short explanation of this "obviously known feature", since people expect exactly this kind of detail, because everyone feels behind.

We are in a place where, just a year ago, [the Stack Overflow Developer Survey 2025](https://survey.stackoverflow.co/2025/ai) found that 76% of developers weren't planning to use AI for deployment and monitoring, and 69% weren't planning to use it for project planning. If that's where we were as an industry a year ago, not many seniors around now 😉

As IDEs improved over the years, they sped up our coding by providing autocompletion, code navigation, etc. With AI coding agents, it's different — quite a lot of people say that our time will shift from coding to other activities. And ironically, I bet you've already seen projects that have done less to simplify monitoring and releases for their devs than they're now doing for their machines.

Building a harness? Show me if it's just an instruction to your agent "ask user for review", [Claude Code hooks](https://code.claude.com/docs/en/hooks), or maybe [good old pre-commit hooks that you are sure will execute](https://blog.arkency.com/getting-nondeterministic-agent-into-deterministic-guardrails/) 😉

Running your agent army? Let me know if those are your old laptops or VPSs and whether you tmux to them one by one, delegating some tasks, or maybe use [Claude's Agent Teams](https://code.claude.com/docs/en/agent-teams) or [AMP](https://ampcode.com/news/agents-in-orbs).

Fewer slogans, more specifics.

This is especially important now, when a lot changes literally every week, meaning there are new areas to discover and new ways to work with those tools. Their non-deterministic nature adds some complexity too. There are no best practices, so whatever works for you today is worth sharing. You don't have to worry it will be outdated next month. You don't have to worry about being wrong. On the other hand, it's not out of the question that what you are doing now will stand the test of time and become a best practice sometime 🙂

We are all juniors, and let's have some fun with it!

That said, and as this whole post was about sharing knowledge, here you have some links from us:
* [Piotr about maintaining an organizational knowledge graph with an LLM and event sourcing.](https://blog.arkency.com/maintaining-an-organizational-knowledge-graph-with-an-llm-and-event-sourcing/)
* [Łukasz about getting a nondeterministic agent into deterministic guardrails.](https://blog.arkency.com/getting-nondeterministic-agent-into-deterministic-guardrails/)
* [Szymon on RBQ 2026 about mutation testing becoming critical in the era of AI agents.](https://www.youtube.com/watch?v=Mavtkt79lpA)
* [Tomek about exploring the Event Store with res-mcp.](https://blog.arkency.com/res-mcp-server/)

Last but not least, if you prefer a condensed, one-to-one experience with Arkencers where we focus on your project and on making your team AI-native in the way we see it, you may be interested in this [workshop](https://arkency.com/ai-native-rails/).

See you next time, and remember: together we will all become seniors sometime 🙂
