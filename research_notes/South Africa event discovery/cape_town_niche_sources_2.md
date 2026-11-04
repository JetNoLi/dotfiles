# Cape Town niche event sources 2: combat sports, skate/extreme, dance, magic, outdoor, extra festivals (as of 20 Oct 2026)

Scope: where these niches announce and ticket events in Cape Town, and where each source publishes **outside Instagram/Facebook**. This follows `cape_town_niche_sources.md` (hip hop, festivals, markets) and does not repeat it. Platform basics (Quicket JSON-LD, Howler event JSON-LD, Cape Town ETC iCal, Fixr/RA 403) are taken as known from that file.

Method: web search plus direct `curl` probes (desktop Chrome UA, **20 Oct 2026**) for JSON-LD, iCal, RSS, WP REST (The Events Calendar `/wp-json/tribe/events/v1/events`) and embedded JSON. "Probe" = checked directly. **[UNVERIFIED]** = single secondary source or background knowledge.

## Key findings

1. **Quicket is the main platform for every niche except races.** Keyword search (`/events/?search=…`, JSON-LD, filter `addressLocality`) turned up Cape Town fight nights (Pound for Pound, Fight Island 7, BMC 11, WKS Africa 3, Ultimate Dirty Boxing 2, Fight Like A Girl, Fight Her Fight), EFC 139/140 (Sandton), College of Magic shows, Cape Town City Ballet's Maynardville season, dance showcases, salsa/SBK events, wine-farm hikes and surf-community events. A keyword list per niche over Quicket search is the cheapest broad net.
2. **Boxing South Africa publishes a machine-readable tournament calendar.** `boxingsa.co.za` home page embeds `<script type="application/json" class="bsa-calendar-data">` (19 sanctioned tournaments on probe, with province, venue, promotion, main bout and title), plus a **per-tournament ICS** (`/?bsa_tournament_ics={id}`). It covers all pro boxing nationally. Only 2 of the 19 were in the Western Cape, so Cape Town pro boxing is thin. Golden Gloves runs mostly at Emperors Palace (Gauteng).
3. **Mountain Club of SA, Cape Town section, has a public Google Calendar ICS:** `https://calendar.google.com/calendar/ical/mcsa.capetown%40gmail.com/public/basic.ics` (linked from `/calendar/`). On probe it held 5,388 VEVENTs in total, **46 from 20 Oct 2026 onward** (Agatha's Gully, Constantiaberg from Silvermine, family hikes and so on). Of all sources in this sweep it is the highest-value find for group hikes.
4. **Meetup group iCal still works:** `https://www.meetup.com/meridian-hiking-club/events/ical/` returned `text/calendar` with 10 VEVENTs. Group pages also carry `Event` JSON-LD (4 events on the Meridian page). Meridian Meetup Hikes has about 7,000 members.
5. **Entry Ninja is the main race-entry platform, and it is easy to scrape.** `entryninja.com/events` is an Inertia.js page whose `data-page` attribute holds a `calendar` array: **284 events, 107 of them Western Cape**, with `start`, `venue`, `province`, `activity` (Trail Running, Road Running, MTB, Hiking, Swimming, Multisport…), `price`, `distances` and `url`, running to 2028. One request covers most trail, MTB, swim and hike events.
6. **Artscape exposes The Events Calendar REST API** (`/wp-json/tribe/events/v1/events`, 21 upcoming on probe, e.g. "The Legacy of Dance Gala", "Dancers Love Dogs", "DRACULA") **and iCal** (`/events/?ical=1`, 25 VEVENTs). **Surfing South Africa** uses the same API (2 upcoming: Sea Harvest Grommet Games 24 Oct, Interclub 21 Nov). These cover ballet/contemporary dance and surf comps cheaply.
7. **Race-specific entry systems:** Cape Town Cycle Tour uses `online.entries.co.za`. Two Oceans uses its own `enter.twooceansmarathon.org.za`. Sanlam Cape Town Marathon 2027 sells on **Howler** (`capetownmarathon.howler.co.za`), which has JSON-LD. `runningcalendar.co.za` event pages carry `Event` JSON-LD and a **per-event `.ics`**, and name the entry platform.
8. **Blocked:** redbull.com/za-en/events (403), gotrail.run (403), running.life (403), sanparks.org (403), howler search (SPA). **Unreachable:** racetime.co.za, baxter.co.za (Baxter moved to `baxter.uct.ac.za`), skateboardingsa.co.za, cluedskate.co.za, baselineskateshop.co.za.

---

## 1. Combat sports (boxing, MMA, Muay Thai/kickboxing)

| Name | Type | Where announced (non-IG/FB) | Ticketing | Machine-readable access | Confidence / source |
|---|---|---|---|---|---|
| **Boxing South Africa** (regulator) | Sanctioned pro boxing calendar, national | boxingsa.co.za tournament calendar (WP plugin "boxing-sa-tournament-calendar" v0.8.3) | n/a (lists promoter and phone) | **Embedded JSON `bsa-calendar-data` + per-tournament ICS `/?bsa_tournament_ics={id}`**; AJAX at `/wp-admin/admin-ajax.php`. Province filter: `western-cape` | High (probe). WC entries: SN Boxing Diep River 4 Sep 2026 (Mlamli Mangcala Promotions); Makers Landing 5 Sep 2026 (Insane Boxing Promotions, WBC Inter Silver) |
| **EFC (Extreme Fighting Championship)** | Pro MMA. Cape Town: EFC KNOX Legacy Series, GrandWest, 26 Feb 2026 (sold out). Regular cards at the EFC Arena, Sandton | efcworldwide.com (Wix, no JSON-LD; PDFs) | Regular cards: **Quicket** (EFC 139, 5 Nov 2026; EFC 140, 3 Dec 2026). GrandWest special: **Ticketmaster** | Quicket JSON-LD (search `EFC`) | High (probe; [Time Out](https://www.timeout.com/cape-town/news/dricus-du-plessis-headlines-cape-towns-first-major-mma-series-111825), [Briefly](https://briefly.co.za/sports/229178-dricus-du-plessis-headlines-efc-fight-night-cape-town-february)). Broadcast: SuperSport [UNVERIFIED for 2026] |
| **Barebones MMA Championship (BMC)** | Amateur/semi-pro MMA, Sunningdale Sports Complex, Milnerton, roughly every 2–3 months | IOL/Cape Argus press releases | **Quicket** ("BMC 11 – Blood Oath", 28 Nov 2026) | Quicket JSON-LD | High (probe, [IOL](https://iol.co.za/sport/mma/2026-07-24-bmc-9-set-to-blow-the-roof-off-sunningdale-sports-complex-on-saturday/)) |
| **Fight Island** | Boxing show ("Vegas in Africa"); earlier editions at Cabo Beach; #7 "December Destruction" 12 Dec 2026, Makers Landing | Press (Atlantic Sun, False Bay Echo) | **Quicket** | Quicket JSON-LD | High (probe) |
| **WKS Africa** | Kickboxing/striking card ("WKS AFRICA 3", 24 Oct 2026, Sunningdale) | Unknown | **Quicket** | Quicket JSON-LD | Medium (probe only) |
| **Pound for Pound Boxing Gym Fight Night** | Gym fight night, 7 Nov 2026 | Gym IG [assumed] | **Quicket** | Quicket JSON-LD | High (probe) |
| **Ultimate Dirty Boxing 2** | Fight night, HomeComing Centre, 21 Nov 2026 | Unknown | **Quicket** | Quicket JSON-LD | Medium (probe) |
| **Fight Like A Girl** (First Principles Gym, 31 Oct) / **Fight Her Fight** (SN Boxing Diep River, 16 Dec) | Women's amateur/gym cards | Unknown | **Quicket** | Quicket JSON-LD | Medium (probe) |
| **Cape Town Combat (Madfit MMA)** | Mixed MMA/Muay Thai card, District Six | — | Quicket (latest listing 2023) | Quicket JSON-LD | Low: no 2026 edition found |
| **Thaiholics Fight Promotions (TFP)** | Muay Thai, Sunningdale | Press (Cape Argus 2024) | [UNVERIFIED] | — | Low: no 2026 card found |
| **Hands Up African Contender Muaythai** | Muay Thai tournament | Cape Town Magazine listing | [UNVERIFIED] | Cape Town Magazine RSS | Low |
| **Golden Gloves** | Pro boxing promoter (SuperSport deal historically) | Boxing SA calendar | [UNVERIFIED] (Computicket/Ticketpro historically) | Boxing SA JSON/ICS | High that it exists; 2026 cards are all Emperors Palace, GP |
| **Rumble Africa Promotions** | Pro boxing, Eastern Cape based | — | — | Boxing SA calendar if sanctioned | Low: no Cape Town 2026 events |
| **SuperSport** schedules | Broadcast listings | supersport.com | — | Not probed (JS-heavy [UNVERIFIED]) | Low value for live attendance |

**IG/FB-only share (combat): ~30–40%.** Most fight cards sell on Quicket because promoters need tickets. The IG-only remainder is gym smokers, interclub sparring and some Muay Thai/BJJ in-house events. Watch out for many Gauteng results in Quicket search, so filter on locality.

## 2. Extreme sports: skateboarding (+ surf, BMX, bouldering)

| Name | Type | Where announced (non-IG/FB) | Ticketing / registration | Machine-readable access | Confidence / source |
|---|---|---|---|---|---|
| **Red Bull Spot Check / BC One / other Red Bull events** | Street skate jam (Nov 2025: City Bowl Park → Company's Garden → Thibault Sq → Civic Centre, started at Baseline Skate Shop) | redbull.com/za-en/events; press (Hype, EWN) | Free / sign-up | **redbull.com 403 to curl**; needs headless browser | High (event), blocked (access). No 2026 Spot Check confirmed |
| **Go Skateboarding Day Cape Town** (Clued Skateboarding + Grand Skate Tour + Red Bull + MICCT) | Annual free CBD jam, ~21 June | Press ([Capetowner](https://capetowner.co.za/news/2026-06-18-skateboarding-music-and-community-spirit-to-take-over-cape-town-cbd-this-sunday/)) | Free | None (cluedskate.co.za unreachable) | High (annual) |
| **Cape Town Pro** (bodyboard + skate, Hout Bay/Llandudno, Eyethu Skate Park) | Annual comp, ~Feb–Mar | Press; Cape Town Magazine listing | Free | Cape Town Magazine RSS | Medium |
| **Vans Park Series Africa / Cape Town Bowl** | Bowl comp | **theboardr.com** event pages | Rider registration on The Boardr | The Boardr pages are Next.js (`__NEXT_DATA__` with `StartDate` fields) | Medium: no confirmed 2026 date |
| **Skateboarding South Africa** (federation) | National champs (2025: Nike Shapa, Soweto), Street Lines (Pretoria), Kimberley Diamond Cup | Press; World Skate calendar | — | skateboardingsa.co.za **unreachable**; World Skate calendar is a news post | Low for Cape Town |
| Skate shops (Baseline, Wawa Surfshop, Atlantic Surf Collective) | Shop-hosted jams, film nights | Mostly IG | Some on **Quicket** (Wawa "Bombocart fun(d)raiser" 6 Nov; Atlantic Surf Collective "Soul Surf Gathering" monthly) | Quicket JSON-LD | Medium (probe) |
| Mill Street / Shred Shed / Gatsby skate | — | Not found | — | — | **[UNVERIFIED]: no web footprint for 2026** |
| **Surfing South Africa** | SA Junior Surf Tour, Grommet Games, Interclub | surfingsouthafrica.co.za/events | Entry via SSA [UNVERIFIED] | **Tribe REST `/wp-json/tribe/events/v1/events`** (2 upcoming on probe) + RSS | High (probe) |
| **Paul Chow Air Show** (Muizenberg surf comp, 14 Nov 2026) | Community surf comp | — | **Quicket** | Quicket JSON-LD | High (probe) |
| **Kommetjie Festival** (21 Nov 2026) | Surf/community festival | — | **Quicket** | Quicket JSON-LD | Medium (probe) |
| 9Miles Project 100Wave Challenge | Surf charity day, Muizenberg (2 May 2026) | Press | Free | — | Medium |
| BMX / bouldering (CityROCK etc.) | — | No 2026 comps found; cityrock.co.za returned 301 with empty body | — | — | **[UNVERIFIED]**; likely gym-IG-only |

**IG/FB-only share (skate/extreme): ~70–80%.** It is the most IG-dependent niche in this sweep. Jams are free, so there is no ticket page, and shops and crews announce on IG. Brand events (Red Bull, Vans) reach press and The Boardr. Surf has a federation feed.

## 3. Dance (battles, Latin socials, ballet/contemporary, showcases)

| Name | Type | Where announced (non-IG/FB) | Ticketing | Machine-readable access | Confidence / source |
|---|---|---|---|---|---|
| **Red Bull BC One Cypher (Cape Town + SA National Final)** | Breaking battle. City Cypher 1 Aug 2026 (V&A Amphitheatre); National Final 5 Sep 2026 (Thibault Sq) | waterfront.co.za/events; press; **and8.dance** (global battle listing) | Free / dancer sign-up | redbull.com 403; and8.dance pages are server-rendered HTML (no JSON-LD) | High ([False Bay Echo](https://falsebayecho.co.za/news/2026-08-04-red-bull-bc-one-cape-town-cypher-local-champions-ready-for-national-competition/)) |
| **Undisputed** (Fujifilm Instax) qualifier | Breaking/crew battle, V&A Waterfront, early Dec (6 Dec 2025) | Press; V&A events | Free [UNVERIFIED] | — | Medium |
| **Cape Town's Most Wanted** | Street dance showcase (18–21 Jun 2026) | Listings (whatsoninjoburg) | [UNVERIFIED] | — | Medium |
| Krump / hip hop dance battles (grassroots) | Cyphers | IG/WhatsApp | Door | None | **[UNVERIFIED]**; none found online |
| **SACATO** | Weekly SBK socials Fri/Sat/Sun, rotating venues (Mojo Market Sunday) | **SalsaVida** listing (WhatsApp number) | Door (~R200/couple) | **SalsaVida event pages carry `Event` JSON-LD** (probe) + site RSS | High (probe) |
| **Paradiso Dance Academy** | Thursday SBK social at Long Street Backpackers; Tuesday salsa class | SalsaVida | Door | SalsaVida JSON-LD | Medium (dates on listing may be stale) |
| **Sensagria** | Weekly classes (Green Point, Century City, Tygervalley) | SalsaVida | — | SalsaVida JSON-LD | Medium |
| **Cape Town Afro-Latin Dance Festival** | Congress, 26 Jan–1 Feb 2027 | SalsaVida festivals page; own site [UNVERIFIED] | [UNVERIFIED] | SalsaVida JSON-LD | High (date) |
| **Cape Town Summer Salsa Festival** | Congress, mid-Dec (2025: 12–14 Dec) | SalsaVida | [UNVERIFIED] | SalsaVida | Medium: 2026 edition unconfirmed |
| SBK All Day Salsa Event (Morgenhof, 31 Oct) / Mojo Salsa Sundays / kizomba "Lovers and Friends" | One-offs | — | **Quicket** | Quicket JSON-LD | High (probe) |
| **Cape Town City Ballet** | Ballet seasons: Maynardville (Jan), Artscape (Mar, Jun, Dec Nutcracker) | capetowncityballet.org.za (WooCommerce "product" pages, RSS) | **Webtickets** for Artscape runs; **Quicket** for Maynardville ("Maynardville 2027: Cape Town City Ballet: Noir", 27 Jan 2027) | Quicket JSON-LD; Webtickets OG only; Artscape Tribe API | High (probe) |
| **Cape Ballet Africa** | Ballet company (Nutcracker Feb 2026; Maynardville 2027) | — | Webtickets / **Quicket** | Quicket JSON-LD | High (probe) |
| **Artscape** | Ballet, contemporary, dance galas, school showcases | artscape.co.za | Webtickets + Dial-A-Seat | **Tribe REST API + iCal `/events/?ical=1`** (21 events / 25 VEVENTs on probe) | High (probe) |
| **Baxter Theatre** (now `baxter.uct.ac.za`, Drupal) | Contemporary dance, dance-academy shows (e.g. Step It Dance Academy) | `/whats-events` listing | **Webtickets** (event page links `webtickets.co.za/v2/event.aspx?itemid=…`) | No JSON-LD; `/rss.xml` 404; HTML scrape of `/events/*` | High (probe) |
| **Jazzart Dance Theatre — Meraki Festival** | Contemporary dance festival (26 Feb–7 Mar 2026, Artscape) | IOL; Artscape | Artscape/Webtickets | Artscape API | Medium |
| **Cape Town Oriental Dance Festival** | Performance day, V&A Amphitheatre, 24 Oct 2026 | — | **Quicket** | Quicket JSON-LD | High (probe) |
| Studio showcases (G-Squared, Kan Jy Dans, Shimmy World Tour, school recitals) | Year-end showcases, Oct–Dec | Studio sites/IG | **Quicket** (many) | Quicket search `dance showcase`, `ballet` | High (probe) |

**IG/FB-only share (dance): ~45–55%.** It splits by sub-niche. Ballet/contemporary is about 5% (theatres have APIs). Studio showcases are about 20% (most use Quicket). Latin socials are about 50% (weekly socials are door-entry; SalsaVida covers the main organisers). Battles and cyphers are about 80% (only Red Bull/Undisputed reach the web).

## 4. Magic shows

| Name | Type | Where announced (non-IG/FB) | Ticketing | Machine-readable access | Confidence / source |
|---|---|---|---|---|---|
| **College of Magic** (Claremont; `magic.capetown` redirects here) | Own-venue shows ("IMPOSSIBLE!", 23–24 Oct 2026), Christmas Magic Show by the Cape Magicians Circle (1 Dec), Stage Junior Magic Champs | collegeofmagic.com (WordPress; Tribe REST exists but **returns 0 events**; EventON present; RSS) | **Quicket** (one event per performance) | **Quicket JSON-LD** (search `magic`, `illusion`, or the venue name "College of Magic") | High (probe) |
| **MAJIKA – Africa's Greatest Illusionists** (College of Magic production, Stuart Taylor host) | Touring illusion show, Cape Town City Hall 7–8 Nov 2026 | BroadwayWorld; Artscape event page `artscape.co.za/event/majika-africas-greatest-illusionists` | [UNVERIFIED] (Artscape/Webtickets or Quicket) | Artscape API if listed | High (event) |
| **Makin' Magic** family show (College of Magic) | Artscape, June school holidays | Cape Town ETC iCal | Artscape/Webtickets | Artscape API, Cape Town ETC iCal | High (2026 run passed) |
| **Monday Night Magic** (Cape Town Magic Club) | Seasonal series at Artscape | Time Out | magic.capetown → College of Magic | — | Low: no 2026 season found |
| International touring magicians (Dynamo, Rob Lake) | Arena shows, GrandWest | Press | **Computicket** (historically) | Computicket not probed here | Medium (irregular, about one a year) |
| **Theatre on the Bay / Pieter Toerien** (same WordPress site; pietertoerien.co.za redirects to it) | Comedy, musicals; magic rarely (none in 2026 found) | Site + RSS | **Webtickets** | No Event JSON-LD (Article only) | High (probe) |
| **Gate69** | Cabaret/illusion-adjacent shows | gate69.co.za (Tribe Events + WooCommerce) | Own WooCommerce | `/events/` JSON-LD **stale (2021 dates)**; Tribe API 301 → HTML | Low: possibly dormant [UNVERIFIED] |

**IG/FB-only share (magic): ~10–15%.** It is a small, institutional niche. The College of Magic sells everything on Quicket, and theatres have websites. The invisible part is corporate/private gigs and restaurant close-up magic, which are not public events anyway.

## 5. Outdoor: group hikes, trail runs, swims, parkrun, cycling

| Name | Type | Where announced (non-IG/FB) | Registration | Machine-readable access | Confidence / source |
|---|---|---|---|---|---|
| **MCSA Cape Town Section** | Up to 200 meets a year (hikes, scrambles, climbs, kloofing, family hikes), weekends + Tue/Thu | mcsacapetown.co.za/calendar | Members (some meets open to guests) | **Public Google Calendar ICS** `calendar.google.com/calendar/ical/mcsa.capetown%40gmail.com/public/basic.ics` (46 upcoming on probe) | High (probe) |
| MCSA Tygerberg section | 25+ meets a year, northern suburbs | tygerberg.mcsa.org.za | Members | Not probed; likely similar | Medium |
| **Meridian Meetup Hikes** | Regular walks/hikes since 1989, ~7k members | meetup.com/meridian-hiking-club | Meetup RSVP | **Meetup iCal `/events/ical/`** (10 VEVENTs) + `Event` JSON-LD on group page | High (probe) |
| **Outdoor Cape Town** (Meetup) | Ad-hoc hikes | meetup.com/outdoor-cape-town | Meetup RSVP | iCal pattern applies; group page had no upcoming events on probe | Medium |
| Other Meetup groups | Outdoor category `meetup.com/find/za--cape-town/outdoor-activities` | Meetup | RSVP | Per-group iCal; discovery page is JS | Medium |
| **ComeHike** (comehike.co.za) | Dated hike series (e.g. 13 Peaks), bookings open 2 months ahead | Site | Own booking | No JSON-LD/feeds on homepage | Medium |
| Wine-farm/guided hikes (Meerendal Full Moon Hike, Muratie Sunset/Full Moon, Intaka Island Bat Night, Koopmanskloof) | Paid social hikes | — | **Quicket** | Quicket JSON-LD (search `hike`) | High (probe) |
| **SANParks / Table Mountain NP** (Wild Card events, Hoerikwaggo) | Park events | sanparks.org | — | **403 to curl** | Low (access) |
| **Entry Ninja** | Trail, road, MTB, hiking, swims, multisport | entryninja.com | Entry Ninja | **Inertia `data-page` JSON, `calendar` array (284 events / 107 WC)**; event pages have no JSON-LD | High (probe) |
| Trail races: Hout Bay Twin Peaks (3 Oct 2026, Energy Events), wine-estate series etc. | Trail running | runningcalendar.co.za; gotrail.run (403) | Mostly Entry Ninja | **runningcalendar.co.za: `Event` JSON-LD + per-event `.ics`** | High (probe) |
| **Totalsports Two Oceans** (31 Mar–4 Apr 2027) | Ultra/half/trail/night run | twooceansmarathon.org.za (RSS) | Own portal `enter.twooceansmarathon.org.za` | RSS for news; no event feed | High (probe) |
| **Sanlam Cape Town Marathon 2027** | Marathon (ballot) | capetownmarathon.com (RSS) | **Howler** (`capetownmarathon.howler.co.za`) | Howler JSON-LD | High (probe) |
| **Cape Town Cycle Tour** (14 Mar 2027 [UNVERIFIED date]) | Mass road cycle | capetowncycletour.com | **online.entries.co.za** (`findperson.aspx?eid=…`) | ASP.NET, no feed | High (platform, probe) |
| Open water: Fish Hoek Mile (12 Sep), Môreson Mile, 36ONE Openwater Series (Clifton, Viking Challenge), Harbour2Harbour, 1SOMS | Swims | Organiser pages | **Entry Ninja**, **Howler** (36ONE), **Racepass** (Harbour2Harbour) | Entry Ninja JSON; Howler JSON-LD | Medium |
| **Cape Point Triathlon** (25 Oct 2026, Simon's Town) | Triathlon | — | **Racepass** (`racepass.com/za/races/…`) | Racepass pages: Organization JSON-LD only; dates in HTML text | High (probe) |
| **parkrun** | 15+ weekly 5k runs in metro (Green Point, Rondebosch Common, Big Bay…) | parkrun.co.za | Free barcode | **`images.parkrun.com/events.json`** (GeoJSON, 230 ZA events). Recurring Sat 08:00, so model as a fixed schedule | High (probe) |
| Strava clubs (run/cycle clubs' group rides) | Club events | Strava | Strava | API requires OAuth and club membership [UNVERIFIED for scraping] | Low |
| Webscorer | Results/timing; some ZA races list registration | webscorer.com | Webscorer | HTML, no JSON-LD on find-races page; has a results API [UNVERIFIED] | Low |
| ABSA Cape Epic (Mar), Ironman 70.3 | Stage MTB / tri | Own sites | Own/Ironman | Not probed | Medium |

**IG/FB-only share (outdoor): ~25–35%.** Organised races are almost entirely on entry platforms, and MCSA plus Meetup cover structured hiking. The IG/WhatsApp-only part is informal hiking crews (women's hiking groups, township hiking clubs, "hike & coffee" groups), which mostly organise in WhatsApp groups. No women-only hiking group with a web calendar was found [UNVERIFIED].

## 6. Additional festivals (sport/outdoor/dance/cultural; not in prior sweep)

| Festival | Month | Type | Ticketing | Machine-readable | Confidence |
|---|---|---|---|---|---|
| HSBC SVNS Cape Town | 5–6 Dec 2026 | Rugby sevens (party-festival crowd) | Ticketmaster [UNVERIFIED for 2026] | — | High (date, [World Rugby](https://www.world.rugby/news/1045878/hsbc-svns-series-and-world-championship-2027-schedule-confirmed-as-road-to-los-angeles-2028-gathers-pace)) |
| Two Oceans Marathon week | 31 Mar–4 Apr 2027 | Running festival | Own portal | RSS | High |
| Cape Town Cycle Tour (+ Lifecycle Week MTB/kids) | Mar 2027 | Cycling | entries.co.za | — | Medium |
| ABSA Cape Epic | Mar | MTB stage race | Own | — | Medium |
| Cape Town Afro-Latin Dance Festival | 26 Jan–1 Feb 2027 | Latin dance congress | [UNVERIFIED] | SalsaVida JSON-LD | High |
| Jazzart Meraki Festival | Feb–Mar | Contemporary dance | Artscape | Artscape API | Medium |
| Cape Town Oriental Dance Festival | Oct (24 Oct 2026) | Belly/oriental dance | Quicket | JSON-LD | High |
| Maynardville Open-Air Theatre season (ballet + Shakespeare) | Jan–Feb 2027 | Ballet/theatre | Quicket | JSON-LD | High (probe) |
| Kommetjie Festival | 21 Nov 2026 | Surf/community | Quicket | JSON-LD | Medium |
| V&A Busker Festival | 30 Oct–1 Nov 2026 | Street performance (already in prior notes) | Free | — | — |
| Earthdance Cape Town | Sept [UNVERIFIED for 2026] | Dance music/peace festival | [UNVERIFIED] | — | Low |
| ArtsAbility Festival | 26 Nov 2026 | Inclusive arts | Quicket | JSON-LD | Medium (probe) |
| Infecting the City / Zabalaza | — | Public art / township theatre | — | — | **[UNVERIFIED]: no 2026 edition found** |

## 7. Ticketing / registration platforms new to these notes

| Platform | Used by | Access notes (probe 20 Oct 2026) |
|---|---|---|
| **Entry Ninja** (entryninja.com) | Trail, road, MTB, hike, swim events (dominant in WC) | Inertia.js `data-page` JSON on `/events`: `calendar[]` with id/title/start/venue/province/activity/price/distances/url. Event pages have no JSON-LD. **Best single outdoor source.** |
| **Racepass** (racepass.com/za) | Triathlons, swims (Cape Point Tri, Harbour2Harbour) | Server-rendered; only `Organization` JSON-LD; date in text. HTML/LLM extraction |
| **online.entries.co.za** ("Entries") | Cape Town Cycle Tour | ASP.NET entry forms; no listing feed |
| **enter.twooceansmarathon.org.za** | Two Oceans | Own portal; use site RSS for announcements |
| **runningcalendar.co.za** (aggregator) | Road/trail races | `Event` JSON-LD + per-event `.ics` (`/events/{slug}/{year}/calendar.ics`); `/events` index 404'd, so discover via sitemap [UNVERIFIED] |
| **gotrail.run / running.life** (aggregators) | Trail/obstacle calendars by region | 403 to curl |
| **The Boardr** (theboardr.com) | Skate/BMX contests (Vans Park Series) | Next.js `__NEXT_DATA__` includes `StartDate` |
| **and8.dance** | Breaking/street-dance battles worldwide (Red Bull BC One listings) | HTML, no JSON-LD |
| **SalsaVida** (salsavida.com) | Latin socials/congresses directory | `Event` JSON-LD on event pages, RSS |
| **Meetup iCal** | Hiking groups | `meetup.com/{group}/events/ical/` returns `text/calendar` (no key needed) |
| **Google Calendar public ICS** | MCSA Cape Town | Stable public ICS URL |
| **Boxing SA tournament calendar** | Sanctioned pro boxing | Embedded JSON + per-tournament ICS |
| **parkrun events.json** | parkrun | GeoJSON of all events (static weekly schedule) |
| **Webscorer**, **RaceTime** | Timing/results; some registration | Webscorer HTML only; racetime.co.za unreachable |
| Strava clubs | Club rides/runs | OAuth API, member-only; out of scope for v1 |

## 8. Instagram/Facebook-only share: summary

| Niche | Rough IG/FB-only share (announcement) | Main machine-readable route |
|---|---|---|
| Combat sports | ~30–40% | Quicket search + Boxing SA JSON/ICS |
| Skate / extreme | ~70–80% | Surfing SA Tribe API, Quicket (surf-shop events), The Boardr; Red Bull blocked |
| Dance | ~45–55% (ballet ~5%, showcases ~20%, Latin ~50%, battles ~80%) | Artscape API/iCal, Quicket, SalsaVida JSON-LD, Baxter HTML |
| Magic | ~10–15% | Quicket (College of Magic), Artscape API |
| Outdoor | ~25–35% | Entry Ninja JSON, MCSA ICS, Meetup iCal, runningcalendar ICS, Quicket hikes |
| Extra festivals | ~10% | Ticket platforms + Artscape API |

## Open questions

- MAJIKA (7–8 Nov) ticket platform; whether Monday Night Magic still runs.
- Whether Gate69 is still operating (stale 2021 event data).
- Exact entry-platform share in WC: run an Entry Ninja `calendar` diff against runningcalendar.co.za to see what Entry Ninja misses (RaceTime, Webscorer, own portals).
- Women's hiking groups, township hiking clubs and krump/breaking cyphers: no web presence found. Probably WhatsApp-only.
- Red Bull events pages (403): test headless fetch or the Red Bull GraphQL API [UNVERIFIED].
