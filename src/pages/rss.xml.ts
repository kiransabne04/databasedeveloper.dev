import type { APIRoute } from 'astro';
import { site } from '../config/site';

const posts = [
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
    return `<item><title>${escapeXml(post.title)}</title><link>${url}</link><guid isPermaLink="true">${url}</guid><description>${escapeXml(post.description)}</description><pubDate>Tue, 13 Oct 2026 00:00:00 GMT</pubDate></item>`;
  }).join('');
  const feed = `<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel><title>DatabaseDeveloper insights</title><link>${site.url}/insights</link><description>${escapeXml(site.description)}</description><language>en</language>${items}</channel></rss>`;
  return new Response(feed, { headers: { 'Content-Type': 'application/rss+xml; charset=utf-8' } });
};
