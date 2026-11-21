# 28-day acquisition review

Use this worksheet to answer two questions. Which routes led to a qualified enquiry or paid investigation? Which step in a promising route needs attention next?

## Set the window

Use the most recent 28 complete days shared by the sources and compare with the immediately preceding 28 days. Write down both date ranges, the extraction date, the production release date and each source’s time zone. Search Console daily reports use Pacific Time. Record the configured GA4 and CRM time zones explicitly. Mark unavailable fields **unavailable** and unconfigured metrics **unmeasured**. Enter zero only after checking a source. [Search Console reporting differences](https://support.google.com/webmasters/answer/17010575?hl=en)

Keep the working copy in the approved private workspace. This repository contains the blank worksheet. Enter aggregate values only, and keep customer names, messages and payment records in their existing private systems.

| Metric | Current 28 days | Previous 28 days | Source or evidence to record |
| --- | --- | --- | --- |
| Google clicks and impressions on walstack.io | | | Search Console domain property, Web search, unfiltered total |
| Google clicks and impressions on databasedeveloper.dev | | | Historical domain property, same dates and filters, when accessible |
| Commercial query clicks and impressions | | | Group terms into one-query diagnosis, code/migration review, performance investigation, upgrade readiness and SQL Server. Retain the filters used. |
| Commercial service-page visibility | | | Clicks, impressions and average position for each canonical service URL |
| Priority guide visibility | | | Per-page clicks/impressions plus position for the same relevant query and page across windows |
| Migration and indexing issues | | | Sample both domains, representative old redirects, chosen canonicals and sitemap/indexing status of new services |
| Landing-page sessions | | | GA4 session counts by landing path and session source/medium or campaign |
| PostgreSQL.org directory referral sessions | | | GA4 sessions with PostgreSQL.org as the session referrer/source; visits are traffic, not leads |
| Service views and article-to-service journeys | | | Service views by offer, internal referrer and original landing page. Inspect article offer clicks separately. |
| CTA clicks, form starts and accepted submissions | | | GA4 event counts by offer and landing page. Reconcile accepted forms with Formspree. |
| Session enquiry rate by landing page | | | Sessions with at least one accepted submission divided by observed sessions landing on that path. Include both counts. |
| Qualified organic enquiries | | | Distinct owner-qualified buyer enquiries with supported organic origin |
| Qualified outreach-sourced enquiries | | | Distinct owner-qualified buyer enquiries with supported outreach origin |
| Qualified PostgreSQL.org-referred enquiries | | | Distinct owner-qualified buyer enquiries where the submitted/CRM referral source is `postgresql.org`; reconcile the enquiry, do not count directory visits or CTA clicks |
| Qualified enquiries from other or unknown sources | | | Retain unattributed opportunities and conflicting evidence for manual review |
| Discovery calls confirmed | | | CRM or calendar-confirmed bookings, using confirmation date and excluding canceled/rescheduled duplicates |
| Proposals submitted | | | Distinct opportunities receiving a written proposal during the period |
| Paid investigations and other paid engagements | | | Distinct engagements with verified first payment during the period, broken out by offer |
| Revenue received | | | Sum receipts net of refunds in the period. Record currency and use separate rows for different currencies. |

### Read the numbers

1. Start with the CRM and receipts. Group qualified enquiries and paid engagements by requested service and acquisition source. Say which evidence supports the source. Preserve the first known source and record later influences separately. Count each opportunity once per stage.
2. Compare campaign-attributed GA4 sessions against identified Formspree submissions in aggregate. Consent, unavailable storage and missing tags reduce coverage. GA4’s session source/medium uses its own session rules. A later tag in the same browser tab may appear on the form under latest touch. [GA4 traffic acquisition](https://support.google.com/analytics/answer/12923437)
3. Follow a plausible route through article, service and form. Inspect each step independently. Check form errors, mobile CTA behavior and whether the destination addresses the article’s buyer decision. Count the canonical form success event once. Consult the [measurement plan](../analytics/MEASUREMENT_PLAN.md) for event names and historical reporting boundaries.
4. Compare search signals against the [commercial content map](../seo/COMMERCIAL_CONTENT_MAP.md). Track the legacy property alongside WalStack and inspect an old URL when discovery shifts between domains. Filtered query totals can omit anonymized queries. Distinguish a change in query mix from a change in position for the same query. [Search Console filters](https://support.google.com/webmasters/answer/17011165?hl=en)
5. Keep period activity and acquisition cohorts distinct. A proposal or payment this month may come from an enquiry received in a previous window. For enquiry-to-paid conversion, follow the same set of enquiries over time and report the number still open.

For sparse pages, report observations as counts and label conclusions provisional. A zero denominator leaves a rate undefined. When different measurement setups straddle a period, annotate the break and compare only the available like-for-like data.

### Choose the next action

| Candidate action and URL | Buyer decision and commercial value | Demand evidence | Observed conversion problem | Founder effort | Confidence and missing evidence | Decision for next 28 days |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

Prefer a small change that can help a buyer complete an observed next step. Record the expected behavior, owner, evidence that would change the decision, and the next review date. A justified outcome can be to leave a page alone until more evidence arrives.
