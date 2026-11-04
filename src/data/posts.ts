/**
 * Guides published in the RSS feeds, newest first. `postgresql` marks the ones that
 * belong in the PostgreSQL-only feed syndicated to Planet PostgreSQL, which accepts
 * only posts about PostgreSQL or closely related technology.
 */
export interface FeedPost {
  title: string;
  path: string;
  date: string;
  description: string;
  postgresql: boolean;
}

const legacyDate = 'Tue, 13 Oct 2026 00:00:00 GMT';

export const posts: FeedPost[] = [
  { title: 'PostgreSQL 18 Async I/O: Does io_method Make Queries Faster?', path: '/insights/postgresql-18-async-io-io-method', date: 'Tue, 27 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Lab-tested on PostgreSQL 18.6: sync, worker and io_uring on cold sequential and bitmap heap scans.' },
  { title: 'RDS and Aurora PostgreSQL 14 Extended Support: What It Will Cost', path: '/insights/rds-aurora-postgresql-14-extended-support-cost', date: 'Tue, 27 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Dates, per-vCPU billing on primaries, standbys and replicas, and how to list affected instances.' },
  { title: 'pgvector 0.8.7 Security Fix: Check Your Version and Upgrade Safely', path: '/insights/pgvector-087-cve-upgrade', date: 'Tue, 27 Oct 2026 00:00:00 GMT', postgresql: true, description: 'CVE-2026-103484 in IVFFlat index builds: version checks, privileges and a tested extension upgrade.' },
  { title: 'Snowflake Gen2 vs Adaptive Warehouses: Decide From Your Query History', path: '/insights/snowflake-gen2-vs-adaptive-warehouses', date: 'Tue, 27 Oct 2026 00:00:00 GMT', postgresql: false, description: 'ACCOUNT_USAGE checks for idle credits, spills, pruning and queuing before converting a warehouse.' },
  { title: 'PostgreSQL Autovacuum Not Removing Dead Tuples: Find Why', path: '/insights/postgresql-autovacuum-not-removing-dead-tuples', date: 'Thu, 22 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Tested on PostgreSQL 18: autovacuum ran 4 times and removed no dead tuples while one session sat idle in transaction. Find the blocker and reclaim the space.' },
  { title: 'PostgreSQL Transaction ID Wraparound: Warning to Recovery', path: '/insights/postgresql-transaction-id-wraparound', date: 'Thu, 22 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Reproduced on PostgreSQL 18: the wraparound warning, the error that stops writes, why VACUUM FREEZE did not help, and the recovery steps that worked.' },
  { title: 'PostgreSQL work_mem Tuning: Temp File Spills Measured', path: '/insights/postgresql-work-mem-temp-file-spills', date: 'Thu, 22 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Tested on PostgreSQL 18: 336 MB of temp file spills at the default work_mem. Raising it 64x removed every spill but saved at most 8%. What to change instead.' },
  { title: 'How to Profile Slow PostgreSQL Queries', path: '/insights/how-to-profile-slow-postgresql-queries', date: 'Wed, 21 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Rank with pg_stat_statements, capture real plans with auto_explain, reproduce with EXPLAIN ANALYZE, then validate the fix.' },
  { title: 'pg_upgrade --check Failures and Fixes: PostgreSQL 14 to 18', path: '/insights/pg-upgrade-check-failures', date: 'Wed, 21 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Real pg_upgrade --check output from a tested PG14 to PG18 run: checksum mismatch, prepared transactions, reg* columns, and what --check misses.' },
  { title: 'pg_upgrade from PostgreSQL 14 Drops Logical Replication Slots', path: '/insights/postgresql-upgrade-logical-replication-slots', date: 'Wed, 21 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Tested PG14 to PG18: pg_upgrade --check passed with a Debezium slot present, and the slot was gone afterwards.' },
  { title: 'RDS and Aurora PostgreSQL 14 to 18: Downtime and Blue/Green', path: '/insights/rds-aurora-postgresql-14-to-18-blue-green', date: 'Wed, 21 Oct 2026 00:00:00 GMT', postgresql: true, description: 'In-place upgrade or Blue/Green: where the downtime goes and the logical replication limits that break Blue/Green.' },
  { title: 'Find Slow PostgreSQL Queries with pg_stat_statements', path: '/insights/postgresql-slow-queries-pg-stat-statements', date: 'Wed, 14 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Rank statements by total time, diff snapshots and read buffer and temp-file signals. Lab-tested on PostgreSQL 17.' },
  { title: 'PostgreSQL Slow After an Upgrade? Check Statistics First', path: '/insights/postgresql-slow-after-major-upgrade', date: 'Wed, 14 Oct 2026 00:00:00 GMT', postgresql: true, description: 'A tested pg_upgrade lost optimizer statistics; how to detect and fix it on self-managed PostgreSQL and RDS.' },
  { title: 'pgvector Filtered Search Returns Too Few Results: Fixes', path: '/insights/pgvector-filtered-search-missing-results', date: 'Wed, 14 Oct 2026 00:00:00 GMT', postgresql: true, description: 'Measured iterative scans, exact search and partial indexes for filtered HNSW queries.' },
  { title: 'SQL Server Parameter Sniffing: Diagnose and Fix It', path: '/insights/sql-server-parameter-sniffing-query-store', date: 'Wed, 14 Oct 2026 00:00:00 GMT', postgresql: false, description: 'Query Store diagnosis and measured PSP, RECOMPILE and covering-index fixes on SQL Server 2022.' },
  { title: 'RDS PostgreSQL 14.18 and 14.19 Lose Standard Support on 31 October 2026', path: '/insights/postgresql-14-minor-version-deadlines', date: legacyDate, postgresql: true, description: 'Check minor-version deadlines that arrive before the PostgreSQL 14 major-version date.' },
  { title: 'What AI Misses in a Production PostgreSQL Performance Diagnosis', path: '/insights/what-ai-misses-postgresql', date: legacyDate, postgresql: true, description: 'A safe production recommendation needs workload, waits, change history and validation.' },
  { title: 'pgvector HNSW vs IVFFlat: Benchmark for Your Filters and Recall', path: '/insights/pgvector-hnsw-vs-ivfflat', date: legacyDate, postgresql: true, description: 'Measure recall, filtered result count, latency and operational cost on the real workload.' },
  { title: 'PostgreSQL Concurrency and Locking: A Comprehensive Guide', path: '/postgresql-concurrency-and-locking-a-comprehensive-guide', date: legacyDate, postgresql: true, description: 'Find blockers, long transactions and DDL queues before changing queries.' },
  { title: 'How to Scale PostgreSQL Databases with Partitioning', path: '/how-to-scale-postgresql-databases-with-partitioning', date: legacyDate, postgresql: true, description: 'Verify partition pruning, data lifecycle and constraint trade-offs.' },
  { title: 'Mastering Clustering in PostgreSQL for Enhanced Query Performance', path: '/mastering-clustering-in-postgresql-for-enhanced-query-performance', date: legacyDate, postgresql: true, description: 'Test physical row order benefits against rewrite and locking costs.' },
  { title: 'Sharding PostgreSQL: Techniques for Achieving Horizontal Scalability', path: '/sharding-postgresql-techniques-for-horizontal-scalability', date: legacyDate, postgresql: true, description: 'Assess shard keys, routing, rebalancing and cross-shard work.' },
  { title: 'PostgreSQL Indexing: When BRIN Beats B-Tree', path: '/postgresql-indexing-when-brin-beats-b-tree', date: legacyDate, postgresql: true, description: 'Decide from correlation, query evidence and index trade-offs.' },
  { title: 'Building a Semantic Similarity Search API with FastAPI, Sentence-BERT, and PostgreSQL pgvector', path: '/building-a-semantic-similarity-search-api-with-fastapi-sentence-bert-and-postgresql-pgvector', date: legacyDate, postgresql: true, description: 'Move from a pgvector demo to measurable recall, filtering and latency.' },
  { title: 'Mastering MongoDB Locking, Concurrency, and Performance Optimization: A Deep Dive', path: '/mastering-mongodb-locking-concurrency-and-performance-optimization-a-deep-dive', date: legacyDate, postgresql: false, description: 'WiredTiger lock modes, versioning and contention diagnosis, with corrections.' }
];

const escapeXml = (value: string) => value.replace(/[&<>"']/g, (character) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;'
})[character] ?? character);

/** RSS 2.0 document for the given posts. */
export function rssFeed(options: { siteUrl: string; feedPath: string; title: string; link: string; description: string; author: string; items: FeedPost[] }): string {
  const { siteUrl, feedPath, title, link, description, author, items } = options;
  const entries = items.map((post) => {
    const url = new URL(post.path, siteUrl).toString();
    return `<item><title>${escapeXml(post.title)}</title><link>${url}</link><guid isPermaLink="true">${url}</guid><dc:creator>${escapeXml(author)}</dc:creator><description>${escapeXml(post.description)}</description><pubDate>${post.date}</pubDate></item>`;
  }).join('');
  const self = new URL(feedPath, siteUrl).toString();
  return `<?xml version="1.0" encoding="UTF-8"?><rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/"><channel><title>${escapeXml(title)}</title><link>${link}</link><atom:link href="${self}" rel="self" type="application/rss+xml"/><description>${escapeXml(description)}</description><language>en</language>${entries}</channel></rss>`;
}
