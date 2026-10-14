/**
 * Verified legacy Hashnode mapping. Keep in sync with vercel.json.
 * All eight old article URLs are retained as pages; RSS remains at /rss.xml.
 */
export const plannedRedirects: Array<{ from: string; to: string; status: 301 | 308 }> = [
  {
    from: '/archive',
    to: '/insights',
    status: 308
  },
  {
    from: '/recommendations',
    to: '/insights',
    status: 308
  },
  {
    from: '/sitemap.xml',
    to: '/sitemap-index.xml',
    status: 308
  }
];
