# Event Aggregator and Discovery Prior Art (South Africa and International), as of Oct 2026

## 1. South African aggregator and discovery attempts, past and present

### Takeaway
SA has no well-funded, dominant consumer event-discovery startup. The space is split three ways. Media and listings sites (What's On Cape Town/Durban, whatsonincapetown.com, Time Out Cape Town/Joburg, Cape Town Etc, Cape Town Magazine) make money from content and ads and are heavily Cape Town-skewed. Ticketing platforms (Computicket, Quicket, now owned by Ticketmaster, Howler, Webtickets, iTickets) each run a discovery layer limited to their own inventory. Small indie apps (e.g. SoWhereTo) appear and then go quiet. Johannesburg is noticeably underserved compared with Cape Town.

### Cited Findings
- **SoWhereTo**: a free iOS app listing events in Cape Town, Stellenbosch and Johannesburg, with filters, a map and check-in rewards. It was built by an individual developer (Lucas Aggouras) and released as v1.0 in Aug 2024. Its version history suggests it may not be actively maintained. — [App Store](https://apps.apple.com/za/app/sowhereto-event-discovery/id6612007806)
- Tracxn counts 68 "events tech" startups in SA (Aug 2026). The search summary says most are event-management or B2B software, not consumer discovery. — [Tracxn](https://tracxn.com/d/explore/events-tech-startups-in-south-africa/__imdTuAwbFjcvv6CcIanzr_5yChKLAA3eVRhADrOYIj8)
- **Whatsnxt** launched in Kigali and planned to expand to SA cities by 2024. I found no confirmation that it did. — [TechGyant, 8 Event Listing Startups in Africa](https://techgyant.com/8-event-listing-startups-in-africa/)
- **Eventerprise** (Cape Town) is a host-to-vendor marketplace, not consumer discovery. — [StartupList Africa](https://www.startuplist.africa/startups/eventerprise)
- **whatsoncapetown.co.za** is live with October 2026 listings. It describes itself as part of a "What's On" network run by the team behind What's On Durban, and links to Quicket for tickets. — [What's On Cape Town](https://whatsoncapetown.co.za/), [events page](https://whatsoncapetown.co.za/events/)
- **whatsonincapetown.com** is a separate, older brand (its X account dates from May 2010). It publishes weekend guides and a newsletter. — [X @woict](https://x.com/woict), [weekend guide](https://whatsonincapetown.com/things-to-do-this-weekend-in-cape-town/)
- **Time Out** runs Cape Town and Johannesburg editions with weekly "Out and About" weekend lists, still publishing in Oct 2026. — [Time Out Cape Town](https://www.timeout.com/cape-town/news/out-and-about-in-cape-town-things-to-do-this-weekend-022526), [Time Out Johannesburg](https://www.timeout.com/johannesburg/news/out-and-about-in-johannesburg-best-things-to-do-this-weekend-082026)
- **Cape Town Etc** publishes weekend roundups and promotes its own **WhatsApp Channel** for distribution. This shows WhatsApp Channels are already used as a delivery pipe for SA "what's on" content. — [Cape Town Etc](https://www.capetownetc.com/lifestyle/things-to-do-weekend-flowers-food-fun/)
- Cape Town Magazine runs a weekly "7 things to do this weekend" feature. — [Cape Town Magazine](https://www.capetownmagazine.com/weekend)
- News24/TRUELOVE publishes occasional Joburg and Cape Town gig guides (2024). — [News24](https://www.news24.com/truelove/she-lives/gig-guide-what-to-do-in-johannesburg-and-cape-town-20241122-2)
- **Ticketing incumbents:** Shoprite calls Computicket the largest ticketing provider in SA. — [Shoprite Holdings](https://www.shopriteholdings.co.za/group/brands/computicket.html)
- **Quicket**: founded in Cape Town in 2011 as self-service general-admission ticketing, also operating in Nigeria, Uganda, Kenya, Zambia and Botswana. Ticketmaster (Live Nation) agreed to acquire it in July 2024 for an undisclosed sum. It continues as a standalone unit under MD James Tagg. Ticketmaster had entered SA in 2022. — [Live Nation press release](https://www.livenationentertainment.com/2024/07/ticketmaster-expands-presence-in-africa-with-acquisition-of-quicket), [News24](https://www.news24.com/business/companies/ticketmaster-the-worlds-largest-ticketing-group-buys-sas-quicket-20240724)
- In 2019 Quicket was heading towards R1bn in cumulative sales, with Webtickets, iTickets and Howler named as rivals. — [IOL Business Report](https://iol.co.za/business-report/companies/sa-ticketing-start-up-heads-towards-r1bn-in-sales-35286802)
- **Howler** (Joburg-based ticketing and cashless festival payments) raised growth funding in 2020. — [Disrupt Africa](https://disruptafrica.com/2020/02/12/south-african-event-ticketing-platform-howler-secures-growth-funding/)
- A 2026 SA comparison site (vendor-run, so treat as marketing) says Howler brings a "dance-scene discovery audience" and that Quicket has "strong organic discoverability." — [tkkt.co.za](https://tkkt.co.za/best-ticket-platforms-south-africa)
- Startup Mzansi's StartupApp includes an events directory for the startup ecosystem, an example of niche discovery for tech and startup events. — [StartupApp](https://www.startupmzansi.app/discover/events)

### Inferences
- No SA consumer-discovery startup appears to have scaled or raised notable funding. Coverage in Ventureburn and Disrupt Africa focuses on ticketing (Howler, Quicket), not aggregation. The failure mode in SA looks more like quiet stagnation (solo apps, abandoned listings) than loud post-mortems.
- Each ticketing platform's discovery covers only its own inventory, and Computicket, Quicket/Ticketmaster, Howler, Webtickets and others split SA supply. The cross-platform "one place" gap is real, but the incumbents with the inventory have little reason to feed an aggregator, apart from affiliate deals.
- Media listings (Time Out, What's On, Cape Town Etc) are editorial and Cape Town-heavy. Johannesburg and Durban/Pretoria have thinner curated coverage, which points to a possible city-first wedge in Joburg.
- Ticketmaster owning Quicket brings global discovery and marketing muscle into SA ticketing. That makes competing on ticketing harder and partnering via affiliate/API more realistic.

### Gaps
- I could not find any record of "Plan-it" or "whatson.co.za" as named SA services, nor any SA event-discovery post-mortems on Ventureburn, Disrupt Africa or TechCentral. Older SA city apps (pre-2018) may exist but did not appear in searches.
- No reliable market-share data for SA ticketing platforms. One market-research page had blank placeholder percentages.
- Traffic and usage numbers for What's On, Time Out SA and the others were not found.
- Ownership of the What's On network (Durban/Cape Town) was not confirmed.

## 2. International comparables: models, outcomes and documented failures

### Takeaway
The international survivors almost all monetise through **ticketing**: Fever/DICE, Eventfinda, RA, Shotgun, Posh, Eventbrite. Others sell **B2B tools and data to artists and promoters** (Bandsintown, and Songkick before its sale) or run **media and ads** (Time Out). Pure listings or affiliate discovery mostly ended up acquired cheaply or shut down. The clearest template is Eventfinda: it started as a listings site to fix a fragmented market, then added ticketing, which became the business.

### Cited Findings
**Fever / DICE**
- Fever's core revenue is ticket sales for events listed on its app and site, much of it for experiences it produces itself (e.g. Candlelight concerts). — [Wikipedia: Fever](https://en.wikipedia.org/wiki/Fever_(app))
- Fever acquired DICE in June 2025, a day after a >$100M round led by L Catterton and Point72. — [Wikipedia: Fever](https://en.wikipedia.org/wiki/Fever_(app)), [Wikipedia: Dice](https://en.wikipedia.org/wiki/Dice_(ticketing_company))
- Fever later raised $250M led by EQT at a reported $5.2B valuation. It claims revenue more than tripled in three years while staying EBITDA-positive (a company claim). — [Digg/MBW summary](https://digg.com/tech/lvhuzt7k)

**Songkick**
- Songkick's original concert-discovery model relied on referral fees from ticketing companies. — [Wikipedia: Songkick](https://en.wikipedia.org/wiki/Songkick)
- WMG sold Songkick to AI music firm Suno in Nov 2025. Reporting suggests Suno mainly wanted the user behavioural data. — [Wikipedia: Songkick](https://en.wikipedia.org/wiki/Songkick)

**Bandsintown**
- Describes itself as a concert ticket aggregator and B2B back-end. Its main product is artist tools for fan growth, tour promotion and analytics. In Oct 2025 it launched an artist-tools marketplace and cited about 100M fans and 700k artists. Revenue figures online ($25–50M) are third-party estimates. — [CB Insights](https://www.cbinsights.com/company/bandsintown), [LeadIQ](https://leadiq.com/c/bandsintown-group/5a1d90f25400005200764c1d)

**Eventfinda (NZ/AU), the closest analogue to a "one stop shop"**
- Founded in Auckland in 2005, launched in 2006 as a listings platform to unify a fragmented market split by category and geography. It later added ticketing, which became its focus: 20M tickets processed in the year before Jan 2017. It also licenses its platform and syndicates listings via an API. — [Startup Daily (2017)](https://www.startupdaily.net/advice/new-zealand-startup-eventfinda-is-a-ticketing-system-built-on-an-events-discovery-platform/), [Wikipedia](https://en.wikipedia.org/wiki/Eventfinda)
- In 2010 it partnered with NZ's Ministry for Culture and Heritage. It expanded to Australia as "Eventfinder" in 2011, and also operates in Singapore, Austria and the US. — [Wikipedia](https://en.wikipedia.org/wiki/Eventfinda)
- CB Insights says Ticketek acquired Eventfinda in Aug 2025. This is single-source and unverified. — [CB Insights](https://www.cbinsights.com/company/eventfinda)

**Resident Advisor and Shotgun (electronic-music niche)**
- RA built editorial and listings credibility, then RA Tickets, which it markets as "the only ticketing platform built solely for the electronic music community". RA Tickets includes anti-touting, face-value resale. RA has been a B Corp since April 2024. — [RA About](https://de.ra.co/about), [Billboard](https://www.billboard.com/?p=6207045)
- An AI-generated filings summary reports negative net assets for Resident Advisor Ltd in 2023–24. Unverified, so check Companies House. — [companiesintheuk](https://www.companiesintheuk.co.uk/company/resident-advisor/analysis)
- Shotgun (founded 2014, France) is a ticketing marketplace that competes with DICE and RA, targets 18–25-year-olds, invests in social features, and claims 8M+ app users (recruiter copy). — [Welcome to the Jungle](https://app.welcometothejungle.com/jobs/Z3_EcHdl)

**Partiful / Luma / Posh, and Facebook Events' decline**
- Commentators describe Facebook Events as declining as younger users leave. No hard usage data was found. — [Ad Age](https://adage.com/article/marketing-news-strategy/facebook-events-has-new-challenger-inside-partiful-event-planning-platform/2491616/), [Hidden Events (competitor blog)](https://hiddenevents.online/blog/luma-vs-meetup-vs-eventbrite-vs-partiful/)
- Partiful: about 500k MAU by Q1 2025, 400% YoY growth (press/company claims). — [NoGood](https://nogood.io/blog/partiful-marketing-strategy/)
- Luma: about 2M event signups per month, user base up 5x from 2023 to 2024. A competitor says Luma discovery is "broken in non-hub cities". — [party.pro](https://party.pro/luma/), [Hidden Events](https://hiddenevents.online/blog/luma-vs-meetup-vs-eventbrite-vs-partiful/)
- Posh: reported 8M users and $350M gross ticket sales, with a discovery feed plus referral "connectors". — [Posh University](https://university.posh.vip/university/post/best-tools-grow-in-person-community-2026)
- Meta ads are still said to convert for local events, so Facebook/Instagram remain a paid acquisition channel even as organic event discovery fades. — [Posh University](https://university.posh.vip/university/post/best-tools-grow-in-person-community-2026)
- In 2016 Facebook tried to make Events a local discovery tool ("Events for You" redesign). — [TechCrunch](https://techcrunch.com/?p=1025397)

**AllEvents.in (covers SA cities). I checked its quality on its Cape Town page (Oct 2026):**
- Listings are mostly current (late Oct to Nov 2026), so freshness is reasonable. Quality problems: the same events repeat across Featured, All and Trending; one event's listed date (Oct 30) contradicts its description (Nov 7); a comedy show is listed at 5:00 am; raw CSS leaks into a description; concerts are mislabelled "Art"; venues are vague ("Cape Town"); prices mix USD, EUR and ZAR; and descriptions use templated text ("Don't Miss X Live in Cape Town…") that suggests bulk scraping or import. Most listings have fewer than 10 "interested" users. — [AllEvents Cape Town](https://allevents.in/cape%20town/all)

**Documented failures**
- **Plancast** (social plans and events): raised an $800k seed, never grew beyond early adopters, and shut down in 2012 before Active Network acquired it. Its founder said people rarely share plans more than a few days ahead, so the data has a short shelf life. A vocal minority added most plans, and early traction misled the team about market size. RSVPing meant leaving the site. — [BetaKit](https://betakit.com/plancast-hits-the-deadpool-after-battling-busy-event-promotion-space/), [Simon Willison summary](https://simonwillison.net/2013/Jul/21/events-leisure-what-platforms/), [SoCalTech 2012](https://www.socaltech.com/fullstory/0044482.html), [HN thread](https://news.ycombinator.com/item?id=3281284)
- **EventVue** (conference attendee networking that pivoted to discovery): "people who would pay, just not enough money and not frequently enough". It was a vitamin, not a painkiller, since organisers cared only about selling tickets. Its discovery widget reportedly reduced organiser sales. — [Failory](https://www.failory.com/cemetery/eventvue), [HN](https://news.ycombinator.com/item?id=3497292)
- **Hugecity** (an event discovery startup, founder Hugh Malkin, 2015 essay): reached about 1M monthly visitors but did not "solve" discovery. Details are under Q3. — [Hugh Malkin](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- Zvents, Going.com, Eventful and Upcoming are named as early attempts that struggled with getting enough listings, either from users or by indexing. — [Quora](https://www.quora.com/Why-have-so-many-events-apps-failed)
- **Facebook Hobbi** was a hobby-project documenting app from Facebook's NPE Team, not an events app. It had about 7k downloads and was shut on 10 Jul 2020. It is only loosely relevant. — [TechCrunch](https://techcrunch.com/2020/06/30/facebook-shuts-down-hobbi-its-experimental-app-for-documenting-personal-projects)
- Gigpeppers (an India live-gig discovery startup) has a self-described failure write-up. — [echai failcode](https://echai.ventures/failcode/a/hn-gigpeppers-com)

### Inferences
- The durable pattern is **discovery as the acquisition funnel, ticketing as the revenue**. Eventfinda, RA, Shotgun and Posh all followed it, and Fever went further into producing its own events. Affiliate-only discovery (early Songkick) ended up as a data asset sold off.
- Niche-first works for credibility: RA and Shotgun in electronic music, Luma in tech/AI meetups, Bandsintown and Songkick in concerts. Generalist "everything" aggregators (AllEvents, Eventful) tend toward low-quality, scraped catalogues.
- AllEvents.in shows that a bulk-scraped generalist product already exists for SA, and that its weaknesses are quality and trust rather than coverage. A new entrant would differentiate on curation and accuracy, not breadth.

### Gaps
- I did not find primary sources for the Yahoo Upcoming shutdown (2013), Sosh, Gogobot, or Facebook Local (the standalone events app, 2016–2019) in this session. The report writer should treat these as unverified unless sourced elsewhere.
- I found no primary data on the economics of Time Out, Meetup, Google Events in Search, or Eventbrite discovery.
- Bandsintown and RA revenue figures are only third-party estimates.
- Partiful's reported June 2026 ticketing-fee launch came from one vendor blog and was not confirmed.

## 3. Structural problems with event aggregators ("startup graveyard")

### Takeaway
The recurring failure causes are consistent across essays and post-mortems: perishable, hyper-local inventory; low-frequency, bursty usage; supply controlled by organisers and platforms that don't need you; low switching costs and Google/Instagram as default search; city-by-city cold starts that don't get cheaper; and low willingness to pay. Investors reportedly see the space as a graveyard.

### Cited Findings
- **Perishability and locality:** an event's value peaks before it happens and drops to zero after, falls sharply with distance, and few events are created more than a month out. — [Hugh Malkin (2015)](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- **Low frequency:** about 90% of Hugecity users visited weekly or less. Traffic peaks before weekends, and roughly half of music tickets sell at announcement and half in the final week. — [Hugh Malkin](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- **Supply capture:** most creators make few events and choose where to post. Facebook's API restricted event access, and 10–20 sign-ins per city were needed for a decent feed. — [Hugh Malkin](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- **City-by-city cold start:** local "tastemakers" (about 10% of users, returning daily) are essential, but each new city needs its own, so expansion costs as much as the first city. — [Hugh Malkin](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- **Investor sentiment:** YC reportedly had an event-discovery company in almost every batch, none successful, and most investors the author approached had lost money in the space (anecdotal). — [Hugh Malkin](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- **CAC and loyalty:** no switching costs, and users default to Google, so SEO is the key channel (e.g. for Time Out, then about 40M monthly visitors). — [Hugh Malkin](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- **Overload:** a full map overwhelmed users, who wanted 5–10 personalised picks. — [Hugh Malkin](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- **Two-sided marketplace chicken-and-egg:** users don't come without listings, and organisers don't list without users. — [Quora](https://www.quora.com/Why-have-so-many-events-apps-failed)
- **Short plan horizon and power-user skew** (Plancast). — [Simon Willison](https://simonwillison.net/2013/Jul/21/events-leisure-what-platforms/), [TechCrunch](https://techcrunch.com/?p=272936)
- **Low willingness to pay and frequency** (EventVue). — [HN](https://news.ycombinator.com/item?id=3497292)
- **Platform risk (2026):** Instagram is reportedly cracking down on aggregator accounts, making online event discovery "harder, pricier, and less reliable" (opinion newsletter). — [Mean CEO blog, May 2026](https://blog.mean.ceo/?p=4621)
- **Passive discovery limit:** a ticketing marketplace's discovery layer reaches only people already browsing for events. — [Posh University](https://university.posh.vip/university/post/best-tools-grow-in-person-community-2026)

### Inferences
- Most structural problems get worse in SA. The market is smaller, ticketing inventory is split across many platforms, and much supply (clubs, markets, community events) lives only on Instagram and WhatsApp posters, which are hard to scrape. Seasonality is strong (summer festival season Dec–Feb, Cape Town tourist peak). That last point is my inference and was not sourced.
- A weekly cadence fits the "bursty, weekend-peaking" usage pattern better than a daily-use app, which supports a newsletter or push-digest format.

### Gaps
- I did not retrieve Andrew Chen's *The Cold Start Problem* or a16z marketplace essays directly. Their framing (atomic networks, hard side = supply) is known but not cited here.
- No quantitative SA seasonality data for events was found.

## 4. What a differentiated SA product could look like, and SA delivery context

### Takeaway
WhatsApp is close to universal among SA internet users (about 92–94%), and mobile data is still expensive, especially prepaid. Both favour lightweight, push-based, curated delivery (a WhatsApp Channel or digest, an email newsletter) over a data-heavy native app. SA media (Cape Town Etc) already use WhatsApp Channels. International evidence favours a niche-first or city-first wedge with curators, monetised later through affiliate links or ticketing partnerships.

### Cited Findings
- WhatsApp monthly use among SA internet users aged 16+ is 92.5% (We Are Social/Meltwater Digital 2026, via secondary source). Other estimates put it at about 94% (MyBroadband citing DataReportal) and 93.9% in late 2025 (Yazi). — [growthpulsemedia](https://www.growthpulsemedia.co.za/smartphone-usage-south-africa-2026/), [MyBroadband](https://mybroadband.co.za/news/smartphones/632644-big-whatsapp-changes-in-south-africa.html), [Yazi](https://www.askyazi.com/articles/whatsapp-penetration-across-africa-statistics-by-country)
- SA had 51.7M internet users (79.6% of the population) as of Oct 2025 (DataReportal Digital 2026, via secondary source). — [itfirst / DataReportal tag page](https://datareportal.com/reports/tag/Southern+Africa)
- Data costs: a standard 30-day prepaid 1GB bundle costs about R79 (down from R100 in 2020), postpaid 1GB about R40. The average across plan types is about R20.50/GB. SA ranks 67th of 100 countries, and 27 African countries are cheaper. — [AllAfrica, Feb 2026](https://allafrica.com/stories/202602120144.html), [AllAfrica StatRanker](https://allafrica.com/stories/202602170116.html), [ICASA tariff report 2024](https://icasa.org.za/uploads/files/2024-25FY-Q2-Bi-annual-Tariff-Analysis-Report-Abridged-Report-RSRU-For-Publication-30092024.pdf)
- Cape Town Etc already pushes weekend content through a WhatsApp Channel. — [Cape Town Etc](https://www.capetownetc.com/lifestyle/things-to-do-weekend-flowers-food-fun/)
- Users want 5–10 personalised picks, not a firehose, and daily-returning "tastemakers" are about 10% of users. — [Hugh Malkin](http://www.hughmalkin.com/blogwriter/2015/9/23/why-no-one-has-solved-event-discovery)
- Niche precedents: RA and Shotgun for electronic music (ticketing on top of community credibility), Luma for tech meetups, and Howler, already positioned around SA dance-scene discovery. — [RA](https://de.ra.co/about), [Shotgun](https://app.welcometothejungle.com/jobs/Z3_EcHdl), [tkkt.co.za](https://tkkt.co.za/best-ticket-platforms-south-africa)
- Eventfinda shows that a listings-first site in a small market (NZ, about 5M people) can become a significant ticketing business and pick up government/cultural partnerships and API syndication revenue. — [Startup Daily](https://www.startupdaily.net/advice/new-zealand-startup-eventfinda-is-a-ticketing-system-built-on-an-events-discovery-platform/)

### Inferences
- **Delivery:** a WhatsApp Channel or opt-in WhatsApp digest, plus a lightweight web page and email, suits SA's near-universal WhatsApp use and costly prepaid data better than a native app. WhatsApp Channels are one-to-many with no per-message cost. Personalised 1:1 WhatsApp Business API alerts carry Meta per-message fees, which I have not sourced here and which would need costing.
- **Wedge options in rough order of evidence:** (a) a niche vertical where the existing SA options are weak or split, e.g. Joburg electronic/amapiano nights or tech/startup meetups; (b) a city-first curated weekly guide for Johannesburg, which has less editorial coverage than Cape Town; (c) a curator or newsletter model with local tastemakers. Avoid a generic all-SA scraped aggregator, because AllEvents.in already occupies that space with poor quality.
- **Monetisation path:** start with affiliate/referral links to Quicket, Howler, Computicket and Webtickets plus promoter-paid featured placement. Later options are own ticketing (the Eventfinda/RA path) or B2B data and promoter tools. Pure ads at SA scale are unlikely to sustain a team (inference, consistent with Time Out needing about 40M monthly visitors globally).
- **Supply acquisition:** much SA supply sits on Instagram, WhatsApp groups and ticketing sites. Organiser self-submission plus curator sourcing is likely needed, since scraping is fragile and Instagram is reportedly cracking down on aggregators.

### Gaps
- I found no SA-specific consumer research on how people currently discover events (survey data on Instagram vs WhatsApp vs ticketing sites).
- No data on whether Quicket, Howler or Computicket offer affiliate programmes or public APIs, or their commission rates.
- WhatsApp Business API pricing for SA (marketing-message rates) was not retrieved.
- No evidence was found on the success or audience size of existing SA WhatsApp Channels for events.
