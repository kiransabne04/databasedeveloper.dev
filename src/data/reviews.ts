// Public fee and delivery settings remain empty until the owner approves them.
export const reviews = {
  'query-rescue': {
    name: 'Query Rescue',
    href: '/query-rescue',
    price: '',
    turnaround: '',
    cta: 'Request a Query Review',
  },
  'database-code-review': {
    name: 'Database Code Review',
    href: '/database-code-review',
    price: '',
    turnaround: '',
    cta: 'Request a Database Code Review',
  },
} as const;

export type ReviewKey = keyof typeof reviews;
