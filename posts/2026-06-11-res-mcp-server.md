---
created_at: 2026-06-11T10:00:00.000Z
author: Tomasz Patrzek
tags: [res, ruby, rails]
publish: false
---

# Give Your AI Assistant Access to the Event Store with `res-mcp`

When you're debugging with an AI assistant, half the work is feeding it context — copy-pasting events, stream contents, and IDs into the chat so it has something to reason about. A new contrib gem — `ruby_event_store-mcp` — cuts that out. It exposes your event store as [MCP tools](https://modelcontextprotocol.io/) that AI assistants (Claude, etc.) can call directly: you ask in plain English, the assistant reads the events itself.

<!-- more -->

## Setup

Add the gem and install:

```ruby
gem "ruby_event_store-mcp"
```

```
bundle install
```

That installs the `res-mcp` binary — but it doesn't register anything with your AI client yet. The binary speaks MCP over **stdio**, launched from your app's root, where it loads `config/environment.rb` and reads the same `Rails.configuration.event_store` your app uses. There's no HTTP endpoint to mount and nothing to deploy. Telling your client about it is a separate, one-time step — and every MCP client takes the same server definition, only the file it goes in changes.

**Claude Code** — drop a `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "res": {
      "command": "bundle",
      "args": ["exec", "res-mcp"]
    }
  }
}
```

(or run `claude mcp add res -- bundle exec res-mcp`). Launched from the project directory, Claude Code runs the server there, so no `cwd` is needed. On the next launch it asks you to trust the project's MCP server — approve it, then run `/mcp` to see `res` connected with its nine tools.

**Claude Desktop** — the same block, but with an explicit `cwd` pointing at your app's root, in `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "res": {
      "command": "bundle",
      "args": ["exec", "res-mcp"],
      "cwd": "/path/to/your/rails/app"
    }
  }
}
```

(macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`; Windows: `%APPDATA%\Claude\claude_desktop_config.json`.)

**Other MCP clients** — Cursor, Windsurf, Cline and the rest take the same `mcpServers` block in their own config file; VS Code's built-in MCP uses a `servers` key with `"type": "stdio"` instead. The `bundle exec res-mcp` command is the portable part.

That's the whole setup. No routes, no mounts, no credentials.

## What you can ask

Once it's connected you just talk to the assistant — **no slash command, no skill**. You ask in plain English and it decides which tools to call (the first call asks your permission; allowlist the `res` server to stop being asked).

The server gives the assistant nine **read-only** tools over your event store. You never call them by name — you ask a question, and the assistant picks the tools it needs. They cover three kinds of questions:

**Browse streams and events**

- `stream_show` — a stream's event count, version, and first/last event
- `stream_events` — the events in a stream, filterable by type, time, or position
- `event_show` — one event in full, data and metadata
- `event_streams` — every stream a given event belongs to

**Search and summarize**

- `recent` — the most recent events across the whole store ("what just happened?")
- `search` — events anywhere, filtered by type, time range, or stream
- `stats` — total counts and the unique event types present

**Follow a process**

- `aggregate_history` — the full event history of one aggregate instance (e.g. a single `Fulfillment::Order`)
- `trace` — the causation tree of everything sharing a correlation ID, so you can see where a multi-step flow stopped

## Examples

Once it's wired up, you debug by asking:

> "What just happened? Show the 20 most recent events."

> "Walk me through the history of Fulfillment::Order f47ac10b-58cc-4372-a567-0e02b2c3d479."

> "Are there any OrderPlaced events from the last hour without a matching OrderConfirmed?"

> "Trace correlation 452fd6f0-e3a2-4716-bc8a-43bbcf2cae61 — where did the process stop?"

The assistant calls `recent`, `aggregate_history`, `search`, or `trace` behind the scenes, reads the results, and reasons over them — no copy-pasting event payloads into the chat, no switching to a Rails console mid-thought.

## Why it's safe to point at any app

Every tool goes through the public `event_store.*` API — the same one you use in application code, read from `Rails.configuration.event_store`. No raw SQL, no ActiveRecord internals, no adapter-specific hacks. And the tools are **read-only**: the assistant can inspect your events but can't append, link, or delete anything. The worst it can do is read — so you can connect it without worrying about an assistant mutating your store.
