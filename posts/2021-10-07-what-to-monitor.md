---
title: What to monitor
created_at: 2021-10-07T09:44:34.271Z
author: Tomasz Wróbel
tags: []
publish: false
---

> Originally put together by Paweł Pacana

most basic ones:
- web workers are up after deployment (https://blog.arkency.com/2016/02/the-smart-way-to-check-health-of-a-rails-app/)
- background jobs are processing (i.e. sidekiq process is up after deployment)
//honeybadger handles both via uptime and check-ins

machine related:
- cpu, ram, swap usage to optimize resource use (https://www.speedshop.co/2015/07/22/secrets-to-speedy-ruby-apps-on-heroku.html)
- disk space on: app/new deployments; database/storage and tmp storage to perform migrations on tables; assets, uploads, etc.  (if it matters, unlikely in cloud but recently reminded by one Hatchbox deployment that it still matters 🙃 )
//out of the box on heroku, also no problems with disk space on ephemeral filesystems, object storage (S3) and cloud-hosted databases but roll your own deployment with Hatchbox and you starting pouring your time into it

app errors:
- backend and frontend
//honeybadger handles both (there are many alternatives but this one is battle-tested: https://blog.arkency.com/2016/04/how-i-hunted-the-most-odd-ruby-bug/)

app performance related:
- slowest endpoints, slowest queries
- job queue latency (https://twitter.com/nateberkopec/status/1371492901402869762)
//I mostly use newrelic here, grafana seems to be self-hosted alternative if you have some $ to burn

last but not least, there are business metrics — how well is your business doing but I guess that was out of scope of the question 🙂
