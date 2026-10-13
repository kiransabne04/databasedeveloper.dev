# databasedeveloper.dev — final starter

Astro site for the DatabaseDeveloper v3.1 strategy. The site builds locally; review the preview, contact path and old Hashnode URLs before changing the live domain.

## Positioning

**Production PostgreSQL performance, investigated from evidence—not guesses.**

Primary:
- PostgreSQL Performance Investigation
- PostgreSQL Upgrade Readiness
- AWS RDS / Aurora PostgreSQL

Secondary capability:
- SQL Server
- pgvector
- Snowflake
- OLAP / analytical workloads

## Run

```bash
npm install
npm run dev
```

Build:

```bash
npm run build
```

## Before launch

1. Confirm `kiran@databasedeveloper.dev` still receives inquiries.
2. Optionally set `PUBLIC_CONTACT_ENDPOINT`.
3. Optionally set analytics env vars.
4. Deploy to a Vercel Pro preview or another host that permits commercial sites. Vercel Hobby is limited to personal, non-commercial use.
5. Verify content/links/mobile.
6. Review `docs/MIGRATION_FROM_HASHNODE.md`. The public sitemap's eight articles are mapped; test all retained paths and redirects on the preview, then compare Search Console for any additional indexed URLs before switching the domain.

## AI context

- `AGENTS.md` is for Codex/code agents.
- `CLAUDE.md` is for Claude/Claude Code.
- `docs/business/` contains the shared strategy/implementation context.

Codex should implement/code.
Claude should review strategy/copy/delivery docs.
ChatGPT should be used for current research, market/lead monitoring and orchestration.

## Truthfulness

No fake clients, logos, staff or performance claims.
Synthetic cases are clearly labeled and backed by reproducible local lab output.
