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
    `> ${site.description} Run by ${site.personName}, an independent PostgreSQL performance engineer based in Pune, India, working remotely and asynchronously.`,
    '',
    'WalStack is one person, not a firm. It does not offer 24/7 incident response. Sample reports and case studies use generated lab data and contain no client results.',
    '',
    '## Services',
    link('PostgreSQL performance investigation', '/postgresql-performance-investigation', `Cause of a slow or expensive RDS, Aurora or self-managed PostgreSQL database, with risk, rollback and validation for each change. ${site.investigationOffer.display}.`),
    link('PostgreSQL upgrade readiness review', '/postgresql-upgrade-readiness', `Blockers, query baseline and go/no-go criteria for a major-version upgrade. ${site.upgradeOffer.display}.`),
    link('Free PostgreSQL snapshot review', '/snapshot', `A read-only script; up to ${site.snapshotMonthlyCap} accepted reviews a month, 3 written findings each.`),
    link('Query Rescue', '/query-rescue', 'One known slow PostgreSQL or SQL Server query reviewed with its plan.'),
    link('Database Code Review', '/database-code-review', 'One migration or pull request reviewed for locking, rollout and performance risk.'),
    link('SQL Server performance consulting', '/sql-server-performance', 'Query Store, plan regressions and blocking.'),
    link('For agencies and fractional CTOs', '/partners', 'How partner engagements, confidentiality and white label work.'),
    link('Pricing', '/pricing', 'All published prices in USD.'),
    '',
    '## Evidence',
    link('Sample investigation report', '/sample-report', 'Report format, built on a demo database.'),
    link('Lab case studies', '/case-studies', 'Reproduced problems on generated data.'),
    `- [Lab scripts and outputs](https://github.com/kiransabne04/databasedeveloper.dev/tree/main/labs): Reproducible scripts behind the guides.`,
    `- [PostgreSQL.org professional services listing](${site.directoryUrl}): Directory entry.`,
    '',
    '## Guides',
    ...posts.map((p) => link(p.title, p.path, p.description)),
    '',
    '## Contact',
    link('Contact', '/contact', `Enquiry form; email ${site.email}.`),
    link('About', '/about', `${site.personName}: background and links.`),
    ''
  ].join('\n');
  return new Response(body, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};
