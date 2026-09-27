---
created_at: 2026-09-27 12:00:00 +0200
author: Piotr Jurewicz
tags: ['ai', 'llm', 'knowledge graph', 'rag']
publish: true
---

# 6 levels of knowledge management maturity in organizations

"Zapomniałem" is Polish for "I forgot".  

On Arkency's Slack, our main communication channel, it has been used over 1200 times.  
And I truly believe I work with exceptionally organized and meticulous people.

<!-- more -->

That only confirms what I wrote in my [previous post](https://blog.arkency.com/maintaining-an-organizational-knowledge-graph-with-an-llm-and-event-sourcing/): _organizations are surprisingly good at forgetting_.  

That post described how we maintain an organizational knowledge graph with an LLM and event sourcing.  
It was about the destination.  
This one is about the road that led us there.

Looking back at how we handle knowledge at Arkency, I identified 6 levels of maturity.  
I presented them yesterday at [Programistok](https://programistok.org) in Białystok, and I am writing this post on the train back home.  

Check where your organization stands.

## Level 0: written sources

You communicate mostly via email and instant messengers.  
You record transcripts of your conversations.  
Agreements made on calls are confirmed in writing: someone posts a note stating what the parties have agreed on.

**This was our starting point**.  
Arkency embraced remote work long before it was cool, and the [async remote](https://blog.arkency.com/async-remote) philosophy has always relied on written artifacts: status updates, meeting summaries, decision records.

## Level 1: one silo

All of the above, and additionally, those written artifacts are not scattered across many tools.  
They land in a single silo.

This is the stage at which you start transcribing meetings automatically and using an LLM to generate summaries.

In our case, we use Slack, and we started recording our meetings on Zoom.  
Configuring a Zapier automation that generates a summary of each meeting and posts it to the right channel took literally 15 minutes, including writing the prompt.  
The prompt is 30 lines long.  
**The cost of reaching this level was close to zero.**

If you know what you are looking for, you will usually find it.  
Sometimes only because you remember a specific word that was said.

## Level 2: semantic search

All of the above, and additionally, you can search your written sources semantically.  
In practice, you no longer need to remember that specific word to find the right piece of data.

At this level, an embedding model turns chunks of your documents into vectors: coordinates on a map of meanings.  
When a question comes in, the most semantically similar chunks are put into the LLM's context, so it can answer questions about data it was never trained on.  
This technique is called [RAG](https://arxiv.org/abs/2005.11401) (Retrieval-Augmented Generation).  
It is hardly news anymore - the idea dates back to 2020 and has been widely adopted since 2023.

**For many companies, level 2 is perfectly enough.**  
If you want to build chatbots or virtual assistants answering specific kinds of questions (customer support, onboarding based on product documentation, policies and regulations), you don't need to go further.  
There is one condition though: the questions have to be **local**.  
The answer has to sit in a single chunk, not be smeared across the whole dataset.  
And the documents should be independent, not describing a network of dependencies, hierarchies or sequences in time.

## Level 3: the LLM organizes knowledge

All of the above, and additionally, you use an LLM to create syntheses of your documents.  
Knowledge about your organization now lives outside the original sources.  
Unstructured data becomes semi-structured.

A perfect example of this level is the [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) proposed by Andrej Karpathy in April 2026.  
His starting point: RAG is in fact a search engine.  
It does not help to organize knowledge in a durable way - the synthesis happens from scratch with every question.  
Instead, he suggests letting an LLM maintain a wiki of interlinked markdown files.

Traditional wikis die because the cost of maintaining them grows faster than the value they bring, and at some point nobody updates them anymore.  
A model doesn't feel that cost.  
It doesn't get bored rewriting the same page for the twentieth time.

You get not only a semantic index, but also a useful artifact that both humans and agents can browse.

The [comments under the gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) point out its weak spots, and the next levels are largely about addressing them.

## Level 4: a knowledge graph

All of the above, but this time the LLM turns unstructured data into formally structured data: a graph of entities and typed relations between them.

The term was popularized by Google in 2012, when they published [_Introducing the Knowledge Graph: things, not strings_](https://blog.google/products-and-platforms/products/search/introducing-knowledge-graph-things-not/).  
The search engine stopped merely matching strings and started recognizing entities.  

In 2024, Microsoft stirred up the RAG world with [GraphRAG](https://arxiv.org/abs/2404.16130).  
They used an LLM to extract nodes and edges from chunks of text, then detected communities in the graph - groups of nodes more strongly connected with each other than with the rest.  
Each community gets a summary.  
When a question comes in, an LLM generates a partial answer from each community summary, filters out the unhelpful ones, and combines the rest into a final answer.  
This way, an LLM can answer **global** questions, like "what are the main themes?" or "what trends can we see?", where the answer is spread over a huge number of sources.  
Plain RAG cannot do that.

Two things are crucial at this level: an ontology that frames the graph and cuts out the noise, and identity resolution that keeps the same entity from appearing as many nodes.  
I covered both in detail in the [previous post](https://blog.arkency.com/maintaining-an-organizational-knowledge-graph-with-an-llm-and-event-sourcing/).

## Level 5: a graph you can rely on

This is where your graph stops being a toy.  
After all, we don't build a knowledge graph for the sake of having one, but for the automations it enables.  
At level 5, your agents work with the graph, traversing it while carrying out complex tasks.

To let that happen, you need solid foundations.  
From my perspective, these are the must-haves:

- **Human in the loop.** The LLM only proposes changes, and a human gets a chance to review them before they land in the graph.
- **Full provenance.** Every fact traces back to its source, and every decision of the model traces back to what it read from the graph.
- **Temporal relations.** Relations between entities change over time, and two sources saying different things do not necessarily contradict each other. The graph should model time frames as attributes of relations.

## Where are you?

At the end of the talk, I asked the audience to raise their hands, level by level.  
When I asked who uses a knowledge graph in their company, only a few hands went up.

Knowledge graphs as a foundation for AI agents are still a fresh topic.  
I'm currently reading _Agentic GraphRAG_ by Anthony Alcaraz and Sam Julien (O'Reilly) - its paperback edition comes out in just two days.  
It expands on much of what I described here as level 5.

And if you want to move your organization up a level or two, [get in touch](https://arkency.com/hire-us/).

Last but not least, big thanks to the organizers of [Programistok](https://programistok.org) for a great conference and for having us in Białystok.

<img src="<%= src_fit("6-levels-of-knowledge-management-maturity/20260926_173129.jpg") %>" width="100%">

_From the left: me, Tomek, Piotrek and Maciej._
