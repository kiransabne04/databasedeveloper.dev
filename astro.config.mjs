import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://databasedeveloper.dev',
  integrations: [sitemap()],
  trailingSlash: 'never',
  build: {
    format: 'directory'
  }
});
