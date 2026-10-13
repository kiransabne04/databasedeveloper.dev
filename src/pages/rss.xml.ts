import type { APIRoute } from 'astro';
import { site } from '../config/site';

const posts = [
  { title: 'RDS PostgreSQL 14.18 and 14.19 Lose Standard Support on 31 October 2026', path: '/insights/postgresql-14-minor-version-deadlines', description: 'Check minor-version deadlines that arrive before the PostgreSQL 14 major-version date.' },
  { title: 'What AI Misses in a Production PostgreSQL Performance Diagnosis', path: '/insights/what-ai-misses-postgresql', description: 'A safe production recommendation needs workload, waits, change history and validation.' },
  { title: 'pgvector HNSW vs IVFFlat: Benchmark for Your Filters and Recall', path: '/insights/pgvector-hnsw-vs-ivfflat', description: 'Measure recall, filtered result count, latency and operational cost on the real workload.' },
  { title: 'PostgreSQL Lock Contention: Find Blocking Queries', path: '/postgresql-concurrency-and-locking-a-comprehensive-guide', description: 'Find blockers, long transactions and DDL queues before changing queries.' },
  { title: 'PostgreSQL Partitioning: Pruning and Retention Trade-offs', path: '/how-to-scale-postgresql-databases-with-partitioning', description: 'Verify partition pruning, data lifecycle and constraint trade-offs.' },
  { title: 'PostgreSQL CLUSTER: Locking and Performance Trade-offs', path: '/mastering-clustering-in-postgresql-for-enhanced-query-performance', description: 'Test physical row order benefits against rewrite and locking costs.' },
  { title: 'PostgreSQL Sharding: When to Split Data Across Nodes', path: '/sharding-postgresql-techniques-for-horizontal-scalability', description: 'Assess shard keys, routing, rebalancing and cross-shard work.' },
  { title: 'BRIN vs B-tree in PostgreSQL: A Production Decision Guide', path: '/postgresql-indexing-when-brin-beats-b-tree', description: 'Decide from correlation, query evidence and index trade-offs.' },
  { title: 'pgvector Semantic Search with FastAPI: Production Checklist', path: '/building-a-semantic-similarity-search-api-with-fastapi-sentence-bert-and-postgresql-pgvector', description: 'Move from a pgvector demo to measurable recall, filtering and latency.' },
  { title: 'MongoDB Locking and Concurrency: Diagnose the Contended Operation', path: '/mastering-mongodb-locking-concurrency-and-performance-optimization-a-deep-dive', description: 'An updated archive guide to WiredTiger concurrency and contention.' }
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
