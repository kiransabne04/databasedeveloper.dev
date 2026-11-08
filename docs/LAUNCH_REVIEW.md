# Commercial launch review — 8 November 2026

## Review the preview

Run `npm ci`, `npm run build`, then `npm run preview -- --host 127.0.0.1 --port 4322`. Open `/`, `/pricing`, `/partners`, `/partner-kit`, `/postgresql-performance-investigation`, `/postgresql-upgrade-readiness`, `/sample-upgrade-readiness-report` and the offer-specific contact URLs. Do not deploy this branch automatically.

Screenshots from the built local preview: [desktop homepage](audits/screenshots/home-desktop.png), [390px homepage](audits/screenshots/home-mobile.png), [desktop partner page](audits/screenshots/partners-desktop.png), [390px partnership inquiry](audits/screenshots/contact-mobile.png). Chrome emulation measured `scrollWidth` equal to viewport width on the tested pages; partnership preselection was `partnership`.

Chrome's print-to-PDF output for `/partner-kit` was verified as one A4 page; that PDF is available at `/downloads/walstack-partner-kit.pdf`.

Local Lighthouse against the static preview, using the installed Chrome on 8 November 2026:

| Mode | Performance | Accessibility | Best practices | SEO | LCP | CLS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Mobile | 100 | 100 | 100 | 100 | 0.8 s | 0 |
| Desktop | 100 | 100 | 100 | 100 | 0.2 s | 0 |

These local scores do not predict production network or third-party behavior. The JSON reports are local in `/private/tmp/walstack-lighthouse-preview-mobile-final.json` and `/private/tmp/walstack-lighthouse-preview-desktop.json`.

## Quality gates run

- `npm ci`, `npm run check`, `npm run build`, `npm run audit:content`: passed. Build generated 58 pages; audit covered 57 Astro routes plus legacy redirects, canonicals, sitemap, internal links and commercial CTAs.
- `npm audit`: zero reported vulnerabilities after Astro/sitemap updates and a patched transitive `fast-uri` override.
- Private operations queue: `node --test tests/queue.test.mjs` passed. It verifies founder approval, no send before approval, a two-follow-up cap and stop after a negative reply.

## Configuration

Public values only. `.env.example` documents `PUBLIC_GA_ID`, `PUBLIC_PLAUSIBLE_DOMAIN`, `PUBLIC_CONTACT_ENDPOINT`, and `PUBLIC_BOOKING_URL`. The defaults currently point to the existing GA4, Formspree and Cal.com setup. Set an explicitly empty `PUBLIC_CONTACT_ENDPOINT` to use the email draft fallback; set an empty `PUBLIC_BOOKING_URL` to hide booking links. No secret is required in the website build. The private operations repo has an unused `HUBSPOT_PRIVATE_APP_TOKEN` placeholder for a future approved API integration; the current queue and CSV workflow require no token.

## Live checks before publishing

Read-only URL check on 8 November 2026: the Cal.com booking page returned HTTP 200. The Formspree endpoint returned HTTP 405 to GET and 400 to HEAD; it is a POST endpoint, so these requests do not verify submission or inbox delivery. No test inquiry or booking was sent.

1. Confirm the final public copy and fixed-quote approach, availability, and the written employer approval boundaries.
2. Send a test investigation and partner inquiry. Confirm Formspree dashboard entries and delivery to `hello@walstack.io`; check the selected offer, source page and UTM fields. Test invalid input and the accessible error path on a preview without load testing the live endpoint.
3. Open the Cal.com triage URL, confirm actual available slots and a confirmation email. No live booking was made by this implementation.
4. Consent to analytics on the production hostname and confirm CTA/form/booking events in GA4 DebugView or Plausible. Decline and verify GA4 stays unloaded. `qualified_lead` and `proposal_requested` belong to real CRM stages only; the website does not emit them.
5. Check the published sitemap/robots, all mapped Hashnode routes, Search Console coverage/404s and any indexed routes missing from `docs/MIGRATION_FROM_HASHNODE.md`.
6. Check phone navigation and keyboard form use on a deployed preview. Re-run Lighthouse there; the scores above are local only.
7. Agree client evidence transfer, retention/deletion and AI-processing terms before the first paid engagement.

## Rollback

The site remains on the existing Astro/static build and existing DNS/host configuration. Keep the current deployed commit as the rollback target. To revert this change, revert the commercial-launch commits in a new branch, run `npm ci`, `npm run build` and `npm run audit:content`, then redeploy the previous known-good site commit. No DNS or production integration setting is changed by this PR. The private operations repo is separate and its local `data/` directory is never committed.

## Next 14 days

1. Days 1–2: approve site copy; perform live form, booking, analytics and Search Console checks; deploy only after review.
2. Days 2–3: create HubSpot Free, map company/contact/task fields, and set the default deal pipeline for real opportunities. Keep speculative signals in the private queue.
3. Days 3–5: select 8–10 public partner/direct signals, verify original URLs/dates and contact channels, and write uncertainty for each. Reject hiring-only leads unless separate buying evidence exists.
4. Days 5–7: personally approve and send at most 4 highly contextual messages; ask 2 relevant partners about a scoped collaboration. No automated sending.
5. Days 8–10: classify replies and arrange discovery only where there is real interest. Quote one bounded investigation or upgrade review in writing after fit, with client-owned operations and evidence terms.
6. Days 11–14: send up to two appropriate manual follow-ups where no negative/opt-out response exists. Review replies, calls, proposals and lost reasons. Refine targeting before increasing volume.
