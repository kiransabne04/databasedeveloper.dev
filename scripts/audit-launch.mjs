import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, relative } from 'node:path';
import { resolveCampaignContext, successfulSubmissionEvent } from '../src/lib/campaign-context.mjs';

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
  const canonicalAliases = { '/postgresql-query-rescue': '/query-rescue', '/postgresql-pr-review': '/database-code-review' };
  const canonical = `https://walstack.io${canonicalAliases[normalized] || (normalized === '/' ? '/' : normalized)}`;
  assert(html.includes(`<link rel="canonical" href="${canonical}"`), `Bad canonical ${normalized}`);
  const compatibilityAlias = ['/postgresql-query-rescue', '/postgresql-pr-review'].includes(normalized);
  const routeUrl = `https://walstack.io${normalized === '/' ? '/' : normalized}`;
  assert(sitemap.includes(`<loc>${routeUrl}</loc>`) === !compatibilityAlias, `Unexpected sitemap status ${normalized}`);
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
const reviewPages = [
  ['query-rescue', 'Query Rescue', 'Query Rescue for PostgreSQL &amp; SQL Server | WalStack'],
  ['database-code-review', 'Database Code Review', 'Database Code Review for PostgreSQL &amp; SQL Server | WalStack'],
];
for (const [key, heading, title] of reviewPages) {
  const route = '/' + key;
  const url = 'https://walstack.io' + route;
  const html = page(route);
  assert.equal(html.match(/<h1\b/g)?.length, 1);
  assert(html.includes('<h1>' + heading + '</h1>') && html.includes('<title>' + title + '</title>'), route + ' heading/title');
  assert(html.includes('property="og:url" content="' + url + '"') && html.includes('name="twitter:title" content="' + title + '"'), route + ' social metadata');
  assert(!/<meta name="robots"[^>]*noindex/i.test(html), route + ' blocked from indexing');
  assert(html.includes('Fixed quote after fit review'), route + ' expected fit-review quote terms');
  const nodes = [...html.matchAll(/<script type="application\/ld\+json"[^>]*>(.*?)<\/script>/gs)].map(m => JSON.parse(m[1]));
  const service = nodes.find(n => n['@type'] === 'Service');
  assert.equal(service?.url, url);
  assert.equal(nodes.filter(n => n['@id'] === service.provider['@id']).length, 1);
  assert(!service.offers && !nodes.some(n => n['@type'] === 'AggregateRating'));
  assert.deepEqual(nodes.find(n => n['@type'] === 'BreadcrumbList')?.itemListElement.map(i => [i.position, i.item]), [[1, 'https://walstack.io/'], [2, url]]);
  for (const [, id] of html.matchAll(/href="#([^"]+)"/g)) assert(html.includes('id="' + id + '"'), route + ' missing #' + id);
  const params = new URLSearchParams({ offer: key, from: route });
  assert(html.includes('href="/contact?' + params.toString().replaceAll('&', '&amp;') + '"'), route + ' enquiry attribution');
  assert(page('/contact').includes('value="' + key + '"'), route + ' contact option');
}
for (const [route, canonical] of [['/postgresql-query-rescue', 'https://walstack.io/query-rescue'], ['/postgresql-pr-review', 'https://walstack.io/database-code-review']]) {
  const html = page(route);
  assert(html.includes(`<link rel="canonical" href="${canonical}"`), `${route} canonical`);
  assert(/<meta name="robots" content="noindex,nofollow"/.test(html), `${route} must not compete with its replacement`);
}

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
for (const key of ['query-rescue', 'database-code-review']) {
  assert(page('/contact').includes(`value="${key}"`), `Contact missing service option: ${key}`);
  assert(page('/').includes(`href="/${key}"`), `Homepage missing service path: ${key}`);
}
const baseSource = readFileSync(join(root, 'src/layouts/BaseLayout.astro'), 'utf8');
const campaignSource = readFileSync(join(root, 'src/lib/campaign-context.mjs'), 'utf8');
for (const route of ['/query-rescue', '/database-code-review']) {
  const html = page(route);
  assert(html.includes(`data-service-id="${route.slice(1)}"`) && baseSource.includes("track('service_page_view'"), `${route} analytics hooks missing`);
  assert(html.includes('application/ld+json') && html.includes('"@type":"Service"'), `${route} Service schema missing`);
}
const contactSource = readFileSync(join(root, 'src/pages/contact.astro'), 'utf8');
assert(contactSource.includes('successfulSubmissionEvent(response') && campaignSource.includes('if (!response.ok) throw'), 'Form submission must count only a successful response');
assert(contactSource.includes("name: 'contact_start'") && contactSource.includes("data-track=\"booking_click\""), 'Contact start and booking click must remain distinct');
assert(!contactSource.includes('contact_draft_open'), 'Email draft must not count as submitted lead');
assert(baseSource.includes('page_location: cleanPage') && baseSource.includes('cleanReferrer(document.referrer)'), 'Analytics page URLs/referrers must be query-free');
assert(baseSource.includes("window.gtag('event', 'service_page_view'") && (baseSource.match(/track\('service_page_view'/g) || []).length === 1, 'Consent should not duplicate the Plausible service view');
assert(campaignSource.includes('first_${key}') && campaignSource.includes('latest_landing_page'), 'First/latest campaign attribution missing');
const memory = new Map();
const storage = { getItem: key => memory.get(key) ?? null, setItem: (key, value) => memory.set(key, value) };
const firstVisit = resolveCampaignContext({ origin: 'https://walstack.io', pathname: '/insights/slow-query', search: '?utm_source=outbound&utm_medium=email&utm_campaign=postgres-performance&utm_content=query-rescue' }, 'https://google.com/search?q=private', storage);
assert.equal(firstVisit.campaignContext.first_utm_campaign, 'postgres-performance');
assert.equal(firstVisit.cleanPage, 'https://walstack.io/insights/slow-query');
assert.equal(firstVisit.cleanReferrer, 'https://google.com/search');
const nextVisit = resolveCampaignContext({ origin: 'https://walstack.io', pathname: '/query-rescue', search: '?utm_source=partner&utm_medium=email&utm_campaign=agency-partnerships&utm_content=review' }, 'https://walstack.io/insights/slow-query?secret=1', storage);
assert.equal(nextVisit.campaignContext.first_utm_source, 'outbound');
assert.equal(nextVisit.campaignContext.utm_source, 'partner');
assert.equal(nextVisit.campaignContext.referring_page, '/insights/slow-query');
assert(!JSON.stringify(nextVisit).includes('secret'));
let submissions = 0;
globalThis.CustomEvent ??= class CustomEvent { constructor(type, init) { this.type = type; this.detail = init.detail; } };
assert.throws(() => successfulSubmissionEvent({ ok: false, status: 500 }), /500/);
assert.equal(submissions, 0);
const successEvent = successfulSubmissionEvent({ ok: true }, { service_id: 'query-rescue' });
if (successEvent.detail.name === 'contact_submit') submissions++;
assert.equal(submissions, 1);
assert(!/\$149|\$60\/hour|\$450|\$750–900/.test(page('/pricing')), 'Legacy price on pricing page');
for (const route of ['/postgresql-performance-investigation','/postgresql-upgrade-readiness']) {
  assert(!page(route).includes('priceCurrency'), `Unpublished price remains in service schema: ${route}`);
}

console.log(`Launch audit passed: ${allHtml.length} Astro routes (${requiredRoutes.length} previously public), metadata, sitemap, internal links and commercial CTAs.`);
