# Watch While Downloading: Near-Instant Playback in Self-Hosted Arr Stacks (as of Oct 2026)

Legal note: these tools are content-neutral. Downloading or streaming copyrighted material without permission is illegal in most jurisdictions, including South Africa (Copyright Act 98 of 1978). Several projects below say they are for legally obtained content only ([nzbdav README](https://github.com/nzbdav-dev/nzbdav)).

Source quality note: many of the 2025-2026 sources are vendor pages from ElfHosted (a paid host of these tools) or single-author blogs (corelab.tech). Treat their claims as practitioner reports, not independent verification.

## qBittorrent sequential download + "first and last pieces first"

### Takeaway
Sequential mode plus first/last-piece priority lets a player open and play a partial file in the download folder, as long as download speed stays above the video bitrate. It works outside Sonarr/Radarr and Jellyfin's normal import flow, it is fragile with multi-file torrents and slow swarms, and it makes the swarm less healthy.

### Cited Findings
- Mechanism: in sequential mode qBittorrent requests pieces in file order instead of rarest-first. "First and last piece first" matters because container metadata (for example the MP4 moov atom or the MKV index) is often at the end of the file, and a player may not open the file until that piece arrives — [qBittorrent forum](https://forum.qbittorrent.org/viewtopic.php?p=21439); [qBittorrent forum](https://forum.qbittorrent.org/viewtopic.php?p=21452)
- In a 2015 bug (qBittorrent 3.x), sequential mode did not fetch the first pieces and previews failed. Enabling only "download first and last piece first" worked, and the bug was fixed in 3.2.1. This is pre-2024 history — [Arch bug FS#44998](https://bugs.archlinux.org/task/44998)
- Multi-file torrents (season packs): sequential works per file in order. To stream a specific episode, set the other files to "Do not download" or skip them. A file's last piece may be shared with the next file — [qBittorrent forum](https://forum.qbittorrent.org/viewtopic.php?p=23302); [qBittorrent forum](https://forum.qbittorrent.org/viewtopic.php?p=23345)
- Swarm health: sequential downloading makes later pieces rarer for other peers, and it fails if the available peers are slow. Rarest-first is the default because it spreads pieces across the swarm — [qBittorrent forum](https://forum.qbittorrent.org/viewtopic.php?p=21439)
- Playback in Jellyfin: one user reports opening a sequentially downloading .mkv in Jellyfin before it finished. Playback continued while the download stayed ahead of the playhead — [Lemmy thread](https://lemmy.imagisphe.re/post/817767)
- qBittorrent has no built-in streaming or HLS server. A fork that added streaming was not merged because of architectural objections — [qBittorrent GitHub discussion #17479](https://github.com/qbittorrent/qBittorrent/discussions/17479)
- Windows file locking: Sonarr on Windows reports "file already in use by another process" when another program holds the file. Reported culprits include Explorer windows open on the folder, unpack tools, and ffmpeg — [Sonarr forum](https://forums.sonarr.tv/t/couldnt-import-episode-file-already-in-use-by-another-process/22068); [Sonarr forum](https://forums.sonarr.tv/t/moving-torrents-from-local-drive-to-nas/18380) (both threads are older than 2024)

### Inferences
- To make this work, add a separate Jellyfin library pointed at the qBittorrent incomplete or download folder (for example a "Downloading" library). The partial file then shows up only after a library scan. Sonarr/Radarr do nothing until the download completes.
- If Jellyfin is reading or transcoding a file when the download finishes, Sonarr's import (move or hardlink) can hit a lock on Windows. In Docker Desktop the files live on a Linux filesystem (WSL2 VHDX) or a 9P-shared Windows path, and lock behaviour may differ. Hardlinks plus "copy, don't move" reduce the risk.
- Many private trackers frown on sequential downloading because of its effect on the swarm. Public swarms are hurt less in practice when they are large.

### Gaps
- No primary source found on whether qBittorrent on Windows opens files with sharing flags that allow concurrent reads. Anecdotally reads work, but this is unverified.
- No quantitative data found on how much sequential mode slows downloads or hurts swarm health.

## Why Sonarr/Radarr import only completed downloads, and surfacing in-progress files

### Takeaway
Completed Download Handling (CDH) polls the download client's API and imports only when the client flags the job as complete. No setting in Sonarr/Radarr imports partial files. Partial files reach Jellyfin only through workarounds: a separate library on the download folder, or tools that present "completed" virtual files immediately (debrid and Usenet WebDAV tools, covered below).

### Cited Findings
- Sonarr tracks downloads through the download client API, so it knows what is still downloading and what is ready to import — [Sonarr forum](https://forums.sonarr.tv/t/question-on-expected-completed-download-handling-behavior/39539)
- "Sonarr will only start importing once the job is flagged as completed." It does not wait for further files to arrive — [Sonarr forum](https://forums.sonarr.tv/t/completed-download-handler-on-season-packs-only-picking-up-first-episode-or-two/22222)
- CDH is described as "the most reliable way to import stuff". Disabling it drops finished downloads from the queue — [Sonarr forum](https://forums.sonarr.tv/t/previous-download-handling/38907)
- For Usenet clients, the Arrs look only 60 items deep in the queue for potential imports — [Servarr wiki (Whisparr activity)](https://wiki.servarr.com/whisparr/activity)
- Decypharr and nzbdav get around this by reporting a download as "complete" to the Arr as soon as the content is available on the debrid or Usenet provider, then handing over symlinks or virtual files — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/); [nzbdav README](https://github.com/nzbdav-dev/nzbdav)

### Inferences
- The only ways to make the Jellyfin library entry appear before bytes are local are: (a) use a "virtual completion" download client (Decypharr, nzbdav, AltMount), or (b) use a Jellyfin plugin that resolves streams on demand (Gelato).

### Gaps
- The Servarr wiki pages (settings, FAQ) did not render through the fetch tool, so CDH documentation is quoted from Sonarr forum moderators, not the wiki itself.
- No tool found that imports genuinely in-progress torrent files into the Arr-managed library.

## Debrid streaming (Real-Debrid / TorBox / AllDebrid) and filesystem exposure

### Takeaway
Debrid services keep copies of popular torrents on their servers ("cached"). Adding a cached torrent completes instantly, and the file streams over HTTPS. Tools such as Decypharr, zurg + rclone, and Riven expose the debrid library as a FUSE/WebDAV filesystem. Sonarr/Radarr then import symlinks into it, so Jellyfin plays the file with near-instant start and nothing stored locally. The big caveats in 2026 are Real-Debrid's DMCA filtering, which has reduced what is cached, and FUSE mount propagation on Docker Desktop.

### Cited Findings
- Decypharr emulates a qBittorrent client. Sonarr/Radarr send it a release, it checks whether the release is cached at the debrid provider, mounts the cached files via WebDAV, and creates symlinks in a folder the Arrs treat as a completed download. Its own description: "a drop in replacement for Qbittorrent, that only searches Debrid source" — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/)
- Decypharr supports Real-Debrid, TorBox, AllDebrid, and DebridLink, with multiple providers at once. Mount options are rclone or DFS (Decypharr's own filesystem, recommended as "snappier"). The example Real-Debrid rate limit is 250 requests/minute. Leave "Download Uncached Files" off unless you want that behaviour — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/)
- Decypharr Docker requirements: image `cy01/blackhole:latest`, port 8282, `/dev/fuse`, `SYS_ADMIN`, `apparmor:unconfined`, the mount at `/mnt` with `rshared` propagation, and Arr containers mounting it with `rslave`. All containers need the same root path. Hardlinks don't work from FUSE, but symlinks do — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/)
- Operational caveats: no internet means no media. Uncached content is unavailable. Run repair workers roughly every 25 days. Mount problems cause I/O errors or ghost files. Disable Jellyfin intro detection, thumbnail extraction, and deep analysis to avoid hammering the debrid service — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/)
- Real-Debrid 2026 DMCA filtering: "infringing file" errors, filename exclusions, and removal of a significant amount of cached content. Some users moved to TorBox. Dates conflict: a search snippet showed an update dated 12 June 2026, but the fetched article showed 17 September 2026 — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/); [corelab unlimited streamer guide](https://corelab.tech/unlimitedstreamer/)
- ElfHosted's flow: Sonarr asks Decypharr, Decypharr adds the torrent to Real-Debrid and places it in the completed folder, Sonarr creates the library entry (a symlink), and Jellyfin plays the symlink, which resolves to the mounted file — [ElfHosted Jellyfin + RealDebrid + Arrs guide](https://docs.elfhosted.com/guides/media/jellyfin-realdebrid-aars)
- Zurg applies regex rules to a Real-Debrid library and serves it as WebDAV, which rclone mounts — [ElfHosted zurg docs](https://docs.elfhosted.com/app/zurg). CineSync can build symlink trees from a zurg mount for Jellyfin — [ElfHosted CineSync](https://store.elfhosted.com/product/cinesync/)
- Zurg on native Windows needs WinFsp and the rclone `--links` flag. The mount belongs to the Windows session that started it — [zurg WINDOWS.md](https://raw.githubusercontent.com/debridmediamanager/zurg-public/HEAD/WINDOWS.md)
- Riven: the older architecture watched zurg's `__all__` folder and created symlinks. Current docs describe RivenVFS, a FUSE virtual filesystem that Plex, Jellyfin, or Emby scan and stream from directly, never downloading locally. Supported providers are Real-Debrid, AllDebrid, and Debrid-Link — [ElfHosted Emby + Riven guide](https://docs.elfhosted.com/guides/media/emby-realdebrid-riven); [Riven docs (mintlify mirror)](https://mintlify.wiki/rivenmedia/riven/introduction)
- Riven integrates with request tools (Overseerr, Jellyseerr, Seerr) — [deuts.org](https://deuts.org/x/802-seerr)
- rdt-client also emulates qBittorrent for Real-Debrid. No 2026 source was fetched for it (see Gaps)

### Inferences
- Debrid makes "watch while downloading" moot. For cached items, the "download" completes in seconds and the stream is read on demand through the mount.
- Playback quality depends on the international bandwidth from South Africa to the debrid CDN (mostly EU-hosted for Real-Debrid). High-bitrate 4K remux may buffer on slower SA fibre lines.

### Gaps
- No current README fetched for rdt-client, or for TorBox's own WebDAV/mount offering.
- The exact date of Real-Debrid's filtering change is unresolved (June vs September 2026).

## Stremio + Torrentio/debrid direct streaming, and Jellyfin/Jellyseerr integration

### Takeaway
Stremio addons (Torrentio, Comet, AIOStreams) resolve debrid or torrent streams on demand, with no library or Arr involved. Since 2025-2026 they can be brought into Jellyfin through the Gelato plugin, which needs AIOStreams as its backend. That gives Jellyfin clients search and catalog access to on-demand streams. This sits beside or replaces the Arr flow and is not a Jellyseerr integration.

### Cited Findings
- Gelato is a Jellyfin plugin that replaces Jellyfin's search with Stremio-addon results and can import whole catalogs through scheduled tasks. Streams resolve on demand. Upstream it supports Jellyfin 10.11. It needs a TMDB addon plus a stream addon (Comet given as the example) — [Gelato GitHub (mirror)](https://scour.ing/p/https://github.com/lostb1t/Gelato); [JellyWatch 2026 guide](https://jellywatch.app/blog/jellyfin-gelato-stremio-integration-plugin-2026)
- ElfHosted says Gelato "only works with AIOStreams as its backend". A working setup needs a debrid and/or Usenet account. Jellyfin 12 support arrived in Gelato v0.26.17.0 via ElfHosted's repo. Plugins can lag after major Jellyfin releases — [ElfHosted: Stremio addons in Jellyfin](https://docs.elfhosted.com/guides/media/stremio-addons-in-jellyfin/)
- The Gelato author now points to Remux, a Rust media server designed to replace Jellyfin entirely — [Gelato GitHub (mirror)](https://scour.ing/p/https://github.com/lostb1t/Gelato)
- Jellio and stremio-jellyfin go the other way, exposing a Jellyfin library inside Stremio — [ElfHosted](https://docs.elfhosted.com/guides/media/stremio-addons-in-jellyfin/)
- Direct-play setups (JellyStreams, Remux) do not transcode, so the client must decode the format natively. Browsers may need H.264 releases — [ElfHosted](https://docs.elfhosted.com/guides/media/stremio-addons-in-jellyfin/)
- Clients tested with Gelato include Infuse, Swiftfin, Streamyfin-class apps, and the official Jellyfin Android, Android TV, Fire TV, and web apps — [ElfHosted](https://docs.elfhosted.com/guides/media/stremio-addons-in-jellyfin/)
- nzbdav's docs include Stremio use via AIOStreams, which streams Usenet into Stremio — [nzbdav README](https://github.com/nzbdav-dev/nzbdav)

### Inferences
- Torrentio without debrid streams over P2P from the user's own IP, with the same exposure as torrenting. With debrid, the debrid server does the P2P.
- Jellyseerr works with the Arr or Decypharr path, not with Gelato's on-demand path.

### Gaps
- No source confirmed Torrentio as a Gelato stream source (only Comet and AIOStreams are documented).

## Usenet: speed, and NZB streaming tools (nzbdav, AltMount)

### Takeaway
With a good provider, Usenet often runs near line speed, so on a fast connection an episode finishes in minutes and streaming while downloading is mostly unnecessary. nzbdav and AltMount go further: they present NZB contents as a WebDAV/FUSE filesystem and stream articles from the provider on demand. nzbdav also exposes a SABnzbd-compatible API, so Sonarr/Radarr "complete" immediately.

### Cited Findings
- Speed is provider- and route-dependent. A Feb 2025 r/usenet user on 1 Gbps fibre in Australia got about 65 MB/s from one provider and about 110 MB/s after switching to one with a closer server — [r/usenet mirror](https://reddit.sudovanilla.org/1iy5ybc)
- A user on a ~900 Mb/s line plateaued at ~42 MB/s in SABnzbd, while torrents reached ~80 MB/s — [SABnzbd forum](https://forums.sabnzbd.org/viewtopic.php?p=129591)
- Extreme case: ~1.1 GB/s using 10 Gbps fibre, RAM disks, and NVMe RAID. Not representative — [Jawbreaker](https://jawbreaker.transistor.fm/episodes/unleashing-speed-usenet-to-plex-in-under-two-minutes)
- nzbdav: "Usenet streaming with a WebDAV server and a SABnzbd-compatible API." It presents NZBs as a virtual filesystem, streams with seeking, reads inside RAR and 7z archives (including password-protected ones), runs health checks, and repairs content removed from the provider. Docker image `nzbdav/nzbdav`, port 3000, with an rclone sidecar in the compose guide — [nzbdav README](https://github.com/nzbdav-dev/nzbdav)
- nzbdav status: the README says the project "is no longer maintained" and points to community forks. Versions 0.2.46 to 0.6.1 had an auth-bypass vulnerability, reported 2026-03-17. Patched images carry the `+260317` suffix — [nzbdav README](https://github.com/nzbdav-dev/nzbdav). InfiniDysk is listed as the renamed nzbdav "SuperFork", with a SABnzbd-compatible API — [Brandfetch listing](https://brandfetch.com/infinidysk.com.md) (low-quality source)
- AltMount: "A WebDAV server backed by NZB/Usenet". Go project (MIT), image `ghcr.io/kipsilabs/altmount:latest`, port 8080, `/dev/fuse` + `SYS_ADMIN` in compose. Optional external rclone. Windows notes mention enabling long paths — [AltMount GitHub](https://github.com/javi11/altmount); [pkg.go.dev](https://pkg.go.dev/github.com/kipsilabs/altmount)
- Decypharr's author planned a Usenet backstop "coming very soon" (Sept 2026) — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/)

### Inferences
- SA context: international bandwidth and distance to EU/US Usenet servers will likely cap speeds below line rate. The Australian example is analogous.
- Usenet streaming tools need many provider connections and good per-connection throughput, because they fetch articles live during playback.

### Gaps
- The AltMount README fetched did not document a SABnzbd API or Arr integration. Whether it has one is unconfirmed.
- No reliable source found for typical per-episode Usenet download times.

## Jellyfin specifics: scanning and transcoding partial or growing files

### Takeaway
Jellyfin's real-time monitoring uses inotify and triggers a scan when files change. It does not work over network shares (SMB/NFS) and is unreliable across Docker Desktop's Windows-to-WSL2 file sharing, so scheduled or Arr-triggered scans are the norm. Playing a growing file works only while the download stays ahead of the playhead. No source documents how Jellyfin handles seeking past the downloaded point.

### Cited Findings
- Real-time monitoring relies on inotify. It doesn't work over network shares, and moderators advise disabling it for NFS/SMB. On unsupported shares Jellyfin can fall back to constant polling — [Jellyfin forum](https://forum.jellyfin.org/t-solved-real-time-monitoring-not-working-on-some-libraries)
- Each watched file uses an inotify watcher. Exceeding the watcher limit breaks monitoring for the remaining files. The default library scan runs every 12 hours (Dashboard > Scheduled Tasks) — [Jellyfin forum](https://forum.jellyfin.org/t-new-elements-not-automatically-scanned-recognized-why)
- Docker's WSL2 docs say Linux containers receive file change events only when the files are stored in the Linux filesystem, not on the Windows host via bind mount — [Docker forum / WSL2 docs summary](https://forums.docker.com/t/volumes-bind-mounts-of-windows-directories-appears-to-be-broken-in-docker-desktop-wsl2-integration/97167)
- Jellyfin 10.11.0 had reports of full scans stalling at 65-85% — [Jellyfin forum](https://forum.jellyfin.org/t-jellyfin-scan-never-finishes-in-10-11-00?pid=65867)
- Debrid and Usenet mounts: disable intro detection, trickplay/thumbnail extraction, and deep analysis, to avoid reading whole files through the mount — [corelab Decypharr guide](https://corelab.tech/decypharr-setup-guide/)
- Growing-file playback works while the download outpaces playback — [Lemmy thread](https://lemmy.imagisphe.re/post/817767)

### Inferences
- When Jellyfin probes a partial file, ffprobe may record the wrong duration or treat the file as broken, and that metadata may persist until a refresh. Do a "Refresh metadata" after completion.
- Transcoding a growing file: ffmpeg reads sequentially, so it can work. Seeking beyond the downloaded point will likely stall or fail.

### Gaps
- No Jellyfin documentation found on partial-file handling or transcoding growing files.

## Windows 11 Home + Docker Desktop (WSL2) compatibility

### Takeaway
Plain qBittorrent sequential download and Usenet clients work fine on Docker Desktop. Docker Desktop is the weak point for FUSE-based tools (Decypharr, zurg/rclone, Riven, nzbdav/AltMount mounts) because sharing a FUSE mount between containers needs `rshared`/`rslave` propagation, which Docker Desktop does not support reliably. Workarounds: run the rclone mount and the consumers inside one container, run zurg/rclone natively on Windows with WinFsp, or run Docker Engine directly inside a WSL2 distro instead of Docker Desktop.

### Cited Findings
- pd_zurg says "Docker Desktop CANNOT be used to run pd_zurg", because Docker Desktop doesn't support the mount propagation required for rclone mounts. It points Windows users to WSL2-based alternatives — [pd_zurg GitHub](https://github.com/I-am-PUID-0/pd_zurg)
- Docker Desktop 3.3.2 with WSL2 (May 2021): an rshared FUSE mount was visible inside the container but empty on the host. Without WSL2 the error was "not a shared mount". No resolution was posted. Pre-2024, possibly outdated — [Docker forum](https://forums.docker.com/t/make-mount-point-accesible-from-container-to-host-rshared-not-working/108759)
- Remounted or new FUSE mounts on a host aren't propagated to running containers unless the bind uses `rslave`/`rshared`. Start the mount container first. It needs `SYS_ADMIN`, `/dev/fuse`, and `apparmor:unconfined` (Linux-host reports) — [rclone forum](https://forum.rclone.org/t/propogating-rclone-mounts-to-docker-containers-without-transport-endpoint-going-stale/48112); [rclone forum](https://forum.rclone.org/t/docker-fuse-and-host-mounted-rclone/4735)
- An rclone mount made on Windows as a drive letter was not reachable from WSL2 or Docker containers — [rclone forum](https://forum.rclone.org/t/mapping-to-rclone-mount-from-within-windows-docker-desktop-containers/33002)
- `--allow-other` does nothing on Windows. Native Windows mounts need WinFsp — [rclone forum](https://forum.rclone.org/t/rclone-mount-in-windows-docker/22595); [zurg WINDOWS.md](https://raw.githubusercontent.com/debridmediamanager/zurg-public/HEAD/WINDOWS.md)
- Docker recommends keeping bind-mounted data in the Linux filesystem for performance and file-change events — [Docker forum](https://forums.docker.com/t/volumes-bind-mounts-of-windows-directories-appears-to-be-broken-in-docker-desktop-wsl2-integration/97167)

### Inferences
- Compatibility summary for this user's setup:
  - qBittorrent sequential plus a separate Jellyfin "downloading" library: works.
  - SABnzbd/NZBGet: works. Store data on the WSL2 ext4 filesystem or a dedicated drive for speed.
  - Gelato/AIOStreams: works, because it uses HTTP streams and no FUSE.
  - Decypharr, zurg + rclone, Riven, nzbdav, AltMount with an rclone mount shared to Jellyfin and the Arrs: likely to break under Docker Desktop. Feasible options are native Windows rclone/WinFsp with Jellyfin also native, or Docker Engine installed inside an Ubuntu WSL2 distro.
- nzbdav and Decypharr also serve WebDAV over HTTP. In principle Jellyfin can't scan WebDAV directly, so a mount is still needed.
- Windows 11 Home has no Hyper-V Manager, but WSL2 works, so Docker Desktop on the WSL2 backend is supported.

### Gaps
- No 2025-2026 official Docker statement found on bind-propagation support in current Docker Desktop releases.
- No first-hand report found of Decypharr or nzbdav running on Docker Desktop for Windows.
