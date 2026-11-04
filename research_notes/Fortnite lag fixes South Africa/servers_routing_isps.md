# Fortnite server regions and international routing from South Africa (as of Oct 2026)

Source-quality note for the report writer: a large share of search results come from `evezone.evetech.co.za` (a PC retailer's blog). Its "latency test results" pages contradict each other and Epic (some claim Johannesburg/Cape Town Fortnite servers at 8-32ms; others say no SA server exists). At least two are dated December 2026, which is in the future. Treat that site as unreliable and do not quote its ping figures as measurements. Reddit could not be fetched. Epic's own help pages and fortnite.com news pages returned HTTP 403, so Epic's region list is cited second-hand.

## 1. Does Epic run a Middle East / Africa / South Africa Fortnite region? State as of 2026

### Takeaway
No official South African or African Fortnite region exists as of Oct 2026. SA players connect to Europe (EU) or Middle East (ME). Leaker Hypex reported in June 2026 that Epic was testing a Cape Town server, but Epic has not confirmed it. The ME region itself was unstable in 2026: after AWS Gulf data centres were damaged in March 2026, ME was moved to Mumbai and then, by May 2026, to Doha, Qatar.

### Cited Findings
- Epic launched the Middle East server region in August 2019, aimed at Saudi Arabia, UAE, Bahrain and India, and expected 20-50% ping improvements for many southern Middle East players. — [Fortnite news, 8 Aug 2019 (via search snippet; page 403'd)](https://www.fortnite.com/news/announcing-the-middle-east-server-region)
- Epic's support page lists the regions as North America, Brazil, Europe, Oceania, Asia and Middle East, with no South African region. This is reported second-hand by a retailer blog and matches every other source. — [Evezone (secondary)](https://evezone.evetech.co.za/quick-bytes/does-fortnite-have-south-african-servers-yet)
- In 2020: "Africa has no Fortnite servers". SA players use Europe or the Middle East. #AfricanFortniteServers trended in August 2020 after AWS opened infrastructure in Africa (AWS Cape Town), and Epic did not comment. — [Mail & Guardian, Oct 2020](https://mg.co.za/news/2020-10-22-epic-fail-africas-fortnite-battle)
- On 27 June 2026, FRVR reported, citing leaker Hypex on X, that Epic was testing new servers in Cape Town, Spain, India, France, Belgium, Sweden, Malaysia, Chile, Taiwan and Singapore, reportedly on AWS and Google Cloud. Some might be new regions and others only routing tests. Epic has not confirmed this. — [FRVR, 27 Jun 2026](https://frvr.com/blog/news/fortnite-servers-new-regions/)
- The same June 2026 Hypex leak was covered as "server tests target lower ping in 10 new cities". — [allthings.how](https://allthings.how/fortnite-server-tests-target-lower-ping-in-10-new-cities/)
- In March 2026, drone strikes during the Iran conflict reportedly damaged AWS data centres in Bahrain and the UAE. Epic moved ME traffic to Mumbai, India, and Gulf players went from roughly 20-40ms to 80-150ms+. These figures come from vendor blogs and player reports. — [NoPing blog](https://noping.com/blog/fortnite-servers-saudi-arabia-mumbai-migration-fix-2026); [LagoFast](https://www.lagofast.com/en/blog/fortnite-middle-east-servers-down/); [Fortnite Underground on X](https://x.com/FNBRunderground/status/2041808554164715549?lang=en)
- In April 2026 Epic reportedly said it could not fix ME latency until Amazon repaired its servers or built new ones in the region. — [LagoFast (secondary)](https://www.lagofast.com/en/blog/fortnite-middle-east-servers-down/)
- On 7 May 2026 the Fortnite Status X account said the ME servers were "fully back in Qatar" (Doha), moved from Mumbai, and that Epic "will continue to monitor latency and stability... and make adjustments if needed." Indian players then reported spikes above 300ms. — [Beebom, 7 May 2026](https://beebom.com/fortnite-relocates-middle-east-server-and-indian-players-arent-happy/)

### Inferences
- For SA players the ME region in Oct 2026 most likely means Doha, Qatar, not Bahrain. From SA, Doha is geographically similar to Bahrain, but routing from SA to the Gulf depends on east-coast cables and Red Sea or Gulf transit, so results vary by ISP.
- Between March and early May 2026, ME was in Mumbai. SA pings to ME during that window would have been worse and do not reflect ME today.
- I found no evidence that Fortnite uses AWS af-south-1 (Cape Town) for production matchmaking. The Cape Town test, if real, is unconfirmed.

### Gaps
- Epic's help page ("Where are Fortnite servers located") and the March 2026 ME latency support page could not be fetched (403), so the current official wording and date are unverified.
- No confirmation of whether the ME region is still Doha in Oct 2026 or has moved back to Bahrain.
- No confirmation of whether the Cape Town test became anything public.

## 2. Typical ping from Johannesburg, Cape Town and Durban to EU and ME

### Takeaway
Expect about 140-200ms to EU from SA fibre, with Cape Town slightly better than Johannesburg or Durban on west-coast routes. ME was historically 120-170ms (2020) but varies more by ISP. Credible, recent ME figures from SA are scarce; claims of 40-90ms to ME are unverified and implausible on physical distance.

### Cited Findings
- 2020: SA players on EU servers usually see 160-200ms. A pro player on ME got 120-170ms "using special software and a VPN", and the article estimated about 300ms for him without it. — [Mail & Guardian, 2020](https://mg.co.za/news/2020-10-22-epic-fail-africas-fortnite-battle)
- SEACOM's Equiano private-line latency is about 110ms between South Africa and Europe (Cape Town to Lisbon), "the fastest direct route" at launch in March/April 2023. This is the best case for raw transport; game ping adds ISP backhaul and transit to Frankfurt or London. — [Engineering News, Apr 2023](https://www.engineeringnews.co.za/article/seacom-goes-live-on-equiano-subsea-cable-2023-04-07); [BusinessTech](https://businesstech.co.za/news/industry-news/672565/seacom-goes-live-on-equiano-subsea-cable/)
- Paratus's Johannesburg-to-Europe express route over Equiano (via Namibia) is 123ms. — [Engineering News, Apr 2024](https://www.engineeringnews.co.za/article/paratus-express-route-from-johannesburg-to-europe-goes-live-2024-04-15)
- MyBroadband forum reports (anecdotal): Afrihost fibre, about 158ms baseline to London with spikes up to 256-280ms. Cool Ideas, about 155-156ms to London (Cape Town and KZN). RSAWEB, about 149ms to an EU server. A poster estimated about 140-142ms from Cape Town to London via WACS and about 135-138ms to France via ACE. — [MyBroadband forum: Afrihost spikes](https://mybroadband.co.za/forum/threads/random-latency-spikes-up-to-280ms-afrihost-fibre.1345471/); [Best ISP for gaming/international latency](https://mybroadband.co.za/forum/threads/best-isp-for-gaming-international-latency.1126628/page-2); [Afrihost 130 ping to EU thread](https://mybroadband.co.za/forum/threads/gamer-on-reddit-claims-she-gets-130-ping-to-eu-on-afrihost-in-wow-is-this-true.1183642/)
- A retailer blog claims ME pings "as low as 40-90ms" from SA. This is unsourced and contradicted by the 2020 M&G figures and by distance (Johannesburg to Doha is about 6,000 km great-circle, so a fibre round trip is at least about 60ms before any routing detours). — [Evezone (unreliable)](https://evezone.evetech.co.za/game-desk/fortnite-middle-east-vs-eu-servers-ping-sa/)
- An ISP's routing choice, such as hauling Cape Town traffic via Johannesburg before going international, added about 20ms or more in one forum case. — [MyBroadband forum: higher ping due to routing](https://mybroadband.co.za/forum/threads/higher-ping-to-some-international-servers-because-of-routing.1184818/)

### Inferences
- Cape Town players on ISPs that break out internationally in Cape Town (west-coast cables: WACS, SAT-3, Equiano, 2Africa west) should see the lowest EU ping, about 140-160ms. Johannesburg adds roughly 15-25ms of domestic backhaul (Johannesburg to Cape Town is about 1,300 km) unless the ISP uses an express route. Durban players may route via the east coast (SEACOM/EASSy via Red Sea) or back through Johannesburg and Cape Town.
- ME from SA logically rides east-coast cables (SEACOM, EASSy, 2Africa east) toward the Gulf. Its quality therefore depends heavily on whether the ISP has a direct path to the Gulf or hairpins through Europe. Hairpinning through Europe would make ME worse than EU.

### Gaps
- No credible recent (2025-2026) measured Fortnite ping from SA to ME (Doha) was found. In-game readings by the user are the reliable route.
- No per-city (Durban vs Johannesburg vs Cape Town) Fortnite measurements from a credible source.

## 3. How subsea cables and cable breaks affect latency to EU and ME, and recent outages

### Takeaway
SA's EU traffic mostly uses west-coast cables (WACS, SAT-3, ACE, Equiano, 2Africa west), with east-coast SEACOM, EASSy and 2Africa east via the Red Sea as alternates. Breaks don't usually take SA offline, because ISPs fail over to other routes, but latency rises while traffic rides longer paths. Major events: west-coast WACS and SAT-3 in Jan 2020 and Aug 2023; SEACOM in the Red Sea in Feb 2024; east-coast EASSy and SEACOM off Durban in May 2024; Red Sea cuts (SMW4, IMEWE and others) in Sept 2025.

### Cited Findings
- Jan 2020: WACS broke at two points and SAT-3 also broke along the same west-coast route, linked to a Congo Canyon undersea landslide. Traffic failed over to SEACOM and EASSy, and latency increased. — [IEEE Spectrum](https://spectrum.ieee.org/tech-talk/telecom/internet/undersea-cable-repairs-south-africa); [Quartz](https://qz.com/africa/1828436/lockdown-south-africa-internet-slows-as-submarine-cable-snaps)
- Aug 2023: WACS and SAT-3 were cut off Congo again (ACE was also hit later). WACS was repaired about a month later (early Sept 2023). — [News24, Sept 2023](https://www.news24.com/news24/tech-and-trends/news/internet-speed-relief-a-snapped-undersea-cable-is-now-fixed-20230907); [ITWeb](https://www.itweb.co.za/article/wacs-submarine-cable-to-be-fully-repaired-this-week/xnklOqz154lM4Ymz)
- WACS lands at Yzerfontein, and SAT-3 lands at Melkbosstrand (Western Cape). — [ITWeb](https://itweb.co.za/content/KzQenMjVd2NMZd2r)
- 24 Feb 2024: SEACOM had an outage on its Mombasa-Zafarana (Egypt) Red Sea segment. SA-to-Europe IP traffic carried by SEACOM was automatically rerouted via Equiano, PEACE and WACS. Clients stayed online with higher latency. — [BusinessDay, 26 Feb 2024](https://www.businessday.co.za/bd/companies/telecoms-and-technology/2024-02-26-seacom-undersea-cable-in-red-sea-breaks/); [ITWeb](https://itweb.co.za/article/seacom-confirms-cable-outage-in-red-sea/KPNG8v8NyDNM4mwD)
- 12 May 2024: EASSy (fault about 45km north of Durban) and SEACOM were both cut between SA and Mozambique, severing nearly all subsea capacity between SA and East Africa. A dragged anchor was suspected. SA traffic was routed via west-coast systems, and NAPAfrica traffic dipped. — [TechCentral](https://techcentral.co.za/?p=245251); [Internet Society Pulse](https://pulse.internetsociety.org/blog/internet-remains-on-in-africa-despite-new-cable-outages); [Techpoint Africa](https://techpoint.africa/2024/05/13/new-subsea-cable-cuts-east-africa/)
- 6 Sept 2025: SMW4 and IMEWE were cut near Jeddah in the Red Sea, with private information suggesting EIG and FALCON breaks too. Cloudflare saw up to 30% higher India-Europe delays, and Microsoft Azure warned of latency for Middle East traffic to and from Asia and Europe. A dragged anchor was the likely cause. — [Kentik](https://www.kentik.com/blog/subsea-cables-parted-in-red-sea-again); [Gulf Business](https://gulfbusiness.com/2025/telecoms/red-sea-subsea-cable-cuts-slow-internet-uae-wider-region/); [Tom's Hardware](https://tomshardware.com/tech-industry/red-sea-cable-cut-takes-azure-routes-down)
- Equiano (Google): Portugal to South Africa, about 15,000 km, 144 Tbps, landed in Cape Town in Aug 2022, with SEACOM services live March 2023 at about 110ms SA-Europe. — [Engineering News](https://www.engineeringnews.co.za/article/seacom-goes-live-on-equiano-subsea-cable-2023-04-07)
- 2Africa (Meta-led) lands in SA at Yzerfontein and Duynefontein (MTN), Gqeberha (Vodacom) and Amanzimtoti (WIOCC). The SA-Kenya segment went live in June 2024, and Meta announced the core system complete in Nov 2025. — [Wikipedia: 2Africa](https://en.wikipedia.org/wiki/2Africa); [DCD: Vodacom lands 2Africa](https://datacenterdynamics.com/en/news/vodacom-lands-2africa-subsea-cable-in-south-africa)

### Inferences
- A west-coast break (WACS, SAT-3 or ACE) pushes EU traffic onto Equiano or onto east-coast routes via the Red Sea, which can add tens of ms to EU ping. A Red Sea break mainly hurts east-coast EU paths and the Gulf/ME paths.
- With Equiano and 2Africa now in service, SA has more redundancy than in 2020. Single-cable breaks should cause smaller latency jumps now, though it depends which cables each ISP buys capacity on.

### Gaps
- No SA-specific latency measurement for the Sept 2025 Red Sea cuts.
- No reports found of a major WACS or SAT-3 break in 2025-2026. The search found none, but this is not confirmed.
- Commercial 2Africa capacity for SA retail ISPs (who buys on it) was not confirmed.

## 4. Which SA ISPs and FNOs route better to Fortnite servers; gaming products and peering

### Takeaway
No credible source ranks SA ISPs by Fortnite (EU or ME) ping. The only solid dataset (MyBroadband Q1 2025) measures domestic latency to Teraco and shows Cybersmart, Clear Access, Rocketnet, Home-Connect and Cool Ideas lowest, with Afrihost at 13th. International ping differences between major fibre ISPs are small (about 150-160ms to London) and come down to each ISP's transit and cable choices. The fibre network operator (Vumatel, Openserve, Frogfoot) is a last-mile layer and matters less than the ISP's international routing.

### Cited Findings
- MyBroadband Insights, Q1 2025 (793,772 speed tests to Teraco servers in SA), average fibre ISP latency: Cybersmart 7.41ms, Clear Access 9.64, Rocketnet 10.69, Home-Connect 10.97, Cool Ideas 11.20, Mind the Speed 11.34, Webafrica 11.41, RSAWEB 12.90, FirstNet Technology (UrbanX parent) 13.32, MWEB 14.44, Level-7 15.78, Metrofibre 16.14, Afrihost 16.98, Vox 17.14, Accelerit 19.42, Supersonic 20.51, wirulink 20.84, HeroTel 21.53, Axxess 22.23, Internet Solutions 27.22. The article names Clear Access and UrbanX as gaming-focused ISPs and credits "carefully managed infrastructure, peering choices" and game-company partnerships. It does not measure international or EU latency. — [MyBroadband, 29 Apr 2025](https://mybroadband.co.za/news/fibre/592472-best-south-african-fibre-isps-for-online-gamers-in-2025.html)
- Anecdotal London pings: Afrihost about 158ms with spikes, Cool Ideas about 155-156ms, RSAWEB about 149ms to EU. — [MyBroadband forum threads](https://mybroadband.co.za/forum/threads/random-latency-spikes-up-to-280ms-afrihost-fibre.1345471/); [Best ISP for gaming/international latency](https://mybroadband.co.za/forum/threads/best-isp-for-gaming-international-latency.1126628/page-2)
- One forum thread reports increased latency to EU servers tied to an ISP's upstream or route changes. This shows EU ping can shift when an ISP changes transit. — [MyBroadband forum: Increased latency to EU servers](https://mybroadband.co.za/forum/threads/increased-latency-to-eu-servers.1203761/)
- An MTN "February 2026" Fortnite test claims an "Africa South" node at 35-55ms, and an Afrihost test claims 18-32ms to Cape Town and Johannesburg servers. Both are from the retailer blog and contradict Epic's region list, so they are not credible. — [Evezone MTN](https://evezone.evetech.co.za/performance-pulse/mtn-gaming-latency-test-results-february-2026-fortnite); [Evezone Afrihost](https://evezone.evetech.co.za/performance-pulse/afrihost-gaming-latency-test-results-february-2026-fortnite)

### Inferences
- Because Fortnite servers are overseas, the domestic-latency ranking only partly predicts Fortnite ping. A good ISP choice means one with a direct, uncongested international path (e.g. Equiano or west-coast breakout from Cape Town) and stable evening performance. Domestic 7ms vs 17ms is minor next to a 150ms international leg.
- Mobile and fixed-LTE/5G (Rain, Vodacom, MTN, Telkom) typically add latency and jitter over fibre. No Fortnite-specific credible data was found for them.
- The FNO (Vumatel, Openserve, Frogfoot) mostly affects last-mile stability. Among ISPs on the same FNO, the ISP's upstream determines international ping.

### Gaps
- No credible 2025-2026 per-ISP measurements of Fortnite EU or ME ping.
- Couldn't verify any current "gaming route" products. For example, there is no confirmed Afrihost or RSAWEB Fortnite-specific peering. The partnerships article MyBroadband links to was not fetched.
- PeeringDB was not checked: Epic and Fortnite run on AWS/GCP, so direct peering with Epic in SA is unlikely to be relevant.
- No credible Rain, Vodacom, MTN or Telkom data for gaming latency to EU or ME.

## 5. Is it worth switching matchmaking region (EU vs ME)? Queue time and lobby skill tradeoffs

### Takeaway
It depends on the ISP's routing, so test both. EU has a much larger player pool (faster queues, fuller lobbies in every mode, and very strong competitive lobbies). ME was historically a bit lower in ping for some SA players but less stable in 2026 (Mumbai detour March to May 2026), and its smaller pool can mean longer queues in niche modes. No credible queue-time data was found.

### Cited Findings
- In 2020 a top SA pro played on ME at 120-170ms (with VPN or routing software) vs 160-200ms typical on EU. His team added a Middle Eastern player to offset the ping gap. — [Mail & Guardian](https://mg.co.za/news/2020-10-22-epic-fail-africas-fortnite-battle)
- High ping puts African players at a disadvantage in lobbies: EU players "see and shoot them first", and building or editing fights suffer. — [Mail & Guardian](https://mg.co.za/news/2020-10-22-epic-fail-africas-fortnite-battle)
- ME routing in 2026 moved Bahrain/UAE to Mumbai (March) and then to Doha (May). Epic said it would "monitor latency... and make adjustments". — [Beebom](https://beebom.com/fortnite-relocates-middle-east-server-and-indian-players-arent-happy/)
- A suggested method is to note the in-game estimated ping for ME and EU, then play at least three matches on each at the same time of day. This advice is reasonable but comes from a low-quality source. — [Evezone (secondary)](https://evezone.evetech.co.za/build-lab/best-fortnite-server-region-for-south-african-players)

### Inferences
- Choose the region with the lower and steadier in-game ping at your usual play time. If they are within about 10-15ms, EU is probably the better default for queue reliability. This is an inference, since queue data is not public.
- Competitive (Arena or tournaments) region choice also fixes which leaderboard or region you compete in. For SA players this has historically been EU or ME.
- Because ME hosting moved twice in 2026, any SA player's pre-March 2026 ME experience may not hold now. Re-test.

### Gaps
- No public data on Fortnite queue times or player counts per region (EU vs ME).
- No data on relative lobby skill (SBMM) between EU and ME.
