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
  // GA4 measurement ID (public). Loads only on the production hostnames below, after consent.
  gaId: import.meta.env.PUBLIC_GA_ID ?? 'G-4YXPCMHXYD',
  analyticsHosts: ['walstack.io', 'www.walstack.io'],
  // Public scheduling page (Cal.com, Calendly, Google Calendar booking page…).
  // Empty hides every "book a call" link, so no page points at a dead booking URL.
  bookingUrl: import.meta.env.PUBLIC_BOOKING_URL ?? 'https://cal.com/kiransabne13/triage-call',
  triageCallMinutes: 20,
  // Hosted form endpoint (Formspree). Empty falls back to an email draft.
  contactEndpoint: import.meta.env.PUBLIC_CONTACT_ENDPOINT ?? 'https://formspree.io/f/maeqleqk',
  investigationTurnaround: '5–7 business days',
  investigationOffer: { display: 'Fixed quote after fit review', scope: 'one cluster, one dominant workload or bounded problem, up to 10 prioritized query fingerprints or problem areas' },
  upgradeOffer: { display: 'Fixed quote after fit review', scope: 'one cluster, agreed current and target versions, representative workload and major blockers' },
  sprintOffer: { display: 'Custom scope and quote', scope: 'a separately agreed remediation or validation objective' }
} as const;

export const nav = [
  { label: 'Investigation', href: '/postgresql-performance-investigation' },
  { label: 'Upgrade', href: '/postgresql-upgrade-readiness' },
  { label: 'Problems', href: '/problems' },
  { label: 'Capabilities', href: '/capabilities' },
  { label: 'Guides', href: '/insights' },
  { label: 'Pricing', href: '/pricing' },
  { label: 'Partners', href: '/partners' }
] as const;
