# Content distribution

Updated 27 October 2026.

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
