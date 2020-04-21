---
title: Gradual automation in Ruby 
created_at: 2020-04-21T12:23:34.488Z
author: Tomasz Wróbel
tags: []
publish: false
---

Also known as: do-nothing scripting. [Original inspiration](https://blog.danslimmon.com/2019/07/15/do-nothing-scripting-the-key-to-gradual-automation/).


This is how we approached this:

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
