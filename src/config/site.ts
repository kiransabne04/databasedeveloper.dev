export const site = {
  brand: 'DatabaseDeveloper',
  legalName: 'DatabaseDeveloper',
  url: 'https://databasedeveloper.dev',
  description:
    'Evidence-first PostgreSQL performance investigations for SaaS engineering teams, with specialist capability across SQL Server, pgvector, Snowflake and OLAP workloads.',
  email: 'kiran@databasedeveloper.dev',
  personName: 'Kiran Sabne',
  planReaderUrl: 'https://planreader.dev',
  // GA4 measurement ID (public). Loads only on the production hostnames below, after consent.
  gaId: import.meta.env.PUBLIC_GA_ID || 'G-4YXPCMHXYD',
  analyticsHosts: ['databasedeveloper.dev', 'www.databasedeveloper.dev'],
  foundingOffer: {
    enabled: true,
    international: '$450',
    india: '₹29,000',
    label: 'Founding investigation'
  },
  investigationTurnaround: '3 business days',
  standardOffer: {
    international: '$750+',
    india: '₹45,000+'
  },
  upgradeOffer: {
    international: '$750–900',
    india: '₹45k–55k'
  }
} as const;

export const nav = [
  { label: 'Investigation', href: '/postgresql-performance-investigation' },
  { label: 'Upgrade', href: '/postgresql-upgrade-readiness' },
  { label: 'Problems', href: '/problems' },
  { label: 'Capabilities', href: '/capabilities' },
  { label: 'Guides', href: '/insights' },
  { label: 'Pricing', href: '/pricing' }
] as const;
