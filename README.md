# WalStack — walstack.io

Astro site for WalStack. The site builds locally; review the preview, contact path and old Hashnode URLs before changing the live domain.

## 30-day conversion test

The primary conversion is a free PostgreSQL snapshot submission. The secondary conversion is a booked 15-minute call with Kiran. The pricing page lists the investigation and upgrade review fees.

Review the [complete page copy](docs/conversion-test-copy.html) and [current setup and measurement plan](docs/analytics/MEASUREMENT_PLAN.md) before starting the test. The plan covers the portrait, script download, file uploads, the production calendar, analytics goals and the Search Console sitemap.

## Run

```bash
npm install
npm run dev
```

Build and audit:

```bash
npm run build
npm run audit:content
```

Commercial launch review, preview screenshots, live integration checklist and rollback steps: `docs/LAUNCH_REVIEW.md`. Prospecting and delivery templates live in the separate private `walstack-business-ops` repository; its local checkout is ignored by this public repository.

## Before launch

1. Confirm `hello@walstack.io` receives inquiries and the form endpoint delivers to the intended inbox.
2. Optionally set `PUBLIC_CONTACT_ENDPOINT`.
3. Optionally set analytics env vars.
4. Deploy to a Vercel Pro preview or another host that permits commercial sites. Vercel Hobby is limited to personal, non-commercial use.
5. Verify content/links/mobile.
6. Review `docs/MIGRATION_FROM_HASHNODE.md`. The public sitemap's eight articles are mapped; test all retained paths and redirects on the preview, then compare Search Console for any additional indexed URLs before switching the domain.

## AI context

`AGENTS.md`, `CLAUDE.md` and `docs/business/` hold the agent instructions and business strategy. They are kept locally and excluded from this public repository by `.gitignore`.

Codex should implement/code.
Claude should review strategy/copy/delivery docs.
ChatGPT should be used for current research, market/lead monitoring and orchestration.

## Truthfulness

No fake clients, logos, staff or performance claims.
Synthetic cases are clearly labeled and backed by reproducible local lab output.
