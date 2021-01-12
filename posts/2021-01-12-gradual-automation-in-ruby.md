---
title: Gradual automation in Ruby
created_at: 2021-01-12T10:51:20.895Z
author: Tomasz Wróbel
tags: []
publish: false
---

# Gradual automation in Ruby

Simplest piece of Ruby code you'll read today. Also known as: _do-nothing scripting_. [Original inspiration](https://blog.danslimmon.com/2019/07/15/do-nothing-scripting-the-key-to-gradual-automation/).

**Problem**: you want to codify a manual process like setting up another instance of your e-commerce app. It may involve several steps with varying potential for automation (like seed the db, set up a subdomain, set up admin account).

Solution 1: lay out all steps in a wiki page and teach people to conform.

Solution 2: don't even document the steps, keep it in your own head. Have people always come to you or discover it from scratch, develop tribal knowledge.

Solution 3: make everything happen at the push of a button in your glossy dashboard app. Spend weeks implementing it and months maintaining it. Lie to yourself that this is good ROI.

Solution 4: skip the UI part, write a script that automates it all. Wonder why people don't use it.

Solution 5: make a _do-nothing script_ that tells you what to do. Gradually automate it where it makes sense.

**Advantages** of a _do-nothing script_:

* it's version controlled just as the rest of your stuff
* easy to start with — at the beginning nothing needs to be automated
* it can keep track of your progress
* you can automate some steps, leave the rest to be done manually

The original example is in Python. This is how I once did it in Ruby:

```ruby
STEPS = [
  -> {
    puts "Create a user"
    puts
    puts
    puts "u = User.create!("
    puts "  name: '#{name}',"
    puts "  email: '#{email}',"
    puts "  company: '#{company}',"
    puts ")"
  },
  -> {
    puts "Setup an account on a 3rd party service"
    puts
  },
]

def ask_to_continue
  puts 'Continue? [Y/n]'
  input = STDIN.gets.chomp
  unless input == '' || /^[Yy]$/.match(input)
    puts 'User cancelled.'
    exit
  end
end

STEPS.each_with_index do |step, i|
  puts "-----------------------------------------------------------------------"
  puts "Step #{i}"
  puts "-----------------------------------------------------------------------"
  puts
  step.call
  puts
  ask_to_continue if i < (STEPS.size - 1)
end
```

## I bet you can do it better!

Send me a gist showing how you do it and I'll link your example here. [DMs open](https://twitter.com/tomasz_wro).
