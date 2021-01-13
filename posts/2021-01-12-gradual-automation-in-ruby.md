---
title: Gradual automation in Ruby
created_at: 2021-01-12T10:51:20.895Z
author: Tomasz Wróbel
tags: ["infra", "devops", "deployment"]
publish: true
---

# Gradual automation in Ruby

It's the simplest piece of Ruby code you'll read today. Also known as: _do-nothing scripting_. [Original inspiration](https://blog.danslimmon.com/2019/07/15/do-nothing-scripting-the-key-to-gradual-automation/).

## Problem

You want to codify a manual process like setting up another instance of your e-commerce app. It may involve several steps with varying potential for automation (like seed the db, set up a subdomain, set up admin account).

* Solution 1 📖: lay out all steps in a wiki page and teach people to conform.
* Solution 2 🧠: don't even document the steps, keep it in your own head. Have people always come to you or discover it from scratch, develop tribal knowledge.
* Solution 3 🖲: make everything happen at the push of a button in your glossy dashboard app. Spend weeks implementing it and months maintaining it. Lie to yourself that this is good ROI.
* Solution 4 ⚙️: skip the UI part, write a script that automates it all. Wonder why people don't use it.
* Solution 5 📝 + ⚙️: make a _do-nothing script_ that only tells you what to do next. Gradually automate it where it makes sense.

## An example

The original example is in Python. This is how I once did it in Ruby. I hereby announce another name for this technique — **Puts-Driven Automation**, or **Puts-First Automation** — at first you `puts` what has to be done, then you gradually automate, when you think it's worth it. You can see here how one step is done manualy, and the other is automated.

```ruby
STEPS = [
  -> {
    puts "Please open https://my.hosting/dashboard and create a new subdomain"
  },
  -> {
    puts "Creating admin user"
    system(%q{ heroku run -a my-heroku-app rails runner "User.create(name: 'admin')" })
    puts "Created admin user"
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

## Advantages of _Puts-First Automation_

* It's version controlled just as the rest of your stuff.
* It's easy to start with — at the beginning nothing needs to be automated.
* It can keep track of your progress (as opposed to a wiki page)
* You can automate just some steps, leave the rest to be done manually

## I bet you can make the above snippet better!

Send me a gist showing how you do it and I'll link your example here. [DMs open](https://twitter.com/tomasz_wro).

Got comments? [Reply under this tweet](https://twitter.com/tomasz_wro/status/1348956291117547520).
