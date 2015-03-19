---
title: "Tracking down unused templates"
created_at: 2015-03-18 03:23:22 +0100
kind: article
publish: false
author: Rafał Łasocha
tags: [ 'story', 'chillout', 'activesupport' ]
newsletter: :arkency_form
img: "/assets/images/tracking-down-unused-templates/countryside-fence-field-fit.jpg"
---

<p>
  <figure>
    <img src="/assets/images/tracking-down-unused-templates/countryside-fence-field-fit.jpg" width="100%">
  </figure>
</p>

Few days ago, my colleague raised _#sci-fi_ idea. **Maybe we could somehow track templates rendered in application to track down which ones aren't used?** Maybe we could have **metrics** how often they're used? Metrics? That sounds like gathering data using Chillout.io. In other project at which I work we already have Chillout gem installed and used.

<!-- more -->

## Track down used templates

To know which templates aren't used we firstly would like to know which ones **are** used.
We would like somehow to **hook into rails internals** and increment specific counter (named like `counter_app/views/posts/new.html.erb`) when rails renders a template.

**Well, that sounds hacky**. However it's good to work with people more experienced in rails - they know about parts of rails, you haven't idea about. There exists a module called [Active Support Instrumentation](http://edgeguides.rubyonrails.org/active_support_instrumentation.html). Let's read what's its purpose:

_"Active Support is a part of core Rails that provides Ruby language extensions, utilities and other things. One of the things it includes is an instrumentation API that can be used inside an application to **measure certain actions that occur within Ruby code**, such as that inside a Rails application or the framework itself."_

These are the methods we are looking for! After quick look on table of contents, we can see [two hooks](http://edgeguides.rubyonrails.org/active_support_instrumentation.html#action-view) which would suit us: `render_partial.action_view` and `render_template.action_view`. Both of them return identifier of the template which is full path to the template. Great, now we have to learn how to subscribe to these hooks.

[Example from the same rails guide](http://edgeguides.rubyonrails.org/active_support_instrumentation.html#subscribing-to-an-event):

```
#!ruby
ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
  event = ActiveSupport::Notifications::Event.new *args
 
  event.name      # => "process_action.action_controller"
  event.duration  # => 10 (in milliseconds)
  event.payload   # => {:extra=>information}
 
  Rails.logger.info "#{event} Received!"
end
```

Now let's write the code which will track using of our partials. We put it into `config/initializers/template_monitoring.rb` because we want it to execute only once.

```
#!ruby
require 'active_support/notifications'

%w(render_template.action_view render_partial.action_view).map do |event_name|
  ActiveSupport::Notifications.subscribe(event_name) do |*data|
    event = ActiveSupport::Notifications::Event.new(*data)
    template_name = event.payload[:identifier]
    
    Chillout::Metric.track(template_name)
  end
end
```

As you can probably guess, `Chillout::Metric.track(name)` is incrementing a counter named `template_name`.
Thus now **every time rails renders a template it notifies Chillout** which handles the rest.

## Full paths are not what we want

However, again from previously referenced rails guide, `event.payload[:identifier]` is an absolute path to the template. That's not good - what will happen when we deploy with capistrano new version of our application? In absolute path we have number of release which changes on each deployment. Let's change that.

```
#!ruby
def metric_name(path)
  template_name = path.sub(/\A#{Rails.root}/, '')
  "template_#{partial_name}"
end
```

Obviously now in our previous code we've to change

```
#!ruby
template_name = event.payload[:identifier]
```
to

```
#!ruby
template_name = metric_name(event.payload[:identifier])
```

Great, now we are tracking usage of used templates! We got chillout report and we can read how many each one partial was rendered.

**And it's total opposite of what we wanted to achieve because partials which weren't rendered at least once are not present on the list.**

## Track down not used templates

**That's going to be pretty chillout-specific.** Firstly we need to create container which keeps templates' counters.

```
#!ruby
template_name = metric_name(event.payload[:identifier])
Thread.current[:creations] ||= Chillout::CreationsContainer.new
container = Thread.current[:creations]
```

We're assigning it to `Thread.current[:creations]` because that's place where chillout seeks for container (or creates it, if it's uninitialized).

Then we need to initialize counters for all templates to 0. We can do that by asking chillout "What is counter of `template_name` now?". We do that by fetching `container[template_name]`. From that moment Chillout will be aware that there exists such counter named `template_name`. Thus it will show it in reports.

```
#!ruby
template_name = metric_name(event.payload[:identifier])
Dir.glob("#{Rails.root}/app/views/**/_**").each do |raw_path|
  template_name = metric_name(raw_path)
  value = container[template_name]
  Rails.logger.info "[Chillout] #{template_name}: #{value}"
end
```

In the end whole `config/initializers/template_monitoring.rb` looks like this:

```
#!ruby
template_name = metric_name(event.payload[:identifier])
require 'active_support/notifications'

def metric_name(path)
  template_name = path.sub(/\A#{Rails.root}/, '')
  "template_#{template_name}"
end

%w(render_template.action_view render_partial.action_view).map do |event_name|
  ActiveSupport::Notifications.subscribe(event_name) do |*data|
    event = ActiveSupport::Notifications::Event.new(*data)
    template_name = metric_name(event.payload[:identifier])
    Chillout::Metric.track(template_name)
  end
end

Thread.current[:creations] ||= Chillout::CreationsContainer.new
container = Thread.current[:creations]

Dir.glob("#{Rails.root}/app/views/**/_**").each do |raw_path|
  template_name = metric_name(raw_path)
  value = container[template_name]
  Rails.logger.info "[Chillout] #{template_name}: #{value}"
end
```


## Conclusions

That's how we are tracking unused templates in our app. Obviously we can't be 100% sure that templates which have counter equal to 0 aren't used anywhere. Maybe this template is just very rarely used? But it's also very useful information. Now we can discuss that with client. Maybe maintenance of the feature using that template is not worth it? Maybe we could drop it?

**Note that you could make this not only by using chillout. One of my colleagues did this using plain redis hash. Take a look on Active Support Instrumentation and use your creativity.**
