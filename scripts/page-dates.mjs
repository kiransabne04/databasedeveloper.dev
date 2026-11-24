// Writes src/data/page-dates.json: for each page route, the date its source last changed.
// Uses git history of the page file and any src/originals/*.md it imports. Files with
// uncommitted changes get today's date. Run `npm run page-dates` before committing page edits.
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, globSync } from 'node:fs';

const today = new Date().toISOString().slice(0, 10);
const dirty = new Set(execFileSync('git', ['status', '--porcelain'], { encoding: 'utf8' })
  .split('\n').filter(Boolean).map((line) => line.slice(3).trim()));
const fileDate = (file) => {
  if (dirty.has(file) || [...dirty].some((d) => d.endsWith('/') && file.startsWith(d))) return today;
  return execFileSync('git', ['log', '-1', '--format=%cs', '--', file], { encoding: 'utf8' }).trim() || today;
};

const dates = {};
for (const file of globSync('src/pages/**/*.astro')) {
  let route = '/' + file.replace(/^src\/pages\//, '').replace(/\.astro$/, '').replace(/(^|\/)index$/, '');
  route = route.replace(/\/$/, '') || '/';
  if (route.includes('[')) continue;
  const sources = [file, ...[...readFileSync(file, 'utf8').matchAll(/from '\.\.\/(?:\.\.\/)?(originals\/[^']+\.md)'/g)].map((m) => 'src/' + m[1])];
  dates[route] = sources.map(fileDate).sort().at(-1);
}
writeFileSync('src/data/page-dates.json', JSON.stringify(Object.fromEntries(Object.entries(dates).sort()), null, 2) + '\n');
console.log(`page-dates: ${Object.keys(dates).length} routes`);
