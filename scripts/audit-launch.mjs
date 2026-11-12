import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, relative } from 'node:path';

const root = new URL('..', import.meta.url).pathname;
const dist = join(root, 'dist');
const pages = join(root, 'src/pages');
const sitemap = readFileSync(join(dist, 'sitemap-0.xml'), 'utf8');
const redirects = JSON.parse(readFileSync(join(root, 'vercel.json'), 'utf8')).redirects;
const requiredRoutes = JSON.parse(readFileSync(join(root, 'scripts/required-routes.json'), 'utf8'));
const allHtml = [];

function walk(dir, extension) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((item) => {
    const file = join(dir, item.name);
    return item.isDirectory() ? walk(file, extension) : item.name.endsWith(extension) ? [file] : [];
  });
}
for (const source of walk(pages, '.astro')) {
  const route = '/' + relative(pages, source).replace(/\.astro$/, '').replace(/(?:^|\/)index$/, '');
  const normalized = route === '/' ? '/' : route.replace(/\/$/, '');
  if (normalized === '/404') continue;
  const output = normalized === '/' ? join(dist, 'index.html') : join(dist, normalized.slice(1), 'index.html');
  assert(existsSync(output), `Missing public route ${normalized}`);
  const html = readFileSync(output, 'utf8');
  const canonical = `https://walstack.io${normalized === '/' ? '/' : normalized}`;
  assert(html.includes(`<link rel="canonical" href="${canonical}"`), `Bad canonical ${normalized}`);
  assert(sitemap.includes(`<loc>${canonical}</loc>`), `Missing sitemap entry ${normalized}`);
  assert(/<meta name="description" content="[^"]+"/.test(html), `Missing description ${normalized}`);
  allHtml.push([normalized, html]);
}
for (const route of requiredRoutes) assert(allHtml.some(([path]) => path === route), `Previously public route removed: ${route}`);
for (const source of ['/archive','/members','/recommendations','/sitemap.xml']) assert(redirects.some((r) => r.source === source), `Legacy redirect removed: ${source}`);
for (const [route, html] of allHtml) {
  for (const [, href] of html.matchAll(/<a\b[^>]*href="(\/[^"#]*)"/g)) {
    const path = href.split(/[?#]/)[0].replace(/\/$/, '') || '/';
    const destination = path === '/' ? join(dist, 'index.html') : join(dist, path.slice(1), 'index.html');
    const asset = join(dist, path.slice(1));
    assert(existsSync(destination) || existsSync(asset) || redirects.some((r) => r.source === path), `Broken ${href} in ${route}`);
  }
}
const page = (route) => allHtml.find(([path]) => path === route)?.[1] || '';
const indexWaitGuide = page('/insights/postgresql-create-index-concurrently-stuck');
assert(indexWaitGuide.includes('"@type":"Article"'), 'Concurrent index guide lost Article structured data');
for (const section of ['progress', 'waits', 'working', 'failed-build', 'rds-aurora', 'response', 'sources']) {
  assert(indexWaitGuide.includes(`href="#${section}"`) && indexWaitGuide.includes(`id="${section}"`), `Concurrent index guide TOC target missing: ${section}`);
}
for (const route of ['/problems/postgresql-lock-contention', '/aws-rds-aurora-postgresql', '/evidence-collection', '/sample-report', '/postgresql-performance-investigation']) {
  assert(indexWaitGuide.includes(`href="${route}"`), `Concurrent index guide missing link: ${route}`);
}
assert(/href="https:\/\/(?:www\.)?planreader\.dev\//.test(indexWaitGuide), 'Concurrent index guide missing PlanReader link');
assert(page('/postgresql-concurrency-and-locking-a-comprehensive-guide').includes('href="/insights/postgresql-create-index-concurrently-stuck"'), 'Locking guide backlink missing');
const newGuides = [
  ['/postgresql-14-eol', ['dates', 'what-changes', 'managed', 'inventory', 'target', 'breaks', 'paths', 'plan', 'faq', 'sources'], ['/postgresql-14-upgrade-checklist', '/insights/rds-aurora-postgresql-14-extended-support-cost', '/insights/postgresql-upgrade-logical-replication-slots']],
  ['/insights/postgresql-find-unused-indexes', ['test', 'replicas', 'reset', 'query', 'duplicates', 'cost', 'drop', 'managed', 'faq', 'sources'], ['/insights/postgresql-create-index-concurrently-stuck', '/insights/postgresql-slow-queries-pg-stat-statements']],
  ['/insights/pgvector-hnsw-index-build-slow', ['setup', 'memory', 'workers', 'shm', 'progress', 'production', 'faq', 'sources'], ['/insights/pgvector-hnsw-vs-ivfflat', '/insights/postgresql-create-index-concurrently-stuck']],
  ['/insights/sql-server-implicit-conversion-nvarchar-varchar', ['repro', 'collation', 'find', 'fix', 'cast', 'validate', 'faq', 'sources'], ['/insights/sql-server-parameter-sniffing-query-store']]
];
for (const [route, sections, links] of newGuides) {
  const html = page(route);
  assert(html.includes('"@type":"Article"'), `${route} lost Article structured data`);
  assert(html.includes('"@type":"FAQPage"'), `${route} lost FAQPage structured data`);
  for (const section of sections) assert(html.includes(`href="#${section}"`) && html.includes(`id="${section}"`), `${route} TOC target missing: ${section}`);
  for (const link of links) assert(html.includes(`href="${link}"`), `${route} missing link: ${link}`);
}
assert(page('/').includes('href="/contact?offer=investigation&amp;from=/"'), 'Homepage primary CTA lost offer attribution');
assert(page('/').includes('href="/sample-report"'), 'Homepage sample CTA missing');
assert(page('/partners').includes('href="/contact?offer=partnership&amp;from=/partners"'), 'Partner CTA missing');
assert(page('/postgresql-upgrade-readiness').includes('href="/contact?offer=upgrade&amp;from=/postgresql-upgrade-readiness"'), 'Upgrade CTA missing offer attribution');
assert(page('/sample-upgrade-readiness-report').includes('Synthetic'), 'Upgrade sample lost synthetic label');
assert(page('/contact').includes('name="offer"') && page('/contact').includes('name="_gotcha"'), 'Contact offer or spam field missing');
assert(!/\$149|\$60\/hour|\$450|\$750–900/.test(page('/pricing')), 'Legacy price on pricing page');
for (const route of ['/postgresql-performance-investigation','/postgresql-upgrade-readiness']) {
  assert(!page(route).includes('priceCurrency'), `Unpublished price remains in service schema: ${route}`);
}

console.log(`Launch audit passed: ${allHtml.length} Astro routes (${requiredRoutes.length} previously public), metadata, sitemap, internal links and commercial CTAs.`);
