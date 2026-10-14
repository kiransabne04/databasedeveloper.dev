import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://databasedeveloper.dev',
  integrations: [sitemap({ xslURL: '/sitemap.xsl' })],
  trailingSlash: 'never',
  markdown: {
    syntaxHighlight: false
  },
  build: {
    format: 'directory'
  }
});
