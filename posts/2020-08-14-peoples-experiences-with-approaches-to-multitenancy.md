---
title: People's experiences with approaches to multitenancy
created_at: 2020-08-14T11:13:40.478Z
author: Tomasz Wróbel
tags: []
publish: false
---

# People's experiences with approaches to multitenancy

Recently I've been researching the topic of multitenancy in Rails. You might have already seen the [previous blogpost comparing approaches to multitenancy](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/).

In the meantime there was another [discussion about multitenancy on HN](https://news.ycombinator.com/item?id=23305111) which pretty much blew up. It means that a lot of people have experiences in the topic and their opinions were strong enough to go and post about them.

I don't typically read all the comments on HN, but this time I wanted to go through it to know people's experiences on the topic I was researching.

This was the original question:

> Ask HN: Has anybody shipped a web app at scale with 1 DB per account?
>
> A common way of deploying a web application database at scale is to setup a MySQL or Postgres server, create one table for all customers, and have an account_id or owner_if field and let the application code handle security. This makes it easier to run database migrations and upgrade code per customer all at once.
>
> I’m curious if anybody has taken the approach of provisioning one database per account? This means you’d have to run migrations per account and keep track of all the migration versions and statuses somewhere. Additionally, if an application has custom fields or columns, the differences would have to be tracked somehow and name space collisions managed.
>
> Has anybody done this? Particularly with Rails? What kinda of tools or processes did you learn when you did it? Would you do it again? What are some interesting trade offs between the two approaches?

The original question asks about db-level multitenancy, but a lot of answers relate to schema-level as well (which people also often explicitly related to). Also schema-level in Postrgres has a lot in common with db-level in MySQL as you can read in [my previous blogpost](https://blog.arkency.com/comparison-of-approaches-to-multitenancy-in-rails-apps/).

Below are some quotes that drew my attention, extracted to save you some time. They seem to be pretty harsh on db/schema-level approach at the begginning, with more balanced takes coming in later parts of the discussion.

All the credit goes of course to original comments' authors. You can easily find them by grepping the original [discussion page](https://news.ycombinator.com/item?id=23305111).

\*\*\*

My startup currently does just this 'at scale', which is for us ~150 b2b customers with a total database footprint of ~500 GB. We are using Rails and the Apartment gem to do mutli-tenancy via unique databases per account with a single master database holding some top-level tables.

This architecture decisions is one of my biggest regrets, and we are currently in the process of rebuilding into a single database model.

FWIW, this process has worked well for what it was originally intended to do. Data-security has a nice db level stopgap and we can keep customer data nicely isolated. It's nice for extracting all data from a single customer if we have extended debugging work or unique data modeling work. It saves a lot of application layer logic and code. I'm sure for the most part it makes the system slightly faster.

However as we have grown this has become a huge headache. It is blocking major feature refactors and improvements. It restricts our data flexibility a lot. Operationally there are some killers. Data migrations take a long time, and if they fail you are left with multiple databases in different states and no clear sense of where the break occurred.

Lastly, if you use the Apartment gem, you are at the mercy of a poorly supported library that has deep ties into ActiveRecord. The company behind it abandoned this approach as described here: https://influitive.io/our-multi-tenancy-journey-with-postgres-schemas-and-apartment-6ecda151a21f

\*\*\*

Echoing this as well, I worked for Influitive and was one of the original authours of apartment (sorry!)

There are a lot of headaches involved with the "tenant per schema" approach. Certainly it was nice to never have to worry about the "customer is seeing data from another customer" bug (a death knell if you're in enterprisish B2B software), but it added so many problems:

Migrations become a very expensive and time-consuming process, and potentially fraught with errors. Doing continious-deployment style development that involves database schema changes is close to impossible without putting a LOT of effort into having super-safe migrations.

You'll run into weird edge cases due to the fact that you have an absolutely massive schema (since every table you have is multiplied by your number of tenants). We had to patch Rails to get around some column caching it was doing.

Cloud DB hosting often doesn't play nice with this solution. We continually saw weird performance issues on Heroku Postgres, particularly with backup / restores (Heroku now has warnings against this approach in their docs)

It doesn't get you any closer to horizontal scalability, since connecting to a different server is significantly different than connecting to another schema.

It will probably push the need for a dedicated BI / DW environment earlier than you would otherwise need it, due to the inability to analyze data cross-schema.
    
I still think there's maybe an interesting approach using partioning rather than schemas that eliminates a lot of these problems, but apartment probably isn't the library to do it (for starters, migrations would be entirely different if partioning is used over schemas)

\*\*\*

I agree that migrations are painful at the best of times, but dealing with the complexity of migrating a single database is far simpler than dealing with migrating hundreds of schemas:

- Migrations will first of all just take longer - you're multiplying the number of schema changes by the number of tenants you have.

- While in an ideal world migrations should be purely run within a transaction, occasionally performance considerations mandate that you run without DDL transactions - when some tenants fail and your migrations are in a partially completed state for some of your tenants and not others, it can be scary and painful.

- In my experience, almost no one approaches data migrations in a way that is purely backwards compatible 100% of the time without exception. You certainly can, but there's a significant tax associated with this, and if you're in a traditional scoped environment, you can often get away with the potential for errors in the minuscule time that a schema change is operating (of course, some schema changes aren't run in minuscule times, but those are the ones you're more likely to plan for)

Going read only during migrations is an interesting approach, but there's real business costs associated with that (particularly if your migration speed is multiplied by running it across tenants).

I don't want to say that you should never isolate data on a schema level, but I do think it's something that shouldn't be a standard tool to reach for. For the vast majority of companies, the costs outweigh the benefits in my mind.

\*\*\*

Can confirm, here be dragons. I did a DB per tenant for a local franchise retailer and it was the worst design mistake I ever made, which of course seemed justified at the time (different tax rules, what not), but we never managed to get off it and I spent a significant amount of time working around it, building ETL sync processes to suck everything into one big DB, and so on.

Instead of a DB per tenant, or a table per tenant, just add a TenantId column on every table from day 1.

\*\*\*

I do both.

Have a tenant_id column in every table.

This gives me flexibility to either host each client separately or club them together.

\*\*\*

> How does the architecture block major refactors or improvements? Are you running a single codebase for all your tenants, albeit with separate schemas for each?

Here I'll give you one: If you want to change a property of the database that will give your specific use improved performance, you have no way to transactionally apply that change. Rolling back becomes a problem of operational scale, rolling out as well.

What if you need to release some feature, but that feature requires a database feature enabled? Normally you enable it once, in a transaction hopefully, and then roll out your application. With this style you have to wait for N database servers to connect, enable, validate, then go live before you can even attempt the application being deployed, much less if you get it wrong.

\*\*\*

For me it falls into the category of decisions that are easy to make and difficult to un-make. If for whatever reason you decide this was the wrong choice for you, be in tech needs (e.g. rails) or business needs, merging your data and going back into a codebase to add this level of filtering is a massive undertaking.

\*\*\*

Indeed, but if you are making a B2B enterprise/SMB SaaS, I think you are most likely to regret the opposite choice [1][2]. A lot of companies run a single instance, multitenant application and have to develop custom sharding functionality down the road when they realize the inevitable: that most joins and caches are only needed on strict subsets of the data that are tenant specific.

If you get successful enough in this type of application space, you reach a mature state in which you need to be able to:

* Run large dedicated instances for your largest customers, because either their performance or security requirements mandate it.

* Share resources among a large number of smaller customers, for efficiency and fault tolerance reasons.

You can get there in two ways:

* You start with a massive multi tenant application, and you figure out a way to shard it and separate in pieces later.

* You start with multiple small applications, and you develop the ability to orchestrate the group, and scale the largest of them.

I would argue the latter is more flexible and cost efficient, and requires less technical prowess.

\*\*\*

I’ve managed a system with millions of users and tens of billions of rows, and I always dreamed of DB per user. Generally, \~1% of users were active at a given time, but a lot of resources were used for the 99% who were offline (eg, indexes in memory where 99% of the data wouldn’t be needed). Learned a few tricks. If this is the problem you're trying to solve, some tips below.

\*\*\*

> You can always take a multi-tenant system and convert it into a single-tenant system a lot more easily. First and foremost, you can simply run the full multi-tenant system with only a single tenant, which if nothing else enables progressive development (you can slowly remove those now-unnecessary WHERE clauses, etc).

True, but:

In my experience by the time you reach this point you have a lot of operational complexity because you and your team are used to your production cluster being a single behemoth, so chances are it's not easy to stand up a new one or the overhead for doing so is massive (i.e. your production system grew very complex because there is rarely if ever a need to stand up a new one).

Additionally, a multi tenant behemoth might be full of assumptions that it's the only system in town therefore making it hard to run a separate instance (i.e. uniqueness constraints on names, IDs, etc).

\*\*\*

If an "account" is an "enterprise" customer (SMB or large, anything with multiple user accounts in it), then yes, I know at least a few successful companies, and I would argue in a lot of scenarios, it's actually advantageous over conventional multitenancy.

The biggest advantage is flexibility to handle customers requirements (e.g. change management might have restrictions on versioning updates) and reduced impact of any failures during upgrade processes. It's easier to roll out upgrades progressively with proven conventional tools (git branches instead of shoddy feature flags). Increased isolation is also great from a security standpoint - you're not a where clause away from leaking customer data to other customers.

I would go as far as saying this should be the default architecture for enterprise applications. Cloud infrastructure has eliminated most of the advantages of conventional multitenancy.

If an account is a single user then no.

PS: I have a quite a lot of experience with this so if you would like more details just ask.

\*\*\*

Yes, for multi-tenancy. Database per tenant works alright if you have enterprise customers - i.e. in the hundreds, not millions - and it does help in security. With the right idioms in the codebase, it pretty much guarantees you don't accidentally hand one tenant data belonging to a different tenant.

MySQL connections can be reused with database per tenant. Rack middleware (apartment gem) helps with managing applying migrations across all databases, and with the mechanics of configuring connections to use a tenant based on Host header as requests come in.

\*\*\*

Not a problem with MySQL, "use `tenant`" switches a connection's schema.

Rails migrations work reasonably well with apartment gem. Never had a problem with inconsistent database migrations. Sometimes a migration will fail for a tenant, but ActiveRecord migrations records that, you fix the migration, and reapply, a no-op where it's already done.

\*\*\*

Using schemas gives you imperfect but still improved isolation. It's still possible for a database connection to cross into another tenant, but if your schema search path only includes the tenant in question, it significantly reduces the chance that cross-customer data is accidentally shared.

\*\*\*

> It's a terrible idea in the same way that using PHP instead of Rust to build a production large scale application is a terrible idea (i.e. it's actually a great idea but it's not "cool").

It’s not a cool factor issue. It’s an issue of bloating the system catalogs, inability to use the buffer pool, and having to run database migrations for each and every separate schema or maintaining concurrent versions of application code to deal with different schema versions.

\*\*\*

As you can see now that the thread has matured, there are a lot of proponents of this architecture that have production experience with it, so it's likely not as dumb as you assume.

\*\*\*

> As you can see now that the thread has matured, there are a lot of proponents of this architecture that have production experience with it, ...

Skimming through the updated comments I do not see many claiming it was a good idea or successful at scale. It may work fine for 10s or even 100s of customers, but it quickly grows out of control. Trying to maintain 100,000 customer schemas and running database migrations across all of them is a serious headache.

> ...so it's likely not as dumb as you assume.

I'm not just assuming, I've tried out some of the ideas proposed in this thread and know first hand they do not work at scale. Index page caching in particular is a killer as you lose most benefits of a centralized BTREE structure when each customer has their own top level pages. Also, writing dynamic SQL to perform 100K "... UNION ALL SELECT * FROM customer_12345.widget" is both incredibly annoying and painfully slow.

\*\*\*

I don't think we share the definition of "scale".

Extremely few companies that sell B2B SaaS software for enterprises have 10K customers, let alone 100K (that's the kind of customer base that pays for a Sauron-looking tower in downtown SF). Service Now, Workday, etc, are publicly traded and have less than 5000 customers each.

All of them also (a) don't run a single multitenant cluster for all their customers and (b) are a massive pain in the ass to run in every possible way (an assumption, but a safe one at that!).

\*\*\*

In the past I worked at a company that managed thousands of individual MSSQL databases for individual customers due to data security concerns. Effectively what happened is the schema became locked in place since running migrations across so many databases became hard to manage.

I currently work at a company where customers have similar concerns around data privacy, but we've been to continue using a single multitenant DB instance by using PostgreSQL's row level security capabilities where rows in a table are only accessible by a given client's database user:

https://www.postgresql.org/docs/9.5/ddl-rowsecurity.html

We customized both ActiveRecord and Hibernate to accommodate this requirement.

\*\*\*

I am aware of at least one company which does this from my consulting days, and would caution you that what you get in perceived security benefits from making sure that tenants can't interact with each others' data you'll give back many times over with engineering complexity, operational issues, and substantial pain to resolve \~trivial questions.

I also tend to think that the security benefit is more theatre than reality. If an adversary compromises an employee laptop or gets RCE on the web tier (etc, etc), they'll get all the databases regardless of whose account (if any) they started with.

(The way I generally deal with this in a cross-tenant application is to ban, in Rails parlance, Model.find(...) unless the model is whitelisted (non-customer-specific). All access to customer-specific data is through @current_account.models.find(...) or Model.dangerously_find_across_accounts(...) for e.g. internal admin dashboards. One can audit new uses of dangerously_ methods, restrict them to particular parts of the codebase via testing or metaprogramming magic, etc.

\*\*\*

This is true if your application is running on a shared servers - however if you have fully isolated application and database deploys then you really do benefit from a security and scalability perspective- and by being able to run closer to your clients. I'd also say that it works better when you have 100s, rather than thousands of clients, most probably larger organisations at this point.

\*\*\*

For Postgress you can use and scale one schema per customer (B2B). Even then, depending on the instance size you will be able to accommodate 2000-5000 customers at max on a Postgres database instance. We have scaled one schema per customer model quite well so far (https://axioms.io/product/multi-tenant/).

That said, there are some interesting challenges with this model like schema migration and DB backups etc. some of which can be easily overcome by smartly using workers and queuing. We run migration per schema using a queue to track progress and handle failures. We also avoid migrations by using Postgres JSON fields as much as possible. For instance, creating two placeholder fields in every table like metadata and data. To validate data in JSON fields we use JSONSchema extensively and it works really well.

Probably you also need to consider application caching scenarios. Even you managed to do one database per customer running Redis instance per customer will be a challenge. Probably you can run Redis as a docker container for each customer.

\*\*\*

I worked for a company that did this, we had hundreds of database instances, one per customer (which was then used by each of those customers' employees).

It worked out pretty well. The only downside was that analytics/cross customer stats were kind of a pain.

The customers all seemed to like that their data was separate from everyone else's. This never happened, but if one database was compromised, everyone else's would have been fine.

If I were starting a B2B SaaS today where no customers shared data (each customer = a whole other company) I would use this approach.

\*\*\*

It has been an actual requirement from our customers that they don't share an instance or database with other customers. It also seriously limits the scope of bugs in permissions checks. Sometimes I will find a bit of code that should be doing a permissions check but isnt which would be a much bigger problem if it was shared with other companies.

\*\*\*

As one example, New Relic had a table per (hour, customer) pair for a long time. From http://highscalability.com/blog/2011/7/18/new-relic-architecture-collecting-20-billion-metrics-a-day.html (2011):

> Within each server we have individual tables per customer to keep the customer data close together on disk and to keep the total number of rows per table down.

\*\*\*

I've maintained an enterprise saas product for \~1500 customers that used this strategy. Cross account analytics were definitely a problem, but the gaping SQL injection vulnerabilities left by the contractors that built the initial product were less of a concern.

Snapshotting / restoring entire accounts to a previous state was easy, and debugging data issues was also much easier when you could spin up an entire account's DB from a certain point in time locally.

We also could run multiple versions of the product on different schema versions. Useful when certain customers only wanted their "software" updated once every 6 months.

\*\*\*

We do that where I am. I think it's been in place for about twenty years - certainly more than a decade. We're on MySQL/PHP without persistent connections. There have been many questionable architectural decisions in the codebase, but this isn't one of them. It seems quite natural that separate data should be separated and it regularly comes up as a question from potential clients.

\*\*\*

Schemas[0] are the scalable way to do this, not databases, at least in Postgres.

If you're going to go this route you might also want to consider creating a role-per-user and taking advantage of the role-based security features[1].

That said, this is not how people usually handle multi-tenancy, for good reason, the complexity often outweighs the security benefit, there are good articles on it, and here's one by CitusData\[2] (pre-acquisition).

\*\*\*

I’ve done this. But the service was suited for it in a couple ways;

1. Each tenant typically only has <10 users, never >20. And load is irregular, maybe only ever dealing with 2-3 connections simultaneously. Maybe <1000 queries per hour max. No concerns with connection bloat/inefficiency.

2. Tenants creates and archives a large number of rows on some tables. Mutable but in practice generally doesn’t change much. But >100M row count not unusual after couple years on service. Not big data by any means, limited fields with smallish data types, but...

I didn’t want to deal with sharding a single database. Also given row count would be billions or trillions at a point the indexing and performance tuning was beyond what I wanted to manage. Also, this was at a time before most cloud services/CDNs and I could easily deploy close to my clients office if needed. It worked well and I didn’t really have to hire a DBM or try to become one.

Should be noted, this was a >$1000/month service so I had some decent infrastructure budget to work with.

\*\*\*

I guess the question is, why do you want to?

The only real reason you mention is security, but to me this sounds like the worst tool for the job. Badly written queries accidentally returning other users' data, that makes it into production, isn't usually a common problem. If for some reason you have unique reasons that it might be, then traditional testing + production checks at a separate level (e.g. when data is sent to a view, double-check only permitted user ID's) would probably be your answer.

If you're running any kind of "traditional" webapp (millions of users, relatively comparable amounts of data per user) then separate databases per user sounds like crazytown.

If you have massive individual users who you think will be using storage/CPU that is a significant percentage of a commodity database server's capacity (e.g. 1 to 20 users per server), who need the performance of having all their data on the same server, but also whose storage/CPU requirements may vary widely and unpredictably (and possibly require performance guarantees), then yes this seems like it could be an option to "shard". Also, if there are very special configurations per-user that require this flexibility, e.g. stored on a server in a particular country, with an overall different encryption level, a different version of client software, etc.

But unless you're dealing with a very unique situation like that, it's hard to imagine why you'd go with it instead of just traditional sharding techniques.

\*\*\*

I have used this architecture at 2 companies and it is by far the best for B2B scenarios where there could be large amounts of data for a single customer.

It is great for data isolation, scaling data across servers, deleting customers when they leave easily.

The only trick are schema migrations. Just make sure you apply migration scripts to databases in an automated way. We use a tool called DbUp. Do not try to use something like a schema compare tool for releases.

I have managed more than 1500 databases and it is very simple.

\*\*\*

WordPress Multisite gives each blog a set of tables within a single database, with each set of tables getting the standard WordPress prefix ("wp_") followed by the blog ID and another underscore before the table name. Then with the hyperdb plugin you can create rules that let you shard the tables into different databases based on your requirements. That seems like a good model that gives you the best of both worlds.

\*\*\*

I have a bit of experience with this. A SaaS company I used to work with did this while I worked there, primarily due to our legacy architecture (not originally being a SaaS company)

We already had experience writing DB migrations that were reliable, and we had a pretty solid test suite of weird edge cases that caught most failures before we deployed them. Still, some problems would inevitably fall through the cracks. We had in-house tools that would take a DB snapshot before upgrading each customer, and our platform provided the functionality to leave a customer on an old version of our app while we investigated. We also had tools to do progressive rollouts if we suspected a change was risky.

Even with the best tooling in the world I would strongly advise against this approach. Cost is one huge factor - the cheapest RDS instance is about $12/month, so you have to charge more than that to break even (if you're using AWS- we weren't at the time). But the biggest problems come from keeping track of scaling for hundreds or thousands of small databases, and paying performance overhead costs thousands of times.

\*\*\*

> Virtual Private Databases.

> What a lot of enterprise SaaS vendors do is have one single database for all customer data (single tenant). They then use features like Virtual Private Database to hide customer A data from customer B. So that if customer A did a “select \*” they only see their own data and not all of the other customers data. This creates faux multi-tenancy and all done using a single db account.

This sounds very much like Row Level Security, but I've never heard the term "Virtual Private Database" to describe it.

\*\*\*

What we do at my current job is server per multiple accounts each server holds 500-1000 "normal sized" customers and the huge or intensive customers get their own server with another 10-50 customers Currently moving from EC2 + mysql 5.7 to RDS, mainly for ease of managing.

However, we dont use a tenent id in all tables to differentiate customers we use (confusingly named) DB named prefix + tenent id for programatically making the connection.

Have a single server + db for shared data of tenents like product wide statistics, user/tenent data and mappings and such things. In the tenent table just have column for the name of the DB server for that tenent and that's pretty much it. Migrations are handled by an internal tool that executes the migrations on each tenent DB and 99% of the time everything works just fine if you are careful on what kind of migration you do and how you write your code

Some pitfalls concern column type changes + the read replicas going out of sync but that was a single incident that only hurt the replica.

\*\*\*

When using a single db I'd highly recommend adding `account_id` to every single table that contains data for multiple accounts. It's much easier to check every query contains `account_id`, as opposed to checking multiple foreign keys etc. Depending on the db you can then also easily export all data for a specific account using filters on the dump tool

\*\*\*

> Seems impractical and slow at scale to manage even a few hundred separate databases. You lose all the advantages of the relational model — asking simple questions like “Which customers ordered more than $100 last month” require more application code. You might as well store the customer info in separate files on disk, each with a different possible format and version.

Those queries are definitely convenient early on but eventually you shouldn't be making those against that system and instead aggregate the data into warehouse.

\*\*\*

In my case this worked out pretty well. Other than data separation and ease of scaling database per-customer (they might have different behavior of read/write operations), they other benefit was that we could place customer's database in any jurisdiction, which for some enterprise customers appeared an important point, regulations wise...

\*\*\*

The apartment gem enables multi-tenant Rails apps using the Postgres schemas approach described by others here.

It’s slightly clunky in that the public, shared schema tables, say, the one that holds the list of tenants, exists in every schema — they’re just empty.

I rolled my own based on apartment that has one shared public schema, and a schema for each tenant. Works well.

\*\*\*

> Seems pretty odd. The closest example I can think of would be maybe salesforce? Which basically, as far as I can tell, launches a whole new instance of the application (hosted by heroku?) for each client. I'm not a 100% sure about this, but i think this is how it works.

Not at all how Salesforce works, they take a lot of pride in their multi-tenant setup (for better or worse). Every org on a given instance shares the same application servers and Oracle cluster.

If I were to make a Salesforce competitor that’s one thing I would do differently, with tools like Kubernetes it’s a lot easier to just give every customer their own instances. Yes, it can take up more resources - but I cannot imagine the security nightmare involved with letting multiple customers execute code (even if it’s theoretically sandboxed) in the same process, plus the headache that is their database schema.

\*\*\*

As snuxoll writes, Salesforce does use a shared database with tenant_id (org_id) as a column on every table. You can read a lot about our multi-tenancy mechanisms in a whitepaper published a while back [https://developer.salesforce.com/wiki/multi_tenant_architecture].

\*\*\*

There aren't a lot of benefits to doing it. If you have frequent migrations, then it probably isn't something you ever want to do.

For a site I run, I have one large shared read-only database everyone can access, and then one database per user.

The per-user DB isn't the most performant way of doing things, but it made it easier to:

+ Encrypt an entire user's data at rest using a key I can't reverse engineer. (The user's DB can only be accessed by the user whilst they're logged in.)

+ Securely delete a user's data once they delete their account. (A backup of their account is maintained for sixty days... But I can't decrypt it during that time. I can restore the account by request, but they still have to login to access it).

There are other, better, ways of doing the above.

\*\*\*

How about dozens per account? :) I didn’t ship this, but I work for Automattic and WordPress.com is basically highly modified WordPress MU. This means every time you spin up a site (free or otherwise) a bunch of tables are generated just for that site. There’s at least hundreds of millions of tables. Migrating schema changes isn’t something I personally deal with, but it’s all meticulously maintained. It’s nothing special on the surface.

You can look up how WordPress MU maintains schema versions and migrations and get an idea of how it works if you’re really curious. If you don’t have homogeneous migrations, it might get pretty dicey, so I’d recommend not doing that.

\*\*\*

Jira Cloud and Confluence use a DB per user architecture at reasonable, but not outrageous, scale. I can't share numbers because I am an ex-employee, but their cloud figures are high enough. This architecture requires significant tooling an I don't recommend it. It will cause you all kinds of headaches with regards to reporting and aggregating data. You will spend a small fortune on vendor tools to solve these problems. And worst of all despite your best efforts you WILL end up with "snowflake" tenants whose schemas have drifted just enough to cause you MAJOR headaches.

\*\*\*

I have similar. One PG database per tenant (640). Getting the current DSN is part of auth process (central auth DB), connect through PGBouncer.

Schema migrations are kind of a pain, we roll out changes, so on auth there is this blue/green decision.

Custom fields in EAV data-tables or jsonb data.

Backups are great, small(er) and easier to work with/restore.

Easier to move client data between PG nodes. Each DB is faster than one large one. EG: inventory table is only your 1M records, not everyone's 600M records so even sequential scan queries are pretty fast.

\*\*\*

I worked for one of the biggest boarding school software companies. The only option was full-service, but clients could chose between hosted by us or hosted by them. We didn’t just do 1 database per school, we did entirely separate hardware/VMs per school. Some regions have very strict data regulations and the school’s compliance advisors tended to be overly cautious; they interpreted the regulations and translated them to even stricter requirements. These requirements were often impossible to satisfy. (How can the emergency roll call app both work offline AND comply with “no student PII saved to non-approved storage devices”? Does swap memory count as saving to a storage device?? Is RAM a “storage device”??? Can 7 red lines be parallel!?!?)

Shared DB instances would have been completely off the table. Thankfully, most boarding schools have massive IT budgets, so cost minimization was not as important as adding additional features that justified more spend. Also the market was quite green when I was there. Strangely, the software seemed to market itself; the number of out-of-the-blue demo requests was very high, so first impressions and conversion to paying clients was the primary focus.

\*\*\*

I worked for a company that did this, and our scale was quite large. It took a lot of work to get AWS to give us more and more databases on RDS. We had some unique challenges with scaling databases to appropriately meet the needs of each account. Specifically, it was difficult to automatically right-size a DB instance to the amount of data and performance a given customer would need. On the other hand, we did have the flexibility to manually bump an account's database to a much larger node size if we needed to help someone who was running into performance issues.

I think the biggest problems had to do with migrations and backups. We maintained multiple distinct versions of the application, and each had a unique DB schema, so there was frequent drift in the actual schemas across accounts. This was painful both from a maintenance POV, and for doing things like change data capture or ETLs into the data warehouse for data science/analysis.

Another big problem was dealing with backup/restore situations.

I suspect this decision was made early in the company's history because it was easier than figuring out how to scale an application originally designed to be an on-prem solution to become something that could be sold as a SaaS product.

Anyway, I think choosing a solution that nets your business fewer, larger database nodes will probably avoid a lot of maintenance hurdles. If you can think ahead and design your application to support things like feature flags to allow customers to gradually opt in to new versions without breaking backwards compatibility in your codebase, I think this is probably the better choice, but consider the safety and security requirements in your product, because there may be reasons you still want to isolate each tenant's data in its own logical database.

\*\*\*

Years ago I worked for a startup that provided CMS and ecommerce software for small business. Each of our 3000+ customers had their own MySQL database.

We had a long tail of customers with negligible usage and would run several thousand MySQL databases on a single server. As customers scaled we could migrate the database to balance capacity. We could also optionally offer "premium" and "enterprise" services that guaranteed isolation and higher durability.

Scaling was never a real issue, but the nature of our clients was steady incremental growth. I don't think we ever had a case of real "overnight success" where a shared host customer suddenly melted the infrastructure for everyone.

However, managing and migrating the databases could be a real issue. We had a few ways of handling it, but often would need to handle it in the code, `if schemaVersion == 1 else`. Over time this added up and required discipline to ensure migration, deprecation and cleanuop. As a startup, we mostly didn't have that discipline and we did have a fair bit of drift in versions and old code lying around.<Paste>

\*\*\*

B2B CRM space startup. We have somewhat of a middle-ground approach. Our level of isolation for customers is at a schema-level.

What this means is each customer has her own schema. Now, large customers want to be single tenant, so they have a single schema on the entire DB. Smaller (SMB) customers are a bit more price conscious so they can choose to be multitenant i.e multiple schemas on same DB.

Managing this is pushed out to a separate metadata manager component which is just a DB that maps customer to the DB/schema they reside on. Connection pooling is at the DB level (so if you are multitenant then you may have lower perf because some other customer in the DB is hogging the connections)... But this has not happened to us yet.

Large customers are more conscious in terms of data so want things like disc level encryption with their own keys etc, which we can provide since we are encrypting the whole DB for them (KMS is the fave here).

We are not really large scale yet, so dunno what they major gotchas will be once we scale, but this approach has served us well so far.

\*\*\*

Stackoverflow's DBA had just posted about this: https://twitter.com/tarynpivots/status/1260680179195629568

He has 564,295 tables in one SQL Server. Apparently this is for "Stack Overflow For Teams"

\*\*\*

One model I have seen used successfully is a hybrid model in which the product is designed to be multi-tenant, but then it is deployed in a mix of single tenant and multi-tenant instances. If you have a big mix of customer sizes (small businesses through to large enterprises) – single-tenant instances for the large enterprise customers gives them maximum flexibility, while multi-tenant for the small business customers (and even individual teams/departments within a large enterprise) keeps it cost-effective at the low end. (One complexity you can have is when a customer starts small but grows big – sometimes you might start out with just a small team at a large enterprise and then grow the account to enterprise scale – it can become necessary to design a mechanism to migrate a tenant from a multi-tenant instance into their own single-tenant instance.)

\*\*\*

There are definitely downsides to scaling out thousands of tenants - I've been told Heroku supports this, and at a glance I found this doc that says it may cause issues, https://devcenter.heroku.com/articles/heroku-postgresql#multiple-schemas but it really doesn't change whether you're on Heroku or not. At the end of the day it's just about your application structure, how much data you have, how many tables you have etc. Unfortunately the Apartment gem even has these problems, and even its creators have expressed some concern (https://mtm.dev/multitenancy-without-subdomains-rails-5-acts-as-tenant/#why-acts_as_tenant) about scalability with multiple schemas.

The acts_as_tenant gem might be what you’re looking for:

> This gem was born out of our own need for a fail-safe and out-of-the-way manner to add multi-tenancy to our Rails app through a shared database strategy, that integrates (near) seamless with Rails.

My recommended configuration to achieve this is to simply add a `tenant_id` column (or `customer_id` column, etc) on every object that belongs to a tenant, and backfilling your existing data to have this column set correctly. When a new account signs up, not a lot happens under-the-hood; you can create a row in the main table with the new account, do some initial provisioning for billing and such, and not much else. Being a multi-tenant platform you want to keep the cost really low of signing up new accounts. The easiest way to run a typical SQL query in a distributed system without restrictions is to always access data scoped by the tenant. You can specify both the tenant_id and an object’s own ID for queries in your controller, so the coordinator can locate your data quickly. The tenant_id should always be included, even when you can locate an object using its own object_id.

\*\*\*

Yes, we did it at Kenna Security. About 300 paying customers, but over 1000 with trials, and overall about 6B vulnerabilities being tracked (the largest table in aggregate). Some of the tables were business intelligence data accessible to all customers, so they were on a “master” DB that all could access; and some of the tables were fully multi-tenant data, so each customer had their MySQL DB for it.

The motivation was that we were on RDS’s highest instance and growing, with jobs mutating the data taking a less and less excusable amount of time.

The initial setup was using just the Octopus gem and a bunch of Ruby magic. That got real complicated really fast (Ruby is not meant to do systems programming stuff, and Octopus turned out very poorly maintained), and the project turned into a crazy rabbit hole with tons of debt we never could quite fix later. Over time, we replaced as many Ruby bits as we could with lower-level stuff, leveraging proxySQL as we could; the architecture should have been as low-level as possible from the get-go... I think Rails 6’s multi-DB mode was going to eventually help out too.

One fun piece of debt: after we had migrated all our major clients to their own shards, we started to work in parallel on making sure new clients would get their own shard too. We meant to just create the new shard on signup, but that’s when we found out, when you modify Octopus’s in-memory config of DBs, it replaces that config with a bulldozer, and interrupts all DB connections in flight. So, if you were doing stuff right when someone else signs up, your stuff would fail. We solved this by pre-allocating shards manually every month or so, triggering a manual blue-green deploy at the end of the process to gracefully refresh the config. It was tedious but worked great.

And of course, since it was a bunch of Active Record hacks, there’s a number of data-related features we couldn’t do because of the challenging architecture, and it was a constant effort to just keep it going through the constant bottlenecks we were meeting. Ha, scale.

Did we regret doing it? No, we needed to solve that scale problem one way or another. But it was definitely not solved the best way. It’s not an easy problem to solve.

\*\*\*

I believe that FogBugz used this approach, back in the day (with a SQL Server backend).

The reasoning was that customers data couldn't ever leak into each other, and moving a customer to a different server was easier. I vaguely recall Joel Spolsky speaking or writing about it.

\*\*\*

This question reminds me of some legacy system which I've seen in the past :D :D :D

In summary it was working in the following way:

There was table client(id, name).

And then dozens of other tables. Don't remember exactly the structure, so I will just use some sample names: - order_X - order_item_X - customer_X - newsletter_X

"X" being ID from the client table mentioned earlier.

Now imagine dozens of "template" tables become hundreds, once you start adding new clients. And then in the code, that beautiful logic to fetch data for given client :D

And to make things worse, sets of tables didn't have same DB schema. So imagine those conditions building selects depending on the client ID :D

\*\*\*

We did this in a company long long time ago, each customer had their own Access database running an ASP website. Some larger migrations were a pain, but all upgrades were billed from the customers, so it didn't affect anything.

If you can bill the extra computing and devops work from your customers, I'd go with separate environments alltogether. You can do this easily with AWS.

On the plus side you can roll out changes gradually, upgrade the environments one user at a time.

Also if Customer X pays you to make a custom feature for them, you can sell the same to all other users if it's generic enough.

\*\*\*

This is a common approach outside of the SaaS space. I'd worry less about Rails and tools, and more about the outcomes you need. If you have a smaller number of high value customers (big enterprises or regulated industries), or offer customers custom add-ons then it can be advantageous to give each customer their own database. Most of the HN audience will definitely not need this.

In some industries you'll also have to fight with lawyers about being allowed to use a database shared between customers because their standard terms will start with this separation. This approach is helpful when you have to keep data inside the EU for customers based there. If you want to get creative, you can also use the approach to game SLAs by using it as the basis to split customers into "pods" and even if some of these are down you may not have a 100% outage and have to pay customers back.

This design imposes challenges with speed of development and maintenance. If you don't know your requirements (think: almost any SaaS startup in the consumer or enterprise space) which is trying to find a niche, then following this approach is likely to add overhead which is inadvisable. The companies that can use this approach are going after an area they already know, and are prepared to go much more slowly than what most startup developers are used to.

Using row-level security or schemas are recommended for most SaaS/startup scenarios since you don't have N databases to update and keep in sync with every change. If you want to do any kind of split then you might consider a US/EU split, if your customers need to keep data in the EU, but it's best to consider this at the app-level since caches and other data stores start to become as important as your database when you have customers that need this.

Consideration should be given to URL design. When you put everything under yourapp.com/customername it can become hard to split it later. Using URLs like yourapp.com/invoice/kfsdj28jj42 where "kfsdj28jj42" has an index for the database (or set of web servers, databases, and caches) encoded becomes easier to route. Using customer.yourapp.com is a more natural design since it uses DNS, but the former feels more popular, possibly because it can be handled more easily in frameworks and doesn't need DNS setup in developer environments.

\*\*\*

We did this for 2 large projects I worked on. Works really well for env. where you can get a lot of data per customer. We had customers with up to 3-4 TB databases so any other option would either be crazy expensive to run and or to develop for. You need to invest a bit of time into nice tooling for this but in a grand scheme of things it's pretty easy to do.

\*\*\*

Yes!! In hosted forum software this is the norm. If you want to create an account you create an entire database for this user. It isn't that bad! Basically when a user creates an account you run a setup.sql that creates the db schema. Devops is pretty complex but is possible. EG! Adding a column - would be a script.

Scaling is super easy since you can move a db to another host.

\*\*\*

This is pretty much how WordPress.com works - or used to work, I don't know if they changed this.

Each account gets its own set of database tables (with a per-account table prefix) which are located in the same database. Upgrades can then take place on an account-by-account basis. They run many, many separate MySQL databases.

\*\*\*

Already some great answers. Some color: A lot of B2B contracts require this sort of "isolation". So if you read 1 database per account and think that's crazy, it's not that rare. Now you know! I certainly didn't 2 years ago.

\*\*\*

Nutshell does this! We have 5,000+ MySQL databases for customers and trials. Each is fully isolated into their own database, as well as their own Solr "core."

We've done this from day one, so I can't really speak to the downsides of not doing it. The piece of mind that comes from some very hard walls preventing customer data from leaking is worth a few headaches.

A few takeaways:

- Older MySQL versions struggled to quickly create 100+ tables when a new trial was provisioned (on the order of a minute to create the DB + tables). We wanted this to happen in seconds, so we took to preprovisioning empty databases. This hasn't been necessary in newer versions of MySQL.

- Thousands of DBs x 100s of tables x `innodb_file_per_table` does cause a bit of FS overhead and takes some tuning, especially around `table_open_cache`. It's not insurmountable, but does require attention.

- We use discrete MySQL credentials per-customer to reduce the blast radius of a potential SQL injection. Others in this thread mentioned problems with connection pooling. We've never experienced trouble here. We do 10-20k requests / minute.

- This setup doesn't seem to play well with AWS RDS. We did some real-world testing on Aurora, and saw lousy performance when we got into the hundreds / thousands of DBs. We'd observe slow memory leaks and eventual restarts. We run our own MySQL servers on EC2.

- We don't split ALBs / ASGs / application servers per customer. It's only the MySQL / Solr layer which is multi-tenant. Memcache and worker queues are shared.

- We do a DB migration every few weeks. Like a single-tenant app would, we execute the migration under application code that can handle either version of the schema. Each database has a table like ActiveRecord's migrations, to track all deltas. We have tooling to roll out a delta across all customer instances, monitor results.

- A fun bug to periodically track down is when one customer has an odd collection of data which changes cardinality in such a way that different indexes are used in a difficult query. In this case, we're comparing `EXPLAIN` output from a known-good database against a poorly-performing database.

- This is managed by a pretty lightweight homegrown coordination application ("Drops"), which tracks customers / usernames, and maps them to resources like database & Solr.

- All of this makes it really easy to backup, archive, or snapshot a single customer's data for local development.

\*\*\*

Thanks for reading to the very bottom. I hope it was valuable for you!
