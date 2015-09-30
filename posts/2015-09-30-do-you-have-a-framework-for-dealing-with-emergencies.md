---
title: "Do you have a framework for dealing with emergencies?"
created_at: 2015-09-30 09:19:36 +0200
kind: article
publish: false
author: Bartosz Krajka
tags: [ '' ]
newsletter: :skip
---

In my pre-Arkency life, I worked for a corporation.

Keep in mind that it was my _very beginning_ of the commercial-IT world. I sometimes felt lost inside this huge DevOps machine. Lost and alone - as usually when something breaks, there was nobody to ask for help.

It had to happen. One day, **by accident, I ran some kind of a DB-clean-up script, with wrong date, on production**. The script's job was to delete records that are _old enough_. While fiddling with the script, I changed the definition of _record old enough_ to _every record_. And accidentaly ran the script.

My reaction - paralysis. I wasn't even sure what the script exactly did. Unfortunatelly, I had never found time before to analise the script line-by-line. Did the script have unit tests? Pfff. Forget about it. Unit tests in a corporation?

As mention before, I knew it was _some kind of a DB-clean-up script_, but maybe it had a protection from such accidental usage as mine? It should have, right?

I better stay quiet. If something terrible just happened - maybe nobody noticed... 

But someone did. One of the managers visited me quickly and brought to book: 

> Where are my data? I need it NOW for my work. When will you restore it?

I already realised that I had to call an old co-worker of mine (he was currently on vacation, but I had no choice...) to get all needed information. So my answer was:

> I don't know. In worst-case-scenario, when he is back, so next week.

TODO:

* no communication :(
* O/N/P estimation
* paralysis > panic
* do what you really trust while emergency
* framework