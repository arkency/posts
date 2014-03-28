---
title: "Unicorn successful deploy verification procedure"
created_at: 2014-03-28 16:21:18 +0100
kind: article
publish: false
author: Robert Pankowecki
newsletter: :arkency_form
tags: [ 'rails', 'ruby', 'unicorn', 'deploy', 'verification' ]
---

<p>
  <figure>
    <img src="/assets/images/unicorn-restart/unicorn-kill-restart-verify-deploy-2-small.jpg" width="100%">
    <details>
      <a href="http://www.flickr.com/photos/robboudon/6035265163/sizes/z/">Photo</a>
      remix available thanks to the courtesy of
      <a href="http://www.flickr.com/photos/robboudon/">Rob Boudon</a>.
      <a href="http://creativecommons.org/licenses/by/2.0/">CC BY 2.0</a>
    </details>
  </figure>
</p>

Unicorn has a nice feature that bought it a lot of popularity and set standards
for other Ruby web servers: The ability to do _Zero Downtime Deploy_, also known
by the name _rolling deploy_ or _rolling restart_ aka _hot restart_. You start it by issuing
`USR2` signal. But here is something that most websites won't tell you. It can fail
and you won't even notice.

So what you need is a small verification procedure that everything worked as
exptected. This article will demonstrate simple solution for achieving it
when you are using `capistrano` for deploying the app.

<!-- more -->

Here is what we assume

## deploy.rb

```
#!ruby
namespace :deploy do
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    reload
  end
end
```

## config/unicorn.rb

```
#!ruby
before_fork do |server, worker|
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)
end
```

Let's add the verification step after deployment.

## deploy.rb

We want to trigger our verification procedure for deploy no matter whether we
executed it with or without migrations.

Also we don't want to implement the verification procedure in this file. So we
extract it into `'./config/deploy/verify'` and requre in the task.

```
#!ruby
namespace :deploy do
  task :verify, :roles => :app, :except => { :no_release => true } do
    require './config/deploy/verify'

    DeployVerification.new(
      fetch(:target_host),
      current_release
    ).start
  end
end

after "deploy",            "deploy:verify"
after "deploy:migrations", "deploy:verify"
```

## config/deploy/production.rb

```
set :target_host, "app.example.com"
```

## config/deploy/staging.rb

```
set :target_host, "app.example.org"
```

## config/deploy/verify.rb


```
#!ruby
require 'net/http'
require 'timeout'

class DeployVerification
  class VerificationFailedAtDir < StandardError; end

  attr_reader :target_host, :current_release

  def initialize(target_host, current_release)
    @timeout         = 60
    @target_host     = target_host
    @current_release = current_release
  end

  def start
    Timeout.timeout(@timeout) do
      begin
        uri = URI.parse('http://about:a76ffd@example.com/about/deploy')
        uri.host = target_host
        Net::HTTP.start(uri.host, uri.port) do |http|
          req = Net::HTTP::Get.new(uri.path)
          req.basic_auth uri.user, uri.password
          result = http.request(req).body
          unless result == current_release
            raise VerificationFailedAtDir, "Invalid app working dir. Expected: #{current_release}, got: #{result}"
          end
          puts "Verified deploy is running"
        end
      rescue VerificationFailedAtDir => x
        puts x.message
        puts "Error when running verification. Retrying... \n"
        sleep(1)
        retry
      end
    end
  end
end
```
