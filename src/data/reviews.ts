// Only enter a public fee or delivery window here after business-owner approval.
export const reviews = {
  'query-rescue': {
    name: 'PostgreSQL Query Rescue',
    href: '/postgresql-query-rescue',
    price: '',
    turnaround: '',
    cta: 'Request a Query Review',
  },
  'pr-review': {
    name: 'PostgreSQL PR & Migration Review',
    href: '/postgresql-pr-review',
    price: '',
    turnaround: '',
    cta: 'Request a Database Change Review',
  },
} as const;

export type ReviewKey = keyof typeof reviews;
