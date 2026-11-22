# WalStack 30-day conversion test

Start the 30 days when the public snapshot script, upload delivery and booking calendar work on the live domain. Record the start date. Use accepted snapshot requests and confirmed Cal.com bookings as the two outcomes.

## Setup

- The Astro build reads the public variables in `.env.example`. The snapshot form posts multipart data directly to Formspree. Set `PUBLIC_SNAPSHOT_ENDPOINT` for a separate upload-enabled form, or use the existing contact endpoint. Keep private account credentials outside the repository.
- File uploads require a Formspree plan that supports them. Confirm the destination inbox, attachment storage, billing capacity and access permissions. The browser requires one text file, allows a second, and allows one PNG/JPEG. Each file must be nonempty and at most 5,000,000 bytes. These are browser validations. Formspree applies its own service limits to direct submissions. [Formspree upload documentation](https://help.formspree.io/articles/building-your-form/file-uploads)
- On the hosted preview, send an authorized submission using harmless test files. Open both text files and the screenshot from the Formspree submission. Confirm the UTM fields, receipt page and delivery. Delete the test submission, files and downloaded copies. Repeat this deletion for real snapshots at 30 days unless an engagement changes the terms.
- The snapshot SQL is in `public/snapshot/walstack-snapshot.sql`. Vercel serves it as a plain-text attachment. Verify the download on the hosted preview.
- Add Kiran’s approved portrait as `public/images/kiran-sabne.webp` and rebuild. The hero and About page will use the same file. Use a square crop for display.
- The booking default is Kiran’s [15-minute event](https://cal.com/kiransabne13/15min). Confirm available slots and remove any production `PUBLIC_BOOKING_URL` override pointing to the old triage call.
- In Plausible, add walstack.io, copy the site script URL into `PUBLIC_PLAUSIBLE_SCRIPT_URL` and register the six custom event goals below with exactly these names. Use the installation check and live dashboard on the production domain. The shared layout loads the script on production hostnames. Keep automatic form, file and outbound-link goals off if you only want the explicit goals. [Plausible installation](https://plausible.io/docs/script-update-guide) · [Custom goals](https://plausible.io/docs/custom-event-goals)
- The WalStack domain property is owner-verified in Google Search Console. In its Sitemaps report, confirm or submit `https://walstack.io/sitemap-index.xml`. The connected property listing does not expose sitemap receipts. The new receipt page is excluded from indexing.

## Events

| Event | Observation |
| --- | --- |
| snapshot_page_view | Visit to /snapshot |
| script_download | Click on the actual snapshot SQL download |
| snapshot_submitted | Formspree accepted the multipart request. Visiting or refreshing the receipt URL adds no submission. |
| book_call_click | Click on Kiran’s scheduling link, including the upgrade and partner buttons |
| sample_report_view | Visit to /sample-report |
| pricing_view | Visit to /pricing |

## Channel attribution

Use a link such as `https://walstack.io/?utm_source=intro&utm_medium=referral&utm_campaign=30day`. Use `upwork`, `reddit`, `slack`, `hn`, `email`, `intro`, `agency` or `linkedin` for the source. Keep campaign values URL-safe using letters, numbers, underscores and hyphens.

Tagged visits retain first and latest campaign fields in this browser tab. The snapshot form includes source, medium, campaign, content, term and landing paths. Local storage restrictions can limit attribution across pages. Analytics receives campaign context and page paths. Form answers, names, email addresses and file contents go only to the intake handler.

At day 30, compare visits, download clicks, accepted snapshots and booking clicks by source. Confirm actual bookings in Cal.com and unique, usable submissions in Formspree. Record repeat requests and cancellations separately. Leave a channel unassigned if no reliable source is available.
