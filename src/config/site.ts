export const site = {
  brand: 'WalStack',
  legalName: 'WalStack',
  url: 'https://walstack.io',
  description:
    'WalStack helps engineering teams diagnose PostgreSQL performance problems and validate risky database upgrades through independent, evidence-backed assessments.',
  email: 'hello@walstack.io',
  personName: 'Kiran Sabne',
  linkedinUrl: 'https://www.linkedin.com/in/kiransabne/',
  githubUrl: 'https://github.com/kiransabne04',
  personalSiteUrl: 'https://kiransabne.dev',
  planReaderUrl: 'https://www.planreader.dev/',
  planReaderPostgresUrl: 'https://www.planreader.dev/postgresql-execution-plan-analyzer',
  planReaderSqlServerUrl: 'https://www.planreader.dev/sql-server-execution-plan-analyzer',
  planReaderSnowflakeUrl: 'https://www.planreader.dev/snowflake-query-profile-analyzer',
  sqlServerBlogUrl: 'https://mssqlserver.dev',
  directoryUrl: 'https://www.postgresql.org/support/professional_support/asia/',
  extensionUrl: 'https://github.com/kiransabne04/pg_stat_index_queries',
  analyticsHosts: ['walstack.io', 'www.walstack.io'],
  plausibleDomain: import.meta.env.PUBLIC_PLAUSIBLE_DOMAIN ?? 'walstack.io',
  plausibleScript: import.meta.env.PUBLIC_PLAUSIBLE_SCRIPT_URL || '',
  bookingUrl: import.meta.env.PUBLIC_BOOKING_URL || 'https://cal.com/kiransabne13/15min',
  callLabel: 'Book a 15-minute call',
  contactEndpoint: import.meta.env.PUBLIC_CONTACT_ENDPOINT ?? 'https://formspree.io/f/maeqleqk',
  snapshotEndpoint: import.meta.env.PUBLIC_SNAPSHOT_ENDPOINT || import.meta.env.PUBLIC_CONTACT_ENDPOINT || 'https://formspree.io/f/maeqleqk',
  retentionDays: 30,
  /** Free snapshot reviews accepted per calendar month. */
  snapshotMonthlyCap: 5,
  investigationTurnaround: '3 business days',
  investigationOffer: { display: '$450 for my first 3 clients, then $750' },
  upgradeOffer: { display: '$600 founding price, then $900' }
} as const;

export const nav = [
  { label: 'Investigation', href: '/postgresql-performance-investigation' },
  { label: 'Free snapshot', href: '/snapshot' },
  { label: 'Upgrade (PG14)', href: '/postgresql-upgrade-readiness' },
  { label: 'Pricing', href: '/pricing' },
  { label: 'About', href: '/about' }
] as const;
