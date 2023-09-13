---
created_at: 2023-09-13 10:00:00 +0200
author: Paweł Pacana
tags: %w[ruby testing]
publish: false
---

# Six ways to prevent a monkey-patch drift from the original code

Monkey-patching in short is modifying external code, whose source we don't directly control, to fit our specific purpose in the project. When modernising framework stack in "legacy" projects this is often a necessity when upgrade of a dependency is not yet possible, or would involve moving too many blocks at once.

It's a short-term solution to move things forward. The reward we get from monkey-patching is instant. The code is changed without asking for anyone's permission and without much extra work that a dependency fork would involve.

But it comes with a hefty price of being very brittle. We absolutely cannot expect that a monkey-patch would work with any future versions of the external dependency. Thus communicating this short-term loan is crucial when we're not soloing.

## Guarding patched dependency changes with version check

One way to communicate a monkey-patched dependency is to document it with a test.

Why test?

1. It is close to the changed code — in project source, as opposed to any external documentation medium.

2. It is executable, unlike code comment and greatly reduces the risk of someone [not noticing an announcement](https://www.goodreads.com/quotes/379100-there-s-no-point-in-acting-surprised-about-it-all-the).

In a project I've recently worked on there was already an unannounced `AcitveRecord::Persistence#reload` method patch inside `User` model. I consider myself very lucky spotting within over 910000 lines of code having only 10% test coverage.

A code comment would definitely not help me noticing it, coming to this project only recently and the authors were already working on something else too.

A test I've added to document it looked like this:

```ruby
# spec/models/user_spec.rb

require "rails_helper"

RSpec.describe "User" do
  specify "#reload method is overridden based on framework implementation" do
    expect(Rails.version).to eq("5.1.7"), failure_message
  end

  def failure_message
    <<~WARN
      It looks like you upgraded Rails.
      Check if User#reload method body corresponds to the current Rails version implementation of rails/activerecord/lib/active_record/persistence.rb#reload.
      When it's ready bump the version in this condition.
    WARN
  end
end
```

Now whenever Rails version changes, this check is supposed to fail. The failure has a descriptive message instructing what needs to be checked in order to prolong the patch.

Within an organisation relying on Continuous Integration and aspiring to testing culture this is should be enough to prevent failure from such patching.

But is it enough developer friendly?

## Improving version check

One drawback of strict version checks is ...being too strict. Some dependencies are best allowed within a range of possible versions. To not fail the check on version changes mitigating security issues for example:

```diff
--- spec/app/models/user_spec.rb
+++ spec/app/models/user_spec.rb
@@ -4,7 +4,7 @@ require 'rails_helper'

-    expect(Rails.version).to eq('7.0.7'), failure_message
+    expect(Rails.version).to eq('7.0.7.2'), failure_message
+    # Mitigate CVE-2023-38037
+    # https://discuss.rubyonrails.org/t/cve-2023-38037-possible-file-disclosure-of-locally-encrypted-files/83544
```

When we're certain that a dependency follows a meaningful version numbering scheme, we can change the check to verify more relaxed version constraints.

An example using RubyGems API:

```diff
--- spec/app/models/user_spec.rb
+++ spec/app/models/user_spec.rb
@@ -4,7 +4,7 @@ require 'rails_helper'

-   expect(Rails.version).to eq('7.0.7.2'), failure_message
+   expect(Gem::Requirement.create('~> 7.0.0').satisfied_by?(Gem::Version.create(Rails.version))).to eq(true), failure_message
```

But do we know for sure that a security-patch-release does not change the code we've patched?

## Checking if the source did not change

It would be ideal if we could peek into the source of the method we're patching and tell if it has changed since the original one.

Reading a tweet from my [former arkency fellow](https://blog.arkency.com/authors/robert-pankowecki/) shed new light on the issue.

<% link_to "https://twitter.com/pankowecki/status/1687103206713962497", target: "_blank", rel: "noreferrer" do %> 
  <img src="<%= src_fit("six-ways-mp/tweet-1687103206713962497.png") %>" width="100%">
<% end %>

A complete test utilising this technique may look like this:

```ruby
# spec/models/user_spec.rb

require "rails_helper"

RSpec.describe "User" do
  specify "#reload method is overridden based on framework implementation" do
    expect(checksum_of_actual_reload_implementation).to eq(
      checksum_of_expected_reload_implementation,
    ),
    failure_message

    private

    def checksum_of_actual_reload_implementation
      Digest::SHA256.hexdigest(
        ActiveRecord::Persistence.instance_method(:reload).source,
      )
    end

    def checksum_of_expected_reload_implementation
      "3bf4f24fb7f24f75492b979f7643c78d6ddf8b9f5fbd182f82f3dd3d4c9f1600"
    end

    def failure_message
      #...
    end
  end
end
```

The little disappointment came shortly after I've realised [Method#source is not a standard Ruby](https://twitter.com/mostlyobvious/status/1694700843629478389). It is from a `method_source` [dependency](https://github.com/banister/method_source/tree/master) that came to the project I've worked on indirectly via `pry`. Nevertheless it worked within the scope of existing project dependencies and was better than a plain version check.

Can we do any better?

## Checking Abstract Syntax Tree of the implementation

I admit that computing hash of the source code is neat. However it falls short of "formatting" changes. Source code is a textual representation. Introducing whitespace characters — spaces or line breaks, does not change the implementation. It behaves exactly the same. The hash will be different though, raising false negative.

So can we do it better? Yes we can, with little help of [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree). In theory and AST representation should free us from how the patched code is formatted.

In Ruby we have a few options to render AST of the source code. The popular `parser` and `syntax_tree` gems. The `Ripper` in the standard library. Or the native `RubyVM::AbstractSyntaxTree`.

A pessimist may notice their limitations first:

- `RubyVM::AbstractSyntaxTree` and `Ripper` still include formatting in the output, defeating the purpose

- `parser` and `syntax_tree` are external dependencies, so not universally applicable — chances are they're already a transitive dependency in your project

I definitely did not see it all on first sight. Here are the implementations I would not recommend.

### False hopes for checksum free from formatting

In core Ruby there is `RubyVM::AbstractSyntaxTree` [module](https://ruby-doc.org/core-trunk/RubyVM/AbstractSyntaxTree.html), which provides methods to parse Ruby code into abstract syntax trees. Unfortunately the output includes line and column information, making it unfit for checksumming independent of source formatting. Thus it is not better in any aspect then hexdigest on plain source code. 

```ruby
# spec/models/user_spec.rb

require "rails_helper"

RSpec.describe "User" do
  specify "#reload method is overridden based on framework implementation" do
    expect(checksum_of_actual_reload_implementation).to eq(
      checksum_of_expected_reload_implementation,
    ),
    failure_message
  end

  private

  def checksum_of_actual_reload_implementation
    Digest::SHA256.hexdigest(
      RubyVM::AbstractSyntaxTree.parse(
        ActiveRecord::Persistence.instance_method(:reload).source,
      ).pretty_print_inspect,
    )
  end

  def checksum_of_expected_reload_implementation
    "ed2f4fdf62aece74173a44a65d8919ecf3e0fca7a5d38e2cefb9e51c408a4ab4"
  end
end
```

### No checksum for the added benefit of seeing actual implementation changes

In Ruby standard library we may also find `Ripper`, a [Ruby script parser](https://ruby-doc.org/stdlib-3.0.0/libdoc/ripper/rdoc/Ripper.html). It parses the code into a [symbolic expression tree](https://en.wikipedia.org/wiki/S-expression). Unfortunately this too containts line and column information in the output. Perhaps with some additional post-processing step we could get rid of it. I prefer comparing s-expressions to checksums — on failure the test framework has a chance to show differences in the syntax tree. Which is a nice bonus!

```ruby
# spec/models/user_spec.rb

require "rails_helper"

RSpec.describe "User" do
  specify "#reload method is overridden based on framework implementation" do
    expect(actual_find_record_implementation).to eq(
      expected_find_record_implementation,
    ),
    failure_message
  end

  private

  def actual_reload_implementation
    Ripper.sexp(ActiveRecord::Persistence.instance_method(:reload).source)
  end

  def expected_reload_implementation
    [
      :program,
      [
        [
          :def,
          [:@ident, "reload", [1, 8]],
          [
            :paren,
            [
              :params,
              nil,
              [
                [
                  [:@ident, "options", [1, 15]],
                  [:var_ref, [:@kw, "nil", [1, 25]]],
                ],
              ],
              nil,
              nil,
              nil,
              nil,
              nil,
            ],
          ],
          [
            :bodystmt,
            [
              [
                :call,
                [
                  :call,
                  [
                    :call,
                    [:var_ref, [:@kw, "self", [2, 6]]],
                    [:@period, ".", [2, 10]],
                    [:@ident, "class", [2, 11]],
                  ],
                  [:@period, ".", [2, 16]],
                  [:@ident, "connection", [2, 17]],
                ],
                [:@period, ".", [2, 27]],
                [:@ident, "clear_query_cache", [2, 28]],
              ],
              [
                :assign,
                [:var_field, [:@ident, "fresh_object", [4, 6]]],
                [
                  :if,
                  [
                    :method_add_arg,
                    [:fcall, [:@ident, "apply_scoping?", [4, 24]]],
                    [
                      :arg_paren,
                      [
                        :args_add_block,
                        [[:var_ref, [:@ident, "options", [4, 39]]]],
                        false,
                      ],
                    ],
                  ],
                  [
                    [
                      :method_add_arg,
                      [:fcall, [:@ident, "_find_record", [5, 8]]],
                      [
                        :arg_paren,
                        [
                          :args_add_block,
                          [[:var_ref, [:@ident, "options", [5, 21]]]],
                          false,
                        ],
                      ],
                    ],
                  ],
                  [
                    :else,
                    [
                      [
                        :method_add_block,
                        [
                          :call,
                          [
                            :call,
                            [:var_ref, [:@kw, "self", [7, 8]]],
                            [:@period, ".", [7, 12]],
                            [:@ident, "class", [7, 13]],
                          ],
                          [:@period, ".", [7, 18]],
                          [:@ident, "unscoped", [7, 19]],
                        ],
                        [
                          :brace_block,
                          nil,
                          [
                            [
                              :method_add_arg,
                              [:fcall, [:@ident, "_find_record", [7, 30]]],
                              [
                                :arg_paren,
                                [
                                  :args_add_block,
                                  [[:var_ref, [:@ident, "options", [7, 43]]]],
                                  false,
                                ],
                              ],
                            ],
                          ],
                        ],
                      ],
                    ],
                  ],
                ],
              ],
              [
                :assign,
                [:var_field, [:@ivar, "@association_cache", [10, 6]]],
                [
                  :method_add_arg,
                  [
                    :call,
                    [:var_ref, [:@ident, "fresh_object", [10, 27]]],
                    [:@period, ".", [10, 39]],
                    [:@ident, "instance_variable_get", [10, 40]],
                  ],
                  [
                    :arg_paren,
                    [
                      :args_add_block,
                      [
                        [
                          :symbol_literal,
                          [:symbol, [:@ivar, "@association_cache", [10, 63]]],
                        ],
                      ],
                      false,
                    ],
                  ],
                ],
              ],
              [
                :assign,
                [:var_field, [:@ivar, "@attributes", [11, 6]]],
                [
                  :method_add_arg,
                  [
                    :call,
                    [:var_ref, [:@ident, "fresh_object", [11, 20]]],
                    [:@period, ".", [11, 32]],
                    [:@ident, "instance_variable_get", [11, 33]],
                  ],
                  [
                    :arg_paren,
                    [
                      :args_add_block,
                      [
                        [
                          :symbol_literal,
                          [:symbol, [:@ivar, "@attributes", [11, 56]]],
                        ],
                      ],
                      false,
                    ],
                  ],
                ],
              ],
              [
                :assign,
                [:var_field, [:@ivar, "@new_record", [12, 6]]],
                [:var_ref, [:@kw, "false", [12, 20]]],
              ],
              [
                :assign,
                [:var_field, [:@ivar, "@previously_new_record", [13, 6]]],
                [:var_ref, [:@kw, "false", [13, 31]]],
              ],
              [:var_ref, [:@kw, "self", [14, 6]]],
            ],
            nil,
            nil,
            nil,
          ],
        ],
      ],
    ]
  end

  def failure_message
    # ...
  end
end
```

## The final boss

Final, "pragmatic" implementation that I'm sticking with. It depends on `parser` and `method_source` gems. I've made peace with them, as they're already in the project via `pry`, `mutant` and `rubocop` additions.

```ruby
require "parser/current"

RSpec.describe "User" do
  include AST::Sexp

  specify "#reload method is overridden based on framework implementation" do
    expect(actual_find_record_implementation).to eq(
      expected_find_record_implementation,
    ),
    failure_message
  end

  private

  def actual_reload_implementation
    Parser::CurrentRuby.parse(
      ActiveRecord::Persistence.instance_method(:reload).source,
    )
  end

  def expected_reload_implementation
    s(
      :def,
      :reload,
      s(:args, s(:optarg, :options, s(:nil))),
      s(
        :begin,
        s(
          :send,
          s(:send, s(:send, s(:self), :class), :connection),
          :clear_query_cache,
        ),
        s(
          :lvasgn,
          :fresh_object,
          s(
            :if,
            s(:send, nil, :apply_scoping?, s(:lvar, :options)),
            s(:send, nil, :_find_record, s(:lvar, :options)),
            s(
              :block,
              s(:send, s(:send, s(:self), :class), :unscoped),
              s(:args),
              s(:send, nil, :_find_record, s(:lvar, :options)),
            ),
          ),
        ),
        s(
          :ivasgn,
          :@association_cache,
          s(
            :send,
            s(:lvar, :fresh_object),
            :instance_variable_get,
            s(:sym, :@association_cache),
          ),
        ),
        s(
          :ivasgn,
          :@attributes,
          s(
            :send,
            s(:lvar, :fresh_object),
            :instance_variable_get,
            s(:sym, :@attributes),
          ),
        ),
        s(:ivasgn, :@new_record, s(:false)),
        s(:ivasgn, :@previously_new_record, s(:false)),
        s(:self),
      ),
    )
  end

  def failure_message
    # ...
  end
end
```

As you can see, there is no line or column references in the output. It stil depends on non-core-or-stdlib `parser` and `method_source` gems. I've made peace with them, as they're already in the project via `pry`, `mutant` and `rubocop` additions. 

For the portability I wish those dependencies weren't needed. Hopefully one day this all will be easier in the future Ruby:

<% link_to "https://twitter.com/_m_b_j_/status/1694830922548257141", target: "_blank", rel: "noreferrer" do %>
  <img src="<%= src_fit("six-ways-mp/tweet-1694830922548257141.png") %>" width="100%">
<% end %>

Fingers crossed 🤞