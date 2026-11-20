# Commercial content map

Use this map when choosing which guide to improve and where to send a reader who needs paid help. Start with the decision the reader needs to make. Kiran owns this map and reviews it alongside the [28-day acquisition scorecard](../growth/SEO_REVIEW_SCORECARD.md).

## Evidence and status

The November 19 migration audit covers October 20 through November 16, 2026. Its page-grouped Search Console results show most search exposure still on the historical domain. Locking led the listed historical pages by impressions. Slow-after-upgrade led them by clicks. A read-only check of the connected WalStack property for the same final 28-day window also showed impressions for the RDS support-cost, PG14 minor-deadline, PG14 EOL and upgrade-check guides. Keep the two properties separate when reviewing trends. [Historical audit and exact figures](https://app.openseo.so/p/34bbbdb9-1a2a-42f5-a9ab-4b5fd89fc1c2/reports/19296388-2623-4fd6-a078-e77178855d3e)

“Historical” below refers to the old domain in that report. “WalStack” refers to the current domain in the same window. “Buyer scenario” is an editorial hypothesis grounded in a concrete engineering decision. It has no measured demand or revenue attached. “Current” identifies an existing route, “implemented” identifies a new route in this branch and “proposed” identifies a future mapping to test.

## Offers and decision pages

| URL | Search intent | Buyer relevance | Commercial offer | CTA | Evidence | Measurement | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `/` | Find the specialist and choose the right scope | High | PostgreSQL Performance Investigation | Request an Investigation | WalStack homepage received a search click | Homepage-originated accepted enquiries, then qualified opportunities | Current |
| `/postgresql-performance-investigation` | Determine why a production workload changed | High | PostgreSQL Performance Investigation | Request an Investigation | Historical audit found the service indexed on WalStack | Investigation submissions, qualification and paid investigations | Current |
| `/postgresql-upgrade-readiness` | Scope a version change and decide whether the workload is ready | High | PostgreSQL Upgrade Readiness | Ask about upgrade readiness | Historical upgrade-check and support-cost clicks | Upgrade enquiries, qualified release decisions and paid reviews | Current |
| `/query-rescue` | Commission analysis of one PostgreSQL or SQL Server statement | High | Query Rescue | Request a query review | Buyer scenario supported by existing slow-query and Query Store guides | Enquiries by engine and originating guide, then paid reviews | Implemented |
| `/database-code-review` | Get a bounded SQL change reviewed before rollout | High | Database Code Review | Request a database code review | Buyer scenario involving a defined migration or PR | Qualified bounded changes and accepted proposals | Implemented |
| `/postgresql-query-rescue` | Legacy PostgreSQL-only route for a single-query service | Medium | Query Rescue | Continue to `/query-rescue` | Existing URL retained as canonical/noindex compatibility page | Noindex route; monitor only for inbound legacy links | Implemented alias |
| `/postgresql-pr-review` | Legacy PostgreSQL-only route for code and migration review | Medium | Database Code Review | Continue to `/database-code-review` | Existing URL retained as canonical/noindex compatibility page | Noindex route; monitor only for inbound legacy links | Implemented alias |
| `/sql-server-performance` | Diagnose SQL Server performance across a workload | High | SQL Server Performance Review | Ask about a SQL Server review | Historical service impressions and “sql server performance” query | SQL Server submissions, qualified opportunities and paid work | Current |
| `/aws-rds-aurora-postgresql` | Interpret managed PostgreSQL evidence during a slowdown | High | PostgreSQL Performance Investigation | Request an Investigation | WalStack page impressions | RDS/Aurora investigation enquiries with platform context | Current |
| `/partners` | Find a specialist for an agency or delivery partner | High | Database Code Review or a separately scoped investigation | Explore a technical partnership | Buyer scenario involving a client release and an identified delivery owner | Genuine partner enquiries, scoped engagements and paid referrals | Current |
| `/pricing` | Compare scope before asking for a fee | High | Four offers plus separately scoped remediation | Choose the review that matches the decision | WalStack page impressions | Selected offer, successful submissions and accepted quotes | Current |
| `/sample-report` | Judge report depth before buying | High | PostgreSQL Performance Investigation | Request an Investigation | Existing clearly labelled synthetic deliverable | Sample-assisted submissions and qualified enquiries | Current |
| `/contact` | Submit a sanitized description and check fit | High | Selected service | Send an enquiry | Existing enquiry flow | Successful submissions reconciled with genuine buyer enquiries | Current |

## Diagnostic guides

For each guide, leave the tests, limitations and original sources accessible. Place one relevant offer at the point where the reader has enough evidence to choose a scope.

| URL | Search intent | Buyer relevance | Commercial offer | CTA | Evidence | Measurement | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `/postgresql-concurrency-and-locking-a-comprehensive-guide` | Identify the head blocker during a real wait | High | PostgreSQL Performance Investigation | Bring a sanitized blocking-chain snapshot | Historical impressions leader, with clicks | Guide-assisted enquiries about recurring contention | Current |
| `/insights/pg-upgrade-check-failures` | Interpret a failed compatibility check before the window | High | PostgreSQL Upgrade Readiness | Scope a review of the remaining blockers | Historical clicks and WalStack impressions | Upgrade-review submissions originating here, then confirmed opportunities | Current |
| `/insights/postgresql-slow-after-major-upgrade` | Explain a post-upgrade regression in representative plans | High | Query Rescue for an isolated statement | Request a review of the regressed query | Highest clicks among the seven historical pages highlighted in the audit | Query enquiries with this originating guide and actual scope fits | Current |
| `/postgresql-14-eol` | Decide when to leave a community-unsupported version | High | PostgreSQL Upgrade Readiness | Review blockers for the target version | Historical clicks and WalStack impressions | EOL-assisted readiness enquiries and paid reviews | Current |
| `/insights/rds-aurora-postgresql-14-extended-support-cost` | Weigh the cost of waiting against upgrade readiness | High | PostgreSQL Upgrade Readiness | Scope an assessment before choosing a window | Historical clicks and WalStack impressions | Qualified RDS/Aurora upgrade enquiries assisted by this page | Current |
| `/insights/postgresql-14-minor-version-deadlines` | Establish which managed-engine deadline applies | Medium | PostgreSQL Upgrade Readiness | Review the upgrade scope if blockers remain | WalStack page impressions | Readiness enquiries that include the platform and version | Current |
| `/insights/postgresql-slow-queries-pg-stat-statements` | Rank fingerprints and identify which query to examine | High | Query Rescue once a single statement is isolated | Bring the relevant statement and its execution context | WalStack page impressions | Query enquiries from this guide and qualified single-query work | Current |
| `/insights/sql-server-parameter-sniffing-query-store` | Test whether a parameter-sensitive plan explains a regression | High | Query Rescue | Request a review of the affected SQL Server statement | Historical property showed “parameter sniffing” impressions at query level | SQL Server query enquiries and paid reviews assisted by the guide | Current |
| `/insights/postgresql-find-unused-indexes` | Decide whether a proposed index removal is safe to test | High | Database Code Review for a defined index change | Scope the proposed index diff | Buyer scenario involving a concrete deployment decision | Index-change PR enquiries and paid reviews | Current |
| `/sharding-postgresql-techniques-for-horizontal-scalability` | Decide whether distribution is justified by observed capacity limits | Medium | PostgreSQL Performance Investigation | Establish the workload bottleneck before redesign | Historical impressions and clicks, plus WalStack impressions | Qualified investigation enquiries from readers with a measured bottleneck | Current |

## Maintenance

At each 28-day review, record the dates, property and evidence source before changing a priority. For a guide, follow its service link, confirm the chosen offer and source on the enquiry, then check the accepted submissions and CRM outcomes in aggregate. A visitor who opens a service page has shown interest. Only an actual submission, confirmed qualification or paid engagement can count toward its corresponding measure. Record insufficient data explicitly. Interview preparation and broad conceptual articles can remain useful without a new paid offer.

On November 20, 2026, both historical hostnames returned a single 301 to the matching WalStack URL for the homepage and all seven historical winners listed in the audit. Each destination returned 200. On the same day, Search Console URL Inspection returned matching declared and Google-selected WalStack canonicals for the investigation, SQL Server service and PG14 EOL pages. Its stored results showed the investigation indexed, with the other two marked “Crawled - currently not indexed” after their November 12 and November 18 crawls respectively. Prioritize those two URLs at the next review. [Migration baseline](https://app.openseo.so/p/34bbbdb9-1a2a-42f5-a9ab-4b5fd89fc1c2/reports/19296388-2623-4fd6-a078-e77178855d3e)
