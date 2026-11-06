# Content distribution

Updated 6 November 2026.

## Share the measured upgrade guide

Guide: `https://walstack.io/insights/postgresql-slow-after-major-upgrade`

LinkedIn draft for Kiran's profile:

> A PostgreSQL major upgrade can finish cleanly and still leave a query slower the next morning.
>
> I reproduced this on generated data in a PostgreSQL 14 → 17 lab. The same join took 222 ms before the upgrade and 904 ms immediately after it. The upgraded cluster had no optimizer statistics, so the planner chose a nested loop with 2.7 million lookups. After staged `ANALYZE`, the query returned to 252 ms.
>
> The useful upgrade check is to capture important plans and workload timings before the cutover, then compare them after statistics are rebuilt. The guide includes the read-only checks, the measured plans, and the limitations of the lab: https://walstack.io/insights/postgresql-slow-after-major-upgrade

Keep the generated-data disclosure in every excerpt. This is a technical post, not a client result or a promise about other workloads.

For the PostgreSQL-only feed, the guide is already listed in `src/data/posts.ts`. Register `https://walstack.io/rss/postgresql.xml` with Planet PostgreSQL if it has not been registered yet; feed inclusion alone does not submit it to an external publication.

## Relevant link from MSSQLServer.dev

The Hashnode article `https://mssqlserver.dev/in-memory-oltp-for-faster-sql-server-your-complete-guide` discusses a performance feature. Add this short, clearly separated note near its conclusion after checking the technical content is still accurate:

> **Production performance review:** In-Memory OLTP is one possible response to a measured bottleneck. For a fixed-scope review of Query Store, waits, blocking, plan changes and application SQL before choosing an intervention, see [WalStack's SQL Server performance review](https://walstack.io/sql-server-performance).

Avoid putting this consulting link on unrelated CTE, PIVOT or syntax tutorials. The primary WalStack offer remains PostgreSQL Performance Investigation.

## Planet PostgreSQL

Feed to register: `https://walstack.io/rss/postgresql.xml`. It lists only guides marked `postgresql: true` in `src/data/posts.ts` (PostgreSQL and pgvector); SQL Server, Snowflake and MongoDB posts stay out. Mark every new guide there.

Steps, from [Adding your blog to Planet PostgreSQL](https://planet.postgresql.org/add.html):

1. Check the [policy](https://www.postgresql.org/about/policies/planet-postgresql): English, about PostgreSQL, identified by the author's name, no advertising in the syndicated part, feed titles and domains within the PostgreSQL trademark policy.
2. Create a PostgreSQL community account in your own name.
3. Register the feed on the Planet registration site and wait for moderator approval.

The feed carries title and summary only, so the offer boxes on the pages are not syndicated. Moderators say the usual rejection is failing the "ad test": a post must still be useful with all non-PostgreSQL material removed. Every guide in the feed passes that today; keep it so.

## Postgres Weekly

Published by Cooperpress. No public submission address was found on postgresweekly.com on 27 October 2026; subscribe, and check an emailed issue's footer for how to send links before writing. Issue 670 (21 October) led with PostgreSQL 19 RC1, so the async I/O lab is the most topical link.

Draft:

> Subject: Lab: PostgreSQL 18 io_method on cold scans (worker vs io_uring vs sync)
>
> Hi,
>
> A reproducible PostgreSQL 18.6 lab comparing io_method settings on cold sequential and bitmap heap scans. worker cut the sequential scan by about a third; io_uring won on the bitmap scan instead, and effective_io_concurrency above 16 changed nothing on that shape. It covers how to see async reads in pg_aios and why laptop numbers understate network storage.
>
> https://walstack.io/insights/postgresql-18-async-io-io-method
> Script and full output: https://github.com/kiransabne04/databasedeveloper.dev/tree/main/labs/pg18-async-io
>
> Kiran Sabne
