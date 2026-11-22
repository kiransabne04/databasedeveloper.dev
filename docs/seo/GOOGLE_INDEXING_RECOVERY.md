# Google indexing and domain-migration recovery

Owner runbook for moving search visibility from `databasedeveloper.dev` to `walstack.io`. The live HTTP checks below were run on 22 November 2026 with `curl` from India (Vercel `bom1` edge). No Search Console action has been taken by an agent. Every Search Console step below is for the owner.

Submitting a sitemap, requesting indexing or filing a Change of Address helps Google discover and process URLs. None of them guarantees indexing or ranking. Google's guide: [Site moves with URL changes](https://developers.google.com/search/docs/crawling-indexing/site-move-with-url-changes).

## 1. What the live checks found

| Check | Result on 22 Nov 2026 | Status |
| --- | --- | --- |
| `https://databasedeveloper.dev/` and `https://www.databasedeveloper.dev/` | 301 to `https://walstack.io/` in one hop | OK |
| `http://` variants of the old domain | 308 to `https://` on the same host, then 301 to walstack.io (two hops). Vercel adds the HTTPS step before `vercel.json` rules run. | Acceptable. Google follows short chains. |
| `https://www.walstack.io/` | 308 to `https://walstack.io/` | OK |
| `http://walstack.io/` | 308 to HTTPS | OK |
| All 54 routes in `scripts/required-routes.json` on the old domain | Each 301 to the same path on walstack.io in one hop, final 200 | OK |
| `/sitemap.xml`, `/archive`, `/members`, `/recommendations`, interview pointer on the old domain | Two hops (old domain, then walstack.io, then destination) | **Fixed in this branch** with host-specific one-hop 301s |
| `https://walstack.io/postgresql-performance-investigation/` (trailing slash) | 200, duplicate of the slash-less URL. Its canonical points to the slash-less URL. | **Fixed in this branch** with `trailingSlash: false` (308 to the slash-less URL) |
| Canonicals | Self-referencing, slash-less, on `https://walstack.io` | OK |
| `robots.txt` | `Allow: /` and `Sitemap: https://walstack.io/sitemap-index.xml` | OK |
| Sitemap | `sitemap-index.xml` lists `sitemap-0.xml` with 64 URLs. It excludes `/snapshot/thank-you` and the two noindex alias pages. | OK |
| `/snapshot/thank-you` | `noindex,nofollow`, not in the sitemap | OK |
| Production build | Live homepage H1 and snapshot form match `main` at `f94b72a` | Deployed |

No noindex or robots block was found on a commercial page. The "crawled, not indexed" states in Search Console are not explained by a technical block.

## 2. Important old URLs

The old domain served Hashnode articles first, then this Astro site, before the move to walstack.io. Every path below was requested on `https://databasedeveloper.dev`.

| Old URL path | Live behaviour (22 Nov) | Destination | Canonical at destination | Action |
| --- | --- | --- | --- | --- |
| `/postgresql-concurrency-and-locking-a-comprehensive-guide` | 301, one hop | Same path on walstack.io | Self | Keep. Highest historical impressions. |
| `/sharding-postgresql-techniques-for-horizontal-scalability` | 301, one hop (www too) | Same path | Self | Keep. In-article investigation offer added. |
| `/how-to-scale-postgresql-databases-with-partitioning` | 301, one hop | Same path | Self | Keep |
| `/mastering-clustering-in-postgresql-for-enhanced-query-performance` | 301, one hop | Same path | Self | Keep |
| `/postgresql-indexing-when-brin-beats-b-tree` | 301, one hop | Same path | Self | Keep |
| `/building-a-semantic-similarity-search-api-with-fastapi-sentence-bert-and-postgresql-pgvector` | 301, one hop | Same path | Self | Keep |
| `/mastering-mongodb-locking-concurrency-and-performance-optimization-a-deep-dive` | 301, one hop | Same path | Self | Keep (archive) |
| `/insights/pg-upgrade-check-failures` | 301, one hop | Same path | Self | Keep |
| `/insights/postgresql-slow-after-major-upgrade` | 301, one hop | Same path | Self | Keep. Most historical clicks. |
| `/postgresql-14-eol` | 301, one hop | Same path | Self | Keep |
| `/insights/rds-aurora-postgresql-14-extended-support-cost` | 301, one hop | Same path | Self | Keep |
| `/insights/postgresql-slow-queries-pg-stat-statements` | 301, one hop | Same path | Self | Keep |
| `/crack-sql-interviews-with-these-postgresql-internals-and-real-questions` | 301 then 308 (two hops) | kiransabne.dev full article | On kiransabne.dev | One hop after this branch deploys |
| `/archive`, `/members`, `/recommendations` | Two hops | `/insights` | Self | One hop after this branch deploys |
| `/sitemap.xml` | Two hops | `/sitemap-index.xml` | n/a | One hop after this branch deploys |

No slug was changed. No historical article redirects to an unrelated page.

## 3. Owner steps in Search Console

### 3.1 Confirm both properties

1. Open [Search Console](https://search.google.com/search-console). Confirm you are a verified owner of both `walstack.io` and `databasedeveloper.dev`, preferably as Domain properties. The Change of Address tool needs owner access to both. [Change of Address tool](https://support.google.com/webmasters/answer/9370220)
2. If `databasedeveloper.dev` is not verified as a Domain property, add the DNS TXT record from Search Console at the old domain's registrar. Keep that record in place permanently.

### 3.2 Check or file the Change of Address

1. In the `databasedeveloper.dev` property, open **Settings → Change of address**.
2. If it says a move to `walstack.io` is already in progress, record the date in the scorecard and do nothing else.
3. If not, select `walstack.io`. The tool checks that the homepage and a sample of URLs 301 to the new site. Submit only after it passes.
4. Keep the old domain registered and the redirects in place indefinitely. Google's site-move guide says to keep redirects as long as possible, generally at least a year.

An agent cannot see or file this. The current state is **unknown**.

### 3.3 Check redirects yourself

```bash
for u in https://databasedeveloper.dev/ https://www.databasedeveloper.dev/postgresql-concurrency-and-locking-a-comprehensive-guide https://databasedeveloper.dev/sitemap.xml https://walstack.io/pricing/; do
  curl -s -o /dev/null -L -w "%{http_code} hops=%{num_redirects} %{url_effective}\n" "$u"
done
```

Each line should end on `200` at `https://walstack.io/...` with `hops=1`. After this branch deploys, `sitemap.xml` and `/pricing/` should also show one hop.

### 3.4 Sitemap

1. In the `walstack.io` property, open **Sitemaps**. Confirm `https://walstack.io/sitemap-index.xml` is listed with status **Success** and a recent "Last read" date. If not, submit it.
2. Do not submit a walstack.io sitemap in the old property. The old property keeps no sitemap. Google finds the redirects by recrawling old URLs.

### 3.5 Inspect the service pages

Run **URL Inspection** on each page and record the coverage state, the Google-selected canonical and the last crawl date:

`/`, `/postgresql-performance-investigation`, `/postgresql-upgrade-readiness`, `/query-rescue`, `/database-code-review`, `/sql-server-performance`, `/pricing`, `/snapshot`, `/partners`.

Then click **Test live URL**. It should report "URL is available to Google" and show the self canonical. If the Google-selected canonical is a different URL, record that URL. It is the most useful signal for diagnosing duplication.

### 3.6 Request indexing selectively

Request indexing for a page only after its content has changed and the change is deployed. In this branch that applies to `/postgresql-upgrade-readiness`, `/partners`, `/query-rescue`, `/sql-server-performance` and `/postgresql-performance-investigation`. Request each one once. Repeating a request does not speed it up, and the tool has a daily quota.

### 3.7 Reading the coverage states

| State | Meaning | What to do |
| --- | --- | --- |
| Discovered, currently not indexed | Google knows the URL but has not crawled it yet. This is common for new URLs on a new domain. | Wait. Add internal links from pages that already get impressions. |
| Crawled, currently not indexed | Google fetched the page and decided not to index it for now. That is a judgement about value or duplication, not a technical error. | Make the page clearly distinct from the homepage and its siblings. Add internal links from indexed guides. Request indexing again after a real change. |
| Duplicate, Google chose different canonical | Google treats the page as a copy of another URL | Compare the two pages and make the intent of each distinct |
| Excluded by noindex | Intended only for `/snapshot/thank-you`, `/postgresql-query-rescue` and `/postgresql-pr-review` | Investigate any other page in this state |
| Page with redirect | Expected for every old-domain URL and for slash variants | No action |
| Not found (404) / Server error (5xx) | A genuine error | Fix and validate |

The investigation, upgrade, SQL Server and pricing pages were "crawled, not indexed" in the stored inspections. These pages are a few weeks old on a domain with little history, and they overlap the homepage, which repeats the investigation offer and price. Expect them to take weeks. The useful levers are distinct content (done for upgrade and partners), links from the indexed historical guides (already present in each guide's header and closing panel) and patience.

### 3.8 Monitor the migration

Every 28 days, record in [the scorecard](../growth/SEO_REVIEW_SCORECARD.md):

- Impressions and clicks for each property over the same dates. Expect the old property to fall as the new one rises. Both falling together is the warning sign.
- For the five historical pages with the most impressions, whether the old-domain URL still appears in Performance and whether the walstack.io URL has started to.
- The indexed count in **Pages** for walstack.io, and how many sitemap URLs are indexed.
- Whether the Google-selected canonical has changed for the inspected service pages.

### 3.9 Real errors versus normal delay

Treat these as real problems: a 4xx or 5xx on a sitemap URL, a redirect that lands on a different topic or on the homepage, a Google-selected canonical on the old domain more than about 8 weeks after the Change of Address, "Blocked by robots.txt", or an unexpected noindex. Treat these as normal for a migration under 3 months old: "Discovered, not indexed", "Crawled, not indexed" on new service pages, slow transfer of impressions, and old URLs still appearing in the old property's report.

## 4. Brand query "walstack"

A US search for "walstack" was dominated by WallStack wallpaper products. Google can only tie the brand to this site if the name appears consistently. This branch adds the `WebSite` structured data (`name: WalStack`, `alternateName: walstack.io`) that Google reads for [site names](https://developers.google.com/search/docs/appearance/site-names), adds `og:site_name`, and puts WalStack in the homepage eyebrow. The PostgreSQL.org listing uses the name "WAL Stack Labs". Aligning it with "WalStack" is an owner decision, tracked in the local owner checklist.
