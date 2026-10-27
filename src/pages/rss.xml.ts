import type { APIRoute } from 'astro';
import { site } from '../config/site';

const posts = [
  { title: 'PostgreSQL 18 Async I/O: Does io_method Make Queries Faster?', path: '/insights/postgresql-18-async-io-io-method', date: 'Tue, 27 Oct 2026 00:00:00 GMT', description: 'Lab-tested on PostgreSQL 18.6: sync, worker and io_uring on cold sequential and bitmap heap scans.' },
  { title: 'RDS and Aurora PostgreSQL 14 Extended Support: What It Will Cost', path: '/insights/rds-aurora-postgresql-14-extended-support-cost', date: 'Tue, 27 Oct 2026 00:00:00 GMT', description: 'Dates, per-vCPU billing on primaries, standbys and replicas, and how to list affected instances.' },
  { title: 'pgvector 0.8.7 Security Fix: Check Your Version and Upgrade Safely', path: '/insights/pgvector-087-cve-upgrade', date: 'Tue, 27 Oct 2026 00:00:00 GMT', description: 'CVE-2026-103484 in IVFFlat index builds: version checks, privileges and a tested extension upgrade.' },
  { title: 'Snowflake Gen2 vs Adaptive Warehouses: Decide From Your Query History', path: '/insights/snowflake-gen2-vs-adaptive-warehouses', date: 'Tue, 27 Oct 2026 00:00:00 GMT', description: 'ACCOUNT_USAGE checks for idle credits, spills, pruning and queuing before converting a warehouse.' },
  { title: 'Find Slow PostgreSQL Queries with pg_stat_statements', path: '/insights/postgresql-slow-queries-pg-stat-statements', date: 'Wed, 14 Oct 2026 00:00:00 GMT', description: 'Rank statements by total time, diff snapshots and read buffer and temp-file signals. Lab-tested on PostgreSQL 17.' },
  { title: 'PostgreSQL Slow After an Upgrade? Check Statistics First', path: '/insights/postgresql-slow-after-major-upgrade', date: 'Wed, 14 Oct 2026 00:00:00 GMT', description: 'A tested pg_upgrade lost optimizer statistics; how to detect and fix it on self-managed PostgreSQL and RDS.' },
  { title: 'pgvector Filtered Search Returns Too Few Results: Fixes', path: '/insights/pgvector-filtered-search-missing-results', date: 'Wed, 14 Oct 2026 00:00:00 GMT', description: 'Measured iterative scans, exact search and partial indexes for filtered HNSW queries.' },
  { title: 'SQL Server Parameter Sniffing: Diagnose and Fix It', path: '/insights/sql-server-parameter-sniffing-query-store', date: 'Wed, 14 Oct 2026 00:00:00 GMT', description: 'Query Store diagnosis and measured PSP, RECOMPILE and covering-index fixes on SQL Server 2022.' },
  { title: 'RDS PostgreSQL 14.18 and 14.19 Lose Standard Support on 31 October 2026', path: '/insights/postgresql-14-minor-version-deadlines', description: 'Check minor-version deadlines that arrive before the PostgreSQL 14 major-version date.' },
  { title: 'What AI Misses in a Production PostgreSQL Performance Diagnosis', path: '/insights/what-ai-misses-postgresql', description: 'A safe production recommendation needs workload, waits, change history and validation.' },
  { title: 'pgvector HNSW vs IVFFlat: Benchmark for Your Filters and Recall', path: '/insights/pgvector-hnsw-vs-ivfflat', description: 'Measure recall, filtered result count, latency and operational cost on the real workload.' },
  { title: 'PostgreSQL Concurrency and Locking: A Comprehensive Guide', path: '/postgresql-concurrency-and-locking-a-comprehensive-guide', description: 'Find blockers, long transactions and DDL queues before changing queries.' },
  { title: 'How to Scale PostgreSQL Databases with Partitioning', path: '/how-to-scale-postgresql-databases-with-partitioning', description: 'Verify partition pruning, data lifecycle and constraint trade-offs.' },
  { title: 'Mastering Clustering in PostgreSQL for Enhanced Query Performance', path: '/mastering-clustering-in-postgresql-for-enhanced-query-performance', description: 'Test physical row order benefits against rewrite and locking costs.' },
  { title: 'Sharding PostgreSQL: Techniques for Achieving Horizontal Scalability', path: '/sharding-postgresql-techniques-for-horizontal-scalability', description: 'Assess shard keys, routing, rebalancing and cross-shard work.' },
  { title: 'PostgreSQL Indexing: When BRIN Beats B-Tree', path: '/postgresql-indexing-when-brin-beats-b-tree', description: 'Decide from correlation, query evidence and index trade-offs.' },
  { title: 'Building a Semantic Similarity Search API with FastAPI, Sentence-BERT, and PostgreSQL pgvector', path: '/building-a-semantic-similarity-search-api-with-fastapi-sentence-bert-and-postgresql-pgvector', description: 'Move from a pgvector demo to measurable recall, filtering and latency.' },
  { title: 'Mastering MongoDB Locking, Concurrency, and Performance Optimization: A Deep Dive', path: '/mastering-mongodb-locking-concurrency-and-performance-optimization-a-deep-dive', description: 'WiredTiger lock modes, versioning and contention diagnosis, with corrections.' }
] as const;

const escapeXml = (value: string) => value.replace(/[&<>"']/g, (character) => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&apos;'
})[character] ?? character);

export const GET: APIRoute = () => {
  const items = posts.map((post) => {
    const url = new URL(post.path, site.url).toString();
    return `<item><title>${escapeXml(post.title)}</title><link>${url}</link><guid isPermaLink="true">${url}</guid><description>${escapeXml(post.description)}</description><pubDate>${'date' in post ? post.date : 'Tue, 13 Oct 2026 00:00:00 GMT'}</pubDate></item>`;
  }).join('');
  const feed = `<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>DatabaseDeveloper insights</title><link>${site.url}/insights</link><description>${escapeXml(site.description)}</description><language>en</language>${items}</channel></rss>`;
  return new Response(feed, { headers: { 'Content-Type': 'application/rss+xml; charset=utf-8' } });
};
