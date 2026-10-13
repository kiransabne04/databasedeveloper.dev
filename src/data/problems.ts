export const problems = [
  {
    title: 'High PostgreSQL CPU',
    href: '/problems/postgresql-high-cpu',
    description: 'Separate workload concentration, bad plans, I/O pressure and application amplification before scaling hardware.'
  },
  {
    title: 'Connection exhaustion',
    href: '/problems/postgresql-connection-exhaustion',
    description: 'Distinguish pool behavior, long transactions, application storms and server-side limits.'
  },
  {
    title: 'Lock contention',
    href: '/problems/postgresql-lock-contention',
    description: 'Find blockers, lock queues, long transactions and DDL interactions from evidence.'
  },
  {
    title: 'Plan regression',
    href: '/problems/postgresql-plan-regression',
    description: 'Compare plan shape, row estimates, data distribution and deployment/version changes.'
  }
] as const;
