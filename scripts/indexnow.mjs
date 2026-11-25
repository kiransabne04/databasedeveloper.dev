// Tell IndexNow engines (Bing, Yandex, Seznam, Naver) which walstack.io URLs changed.
// Google does not use IndexNow.
//
// Reads the LIVE sitemap, so only deployed pages are sent. Compares each URL's
// lastmod with src/data/indexnow-state.json and lists the changed ones.
//
//   npm run indexnow                          dry run: list what would be sent
//   npm run indexnow -- --since 2026-11-24    first run (no state yet): URLs with lastmod on or after the date
//   npm run indexnow -- --url /privacy        add a URL that is not in the sitemap (e.g. newly noindexed)
//   npm run indexnow -- --submit              send, then record the result in the state file (commit it)
//
// Never run from build or CI: every submission sends data to an outside service.
import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';

const HOST = 'walstack.io';
const ORIGIN = `https://${HOST}`;
const ENDPOINT = 'https://api.indexnow.org/indexnow';
const STATE = new URL('../src/data/indexnow-state.json', import.meta.url);
const PUBLIC = new URL('../public/', import.meta.url);

const args = process.argv.slice(2);
const submit = args.includes('--submit');
const since = args.includes('--since') ? args[args.indexOf('--since') + 1] : null;
const extra = args.flatMap((a, i) => (a === '--url' ? [args[i + 1]] : []));
if (since && !/^\d{4}-\d{2}-\d{2}$/.test(since)) throw new Error('--since needs a date like 2026-11-24');

const keys = readdirSync(PUBLIC).filter((f) => /^[a-f0-9]{32}\.txt$/.test(f));
if (keys.length !== 1) throw new Error(`Expected one IndexNow key file in public/, found ${keys.length}`);
const key = keys[0].slice(0, -4);
if (readFileSync(new URL(keys[0], PUBLIC), 'utf8').trim() !== key) throw new Error('Key file content must equal its name');
const keyLocation = `${ORIGIN}/${key}.txt`;

const state = existsSync(STATE) ? JSON.parse(readFileSync(STATE, 'utf8')) : { submitted: {} };
const firstRun = Object.keys(state.submitted).length === 0;
if (firstRun && !since) throw new Error('No submissions recorded yet. Pass --since YYYY-MM-DD to choose the first batch.');

const get = async (url) => {
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok) throw new Error(`${url} returned ${res.status}`);
  return res.text();
};
const index = await get(`${ORIGIN}/sitemap-index.xml`);
const sitemaps = [...index.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => m[1]);
const entries = [];
for (const sm of sitemaps) {
  const xml = await get(sm);
  for (const m of xml.matchAll(/<url>\s*<loc>([^<]+)<\/loc>\s*(?:<lastmod>([^<]+)<\/lastmod>)?/g)) {
    entries.push({ url: m[1], lastmod: (m[2] || '').slice(0, 10) });
  }
}

const changed = entries.filter(({ url, lastmod }) => {
  if (since && lastmod >= since) return true;
  return !firstRun && state.submitted[url] !== lastmod;
});
for (const path of extra) {
  if (!path?.startsWith('/')) throw new Error('--url takes a path such as /privacy');
  const url = ORIGIN + (path === '/' ? '/' : path.replace(/\/$/, ''));
  if (!changed.some((e) => e.url === url)) changed.push({ url, lastmod: 'extra' });
}
for (const { url } of changed) if (new URL(url).host !== HOST) throw new Error(`Foreign host: ${url}`);

console.log(`${entries.length} URLs in the live sitemap; ${changed.length} to send.`);
for (const e of changed) console.log(`  ${e.lastmod}  ${e.url}`);
if (!changed.length) process.exit(0);
if (changed.length > 10000) throw new Error('IndexNow accepts at most 10,000 URLs per request');

if (!submit) {
  console.log('\nDry run. Nothing sent. Re-run with --submit after the deploy is live.');
  process.exit(0);
}

const live = await get(keyLocation).catch((e) => { throw new Error(`Key file not live at ${keyLocation}: ${e.message}`); });
if (live.trim() !== key) throw new Error(`Live key file at ${keyLocation} does not match`);

const res = await fetch(ENDPOINT, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json; charset=utf-8' },
  body: JSON.stringify({ host: HOST, key, keyLocation, urlList: changed.map((e) => e.url) })
});
console.log(`\nIndexNow responded ${res.status} ${res.statusText}`);
if (res.status !== 200 && res.status !== 202) {
  console.error(await res.text());
  process.exit(1);
}

const today = new Date().toISOString().slice(0, 10);
for (const e of entries) if (changed.some((c) => c.url === e.url)) state.submitted[e.url] = e.lastmod;
for (const e of changed) if (e.lastmod === 'extra') state.submitted[e.url] = `extra ${today}`;
if (firstRun) for (const e of entries) state.submitted[e.url] ??= e.lastmod; // older pages count as already known
state.lastSubmission = { date: today, count: changed.length, status: res.status };
state.submitted = Object.fromEntries(Object.entries(state.submitted).sort());
writeFileSync(STATE, JSON.stringify(state, null, 2) + '\n');
console.log('Recorded in src/data/indexnow-state.json. Commit it.');
