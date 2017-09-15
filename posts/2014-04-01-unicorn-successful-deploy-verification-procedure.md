---
title: "Zero uptime deploy"
created_at: 2014-04-01 16:21:18 +0100
kind: article
publish: true
author: Robert Pankowecki
newsletter: :arkency_form
tags: [ 'rails', 'ruby', 'unicorn', 'deploy', 'verification' ]
---

<p>
  <figure>
    <img src="<%= src_fit("unicorn-restart/unicorn-kill-restart-verify-deploy-2-small.jpg") %>" width="100%">
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
and you won't even notice. You will be thinking that everything went ok, living in Wonderland,
whereas in reality your deploy achieved uptime of exactly 0 seconds.

So what you need is a small verification procedure that everything worked as
expected. This article will demonstrate simple solution for achieving it
in case you are using `capistrano` for deploying the app. However you can use very similar
procedure if you deploy your app with other tools.

<!-- more -->

Here is what we assume that you already have

## deploy.rb

Nothing fancy here. As the documentation states:

`USR2` signal for master process - _reexecute the running binary. A separate
`QUIT` should be sent to the original process once the child is verified to be up and running._

```ruby
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

Whenever we spawn new child process we decrement the number of worker
processes by one with sending `TTOU` signal to master process.

At the end we send `QUIT` so the new master worker can take it place.

```ruby
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

Also we don't want to implement the entire verification procedure algorithm in
this file. So we extract it into `'./config/deploy/verify'` and require
inside the task.

```ruby

require 'securerandom'
set :deploy_token, SecureRandom.hex(16)

namespace :deploy do
  namespace :verify do
    task :prepare, :roles => :app, :except => { :no_release => true } do
      run "echo -n #{deploy_token} > #{release_path}/TOKEN"
    end

    task :check, :roles => :app, :except => { :no_release => true } do
      require './config/deploy/verify'

      user = 'about'
      pass = 'VerySecretPass'
      url  = "https://#{user}:#{pass}@#{target_host}/about/deploy"
      DeployVerification.new(url, deploy_token).start
    end
  end
end

before "deploy:restart", "deploy:verify:prepare"
after  "deploy:restart", "deploy:verify:check"
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

The whole idea is that we do the request to our just deployed/restarted webapp
and check whether it returns randomly generated token that we set before
restart. If it does, everything went smoothly and new workers started, they
read the new token and are serving it.

If however the new Unicorn workers could not properly start after deploy,
the old workers will be still working and serving requests, including the
request to `/about/deploy` that will give us the old token generated during
previous deploy.

It takes some time to start new Rails app, create new workers, kill old workers
and for the master unicorn worker to switch to the new process. So we wait max 60s
for the entire procedure to finish. In this time we are hitting our application
with request every now and then to check whether new workers are serving requests
or the old ones.

```ruby
require 'net/http'
require 'net/https'
require 'timeout'

class DeployVerification
  class VerificationFailedAtDir < StandardError; end

  def initialize(url, token, timeout = 60)
    @timeout = timeout
    @url     = url
    @token   = token
  end

  def start
    Timeout.timeout(@timeout) do
      begin
        uri  = URI.parse(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.start do |http|
          req = Net::HTTP::Get.new(uri.path)

          if uri.user && uri.password
            req.basic_auth uri.user, uri.password
          end

          result = http.request(req).body
          unless result == @token
            raise VerificationFailedAtDir, "Invalid verification token.
                                            Expected: #{@token},
                                            got: #{result}."
          end
          puts "Verified deploy is running"
        end
      rescue VerificationFailedAtDir => x
        puts x.message
        puts "Error when running verification. Retrying... \n"
        sleep(0.5)
        retry
      end
    end
  end
end
```

## config/routes.rb

```ruby

get "about/deploy"
```

## app/controllers/about_controller.rb

Here is the controller doing basic auth and serving the token. It does
not try to dynamically read the `TOKEN` file because that would
always return the new value written to that file during last deploy.

Instead it returns the token that is instantiated only once during Rails
startup process.

```ruby
class AboutController < ApplicationController

  before_filter :http_basic_authentication

  def http_basic_authentication
    authenticate_or_request_with_http_basic do |name, pass|
      name == 'about' && pass == 'VerySecretPass'
    end
  end

  def deploy
    render text: Rails.configuration.deploy_token, layout: false
  end
end
```

## config/application.rb

Here you can see that we are storing the token when rails is starting.

```ruby
deploy_token_file   = Rails.root.join('TOKEN')
config.deploy_token = if deploy_token_file.exist?
  deploy_token_file.read
else
  'none'
end
```

## But why?

Now that you know how, you are still probably wondering why.

Not everything can be caught by your tests, especially not errors made in
production environment configuration. That can be even something as simple as
typo in `config/environments/production.rb`.

We also experienced gems behaving differently and preventing app from being
started due to tiny difference in environment variables (`ENV`). So now,
whenever we manage application that is not hosted in cloud because of customer
preferences, we just add this little script to make sure that the deployed code
was actually deployed and workers restarted properly. Because sending signal
is sometimes just not good enough :)
