import { site } from '../config/site';

/**
 * Paid offers that guides point readers to. Each article names one with its
 * `offer` prop so the header line, in-article box and closing panel all match
 * the problem the reader came with.
 */
export type OfferKey = 'investigation' | 'upgrade' | 'pgvector' | 'sqlserver';

export interface Offer {
  name: string;
  href: string;
  price: string;
  terms: string;
  receive: string[];
  send: string;
  askLabel: string;
  magnet: { label: string; href: string; track: string };
}

const investigationPrice = site.foundingOffer.enabled
  ? `${site.foundingOffer.international} founding price for the first three engagements`
  : `From ${site.standardOffer.international}`;

export const offers: Record<OfferKey, Offer> = {
  investigation: {
    name: 'PostgreSQL performance investigation',
    href: '/postgresql-performance-investigation',
    price: investigationPrice,
    terms: `Report in ${site.investigationTurnaround} from read-only evidence`,
    receive: [
      'The statements and causes behind the slowdown, ranked by impact',
      'Evidence, risk and rollback for each recommended change',
      'A validation plan: which numbers should move, and by how much'
    ],
    send: 'pg_stat_statements output from a normal and a slow window, your version and platform',
    askLabel: 'Request an investigation',
    magnet: { label: 'See a sample report', href: '/sample-report', track: 'sample_report_click' }
  },
  upgrade: {
    name: 'PostgreSQL upgrade readiness review',
    href: '/postgresql-upgrade-readiness',
    price: `${site.upgradeOffer.international} for one cluster`,
    terms: 'Fixed scope and delivery date agreed before work starts',
    receive: [
      'Blockers and risks for your target version, ranked with evidence',
      'A pre-upgrade baseline and the queries to compare afterwards',
      'Go/no-go and rollback criteria for the change window'
    ],
    send: 'your platform, current and target version, extension list and any CDC or replication in use',
    askLabel: 'Ask about upgrade readiness',
    magnet: { label: 'Get the PG14 checklist', href: '/postgresql-14-upgrade-checklist', track: 'checklist_click' }
  },
  pgvector: {
    name: 'pgvector performance review',
    href: '/pgvector-performance',
    price: 'Fixed price agreed after a free fit review',
    terms: 'Measured recall and latency on your data, not a benchmark from elsewhere',
    receive: [
      'Recall and latency measured against an exact baseline',
      'Index, filtering and memory choices ranked for your workload',
      'A validation plan for the change'
    ],
    send: 'pgvector version, index definitions, a typical filtered query and table sizes',
    askLabel: 'Ask about a pgvector review',
    magnet: { label: 'See a sample report', href: '/sample-report', track: 'sample_report_click' }
  },
  sqlserver: {
    name: 'SQL Server performance review',
    href: '/sql-server-performance',
    price: 'Fixed price agreed after a free fit review',
    terms: 'Read-only evidence from Query Store and DMVs',
    receive: [
      'Regressed queries and their causes, ranked by impact',
      'Evidence, risk and rollback for each recommended change',
      'A validation plan using the same Query Store measures'
    ],
    send: 'SQL Server version, the slow query or Query Store export, and when it started',
    askLabel: 'Ask about a SQL Server review',
    magnet: { label: 'See a sample report', href: '/sample-report', track: 'sample_report_click' }
  }
};

/** Contact link that tells the form which guide and offer the reader came from. */
export function contactHref(offer: OfferKey, fromPath: string): string {
  const params = new URLSearchParams({ offer, from: fromPath });
  return `/contact?${params.toString()}`;
}
