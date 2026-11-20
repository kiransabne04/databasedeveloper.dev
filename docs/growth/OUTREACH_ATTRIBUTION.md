# Outreach attribution

Use one campaign link for everyone receiving the same manually approved message. Choose the destination that answers the buyer’s question. Tag the incoming link once. Keep subsequent WalStack links clean so navigating to a service or the enquiry form preserves how the visitor arrived.

## Campaign links

Use `utm_source=outbound` and `utm_medium=email` for prospecting and follow-up emails. Pick one lowercase campaign code from the table. Set `utm_content` to the linked destination’s approved code. Use the same spelling across the email, reporting and CRM. [Google Analytics campaign tagging](https://support.google.com/analytics/answer/10917952)

| Audience or decision | `utm_campaign` | Suggested destination | `utm_content` |
| --- | --- | --- | --- |
| Startup with one expensive statement | `startup-prospecting` | `/query-rescue` | `query-rescue` |
| Agency with a client release to review | `agency-partnerships` | `/database-code-review` or `/partners` | `database-code-review` or `partners` |
| SQL Server team with a workload regression | `sql-server-outreach` | `/sql-server-performance` | `sql-server-performance` |
| PostgreSQL team investigating latency | `postgres-performance` | `/query-rescue` or `/postgresql-performance-investigation` | `query-rescue` or `postgresql-performance-investigation` |
| Team preparing for a version change | `postgres-upgrade` | `/postgresql-upgrade-readiness` | `postgresql-upgrade-readiness` |
| Active conversation about the deliverable | `warm-follow-up` | `/sample-report` | `sample-report` |

For a PostgreSQL performance email that leads to Query Rescue, use this shared campaign link.

```text
https://walstack.io/query-rescue?utm_source=outbound&utm_medium=email&utm_campaign=postgres-performance&utm_content=query-rescue
```

Keep names, email addresses, company or contact identifiers, personalized tokens, free text and technical evidence out of URLs. Recipients can forward these links. A visit identifies activity associated with the campaign code, irrespective of who opened the link. When adding a campaign code, update the documented and accepted values together and test a round trip to the local form.

## What each signal establishes

| Signal | How to use it |
| --- | --- |
| Zoho message logged via HubSpot BCC | Evidence of a logged message. Manual BCC logging records email activity and can create recipient records. Open, link-click and website-visit tracking require separate capabilities. [HubSpot email logging](https://knowledge.hubspot.com/connected-email/log-email-in-your-crm-with-the-bcc-or-forwarding-address) |
| Tagged website session | Aggregate visits and destinations for a shared campaign, subject to consent, blocking, forwarding and automated visits. Compare session campaign and landing page. |
| Anonymous page or CTA event | Evidence that a page was viewed or a link activated. Use for navigation analysis. |
| Successful form submission | The sender supplied contact details and a description to Formspree. Review the actual submission and source fields in the approved private workspace. An analytics event alone cannot identify the sender. |
| Reply, booking click or email draft | A reply belongs to the email conversation. A booking link shows scheduling interest. Verify the calendar booking or received enquiry before recording the corresponding outcome. |
| Qualified buyer interest | The owner confirms a real project, a fitting service and an agreed next step. Record the outcome against that opportunity. |

HubSpot can associate browsing with a contact when its tracking code, permitted cookies and a qualifying identity event are present. Existing HubSpot contacts alone do not establish a website visitor’s identity. Any proposal to add tracking needs separate owner approval and a review of consent and privacy language. [HubSpot visitor association](https://knowledge.hubspot.com/account/how-does-hubspot-track-visitors)

## Reconcile an identified enquiry

| Submission field | Private enquiry record |
| --- | --- |
| `offer` | Requested service. Keep `query-rescue` and `database-code-review` distinct. |
| `landing_page`, `first_utm_source`, `first_utm_medium`, `first_utm_campaign`, `first_utm_content` | First observed landing context. Keep the original values even when later links carry different tags. |
| `utm_source`, `utm_medium`, `utm_campaign`, `utm_content` | Latest recorded campaign context for this visit. Store alongside the original fields. |
| `from_page` | Internal page associated with opening the form. Use it to identify the article or service that led to intake. |

1. Open the accepted submission in the approved inbox or Formspree workspace. Classify the inbound item as a buyer enquiry, partner enquiry, unrelated solicitation or spam. Keep outreach replies as a separate origin. Exclude internal tests and solicitations from buyer counts.
2. Look up the submitted work email in HubSpot, including known secondary addresses. If there is a clear match, associate the enquiry with the existing contact. Check ambiguous aliases manually. Only create a new contact through an approved process when the sender is distinct. Avoid matching on an anonymous URL visit or company domain alone. [HubSpot deduplication](https://knowledge.hubspot.com/records/deduplication-of-records)
3. For a real submission, record its receipt time, requested offer, landing page, source page, and first and latest campaign fields together on the enquiry activity or relevant opportunity. Treat the original recorded campaign on that enquiry as immutable. Keep the latest touch in separate fields and retain unknowns. A returning contact can have multiple enquiries with different sources. Preserve HubSpot’s native original traffic-source history.
4. Keep the submitted offer as the intake value. Record a separately scoped service on the opportunity if the fit review changes it. If native fields or an approved mapping are unavailable, a structured private activity note suffices. A contact or company alone need not open a deal.
5. Use a provider submission reference where available to recognize a redelivery. Otherwise compare the private receipt time, sender, offer and message before logging a duplicate. Update the same opportunity as the owner confirms qualification, meeting, proposal and payment. Store only aggregate counts in shared scorecards.

See the [measurement plan](../analytics/MEASUREMENT_PLAN.md) for the form field dictionary and local checks, and the [28-day scorecard](SEO_REVIEW_SCORECARD.md) for reporting.
