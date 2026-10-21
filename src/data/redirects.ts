/**
 * Verified mapping of the original article URLs. Keep in sync with vercel.json.
 * Seven old article URLs are retained as pages; the interview pointer redirects
 * to its full article on kiransabne.dev. RSS remains at /rss.xml.
 */
export const plannedRedirects: Array<{ from: string; to: string; status: 301 | 308 }> = [
  {
    from: '/crack-sql-interviews-with-these-postgresql-internals-and-real-questions',
    to: 'https://kiransabne.dev/cracking-the-sql-interview-real-questions-and-postgresql-internals-you-should-know',
    status: 308
  },
  {
    from: '/archive',
    to: '/insights',
    status: 308
  },
  {
    from: '/members',
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
