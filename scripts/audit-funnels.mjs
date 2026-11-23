// Funnel, redirect and indexability checks for the built site (run after `npm run build`).
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { submitSnapshot } from '../src/lib/snapshot-submit.mjs';
import { createTracker, clickProps } from '../src/lib/analytics.mjs';

const root = new URL('..', import.meta.url).pathname;
const dist = join(root, 'dist');
const page = (route) => readFileSync(route === '/' ? join(dist, 'index.html') : join(dist, route.slice(1), 'index.html'), 'utf8');
const main = (route) => page(route).match(/<main[^>]*>(.*?)<\/main>/s)[1];
const vercel = JSON.parse(readFileSync(join(root, 'vercel.json'), 'utf8'));
let checks = 0;
const ok = (cond, msg) => { assert(cond, msg); checks++; };

// 1. Service-specific next steps. Only the PostgreSQL investigation path starts at /snapshot.
const enquiry = (offer, from) => `href="/contact?offer=${offer}&amp;from=${encodeURIComponent(from)}"`;
for (const [route, offer] of [
  ['/query-rescue', 'query-rescue'], ['/database-code-review', 'database-code-review'],
  ['/postgresql-upgrade-readiness', 'upgrade'], ['/sql-server-performance', 'sqlserver'],
  ['/pgvector-performance', 'pgvector'], ['/snowflake-performance', 'snowflake']
]) {
  const body = main(route);
  ok(body.includes(enquiry(offer, route)) || body.includes(enquiry(offer, '/' + offer)), `${route} missing ${offer} enquiry`);
  ok(!/class="button primary"[^>]*href="\/snapshot"|href="\/snapshot"[^>]*class="button primary"/.test(body), `${route} primary button sends buyers to the PostgreSQL snapshot`);
}
const investigation = main('/postgresql-performance-investigation');
ok(investigation.includes('href="/snapshot"') && investigation.includes(enquiry('investigation', '/postgresql-performance-investigation')), 'Investigation needs snapshot and direct paid route');
ok(main('/partners').includes('href="/contact?offer=partnership&amp;from=%2Fpartners"'), 'Partners enquiry route');
ok(page('/contact').includes('value="partnership"'), 'Contact form must accept the partnership offer');
ok(main('/partners').replace(/<[^>]+>/g, ' ').split(/\s+/).filter(Boolean).length > 400, 'Partners page is thin');
ok(main('/olap-analytical-performance').includes('href="/contact?from=%2Folap-analytical-performance"'), 'OLAP enquiry route');

// Articles follow their declared offer.
for (const [route, offer] of [
  ['/insights/how-to-profile-slow-postgresql-queries', 'query-rescue'],
  ['/insights/sql-server-parameter-sniffing-query-store', 'query-rescue'],
  ['/insights/pg-upgrade-check-failures', 'upgrade'],
  ['/insights/postgresql-slow-after-major-upgrade', 'upgrade'],
  ['/insights/sql-server-implicit-conversion-nvarchar-varchar', 'sqlserver']
]) ok(main(route).includes(enquiry(offer, route)), `${route} should route to ${offer}`);
ok(main('/postgresql-concurrency-and-locking-a-comprehensive-guide').includes('href="/snapshot"'), 'Locking guide keeps the snapshot route');
// Any panel labelled 'Upgrade readiness' must lead to the upgrade enquiry, not the performance snapshot.
for (const route of ['/postgresql-14-upgrade-checklist', '/insights/postgresql-14-minor-version-deadlines']) {
  const panel = main(route).split('Upgrade readiness</span>')[1] || '';
  ok(panel.includes(enquiry('upgrade', route)) && !/class="button primary"[^>]*href="\/snapshot"/.test(panel.slice(0, 1500)), `${route} upgrade panel must route to the upgrade enquiry`);
}
for (const route of ['/insights/pg-upgrade-check-failures', '/insights/sql-server-implicit-conversion-nvarchar-varchar']) {
  ok(!main(route).includes('Get a free snapshot review'), `${route} offers a PostgreSQL performance snapshot to the wrong buyer`);
}

// 2. Navigation targets exist.
for (const [, href] of page('/').match(/<nav class="desktop-nav"[^>]*>(.*?)<\/nav>/s)[1].matchAll(/href="(\/[^"]*)"/g)) {
  ok(page(href), `Nav target ${href}`);
}

// 3. Indexability.
const sitemap = readFileSync(join(dist, 'sitemap-0.xml'), 'utf8');
for (const route of ['/', '/snapshot', '/postgresql-performance-investigation', '/postgresql-upgrade-readiness', '/sql-server-performance', '/query-rescue', '/database-code-review', '/pricing', '/partners']) {
  const url = 'https://walstack.io' + route;
  ok(sitemap.includes(`<loc>${url}</loc>`), `Sitemap missing ${route}`);
  ok(page(route).includes(`<link rel="canonical" href="${url}"`), `Canonical ${route}`);
  ok(!/<meta name="robots"[^>]*noindex/.test(page(route)), `${route} must be indexable`);
}
ok(!sitemap.includes('/snapshot/thank-you'), 'Receipt page in sitemap');
ok(/<meta name="robots" content="noindex/.test(page('/snapshot/thank-you')), 'Receipt page must be noindex');
ok(!/databasedeveloper\.dev/.test(sitemap), 'Sitemap must use the production domain only');
const robots = readFileSync(join(dist, 'robots.txt'), 'utf8');
ok(robots.includes('Sitemap: https://walstack.io/sitemap-index.xml') && !/Disallow:\s*\/\s*$/m.test(robots), 'robots.txt');
for (const route of ['/', '/pricing', '/partners']) {
  const nodes = [...page(route).matchAll(/<script type="application\/ld\+json"[^>]*>(.*?)<\/script>/gs)].map((m) => JSON.parse(m[1]));
  const org = nodes.find((n) => n['@id'] === 'https://walstack.io/#practice');
  ok(org?.name === 'WalStack' && org.url === 'https://walstack.io', `${route} organization identity`);
  ok(nodes.some((n) => n['@type'] === 'WebSite' && n.url === 'https://walstack.io'), `${route} WebSite schema`);
}

for (const route of ['/sql-server-performance', '/pgvector-performance', '/snowflake-performance', '/olap-analytical-performance', '/aws-rds-aurora-postgresql', '/postgresql-performance-investigation', '/postgresql-upgrade-readiness']) {
  const nodes = [...page(route).matchAll(/<script type="application\/ld\+json"[^>]*>(.*?)<\/script>/gs)].map((m) => JSON.parse(m[1]));
  const service = nodes.find((n) => n['@type'] === 'Service');
  ok(service && service.provider?.['@id'] === 'https://walstack.io/#practice', `${route} needs Service schema linked to the practice`);
}
ok(page('/').includes('<meta name="viewport" content="width=device-width, initial-scale=1"'), 'Viewport must set initial-scale=1');
const llms = readFileSync(join(dist, 'llms.txt'), 'utf8');
ok(llms.startsWith('# WalStack\n') && llms.includes('one person, not a firm') && llms.includes('up to 5 accepted reviews a month'), 'llms.txt identity, honesty note and snapshot cap');
for (const [, path] of llms.matchAll(/\]\(https:\/\/walstack\.io(\/[^)]*)\)/g)) ok(page(path), `llms.txt links to missing page ${path}`);

// 4. Redirects: old domain reaches its final URL in one hop; slash variants collapse.
ok(vercel.trailingSlash === false, 'trailingSlash must be false so /path/ redirects to /path');
const oldHosts = ['databasedeveloper.dev', 'www.databasedeveloper.dev'];
for (const host of oldHosts) {
  const rules = vercel.redirects.filter((r) => r.has?.some((h) => h.type === 'host' && h.value === host));
  ok(rules.every((r) => /^https:\/\/(walstack\.io|kiransabne\.dev)\//.test(r.destination) && r.statusCode === 301), `${host} rules must be absolute 301s`);
  const catchAll = rules.findIndex((r) => r.source === '/:path*');
  for (const source of ['/sitemap.xml', '/archive', '/members', '/recommendations', '/crack-sql-interviews-with-these-postgresql-internals-and-real-questions']) {
    const i = rules.findIndex((r) => r.source === source);
    ok(i !== -1 && i < catchAll, `${host}${source} needs a one-hop rule before the catch-all`);
    const generic = vercel.redirects.find((r) => r.source === source && !r.has);
    const target = generic.destination.startsWith('/') ? 'https://walstack.io' + generic.destination : generic.destination;
    ok(rules[i].destination === target, `${host}${source} must match the walstack.io destination`);
  }
}

// 5. Snapshot script stays read-only and redacts credential text.
const sql = readFileSync(join(root, 'public/snapshot/walstack-snapshot.sql'), 'utf8');
const executable = sql.split('\n').filter((l) => !/^\s*(--|\\qecho)/.test(l)).join('\n');
ok(!/\b(INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|TRUNCATE|GRANT|REVOKE|VACUUM|ANALYZE|REINDEX|CLUSTER|COPY|EXPLAIN)\b/i.test(executable), 'Snapshot script has a write or execution statement');
ok(/SET default_transaction_read_only = on;/.test(sql) && /SET statement_timeout = '10s';/.test(sql) && /SET lock_timeout = '1s';/.test(sql), 'Snapshot session guards');
ok((sql.match(/omitted by script: text mentions a credential/g) || []).length === 2, 'Both query-text sections redact credentials');
ok(sql.includes('\\if :{?show_query_text}') && sql.includes('\\if :{?show_schema}'), 'Privacy switches must be overridable with psql -v');

// Owner-approved terms (Nov 2026): objective refund condition and a snapshot fit check.
for (const route of ['/', '/pricing', '/postgresql-performance-investigation']) {
  ok(!/evidence-backed improvement|find nothing you can act on/.test(page(route)), `${route} uses the old subjective refund wording`);
  ok(/no (evidence-backed recommendation|recommendation backed by evidence)/.test(page(route)), `${route} missing the objective refund condition`);
}
ok(/up to 5 snapshots a month/.test(page('/snapshot')) && /Up to 5 a month/.test(page('/pricing')), 'Snapshot cap must match site.snapshotMonthlyCap (5)');
ok(/check that the output is usable and the request fits/.test(page('/snapshot')) && /within 1 business day/.test(page('/snapshot')), 'Snapshot fit check missing');
ok(/within 1 business day/i.test(page('/snapshot/thank-you')), 'Receipt page must state the fit-check reply time');

// 6. Snapshot submission with mocked endpoint, analytics and timers.
const run = async (response, { analyticsCalls = true, throws = false } = {}) => {
  const events = []; let navigations = 0; const timers = [];
  const result = await submitSnapshot({
    action: 'https://formspree.test/f/x', data: {},
    fetchImpl: async () => { if (throws) throw new Error('offline'); return response; },
    track: (name, cb) => { events.push(name); if (analyticsCalls) cb(); },
    navigate: () => navigations++, wait: (fn) => timers.push(fn)
  });
  timers.forEach((fn) => fn());
  return { result, events, navigations };
};
let r = await run({ ok: true, status: 200 });
ok(r.result.ok && r.events.join() === 'snapshot_submitted' && r.navigations === 1, 'Accepted upload: one event, one navigation');
r = await run({ ok: true, status: 200 }, { analyticsCalls: false });
ok(r.navigations === 1, 'Blocked analytics must not trap the visitor');
r = await run({ ok: false, status: 422, json: async () => ({ errors: [{ message: 'File uploads are not supported on this plan' }] }) });
ok(!r.result.ok && r.events.length === 0 && r.navigations === 0 && /File uploads/.test(r.result.message), 'Rejected upload: no event, message shown');
r = await run({ ok: false, status: 500, json: async () => { throw new Error('html'); } });
ok(!r.result.ok && r.result.message === '' && r.events.length === 0, 'Server error without JSON');
r = await run(null, { throws: true });
ok(!r.result.ok && r.events.length === 0, 'Network failure');
const snapshotHtml = page('/snapshot');
for (const field of ['utm_source', 'first_utm_source', 'landing_page', 'referring_page', 'referral_source', 'referral_landing_page', '_gotcha', 'allowed_to_share']) {
  ok(snapshotHtml.includes(`name="${field}"`), `Snapshot form field ${field}`);
}

// 7. Analytics dispatch.
const sent = [];
const track = createTracker({ getPlausible: () => (name, opts) => { sent.push([name, opts]); opts.callback?.(); }, location: { pathname: '/pricing' }, campaignContext: { utm_source: 'hn' } });
let called = 0;
track('book_call_click', clickProps({ offer: 'upgrade' }, 'query-rescue'), () => called++);
ok(sent[0][0] === 'book_call_click' && sent[0][1].props.offer === 'upgrade' && sent[0][1].props.service_id === 'query-rescue' && sent[0][1].props.source_page === '/pricing' && sent[0][1].props.utm_source === 'hn' && called === 1, 'Tracked props');
const silent = createTracker({ getPlausible: () => undefined, location: { pathname: '/' }, campaignContext: {} });
silent('x', {}, () => called++);
ok(called === 2, 'Callback runs without analytics');

console.log(`Funnel audit passed: ${checks} checks (service routes, indexability, one-hop redirects, read-only snapshot script, mocked submission and analytics).`);
