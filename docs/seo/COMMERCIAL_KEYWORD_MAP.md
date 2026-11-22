# Commercial keyword map

Which buyer searches each WalStack page should answer, ranked by plausible commercial value rather than search volume. Prepared 22 November 2026. Review it with the [28-day scorecard](../growth/SEO_REVIEW_SCORECARD.md) and the editorial [commercial content map](COMMERCIAL_CONTENT_MAP.md).

## Evidence used, and its limits

- **Search Console (owner-supplied, 23 Oct to 19 Nov 2026):** walstack.io had 160 page-grouped impressions and 2 clicks, mostly from informational queries. databasedeveloper.dev had 5,430 impressions and 34 clicks, led by locking, sharding, pg_upgrade failures, slow-after-upgrade and RDS/Aurora support deadlines. The two properties are not deduplicated, and almost all of the window predates the 22 November rewrite. No query-level export was available to this review.
- **Volume estimates (owner-supplied, US, from earlier OpenSEO research):** "postgresql consulting", "postgresql consultant" and "postgresql consultants" about 30 a month each; "sql server consulting services" about 110; "postgres performance tuning" about 110 (mostly informational). Closely related terms can share an estimate, so these figures are not additive. No other volumes or difficulty scores are given below, because none were measured.
- **SERP spot checks (one US web search per term, 22 Nov 2026).** These record the kinds of result that rank, not positions:
  - "postgresql consultant": the PostgreSQL.org regional directories, large firms (Pythian, Percona, CYBERTEC, Instaclustr), marketplaces (Upwork, Toptal, Fiverr) and a few independent consultants.
  - "postgresql upgrade consulting": vendor service pages (EDB, Fastware, CYBERTEC, Percona), with cloud-provider upgrade documentation mixed in.
  - "sql server consulting services performance": established independents (Erik Darling, Straight Path), Pythian, Toptal and Azure Marketplace fixed-scope offers.
  - "aurora postgresql performance issues": almost entirely AWS documentation and Knowledge Center articles. This is a troubleshooting query, not a buying query.
  - "database code review migration review service": no service results. GitLab's database review guidelines and cloud migration products rank.
- **Indexing state (stored URL Inspection results, not a live crawl):** `/` indexed. `/postgresql-performance-investigation`, `/postgresql-upgrade-readiness`, `/sql-server-performance` and `/pricing` crawled, not indexed. `/snapshot`, `/query-rescue` and `/database-code-review` unknown.

Confidence ratings: **High** means demand and intent are both evidenced. **Medium** means intent is clear but demand is unmeasured or small. **Low** means it is a hypothesis to test.

## Priority order

| # | Cluster | Why first |
| --- | --- | --- |
| 1 | C. Major-version upgrades | The only cluster with search exposure on the old domain, a deadline (RDS PostgreSQL 14 standard support ends 28 Feb 2027) and a priced offer. The lab-backed guides already rank. |
| 2 | A. PostgreSQL consulting | Direct buying intent and the PostgreSQL.org listing already ranks for it, but volume is small and the SERP is dominated by firms and directories. |
| 3 | B. PostgreSQL performance problems | Large informational volume that reaches the paid investigation through guides, not head terms |
| 4 | D. SQL Server | Higher volume than the PostgreSQL consulting terms, but a crowded field of established specialists. It is a secondary capability. |
| 5 | E. Database code review | No observed search demand. Useful as a sales and partner offer, not an SEO target. |
| 6 | F. Agency specialists | Hypothesis only. Reach agencies through outreach and referrals rather than search. |

## Cluster detail

### A. PostgreSQL consulting

| Field | Entry |
| --- | --- |
| Terms | PostgreSQL consultant, PostgreSQL consulting (services), PostgreSQL performance consultant, remote PostgreSQL consultant |
| Intent | Commercial: choosing a provider |
| Buyer | CTO, engineering manager or founder at a SaaS company without a DBA |
| Target page | `/` primary, `/postgresql-performance-investigation` secondary |
| GSC evidence | None in the walstack.io window. Brand-free consulting queries were not observed. |
| Metrics | About 30 a month each (shared estimate) |
| Competing results | PostgreSQL.org directory, consultancies, marketplaces, a few independents |
| Indexing | `/` indexed. The investigation page is crawled, not indexed. |
| Content gap | The homepage title already says "PostgreSQL Performance Consultant". The H1 is problem-led, which is right for conversion, and the eyebrow now carries "WalStack · PostgreSQL performance consultant". The investigation page repeats the homepage offer almost word for word, which may be why Google declined to index it. |
| Action | Done: title and eyebrow. Proposed (owner review): give the investigation page content the homepage lacks, such as a worked timeline of a real investigation step and the evidence list per symptom, rather than more keywords. Keep the PostgreSQL.org listing accurate, since it is the result most likely to send this traffic. |
| Business value | High per visit, low volume |
| Confidence | Medium |

### B. PostgreSQL performance problems

| Field | Entry |
| --- | --- |
| Terms | PostgreSQL performance investigation, Postgres slow query optimization service, RDS PostgreSQL slow queries, Aurora PostgreSQL performance issues, PostgreSQL production performance review |
| Intent | Mostly troubleshooting. "Service" and "consulting" variants are commercial but rare. |
| Buyer | Backend engineer or tech lead during or after a slowdown, who escalates to a manager to pay |
| Target page | `/postgresql-performance-investigation`; `/query-rescue` when one statement is known; `/aws-rds-aurora-postgresql` for managed-platform evidence |
| GSC evidence | Slow-query and pg_stat_statements guides received impressions on both properties |
| Metrics | "postgres performance tuning" about 110 a month, mostly informational |
| Competing results | AWS documentation and Knowledge Center dominate the RDS/Aurora terms. Vendor blogs and monitoring tools rank for tuning. |
| Indexing | Investigation page crawled, not indexed. Query Rescue unknown. |
| Content gap | WalStack cannot outrank AWS documentation for "Aurora PostgreSQL performance issues". The realistic route is a guide that ranks for a specific symptom and hands over to the paid service. |
| Action | Done: guides now route to the matching offer. Query Rescue no longer sends a reader who knows the statement to the full-cluster snapshot. Proposed: one symptom guide for a gap such as "Aurora PostgreSQL high CPU after upgrade", only if Search Console shows impressions for it. |
| Business value | Medium. Volume is real but buying intent is indirect. |
| Confidence | Medium |

### C. Major-version upgrades

| Field | Entry |
| --- | --- |
| Terms | PostgreSQL upgrade consulting, PostgreSQL major version upgrade assessment, RDS PostgreSQL upgrade readiness, Aurora PostgreSQL upgrade consultant, PostgreSQL upgrade regression testing |
| Intent | Commercial for "consulting"/"assessment"; planning and troubleshooting for the rest |
| Buyer | Platform or engineering lead with PostgreSQL 14 instances and an RDS deadline |
| Target page | `/postgresql-upgrade-readiness`, fed by `/postgresql-14-eol`, `/insights/pg-upgrade-check-failures`, `/insights/postgresql-slow-after-major-upgrade`, `/insights/rds-aurora-postgresql-14-extended-support-cost`, `/insights/rds-aurora-postgresql-14-to-18-blue-green` |
| GSC evidence | Strongest on the old domain: pg_upgrade failures, slow after upgrade, RDS/Aurora support deadlines. walstack.io also showed impressions for the support-cost, minor-deadline, EOL and upgrade-check guides. |
| Metrics | None measured for the commercial variants |
| Competing results | EDB, Fastware, CYBERTEC and Percona service pages, plus cloud upgrade documentation |
| Indexing | Service page crawled, not indexed |
| Content gap | The service page H1 was only about PostgreSQL 14 Extended Support. That made the service look temporary. |
| Action | Done: an evergreen H1 and description ("major-version upgrade on RDS, Aurora or a self-managed server"), with PostgreSQL 14 kept as a supporting section, links to the five lab-tested upgrade guides, and upgrade-specific CTAs throughout. Every upgrade guide now leads to "Ask about upgrade readiness" instead of the performance snapshot. Proposed: after deployment, request indexing for the service page once. |
| Business value | Highest. It is priced, deadline-driven and already visible. |
| Confidence | High |

### D. SQL Server

| Field | Entry |
| --- | --- |
| Terms | SQL Server consulting services, SQL Server performance consultant, SQL Server Query Store expert, SQL Server blocking investigation |
| Intent | Commercial |
| Buyer | .NET or enterprise SaaS team without a DBA |
| Target page | `/sql-server-performance`, fed by the parameter-sniffing and implicit-conversion guides |
| GSC evidence | The earlier content map records historical service impressions and a "sql server performance" query |
| Metrics | "sql server consulting services" about 110 a month |
| Competing results | Established independents with long track records, Pythian, Toptal, Azure Marketplace fixed-scope listings |
| Indexing | Crawled, not indexed |
| Content gap | The page title said "Performance Review". The closing CTA sent SQL Server buyers to the PostgreSQL snapshot. |
| Action | Done: title "SQL Server Performance Consulting: Query Store & Blocking", and the closing CTA now goes to `/contact?offer=sqlserver`. Do not build more SQL Server landing pages. `mssqlserver.dev` exists for broader SQL Server content. |
| Business value | Medium. It is secondary to the PostgreSQL wedge. |
| Confidence | Medium |

### E. Database code review

| Field | Entry |
| --- | --- |
| Terms | Database code review, PostgreSQL migration review, database schema migration review, SQL Server stored procedure review |
| Intent | Mixed. The SERP is about internal review guidelines and migration products, not buying a review. |
| Buyer | Engineering lead or agency about to ship a risky migration |
| Target page | `/database-code-review` |
| GSC evidence | None |
| Metrics | None |
| Competing results | GitLab's database review guidelines, cloud migration services |
| Indexing | Unknown |
| Content gap | The page pointed readers to the performance snapshot. |
| Action | Done: the hero and closing CTA go to the code review enquiry. Snapshot is mentioned only for changes that already shipped. Sell this offer through partners and outreach, not search. |
| Business value | Medium as a sales offer, low as SEO |
| Confidence | Low |

### F. Agency specialists

| Field | Entry |
| --- | --- |
| Terms | PostgreSQL consultant for agencies, white-label PostgreSQL engineering, fractional database engineer |
| Intent | Commercial, rare |
| Buyer | Agency owner or fractional CTO |
| Target page | `/partners` |
| GSC evidence | None |
| Metrics | None |
| Competing results | Not checked. Expect marketplaces and staffing firms. |
| Indexing | Unknown. The page had about 111 words. |
| Content gap | It was thin and its secondary button sent agencies to the public snapshot. |
| Action | Done: the page now covers partner types, when to collaborate, how the free first review is bounded, roles, white label, confidentiality, offers and a partnership enquiry. Use it as the link in partner outreach. Do not create more agency pages. |
| Business value | Potentially high per partner |
| Confidence | Low |

## Terms to avoid as primary targets

- **"Postgres engineer" / "PostgreSQL engineer".** These have strong job-search intent.
- **"walstack" alone.** WallStack wallpaper products dominate the results. Strengthen brand signals (done: WebSite schema, `og:site_name`, eyebrow) and fix the PostgreSQL.org listing name rather than chasing the term.
- **Generic "postgres performance tuning".** It is informational and dominated by vendors and tools. It reaches buyers through the guides.

## Proposed, not done (P2)

- Separate landing pages per keyword variant. Rejected: they would be near-duplicates and could dilute crawl attention on a new domain.
- A paid keyword tool subscription. Not before revenue. Search Console query exports cover the need.
- A comparison page against large consultancies. Wait until there is client evidence to cite.
