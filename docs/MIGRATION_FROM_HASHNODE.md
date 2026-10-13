# Hashnode migration inventory

Checked against the live `databasedeveloper.dev` Hashnode publication on 13 October 2026. It listed eight posts. The new site retains seven original paths with technically revised articles and redirects the one short interview pointer to its existing full article on `kiransabne.dev`.

The public Hashnode sitemap was checked as well. It contained those eight posts plus `/archive` and `/recommendations`; both listing routes redirect to `/insights`. The old `/rss.xml` feed path is retained with a new feed, and `/sitemap.xml` redirects to the new `/sitemap-index.xml`.

| Old path | Original type | New handling |
| --- | --- | --- |
| `/postgresql-indexing-when-brin-beats-b-tree` | Short pointer to a fuller personal article | New, distinct production decision guide at the same path; links to the personal deep dive |
| `/mastering-mongodb-locking-concurrency-and-performance-optimization-a-deep-dive` | Standalone article | Revised archive article at the same path; corrects oversimplified locking advice |
| `/building-a-semantic-similarity-search-api-with-fastapi-sentence-bert-and-postgresql-pgvector` | Short pointer to a fuller personal article | New, distinct production architecture guide at the same path; links to the personal implementation |
| `/crack-sql-interviews-with-these-postgresql-internals-and-real-questions` | Short pointer to a fuller personal article | Permanent Vercel redirect to the full personal article |
| `/sharding-postgresql-techniques-for-horizontal-scalability` | Standalone article | Revised article at the same path; separates FDW from a complete sharding design |
| `/mastering-clustering-in-postgresql-for-enhanced-query-performance` | Standalone article | Revised article at the same path; emphasizes the `ACCESS EXCLUSIVE` lock and measured benefit |
| `/how-to-scale-postgresql-databases-with-partitioning` | Standalone article | Revised article at the same path; covers pruning and constraints rather than promising universal speedups |
| `/postgresql-concurrency-and-locking-a-comprehensive-guide` | Standalone article | Revised article at the same path; focuses on blocking-chain diagnosis |

The revised pages show their original publication date and the revision date. They are original rewrites, not verbatim copies of the Hashnode text. The interview URL is the only redirect because its full article already exists on the personal site.

The PostgreSQL and pgvector revisions now answer distinct production questions with diagnostic SQL or query examples, decision criteria, operational risks and relevant service links. The MongoDB article remains a technical archive item. The search-intent map and measurement plan are in `docs/CONTENT_SEARCH_PLAN.md`; it does not claim search volume or rankings without Search Console data.

Run `npm run build` and `npm run audit:content` before a preview deploy. The audit checks all seven retained article paths in the generated site, self-canonicals, Article and breadcrumb schema, sitemap entries, internal links and the interview redirect configuration.

## Before switching DNS

1. Deploy a preview and test all eight old paths on the chosen host. Vercel applies the interview redirect from `vercel.json`; another host needs an equivalent rule.
2. Compare the public Hashnode sitemap and Search Console URL report with this inventory. If either reveals another URL, add a retained page or specific redirect before switching.
3. Check that revised pages have self-canonicals, appear in the sitemap, and link to related service or problem pages.
4. After the switch, monitor 404s, indexing, traffic and backlinks in Search Console. Do not redirect unrelated old URLs to the homepage.

`kiransabne.dev` remains the home of the full interview article and existing broader personal writing. Avoid copying those articles in full to this domain.
