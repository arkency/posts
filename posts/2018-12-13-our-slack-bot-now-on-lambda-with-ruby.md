---
title: "Serverless Slack bot on Lambda with Ruby (and what’s the less pleasant part about it)"
created_at: 2018-12-13 14:00:00 +0100
kind: article
publish: true
author: Paweł Pacana
tags: [ 'aws', 'lambda', 'serverless', 'slack' ]
newsletter: arkency_form
---

We love sharing knowledge at Arkency. Education is in our DNA. We're happy when our readers and customers are benefiting from that as well. And we've set a Slack bot celebrate on each such occasion!

## Pandas and sales

SlackProxy, which is the name of our application, notifies us whenever we make a sale from our e-commerce solution, that is [DPD](https://arkency.dpdcart.com). This is an extremely rewarding experience when launching a new product but also a reminder to keep up improving existing ones.

<%= img_fit "serverless/sale_panda.png" %>

Initially SlackProxy was a Rails application deployed on our internal infrastructure, then moved to Heroku. Technically it is nothing more than a proxy that transforms incoming webhooks from DPD into formatted messages posted on dedicated Slack channel.

See yourself, this one of the controllers:

```ruby
module SlackProxy
  class SaleController < ApplicationController
    def create
      notifier = SaleNotifier.new
      items = [params.fetch(:item_name1), params[:item_name2], params[:item_name3], params[:item_name4]].compact
      notifier.call(params.fetch(:mc_gross), params.fetch(:coupon_code), params.fetch(:payer_email), params.fetch(:first_name), params.fetch(:last_name), items)
      render nothing: true
    end
  end
end
```

Nothing much interesting in the controller. The notification part is in the `SaleNotifier` which does the formatting and posting with help of a library to chat with Slack API.

```ruby
module SlackProxy
  class SaleNotifier
    def call(money, code, email, name, surname, items)
      notifier = Slack::Notifier.new(
        db.fetch("webhook_url"),
        {
          username: db.fetch("username"),
          icon_emoji: ":panda_face:",
          attachments: [{
            fallback: "+#{money}$",
            text: "+#{money}$",
            color: 'good'
          }]
        }
      )
      if code.present?
        main_message = "#{name} #{surname} (#{email}) bought #{items.join(", ")} with the following code: #{code}"
      else
        main_message = "#{name} #{surname} (#{email}) bought #{items.join(", ")}"
      end
      notifier.ping(main_message)
    end

    private

    def db
      Rails.application.secrets.fetch(:sale_slack_data)
    end
  end
end
```


## Enter serverless

When AWS announced Lambda support for Ruby [I was really excited about the possibilities it opens](https://twitter.com/pawelpacana/status/1068525554708602882). Not that those possibilities were unreachable before — with Ruby it is just more fun. I knew what would be the first thing we happily move there and we already had most of the code 😅

In fact the way traffic shapes for SlackProxy [is an ideal candidate](https://servers.lol) for a Lambda deployment — huge spikes for several launch days and more peaceful pings on other days. Nothing latency–critical as well.

Lambda functions may be triggered by several AWS events. Be it a repository event from CodeCommit, an upload to S3 or and update from SQS. For us, web developers, a request coming to an API Gateway sounds most familiar. It is a good entry point to explore Lambda.

<%= img_fit "serverless/lambda_trigger.png" %>

I figured that an "API Gateway to Rack" adapter would be a natural glue for any Ruby web application and was relieved to [find it contributed by AWS](https://github.com/aws-samples/serverless-sinatra-sample/blob/master/lambda.rb). After all, Rails application is just a an elaborate mechanisms to turn `env` into `[status, headers, body]`.

Some resistance against Lambda has formed around the opinion that "you cannot run this in development". I find it hard to defend when the boundary of you application ends on Rack. We already manage that well with existing tooling. And [in production](https://blog.arkency.com/2017/01/run-your-tests-on-production/) you may need different set of checks anyway.

## Serverless Panda

Without any further ado here's a rewrite of a notifier in form of a simplest [Rack](https://rack.github.io) application:

```ruby
require 'slack-notifier'

module SlackProxy
  class SaleNotifier
    def initialize(slack_webhook_url, slack_username)
      @slack_webhook_url = slack_webhook_url
      @slack_username    = slack_username
    end

    def call(env)
      params     = Rack::Request.new(env).params
      money      = params.fetch('mc_gross')
      code       = params.fetch('coupon_code')
      email      = params.fetch('payer_email')
      given_name = params.fetch_values('first_name', 'last_name').join(' ')
      items      = params.values_at('item_name1', 'item_name2', 'item_name3', 'item_name4').compact

      send_message(money, given_name, email, items, code)
      render_nothing
    end

    private
    attr_reader :slack_webhook_url, :slack_username

    def render_nothing
      Rack::Response.new
    end

    def send_message(money, given_name, email, items, code)
      notifier = Slack::Notifier.new(slack_webhook_url, {
        username: slack_username,
        icon_emoji: ":panda_face:",
        attachments: [{
          fallback: "+#{money}$",
          text: "+#{money}$",
          color: 'good'
        }]
      })
      main_message = "#{given_name} (#{email}) bought #{items.join(", ")}"
      main_message << " with the following code: #{code}" unless code.empty?
      notifier.ping(main_message)
    end
  end
end
```

This comes with a handy `config.ru` that [rack-lambda](https://github.com/arkency/slack_proxy/blob/843442a7722e4aed40dcfec130011d8a2a81fb58/lambda.rb#L21) handler expects:

```ruby
$LOAD_PATH << File.join(__dir__, 'lib')
require 'slack_proxy'

use Rack::CommonLogger
run SlackProxy::SaleNotifier.new(ENV['SLACK_WEBHOOK_URL'], ENV['SLACK_USERNAME'])
```

That makes it trivial to run such app in development with [rackup](https://github.com/arkency/slack_proxy/blob/843442a7722e4aed40dcfec130011d8a2a81fb58/Makefile#L9). You can find full source code with unit and mutation tests at [slack_proxy](https://github.com/arkency/slack_proxy).

## The deployment and less pleasant part

So far it did not mention how we get this code deployed. There are several options possible:

* copy and paste in web editor
* package and deliver via S3 with help of (SAM CLI)[https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-deploying.html#serverless-deploying-automated]
* on git push via [CodePipeline](https://docs.aws.amazon.com/lambda/latest/dg/build-pipeline.html)

First option is fine for exploring the environment. It gets you up to speed without bothering much. In the long run, being accustomed to Continuous Delivery I'd favor CodePipeline. I did not figure it out just yet. At the moment we rely on SAM CLI, as described in Ruby [announcement post](https://aws.amazon.com/blogs/compute/announcing-ruby-support-for-aws-lambda/).

The biggest obstacle for me so far was getting familiar with AWS services involved (IAM, API Gateway, Certificate Manager) and making sense out of the documentation. That is not something Lambda specific and I guess you'd have to face it when dealing with any AWS service. This was far for me from the Heroku-like experience.

What could be also problematic for particular deployments is getting some [required dependencies](https://www.reddit.com/r/ruby/comments/a3e7a1/postgresql_on_aws_lambda_ruby/). It might be more desirable to lean on AWS ecosystem more deeply in that case (i.e. consider Dynamo storage).

Should you try AWS Lambda with Ruby after all? Yes, go explore it!
