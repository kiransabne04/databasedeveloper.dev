import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import { readFileSync } from 'node:fs';

const site = 'https://walstack.io';
// Noindex pages: aliases, the receipt, secondary capabilities and legal pages.
const excluded = new Set([
  '/postgresql-query-rescue', '/postgresql-pr-review', '/snapshot/thank-you',
  '/sql-server-performance', '/snowflake-performance', '/olap-analytical-performance',
  '/partner-kit', '/privacy', '/terms', '/capabilities',
  // Non-PostgreSQL articles, noindex since 26 Nov 2026
  '/insights/snowflake-gen2-vs-adaptive-warehouses', '/insights/sql-server-implicit-conversion-nvarchar-varchar',
  '/insights/sql-server-parameter-sniffing-query-store', '/mastering-mongodb-locking-concurrency-and-performance-optimization-a-deep-dive'
].map((path) => site + path));
// Last source change per route, from `npm run page-dates`.
const pageDates = JSON.parse(readFileSync(new URL('./src/data/page-dates.json', import.meta.url), 'utf8'));

export default defineConfig({
  site,
  integrations: [sitemap({
    xslURL: '/sitemap.xsl',
    filter: (page) => !excluded.has(page.replace(/\/$/, '')),
    serialize: (item) => {
      const path = item.url.replace(site, '').replace(/\/$/, '') || '/';
      return pageDates[path] ? { ...item, lastmod: pageDates[path] } : item;
    }
  })],
  trailingSlash: 'never',
  markdown: {
    syntaxHighlight: false
  },
  build: {
    format: 'directory'
  }
});
