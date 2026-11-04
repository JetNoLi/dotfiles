# Acquisition methods for a self-hosted arr stack: torrents vs Usenet vs debrid (as of 25 Oct 2026)

Legal note: downloading or sharing copyrighted content without permission is illegal in most jurisdictions, South Africa included. These notes describe the technology and market factually. Prices were observed or reported on 25 Oct 2026 unless a date is given. Many secondary sources here are affiliate or vendor sites (ElfHosted, Usenet.com, troypoint, firesticktvstream), and they are flagged where it matters.

## Torrents (public vs private trackers): speeds, new-episode availability, seeding obligations, private tracker access

### Takeaway
Torrents cost nothing beyond a VPN and are natively supported by Sonarr/Radarr through qBittorrent plus Prowlarr. Public trackers expose your IP to the swarm, and their speed depends on how many peers there are. Private trackers such as BroadcasTheNet (TV) and PassThePopcorn (film) have the best catalogs, but you need an invite and must keep ratio and seeding rules. I found little dated 2026 data on this, so this section is thin.

### Cited Findings
- Private trackers are invite-only, tend to have the strongest catalogs, and impose ratio/seeding rules. A common pattern among users is "Usenet for popular content, private trackers for everything else" — [AnandTech forum thread](https://forums.anandtech.com/threads/who-still-uses-usenet.2269479/page-7) (older forum discussion, not 2026)
- BroadcasTheNet is a private, invite-only TV tracker, and PassThePopcorn is the private film equivalent — [Wikipedia: BroadcasTheNet](https://en.wikipedia.org/wiki/BroadcasTheNet); [Wikipedia: PassThePopcorn](https://en.wikipedia.org/wiki/PassThePopcorn)
- Sonarr is described as "an internet PVR for Usenet and Torrents". Jackett (now generally replaced by Prowlarr) is commonly used to proxy tracker indexers — [AlternativeTo: Sonarr](https://alternativeto.net/software/sonarr/about)
- Downloading a torrent that a debrid service has not cached can be slow when there are few seeds. Speed depends on seed count, and the same applies to direct torrenting — [AnandTech forum](https://forums.anandtech.com/threads/who-still-uses-usenet.2269479/post-34116090)

### Inferences
- With direct torrenting, your residential IP sits in the swarm, so you need a VPN with port forwarding. Many ISPs and rights holders monitor public swarms.
- South Africa: peers in a swarm are mostly in Europe and North America, so international latency (see the Usenet section) also limits per-peer throughput. Seeding uses upload bandwidth, which matters on asymmetric SA fibre and LTE plans.
- Of the three methods, torrents need the least extra software for the arr stack. Sonarr/Radarr talk to qBittorrent natively, and TRaSH Guides document hardlink-friendly folder layouts. The ongoing burden is keeping ratio on private trackers and managing a VPN.

### Gaps
- I did not fetch dated 2026 data on public tracker speed or availability, or on how quickly new TV episodes appear (e.g. EZTV/TorrentGalaxy status in 2026, Prowlarr's public indexer list).
- I did not verify current private tracker invite routes in 2026 (e.g. r/OpenSignups, interview trackers such as MyAnonamouse, or recruitment forums).

## Usenet: how it works, retention, completion/DMCA, 2026 costs (provider + indexers, block accounts), speeds from South Africa

### Takeaway
A Usenet setup is a paid provider on a backbone, plus one or two indexers that supply NZB files, plus SABnzbd or NZBGet as the downloader. Typical cost is about $25-60/year for a provider (promo pricing) plus $10-40/year for indexers, so roughly $3-8/month in total. Frugal Usenet is notable for SA users because it lists an Africa server location. Takedowns (DMCA in the US, NTD for Dutch/EU providers) remove content, so people combine providers on different backbones and add block accounts.

### Cited Findings
**How it works / retention**
- Usenet is a network of paid servers. Retention limits how long files stay before deletion, and PAR files repair damaged downloads — [AnandTech forum](https://forums.anandtech.com/threads/who-still-uses-usenet.2269479/post-33952784)
- Frugal Usenet advertises 5000+ days of retention on its $5.99/mo plan and up to 250 connections — [frugalusenet.com](https://www.frugalusenet.com/) (fetched 25 Oct 2026)

**Takedowns / completion**
- Dutch providers follow a Notice-and-Takedown (NTD) code of conduct. In practice almost all accept requests, and those requests are often generated and processed automatically by monitoring tools — [id.nl](https://id.nl/huis-en-entertainment/computer-en-gaming/netwerk/onvindbaar-op-usenet-echt-niet-61799) (undated)
- A Dutch court ordered a Usenet service to remove infringing material from its servers. BREIN's case against News-Service Europe ended with that company closing, and providers reported rising takedown notices — [Managing IP](https://www.managingip.com/article/2a5c7dlc88ujq7mni86bk/dutch-copyright-owners-score-usenet-victory); [TorrentFreak, 2012](https://torrentfreak.com/usenet-feels-the-heat-as-copyright-holders-try-to-strip-away-content-121109/)
- Posters have used "DRM-like" obfuscation to make bulk takedowns harder — [TorrentFreak, 2013](https://torrentfreak.com/is-pirate-drm-really-the-best-response-to-bulk-dmca-takedowns-130210/)

**Provider pricing (current list, 25 Oct 2026)**
- Frugal Usenet: from $5.00/mo, $5.99/mo, or $60/yr including a Blocknews block account. Servers: 2 US, 1 EU, 1 Africa, 1 Asia, 1 Australia, 1 South America, plus a bonus EU server — [frugalusenet.com](https://www.frugalusenet.com/)
- UsenetServer $5.99/mo on a 12-month plan with 3 months free. Newshosting $8.33/mo on a yearly plan — [Usenet.com Black Friday page](https://www.usenet.com/usenet-black-friday-cyber-week-deals/) (affiliate-driven source)
- 2026 Black Friday deals were not live as of late Oct 2026. They usually start the week before Black Friday — [Usenet.com](https://www.usenet.com/usenet-black-friday-cyber-week-deals/); [nzbhydra blog](https://nzbhydra.com/blog/usenet-black-friday-2026/)

**Most recent promo pricing (Black Friday 2025, as a guide to what to expect in Nov 2026)** — all from [Usenet Almanac](https://usenetalmanac.com/black-friday/)
- Newshosting: $25.05 for 15 months ($1.67/mo), renews at $71.88/yr. Omicron backbone. Includes Easynews, Tweaknews and VPN
- Eweka: €37.50 for 15 months (€2.50/mo), renews at €71.88. Eweka's own backbone (Netherlands). Includes Easynews and VPN
- Easynews: $24.75 for 15 months, renews at $89.99. Omicron backbone. Accepts crypto
- Frugal Usenet: $32/yr, rebills at the same price. NetNews backbone. Bonus backup server up to 1TB/month
- Indexers: NZBGeek $9/yr, $30 for 5 years, $60 lifetime. NZBFinder Basic $12.75/yr, Pro $25.50, Elite $38.25 (with a 15% code). DrunkenSlug 2024: €15 for 16 months (Ale tier), €25 (Wine). In 2025 DrunkenSlug offered +3 bonus months
- nzbhydra's 2025 recap also lists AltHub at $5-20 and an NZBPlanet lifetime tier of about £30 — [nzbhydra](https://nzbhydra.com/blog/usenet-black-friday-2026/)
- Block accounts in 2025 (one-time payment, per TB): Bulknews €15 for 6TB (Abavia), Blocknews $14.99 for 2TB (NetNews), UsenetPrime $15 for 2TB (UsenetExpress/Abavia), ViperNews $18 for 2TB (Uzo Reto), NewsDemon $9 for 1TB (UsenetExpress), UsenetExpress $5 for 500GB — [Usenet Almanac](https://usenetalmanac.com/black-friday/)

**South Africa**
- SA crowd-sourced median download is about 24 Mbps and median latency about 99 ms (date and method unverified) — [speedof.me](https://speedof.me/internet-speed/south-africa)
- In 2013, overseas-hosted content from SA showed about 280-400 ms latency, versus about 25 ms for local content — [RSAWEB](https://www.rsaweb.co.za/south-african-hosting-at-parity-with-the-usa/) (dated)
- Older SABnzbd forum threads from SA users discuss ISP throttling of international bandwidth — [SABnzbd forum](https://forums.sabnzbd.org/viewtopic.php?p=102508)

### Inferences
- A cheap, resilient 2026 combination is one Omicron provider (Newshosting or Easynews on promo), one non-Omicron provider or block (Eweka, Frugal/NetNews, or a Blocknews/Bulknews block), and two indexers (NZBGeek plus DrunkenSlug or NZBFinder). Using different backbones helps completion when one backbone has removed articles. Expect roughly $60-100 in the first year on Black Friday pricing.
- From SA, high latency means you need many connections (SABnzbd 20-50+) to fill the line. Usenet is a single-server TCP download, so with enough connections it should saturate typical SA fibre (100 Mbps to 1 Gbps) better than a thin torrent swarm. Frugal's Africa server may help, but I found no measured data.
- SA payment: providers that take international Visa/Mastercard, or crypto (Easynews), should work. Expect foreign transaction fees, and prices are in USD/EUR.
- Most providers sell over SSL and need no VPN for downloading, which simplifies a Docker on Windows setup.

### Gaps
- I could not fetch the official 2026 list prices for Newshosting and Eweka (pricing pages returned 404). I also did not confirm current non-promo prices for NZBGeek, DrunkenSlug or NZBFinder.
- I found no measured 2026 data on Usenet speeds from South Africa, or on the location and performance of Frugal's Africa server.
- I found no 2026 data on backbone completion rates, or on DMCA vs NTD removal speed (the r/usenet wiki backbone map was not fetched).

## Debrid services (Real-Debrid, TorBox, AllDebrid, Premiumize): prices, cached model, reliability, arr integration

### Takeaway
A debrid service downloads torrents to its own servers and serves files you request that are already cached, over HTTPS, so your IP never joins the swarm. Prices run from about €3 to $12 a month. Real-Debrid had a major 2026 disruption: starting around 10 May 2026 it began rejecting cached torrents whose filenames match keyword filters (e.g. WEB-DL, WEBRip). It also enforces a single-IP rule. As a result, many arr users have moved to TorBox. Integration with Sonarr/Radarr runs through a shim such as Decypharr, zurg plus rclone, rdt-client, or Riven.

### Cited Findings
**Pricing**
- AllDebrid (official page, 25 Oct 2026): €2.99 every 30 days as a recurring card subscription. One-time plans: €2.99 for 15 days, €3.99 for 30 days, €8.99 for 90 days, €15.99 for 180 days, €24.99 for 300 days. Payment by Visa/Mastercard, or Bitcoin for one-time plans — [alldebrid.com/offer](https://alldebrid.com/offer/)
- Premiumize (official page, 25 Oct 2026): €9.99/US$11.99 for 1 month, €69.99/US$79.99 for 1 year ($6.57/mo). Includes 1 TB of cloud storage, and VAT may apply — [premiumize.me/premium](https://www.premiumize.me/premium)
- Real-Debrid: €16 for 180 days is corroborated by several 2025-2026 sources, with other tiers reported at about €4 and €9. 1,000 loyalty points buy a 30-day extension. Sources disagree on whether PayPal is accepted. The official page returned 403, so I could not verify it — [thepricer](https://www.thepricer.org/how-much-does-real-debrid-cost/); [firesticktvstream 2026](https://www.firesticktvstream.com/?p=1938)
- TorBox: about $3/mo Essential, $5 Standard, $10 Pro. Annual list prices are $33, $55 and $110 (BF 2025 promo: $23.10, $38.50, $77). Essential allows 3 concurrent downloads and Standard 5, both with a 200GB file limit. Pro allows 10 concurrent downloads, a 500GB limit, and includes Usenet. These are third-party figures; the official page did not render — [LowEndTalk](https://lowendtalk.com/discussion/198214/celebrate-torboxs-birthday-with-30-off-giveaways/p1?new=1); [Factually, Jun 2026](https://factually.co/fact-checks/electronics-tech/torbox-long-term-reliability-12-month-user-report-cache-growth-49f885)

**Reliability / policy**
- Real-Debrid began blocking many cached torrents around 10 May 2026 based on filename keywords. The error reads "File was removed from debrid service due to copyright infringement." This is not an outage or an account ban, and there has been no public comment or timeline — [ElfHosted blog, 12 May 2026, updated 4 Oct 2026](https://store.elfhosted.com/blog/2026/05/12/real-debrid-filtering-may-2026/) (vendor that sells alternatives)
- Blocked keywords reportedly include WEB-DL, WEBRip, BDRip, HDRip, DVDRip, and some combinations such as BluRay.x264. The workaround is to prefer x265/HEVC/AV1 releases. The filter is tied to French court action and the FNEF film association, and to EU DSA compliance. Users anecdotally lost 50-70% of their cached content — [corelab.tech](https://corelab.tech/real-debrid-infringing-file-fix/); [pcsteps](https://www.pcsteps.com/49069-what-happened-to-real-debrid/); [iptvranking](https://iptvranking.com/real-debrid-file-removal-2026/)
- ElfHosted says Real-Debrid also has recurring "account-purge waves" and a single-IP rule that make arr setups "increasingly fragile". By contrast it says TorBox has no filename filter and allows streams from multiple IPs (5 on Essential, 10 on Pro), but items not accessed for 30 days expire. Caches are independent, so content cached on Real-Debrid is not necessarily cached on TorBox — [ElfHosted migrate RD to TorBox](https://docs.elfhosted.com/guides/media/migrate-realdebrid-to-torbox/)
- AllDebrid is "experiencing legal pressure" (undated guide) — [troypoint](https://troypoint.com/real-debrid-alternatives/)
- No Real-Debrid outage was reported as of 24 Oct 2026 — [IsDown](https://isdown.app/status/real-debrid)

**Arr integration**
- Decypharr is written in Go. It mocks the qBittorrent and SABnzbd APIs so Sonarr/Radarr treat it as a download client. It supports Real-Debrid, TorBox, Debrid-Link, AllDebrid and Premiumize, plus Usenet over NNTP, and exposes libraries over NFSv4/SMB — [GitHub sirrobot01/decypharr](https://github.com/sirrobot01/decypharr)
- Decypharr works with both Real-Debrid and TorBox for Plex and Jellyfin. Many users have moved to TorBox for consistency, though the guide's author still uses Real-Debrid — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/)
- zurg is built around Real-Debrid. ElfHosted's CatBox is a TorBox-specific alternative designed around TorBox's 30-day retention — [ElfHosted docs](https://docs.elfhosted.com/guides/media/migrate-realdebrid-to-torbox/)
- Hosted bundles: ElfHosted sells TorBox Essential bundles with Comet, AIOStreams or MediaFusion at $9/mo, Usenet streamer bundles at $9/mo, and MediaStorm 4K at $9/mo (bring your own RD or TorBox) — [ElfHosted blog](https://store.elfhosted.com/blog/2026/05/12/real-debrid-filtering-may-2026/)

### Inferences
- With Real-Debrid's 2026 keyword filter, Sonarr's default WEB-DL preference (the TRaSH profiles) collides with the content RD will now serve. RD users would need custom formats that favour x265/HEVC, which works against TRaSH's usual quality recommendations. In late 2026 that makes TorBox (or AllDebrid) the safer debrid option for an arr stack.
- The single-IP rule matters if Plex/Jellyfin streams from the debrid mount to remote family members on other IPs, or if the server and a VPN exit use different IPs.
- SA: debrid content is served over HTTPS from EU data centres (RD and AllDebrid are French-linked), so throughput is limited by international latency and per-connection speed. Decypharr/rclone mounts that stream on demand may buffer at around 250+ ms RTT. Downloading to local storage is safer than streaming from the mount.
- Debrid is the cheapest option per month (€3-5), but the most exposed to policy change: you depend on one company's cache and filtering decisions.

### Gaps
- I could not fetch official Real-Debrid or TorBox pricing pages (403 or blank render), so their prices are secondary and should be verified.
- I found no independent 2026 uptime figures for TorBox, AllDebrid or Premiumize, no 2026 status for rdt-client or Riven, and no specific data on account bans for IP sharing beyond ElfHosted's claims.
- I did not confirm whether SA-issued cards are accepted by each debrid service.

## Setup complexity and maintenance burden with the existing stack (Docker on Windows)

### Takeaway
Usenet is the lowest-maintenance option once configured: SABnzbd plus indexers in Prowlarr, with no ratio to keep, no VPN and no swarm exposure. Torrents are just as simple to set up but add VPN and seeding upkeep. Debrid is the most complex in practice (Decypharr or zurg plus rclone or WebDAV mounts, symlinks, cache misses, provider policy changes), and on Windows Docker the FUSE/rclone mounts are an extra pain point.

### Cited Findings
- Decypharr acts as a fake qBittorrent/SABnzbd download client and exposes NFS/SMB shares, so the arr apps need no plugins — [GitHub decypharr](https://github.com/sirrobot01/decypharr)
- The corelab Decypharr setup guide is a "21 min read", which gives a sense of how complex it is — [corelab](https://corelab.tech/decypharr-setup-guide/)
- Moving from Real-Debrid to TorBox requires a migration guide and a TorBox-specific tool (CatBox) because of TorBox's retention model — [ElfHosted docs](https://docs.elfhosted.com/guides/media/migrate-realdebrid-to-torbox/)

### Inferences
- Docker Desktop on Windows runs containers in a WSL2 VM. Bind-mounting Windows NTFS paths breaks hardlinks across the WSL boundary and is slow, so whichever method is used, downloads and media should share one filesystem inside WSL2 or on a single mounted drive (TRaSH folder structure). rclone/FUSE mounts for debrid need `--privileged` or `/dev/fuse` inside WSL2, which is a known friction point. Decypharr's SMB/NFS export may sidestep it.
- Torrents on Windows Docker need a VPN container (e.g. gluetun) with qBittorrent routed through it, plus port-forwarding support from the VPN provider.

### Gaps
- I did not fetch the Servarr wiki or TRaSH Guides pages on Docker on Windows or WSL2 hardlinks, so the Windows-specific points above are inferences, not citations.

## What power users in r/selfhosted, r/usenet, r/sonarr recommend in 2025-2026 and why

### Takeaway
I could not retrieve actual 2025-2026 Reddit threads. Long-standing community consensus, plus 2026 vendor and blog commentary, suggests Usenet (with private trackers for gaps) is still the arr power-user default. Debrid is popular for streaming setups but lost trust after Real-Debrid's May 2026 filter.

### Cited Findings
- Common pattern: "Usenet is great for popular content. Private trackers for everything else." Usenet for new TV and films, and private trackers or a seedbox for older or niche content — [AnandTech forum](https://forums.anandtech.com/threads/who-still-uses-usenet.2269479/page-7) (older)
- 2026: "many users have migrated to Torbox in search of greater consistency" after Real-Debrid's changes — [corelab](https://corelab.tech/decypharr-setup-guide/)
- Deal-site commenters point people to r/usenet for current deals and recommendations — [Slickdeals BF 2025](https://slickdeals.net/f/18745579-black-friday-usenet-deals-2025-25-05)

### Inferences
- The recommendation for this user: Usenet first (two backbones and two indexers, bought on Black Friday 2026), with qBittorrent and public trackers via Prowlarr as a fallback for misses. Debrid (TorBox) only if instant availability matters more than control.
- Timing: 2026 Black Friday Usenet deals typically start about a week before 27 Nov 2026, so buying then cuts first-year cost by about 60-70% versus list price.

### Gaps
- I found no 2025-2026 r/selfhosted, r/usenet or r/sonarr threads through search, and Reddit was not fetched directly. The sentiment above is inferred and not quoted from those communities.
