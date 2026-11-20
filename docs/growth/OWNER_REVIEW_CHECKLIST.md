# Owner review before production

Review the draft PR and the locally built pages together. Record commercial decisions and remaining blockers on the PR. A completed technical check is separate from approval to release.

## What the buyer can purchase

- [ ] **Query Rescue.** Confirm one PostgreSQL or SQL Server statement and its directly relevant context fit the pilot. Check the written deliverable, evidence limitations, exclusions, and escalation when multiple statements are involved.
- [ ] **Database Code Review.** Confirm one bounded database PR or change set, the evidence needed, the prioritized findings and validation checks. Agree how to handle additional revisions and requests that require production evidence.
- [ ] **Homepage.** Review the hero, first CTA, proof link and focused-review cards on a phone and desktop. Verify that a SaaS engineering lead can choose between one query, one proposed change, cluster performance and a major upgrade.
- [ ] **Pricing and capacity.** Confirm quote-after-fit wording and that timing and scope are agreed before work begins. Review the offers against the founder’s available hours.

## Enquiry and measurement

- [ ] **CTA routing.** Follow one diagnostic article into each focused service, then open contact. Check the requested offer and origin on both journeys. Verify an agency can find Database Code Review from the partnerships page.
- [ ] **Contact form.** Use the local mock flow to test required fields, change the offer, exercise failure and retry, and check successful acceptance. Ensure the form asks for a sanitized description and keeps sensitive code and credentials out of intake.
- [ ] **Privacy.** Review the disclosure for campaign context, analytics consent and the form processor. Try declining analytics and disabling browser storage. Confirm the enquiry remains usable. Check event payloads and campaign links for identifying data.
- [ ] **Analytics.** Confirm the intended GA4 property, measurement configuration, dimensions and single enquiry-success event in the [measurement plan](../analytics/MEASUREMENT_PLAN.md). Keep booking interest separate from a confirmed meeting. Review any existing campaign codes outside the [outreach conventions](OUTREACH_ATTRIBUTION.md) before using them.
- [ ] **CRM handoff.** Identify who reconciles accepted forms, matches existing contacts, filters solicitations and records confirmed stages. Approve any new integration or vendor separately.

## Publication decision

- [ ] **SEO and proof.** Check the four offers, retained PostgreSQL-specific routes, canonical URLs, sitemap, article/service markup, internal links and old-domain redirects. Review EOL wording against upstream support calendars. Verify that examples are labeled and founder claims have a public basis.
- [ ] **Release checks.** Read the PR test results and before/after previews, confirm the proposed source revision, and review the rollback steps. List any configurations that need a separate decision.
- [ ] **Production deployment approval.** Record an explicit owner decision on the PR when ready. After an approved release, verify clean route responses, canonical tags and the form destination, then start the [28-day review](SEO_REVIEW_SCORECARD.md) from the recorded release date.
