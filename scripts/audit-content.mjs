import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const root = new URL('..', import.meta.url).pathname;
const origin = 'https://databasedeveloper.dev';
const legacyArticles = [
  '/postgresql-indexing-when-brin-beats-b-tree',
  '/mastering-mongodb-locking-concurrency-and-performance-optimization-a-deep-dive',
  '/building-a-semantic-similarity-search-api-with-fastapi-sentence-bert-and-postgresql-pgvector',
  '/sharding-postgresql-techniques-for-horizontal-scalability',
  '/mastering-clustering-in-postgresql-for-enhanced-query-performance',
  '/how-to-scale-postgresql-databases-with-partitioning',
  '/postgresql-concurrency-and-locking-a-comprehensive-guide'
];
const sitemap = readFileSync(join(root, 'dist/sitemap-0.xml'), 'utf8');
const redirects = JSON.parse(readFileSync(join(root, 'vercel.json'), 'utf8')).redirects;
const seenTitles = new Set();

for (const route of legacyArticles) {
  const file = join(root, 'dist', route.slice(1), 'index.html');
  assert(existsSync(file), `Missing retained article: ${route}`);
  const html = readFileSync(file, 'utf8');
  const url = `${origin}${route}`;
  assert(html.includes(`<link rel="canonical" href="${url}"`), `Bad canonical: ${route}`);
  assert(sitemap.includes(`<loc>${url}</loc>`), `Missing sitemap URL: ${route}`);
  assert(html.includes('<meta property="og:type" content="article"'), `Missing article Open Graph type: ${route}`);
  assert(/<h1\b[^>]*>.+?<\/h1>/s.test(html), `Missing H1: ${route}`);
  assert(/<meta name="description" content="[^"]+"/.test(html), `Missing description: ${route}`);
  const title = html.match(/<title>(.*?)<\/title>/s)?.[1];
  assert(title && !seenTitles.has(title), `Missing or duplicate title: ${route}`);
  seenTitles.add(title);

  const schemas = [...html.matchAll(/<script type="application\/ld\+json"[^>]*>(.*?)<\/script>/gs)]
    .map((match) => JSON.parse(match[1]));
  assert(schemas.some((schema) => schema['@type'] === 'BlogPosting' && schema.mainEntityOfPage === url), `Missing BlogPosting: ${route}`);
  assert(schemas.some((schema) => schema['@type'] === 'BreadcrumbList'), `Missing breadcrumbs: ${route}`);

  for (const [, href] of html.matchAll(/<a\b[^>]*href="(\/[^"]*)"/g)) {
    const path = href.split(/[?#]/)[0];
    const target = path === '/' ? join(root, 'dist/index.html') : join(root, 'dist', path.slice(1), 'index.html');
    const asset = join(root, 'dist', path.slice(1));
    assert(existsSync(target) || existsSync(asset), `Broken internal link ${href} in ${route}`);
  }
}

const interview = redirects.find((item) => item.source === '/crack-sql-interviews-with-these-postgresql-internals-and-real-questions');
assert(interview?.permanent && interview.destination.startsWith('https://kiransabne.dev/'), 'Missing permanent interview redirect');
assert(!sitemap.includes(`<loc>${origin}${interview.source}</loc>`), 'Redirect URL should not be in the sitemap');

console.log(`Content audit passed: ${legacyArticles.length} retained articles, one permanent interview redirect, metadata, schema, sitemap and internal links.`);
