---
created_at: 2026-02-20 12:20:24 +0100
author: Łukasz Reszke
tags: []
publish: false
---

# Getting nondeterministic agent into deterministic guardrails

AI agents don't reliably follow your instructions. Here's how I made it hurt less.

<!-- more -->

My context:
* I currently work on a 12-year-old Rails legacy code base
* The code base is undergoing modernization. Some of the large Active Record classes have been split into smaller ones, each into its own bounded context. Events are becoming a first-class citizens in the code. We also pay close attention to keep direction of dependencies as designed by context maps.
* The client has a GitHub Copilot subscription. I mostly use Sonnet and Opus models.

## The basic setup

Initially I started with the basics. I was curious where it would get us. There's an AGENTS.md file with general rules to follow. Besides the AGENTS.md file I've added a few skills.
The goal of the skills is to tell the agent about how it should write code. I am a big fan of [Szymon's way of using RSpec](https://blog.arkency.com/test-which-reminded-me-why-i-dont-really-like-rspec/). So I put that into a skill. I also developed a few skills that tell the agent how I want it to deal with event sourcing, ddd technical patterns, hotwire, backfilling data (especially events) and mutation testing. The mutation skill is quite essential because without it the agent goes bananas and tries to achieve 100% of mutation coverage with hacking. 

An example of hacking is calling `send(:method)`. 

I don't want to have such tests. Trying to achieve mutation coverage in such a way indicates that perhaps the code should be removed because it's just unnecessary noise.

So now the question is, is that enough?

## It's pretty good but can be better – tackling non-determinism

More than once (a day) I've experienced my agent to go off-rails and ignore my instructions. It doesn't respect what I've specified in AGENTS.md and/or skills.

It often happens when I am asking it to introduce a very similar-yet-a-little-bit-different command and handler for a specific business use case.

Changes to the production code are going very well. This is especially true if the goal is to replicate well-structured code. However, once it gets to the "write the tests" part, it switches to commodity mode and most likely uses RSpec in the most popular way, which I don't like. This is a large part of the existing codebase. If it doesn't fail on writing tests the way I want it, it usually doesn't run mutation testing, even though I expect the coverage not to drop below a certain point and the mutants to be eliminated. They should be killed properly.
Using the `send` method is no bueno.

### Dealing with non-determinism

So we're not able to change whether the agent will respect AGENTS.md and skills all the time. At least not yet. Maybe never. So we have to deal with it differently.

What I am currently testing is to have guardrails aka dev workflows. The idea is to run tools that:
- Will make me focus less on code structure, incorrect formatting, etc
- Make sure tests for changed files are run
- Make sure mutation tests are run
- And, last but not least, make sure that the boundaries within bounded contexts are not violated. I noticed that the agent, just like humans, loves to take shortcuts to achieve a goal. The difference is that I never tell the agent we're under a strict deadline. So I'm not sure where this choice is coming from.

The workflow is Ruby code that is wired to a `/verify` custom command. The command runs bash with `ruby -r ./lib/dev_workflow.rb`.

The `dev_workflow.rb` orchestrates the full pipeline. Looking at its requires tells you everything about what it runs:

```ruby
require_relative 'dev_workflow/step_result'
require_relative 'dev_workflow/result'
require_relative 'dev_workflow/changed_files'
require_relative 'dev_workflow/steps/base'
require_relative 'dev_workflow/steps/rubocop_step'
require_relative 'dev_workflow/steps/rspec_step'
require_relative 'dev_workflow/steps/mutant_step'
require_relative 'dev_workflow/steps/eslint_step'
require_relative 'dev_workflow/steps/jest_step'
require_relative 'dev_workflow/verify_build'
```

Each step follows the same pattern: check if relevant files changed, run the tool, return a structured result. Here's the mutation testing step as an example — the one that matters most given the problems I described earlier:

```ruby
class MutantStep < Base
  ALLOWED_NAMESPACES = %w[CRM Ordering Billing].freeze

  def call
    unless changed_files.any_ruby?
      return StepResult.skipped(name: name, skip_reason: 'no ruby files changed')
    end

    subjects = mutation_subjects
    if subjects.empty?
      return StepResult.skipped(name: name, skip_reason: 'no mutant-eligible files changed')
    end

    result, duration = measure_duration do
      run_mutant(subjects)
    end

    output, success = result

    if success
      StepResult.success(name: name, duration_seconds: duration, files_checked: subjects.size)
    else
      errors = parse_mutant_output(output)
      StepResult.failure(name: name, duration_seconds: duration, files_checked: subjects.size, errors: errors)
    end
  end

  private

  def run_mutant(subjects)
    subject_args = subjects.map { |s| "'#{s}'" }.join(' ')
    run_command("bundle exec mutant run --since HEAD #{subject_args}")
  end

  def mutation_subjects
    changed_files.ruby_files
      .reject { |f| f.start_with?('spec/') }
      .filter_map { |f| file_to_subject(f) }
      .select { |subject| eligible_namespace?(subject) }
      .uniq
  end
end
```

The key detail is `StepResult`. Each step returns either `.skipped`, `.success`, or `.failure` with structured data. This is what the agent reads to understand what went wrong and what to fix.

Last but not least, to make sure that the non-deterministic agent won't ignore my desire to run this command by itself, I attached it to a git pre-commit hook:

```ruby
#!/usr/bin/env ruby

require_relative "../lib/dev_workflow"

result = DevWorkflow::VerifyBuild.call(staged_only: true)

puts result.to_json

exit(result.success? ? 0 : 1)
```

And at this point, at least calling the verify method is deterministic. So the agent gets feedback, fixes whatever is reported by the tool, reruns the verification and then it's able to commit the changes.

## Reviewing changes

Besides AGENTS.md, SKILLS.md and the workflow I described above, I still review the code. I focus on tests, architecture and security parts.
I do take full ownership of the code that I ship. I don't trust the AI enough to cut the leash. And my conclusion from working with it in a legacy codebase is currently that it will not change that fast (for me).
