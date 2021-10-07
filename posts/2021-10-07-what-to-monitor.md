---
title: What to monitor
created_at: 2021-10-07T09:44:34.271Z
author: Tomasz Wróbel
tags: []
publish: false
---

Here's what one of [Arkademy](https://arkademy.dev) subscribers asked on our subscriber-only Discord server:

> Hi guys! How do you monitor your apps on production? Which metrics do you use? Do you recommend any blogs about application monitoring?

[Paweł](https://twitter.com/pawelpacana) came up with an answer, I thought it's worth sharing.

### Most basic ones

- Web workers are up after deployment. More: [The Smart Way to Check Health of a Rails App](https://blog.arkency.com/2016/02/the-smart-way-to-check-health-of-a-rails-app/).
- Background jobs are processing (i.e. sidekiq process is up after deployment)

(honeybadger handles both via uptime and check-ins)

### Machine related

- cpu, ram, swap usage to optimize resource use (https://www.speedshop.co/2015/07/22/secrets-to-speedy-ruby-apps-on-heroku.html)
- disk space on: app/new deployments; database/storage and tmp storage to perform migrations on tables; assets, uploads, etc.  (if it matters, unlikely in cloud but recently reminded by one Hatchbox deployment that it still matters 🙃 )

out of the box on heroku, also no problems with disk space on ephemeral filesystems, object storage (S3) and cloud-hosted databases but roll your own deployment with Hatchbox and you starting pouring your time into it)

### App errors

- backend
- frontend

(Honeybadger handles both. There are many alternatives but this one is battle-tested: https://blog.arkency.com/2016/04/how-i-hunted-the-most-odd-ruby-bug/)

### App performance related

- slowest endpoints, slowest queries
- job queue latency (https://twitter.com/nateberkopec/status/1371492901402869762)

I mostly use newrelic here, grafana seems to be self-hosted alternative if you have some $ to burn.

### Business metrics

Last but not least, there are business metrics — how well is your business doing but I guess that was out of scope of the question 🙂
