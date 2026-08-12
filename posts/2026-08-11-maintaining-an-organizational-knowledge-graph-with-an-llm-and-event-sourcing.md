---
created_at: 2026-08-11 12:00:00 +0200
author: Piotr Jurewicz
tags: ['ai', 'llm', 'knowledge graph', 'rails event store', 'ruby_llm']
publish: false
---

# Maintaining an organizational knowledge graph with an LLM and event sourcing

Organizations are surprisingly good at forgetting.  
Decisions are made on calls, insights get buried in Slack threads, and a month later no one remembers why things are the way they are.

<!-- more -->

At Arkency, I had a feeling that some things slip away from us too from time to time.  
Weekly calls, ad-hoc meetings, our book clubs, Slack discussions, GitHub mentions, e-mail inbox - we could use some support in organizing all those signals.

Then Ruby Community Conference 2026 happened in March.  
In Kraków, **Obie Fernandez** showed some parts of his NEXUS system.  
He had already described it [on his blog](https://obie.medium.com/what-used-to-take-months-now-takes-days-cc8883cc21e9) back in January, but the conference was where I first came across it.  
That was the push I needed to start building our own software.

When it was already taking shape, Andrej Karpathy published his [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) note.  
Instead of a RAG system rediscovering your documents on every query, an LLM incrementally maintains a persistent wiki: interlinked markdown pages, immutable sources underneath, and a human curating the loop.  
It was quite exciting to realize I was working on something that had just become one of the hottest topics in the industry.

We ended up with _Planet Arkency_ - a **knowledge graph with a closed ontology**, built on Rails Event Store.  
In this post, I want to walk you through the design decisions I made.

## Unstructured input is where LLMs actually shine

For structured data, you could have built such a system like twenty years ago.  
Webhooks, forms, integrations - parsing structured input into a graph is a solved problem.  
The input that was never solved is the one with the most interesting knowledge inside: meeting transcripts, Slack discussions, emails, or anything coming from an integration nobody has built yet.  
This is where LLMs changed the game for us.

Everything flows into the system through a single ingestion endpoint.  
Transcripts, Slack threads someone flagged with a dedicated emoji reaction, emails arriving at a bridge inbox, RSS feeds, calendar invites, personal notes.  
**We don't even write code for the integration points.**  
Tools like Zapier or n8n watch the sources and push the content to that single endpoint.

Every ingested piece of content then goes through an **extraction** - the heart of the system.  
An LLM reads the content and works out what it means for our knowledge: which entities appear in it, what we learned about them, and how they relate to each other.  
Most of this post is about what happens around that single step.

## Why a graph?

The same names keep coming back in our conversations: people, projects, clients, tools, decisions.  
What changes from week to week is what we know about them and how they relate to each other.  
That maps naturally to a graph: entities with attributes, connected by typed relations.  
Who works on what.  
Who made which decision, and when.  
Which project depends on which tool.

This is where we differ most from the LLM Wiki approach.  
In a wiki, the fact that someone works on some project is written down in a sentence on a page, at best with a link between the two pages.  
The knowledge is there, but only a reader can make use of it.  
In a typed graph, `person --works_on--> project` is a piece of data: you can query it, traverse it, count it.

The graph itself sits on PostgreSQL: a `nodes` table, an `edges` table with a unique `(source, target, relation)` triple, `jsonb` attributes on both.  
No rocket science here.  
Dedicated graph databases (Neo4j, triple stores like the one NEXUS uses) could be a better fit for some specific workloads, like deep multi-hop traversal.  
But that is a storage detail - the kind you could change later by writing another adapter for the data layer.

### The ontology

Which kinds of nodes and relations may exist is defined in an **ontology**, stored in a plain YAML file:

```yaml
# from config/ontology.yml
node_kinds:
  - kind: person
    description: "team member, candidate, client contact, external person"
  - kind: decision
    description: "formal decision requiring group verdict — for casual suggestions use idea"
edge_relations:
  - relation: works_on
    signature: "person --works_on--> project"
```

The ontology is closed - if a kind or relation is not on the list, the model cannot use it.  
Initially I was thinking about an open ontology, where the LLM could introduce its own types.  
It brought complete chaos into the graph surprisingly fast.  
In my opinion, it is better to tell the model upfront what to look for.

### Not one graph, but many

_"The organizational knowledge graph"_ suggests one universal graph for all different purposes.  
We don't believe in that, and DDD practitioners will recognize why.

We use multi-tenant architecture to maintain separate graphs with their own ontologies, which really means their own ubiquitous languages.  
Our internal Arkency graph speaks in people, projects and decisions - a domain quite close to a CRM.  
The graph we run as Rails Event Store maintainers speaks in releases, known problems and community content:

<img src="<%= src_original("arkency-planet/ontology.png") %>" width="100%">

Different domains, different vocabularies, the same machinery underneath.  
The boundaries of a bounded context tell you where one graph ends and another begins.

## What comes out of an extraction

The ontology is rendered into the extraction prompt as markdown tables and into the schema as enums.

```erb
(from app/lib/prompts/extraction.md.erb)

You are an organizational knowledge analyst for <%%= Tenancy.current_tenant.name %>. We are building an internal knowledge graph.

Extract a knowledge graph from the provided content: nodes and edges. The graph should allow full reconstruction of the provided content.

## Nodes

Each node has: name, kind, short_description, description, attrs (optional key-value pairs).

Allowed kinds:

| kind | what it represents | typical attrs |
|---|---|---|
<%% ontology.node_kinds.each do |k| -%>
| <%%= k.fetch("kind") %> | <%%= k.fetch("description") %> | <%%= k.fetch("attrs", []).then { |attrs| attrs.empty? ? "—" : attrs.map { |a| a.is_a?(Hash) ? (a["values"] ? "#{a["name"]} (#{a["values"].join(", ")})" : a["name"]) : a }.join(", ") } %> |
<%% end -%>

## Edges

Each edge has: source, target, relation, context, attrs (optional key-value pairs).

Allowed relations:

| relation | source kind | target kind | hint | attrs |
|---|---|---|---|---|
<%% ontology.edge_relations.each do |r| -%>
<%%
  sig = Ontology.parse_signature(r.fetch("signature"))
  source_kind = sig[:source].join(" / ")
  target_kind = sig[:target].join(" / ")
  hint = r["hint"] || "—"
  attrs = r.fetch("attrs", []).then { |a| a.empty? ? "—" : a.map { |at| at.is_a?(Hash) ? (at["values"] ? "#{at["name"]} (#{at["values"].join(", ")})" : at["name"]) : at }.join(", ") }
-%>
| <%%= r.fetch("relation") %> | <%%= source_kind %> | <%%= target_kind %> | <%%= hint %> | <%%= attrs %> |
<%% end -%>

...
```

Each extraction ends with the model returning **one structured result**: the entities it found in the content, the relations between them, and how the existing graph should change to reflect them.  
We use [RubyLLM's schema support](https://rubyllm.com/chat/#using-rubyllmschema-recommended) for that.

```ruby
# from app/lib/extraction_result_schema.rb
array :nodes, description: "Entities to create or update. Each name must be unique — no duplicate nodes." do
  object do
    string :status, enum: ["new", "existing"], description: "'existing' iff the node was returned by search_nodes/list_nodes_by_kind/get_node_edges and you are reusing it. 'new' if you are introducing it. The system verifies the canonical name and aborts on mismatch."
    string :name, description: "Entity name. For 'existing' nodes use the EXACT canonical name from the tool call result. For 'new' nodes the canonical name you are introducing."
    string :new_name, required: false, description: "Optional. Set ONLY for 'existing' nodes when the content reveals a more explicit canonical form (e.g. acronym → full term, diminutive → full name). The node is looked up by `name` and renamed to `new_name`."
    string :kind, description: "Must be one of: #{kind_names}"
    string :short_description, description: "Stable synthesis of what this entity is (for search). General and identity-focused, not episode-specific. Max 15 words."
    string :description, description: "For new nodes: brief description based on the content. For existing nodes: synthesize prior description with new information. Rewriting for clarity is fine, but preserve prior facts."
    array :attrs, description: "Key-value attributes. Only include what is known from the content." do ... end
    array :aliases, required: false, description: "Optional. Alternative surface forms (diminutives, acronyms, full vs short forms) under which this entity was referred to in the content, or — when renaming via `new_name` — the old canonical if it remains a valid surface form. Only include NEW aliases not already present on the existing node. An alias is the SAME entity under another name — never a separate entity." do ... end
  end
end

array :edges, description: "ALL relationships. Be thorough and precise." do
  object do
    string :source, description: "Source node name (exact match — existing or newly created)"
    string :target, description: "Target node name (exact match — existing or newly created)"
    string :relation, description: "Must be one of: #{relation_names}"
    string :context, description: "Briefly explain why this relationship exists, grounded in the content"
    array :attrs, description: "Key-value attributes for this edge (e.g. since, weight)" do ... end
  end
end
```

Actual data operations (create or update, with the exact field-level diff) are derived server-side.  
We load or initialize an ActiveRecord model, assign what the LLM returned, and let dirty tracking do the rest:

```ruby
# from app/handlers/propose_graph_change.rb
node = Node.find_or_initialize_by(name: data[:name])
enforce_status!(data[:name], data[:status], node) # raises when the model's new/existing claim disagrees with the DB

was_new = node.new_record?
node.assign_attributes(short_description: ..., description: ..., attrs: node.attrs.merge(attrs))
changes = node.changes.except("updated_at", "created_at", "kind", "slug")

{ op: was_new ? "create" : "update", node_id: node.persisted? ? node.id : nil, changes: changes }
```

`node.changes` gives us `{field => [before, after]}` pairs for free, and this before/after snapshot becomes the wire format of the graph change proposal.  
Edges get exactly the same treatment - looked up by their `(source, target, relation)` triple and diffed with dirty tracking.

<img src="<%= src_original("arkency-planet/extraction-result.png") %>" width="100%">

We also don't blindly trust what the LLM claims.  
It has to declare each node as `new` or `existing`, and a validator cross-checks it against the database.  
On mismatch, the LLM gets natural-language feedback and another attempt on the same conversation.

## Identity resolution is the hard part

I just wrote that the model has to declare each node as `new` or `existing`.  
But how would it know?  
Do we load the whole graph into LLM context?  
No - this is where **tool calls** come in.

And it is harder than a simple lookup.  
"Piotrek", "Piotr Jurewicz" and whatever Zoom's transcription makes out of my name are the same person.  
If you create a node per surface form, your graph turns into garbage within a week.

We handle it on three levels.

**First, the model must look before it writes.**  
During extraction it has access to read-only tools like `search_nodes` or `get_node_edges`.  
The extraction prompt is explicit about it:

```
(from app/lib/prompts/extraction.md.erb)
- Before creating any node, use search_nodes to check if it already exists. (...)
- If search_nodes returns no results, the node does not exist yet — proceed to create it. (...)
- If search_nodes returns ambiguous results, or you need broader context to make extraction decisions, use get_node_edges to inspect the node's connections.
- After finding nodes with search_nodes, use get_node_edges to see their existing relationships before deciding how to connect them.
```

**Second, aliases are the identity mechanism.**  
Each node has one canonical name and any number of aliases.  
The schema instructs the model that an alias is the same entity under another name - never a separate entity.  
When the content reveals a better canonical form, the model sets `new_name` and the old name stays as an alias, so future fuzzy searches still resolve it.

**Third, the search is hybrid.**  
Trigram similarity (pg_trgm with GIN indexes) over node names *and* aliases catches misspellings.  
Embedding search catches semantic matches which share no characters:

```ruby
# from app/models/node.rb
def self.hybrid_search(query, limit: 10)
  # fuzzy match on canonical names and aliases, powered by pg_trgm
  by_name  = where("similarity(nodes.name, ?) > 0.3", query)
  by_alias = joins(:aliases).where("similarity(node_aliases.name, ?) > 0.3", query)
  trigram_results = union_by_best_similarity(by_name, by_alias)

  response = RubyLLM.embed(query, model: "bge-m3", provider: :ollama)
  semantic_results =
    nearest_neighbors(:embedding, response.vectors, distance: "cosine")
      .select { |n| n.neighbor_distance < SEMANTIC_THRESHOLD }

  merge_and_rank(trigram_results, semantic_results, limit)
end
```

The embeddings come from a self-hosted `bge-m3` model on Ollama, stored in pgvector.

## Every fact has a source

A graph edited by an AI is only trustworthy if you can audit every change.  
For every node and edge we can answer: which extraction created you, which extractions updated you, and what exactly changed each time.

Provenance lives in join tables (`node_extractions` and `edge_extractions`): one row per extraction and entity pair, holding the operation, the status, and the field-level `diff` produced by the dirty tracking described before.  
Starting from any node, you can walk back through these rows to the extraction that touched it, and from the extraction to the ingested content it was based on.  
Every fact in the graph traces back to its source.

We also record something we call the **read set**.  
Every tool call the model makes during extraction is published as an `ExtractionToolCalled` event and projected into `tool_invocations`, linked to the nodes and edges the call returned.  
So we know not only what an extraction wrote, but also what it read before deciding.  
When you wonder "why did the model merge these two people?", the answer is on the extraction page: here is the search it ran, and here is what came back.

<img src="<%= src_original("arkency-planet/tool-calls.png") %>" width="100%">

Each node's page shows its full history: created in, last updated in, read by N extractions.

<img src="<%= src_original("arkency-planet/provenance.png") %>" width="100%">

## Keeping an eye on the costs

Besides auditing changes in the graph, we also track how much each extraction costs: token usage and the resulting price.  
When you work with an LLM API, it is worth keeping a hand on the pulse here.  
A transcript of a few hours of conversation, processed in multiple rounds interleaved with tool calls, can generate serious costs.  
[Prompt caching](https://rubyllm.com/chat/#anthropic-prompt-caching) helps a lot - the system prompt and the content stay identical between rounds, so most of the input is billed at the cache-read rate.

The exact numbers depend on the model you run the extraction on, but most of ours fit within a dozen or so cents.

<img src="<%= src_original("arkency-planet/extractions-cost.png") %>" width="100%">

## Human in the loop

We don't let the LLM write to the graph directly.  
Extraction produces a **proposal** with the before/after diffs, and applying it to the graph is a separate step.

Proposals can sit in a review window before they get applied.  
As soon as an extraction completes, we get a short summary of it on Slack.  
A human can inspect the diff, apply it early, or just let it flow after the configured delay.

Time passes between propose and apply, so the graph may have moved in the meantime.  
When the current state no longer matches what the proposal was based on, the apply stops and the affected rows get marked as conflicted, with a human-readable explanation.

## Event sourcing ties it all together

You may have noticed that every mechanism above was described in terms of events.  
Well, this is an Arkency blog after all.

The whole pipeline is an event flow: `TranscriptIngested` → `ExtractionRequested` → `KnowledgeExtracted` → `GraphChangeProposed` → `GraphChangeApplied` (or `GraphChangeConflicted`).  
Two small aggregates guard the invariants: one per ingestion (no two concurrent extractions of the same content), one per extraction (the propose → apply state machine).  
Everything you see in the UI (ingestions, extractions, diffs, tool invocations) is a read model built from these events.

In this architecture, the review window is just one more state in the aggregate's state machine, and provenance is just one more read model built from an event we already had.  
I cannot understand people claiming that event sourcing makes things more complex ;)

## The graph can feed itself

One feature shows the value of a uniform pipeline well.  
From any node you can request research.  
A job asks a model equipped with Anthropic's server-side `web_search` and `web_fetch` tools to compile a brief about the entity:

```ruby
# from app/jobs/research_topic.rb
chat = RubyLLM
  .chat(model: MODEL)
  .with_params(tools: [
    { type: "web_search_20250305", name: "web_search", max_uses: 10 },
    { type: "web_fetch_20250910", name: "web_fetch", max_uses: 10 }
  ])
  .with_schema(ResearchBriefSchema.build)
```

The prompt grounds the research in what the graph already knows about the entity, and tells the model when to give up:

```
# from app/jobs/research_topic.rb
Research "#{topic}". Use web_search and web_fetch as needed to gather facts.

In our knowledge base this entity is currently described as:
- Kind: ...
- Short description: ...
- Attributes: ...

When you can produce a useful brief, return status="completed" and put the
brief in `brief` as Markdown. (...) Cover identity, key facts a knowledgeable
reader should know, recent activity worth recording, and relationships to
other named entities. Include source URLs inline next to claims that come
from a specific page. Keep it factual; do not speculate.

Return status="aborted" instead — with `abort_reason` naming the specific
problem — when any of these holds:
- The topic is ambiguous and you cannot confidently pick the intended
  interpretation from the disambiguation context above.
- You cannot find substantive, verifiable information about this exact
  entity (...)

Do not pad an aborted result with related-but-different information.
```

The resulting brief is not applied to the graph directly.  
It gets published as a regular `TranscriptIngested` event with its own kind, and flows through the same extraction, proposal and review pipeline as any other input.

## The graph speaks MCP

The graph is not locked inside its own UI.  
We expose it over **MCP**, so any AI assistant with access to our server can search it by asking questions in natural language - and answer from the graph, with sources.

## Final thoughts

Working on Planet Arkency taught me a lot.  
About graphs, about LLMs, and about concepts I had never even heard of before: ontologies, identity resolution, provenance.  
I hope some of that knowledge stays with you after reading this post.

It also reassured me about the tools we have been using at Arkency for years.  
Event-driven architecture and Rails Event Store carried this project naturally.

I still have a head full of ideas on where to take this project next.

Working with [RubyLLM](https://rubyllm.com) was a pure pleasure - credits to Carmine Paolino for this gem.

If you are thinking about organizational memory for your company, or want us to help you build one, [get in touch](https://arkency.com/hire-us/).
