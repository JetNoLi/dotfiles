# SA Event Aggregator: Technical and Legal Feasibility (as of Oct 2026)

Method note: Besides web research, I ran direct HTTP probes (curl, desktop Chrome user-agent, from a residential connection, 19–20 Oct 2026). These checked robots.txt, the HTTP status, whether schema.org JSON-LD is present, and whether there were Cloudflare challenges on each platform. Findings labelled "Direct probe" come from those requests. They are a point-in-time snapshot and were not repeated at scale. Where no source URL is given, the claim comes from the direct probe.

## 1. Per-source data acquisition: official APIs, feeds, structured markup

### Takeaway
None of the SA ticketing platforms offers a public, cross-organiser event-search API. Eventbrite removed theirs in 2020, the Luma and Meetup APIs only cover calendars and groups you own or manage, and the Quicket API needs a key and appears to be organiser-oriented. However, several platforms embed schema.org `Event` JSON-LD in server-rendered HTML: Quicket, Ticketpro and Luma were confirmed by probe. That makes cheap, robust structured extraction possible for those three. Howler, Computicket and Webtickets are JS-rendered or have no JSON-LD, so they need headless rendering or reverse-engineered XHR/JSON endpoints. Resident Advisor's pages sit behind Cloudflare (403 to curl), but its `/graphql` endpoint answered an unauthenticated request.

### Cited Findings
**Quicket** (Ticketmaster/Live Nation-owned since July 2024)
- Ticketmaster announced its acquisition of Quicket on 24 July 2024. Quicket runs as a standalone unit under MD James Tagg and is expanding into Nigeria, Uganda, Kenya, Zambia and Botswana. — [Live Nation press release](https://www.livenationentertainment.com/2024/07/ticketmaster-expands-presence-in-africa-with-acquisition-of-quicket); [News24](https://www.news24.com/business/companies/ticketmaster-the-worlds-largest-ticketing-group-buys-sas-quicket-20240724)
- Quicket has a developer portal where you register for an API key ("To get started testing the API, you'll need an API key"), with docs at docs.quicket.com. The landing page does not list endpoints, eligibility or rate limits, and the docs site is a JS app whose content could not be retrieved. — [Quicket Developer Portal](https://developer.quicket.co.za/)
- Direct probe: `https://www.quicket.co.za/events/` returns HTTP 200 and server-rendered HTML containing a `<script type="application/ld+json">` array of schema.org `Event` objects. These carry `name`, `startDate`/`endDate` (ISO 8601 UTC), `image`, `location` (Place with PostalAddress: street, locality, postal code, region, country), `url` (e.g. `https://www.quicket.co.za/events/398445-jpo-spring-season-2026/`), `eventAttendanceMode` and `offers`. Listing pages paginate (`/events/south-africa/2/`).
- Direct probe: Quicket's robots.txt is about 413 lines. It is mostly a blocklist of named bots (SemrushBot, PetalBot, Python-urllib, etc.). The probe did not find a wildcard `User-agent: *` disallow on `/events/`. Note that the `Python-urllib` UA is explicitly blocked, so crawlers should identify themselves with a custom UA.

**Howler** (Johannesburg, founded 2016)
- Direct probe: `https://www.howler.co.za/events` returns 200, but it is a Vite-built SPA shell (assets on CloudFront) with no JSON-LD and no event links in the HTML. `/sitemap.xml` returned no usable content. Data has to come from the JSON endpoints the SPA calls (discover them with browser devtools or Playwright network capture) or from rendered DOM. Organiser pages exist at `/organisers/{id}`.
- No public Howler developer API was found. The organisers portal is at organisers.howler.co.za.

**Computicket** (Shoprite Holdings; "the largest ticketing service provider in South Africa") — [Shoprite Holdings](https://www.shoprite.co.za/group/brands/computicket.html) (URL as returned by search: shopriteholdings.co.za)
- Direct probe: robots.txt is `User-agent: *` with only a `Sitemap: https://computicket.com/sitemap.xml` line, so no disallows. The sitemap lists top-level pages (home, /event, travel bus/flight), regenerated daily. In the sample read, individual event URLs were not visible in the first entries.
- Direct probe: `/event` HTML (105 KB) has no JSON-LD. It is an SPA that references `computicket.com/event/list` routes, so data is loaded client-side. A headless browser or XHR endpoint capture is needed.

**Webtickets** (Pick n Pay-linked, ASP.NET)
- Direct probe: the root redirects (302) to `/v2/`. robots.txt disallows only `/eventmanager/` paths. Event pages follow `event.aspx?itemid={id}` (e.g. itemid=1531472391 is "Cape Town Abseil"). They are server-rendered and include OpenGraph `og:title`/`og:description`, but no JSON-LD. Plain HTML parsing or LLM extraction works.

**Ticketpro**
- Direct probe: the `www.ticketpro.co.za` homepage (538 KB) links to `/events/{slug}/redirect`, which 302s to `shop.ticketpro.co.za/event/{slug}-{id}`. The shop event page includes schema.org `Event` JSON-LD with location (Place + PostalAddress), name, and offers (price, e.g. 70).
- Direct probe: Ticketpro's robots.txt uses Cloudflare's "Content-Signal" (`search=yes,ai-train=no,use=reference`). It blocks AI training crawlers (GPTBot, ClaudeBot, CCBot, Google-Extended, Bytespider, Amazonbot, Applebot-Extended, Diffbot, etc.), which signals Cloudflare-managed bot policy. An aggregator is "reference/search" use, not training. That is a relevant distinction, but it is not a licence.

**Eventbrite**
- Public event search (`GET /v3/events/search/`) was closed: Eventbrite announced in December 2019 that requests would be denied after 20 Feb 2020. The remaining API covers single events by ID, events by venue (`/v3/venues/:id/events/`) and events by organisation (`/v3/organizations/:id/events/`). — [Rollout API essentials](https://rollout.com/integration-guides/eventbrite/api-essentials); [Automattic eventbrite-api issue #83](https://github.com/Automattic/eventbrite-api/issues/83); [Make community thread](https://community.make.com/t/eventbrite-api-depreciated/80369)
- Third-party Apify actors scrape Eventbrite's logged-out search, "reading the same search the website uses". — [Apify: Eventbrite Events Intel](https://apify.com/seibs.co/eventbrite-events-intel); [Apify: Eventbrite Scraper](https://apify.com/datascoutlab/eventbrite-scraper)
- Direct probe: `eventbrite.co.za/d/south-africa--cape-town/events/` returned 242 KB with no JSON-LD and no `/e/` event links in the raw HTML, and robots.txt fetches returned an HTML page instead of a text file. Discovery pages are JS-rendered and bot-managed. Individual `/e/` pages were not tested.

**Luma (lu.ma, now luma.com)**
- The official Luma API "only grants access to the calendar it was created on" (one key per calendar) and requires a **Luma Plus** subscription. There is no public discovery endpoint. The OpenAPI spec is public at `https://public-api.luma.com/openapi.json`. — [Luma API docs](https://docs.luma.com/reference/getting-started-with-your-api)
- Direct probe: `https://luma.com/capetown` (city discovery page) returns 200 with a JSON-LD `ItemList` ("Popular events in Cape Town", 14 items) of schema.org `Event` objects, each with `@id`/`url` (e.g. `https://luma.com/bxkyggdb`), name and attendance mode. robots.txt carries `Sitemap: https://sitemap.luma.com/sitemap.xml` and only disallows `/social-share`, `/in/`, `/company/` and `/session-*` (for Googlebot). Luma city pages are a very cheap source.

**Meetup**
- Meetup's API is GraphQL. The `meetupr` R package (v0.3.1, Dec 2025) wraps it and notes that "Pro functions will error if you don't have Pro access" (network-wide data). — [meetupr reference (CRAN)](https://cloud.r-project.org/web/packages/meetupr/refman/meetupr.html)
- Secondary sources disagree on whether Pro is needed for general API access or event search. A member token returns limited data, and an organiser token returns full data. — [RapidDev guide](https://www.rapidevelopers.com/md/bolt-ai-integrations/meetup) (third-party, low confidence)
- Direct probe: robots.txt publishes extensive sitemaps, including `events-index-sitemap.xml`, `groups-index-sitemap.xml` and `cities-index-sitemap.xml`, and disallows group calendar Atom/RSS/XML feed paths (`*/calendar/*rss*`, `*/events/atom/*`).

**Resident Advisor (ra.co)**
- Direct probe: `https://ra.co/events/za/capetown` returned **HTTP 403 from Cloudflare** (`server: cloudflare`, `cf-ray ...-CPT`) to curl. The homepage also returned 403.
- Direct probe: an unauthenticated `POST https://ra.co/graphql` with `{"query":"{ __typename }"}` returned `{"data":{"__typename":"Query"}}` (HTTP 200). This is the undocumented GraphQL endpoint used by RA's frontend and by community scrapers. robots.txt disallows `/api/`, `/pro/`, `/user/` and `/widget`, but not `/graphql`. There is no official public RA API.

**Venue websites / iCal**
- No specific SA venue feeds were checked. See Gaps.

### Inferences
- Tiering by acquisition cost:
  - **Tier A (structured, cheap):** Quicket listing JSON-LD, Ticketpro event JSON-LD, Luma city JSON-LD, Meetup sitemaps.
  - **Tier B (JS or undocumented JSON):** Howler, Computicket, Eventbrite, RA GraphQL.
  - **Tier C (unstructured):** Webtickets HTML, venue sites, Instagram posters.
- Because Quicket is now Ticketmaster-owned, a partnership or API-access request may go through a larger corporate legal team. That makes a formal data deal slower, but enforcement against scrapers more likely.
- Undocumented endpoints (RA GraphQL, Howler XHR) can change without notice. Budget for breakage monitoring.

### Gaps
- The contents of the Quicket API docs (docs.quicket.com) could not be retrieved because it is a JS app. I could not confirm whether a public cross-organiser `GET /events` endpoint exists. The Quicket API has historically exposed an events listing with an API key, but this was not verified here.
- Individual Howler, Computicket and Eventbrite event pages were not probed for JSON-LD. Eventbrite event pages often carry JSON-LD for Google Events, but this was unverified.
- Platform ToS texts were not fetched and quoted. Anti-scraping clauses in each ToS remain to be checked.
- No iCal/RSS feeds were found for the SA platforms. Meetup group feeds exist but are robots-disallowed.

## 2. Scraping approach and anti-bot measures

### Takeaway
The best approach is a hybrid. Extract JSON-LD first where it exists, capture the internal JSON APIs of SPAs with Playwright, and use LLM extraction for unstructured pages and poster images. Cloudflare is the main obstacle: RA blocks plain HTTP clients, and Ticketpro's robots.txt shows Cloudflare bot policy. Ready-made Apify actors exist for Eventbrite and Instagram.

### Cited Findings
- Apify hosts commercial actors for Eventbrite discovery, reading "the same search the website uses". These are unofficial and carry ToS and reliability risk. — [Apify Eventbrite Events Intel](https://apify.com/seibs.co/eventbrite-events-intel)
- Direct probe results:
  - Cloudflare 403 on RA HTML pages.
  - No challenge pages ("Just a moment"/cf-chl) on Quicket, Howler, Webtickets, Computicket, Ticketpro, Luma or Eventbrite listing HTML at single-request volume.
- LLM costs for extraction (Claude API list prices, USD per million tokens):
  - Claude Haiku 5.5: $0.10 input / $0.50 output (prompts up to 100k tokens).
  - Claude Sonnet 5.5: $2 input / $10 output.
  - Batch API: 50% discount on both input and output.
  - — [Claude pricing](https://platform.claude.com/docs/en/about-claude/pricing)

### Inferences
- LLM extraction cost at the requested scale is negligible. Example: 5,000 pages/month × ~4k input tokens (cleaned HTML or text) × 500 output tokens on Haiku 5.5 is about 20M input ($2) plus 2.5M output ($1.25), so roughly $3/month, and about $1.60 with Batch. Vision/OCR on posters costs more per item, but at a few thousand images it is still likely under $20–50/month. This is my estimate; it depends on image token counts.
- Suggested tooling:
  - Scrapy or plain httpx plus `extruct` for JSON-LD sources.
  - Playwright or Crawlee (which has a Playwright crawler, request queue and session pool) for SPAs and network capture.
  - Firecrawl or Apify only as paid fallbacks.
- Throttle, cache with ETags, crawl only listing/detail pages, and identify the crawler with a contact UA. This lowers both server-load arguments (see legal section) and block risk.
- Bypassing Cloudflare (RA) with residential proxies or stealth browsers increases legal exposure, because it means circumventing a technical measure (Cybercrimes Act s2 theory below). It is better to pursue RA partnership or omit RA.

### Gaps
- No current Crawlee/Firecrawl/Apify pricing was fetched. No GitHub projects specifically for SA ticket sites were located.
- Bot-detection behaviour at sustained crawl volume was not tested.

## 3. Instagram/Facebook (Meta) access and legal precedent

### Takeaway
Officially, you cannot read events or posts from Facebook pages you don't manage. Event search was removed from the Graph API, and page-content reads need Page Public Content Access, which is a gated App Review feature. Instagram Business Discovery does let a professional account read public media (captions, media URLs) of other **Business/Creator** accounts by username. That makes it a legitimate path for following venue and promoter IG accounts, followed by OCR/LLM on posters. On logged-off scraping, Meta v. Bright Data (N.D. Cal., Jan 2024) held that Meta's terms did not bar logged-off scraping of public data. That is US law, and it does not neutralise POPIA or SA copyright.

### Cited Findings
- Graph API changelog (2018): "You can no longer use the /search endpoint with the following object types: event". GET on certain page edges requires the Page's own access token. — [Graph API v2.11 / 2018 changelog](https://developers.facebook.com/docs/graph-api/changelog/version2.11); [Apr 2018 platform changes](https://developers.secure.facebook.com/ads/blog/post/2018/04/24/platform-product-changes/)
- Endpoints requiring Page Public Content Access need an app token or app secret, and the feature is reviewable. Page Public Metadata Access (2020) gives read-only Pages Search plus some page fields. — [Graph API v6.0 changelog](https://developers.secure.facebook.com/docs/graph-api/changelog/version6.0)
- Instagram Business Discovery works like this:
  - You query from your own IG professional account, passing the target's `username`.
  - Field expansion returns public fields of the target's media (e.g. caption, media_url, like/comment counts).
  - Direct GET on returned media IDs fails.
  - Age-gated accounts are excluded, and media_url is omitted for videos with licensed audio.
  - It needs `instagram_basic`, `instagram_manage_insights` and `pages_read_engagement`.
  - — [Meta: Business Discovery](https://developers.facebook.com/docs/instagram-platform/instagram-api-with-facebook-login/business-discovery); [IG User business_discovery reference](https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/reference/ig-user/business_discovery)
- Meta v. Bright Data: on 23 Jan 2024 Judge Edward Chen (N.D. Cal.) granted Bright Data summary judgment on breach of contract. He held that Facebook/Instagram terms do not prohibit logged-off scraping of public data, because a logged-off scraper is not a "user". There was no evidence that Bright Data scraped logged-in-only data, and the Instagram terms had no survival clause. — [Quinn Emanuel alert](https://www.quinnemanuel.com/the-firm/news-events/client-alert-what-does-the-meta-v-bright-data-summary-judgment-ruling-mean-for-web-scraping/); [Farella Braun + Martel](https://www.fbm.com/post/102kqw7/); [Lowenstein Sandler](https://www.lowenstein.com/news-insights/publications/client-alerts/meta-v-bright-data-ruling-has-important-implications-for-webscraping-activities-by-investment-advisers-im)

### Inferences
- A practical design: maintain a curated list of SA venue and promoter IG Business accounts. Poll them via Business Discovery under your own IG professional account (a rate-limited official route). Run poster images through a vision LLM to extract date, venue, lineup and ticket link. Store only the extracted facts and a link to the post, not the image.
- Facebook Events has no workable official route for third-party pages. Logged-off scraping of FB is technically hard (login walls) and legally contested.

### Gaps
- I did not verify whether Meta appealed or settled Bright Data after Jan 2024. Reports indicated Meta dropped its remaining claims in early 2024, but this was not confirmed in these sources.
- Current Business Discovery rate limits and App Review requirements for 2026 were not confirmed.
- The Instagram Basic Display API was retired in Dec 2024 (background knowledge, not re-verified here).

## 4. Deduplication, geocoding, categorisation, data model, freshness

### Takeaway
Use schema.org `Event` as the canonical model, since the sources already emit it (Quicket, Ticketpro, Luma). Deduplicate with blocking on (date, normalised venue/geo cell), then fuzzy title similarity, with an LLM or embedding tie-breaker for hard cases. Re-crawl listings daily and re-check upcoming events more often.

### Cited Findings
- The schema.org JSON-LD seen in the probes already provides the fields needed for matching: `startDate` (ISO), `location.name` and `address` (locality, postal code, region) and `offers`. Examples are the Quicket "Linder Auditorium, 27 St Andrews Road, Parktown, 2193" and Ticketpro "10bet Ellis Park, S Park Ln, New Doornfontein, 2094" records. (Direct probe.)
- Computicket's sitemap declares `changefreq daily`. (Direct probe.)

### Inferences
- The data model should have:
  - `Event`: a canonical record with `sources[]`, each holding platform, URL, price and last_seen.
  - `Place`/Venue: geocoded, with aliases.
  - `Organizer`: store business names only, to minimise POPIA scope.
  - `Offer`: per-source price and ticket URL.
- The same event appearing on Quicket and Computicket becomes one canonical event with two ticket offers, which is useful for users (price comparison).
- Entity resolution pipeline:
  1. Normalise venue names against a curated SA venue table (a few hundred major venues covers most volume).
  2. Geocode the rest with Google/Mapbox/Nominatim, caching results.
  3. Block candidates on same local date ± 1 day and geocell (e.g. geohash-6) or venue ID.
  4. Score with token-set ratio on titles and lineup/performer overlap.
  5. Auto-merge above a threshold, and send the middle band to an LLM judge (cheap at Haiku prices).
- Categorisation: map each platform's own categories (where provided) to a fixed taxonomy, and use an LLM for the rest.
- Freshness:
  - Listing crawl daily.
  - Events within 14 days re-checked every 6–12 h for sold-out, cancelled or price changes.
  - Expire events after `endDate`.
  - Mark sources stale if not seen in 2 consecutive crawls.

### Gaps
- No SA-specific geocoder accuracy data or dedup benchmark was found. Nominatim's usage policy (1 req/s, no heavy use) was not re-checked.

## 5. Legal position in South Africa (plus international analogues)

### Takeaway
There is no reported SA judgment on web scraping. The main SA risks are:
- copyright in compilations, since SA protects "tables and compilations" as literary works and has no separate database right;
- POPIA, if organiser or individual personal information is processed;
- contractual (ToS) and unlawful-competition claims;
- an untested Cybercrimes Act s2 theory if you continue after being told to stop or circumvent blocks.

A "facts plus link-out" design shrinks every one of these risks: extract factual fields, write your own short descriptions, use no images or only thumbnails with permission, deep-link to the ticket page, and honour opt-outs.

### Cited Findings
- Swart Attorneys' analysis (originally May 2022, republished by Mondaq March 2024) is the main SA commentary found. It **cites no SA case law on scraping**. Its points:
  - The Copyright Act protects compilations of data, so scraping a significant portion could infringe, and persisting images "would likely infringe".
  - Under POPIA, processing personal information via scraping is likely unlawful unless a ground applies. There is a s18 notification duty, and prior authorisation is needed to link data across sources via unique identifiers.
  - ECT Act s76 shields providers of "information location tools" (linking/indexing) from damages for linking to infringing data messages.
  - Under the Cybercrimes Act s2, "access" includes obtaining data output. Scraping after binding terms prohibit it, or after a cease-and-desist, "could be" unlawful access, but this is untested in court.
  - At common law, ToS breach gives contractual remedies and interdicts, unlawful competition may apply, and heavy server load strengthens a complainant's case.
  - Quote: "The fact that something is in the public domain, does not mean that it is free or can be used without conditions."
  - — [Mondaq / Swart Attorneys](https://mondaq.com/southafrica/privacy-protection/1430580/data-scraping-from-a-south-african-perspective)
- A secondary AI-law tracker summarises the SA position this way:
  - The Cybercrimes Act "unlawful access" offence arguably does not reach public pages (citing ENS commentary).
  - POPIA applies even to publicly available personal information.
  - Copyright fair dealing is a closed list with no text-and-data-mining exception.
  - Clickwrap terms are enforceable, browsewrap depends on notice, and robots.txt is non-binding notice.
  - It self-rates its confidence as "medium".
  - — [ungovr: South Africa](https://law.ungovr.org/ai/za); also [MJK Inc on data licensing](https://mjkinc.co.za/software-technology-law/training-data-licensing-agreement)
- US analogue (Meta v. Bright Data, 2024): logged-off scraping of public data was held not to breach Meta's terms. — see section 3 sources.

### Inferences
- **Copyright (compilations):** SA copyright protects original compilations but not the facts themselves. Extracting factual event fields (title, date, venue, price, link) per event is lower risk than wholesale copying of a platform's listings, descriptions and images. Images and long descriptions are separate literary and artistic works, so don't copy them. Use OG-image hotlinks only with permission, or the organiser's own submitted media. SA has no EU-style sui generis database right (background knowledge, consistent with the Swart analysis).
- **ToS as contract:** Browsewrap terms on public pages are weaker than clickwrap. Never create accounts on target platforms for scraping, because that converts browsewrap into clickwrap (cf. Bright Data's account issue).
- **Unlawful competition:** This is the most realistic civil claim from an incumbent such as Computicket or Ticketmaster/Quicket if you free-ride on their listings while diverting sales. Linking out and sending traffic to the platform's own checkout undercuts it, because you drive sales to them.
- **POPIA:** Event listings mostly contain juristic-person and business data, and POPIA also protects juristic persons. Individual organiser names, phone numbers and emails are personal information. Do not store organiser contact details, limit fields to what the listing needs, publish a privacy notice and an opt-out/takedown channel, and register an Information Officer. s12(2) allows collection from sources other than the data subject when information has been deliberately made public by the data subject. This is background knowledge of the POPIA text and was not fetched here; it should be verified.
- **ECT Act s76:** This protects linking/indexing for damages purposes, which supports a link-out search-engine model.
- **Cybercrimes Act:** Stop crawling any site that sends a cease-and-desist or explicitly blocks you. Do not bypass Cloudflare challenges (RA).
- **International analogues** (background knowledge, not re-fetched; cite primary sources before relying on them):
  - hiQ v LinkedIn: in the 9th Cir. 2022, scraping public pages was likely not "without authorization" under the CFAA. The case ended in Dec 2022 with judgment against hiQ on breach of the User Agreement (fake accounts) and a settlement.
  - Ryanair v PR Aviation (CJEU C-30/14, 15 Jan 2015): where a database is protected by neither copyright nor the sui generis right, the Database Directive does not stop the owner restricting its use by contract. The lesson is that contract fills the gap where IP protection is weak, which is persuasive by analogy in SA given there is no database right.

### Gaps
- No Michalsons, Cliffe Dekker Hofmeyr or Webber Wentzel scraping-specific articles were retrieved. The search returned none.
- I did not read the ToS of Quicket, Howler, Computicket, Webtickets, Ticketpro or Eventbrite for anti-scraping clauses.
- The SA Copyright Amendment Bill (Constitutional Court proceedings; [GoLegal](https://www.golegal.co.za/?p=48386)) has an uncertain current status and possible effect on fair use. Not resolved.
- Information Regulator guidance on scraping was not found.

## 6. Reference architecture and monthly costs

### Takeaway
A solo developer can run a few thousand events a month on roughly $15–60/month in infrastructure plus under $10–50 in LLM costs. This is an estimate. The real cost is maintenance time for brittle scrapers (Howler, Computicket, RA) and for dedup quality.

### Cited Findings
- Claude Haiku 5.5 costs $0.10/$0.50 per MTok, with a 50% Batch discount. — [Claude pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- Commercial Apify actors exist for Eventbrite as a fallback. — [Apify](https://apify.com/datascoutlab/eventbrite-scraper)

### Inferences
- Architecture:
  1. Scheduler: cron or GitHub Actions, or a single VPS with systemd timers.
  2. Per-source adapters producing raw snapshots: JSON-LD (httpx + extruct), SPA (Playwright network capture), GraphQL (RA, if permitted), IG Business Discovery, venue HTML (LLM extraction).
  3. Raw store (S3/R2 object storage, with HTML/JSON kept for re-parsing).
  4. Normaliser to schema.org Event.
  5. Geocode, using a venue table and cache.
  6. Entity resolution.
  7. Postgres + PostGIS (or SQLite/Turso at small scale) plus a search index (Postgres FTS or Meilisearch).
  8. Frontend on Next.js/Astro (Vercel/Cloudflare Pages), which emits its own JSON-LD for Google Events SEO.
  9. Monitoring: per-source yield counts and alerts when a source drops more than 50%.
- Rough monthly costs:
  - Small VPS with Playwright: about $5–20.
  - Managed Postgres free or low tier: $0–25.
  - Object storage: about $0–5.
  - Geocoding at about 1–2k new venues per month: free tier or about $5.
  - LLM: about $3–50.
  - Optional residential proxies or Apify: $30–100+, avoidable if you stick to tolerated sources.
  - These are unsourced estimates from typical published pricing, so verify current vendor pricing.
- Organiser self-submission (a form, or ingestion of organisers' iCal/JSON-LD URLs) plus partnerships reduce scraping dependence over time.

### Gaps
- Current Apify, Firecrawl, Crawlee-cloud, VPS and geocoder pricing was not fetched.

## 7. Affiliate monetisation

### Takeaway
I found no public affiliate or referral-commission programme for Quicket, Howler, Computicket, Webtickets or Ticketpro. Monetisation would need direct partnership deals, organiser-level promoter codes (organiser-specific, not platform-wide), sponsored listings, or ads. The international comparison is Skiddle (UK), which runs a formal ticket affiliate programme with a 30-day cookie and a percentage of revenue.

### Cited Findings
- No affiliate terms were found for Quicket, Howler or Computicket. One older TechCentral piece cites Quicket's 4.9% organiser commission, which is the platform fee, not an affiliate payout. — [TechCentral](https://techcentral.co.za/?p=184737)
- Skiddle's ticket affiliate programme credits a percentage of revenue for purchases within 30 days of a referral. — [Skiddle Affiliates](https://www.skiddle.com/affiliates/index.php)
- Ticket Fairy and TicketSource offer organiser-set promoter links and commissions (organiser-level tracking). — [Ticket Fairy](https://www.ticketfairy.com/features/promoters-and-sales-teams); [TicketSource](https://help.ticketsource.com/en/article/reward-affiliates-47qyoy/)

### Inferences
- Ticketmaster runs affiliate programmes in some markets (background knowledge, unverified). After the 2024 acquisition, a Quicket affiliate or partner route might be reachable through Ticketmaster/Live Nation partnerships. Ask directly.
- Outbound links with UTM parameters at least let you show platforms the traffic you drive. That is the basis for negotiating a referral fee or a data licence.

### Gaps
- No direct confirmation either way from Quicket, Howler, Computicket, Ticketpro or Webtickets help centres. Eventbrite's current affiliate status was not checked.
