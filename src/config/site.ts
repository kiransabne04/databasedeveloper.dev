export const site = {
  brand: 'DatabaseDeveloper',
  legalName: 'DatabaseDeveloper',
  url: 'https://databasedeveloper.dev',
  description:
    'Evidence-first PostgreSQL performance investigations for SaaS engineering teams, with specialist capability across SQL Server, pgvector, Snowflake and OLAP workloads.',
  email: 'kiran@databasedeveloper.dev',
  personName: 'Kiran Sabne',
  linkedinUrl: 'https://www.linkedin.com/in/kiransabne/',
  githubUrl: 'https://github.com/kiransabne04',
  personalSiteUrl: 'https://kiransabne.dev',
  planReaderUrl: 'https://planreader.dev',
  sqlServerBlogUrl: 'https://mssqlserver.dev',
  // GA4 measurement ID (public). Loads only on the production hostnames below, after consent.
  gaId: import.meta.env.PUBLIC_GA_ID || 'G-4YXPCMHXYD',
  analyticsHosts: ['databasedeveloper.dev', 'www.databasedeveloper.dev'],
  // Public scheduling page (Cal.com, Calendly, Google Calendar booking page…).
  // Empty hides every "book a call" link, so no page points at a dead booking URL.
  bookingUrl: import.meta.env.PUBLIC_BOOKING_URL || 'https://cal.com/kiransabne13/triage-call',
  triageCallMinutes: 20,
  // Hosted form endpoint (Formspree). Empty falls back to an email draft.
  contactEndpoint: import.meta.env.PUBLIC_CONTACT_ENDPOINT || 'https://formspree.io/f/maeqleqk',
  foundingOffer: {
    enabled: true,
    international: '$450',
    label: 'Founding investigation',
    scope: 'up to 5 dominant statements or problem areas and 7 days of follow-up questions'
  },
  investigationTurnaround: '5 business days',
  standardOffer: {
    scope: 'up to 10 dominant statements or problem areas and 14 days of follow-up questions',
    international: '$750+'
  },
  upgradeOffer: {
    international: '$750–900'
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
