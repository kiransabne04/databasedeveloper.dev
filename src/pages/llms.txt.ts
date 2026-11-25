import type { APIRoute } from 'astro';
import { site } from '../config/site';
import { posts } from '../data/posts';

// llms.txt (https://llmstxt.org): a plain-text index for AI assistants. Built from
// site config and the feed list so prices and guides stay in sync with the pages.
export const GET: APIRoute = () => {
  const link = (title: string, path: string, note: string) => `- [${title}](${site.url}${path}): ${note}`;
  const body = [
    `# ${site.brand}`,
    '',
    `> ${site.description} Run by ${site.personName}, an independent PostgreSQL performance consultant based in India, working remotely and asynchronously.`,
    '',
    'WalStack is one person, not a firm. It does not offer 24/7 incident response. Sample reports and case studies use generated lab data and contain no client results.',
    '',
    '## Services',
    link('PostgreSQL Performance Tuning & Slowdown Audit', '/postgresql-performance-investigation', `Fixed-price audit of one production PostgreSQL database: the cause, the SQL fix, its lock risk, rollback and a 14-day check. ${site.investigationOffer.display}.`),
    link('PostgreSQL 14 Upgrade Readiness Assessment for RDS & Aurora', '/postgresql-upgrade-readiness', `Blockers, a query baseline, regression checks and a rollback plan for a major-version upgrade, before RDS standard support for 14 ends on 28 February 2027. ${site.upgradeOffer.display}.`),
    link('AWS RDS & Aurora PostgreSQL Performance Tuning Consultant', '/aws-rds-aurora-postgresql', 'High CPU, slow queries, connection pressure, RDS Proxy pinning and Aurora I/O cost, from Database Insights and CloudWatch evidence. Priced as the slowdown audit.'),
    link('PostgreSQL Slow Query Optimization & Plan Review', '/query-rescue', 'One known slow PostgreSQL statement reviewed with its plan: ranked fixes, lock risk and a before-and-after check.'),
    link('PostgreSQL Schema & Migration Code Review', '/database-code-review', 'One schema change, migration or database pull request reviewed for locks, rollout order and performance risk before it ships.'),
    link('Free PostgreSQL Health Check & Performance Snapshot', '/snapshot', `One read-only script; up to ${site.snapshotMonthlyCap} accepted reviews a month, 3 written findings each.`),
    link('PostgreSQL Consultant for Agencies and Fractional CTOs', '/partners', 'How partner engagements, confidentiality and white label work.'),
    link('PostgreSQL Consulting Pricing', '/pricing', 'All published prices in USD.'),
    link('How a PostgreSQL investigation works', '/how-it-works', 'The steps from a slow page to a checked fix.'),
    link('pgvector performance review', '/pgvector-performance', 'HNSW and IVFFlat choices, recall and latency, filtered search.'),
    '',
    '## Problems',
    link('PostgreSQL performance problems', '/problems', 'Symptom-first triage pages.'),
    link('High PostgreSQL CPU', '/problems/postgresql-high-cpu', 'Evidence to collect before scaling the instance.'),
    link('PostgreSQL lock contention', '/problems/postgresql-lock-contention', 'Blocking sessions, DDL lock queues and idle transactions.'),
    link('PostgreSQL plan regression', '/problems/postgresql-plan-regression', 'Plans, row estimates, statistics and generic plans.'),
    link('PostgreSQL connection exhaustion', '/problems/postgresql-connection-exhaustion', 'Pool budgets, idle-in-transaction sessions and RDS Proxy.'),
    '',
    '## Evidence',
    link('Sample investigation report', '/sample-report', 'Report format, built on a demo database.'),
    link('Sample upgrade readiness report', '/sample-upgrade-readiness-report', 'Synthetic PostgreSQL 14 to 18 decision record.'),
    link('Lab case studies', '/case-studies', 'Reproduced problems on generated data.'),
    link('Lab: DDL lock queue', '/case-studies/lab-lock-queue', 'One idle transaction, a waiting migration, then reads stop.'),
    link('Lab: generic plan regression', '/case-studies/lab-generic-plan-regression', 'A plan setting that helped large tenants and stalled small ones.'),
    link('Evidence collector', '/evidence-collection', 'The read-only collection script and what it reads.'),
    `- [Lab scripts and outputs](https://github.com/kiransabne04/databasedeveloper.dev/tree/main/labs): Reproducible scripts behind the guides.`,
    `- [pg_stat_index_queries](${site.extensionUrl}): Experimental open-source PostgreSQL extension by ${site.personName} that shows which queries use each index; SQL edition for RDS/Aurora.`,
    `- [PostgreSQL.org professional services listing](${site.directoryUrl}): Directory entry.`,
    '',
    '## Guides',
    ...posts.filter((p) => p.postgresql).map((p) => link(p.title, p.path, p.description)),
    '',
    '## Contact',
    link('Contact', '/contact', `Enquiry form; email ${site.email}.`),
    link('About', '/about', `${site.personName}: background and links.`),
    ''
  ].join('\n');
  return new Response(body, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};
