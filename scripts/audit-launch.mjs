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
  const noindexFollow = ['/sql-server-performance', '/snowflake-performance', '/olap-analytical-performance', '/partner-kit', '/privacy', '/terms'].includes(normalized);
  if (noindexFollow) assert(html.includes('<meta name="robots" content="noindex,follow"'), `${normalized} should be noindex,follow`);
  const excludedFromSitemap = noindexFollow || ['/postgresql-query-rescue', '/postgresql-pr-review', '/snapshot/thank-you'].includes(normalized);
  if (!excludedFromSitemap) assert(!/<meta name="robots"[^>]*noindex/.test(html), `${normalized} is in the sitemap but noindex`);
  const routeUrl = `https://walstack.io${normalized === '/' ? '/' : normalized}`;
  assert(sitemap.includes(`<loc>${routeUrl}</loc>`) === !excludedFromSitemap, `Unexpected sitemap status ${normalized}`);
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
  ['query-rescue', 'PostgreSQL slow query optimization and execution plan review', 'PostgreSQL Slow Query Optimization &amp; Plan Review | WalStack'],
  ['database-code-review', 'PostgreSQL schema and migration code review', 'PostgreSQL Schema &amp; Migration Code Review | WalStack'],
];
for (const [key, heading, title] of reviewPages) {
  const route = '/' + key;
  const url = 'https://walstack.io' + route;
  const html = page(route);
  assert.equal(html.match(/<h1\b/g)?.length, 1);
  assert(html.includes('<h1>' + heading + '</h1>') && html.includes('<title>' + title + '</title>'), route + ' heading/title');
  assert(html.includes('property="og:url" content="' + url + '"') && html.includes('name="twitter:title" content="' + title + '"'), route + ' social metadata');
  assert(!/<meta name="robots"[^>]*noindex/i.test(html), route + ' blocked from indexing');
  const nodes = [...html.matchAll(/<script type="application\/ld\+json"[^>]*>(.*?)<\/script>/gs)].map(m => JSON.parse(m[1]));
  const service = nodes.find(n => n['@type'] === 'Service');
  assert.equal(service?.url, url);
  assert.equal(nodes.filter(n => n['@id'] === service.provider['@id']).length, 1);
  assert(!service.offers && !nodes.some(n => n['@type'] === 'AggregateRating'));
  assert.deepEqual(nodes.find(n => n['@type'] === 'BreadcrumbList')?.itemListElement.map(i => [i.position, i.item]), [[1, 'https://walstack.io/'], [2, url]]);
  for (const [, id] of html.matchAll(/href="#([^"]+)"/g)) assert(html.includes('id="' + id + '"'), route + ' missing #' + id);
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
const home = page('/');
const visibleText = html => html.replace(/<script\b[^>]*>.*?<\/script>/gs, '').replace(/<style\b[^>]*>.*?<\/style>/gs, '').replace(/<[^>]+>/g, ' ');
for (const [route, html] of allHtml) {
  assert.equal((html.match(/<h1\b/g) || []).length, 1, route + ' should have one H1');
  let lastHeading = 0;
  for (const [, level] of html.matchAll(/<h([1-6])\b/g)) {
    assert(Number(level) <= lastHeading + 1, route + ' skips a heading level');
    lastHeading = Number(level);
  }
  assert(html.includes('href="/snapshot"') && html.includes('data-track="book_call_click"'), route + ' missing conversion link');
  assert(!/\b(?:we|our|ours)\b/i.test(visibleText(html)), route + ' uses plural first person');
}
assert(!/workload evidence|workload baselines|prepared-plan regression|DDL lock queue|Query Store|go\/no-go|\bOLAP\b|evidence-first|ranked change plan/i.test(visibleText(home)), 'Homepage jargon');
const main = home.match(/<main[^>]*>(.*?)<\/main>/s)[1];
for (const path of ['/capabilities', '/partners', '/query-rescue', '/database-code-review', '/sql-server-performance']) assert(!main.includes('href="' + path + '"'), path + ' promoted in homepage body');
assert(main.includes('href="/sample-report"') && main.includes('demo database') && main.includes('generated data'), 'Homepage proof labels');
assert(!/<blockquote/.test(main), 'Unexpected homepage quote');
for (const route of ['/sample-report', '/sample-upgrade-readiness-report', '/case-studies', '/case-studies/lab-lock-queue', '/case-studies/lab-generic-plan-regression']) {
  assert(/synthetic|demo database|generated data/i.test(visibleText(page(route))), route + ' missing lab disclosure');
}
const snapshot = page('/snapshot');
assert(snapshot.includes('href="/snapshot/walstack-snapshot.sql"') && snapshot.includes('data-track="script_download"'), 'Snapshot download link or event missing');
assert(existsSync(join(dist, 'snapshot', 'walstack-snapshot.sql')), 'Snapshot SQL missing from build');
assert(snapshot.includes('multipart/form-data') && snapshot.includes('name="snapshot_1"') && snapshot.includes('name="allowed_to_share"'), 'Snapshot form missing');
assert(page('/snapshot/thank-you').includes('noindex,nofollow'), 'Receipt must be excluded from search');
assert(snapshot.includes('utm_source') && page('/pricing').includes('$450') && page('/pricing').includes('$750'), 'Missing attribution or price');
assert(page('/sample-upgrade-readiness-report').includes('Synthetic'), 'Upgrade sample lost synthetic label');
assert(page('/contact').includes('name="offer"') && page('/contact').includes('name="_gotcha"'), 'Contact offer or spam field missing');
const directoryUrl = 'https://www.postgresql.org/support/professional_support/asia/';
for (const route of ['/', '/about', '/postgresql-performance-investigation']) {
  const html = page(route);
  assert(html.includes(`href="${directoryUrl}"`) && html.includes("PostgreSQL.org's Professional Services directory"), `${route} directory reference missing`);
  assert(!/PostgreSQL[^<]*(?:certified|endorsed|officially partnered|approved)/i.test(html), `${route} overstates directory status`);
}
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
assert(contactSource.includes("name: 'contact_start'") && contactSource.includes("data-track=\"book_call_click\""), 'Contact start and booking click must remain distinct');
assert(page('/contact').includes('name="referral_source"') && page('/contact').includes('name="referral_landing_page"'), 'Contact form must preserve directory referral attribution');
assert(!contactSource.includes('contact_draft_open'), 'Email draft must not count as submitted lead');
for (const event of ['snapshot_page_view', 'sample_report_view', 'pricing_view']) assert(baseSource.includes("track('" + event + "')"), event + ' missing');
assert(!baseSource.includes('googletagmanager.com'), 'Test uses cookie-free analytics');
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
const directoryVisit = resolveCampaignContext({ origin: 'https://walstack.io', pathname: '/query-rescue', search: '' }, 'https://www.postgresql.org/support/professional_support/asia/?utm_source=ignored', storage);
assert.equal(directoryVisit.campaignContext.referral_source, 'postgresql.org');
assert.equal(directoryVisit.campaignContext.referral_landing_page, '/query-rescue');
let previousPath = '/query-rescue';
for (const path of ['/postgresql-performance-investigation', '/postgresql-upgrade-readiness', '/contact']) {
  const internalVisit = resolveCampaignContext({ origin: 'https://walstack.io', pathname: path, search: '' }, `https://walstack.io${previousPath}`, storage);
  assert.equal(internalVisit.campaignContext.referral_source, 'postgresql.org');
  assert.equal(internalVisit.campaignContext.referral_landing_page, '/query-rescue');
  previousPath = path;
}
let submissions = 0;
globalThis.CustomEvent ??= class CustomEvent { constructor(type, init) { this.type = type; this.detail = init.detail; } };
assert.throws(() => successfulSubmissionEvent({ ok: false, status: 500 }), /500/);
assert.equal(submissions, 0);
const successEvent = successfulSubmissionEvent({ ok: true }, { service_id: 'query-rescue' });
if (successEvent.detail.name === 'contact_submit') submissions++;
assert.equal(submissions, 1);
console.log(`Launch audit passed: ${allHtml.length} Astro routes (${requiredRoutes.length} previously public), metadata, sitemap, internal links and commercial CTAs.`);
