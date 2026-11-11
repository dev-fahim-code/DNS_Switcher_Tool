```
░█▀▀▄ ░█▄─░█ ░█▀▀▀█    ░█▀▀▀█ ░█──░█ ▀█▀ ▀▀█▀▀ ░█▀▀█ ░█─░█ ░█▀▀▀ ░█▀▀█
░█─░█ ░█░█░█ ─▀▀▀▄▄    ─▀▀▀▄▄ ░█░█░█ ░█─ ─░█── ░█─── ░█▀▀█ ░█▀▀▀ ░█▄▄▀
░█▄▄▀ ░█──▀█ ░█▄▄▄█    ░█▄▄▄█ ░█▄▀▄█ ▄█▄ ─░█── ░█▄▄█ ░█─░█ ░█▄▄▄ ░█─░█
```

# DNS Switcher Tool

A small, menu-driven **PowerShell tool for Windows** that switches your DNS servers with one keypress, backs up your settings first, and measures which DNS provider is actually fastest for *your* connection with a real **45-second ping test**.

No installer, no dependencies, no network access except the tests described below. Everything is plain text you can read before you run it.

## Features

- Switch DNS to **Cloudflare, Google, AdGuard, Quad9, OpenDNS or Cloudflare Family** (IPv4 and IPv6)
- **Automatic backup** of your current DNS before every change
- **Restore** any saved backup, or **reset to automatic** (DHCP/default)
- **Real ping benchmark (about 45 seconds):** ICMP ping and DNS reply time to every provider at the same moments, with average / min / max / jitter / packet loss, then a ranked table
- Quick **connection check** to tell a DNS problem from an internet problem
- Flush the Windows DNS cache
- Works per adapter (Wi-Fi, Ethernet, ...): only the adapter you pick is changed

## Requirements

- Windows 10 or 11
- Windows PowerShell 5.1 (already included in Windows)
- An administrator account (Windows will show a UAC prompt, because changing DNS needs it)

## Quick start

1. Download the project: **Code → Download ZIP**, then extract it. Do not run it from inside the ZIP.
2. Keep `Run-DNS-Switcher.bat` and `DNS-Switcher.ps1` **in the same folder**.
3. Double-click **`Run-DNS-Switcher.bat`** and click **Yes** on the administrator prompt.
4. Choose your network adapter (the one marked `[Up]` that you use for internet).
5. Type a menu number and press Enter.

**Prefer git?** Clone the repository instead of downloading the ZIP:

```
git clone https://github.com/dev-fahim-code/DNS_Switcher_Tool.git
cd DNS_Switcher_Tool
.\Run-DNS-Switcher.bat
```

To get later updates, run `git pull` inside that folder.

A typical session:

1. Option **7**: run the ping benchmark and see which provider is fastest for you.
2. Options **1-6**: switch to that provider (a backup is saved automatically first).
3. Option **8**: confirm DNS and internet still work.
4. Something wrong? Option **10** restores your backup, option **11** returns to automatic DNS.

## Menu

| # | Action |
|---|--------|
| 1-6 | Switch to a DNS provider (backs up first) |
| 7 | Real ping benchmark (about 45 seconds) |
| 8 | Test current DNS / internet connection |
| 9 | Save a DNS backup now |
| 10 | Restore a DNS backup |
| 11 | Reset DNS to automatic (backs up first) |
| 12 | Flush DNS cache |
| 13 | Change network adapter |
| 14 | Exit |

## Providers

| Provider | IPv4 | Notes |
|----------|------|-------|
| Cloudflare | 1.1.1.1, 1.0.0.1 | Fast public resolver |
| Google Public DNS | 8.8.8.8, 8.8.4.4 | General purpose |
| AdGuard DNS | 94.140.14.14, 94.140.15.15 | Blocks many ads and trackers |
| Quad9 | 9.9.9.9, 149.112.112.112 | Security-focused |
| OpenDNS | 208.67.222.222, 208.67.220.220 | Cisco public resolver |
| Cloudflare Family | 1.1.1.3, 1.0.0.3 | Blocks malware and adult content |

Each provider's IPv6 resolvers are set too. Providers are listed in the `$script:Providers` table at the top of `DNS-Switcher.ps1` if you want to add your own.

## How the ping benchmark works

Option 7 starts one worker per resolver (plus your *current* DNS if it is not one of the providers above, so you can compare against your ISP or router). For the whole 45 seconds, every worker sends **one ICMP ping and one real DNS query per second**. All resolvers are measured at the same time, so they face the same network conditions.

- **Avg / Min / Max / Jitter**: ICMP ping time in milliseconds
- **Loss%**: percentage of pings with no reply
- **DNS**: median time for a real UDP DNS answer, in milliseconds
- **Ranking**: lowest average ping wins, with +5 ms added per 1% packet loss. If a resolver ignores ICMP (`blocked`), its DNS reply time is used instead.

For the most accurate result, pause downloads and streaming while it runs. Ping measures the distance to the resolver, **not** website speed. Public resolvers use anycast, so results depend on your ISP's routing and can change during the day. The test length is `$script:BenchmarkSeconds` in the script (default 45).

## Using it safely

This tool changes network settings, so a few habits are worth following.

**Get it from a trusted place**
- Download only from this repository. Do not run copies from other sites, chats or file-sharing links.
- It is a plain-text script: open `DNS-Switcher.ps1` in Notepad and read it before running. Anything that asks you to run an obfuscated or "compiled" version of a DNS tool is a red flag.
- To confirm your copy was not altered, compare its hash with the one in the release notes (if published):
  `Get-FileHash .\DNS-Switcher.ps1 -Algorithm SHA256`
- The script is not code-signed, so SmartScreen or antivirus may show a warning for an unknown script. That is expected for unsigned scripts; use the hash check above if in doubt.

**What it does and does not do**
- It changes **only the DNS servers** of the one adapter you select, and flushes the DNS cache.
- It writes backups to a `DNS-Backups` folder next to the script.
- Its only network traffic is the tests you start yourself: pings and DNS queries to the resolver addresses listed above, a DNS lookup of `example.com`, and a TCP connection test to `1.1.1.1:443`.
- It has no telemetry, does not download anything and does not send your data anywhere.
- `Run-DNS-Switcher.bat` starts PowerShell with `-ExecutionPolicy Bypass` **for that one process only**. It does not change your system's execution policy.

**Before you switch**
- Check the adapter shown in the header is the one you actually use for internet.
- If you use a **VPN**, note that VPN software often sets its own DNS and may override or conflict with this tool. Disconnect it for the benchmark.
- Do not use it on a **work or school PC** where DNS is managed by your organisation.
- Remember that your DNS provider can see which domain names you look up. Pick a provider whose privacy policy you are comfortable with. Filtering providers (AdGuard, Cloudflare Family) will intentionally block some sites.

**After you switch**
- Run option **8** to confirm DNS and internet still work.
- If anything is wrong, use option **10** (restore your backup) or option **11** (reset to automatic). Both work even if the new DNS is not responding.

## Backups

- A backup is saved automatically before every provider switch and before a reset to automatic. Option 9 saves one on demand.
- Files are stored as `DNS-Backups/DNS-<adapter-guid>-<date>-<time>.json`.
- A backup remembers, separately for IPv4 and IPv6, whether the adapter used **static** DNS servers or **automatic** DNS, and restores exactly that.
- Restoring a backup does not create a new backup of your current settings first. If you want to keep them, use option 9 before restoring.
- Backups contain your adapter ID and DNS settings. **Do not publish them.** The included `.gitignore` keeps the `DNS-Backups` folder out of Git.

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| "Running scripts is disabled" | Start it with `Run-DNS-Switcher.bat`, not by double-clicking the `.ps1` |
| Nothing happens after the UAC prompt | The tool opens in a new elevated window; check your taskbar |
| Banner shows odd symbols | Use a font with block characters (Consolas or Cascadia). Right-click the window title → Properties → Font |
| Benchmark shows `blocked` | That resolver or your network drops ICMP ping; its DNS time is used for ranking instead |
| Benchmark shows no replies at all | Check your connection, VPN or firewall (ICMP and UDP port 53 must be allowed) |
| Wrong DNS still used | Run option 12 (flush cache). Some VPNs and browsers with "secure DNS" ignore the Windows setting |
| Want to undo everything | Option 11 resets the adapter to automatic DNS |

## Project files

| File | Purpose |
|------|---------|
| `DNS-Switcher.ps1` | The tool |
| `Run-DNS-Switcher.bat` | Launcher (checks the script exists, starts PowerShell) |
| `.gitignore` | Keeps `DNS-Backups/` out of Git |
| `.gitattributes` | Keeps Windows line endings on `.ps1` and `.bat` files |

## Changelog

**v3.1**
- Now a PowerShell tool, replacing the earlier batch-script version (v0.3)
- Fixed: restoring a backup whose DNS was automatic always failed
- Fixed: choosing a provider without IPv6 left the previous IPv6 resolver active (all six providers now include IPv6)
- Fixed: unexpected errors closed the window before the message could be read
- Fixed: adapter selection on single-adapter systems
- Fixed: a damaged backup file could silently reset DNS
- Fixed: the connection test could hang for 20+ seconds
- New: real ICMP ping + UDP DNS benchmark, all resolvers in parallel, about 45 seconds
- New: ASCII-art banner

**v3.0**
- Initial version with provider switching, backups and a DNS lookup benchmark

## Disclaimer

This tool is provided as is, without warranty. You use it at your own risk; always keep a backup. It is not affiliated with Cloudflare, Google, AdGuard, Quad9 or Cisco/OpenDNS.
