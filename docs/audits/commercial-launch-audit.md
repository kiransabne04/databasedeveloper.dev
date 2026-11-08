# Commercial launch audit — 8 November 2026

## Confirmed

- Astro 7 static site with 50+ public routes, a generated sitemap, robots.txt, canonical and Open Graph metadata, JSON-LD, legacy Vercel redirects, and a seven-article migration regression script. Preserve these routes and redirects.
- The homepage and investigation/upgrade pages already explain evidence-led work. A synthetic performance report and two reproducible lab cases exist; they are explicitly labeled synthetic. PlanReader and the experimental extension are linked.
- The contact form uses Formspree (`PUBLIC_CONTACT_ENDPOINT`, with a configured fallback endpoint), a honeypot, client-side success/error messages, and a mailto fallback when no endpoint is configured. A public Cal.com URL is configured. Neither live delivery nor booking availability has been verified.
- GA4 is consent gated on production hostnames. Plausible is optional. Source-page and three UTM fields are captured, but offer choice is hidden and no partner flow exists. Qualified-lead/proposal-requested events must come from real CRM stages, not website clicks.
- Public pages and JSON-LD initially showed the previous $450/$750 offer experiment; pricing also promoted a $149 query fix and $60/hour contract. Founder chose to remove public prices and quote bounded work after fit review while the practice wins its first clients.
- Homepage, About, and article author bio claimed about eight years. The founder confirmed this figure for public use; wording now applies it to overall engineering experience rather than every named technology.
- The published collector is a bounded, read-only psql script. Its output can expose query fragments and database object names; `pg_monitor` access and version/platform support should be checked per client. No client evidence belongs in this repository.
- PlanReader's public site says plan analysis runs locally in the browser. This implementation did not independently audit PlanReader's code or deployed network behavior; the existing link and description remain subject to that separate product check. The extension is described as experimental, never production-proven.
- `npm run build` performs `astro check`; CI currently does not run the content audit. No broad route/CTA/price regression exists.

## Verified support dates

PG14 community final release: 12 November 2026 ([PostgreSQL](https://www.postgresql.org/support/versioning/)). RDS and Aurora standard support: 28 February 2027, with Extended Support year-one pricing from 1 March 2027 ([RDS](https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-release-calendar.html), [Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/aurorapostgresql-release-calendar.html)). Azure Database for PostgreSQL Flexible Server standard support: 31 January 2027; Extended Support starts 1 February 2027 ([Microsoft](https://learn.microsoft.com/en-us/azure/postgresql/configure-maintain/extended-support)). These are distinct support policies, and minor-version dates can be earlier.

## Unknowns and founder checks

- The founder confirmed written employer approval with no relevant restrictions, but the exact approval text should still be checked before first client delivery. Availability remains subject to capacity.
- Proof for detailed personal production claims on About.
- Formspree inbox delivery, Cal.com availability, GA4/Plausible event receipt, Search Console indexing, real mobile/Lighthouse results, and any indexed legacy URLs beyond the migration inventory.
- Client evidence retention, access, deletion and AI-processing terms. These must be agreed before a paid engagement.

## Priority

1. P0: Rewrite offer hierarchy and remove stale price/schema copy. Use founder-confirmed experience duration and remove the unverified response-time promise.
2. P0: Improve inquiry flow with visible offer preselection, partner attribution, accessible errors, and offline/no-JS fallback.
3. P0: Add partner page and printable kit; expose a clear partnership CTA.
4. P1: Add route, internal-link, CTA and offer-schema regression checks; run them in CI.
5. P1: Keep prospect/CRM/delivery operations private and human approved. Use a hosted CRM before custom storage.

## Reference sites reviewed

- [enterreset.com](https://enterreset.com/) (founder-led fractional CTO site): clear buyer problem, direct founder identity, simple conversation CTA and visible work examples. WalStack adopts the clear decision/next-step pattern but uses only its own synthetic labs and founder information.
- [MyDBOps PostgreSQL consulting](https://www.mydbops.com/postgresql/consulting-service): problem-led service menu, scoped process and a “which service fits” comparison. WalStack adds a compact offer-fit table and written-quote sequence. MyDBOps' client logos, results, certifications, teams and 24×7 coverage are not WalStack claims.
