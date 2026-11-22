# 28-day acquisition review

Use this worksheet to answer two questions. Which routes led to a qualified enquiry or paid investigation? Which step in a promising route needs attention next?

## Set the window

Use the most recent 28 complete days shared by the sources and compare with the immediately preceding 28 days. Write down both date ranges, the extraction date, the production release date and each source’s time zone. Search Console daily reports use Pacific Time. Record the Plausible and CRM time zones explicitly. Mark unavailable fields **unavailable** and unconfigured metrics **unmeasured**. Enter zero only after checking a source. [Search Console reporting differences](https://support.google.com/webmasters/answer/17010575?hl=en)

Keep the working copy in the approved private workspace. This repository contains the blank worksheet. Enter aggregate values only, and keep customer names, messages and payment records in their existing private systems.

Since 22 November 2026 the site uses Plausible, not GA4. Plausible counts visits and custom events without cookies. Rows that used to cite GA4 now cite Plausible.

### Baseline (pre-rewrite)

Recorded on 22 Nov 2026 from owner-supplied Search Console figures. This window ends before the conversion rewrite was deployed, so it is a baseline only. It is not evidence for or against the new design.

| Window | Property | Impressions (page-grouped) | Clicks | Notes |
| --- | --- | --- | --- | --- |
| 23 Oct to 19 Nov 2026 | walstack.io | 160 | 2 | Mostly informational queries. Little service exposure. |
| 23 Oct to 19 Nov 2026 | databasedeveloper.dev | 5,430 | 34 | Locking, sharding, pg_upgrade failures, slow after upgrade, RDS/Aurora deadlines |

Indexing at baseline (stored URL Inspection): `/` indexed. Investigation, upgrade, SQL Server and pricing crawled, not indexed. Snapshot, Query Rescue and code review unknown. Website and pipeline baseline: **unmeasured** (Plausible goals not confirmed, no logged enquiries).

### Worksheet

| Group | Metric | Current 28 days | Previous 28 days | Source or evidence to record |
| --- | --- | --- | --- | --- |
| Search | Clicks and impressions, walstack.io | | | Search Console domain property, Web, unfiltered |
| Search | Clicks and impressions, databasedeveloper.dev | | | Old property, same dates. It should fall as walstack.io rises. |
| Search | Buyer-intent queries (clicks/impressions) | | | Queries containing consultant, consulting, service, review, readiness, assessment, hire. Keep the filter text. |
| Search | Informational queries (clicks/impressions) | | | Everything else, excluding branded |
| Search | Branded queries | | | Queries containing "walstack" or "wal stack". Note how many are WallStack wallpaper noise. |
| Search | Service pages indexed | / 9 | / 9 | URL Inspection for the nine pages in GOOGLE_INDEXING_RECOVERY.md §3.5 |
| Search | Google-selected canonical changes | | | Any inspected page whose Google canonical is not itself |
| Search | Referrals: PostgreSQL.org, PlanReader | | | Plausible Sources. These are visits, not leads. |
| Website | Service landing-page visits | | | Plausible pages: investigation, upgrade, Query Rescue, code review, SQL Server, partners |
| Website | `/snapshot` visits | | | Plausible goal `snapshot_page_view` |
| Website | Script downloads | | | Goal `script_download` (a click, not proof the script ran) |
| Website | Accepted snapshot submissions | | | Formspree entries with files. Reconcile with goal `snapshot_submitted`. |
| Website | Qualified snapshot requests | | | Owner judgement: usable output and a production PostgreSQL company |
| Website | Service-specific enquiries | | | Formspree contact entries by `offer` and `from_page` |
| Website | Booking clicks | | | Goal `book_call_click`. A click is not a booking. |
| Website | Confirmed bookings | | | Cal.com, excluding cancellations and duplicates |
| Pipeline | Qualified conversations | | | Calls or email threads where scope was discussed |
| Pipeline | Proposals sent | | | Written proposals with price |
| Pipeline | Paid investigations / other paid work | | | First payment verified, by offer |
| Pipeline | Revenue received | | | Receipts net of refunds, per currency. Verified only. |

### Read the numbers

1. Start with the CRM and receipts. Group qualified enquiries and paid engagements by requested service and acquisition source. Say which evidence supports the source. Preserve the first known source and record later influences separately. Count each opportunity once per stage.
2. Compare campaign-attributed Plausible visits against identified Formspree submissions in aggregate. Ad blockers, unavailable storage and missing tags reduce coverage. A later tag in the same browser tab may appear on the form under latest touch.
3. Follow a plausible route through article, service and form. Inspect each step independently. Check form errors, mobile CTA behavior and whether the destination addresses the article’s buyer decision. Count the canonical form success event once. Consult the [measurement plan](../analytics/MEASUREMENT_PLAN.md) for event names and historical reporting boundaries.
4. Compare search signals against the [commercial content map](../seo/COMMERCIAL_CONTENT_MAP.md). Track the legacy property alongside WalStack and inspect an old URL when discovery shifts between domains. Filtered query totals can omit anonymized queries. Distinguish a change in query mix from a change in position for the same query. [Search Console filters](https://support.google.com/webmasters/answer/17011165?hl=en)
5. Keep period activity and acquisition cohorts distinct. A proposal or payment this month may come from an enquiry received in a previous window. For enquiry-to-paid conversion, follow the same set of enquiries over time and report the number still open.

For sparse pages, report observations as counts and label conclusions provisional. A zero denominator leaves a rate undefined. When different measurement setups straddle a period, annotate the break and compare only the available like-for-like data.

### Choose the next action

| Candidate action and URL | Buyer decision and commercial value | Demand evidence | Observed conversion problem | Founder effort | Confidence and missing evidence | Decision for next 28 days |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

Prefer a small change that can help a buyer complete an observed next step. Record the expected behavior, owner, evidence that would change the decision, and the next review date. A justified outcome can be to leave a page alone until more evidence arrives.
