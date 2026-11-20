import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://walstack.io',
  integrations: [sitemap({ xslURL: '/sitemap.xsl', filter: (page) => !['https://walstack.io/postgresql-query-rescue', 'https://walstack.io/postgresql-pr-review'].includes(page) })],
  trailingSlash: 'never',
  markdown: {
    syntaxHighlight: false
  },
  build: {
    format: 'directory'
  }
});
