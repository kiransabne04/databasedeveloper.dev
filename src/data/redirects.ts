/**
 * Verified legacy Hashnode mapping. Keep in sync with vercel.json.
 * The other seven old DatabaseDeveloper URLs are retained as article routes.
 */
export const plannedRedirects: Array<{ from: string; to: string; status: 301 | 308 }> = [
  {
    from: '/crack-sql-interviews-with-these-postgresql-internals-and-real-questions',
    to: 'https://kiransabne.dev/cracking-the-sql-interview-real-questions-and-postgresql-internals-you-should-know',
    status: 308
  }
];
