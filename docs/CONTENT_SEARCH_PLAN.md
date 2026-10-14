# Content and search plan

Updated 13 October 2026. This is a search-intent map, not a claim of keyword volume or ranking. It uses the existing Hashnode archive, a live search-result review for the topics below, and the questions a SaaS engineer would ask during a production database problem. Google recommends descriptive titles, clear page focus and original, useful experience rather than pages built only to repeat keywords ([Search Essentials](https://developers.google.com/search/docs/essentials), [helpful content guidance](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)).

| Intent / query cluster | Primary page | Reader's job | Business path |
| --- | --- | --- | --- |
| PostgreSQL performance consultant; PostgreSQL performance investigation | `/postgresql-performance-investigation` | Understand scope, evidence, deliverable and price | Sample report → contact |
| AWS RDS PostgreSQL performance; Aurora PostgreSQL slow queries | `/aws-rds-aurora-postgresql` | Diagnose managed-service waits, query load and resource limits | Investigation → contact |
| PostgreSQL lock contention; find blocking queries; `pg_blocking_pids` | `/postgresql-concurrency-and-locking-a-comprehensive-guide` | Capture a blocking chain and choose a safe response | Lock problem page → lab case → investigation |
| PostgreSQL partition pruning; when to partition a table | `/how-to-scale-postgresql-databases-with-partitioning` | Compare pruning and retention benefit with key and migration costs | Investigation |
| PostgreSQL BRIN vs B-tree; BRIN index time-series table | `/postgresql-indexing-when-brin-beats-b-tree` | Choose an index from physical order and query shape | Investigation |
| PostgreSQL CLUSTER lock; CLUSTER performance | `/mastering-clustering-in-postgresql-for-enhanced-query-performance` | Decide whether a table rewrite is worth the lock and disk cost | Investigation |
| PostgreSQL sharding; when to shard PostgreSQL | `/sharding-postgresql-techniques-for-horizontal-scalability` | Prove a node limit and plan routing and recovery | Investigation / analytical review |
| pgvector semantic search FastAPI; pgvector filtered search | `/building-a-semantic-similarity-search-api-with-fastapi-sentence-bert-and-postgresql-pgvector` | Move a working demo toward a measured service | HNSW versus IVFFlat guide → pgvector review |
| MongoDB locking and WiredTiger concurrency | `/mastering-mongodb-locking-concurrency-and-performance-optimization-a-deep-dive` | Diagnose a legacy archive topic | Keep available; do not promote in PostgreSQL-first navigation |

## Editorial rules

- Preserve the seven original article URLs and the permanent redirect for the SQL interview pointer to its full article on `kiransabne.dev`. Each page keeps the original text with errors corrected in place, adds production notes, and keeps its original publication date and a truthful revision date.
- Give each article one primary question in its title and opening. Explain the decisive evidence, operational trade-off and validation step. Use SQL or code where it helps a reader act; label examples and avoid invented production results.
- Link informational articles to a relevant problem or service page when a real production investigation could help. The shared article CTA is secondary to the technical answer.
- Keep the DatabaseDeveloper archive self-contained. The BRIN and semantic-search pointer posts now have complete local guides; the interview pointer redirects to its full article on `kiransabne.dev`, which is not duplicated here. Inventory any separate `kiransabne.dev` publication before deleting a shared Hashnode account.
- Do not claim a target rank or publish search-volume figures without a measured source. Search-result sampling shows intent, not demand size or conversion rate.

## Measurement after launch

1. Verify the domain in Google Search Console, submit `/sitemap-index.xml`, and inspect all eight legacy URLs after deployment. Seven article URLs stay the same; the interview URL, the old archive and sitemap URLs have direct redirects ([site move guidance](https://developers.google.com/search/docs/crawling-indexing/site-move-with-url-changes)).
2. Export Search Console queries and pages after enough impressions accrue. Group by problem, service and article intent. Compare impressions, clicks, query wording and landing pages; watch for one article and one service page competing for the same intent.
3. Track contact starts and qualified inquiries by landing page and source. Improve the pages that bring relevant leads, not only those with traffic. No ranking or conversion outcome can be guaranteed from on-page edits alone.
