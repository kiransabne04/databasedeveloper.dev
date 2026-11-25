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

## Independent review, 23 November 2026

Second-pass review of the map above and of an external keyword list. Evidence: the live site (production HTML matched `main` at `f7855d2`), the built site's internal links, and one US web search per new term.

### Findings

- **No technical indexing defect.** Every commercial page returns 200, has a self-referencing canonical, has no `noindex` meta or `X-Robots-Tag` header, and is in the sitemap. `robots.txt` allows everything. Old-domain article URLs reach walstack.io in one hop. The "crawled, not indexed" states for the investigation, upgrade, SQL Server, Query Rescue, Code Review, snapshot and pricing pages are Google's selection on a young domain. Most of these pages changed on 22 November, so the next useful signal is the re-inspection around 6 December.
- **Historical articles already route to the matching offer.** Locking, sharding, partitioning and the slow-query guide go to the investigation. The upgrade guides go to the upgrade enquiry. The parameter-sniffing guide goes to SQL Server and Query Rescue. No change needed.
- **Homepage service discovery is already handled.** The footer on every page links all seven services and partners. The nav carries investigation, snapshot, upgrade and pricing. The launch audit's rule that keeps Query Rescue, Code Review, SQL Server and partners out of the homepage body keeps the homepage on one offer. Nothing in Search Console shows that rule is costing discovery, so it stays.
- **One real internal-link gap.** `/aws-rds-aurora-postgresql` is the most detailed page on the RDS/Aurora wedge, but only three pages linked to it in their body, and the investigation page was not one of them. **Implemented:** one sentence on the investigation page links to it ("what each AWS source can and can't answer"). This also gives the investigation page content the homepage does not repeat.

### External keyword list: decisions

| Proposed cluster | What ranks (23 Nov) | Decision | Reason |
| --- | --- | --- | --- |
| Fractional / on-demand PostgreSQL DBA | Remote DBA subscriptions (Datavail, EDB, MinervaDB, MariaDB) offering 24×7 coverage | Reject | The SERP sells ongoing operational coverage. WalStack sells fixed-scope reviews and does not promise 24×7 response. |
| Freelance PostgreSQL DBA / independent Postgres engineer | Upwork, Toptal, Freelancer, Malt and job boards | Reject | Marketplace and job-search intent |
| PostgreSQL performance consultant / consulting services | See cluster A | Already solved | Homepage title carries it. Do not repeat it on the investigation page. |
| AWS RDS PostgreSQL performance tuning (consultant) | AWS documentation and Prescriptive Guidance, plus AWS Marketplace fixed-scope listings | Monitor | Buyer intent exists, but AWS documentation dominates. The RDS page already covers the topic. Retitling it would compete with the investigation page, whose title also says "RDS & Aurora". Revisit if Search Console shows impressions for the RDS page. |
| Reduce RDS/Aurora cost | Not checked separately | Reject as a target | No cost-reduction offer or evidence on the site. Claiming one would be new positioning. |
| RDS Proxy troubleshooting | Not checked | Monitor | Mentioned on the RDS page. A guide is justified only if Search Console shows demand. |
| PostgreSQL 14 to 17/18 upgrade service; RDS 14 end of support | AWS release calendar and upgrade documentation | Already solved | The upgrade page and five upgrade guides cover it, and every guide routes to the upgrade enquiry. |
| Zero-downtime major-version upgrade | Not checked | Reject | A promise the readiness review does not make. Blue/green is covered as a guide. |
| Partitioning consulting, pgvector tuning | Not checked | Reject for now | Secondary capabilities. Their guides already link to the investigation. No new pages before the first paid client. |
| Postgres slow query rescue; lock contention troubleshooting | Not checked | Already solved | Query Rescue page plus the locking guide, which routes to the investigation |

### Owner decision: target primary, secondary and long-tail terms

The owner decided on 23 November to target the primary map below now, rather than wait for the 6 December re-inspection. Every commercial title now leads with its primary term, and a funnel-audit check keeps it that way. Terms were added only where the page already does what the term describes. No keyword stuffing, and no promises the services don't make.

### Primary map (one main term per page)

Revised 24 November 2026 (owner-approved indexing-recovery brief) and 25 November 2026 (consulting-keyword audit). Service titles stay within about 60 characters. Titles lead with the primary term, and the funnel audit enforces it.

| Page | Primary term (title) | Secondary terms (eyebrow, H2s, FAQ) |
| --- | --- | --- |
| `/` | PostgreSQL performance consultant | PostgreSQL consultant, PostgreSQL consulting services (About H2, lede, Organization schema) |
| `/postgresql-performance-investigation` | PostgreSQL performance tuning & slowdown audit | Postgres slowdown investigation, performance audit, RDS/Aurora slow queries |
| `/postgresql-upgrade-readiness` | PostgreSQL 14 upgrade readiness assessment | RDS PostgreSQL 14 end of support, 14 to 17/18 upgrade, query regression testing, upgrade consulting |
| `/aws-rds-aurora-postgresql` | AWS RDS & Aurora PostgreSQL performance tuning consultant | RDS PostgreSQL consultant, Aurora PostgreSQL consultant (H1, eyebrow, H2, FAQ), cost optimization, high CPU, RDS Proxy pinning, Database Insights |
| `/query-rescue` | PostgreSQL slow query optimization | execution plan review, EXPLAIN ANALYZE review, ORM-generated SQL |
| `/database-code-review` | PostgreSQL schema & migration code review | migration lock risk, ALTER TABLE review |
| `/snapshot` | Free PostgreSQL health check | performance snapshot |
| `/partners` | PostgreSQL consultant for agencies | white-label database specialist, fractional CTO |
| `/pricing` | PostgreSQL consulting pricing | fixed-price PostgreSQL review (H1 now matches the title) |
| `/about` | Kiran Sabne, PostgreSQL performance consultant | RDS and Aurora PostgreSQL consultant |

Out of the index since 24 November (noindex,follow and out of the sitemap): `/sql-server-performance`, `/snowflake-performance`, `/olap-analytical-performance`, `/partner-kit`, `/privacy`, `/terms`. The SQL Server, Snowflake and pgvector guides stay indexed.

Guides stay informational. Each one hands off to the matching offer.

### Secondary list: long-tail phrases

No measured volume for any of these. Most are probably 0 to 10 searches a month. They are worth having because the person typing one is close to hiring. Use them in H2s, FAQ questions and guide handoff sentences, not as new pages. Promote a phrase to a title or FAQ change only when Search Console shows impressions for it.

**Investigation:** postgresql database slow after deploy consultant · hire postgresql expert to find slow queries · postgresql performance audit for saas · postgres high cpu root cause analysis service · pg_stat_statements analysis consultant · postgresql query regression investigation · why is my postgres database slow suddenly · one-time postgresql performance review fixed price · postgresql consultant for startups without a dba · postgres database bill went up

**RDS / Aurora (pushed hardest from 25 Nov; the consultant query has no independent consultants ranking):** aws rds postgresql consultant · aurora postgresql consultant · rds postgresql performance tuning consultant · aurora postgresql cost optimization consultant · remote aurora postgresql consultant · rds postgresql consultant cost · rds parameter group tuning postgresql · aurora postgresql high cpu troubleshooting expert · rds postgresql slow queries performance insights analysis · aurora postgresql performance review consultant · rds postgresql cpu spike root cause · aws database insights postgresql help · rds proxy connection issues postgresql · aurora postgresql io cost too high · scale up rds instance or fix queries

**Upgrade:** rds postgresql 14 upgrade before february 2027 · aurora postgresql 14 upgrade assessment · postgresql 14 to 17 upgrade risk assessment · postgresql 14 to 18 upgrade consultant · rds postgresql extended support avoid cost · pg_upgrade compatibility check · postgresql major version upgrade query regression testing · postgresql upgrade rollback plan · rds blue green deployment postgresql major upgrade · postgresql slow after upgrade to 16 or 17

**Query Rescue:** review my slow postgresql query · postgresql explain analyze expert review · fix one slow sql query fixed price · postgres query plan review service · slow orm generated query postgresql · sql server slow query review

**Database Code Review:** postgresql migration review before deploy · review database migration for locking risk · safe postgres schema change review · alter table lock risk review postgresql · create index concurrently migration review · sql server stored procedure code review

**SQL Server:** sql server query store regression consultant · sql server parameter sniffing fix · sql server blocking investigation service · sql server performance review fixed price · sql server slow after upgrade · entity framework slow sql server queries

**Partners (outreach copy rather than search):** postgresql specialist for agencies · white label postgresql consultant · database expert for fractional cto · subcontract postgresql performance work

**Never target:** cheap, freelance, fractional DBA, 24/7, guaranteed, zero downtime, PostgreSQL engineer (job intent), "walstack" alone.

### Not changed, on purpose

- H1s on the investigation, upgrade, SQL Server, Query Rescue and Code Review pages. They carry the offer name or the buyer's problem, which converts better. The term goes in the title and the eyebrow.
- No `/postgresql-consulting` page. It would duplicate the homepage.
- No new long-tail landing pages. Near-duplicates would dilute a young domain.

### Accounts the owner controls

- **Search Console:** re-inspect the nine service pages around 6 and 20 December. Request indexing once, after this change deploys, for each page whose title changed (investigation, upgrade, RDS/Aurora, Query Rescue, Code Review, pricing, homepage), and for `/partners`, which Google did not know about, only if it is still unknown on 6 December.
- **Bing Webmaster Tools:** import the walstack.io property from Search Console and confirm `sitemap-index.xml` is read. Bing powers several AI assistants' web results, and the import takes a few minutes.
- **IndexNow:** optional. It needs a key file committed to `public/` and a submission on each deploy. Decide after Bing shows whether crawling is a problem at all.
