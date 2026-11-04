# Cape Town niche event sources: hip hop, festivals, markets (as of 20 Oct 2026)

Scope: where Cape Town hip hop/amapiano parties, festivals and markets get announced and ticketed, and where each source publishes **outside Instagram/Facebook**. This builds on `sa_ticketing_platforms.md`, `discovery_channels.md` and `aggregator_feasibility.md`. It does not repeat the general platform analysis from those files.

Method: web search plus direct `curl` probes (desktop Chrome user agent, 20 Oct 2026) for JSON-LD, iCal, RSS, WP REST and newsletter or WhatsApp links. "Probe" means I checked it directly. **[UNVERIFIED]** means the item comes from a single secondary source or from background knowledge.

## Key findings

1. **Howler event pages do carry schema.org `Event` JSON-LD.** I probed `howler.co.za/events/orah-festival-2026-3d9a` and `blackcoffeeweekender.howler.co.za/events/...`. Only Howler's discovery/listing pages are a SPA. This corrects the implication in `aggregator_feasibility.md`. If you know an event URL or organiser subdomain, Howler is cheap to scrape.
2. **Quicket keyword search returns JSON-LD.** I probed `https://www.quicket.co.za/events/?search=hip+hop`. It returned about 20 `Event` objects with `startDate`, venue name and `addressLocality`. The `cityName` param did **not** filter, so filter on `addressLocality == "Cape Town"` yourself. Quicket organiser pages (`/organisers/{id}-{slug}`) are server-rendered lists of `/events/{id}` links with no JSON-LD. Follow each link to the event page, which does have JSON-LD.
3. **Fixr and RA return 403 to curl** (Cloudflare). Webtickets and Airdosh event pages have OpenGraph tags but no JSON-LD.
4. **Cape Town ETC is active**, despite being marked unverified in `discovery_channels.md`. It exposes a working **iCal feed** at `https://www.capetownetc.com/whats-on/?ical=1` (`text/calendar`, 17 VEVENTs on probe), and its event pages carry `Event` JSON-LD. It is the cheapest editorial source found.
5. **CapeMarkets (capemarkets.co.za) is the market directory to use.** It has a public WP REST API at `/wp-json/wp/v2/markets` (222 records, taxonomies `area`, `market-type`, `day-of-week`, `frequency`, `season`) and an RSS feed of new and returning markets (`/feed/`, posts dated 9 Oct 2026). It also sends a Friday-morning newsletter and runs a **WhatsApp Channel** for cancellations (`whatsapp.com/channel/0029VbDDx8s05MUbCenK1k0D`).
6. **Hip hop is the most Instagram-dependent niche.** Recurring hip hop and R&B party brands nearly all ticket on Quicket, which is machine-readable, but they announce on Instagram. There is no dedicated Cape Town hip hop listing site. capetownhiphop.com is a thin, SEO-style blog with no calendar.
7. **Rocking the Daisies 2026 was cancelled** (announced 24 Jul 2026). It was replaced by **In The City** at The Ostrich on 3 Oct 2026, with Isaiah Rashad, YoungstaCPT and KDOLLAHZ, ticketed on Quicket. RTD 2027 is unconfirmed. Calabash 2026 was also cancelled.

---

## 1. Hip hop / rap / R&B / amapiano

| Name | Type | Where announced (non-IG) | Ticketing | Machine-readable access | Confidence / source |
|---|---|---|---|---|---|
| **Primetime (Prime)** | Monthly mixed party (R&B, house, gqom, hip hop), Club Paradise, District Six | IG @primetime_za_ only | Quicket org 34913 (3 upcoming events on probe) | Quicket organiser page links, then event JSON-LD | High: [WOCT party guide](https://whatsonincapetown.com/cape-town-party-events/), probe |
| **Private Affair** | Quarterly 90s/2000s R&B and pop throwback (DJ Waggy), Cabo Beach Club | IG @private_affair_cpt | Quicket org 91962 ("10 Years of You & the Music", 24 Oct 2026) | Quicket JSON-LD | High: WOCT, Quicket search probe |
| **Love, No Labels (Amateur Hour)** | Bi-monthly queer party: hip hop, amapiano, trap, gqom, Spaza Shop, Observatory | No IG listed | Quicket org 56420 | Quicket JSON-LD | High: WOCT, probe |
| **Strictly Soul** | Bi-monthly R&B party (DJ Akio), Youngblood Gallery, Bree St; also tours Africa | **Website** strictly-soul.com (Squarespace), Spotify playlist, YouTube, TikTok, lnk.bio | Own Squarespace ticketing | **`/events?format=json` returns upcoming/past JSON** (probe). Squarespace event items usually support `?format=ical` [UNVERIFIED] | High: probe |
| **Suits & Sneakerz (The Clan)** | Quarterly R&B/soul/house, Hotel Sky | IG | Quicket org 52516 | Quicket JSON-LD | Medium: WOCT |
| **Afterdark** (e.g. "Afterdark IV") | Hip hop/R&B/Afrobeats/amapiano club night, Destiny Cape Town | IG [assumed] | Quicket | Quicket JSON-LD | Medium: [Cape Town Current Sept 2026](https://capetowncurrent.com/whats-on-in-cape-town-this-september-2026/) |
| **Mickz'ed Out** | Club night, Destiny Cape Town (Halloween ed. 23 Oct 2026) | IG [assumed] | Quicket | Quicket JSON-LD | Medium: Quicket search probe |
| **The Hip Hop Floor** | Hip hop party, Rooftop on Bree (2 Jan 2027) | Unknown | Quicket | Quicket JSON-LD | Medium: Quicket search probe; no other web footprint |
| **Rolling Live** | Amapiano headliner series (e.g. DJ Maphorisa x Daliwonga), Alley, Paarden Eiland | Press roundups | Unknown [UNVERIFIED] | — | Low: [Urban Street Culture](https://urbanstreetculture.co.za/cape-town-events-this-weekend-august-2026/) |
| **Piano People** | International amapiano brand; Cabo Beach 30 Dec 2026 (Scorpion Kings) | Website pianopeople.club (403 to curl), press | Howler (also own site) | Howler event JSON-LD | High: [Citizen](https://www.citizen.co.za/lifestyle/entertainment/piano-people-announces-johannesburg-debut/) |
| **Kunye** | Amapiano/house day parties (Cabo Beach late Dec; New Year's Day 2027) | No site found (kunye.co.za is an unrelated property firm) | Howler | Howler JSON-LD | Medium: [Wesgro](https://www.wesgro.co.za/travel/events/kunye-concept), aggregator listing |
| **Love + Friends** | Community day party, Cabo Beach (7 Nov 2026) | Cape Town Tourism guide | Howler | Howler JSON-LD | Medium: single source |
| **Chasing Sunsets** | Rooftop afro house, amapiano and hip hop/R&B singalongs (1 Nov 2026) | Cape Town Tourism guide | Quicket | Quicket JSON-LD | Medium: single source |
| **Amapiano Fest** | Amapiano festival (Sept 2025 edition; 2026 listing inconsistent) | — | Howler | Howler JSON-LD | Low: [Howler](https://www.howler.co.za/events/amapiano-fest-153d) |
| **AFROTRAX** | New hip hop festival, The Ostrich, 4 Dec 2026 (French Montana, B.o.B, Nasty C, Cassper, YoungstaCPT) | Website afrotrax.com (WordPress); press; RA listing | "PLAYYY" per press; the site links to **playy.fm**. RA also lists it | RA (Cloudflare). Site has no JSON-LD | High for the event; platform medium: [Bizcommunity](https://www.bizcommunity.com/article/french-montana-to-headline-inaugural-afrotrax-festival-301868a), [RA](https://ra.co/events/2553536) |
| **In The City (Cape Town)** | One-day hip hop festival replacing RTD, The Ostrich, 3 Oct 2026 | Press; RTD channels | Quicket | Quicket JSON-LD | High: [Time Out](https://www.timeout.com/cape-town/news/rocking-the-daisies-cancelled-072426) |
| **Milk + Cookies Festival** | Multi-genre (amapiano, R&B, hip hop), Jan (29 Jan 2027) | Website milkandcookiesfestival.com (JS, no data) | Howler | Howler JSON-LD | High: [Howler](https://www.howler.co.za/events/milk-and-cookies-festival-south-africa-2026-cape-town-87c2) |
| **Cape Town HipHop Festival / Ngqondo Qina Bopha** | Theatre-based hip hop festival, Artscape, March 2026 | Artscape website | Artscape box office (R120) | Artscape event pages (not probed) | Medium: [Artscape](https://www.artscape.co.za/event/ngqondo-qina-bopha/) |
| **African Hip Hop Indaba / Heal the Hood** | Long-running Cape Flats hip hop festival (battles, b-boy); last confirmed 2015-era; Heal the Hood active 2025 | healthehood.org (no events data) | Historically Quicket | — | Low: no 2026 edition found |
| **Bush Radio x Big Little Music** | Live sessions/open mics broadcast on Bush Radio | Bush Radio site; WordPress event-category RSS (`bushradio.wordpress.com/category/event-2/feed/`, mostly community items) | — | RSS (low signal) | Medium: [IOL 2025](https://iol.co.za/weekend-argus/entertainment/2025-08-21-bush-radio-and-big-little-music-sa-a-new-era-for-cape-towns-music-scene/) |
| **Trap House Culture** | Curated hip hop/trap party | IG only ("don't market traditionally") | Unknown | None | Medium: prior notes (Time Out) |
| **Venues: One Park, The Waiting Room (Long St), Arcade (152 Bree), Club Paradise, Destiny, Saint, Rands (Khayelitsha), Cabo Beach Club, Alley** | Venues with hip hop/amapiano nights | Mostly IG. Arcade is listed on xceed.me | Per-event (Quicket/Howler/door) | Ticket-platform venue filter is possible on Quicket JSON-LD `location.name` | Medium: [capetownhiphop.com](https://capetownhiphop.com/the-best-hip-hop-venues-and-djs-in-cape-town/) (thin, Feb 2026), guides |
| **Township Sunday chillas / shisanyama sessions (e.g. Mzoli's, Rands)** | Informal Sunday amapiano sessions | IG/WhatsApp/word of mouth | Mostly door/free | None | Low: no 2026 web evidence |

**Big touring hip hop/R&B shows** (Dave, Kehlani, Jill Scott at GrandWest) sell on **Ticketmaster**. **Songkick's Cape Town hip hop metro page** (`songkick.com/metro-areas/32788-south-africa-cape-town/genre/hip-hop`) lists only big tours, with no iCal. Songkick has an API, but it needs a key.

## 2. Festivals (in/around Cape Town, typical year)

| Festival | Rough month | Genre | Ticketing | Website / non-IG | Machine-readable | Confidence |
|---|---|---|---|---|---|---|
| Milk + Cookies | Jan | Multi-genre/urban | Howler | milkandcookiesfestival.com | Howler JSON-LD | High |
| WAV by AfroNation | Early Jan | R&B/afro | [UNVERIFIED] | — | — | Medium (CT Tourism Jan 2026) |
| Tweede Nuwe Jaar / Cape Town Minstrel Carnival | 2 Jan | Street parade | Free/grandstand | — | — | Background [UNVERIFIED] |
| Origin | Late Jan | Psychedelic/techno | Fixr | originfestival.com | Fixr blocked (403) | High (probe shows fixr.co link) |
| Wolfkop Weekender | Mid Jan | Disco/house | wontom.com | wolfkopweekender.wontom.com | Not probed | Medium |
| Up the Creek | Feb | Live bands | Howler (site links Howler) | upthecreek.co.za (EventON WordPress) | Howler JSON-LD | High (probe) |
| Black Coffee Weekender | Late Feb | House/culture | Howler (`blackcoffeeweekender.howler.co.za`) | blackcoffeeweekender.com | **Howler JSON-LD confirmed** | High (probe) |
| Investec Cape Town Art Fair | Feb | Art | [UNVERIFIED] | investeccapetownartfair.co.za | No JSON-LD on homepage | Medium |
| Cape Town Pride | Feb–Mar | Pride | — | — | — | [UNVERIFIED] |
| Cape Town International Jazz Festival | March (2027 reportedly spans all of March) | Jazz | Ticketmaster | capetownjazzfest.com | Ticketmaster (not probed) | High |
| Cape Town Carnival | March (21 Mar 2026) | Street parade | Free + seating | capetowncarnival.com | No JSON-LD | High (Time Out) |
| Montreux Jazz Festival Franschhoek | March | Jazz | [UNVERIFIED] | — | — | Medium (WOCT) |
| Bazique; Habitat: Whisper in the Woods | March | Electronic/multi | [UNVERIFIED] | — | — | Medium (WOCT) |
| AfrikaBurn | Late Apr–May | Art/burn | Own system/Quicket [UNVERIFIED] | afrikaburn.org (403 to curl) | — | High (event), low (ticketing) |
| Ultra South Africa (Cape Town) | Late Apr (30 Apr 2027, The Ostrich) | EDM | Official ticket page (platform [UNVERIFIED]) | — | — | Medium |
| Jive Cape Town Funny Festival | June | Comedy | Baxter (Webtickets [UNVERIFIED]) | — | — | High (date) |
| Hermanus FynArts | June | Arts | [UNVERIFIED] | — | — | Medium |
| HEAT Winter Arts Festival | August | Arts | — | — | — | Medium (USC) |
| Open Book Festival | Sept [background] | Literature | [UNVERIFIED] | openbookfestival.co.za (Mailchimp newsletter) | No JSON-LD | Medium |
| WOMAD South Africa | Sept (15–24 Sept 2026, Artscape + V&A) | World music | Mixed/[UNVERIFIED] | womadsa (domain unresolved) | — | Medium ([Artscape](https://www.artscape.co.za/?p=17204)) |
| Waarnmakersweek | Sept (Wellington) | Creative | kaarkies.co.za | — | — | Medium |
| Rocking the Daisies | Early Oct, Darling. **Cancelled 2026** | Multi | Quicket (site links Quicket) | rockingthedaisies.com | Quicket JSON-LD | High |
| In The City | Early Oct (2026 replacement) | Hip hop/R&B | Quicket | — | Quicket JSON-LD | High |
| Toyota Stellenbosch Woordfees | Oct | Afrikaans arts | Quicket org 55878 | woordfees.co.za | Quicket JSON-LD | High |
| Boland Summer Festival (Paarl) | Oct | Pop/mainstream | [UNVERIFIED] | — | — | Medium |
| Hermanus Whale Festival | Oct | Eco-arts/markets | — | — | — | Medium |
| Pangea | Late Oct | Electronic | Airdosh | — | OG tags only | High |
| Cape Town International Kite Festival | Oct | Family | — | — | Cape Town ETC iCal | High (probe) |
| Taste of Cape Town | Late Nov (28–29 Nov 2026) | Food | Own site `tasteofcapetown.co/tickets` | tasteofcapetown.com | No JSON-LD | High |
| Best Day Out | Late Nov (Company's Garden) | Live bands/DJs | Webtickets | — | OG only | High |
| Streetopia (Observatory) | Late Nov | Free community | — | — | — | Medium |
| Festive Lights Switch-On (City) | Late Nov | Civic | Free | capetown.gov.za | — | High |
| Kirstenbosch Summer Sunset Concerts | Sundays, late Nov–Mar | Pop/rock/local | Webtickets + gate | sanbi.org news (kirstenbosch.co.za domain now hijacked by a spam site) | Webtickets OG only | High (2025/26 season) |
| AFROTRAX | Early Dec | Hip hop | playy.fm / "PLAYYY" | afrotrax.com | — | High |
| Habitat: Arcadian Forest | Early Dec | Electronic | Quicket | — | Quicket JSON-LD | High |
| Orah, Love & Light | Mid–late Dec | Electronic/psy | Howler (incl. `musicpeople.howler.co.za`) | — | Howler JSON-LD | High |
| Piano People, Kunye (Cabo Beach) | Late Dec / 1 Jan | Amapiano | Howler | pianopeople.club | Howler JSON-LD | High/Medium |
| We Love Summer NYE; Alien Safari Little Forest | NYE | House / psy | Howler (`wls.howler.co.za`) / Quicket | — | JSON-LD | High |
| Wavescape | Dec [background] | Surf film/culture | [UNVERIFIED] | wavescape.co.za | No JSON-LD | Low |
| Calabash | (2026 cancelled) | Rock | — | — | — | Medium |

**Best single festival index:** What's On in Cape Town's [Music Festivals in Cape Town](https://whatsonincapetown.com/music-festivals-in-cape-town/) page. It is a 24-row list with direct ticket links and is kept current (it notes the RTD and Calabash cancellations). Festival homepages rarely carry JSON-LD. **Index the ticket-platform pages, not the festival sites.** Howler organiser subdomains (`{brand}.howler.co.za`) are a stable per-brand hook.

## 3. Markets

| Market | Schedule | Where dates are published (non-IG) | Ticketing | Machine-readable | Confidence |
|---|---|---|---|---|---|
| **Oranjezicht City Farm Market** (Granger Bay, V&A) | Sat 08:00–14:30 (one listing says 12:00), Sun; Wednesday night market 16:00–21:30 (closed Jun–Jul) | ozcf.co.za; **WhatsApp group** link on homepage (`chat.whatsapp.com/I5VrVkWqDzt9yTqooUqUtu`); YouTube | Free | Hours are in HTML only, no JSON-LD | High (probe) |
| **Neighbourgoods Market** (Old Biscuit Mill, Woodstock) | Sat 9–3, Sun 10–4 | neighbourgoodsmarket.co.za (newsletter signup, WhatsApp business `wa.me/27798656957`, YouTube); theoldbiscuitmill.co.za (Mailchimp, Spotify) | Free | No JSON-LD | High (probe) |
| **Bay Harbour Market** (Hout Bay) | Fri 5–9pm, Sat–Sun 9:30–4 | bayharbour.co.za (Mailchimp newsletter) | Free | No JSON-LD | High |
| **Boschendal Friday Night Market** | Every Friday (seasonal from Aug) | **Quicket** (each Friday is a separate event) | Quicket (free/RSVP) | **Quicket JSON-LD** (probe: weekly entries to Jan 2027) | High |
| **Lourensford Market** (Somerset West) | Fri night 5–10pm + weekends (seasonal from Sept) | lourensford.co.za (EventON calendar plugin, Mailchimp) | Free | EventON often exposes iCal [UNVERIFIED] | Medium |
| **Blaauwklippen Family Market** (Stellenbosch) | Sundays [background] | blaauwklippen.com (403 to curl) | Free | — | Low |
| Root44 (Stellenbosch) | Weekends | root44.co.za | Free | No JSON-LD | Medium |
| Mojo Market (Sea Point) | Daily, indoor; event days such as "Mojo Reggae All Day" | site unreachable on probe; Quicket for events | Quicket for events | Quicket JSON-LD | Medium |
| Blue Bird Garage (Muizenberg) | Fridays [background] | bluebirdgarage.co.za | Free | No JSON-LD | Medium |
| Cape Point Vineyards Community Market (Noordhoek) | Thursday evenings, summer [background] | capepointvineyards.co.za; CapeMarkets RSS ("returns for summer", 9 Oct 2026) | Free | RSS via CapeMarkets | Medium |
| Earth Fair (Tokai/St George's) | Wed + Sat | earthfair.co.za (unreachable on probe) | Free | — | Medium |
| Green Point Flea Market, Greenmarket Square, Milnerton Flea | Weekly | Directories only | Free | — | Medium |
| The Obs Thrift + Alt Fest | Last Saturday monthly | WOCT listing; IG | [UNVERIFIED] | — | Medium |
| Time Out Market (V&A) | Daily food hall + events | timeout.com | — | No JSON-LD on probe | High |
| V&A Waterfront events (Busker Festival 30 Oct–1 Nov 2026, Record & Music Fair 19 Dec 2026) | One-offs | waterfront.co.za/events (429 rate-limit on probe) | Free | — | Medium |
| **City of Cape Town "MyCapeTownMarket" pop-ups** (Scottsdene, Atlantis, Grassy Park) | Periodic | capetown.gov.za Media & news (vendor calls) | Free | No feed found | Medium |
| One-off school/Christmas markets | Nov–Dec | **CapeMarkets**, Quicket (e.g. Lycée Français Christmas Market 5 Dec 2026) | Free/Quicket | CapeMarkets REST + Quicket JSON-LD | High |

**How one-off markets get announced:** (1) **CapeMarkets** (directory with REST API, RSS, Friday newsletter and WhatsApp Channel). (2) What's On in Cape Town's [Markets section](https://whatsonincapetown.com/markets-in-cape-town/), with 25 listings including one-offs. (3) Quicket, for markets that take RSVPs or vendor bookings. (4) Weekly roundups (Cape Town Magazine `/sunday-markets` and `/weekend`, Cape Town Current). Most markets also post on IG and Facebook. But the recurring ones publish fixed hours on their own sites, and new or returning markets reach CapeMarkets' RSS.

## 4. Niche listing sites, newsletters, WhatsApp, radio

| Source | Covers | Channel | Machine-readable | Confidence |
|---|---|---|---|---|
| **Cape Town ETC** (capetownetc.com/whats-on) | General incl. big hip hop shows (AFROTRAX), festivals | Site, newsletter (`/newsletter/`) | **iCal `/whats-on/?ical=1`** + `Event` JSON-LD per page + RSS | High (probe) |
| **What's On in Cape Town** | Parties (with promoter→ticket-platform mapping), festivals, markets | Site; newsletter on Maileon (`events.whatsonincapetown.com/hp/...`) | RSS for blog posts. Event pages (`natihub_event` CPT) have **no Event JSON-LD** and are not in REST, but they are listed in `natihub_event-sitemap{1..N}.xml`, so use sitemap + HTML/LLM extraction | High (probe) |
| **CapeMarkets** | Markets | Site, Friday newsletter, WhatsApp Channel | **WP REST `/wp-json/wp/v2/markets`** + RSS | High (probe) |
| **Cape Town Current** (capetowncurrent.com) | Monthly "what's on" with ticket links (incl. hip hop/amapiano nights on Quicket) | Site; Beehiiv "Weekly Guide" newsletter (7,200+ readers claimed) | RSS (`/feed/`); Beehiiv emails are parseable | High (probe) |
| **Urban Street Culture** (urbanstreetculture.co.za) | Street-culture magazine; weekend Cape Town party roundups incl. amapiano | Site, email newsletter | RSS (`/feed/`) | Medium (cadence unknown) |
| **Let's Get Local** (letsgetlocal.co.za) | "Your local gig guide"; international acts for Cape Town | Site | RSS. `/events/` exists but no iCal/Tribe API | Medium |
| **Happen** (happenlive.co.za) | Cape Town/Jhb nightlife | JS app | Not server-rendered | Medium |
| **Cape Town Magazine** | Weekend lists, Sunday markets, nightclubs guide | Site, Mailchimp newsletter | RSS | High |
| **CapeTourism Beehiiv** | Weekend newsletter | Email | Parseable | High (prior notes) |
| **Cape Town Tourism** (capetown.travel) | Monthly what's on, **Summer 2026 Party Guide** (hip hop/amapiano entries with platforms) | Site | **403 to curl and WebFetch** (bot-blocked); content seen via search snippets only | High (exists), access blocked |
| Time Out Cape Town | Weekly "Out and About", curated club scenes | Site, newsletter | No JSON-LD on homepage | High |
| **Good Hope FM** (SABC) | Station events (R&B lunches, Youth Day concert) | `goodhopefm.co.za/goodhopefm/events/` | Page loads, content looks JS-rendered; site RSS exists | Low as gig guide |
| **Bush Radio 89.5** | Community events; hip hop heritage; Big Little Music live sessions | Site + WordPress RSS | RSS (event category) | Low/medium |
| KFM 94.5 / Heart 104.9 | Primedia stations | JS-only shells (about 5 KB HTML) | None without headless browser | Low; no gig guide found |
| Smile 90.4FM | Lifestyle/events section | Site | RSS | Low |
| Songkick / Shazam / concerts50 / AllEvents hip hop pages | Aggregators, big tours only | — | Songkick API (key) | Medium |
| WhatsApp channels for parties | — | **None found** for hip hop/party brands. Only CapeMarkets (channel), OZCF (group) and Neighbourgoods (business number) | — | — |
| Telegram | — | None found for any niche | — | — |

## 5. Machine-readability summary (probe results)

- **JSON-LD `Event`:** Quicket event + search pages; **Howler event pages (new)**; Cape Town ETC event pages; Ticketpro, Luma (prior).
- **iCal:** Cape Town ETC `/whats-on/?ical=1`. Squarespace sites such as Strictly Soul likely support it [UNVERIFIED].
- **JSON APIs:** CapeMarkets WP REST (`/wp-json/wp/v2/markets`); Squarespace `?format=json` (Strictly Soul events).
- **RSS:** CapeMarkets, Cape Town Current, Urban Street Culture, Let's Get Local, Cape Town Magazine, What's On in Cape Town (blog only), Bush Radio.
- **Newsletters (parseable email):** Cape Town Current (Beehiiv), CapeTourism (Beehiiv), CapeMarkets (Fri), What's On in Cape Town (Maileon), Cape Town ETC, Bay Harbour/Old Biscuit Mill/Lourensford (Mailchimp), Urban Street Culture.
- **Blocked:** capetown.travel (403), Fixr (403), RA (403), Blaauwklippen (403), AfrikaBurn (403), Piano People (403), V&A Waterfront (429).
- **Unhelpful domains:** `kirstenbosch.co.za` serves a spam "Tubidy" page; `kunye.co.za` and `inthecity.co.za` belong to unrelated companies. Don't hard-code these.

## 6. Instagram-only share (rough estimate)

- **Hip hop / amapiano parties:** about **70–80% are IG-only for announcement**, but most of them (roughly 75% of the brands identified) still **ticket on Quicket or Howler**. So the event becomes machine-readable once it is on sale, typically 1–4 weeks out. Truly invisible (IG/WhatsApp/door only): Trap House Culture, township Sunday sessions, open mics and cyphers at One Park and The Waiting Room, Bathhouse-type door-only nights. Only Strictly Soul (own site with JSON) and the festival-scale brands (AFROTRAX, Piano People, Milk + Cookies) have real websites.
- **Festivals:** about **10–15% IG-only.** Almost all have websites and sell on Quicket, Howler, Webtickets, Ticketmaster, Fixr or Airdosh, and they are well covered by What's On in Cape Town, Cape Town ETC and Time Out.
- **Markets:** about **30–40% IG/FB-only**, mostly small pop-ups, thrift and makers' markets. The big recurring markets publish fixed hours on their own sites, and CapeMarkets covers most of the long tail with an API.

## Open questions

- Exact identity of "PLAYYY" (AFROTRAX ticketing). The site links to `playy.fm`. Not probed.
- Whether Lourensford's EventON or Strictly Soul's Squarespace expose iCal endpoints (likely, not tested).
- Good Hope FM events page content (appears JS-rendered). No current radio gig guide was confirmed for any station.
- 2027 dates/platforms for Cape Town Pride, Art Fair, Open Book, Wavescape, Mother City Queer Project, Comic Con: not verified.
