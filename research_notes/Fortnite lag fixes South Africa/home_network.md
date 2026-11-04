# Home network fixes for Fortnite lag (South African households)

Source-quality warning for the report writer: most SA-specific search results came from Evetech's "EVEzone" blog (evezone.evetech.co.za). It's a retailer blog, and its articles contradict each other on basic facts. Some say Fortnite has no SA server and pings run 150-220 ms. Others report Johannesburg servers at 8-40 ms, or an "Africa South" node at 35-55 ms. It even has a "Verizon SA" test, though Verizon doesn't sell home internet in SA. The site looks mass-produced. In these notes its figures appear only where they're clearly labelled as low-confidence. I found no MyBroadband articles through search on most of these topics, which leaves a gap.

## 1. Wired Ethernet vs Wi-Fi vs powerline/MoCA vs mesh: measured latency and jitter

### Takeaway
Wired Ethernet from the console or PC to the router is the most reliable home fix. In measured tests it beats Wi-Fi on latency and jitter on every router tested. 5 GHz Wi-Fi comes close, 2.4 GHz is clearly worse, and powerline falls in between and depends on the house wiring. Paying more for a "gaming router" doesn't remove the Wi-Fi penalty.

### Cited Findings
- RTINGS tested 11 routers in three ways: wired, wireless near the router, and wireless at 40 ft. The latency gap between wired and wireless showed up on every model. Their article is titled "Buying a gaming Wi-Fi router won't help your ping" — [RTINGS](https://www.rtings.com/router/learn/research/router-latency) (search-summary data; the full page body wouldn't load).
- PC Gamer ran PingPlotter tests. Ethernet had the lowest latency, 5 GHz Wi-Fi was close behind, and 2.4 GHz was about twice as high. The powerline pairs averaged about 25-26 ms, between 5 GHz and 2.4 GHz — [PC Gamer](https://www.pcgamer.com/uk/heres-how-playing-on-wi-fi-hurts-your-game) (search-summary data; the full page wouldn't load, so the exact table is unverified).
- Jitter estimates (not measured): Cat6 under 0.5 ms, 5 GHz Wi-Fi 5-12 ms, powerline AV2 5-20 ms. Wi-Fi jitter is put at 2-5x Ethernet's — [pong.com](https://www.pong.com/tools/wifi-vs-ethernet) (vendor tool page, so these are estimates).
- Powerline results depend on circuit layout, surge-protector multiplugs and nearby appliances, so test the exact pair of sockets you'll use during normal play — [EVEzone](https://evezone.evetech.co.za/quick-bytes/powerline-adapters-for-gaming-honest-sa-results) (low confidence, but this matches general knowledge).
- Suggested DIY test: ping the router for 5 minutes over Ethernet, repeat from the Wi-Fi spot, and compare the median, the 95th percentile and the loss — [EVEzone](https://evezone.evetech.co.za/quick-bytes/ethernet-wi-fi-gaming-honest-2026-answer).
- bufferbloat.net lists eero mesh as having SQM built in ("optimize for conferencing and gaming"), so some mesh systems help on the WAN-queue side — [Bufferbloat.net](https://www.bufferbloat.net/projects/bloat/wiki/What_can_I_do_about_Bufferbloat/).

### Inferences
- Order of preference: Ethernet, then 5 GHz Wi-Fi with a clear line of sight, then powerline or a mesh node with a wired backhaul, then a wireless mesh hop, then 2.4 GHz. Each wireless hop adds latency and jitter.
- MoCA (Ethernet over coax) is unlikely to matter in SA, since homes rarely have coax runs outside DStv satellite cabling. Powerline, or running a flat Cat6 cable, are the realistic options.
- A gaming router helps only if it has proper SQM/AQM (see section 2). Marketing labels like "gaming port" or "game accelerator" don't fix Wi-Fi physics.

### Gaps
- I couldn't get the exact RTINGS or PC Gamer figures, because the full pages didn't load. I found no independent controlled study of powerline vs mesh jitter, and no MoCA data relevant to SA.

## 2. Bufferbloat: how to test and how to fix (SQM / CAKE / fq_codel, router QoS)

### Takeaway
Bufferbloat is latency that spikes when someone else in the house uploads or downloads. It's the most common home cause of "lag only when someone's streaming or uploading". Test with Waveform or Cloudflare. Fix it with SQM (CAKE, or fq_codel) set to about 90% of your measured line speed. ISP-supplied routers and stock "QoS" or "device priority" features usually don't fix it.

### Cited Findings
- Testing: bufferbloat.net recommends tests that measure latency both idle and under load: the Waveform Bufferbloat Test, Speedtest.net, the Cloudflare Speed Test and the LibreQoS Bufferbloat Test. About 15-25 ms or less of extra latency under load means bufferbloat is under control — [Bufferbloat.net](https://www.bufferbloat.net/projects/bloat/wiki/What_can_I_do_about_Bufferbloat/).
- A faster ISP plan doesn't fix bufferbloat, and neither do expensive routers or basic QoS — [Bufferbloat.net](https://www.bufferbloat.net/projects/bloat/wiki/What_can_I_do_about_Bufferbloat/).
- Fix options listed by bufferbloat.net:
  - Turn on SQM on your current router, or buy one with SQM built in: OpenWrt One, Ubiquiti EdgeRouter, eero, GL.iNet, pfSense/OPNsense (fq_codel/fq_PIE), IPFire.
  - Or flash firmware that supports it: OpenWrt 22.03+ with luci-app-sqm, Asuswrt-Merlin plus CakeQOS-Merlin, DD-WRT, Gargoyle, Tomato.
  - Use cake-autorate on links whose speed varies, such as LTE and Starlink.
  - [Bufferbloat.net](https://www.bufferbloat.net/projects/bloat/wiki/What_can_I_do_about_Bufferbloat/)
- OpenWrt SQM guide:
  - CAKE is preferred and "excellent at mitigating bufferbloat". fq_codel is faster but less comprehensive; one user got about 15% more throughput with it on a weak CPU.
  - Set download and upload to 90% of measured speed, then raise them until bufferbloat appears and back off.
  - SQM is CPU-bound and doesn't work with hardware flow offloading (software offloading is fine).
  - Link-layer overhead for fibre/Ethernet: 44, MPU 84.
  - [OpenWrt docs](https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm)
- OpenWrt example: a 500/35 Mbps line with CAKE at 90% lost some throughput (532 to 495 down, 37 to 28 up). Latency under load fell to +0 ms, and the grade went from B to A+ — [OpenWrt docs](https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm).
- Forum users tune until the 95th-percentile latency is under 40 ms in both directions. Common setup mistakes are picking the wrong WAN interface (e.g. eth0 vs eth0.2) and leaving out the dual-srchost/dual-dsthost options. One Xbox user got an A+ but still lagged, which shows bufferbloat isn't the only cause — [OpenWrt forum threads](https://forum.openwrt.org/t/sqm-high-latency/1087?page=5), [Xbox thread](https://forum.openwrt.org/t/xbox-one-skipping-issues/46887), [Turris forum](https://forum.turris.cz/t/bufferbloat-sqm-omnia/15557?page=2).
- Stock ASUS QoS mostly works on device priority. Asuswrt-Merlin exposes fq_codel or CAKE as the queue discipline. TP-Link Deco is listed as device priority without CAKE or SQM — [ASUS ZenTalk](https://zentalk.asus.com/t5/networking/how-to-set-up-sqm-on-asus-router/m-p/449117), [home-network guide (moderate reliability)](https://home-security-guide.readthedocs.io/en/latest/home-networking/14-qos-configuration-for-home-networks-uk/).
- One OpenWrt user found that one modem produced oscillating bufferbloat SQM couldn't control, while a different modem's could be smoothed. In other words, the ISP's CPE matters — [OpenWrt forum](https://forum.openwrt.org/t/how-to-add-new-router-to-fix-bufferbloat/184351).

### Inferences
- SA fibre households usually get an ISP-supplied router running stock firmware, often TP-Link Archer/Deco, Huawei or ZTE. Those generally lack CAKE/SQM. A practical upgrade path is to put an SQM-capable router behind the ONT: GL.iNet, an OpenWrt router, ASUS with Merlin, a MikroTik (RouterOS 7 has a CAKE queue type) or a UniFi gateway with Smart Queues.
- On 25-100 Mbps fibre (common in SA), a modest CPU can shape at line rate, so you lose little throughput by turning SQM on.
- Fixed-LTE/5G speeds vary, so a fixed SQM rate either wastes bandwidth or fails at peak hours. cake-autorate (OpenWrt) is the tool for that case.

### Gaps
- I didn't retrieve vendor docs for MikroTik CAKE, UniFi Smart Queues or TP-Link's newer QoS, so the MikroTik and UniFi points above come from general knowledge and are unverified. I found no data on which router models SA ISPs supply in 2026, or on whether those models support SQM. The Waveform page returned 403, so its grade thresholds aren't quoted here.

## 3. Fibre vs fixed-LTE/5G (Rain, Vodacom, MTN) vs Starlink

### Takeaway
Fibre gives the lowest and steadiest latency. Fixed-LTE/5G works for casual play but suffers evening congestion spikes, more jitter and packet loss, and usually CGNAT. Starlink is still not licensed in SA as of October 2026, and Amazon Leo (via Herotel) is aimed at 2027.

### Cited Findings
- Retailer estimates (low confidence):
  - Fibre: 5-15 ms to local servers. Rain 5G: 20-50 ms, with evening congestion spikes of 80-120 ms. LTE jumps between about 35 and 120 ms.
  - 5G and LTE show more packet loss and jitter than fibre, which shows up as hitching or teleporting in game.
  - [EVEzone Rain 5G](https://evezone.evetech.co.za/quick-bytes/can-you-game-on-rain-5g-in-south-africa), [EVEzone fibre vs LTE](https://evezone.evetech.co.za/performance-pulse/lte-vs-fibre-for-gaming-in-south-africa-can-you-game-on-mobile-data)
- Older SA ISP article: latency is usually much lower on fixed connections (fibre, ADSL) than on wireless ones like Telkom LTE — [FibreTiger](https://www.fibretiger.co.za/article/bandwith-vs-latency).
- CGNAT is common on fixed wireless. It doesn't by itself cause high ping, but it can break incoming connections, voice and peer hosting. To check, see whether the router's WAN IP is in 100.64.0.0/10 — [EVEzone CGNAT](https://evezone.evetech.co.za/quick-bytes/cgnat-gaming-hidden-problem-with-5g-connections).
- Starlink status:
  - In a June 2026 Gazette notice, ICASA set out the licences a satellite operator needs: I-ECS, I-ECNS and spectrum — [Advanced Television](https://www.advanced-television.com/2026/06/30/icasa-sets-out-demands-for-starlink-in-south-africa/).
  - A December 2025 ministerial direction allows equity-equivalent programmes in place of the 30% HDG ownership rule. ICASA's rule change could take 12-18 months, so launch is expected in late 2026 or 2027 at the earliest — [Drive Tesla Canada](https://driveteslacanada.ca/news/starlinks-launch-south-africa-unlikely-before-2027-despite-investment-plan/).
  - In August 2026, SpaceX pressed for clarity at ICASA's spectrum hearings, but no licence has been granted — [Further Africa](https://furtherafrica.com/2026/08/27/starlink-south-africa-edges-closer-to-a-licence/).
  - Using Starlink unofficially in SA breaches local law — [TechInAfrica](https://www.techinafrica.com/is-starlink-legal-south-africa-icasa-rules-licensing-2026/).
- Amazon Leo will be sold through Herotel under the "Evry" brand, with a commercial launch expected in 2027 — [Advanced Television](https://www.advanced-television.com/?p=288890).

### Inferences
- Fortnite's servers sit outside SA, in the Middle East and Europe (see the note in section 5), so the extra 10-40 ms of a good 5G link matters less than its jitter and evening spikes. Stability is what decides the choice.
- If fibre isn't available, place the LTE/5G router by a window facing the tower, use Ethernet from the router and play off-peak. SQM with cake-autorate can help.
- Starlink would probably not beat fibre for Fortnite anyway, because the game servers are far away. Its latency typically runs 25-60 ms and varies (general knowledge, not sourced here). Treat it as unavailable in SA in 2026.

### Gaps
- I found no MyBroadband or other independent measured comparison of fibre, Rain, Vodacom and MTN latency to Fortnite servers. All the SA figures above come from a low-reliability retailer blog.

## 4. Load shedding and power: UPS for the ONT and router, and whether it's still relevant in 2026

### Takeaway
Load shedding has largely stopped. Eskom reported 341 consecutive days without it and projected no load shedding for winter 2026. Local "load reduction" outages and the risk of a return in 2029-2030 remain, so a cheap DC mini-UPS for the ONT and router is still worth having. Most fibre networks have backup power upstream, so the home equipment is the weak point.

### Cited Findings
- At its April 2026 Winter Outlook, Eskom projected no load shedding from 1 April to 31 August 2026 and cited 341 consecutive days without it. EAF rose from 54.55% (FY2023) to about 65.35% (FY2026) — [SAnews](https://www.sanews.gov.za/south-africa/load-shedding-free-winter-cards-sa), [The Post](https://thepost.co.za/weekend-argus/2026-04-28-eskom-forecasts-a-stable-winter-with-no-load-shedding-in-2026/).
- Load reduction continues on some feeders. Eskom expected to take 573 of 971 affected feeders off load reduction by September 2026, with the rest by 2027 — [SAnews](https://www.sanews.gov.za/south-africa/load-shedding-free-winter-cards-sa).
- Eskom's Medium-Term System Adequacy Outlook (October 2025) flags a high likelihood of load shedding in 2029-2030 — [Daily Investor](https://dailyinvestor.com/energy/118224/eskom-warns-of-high-likelihood-of-load-shedding-in-the-future/).
- Most fibre network operators have enough backup on their networks, so the home router and ONT are what need backup power. Some ISPs bundle free mini-UPSs. Units range from about 18 to 105 Wh; for example, a 57.72 Wh unit gives about 5-6 hours on a 10 W router. Check the 9 V or 12 V output against the adapter label, and use splitter cables to run both the ONT and the router. Prices run about R500-R1,500 — [BizNews/MyBroadband reprint](https://www.biznews.com/energy/ups-backup-batteries-loadshedding), [RSAWEB mini UPS](https://shop.rsaweb.co.za/shop/uncategorized/free-mini-ups-v1203w/).

### Inferences
- A power cut doesn't add lag, but it disconnects you, and a mid-match disconnect is a loss. A UPS also protects against brownouts and router reboots.
- If an LTE/5G tower's backup battery runs out during long outages, the home UPS can't help with that.

### Gaps
- I found no independent tests of SA mini-UPS runtimes, and no data on how often fibre networks fail during outages in 2025-2026.

## 5. Gaming VPNs and "ping reducers" (ExitLag, NoPing, WTFast, Mudfish): do they help from SA?

### Takeaway
I found no independent evidence that these tools reliably cut Fortnite ping from SA. In principle they help only when your ISP's default route to the server is poor. They can't beat physical distance, and a normal VPN usually adds latency. The test is to measure with the tool on and off, over Ethernet, at your usual playing time.

### Cited Findings
- ExitLag calls itself a multi-route optimiser rather than a VPN. It sends game traffic along several paths at once and uses the first to arrive — [ExitLag blog](https://www.exitlag.com/blog/what-is-exitlag/), [Evetech](https://www.evetech.co.za/best-vpn-gaming-south-africa/e/3922).
- SA retailer guides claim gains of 5-15 ms, mostly in jitter and loss (LoL guide), and 15-50 ms when ISP routing is bad. These are unverified and come from vendor-adjacent sources — [EVEzone LoL](https://evezone.evetech.co.za/performance-pulse/exitlag-lol-eu-west-ping), [Evetech](https://www.evetech.co.za/best-vpn-gaming-south-africa/e/3922).
- Gaming VPNs usually add latency from SA, because traffic detours via the VPN endpoint. Keep one only if average ping, jitter and loss improve across several matches. Some games and tournaments restrict VPN use — [EVEzone](https://evezone.evetech.co.za/quick-bytes/gaming-vpns-from-south-africa-help-or-hurt).
- A Carry1st post (ExitLag partner content) says many games, Fortnite included, have no official African servers, and gives no Fortnite-specific measurements — [Carry1st](https://carry1st.com/blog/exitlag-boosts-african-gaming-lower-ping-in-pubg-call-of-duty-free-fire).
- Fortnite server context (conflicting, low confidence):
  - Epic's region list reportedly includes NA, Brazil, Europe, Oceania, Asia and Middle East, with no SA region. SA players reportedly see about 150-220 ms, and Middle East estimates range from 60 to 160 ms depending on routing — [EVEzone ME vs EU](https://evezone.evetech.co.za/game-desk/fortnite-middle-east-vs-eu-servers-ping-sa/), [EVEzone SA servers](https://evezone.evetech.co.za/quick-bytes/does-fortnite-have-south-african-servers-yet).
  - Other pages on the same site claim local servers or an "Africa South" node. These contradict the pages above and shouldn't be trusted.
  - Epic has trialled servers in new cities — [allthings.how](https://allthings.how/fortnite-server-tests-target-lower-ping-in-10-new-cities/).

### Inferences
- From SA, the base latency comes from the undersea-cable path to Europe or the Middle East, and no software changes that. A route optimiser can help in two cases: when the ISP sends Middle East traffic via Europe, which is a known kind of SA routing quirk, or when there's packet loss on one path. Most of these tools offer free trials, so measure before paying.
- Choosing the right Matchmaking Region in Fortnite (test Middle East against Europe on your own line) probably does more than any ping reducer, and it's free.

### Gaps
- I found no independent or MyBroadband measurements of ExitLag, NoPing, WTFast or Mudfish for Fortnite from SA, and nothing on Mudfish or WTFast specifically. Epic's official server locations and SA ping figures weren't confirmed from a primary source; another researcher may cover this.

## 6. DNS changes, port forwarding, NAT type and UPnP: do they affect in-game latency?

### Takeaway
Mostly myths for in-match ping. DNS is looked up once, before the session. Fortnite uses dedicated servers, so NAT type and port forwarding mainly affect party and voice chat and connection reliability, not ping. Turning UPnP on, or forwarding the ports Epic documents, fixes voice and party problems.

### Cited Findings
- A DNS lookup takes about 10 ms before the session, and the cached address is reused afterwards, so in-match ping doesn't depend on DNS. DNS affects launcher, login, matchmaking lookups, voice endpoints and the choice of patch CDN — [whatsmydns.net](https://www.whatsmydns.net/articles?page=1), [pinggy.io](https://pinggy.io/blog/best_dns_for_gaming/) (commercial DNS blog), [SafeDNS](https://blog.safedns.com/debunking-the-dns-servers-for-gaming-myth-separating-fact-from-fiction/).
- Dissent: VPN Central says DNS can slightly affect ping. That's a weak source — [VPN Central](https://vpncentral.com/changing-dns-gaming/).
- A Netduma staff member says NAT type has no effect on ping, and that port forwarding just opens ports so NAT shows as Open. That's a 2018 forum post — [Netduma forum](https://forum.netduma.com/topic/26130-port-forwarding). Contradicted by ISP and VPN marketing blogs claiming strict NAT adds latency by relaying traffic — [MyRepublic](https://myrepublic.net/sg/blog/broadband/what-is-a-nat-nat-types-explained-and-why-your-games-are-lagging/).
- Epic's official help page says Fortnite voice chat uses XMPP and needs ports 5222 and 443 open. The page actually prints "433", almost certainly a typo for 443. It also lists Party versus Game channel settings, and notes that Xbox or PlayStation party chat can override Fortnite voice — [Epic Games Help](https://www.epicgames.com/help/c-1/a12434495).
- On CGNAT (common on SA fixed-LTE/5G), incoming connections and voice or peer features can break, and port forwarding is impossible without a public IP — [EVEzone CGNAT](https://evezone.evetech.co.za/quick-bytes/cgnat-gaming-hidden-problem-with-5g-connections).

### Inferences
- Fortnite match traffic goes client to Epic's dedicated server, so NAT type shouldn't change in-match ping. Leaving UPnP on (or forwarding Epic's documented ports) is still sensible for party and voice. On CGNAT, ask the ISP for a public or static IP add-on if voice or party issues persist.
- Changing DNS to Cloudflare or Google is harmless and may speed up logins, but it shouldn't be sold as a ping fix.

### Gaps
- I didn't open Epic's separate "unblock ports for the Launcher and Fortnite" article, so the full port list isn't captured. I found no controlled test of the effect of NAT type on Fortnite ping.
