# Website measurement plan

Use the existing GA4 consent flow and Formspree form. Do not add a tracking vendor or a custom backend. GA4 counts describe observed site behavior; Formspree receipts and the owner's private CRM records establish later business outcomes.

## Event dictionary

| Event | Trigger | Useful parameters |
| --- | --- | --- |
| `primary_cta_click` | Click on a general primary service CTA | `source_page`, `offer`, campaign fields when present |
| `article_offer_click` | Click on a service link in an article offer position | `source_page`, `offer` |
| `service_page_view` | Load of Query Rescue or Database Code Review page | `service_id`, `source_page` |
| `service_cta_click` | Click on a focused service page CTA | `service_id`, `source_page` |
| `contact_start` | First focus in the enquiry form during a page visit | selected `service_id` when selected, `source_page` |
| `contact_submit` | Formspree responds successfully to an enquiry | selected offer/service, internal source path, and `referral_source` when present |
| `booking_click` | Click on the external booking link | `source_page` |
| `email_click` | Click on a `mailto:` link | `source_page` |
| `sample_report_click` | Click through to a synthetic sample report | `source_page` |
| `planreader_click` | Click through to PlanReader | `source_page` |

`contact_submit` means a successful Formspree response, not a qualified lead. A booking click is scheduling interest, not a confirmed call. Only the owner or CRM can confirm qualification, call completion, proposal and payment. The public email-draft fallback does not fire `contact_submit`.

## Data and privacy behavior

- GA4 loads only after analytics consent. If consent is declined, storage is unavailable, or analytics is blocked, the enquiry still works.
- First and latest UTM values plus the first and latest tagged landing path are kept in this tab's `sessionStorage`; the current internal path is recorded separately for referrer attribution. The values are optional hidden form fields.
- When the initial external referrer is PostgreSQL.org (including its subdomains), the tab stores only `referral_source=postgresql.org` and the first WalStack landing path. It does not store the directory URL path, query string, or visitor identity. These optional fields follow visitors across internal pages and can accompany a submitted enquiry.
- Never add names, email addresses, company or prospect identifiers, SQL, source-code diffs, free-text descriptions, credentials or technical evidence to analytics parameters.
- GA4 receives a query-free `page_location` and a query-free `page_referrer`; only the four recognized UTM fields are passed as campaign context. Validate GA4 Enhanced Measurement settings because independently configured outbound-click measurement may include a link URL.
- Campaign links must not contain personal identifiers. A shared UTM identifies a campaign destination, not an individual visitor.
- This implementation does not add HubSpot tracking. Existing contacts do not identify anonymous browsing by themselves.

## Attribution rules

Recognized campaign fields: `utm_source`, `utm_medium`, `utm_campaign`, and `utm_content`. Values are trimmed and capped in length. First-touch fields are written once per tab; latest fields update when a later tagged landing occurs. A clean internal navigation preserves both. A PostgreSQL.org referral is also stored for the tab and passed with the first WalStack landing path. A submitted form includes `from_page` when a service/article link opened contact, otherwise the last internal page may be available as `referring_page`.

Session storage is tab-scoped, can be blocked or cleared, and is not a durable user identity. Direct/organic visits without UTMs remain untagged. Do not infer organic source solely from a missing campaign. Reconcile Formspree submissions privately and preserve original and latest attribution separately in HubSpot only through an approved manual process.

## Local verification

1. Start a local preview with a mocked `https://www.postgresql.org/support/professional_support/asia/` referrer. Navigate through Query Rescue, Performance Investigation or Upgrade Readiness to `/contact`; confirm the contact form retains `referral_source=postgresql.org` and the original WalStack landing path.
2. Open a new tab with the example UTM link from [outreach attribution](../growth/OUTREACH_ATTRIBUTION.md); navigate through a service page to contact and confirm first and latest fields remain present.
3. Inspect the browser network panel with analytics declined. No GA request should be sent; form navigation remains usable.
4. With consent granted, use a mocked successful Formspree response and verify one `contact_submit`. Mock a non-2xx response and verify there is no submission event. Do not submit to the production endpoint.
5. Click a booking link and verify `booking_click` only; confirm it is not treated as a booked call.
6. Inspect GA4 event parameters and browser requests for accidental personal or query-string data. Do not use real customer details in fixtures.

## Recommended GA4 review

Use Traffic acquisition for session source/medium and campaign, and isolate `postgresql.org / referral` sessions where available. Use Landing page plus query string (or a query-free landing-path exploration) for page entry. Build an Exploration with event name, `service_id`, `source_page`, `from_page`, `referral_source` and campaign dimensions to review article/directory-to-service-to-form paths. Compare accepted `contact_submit` counts with Formspree receipts; consent and blocking create expected gaps. GA4 is not a CRM or revenue ledger.

## HubSpot reconciliation

Use the [outreach attribution procedure](../growth/OUTREACH_ATTRIBUTION.md): inspect a real received enquiry, find an existing contact by the submitted address, avoid duplicate creation, retain original campaign fields, record requested service, and update qualification/call/proposal/payment only when verified in the relevant private system. Keep outbound replies, solicitations, spam and website enquiry origin distinct. Zoho BCC email logging does not establish a website visit or link click.

## Known limitations

No live GA4, Search Console, Formspree or HubSpot property access was used to validate account-side settings. `sessionStorage` attribution is best-effort and tab-scoped. Consent, ad blockers, forwarded links, browser restrictions and independent GA4 settings can affect attribution. Sparse counts should be treated as provisional.
