---
title: Multitenancy in Rails - what says the internet
created_at: 2020-07-30T10:10:16.167Z
author: Tomasz Wróbel
tags: []
publish: false
---


Recently I've been researching the topic of multitenancy in Rails. You might have already seen the [previous blogpost](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/).

In the meantime there was another [discussion about multitenancy on HN](https://news.ycombinator.com/item?id=23305111) which pretty much blew up. I don't typically read all the comments on HN, but this time I wanted to go through it to know people's experiences on the topic I was researching.

Here's some quotes that drew my attention, extracted to save you some time.

The original question asked about db-level multitenancy, but a lot of this relates to schema-level as well (which people also often explicitly related to). Also schema-level in Postrgres has a lot in common with db-level in MySQL as you can read in [my previous blogpost](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/).

All the credit goes of course to original comments' authors. You can easily find them by grepping the original [discussion page](https://news.ycombinator.com/item?id=23305111).


* My startup currently does just this 'at scale', which is for us ~150 b2b customers with a total database footprint of ~500 GB. We are using Rails and the Apartment gem to do mutli-tenancy via unique databases per account with a single master database holding some top-level tables.

  This architecture decisions is one of my biggest regrets, and we are currently in the process of rebuilding into a single database model.

  FWIW, this process has worked well for what it was originally intended to do. Data-security has a nice db level stopgap and we can keep customer data nicely isolated. It's nice for extracting all data from a single customer if we have extended debugging work or unique data modeling work. It saves a lot of application layer logic and code. I'm sure for the most part it makes the system slightly faster.

  However as we have grown this has become a huge headache. It is blocking major feature refactors and improvements. It restricts our data flexibility a lot. Operationally there are some killers. Data migrations take a long time, and if they fail you are left with multiple databases in different states and no clear sense of where the break occurred.

  Lastly, if you use the Apartment gem, you are at the mercy of a poorly supported library that has deep ties into ActiveRecord. The company behind it abandoned this approach as described here: https://influitive.io/our-multi-tenancy-journey-with-postgre...

    * Echoing this as well, I worked for Influitive and was one of the original authours of apartment (sorry!)
    
      There are a lot of headaches involved with the "tenant per schema" approach. Certainly it was nice to never have to worry about the "customer is seeing data from another customer" bug (a death knell if you're in enterprisish B2B software), but it added so many problems:
    
      Migrations become a very expensive and time-consuming process, and potentially fraught with errors. Doing continious-deployment style development that involves database schema changes is close to impossible without putting a LOT of effort into having super-safe migrations.
    
      You'll run into weird edge cases due to the fact that you have an absolutely massive schema (since every table you have is multiplied by your number of tenants). We had to patch Rails to get around some column caching it was doing.
    
      Cloud DB hosting often doesn't play nice with this solution. We continually saw weird performance issues on Heroku Postgres, particularly with backup / restores (Heroku now has warnings against this approach in their docs)
    
      It doesn't get you any closer to horizontal scalability, since connecting to a different server is significantly different than connecting to another schema.
    
      It will probably push the need for a dedicated BI / DW environment earlier than you would otherwise need it, due to the inability to analyze data cross-schema.
    
      I still think there's maybe an interesting approach using partioning rather than schemas that eliminates a lot of these problems, but apartment probably isn't the library to do it (for starters, migrations would be entirely different if partioning is used over schemas)

---

I agree that migrations are painful at the best of times, but dealing with the complexity of migrating a single database is far simpler than dealing with migrating hundreds of schemas:
- Migrations will first of all just take longer - you're multiplying the number of schema changes by the number of tenants you have.

- While in an ideal world migrations should be purely run within a transaction, occasionally performance considerations mandate that you run without DDL transactions - when some tenants fail and your migrations are in a partially completed state for some of your tenants and not others, it can be scary and painful.

- In my experience, almost no one approaches data migrations in a way that is purely backwards compatible 100% of the time without exception. You certainly can, but there's a significant tax associated with this, and if you're in a traditional scoped environment, you can often get away with the potential for errors in the minuscule time that a schema change is operating (of course, some schema changes aren't run in minuscule times, but those are the ones you're more likely to plan for)

Going read only during migrations is an interesting approach, but there's real business costs associated with that (particularly if your migration speed is multiplied by running it across tenants).

I don't want to say that you should never isolate data on a schema level, but I do think it's something that shouldn't be a standard tool to reach for. For the vast majority of companies, the costs outweigh the benefits in my mind.

---

Can confirm, here be dragons. I did a DB per tenant for a local franchise retailer and it was the worst design mistake I ever made, which of course seemed justified at the time (different tax rules, what not), but we never managed to get off it and I spent a significant amount of time working around it, building ETL sync processes to suck everything into one big DB, and so on.
Instead of a DB per tenant, or a table per tenant, just add a TenantId column on every table from day 1.

---

I do both.
Have a tenant_id column in every table.

This gives me flexibility to either host each client separately or club them together.

---

Here I'll give you one: If you want to change a property of the database that will give your specific use improved performance, you have no way to transactionally apply that change. Rolling back becomes a problem of operational scale, rolling out as well.
What if you need to release some feature, but that feature requires a database feature enabled? Normally you enable it once, in a transaction hopefully, and then roll out your application. With this style you have to wait for N database servers to connect, enable, validate, then go live before you can even attempt the application being deployed, much less if you get it wrong.

---

For me it falls into the category of decisions that are easy to make and difficult to un-make. If for whatever reason you decide this was the wrong choice for you, be in tech needs (e.g. rails) or business needs, merging your data and going back into a codebase to add this level of filtering is a massive undertaking.

---

Indeed, but if you are making a B2B enterprise/SMB SaaS, I think you are most likely to regret the opposite choice [1][2]. A lot of companies run a single instance, multitenant application and have to develop custom sharding functionality down the road when they realize the inevitable: that most joins and caches are only needed on strict subsets of the data that are tenant specific.
If you get successful enough in this type of application space, you reach a mature state in which you need to be able to:

* Run large dedicated instances for your largest customers, because either their performance or security requirements mandate it.

* Share resources among a large number of smaller customers, for efficiency and fault tolerance reasons.

You can get there in two ways:

* You start with a massive multi tenant application, and you figure out a way to shard it and separate in pieces later.

* You start with multiple small applications, and you develop the ability to orchestrate the group, and scale the largest of them.

I would argue the latter is more flexible and cost efficient, and requires less technical prowess.

---

I’ve managed a system with millions of users and tens of billions of rows, and I always dreamed of DB per user. Generally, ~1% of users were active at a given time, but a lot of resources were used for the 99% who were offline (eg, indexes in memory where 99% of the data wouldn’t be needed). Learned a few tricks. If this is the problem you're trying to solve, some tips below.

---

You can always take a multi-tenant system and convert it into a single-tenant system a lot more easily. First and foremost, you can simply run the full multi-tenant system with only a single tenant, which if nothing else enables progressive development (you can slowly remove those now-unnecessary WHERE clauses, etc).

---

True, but:
In my experience by the time you reach this point you have a lot of operational complexity because you and your team are used to your production cluster being a single behemoth, so chances are it's not easy to stand up a new one or the overhead for doing so is massive (i.e. your production system grew very complex because there is rarely if ever a need to stand up a new one).

Additionally, a multi tenant behemoth might be full of assumptions that it's the only system in town therefore making it hard to run a separate instance (i.e. uniqueness constraints on names, IDs, etc).

---

If an "account" is an "enterprise" customer (SMB or large, anything with multiple user accounts in it), then yes, I know at least a few successful companies, and I would argue in a lot of scenarios, it's actually advantageous over conventional multitenancy.
The biggest advantage is flexibility to handle customers requirements (e.g. change management might have restrictions on versioning updates) and reduced impact of any failures during upgrade processes. It's easier to roll out upgrades progressively with proven conventional tools (git branches instead of shoddy feature flags). Increased isolation is also great from a security standpoint - you're not a where clause away from leaking customer data to other customers.

I would go as far as saying this should be the default architecture for enterprise applications. Cloud infrastructure has eliminated most of the advantages of conventional multitenancy.

If an account is a single user then no.

PS: I have a quite a lot of experience with this so if you would like more details just ask.

---

Yes, for multi-tenancy. Database per tenant works alright if you have enterprise customers - i.e. in the hundreds, not millions - and it does help in security. With the right idioms in the codebase, it pretty much guarantees you don't accidentally hand one tenant data belonging to a different tenant.
MySQL connections can be reused with database per tenant. Rack middleware (apartment gem) helps with managing applying migrations across all databases, and with the mechanics of configuring connections to use a tenant based on Host header as requests come in.

---

Not a problem with MySQL, "use `tenant`" switches a connection's schema.
Rails migrations work reasonably well with apartment gem. Never had a problem with inconsistent database migrations. Sometimes a migration will fail for a tenant, but ActiveRecord migrations records that, you fix the migration, and reapply, a no-op where it's already done.

---

Using schemas gives you imperfect but still improved isolation. It's still possible for a database connection to cross into another tenant, but if your schema search path only includes the tenant in question, it significantly reduces the chance that cross-customer data is accidentally shared.

---

It’s not a cool factor issue. It’s an issue of bloating the system catalogs, inability to use the buffer pool, and having to run database migrations for each and every separate schema or maintaining concurrent versions of application code to deal with different schema versions.

---

As you can see now that the thread has matured, there are a lot of proponents of this architecture that have production experience with it, so it's likely not as dumb as you assume.

---

> As you can see now that the thread has matured, there are a lot of proponents of this architecture that have production experience with it, ...
Skimming through the updated comments I do not see many claiming it was a good idea or successful at scale. It may work fine for 10s or even 100s of customers, but it quickly grows out of control. Trying to maintain 100,000 customer schemas and running database migrations across all of them is a serious headache.

> ...so it's likely not as dumb as you assume.

I'm not just assuming, I've tried out some of the ideas proposed in this thread and know first hand they do not work at scale. Index page caching in particular is a killer as you lose most benefits of a centralized BTREE structure when each customer has their own top level pages. Also, writing dynamic SQL to perform 100K "... UNION ALL SELECT * FROM customer_12345.widget" is both incredibly annoying and painfully slow.

---

I don't think we share the definition of "scale".
Extremely few companies that sell B2B SaaS software for enterprises have 10K customers, let alone 100K (that's the kind of customer base that pays for a Sauron-looking tower in downtown SF). Service Now, Workday, etc, are publicly traded and have less than 5000 customers each.

All of them also (a) don't run a single multitenant cluster for all their customers and (b) are a massive pain in the ass to run in every possible way (an assumption, but a safe one at that!).

---

In the past I worked at a company that managed thousands of individual MSSQL databases for individual customers due to data security concerns. Effectively what happened is the schema became locked in place since running migrations across so many databases became hard to manage.
I currently work at a company where customers have similar concerns around data privacy, but we've been to continue using a single multitenant DB instance by using PostgreSQL's row level security capabilities where rows in a table are only accessible by a given client's database user:

https://www.postgresql.org/docs/9.5/ddl-rowsecurity.html

We customized both ActiveRecord and Hibernate to accommodate this requirement.

---

I am aware of at least one company which does this from my consulting days, and would caution you that what you get in perceived security benefits from making sure that tenants can't interact with each others' data you'll give back many times over with engineering complexity, operational issues, and substantial pain to resolve ~trivial questions.
I also tend to think that the security benefit is more theatre than reality. If an adversary compromises an employee laptop or gets RCE on the web tier (etc, etc), they'll get all the databases regardless of whose account (if any) they started with.

(The way I generally deal with this in a cross-tenant application is to ban, in Rails parlance, Model.find(...) unless the model is whitelisted (non-customer-specific). All access to customer-specific data is through @current_account.models.find(...) or Model.dangerously_find_across_accounts(...) for e.g. internal admin dashboards. One can audit new uses of dangerously_ methods, restrict them to particular parts of the codebase via testing or metaprogramming magic, etc.

---

This is true if your application is running on a shared servers - however if you have fully isolated application and database deploys then you really do benefit from a security and scalability perspective- and by being able to run closer to your clients. I'd also say that it works better when you have 100s, rather than thousands of clients, most probably larger organisations at this point.

---

For Postgress you can use and scale one schema per customer (B2B). Even then, depending on the instance size you will be able to accommodate 2000-5000 customers at max on a Postgres database instance. We have scaled one schema per customer model quite well so far (https://axioms.io/product/multi-tenant/).
That said, there are some interesting challenges with this model like schema migration and DB backups etc. some of which can be easily overcome by smartly using workers and queuing. We run migration per schema using a queue to track progress and handle failures. We also avoid migrations by using Postgres JSON fields as much as possible. For instance, creating two placeholder fields in every table like metadata and data. To validate data in JSON fields we use JSONSchema extensively and it works really well.

Probably you also need to consider application caching scenarios. Even you managed to do one database per customer running Redis instance per customer will be a challenge. Probably you can run Redis as a docker container for each customer.

---

I worked for a company that did this, we had hundreds of database instances, one per customer (which was then used by each of those customers' employees).
It worked out pretty well. The only downside was that analytics/cross customer stats were kind of a pain.

The customers all seemed to like that their data was separate from everyone else's. This never happened, but if one database was compromised, everyone else's would have been fine.

If I were starting a B2B SaaS today where no customers shared data (each customer = a whole other company) I would use this approach.

---

It has been an actual requirement from our customers that they don't share an instance or database with other customers. It also seriously limits the scope of bugs in permissions checks. Sometimes I will find a bit of code that should be doing a permissions check but isnt which would be a much bigger problem if it was shared with other companies.

---

As one example, New Relic had a table per (hour, customer) pair for a long time. From http://highscalability.com/blog/2011/7/18/new-relic-architec... (2011):

> Within each server we have individual tables per customer to keep the customer data close together on disk and to keep the total number of rows per table down.
---

I've maintained an enterprise saas product for ~1500 customers that used this strategy. Cross account analytics were definitely a problem, but the gaping SQL injection vulnerabilities left by the contractors that built the initial product were less of a concern.
Snapshotting / restoring entire accounts to a previous state was easy, and debugging data issues was also much easier when you could spin up an entire account's DB from a certain point in time locally.

We also could run multiple versions of the product on different schema versions. Useful when certain customers only wanted their "software" updated once every 6 months.

---

We do that where I am. I think it's been in place for about twenty years - certainly more than a decade. We're on MySQL/PHP without persistent connections. There have been many questionable architectural decisions in the codebase, but this isn't one of them. It seems quite natural that separate data should be separated and it regularly comes up as a question from potential clients.

---

Schemas[0] are the scalable way to do this, not databases, at least in Postgres.
If you're going to go this route you might also want to consider creating a role-per-user and taking advantage of the role-based security features[1].

That said, this is not how people usually handle multi-tenancy, for good reason, the complexity often outweighs the security benefit, there are good articles on it, and here's one by CitusData[2] (pre-acquisition).

---

I’ve done this. But the service was suited for it in a couple ways;
1. Each tenant typically only has <10 users, never >20. And load is irregular, maybe only ever dealing with 2-3 connections simultaneously. Maybe <1000 queries per hour max. No concerns with connection bloat/inefficiency.

2. Tenants creates and archives a large number of rows on some tables. Mutable but in practice generally doesn’t change much. But >100M row count not unusual after couple years on service. Not big data by any means, limited fields with smallish data types, but...

I didn’t want to deal with sharding a single database. Also given row count would be billions or trillions at a point the indexing and performance tuning was beyond what I wanted to manage. Also, this was at a time before most cloud services/CDNs and I could easily deploy close to my clients office if needed. It worked well and I didn’t really have to hire a DBM or try to become one.

Should be noted, this was a >$1000/month service so I had some decent infrastructure budget to work with.

---

I guess the question is, why do you want to?
The only real reason you mention is security, but to me this sounds like the worst tool for the job. Badly written queries accidentally returning other users' data, that makes it into production, isn't usually a common problem. If for some reason you have unique reasons that it might be, then traditional testing + production checks at a separate level (e.g. when data is sent to a view, double-check only permitted user ID's) would probably be your answer.

If you're running any kind of "traditional" webapp (millions of users, relatively comparable amounts of data per user) then separate databases per user sounds like crazytown.

If you have massive individual users who you think will be using storage/CPU that is a significant percentage of a commodity database server's capacity (e.g. 1 to 20 users per server), who need the performance of having all their data on the same server, but also whose storage/CPU requirements may vary widely and unpredictably (and possibly require performance guarantees), then yes this seems like it could be an option to "shard". Also, if there are very special configurations per-user that require this flexibility, e.g. stored on a server in a particular country, with an overall different encryption level, a different version of client software, etc.

But unless you're dealing with a very unique situation like that, it's hard to imagine why you'd go with it instead of just traditional sharding techniques.

---

I have used this architecture at 2 companies and it is by far the best for B2B scenarios where there could be large amounts of data for a single customer.
It is great for data isolation, scaling data across servers, deleting customers when they leave easily.

The only trick are schema migrations. Just make sure you apply migration scripts to databases in an automated way. We use a tool called DbUp. Do not try to use something like a schema compare tool for releases.

I have managed more than 1500 databases and it is very simple.

---

WordPress Multisite gives each blog a set of tables within a single database, with each set of tables getting the standard WordPress prefix ("wp_") followed by the blog ID and another underscore before the table name. Then with the hyperdb plugin you can create rules that let you shard the tables into different databases based on your requirements. That seems like a good model that gives you the best of both worlds.

---

I have a bit of experience with this. A SaaS company I used to work with did this while I worked there, primarily due to our legacy architecture (not originally being a SaaS company)
We already had experience writing DB migrations that were reliable, and we had a pretty solid test suite of weird edge cases that caught most failures before we deployed them. Still, some problems would inevitably fall through the cracks. We had in-house tools that would take a DB snapshot before upgrading each customer, and our platform provided the functionality to leave a customer on an old version of our app while we investigated. We also had tools to do progressive rollouts if we suspected a change was risky.

Even with the best tooling in the world I would strongly advise against this approach. Cost is one huge factor - the cheapest RDS instance is about $12/month, so you have to charge more than that to break even (if you're using AWS- we weren't at the time). But the biggest problems come from keeping track of scaling for hundreds or thousands of small databases, and paying performance overhead costs thousands of times.

<!-- TODO: discuss on twitter -->
