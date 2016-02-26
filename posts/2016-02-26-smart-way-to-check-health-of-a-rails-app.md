---
title: "Smart way to check health of a Rails app"
created_at: 2016-02-26 17:05:19 +0100
kind: article
publish: false
author: anonymous
tags: [ 'rails', 'health check', 'ops' ]
newsletter: :arkency_form
---

Recently we added monitoring to one of our customer’s application. The app was tiny, but with a huge responsibility. We simply wanted to know if it’s alive. We wen’t with [Sensu](https://sensuapp.org) HTTP check, since it was a no-brainer. And it just worked, however we got warning from monitoring tool.

<!-- more -->

## This is not the HTTP code you are looking for
Authentication is required to access any of the app resources. It simply does redirect to login page. `302` code is returned instead of expected one of  `2xx` code family.

<p>
    <figure>
        <img src="<%= src_fit('smart-way-to-check-health-of-a-rails-app/sensu_warning.png') %>" width="100%">
    </figure>
</p>

## What to do about that?
We've found out that the best solution would be having a **dedicated endpoint** in the app. This endpoint shouldn't require any authentication or involve any of the application logic. It should only return `204 No Content`. Monitoring checks will become green and everyone will be happy.