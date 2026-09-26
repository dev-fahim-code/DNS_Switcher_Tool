# DNS_Switcher_Tool

A lightweight, interactive Windows batch script for quickly switching your DNS servers between popular public DNS providers, running latency tests, and resetting back to automatic (DHCP) — all from a simple colored console menu.

**GitHub**: https://github.com/dev-fahim-code

## Features

- 🔒 **Auto-elevation** — automatically requests Administrator privileges via UAC (required to modify network settings)
- 🌐 **Smart adapter detection** — auto-detects active network adapters (Wi-Fi, Ethernet, Other) with manual selection fallback
- ⚡ **One-click DNS switching** — instantly apply DNS settings for 4 popular providers, configured for both IPv4 and IPv6
- 📊 **Built-in ping test** — compare latency across all DNS providers to find the fastest option
- ↩️ **Easy reset** — restore automatic, DHCP-assigned DNS with a single command
- 🛠️ **Full network reset** — one-step Winsock reset, TCP/IP stack repair, IP release/renew, and DNS flush for deeper connectivity issues
- 🎨 **Simple colored console UI** — red text on black background, no installation or dependencies required
- ✅ **Result checking** — every DNS/reset operation verifies each `netsh` call actually succeeded and warns you instead of always claiming success
- ✅ **Minimal footprint** — DNS changes are applied live via `netsh` and can be reset anytime (see [Safety & Reversibility](#safety--reversibility) for the one exception)

## Supported DNS Providers

| # | Provider | IPv4 Primary | IPv4 Secondary | IPv6 Primary | IPv6 Secondary | Best For |
|---|----------|--------------|---|---|---|----------|
| 1 | **Cloudflare** | `1.1.1.1` | `1.0.0.1` | `2606:4700:4700::1111` | `2606:4700:4700::1001` | Gaming & Speed |
| 2 | **Google Public DNS** | `8.8.8.8` | `8.8.4.4` | `2001:4860:4860::8888` | `2001:4860:4860::8844` | General Stability & Routing |
| 3 | **AdGuard DNS** | `94.140.14.14` | `94.140.15.15` | `2a10:50c0::ad1:ff` | `2a10:50c0::ad2:ff` | Blocking Ads & Trackers |
| 4 | **Quad9** | `9.9.9.9` | `149.112.112.112` | `2620:fe::fe` | `2620:fe::9` | Security & Threat Prevention |

## Requirements

- **Windows 10 or 11**
- **Administrator privileges** — the script automatically requests elevation via UAC on startup
- **Network adapter** — at least one active (Connected) network interface

## Quick Start

### Installation

1. Download `dns-tool.bat` from this repository
2. Save it to a convenient location (e.g., Desktop, Documents, or a Scripts folder)
3. Double-click to run, or execute from Command Prompt

### First Run

When you launch the script:

1. **UAC Prompt** — Accept the Administrator access request. If you decline it, the script now shows a message explaining that Administrator rights are required, instead of just closing silently.
2. **Adapter Detection** — The script scans for active network adapters and displays them classified by type:
   - **[Ethernet]** — wired connections (detected via "Ethernet" or "LAN" in name)
   - **[Wi-Fi]** — wireless connections (detected via "Wi-Fi", "Wireless", or "WLAN" in name)
   - **[Other]** — any other adapter type
3. **Select Adapter** — Choose your preferred adapter (e.g., enter `1` for the first option)
4. **Main Menu** — The interactive menu appears with your selected adapter in the header

## Screenshots

### Main Menu with Active Adapter Detection

Shows the interactive menu with detected network adapter (Ethernet) and current DNS configuration for both IPv4 and IPv6.

![Main Menu Screenshot](https://github.com/dev-fahim-code/DNS_Switcher_Tool/blob/main/main-menu.png)

### Ping Test Results

Displays latency comparison across all DNS providers to help you choose the fastest option.

![Ping Test Screenshot](https://github.com/dev-fahim-code/DNS_Switcher_Tool/blob/main/ping-test.png)

## Menu Options

```
==========================================================
              DNS_Switcher_Tool(v_0.3)
             https://github.com/dev-fahim-code
==========================================================

Active Network Adapter: [Your Adapter Name]

Currently Active DNS on [Your Adapter Name]
IPv4:
  ...
IPv6:
  ...

1. Cloudflare DNS (Best for Gaming & Speed)
2. Google Public DNS (Best for General Stability & Routing)
3. AdGuard DNS (Best for Blocking Ads & Trackers)
4. Quad9 DNS (Best for Security & Threat Prevention)
5. Ping Test All DNS Servers
6. Change Network Adapter
7. Reset DNS to Automatic (DHCP)
8. Full Network Reset (Winsock, TCP/IP, IP Release/Renew, Flush DNS)
9. Exit
```

### Option 1-4: Apply DNS

Select a DNS provider to immediately apply both IPv4 and IPv6 servers to your active adapter:

- Sends both primary and secondary DNS servers
- Applies to the currently selected network adapter only
- Takes effect immediately (no restart needed)
- Verifies each of the four `netsh` calls (IPv4 primary/secondary, IPv6 primary/secondary) actually succeeded — if any of them fail, you'll see a warning instead of a false "successfully changed" message
- Displays the new DNS configuration after applying
- Press any key to return to menu

**Example: Choosing Option 1 (Cloudflare) — success case**
```
Applying Cloudflare DNS...
DNS successfully changed to Cloudflare!

Currently Active DNS on [Ethernet]
IPv4:
  1.1.1.1
  1.0.0.1
IPv6:
  2606:4700:4700::1111
  2606:4700:4700::1001
```

**Example: something failed (e.g. stale adapter name)**
```
Applying Cloudflare DNS...

WARNING: One or more DNS entries may not have applied. Verify the
adapter name below is still correct and check the results.

Currently Active DNS on [Wi-Fi]
IPv4:
  ...
```

### Option 5: Ping Test All DNS Servers

Runs a latency test against all 4 DNS providers using `ping -n 4` (4 ICMP packets):

- **Output**: Shows average round-trip time (RTT) in milliseconds for each provider
- **Interpretation**: Lower average = faster DNS lookups for your location
- **Failures**: Shows "Request timed out or host unreachable" if the DNS server is unreachable
- **Use case**: Run before choosing a DNS provider to pick the fastest one for your network
- **Note**: this measures raw ICMP ping time to each provider's IP, which is a good proxy for but not identical to actual DNS query response time

**Example Output:**
```
==========================================================
                  Running Ping Tests
==========================================================

Pinging Cloudflare (1.1.1.1)...
    Average =23ms

Pinging Google (8.8.8.8)...
    Average =28ms

Pinging AdGuard (94.140.14.14)...
    Average =45ms

Pinging Quad9 (9.9.9.9)...
    Average =35ms

==========================================================
Ping test complete. Lower average time is better.
```

### Option 6: Change Network Adapter

Re-runs adapter detection and lets you switch to a different adapter:

- Rescans all connected adapters
- Re-classifies them (Ethernet, Wi-Fi, Other)
- Presents the selection menu again
- Future DNS changes will apply to the newly selected adapter
- If no adapters are detected, the tool falls back to guessing "Wi-Fi" as the adapter name and now explicitly warns you that this may not match your real adapter

### Option 7: Reset DNS to Automatic (DHCP)

Restores your adapter to automatically assigned (DHCP) DNS servers:

- Resets both IPv4 and IPv6 to DHCP
- Takes effect immediately
- Verifies both `netsh` calls succeeded and warns if either did not
- Useful if you want to go back to your ISP's DNS or if you experience issues
- Displays current DNS after reset

### Option 8: Full Network Reset

Runs a deeper repair sequence for connectivity issues that a simple DNS change won't fix — for example, when the network stack itself is misbehaving rather than just DNS resolution. Unlike Options 1-7, **this affects the whole machine, not just the selected adapter.** It does **not** reset or reinstall the network adapter driver itself — see [Limitations](#limitations).

Steps performed, in order:

1. `netsh winsock reset` — resets the Winsock catalog (fixes many "can't connect" failures)
2. `netsh int ip reset` — repairs the TCP/IP stack
3. `ipconfig /release` — drops the current IP lease
4. `ipconfig /renew` — requests a new IP lease
5. `ipconfig /flushdns` — clears the local DNS resolver cache

- You're asked to confirm (`Y/N`) before anything runs
- Your network connection will drop briefly during the process
- After completion, you're prompted to restart immediately (`shutdown /r /t 10`, cancelable with `Ctrl+C`) or restart manually later — **a restart is strongly recommended** so the Winsock and TCP/IP changes fully take effect
- See [Safety & Reversibility](#safety--reversibility) below for what makes this option different from the rest of the tool

**Example Output:**
```
==========================================================
                 Full Network Reset
==========================================================

This will run, in order:
  1. netsh winsock reset      (fix connection failures)
  2. netsh int ip reset       (repair TCP/IP stack)
  3. ipconfig /release        (drop current IP)
  4. ipconfig /renew          (request new IP)
  5. ipconfig /flushdns       (clear DNS cache)

Your network connection will drop briefly during this
process. A RESTART is recommended afterward so the
Winsock and TCP/IP changes fully take effect.

Proceed with Full Network Reset? (Y/N): y

[1/5] Resetting Winsock catalog...
[2/5] Resetting TCP/IP stack...
[3/5] Releasing current IP address...
[4/5] Renewing IP address...
[5/5] Flushing DNS resolver cache...

Full network reset complete!

----------------------------------------------------------
 A RESTART is strongly recommended now so the Winsock
 and TCP/IP changes fully apply.
----------------------------------------------------------

Restart the PC now? (Y/N):
```

### Option 9: Exit

Closes the script cleanly.

---

## How It Works

### 1. Admin Check & Elevation

The script starts by checking if it's running with Administrator privileges:

```batch
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if !errorlevel! neq 0 (
        echo Elevation was cancelled or failed. This tool requires Administrator rights to run.
        pause
    )
    exit /b
)
```

If not admin, it relaunches itself via PowerShell with the `RunAs` verb, triggering the UAC prompt. If the user denies the prompt, PowerShell's `Start-Process` throws, the `catch` block sets a non-zero exit code, and the script surfaces a clear message before closing instead of exiting silently.

### 2. Adapter Detection (`:EnumerateAdapters`)

Queries all connected network adapters using `netsh`:

```batch
netsh interface show interface | findstr /C:"Connected"
```

- Extracts adapter names from the output
- Stores them in indexed variables (`adapterName_1`, `adapterName_2`, etc.)
- Counts total adapters
- Relies on the English-language word "Connected" in `netsh`'s output — see [Limitations](#limitations)

### 3. Adapter Classification (`:ClassifyAdapters`)

Scans each adapter name for keywords:

- **Wi-Fi**: matches "Wi-Fi", "Wireless", or "WLAN" (case-insensitive)
- **Ethernet**: matches "Ethernet" or "LAN"
- **Other**: anything else

Organizes them into separate indexed arrays for organized menu display.

### 4. Adapter Selection (`:AdapterMenu`)

Presents a numbered list of adapters grouped by type:

```
1. [Ethernet]  Ethernet Connection
2. [Wi-Fi]     Wi-Fi
3. [Other]     VPN Adapter
```

User selects by number; the chosen adapter name is stored in the `%adapter%` variable for all subsequent operations. If no adapters are detected, the tool falls back to the literal name "Wi-Fi" and warns that this may not match the real adapter.

### 5. DNS Configuration

Each DNS option (1-4) performs the same pattern, and checks the result of every call:

**IPv4:**
```batch
netsh interface ipv4 set dnsservers name="%adapter%" static [PRIMARY] primary validate=no
netsh interface ipv4 add dnsservers name="%adapter%" [SECONDARY] index=2 validate=no
```

**IPv6:**
```batch
netsh interface ipv6 set dnsservers name="%adapter%" static [PRIMARY] validate=no
netsh interface ipv6 add dnsservers name="%adapter%" [SECONDARY] index=2 validate=no
```

- `set dnsservers` — replaces all existing DNS servers with the primary
- `add dnsservers` — appends the secondary server at index 2
- `validate=no` — skips reachability validation on **both IPv4 and IPv6** calls; without it on IPv6, `netsh` could prompt for confirmation if it couldn't verify reachability, which would appear to hang the script since output is suppressed
- Applies only to the selected adapter
- After all four calls, the script checks each `errorlevel` and only reports success if every call actually succeeded

### 6. Display Current DNS (`:ShowCurrentDNS`)

Shows active DNS configuration on the selected adapter:

```batch
netsh interface ipv4 show dnsservers name="%adapter%" | findstr /V /C:"Register"
netsh interface ipv6 show dnsservers name="%adapter%" | findstr /V /C:"Register"
```

Filters out the "Register with DNS..." line to keep output clean.

### 7. Ping Test (`:PingAll` & `:DoPing`)

For each DNS provider, runs:

```batch
ping -n 4 [IP] | findstr /C:"Average"
```

Extracts and displays the average RTT. If no average is found (timeout), displays an error message. Relies on the English-language word "Average" in `ping`'s summary line — see [Limitations](#limitations).

### 8. Reset DNS (`:Reset`)

Restores DHCP assignment and checks both calls succeeded:

```batch
netsh interface ipv4 set dnsservers name="%adapter%" dhcp
netsh interface ipv6 set dnsservers name="%adapter%" dhcp
```

### 9. Full Network Reset (`:FullReset`)

After a `Y/N` confirmation prompt, runs the full repair sequence machine-wide (not scoped to `%adapter%`):

```batch
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
```

Then offers an optional restart:

```batch
shutdown /r /t 10 /c "Restarting to complete network reset..."
```

The 10-second countdown can be canceled with `Ctrl+C` in the console window.

---

## Important Notes

### Scope of Changes

- **Options 1-7 only affect the selected adapter** — other network adapters remain untouched
- **Option 8 (Full Network Reset) is machine-wide**, not adapter-scoped — `netsh winsock reset`, `netsh int ip reset`, and the `ipconfig /release` / `/renew` calls act on the system's network stack as a whole, not just the adapter chosen in the menu
- **Option 8 does not reset the network adapter driver** — it operates at the Winsock/TCP-IP/DHCP layer only; the adapter driver itself is never disabled, restarted, or reinstalled
- All changes are applied immediately without requiring a system restart (except Option 8, where a restart is recommended to fully apply the Winsock/TCP-IP reset)
- Changes persist until manually reset or modified again

### Safety & Reversibility

- **DNS changes (Options 1-4, 7) use only `netsh`** and make no registry modifications — they're temporary and reversible with Option 7 at any time
- **Option 8 does touch the Windows registry** — `netsh winsock reset` rewrites the Winsock catalog, and `netsh int ip reset` resets several TCP/IP registry keys. These are standard, well-documented Windows repair operations, but they are a deeper change than anything else in the tool and are why a restart is recommended afterward
- **No persistent files are written by the script itself** — all DNS/adapter state lives in Windows' own network configuration, not in files created by this tool
- **Result checking** — every DNS-changing operation checks whether its underlying `netsh` calls actually succeeded and shows a warning rather than a false "success" message if something didn't apply
- **Easy reset** — use Option 7 at any time to restore DHCP-assigned DNS
- **No auto-persistence of DNS settings** — DNS settings are lost if the adapter is disabled/re-enabled or the system reboots (unless you run the script again); this does not apply to Option 8, whose Winsock/TCP-IP changes are intended to persist across reboots

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Script won't run | Make sure you're on Windows 10/11 and double-click (or run `cmd` as Administrator) |
| No adapters detected | Ensure at least one network adapter is connected; check Device Manager |
| DNS not changing | Run as Administrator (the script will prompt via UAC if needed) |
| Script shows a WARNING after applying DNS | One or more `netsh` calls failed — verify the adapter name shown at the top of the menu is still correct, then use Option 6 to re-select the adapter and try again |
| No internet after DNS change | Use Option 7 to reset to DHCP, or restart your router |
| Adapter not recognized | Use Option 6 to manually select from the list, or check adapter name in Network Settings |
| Ping test shows timeout | The DNS provider may be unreachable on your network; try a different one |
| DNS reset didn't fix connectivity | Try Option 8 (Full Network Reset) for deeper stack-level issues, then restart |
| WiFi still drops/misbehaves after Option 8 | Option 8 does not reset the adapter driver; try disabling/re-enabling the adapter in Device Manager, or a driver reinstall |

---

## Technical Details

### Variables & Arrays

The script uses several naming conventions for array management:

- `adapterName_1`, `adapterName_2`, ... — all connected adapters
- `ethName_1`, `ethName_2`, ... — Ethernet adapters
- `wifiName_1`, `wifiName_2`, ... — Wi-Fi adapters
- `otherName_1`, `otherName_2`, ... — other adapter types
- `opt_1`, `opt_2`, ... — menu options mapped to adapter names
- `dnsError` — set to `1` if any `netsh` call in a DNS/reset operation fails, used to decide whether to show a success or warning message

Arrays are cleared at the start of `:EnumerateAdapters` to prevent variable pollution.

### Delayed Expansion

The script uses `setlocal EnableDelayedExpansion` to support dynamic variable access with `!variable!` syntax within loops and after commands — necessary for proper array iteration and for reading `!errorlevel!` right after each `netsh` call.

### Color Scheme

- **Background**: Black (0)
- **Text**: Light Red (C)
- **GitHub link**: Blue (via PowerShell `Write-Host`)

---

## Supported Operating Systems

- ✅ Windows 10
- ✅ Windows 11
- ❌ Windows 7 / 8 (likely incompatible; `netsh` behavior may differ)
- ❌ Windows Server editions (untested; may require different adapter classification)

---

## Limitations

1. **Adapter Name Length** — Very long adapter names may display awkwardly in the menu
2. **Duplicate Names** — If two adapters have identical names, only one will be selectable
3. **Special Characters** — Adapter names with special characters (quotes, pipes, etc.) may cause issues
4. **Offline Adapters** — Only "Connected" adapters are detected; disabled adapters are skipped
5. **Language-dependent Parsing** — Adapter detection and ping-result parsing rely on English-language Windows output (the words "Connected" and "Average"); on non-English Windows installs, adapter auto-detection may find nothing and ping results may always show as unreachable
6. **Fallback Adapter Name** — If no connected adapters are auto-detected, the tool falls back to assuming an adapter literally named "Wi-Fi" exists; if your real adapter has a different name, DNS commands will fail (v0.3 now warns you when this happens, but doesn't fix the underlying guess)
7. **Full Network Reset is machine-wide** — Option 8 is not limited to the selected adapter and briefly interrupts all network connectivity on the system
8. **No driver-level reset** — Option 8 resets Winsock, TCP/IP, IP lease, and DNS cache, but does not disable/re-enable the adapter or restart its driver; persistent WiFi driver issues need a separate fix outside this tool's current scope

---

## Disclaimer

⚠️ **This tool modifies system-level network settings and requires administrator access to run.**

- Use at your own risk
- Ensure you understand the DNS provider you're switching to
- If you experience connectivity issues after a change, **use Option 7** to reset to DHCP
- Always test with Option 5 before committing to a new DNS provider
- Some networks or ISPs may block or throttle certain DNS providers
- **Option 8 (Full Network Reset) affects your entire network stack**, not just the DNS settings this tool otherwise manages — only use it if you understand what a Winsock/TCP-IP reset does, and expect to restart afterward

---

## License

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

This project is licensed under the MIT License — feel free to use, modify, and distribute.

---

## Support & Community

For issues, feature requests, or just to chat:

[![Discord](https://img.shields.io/badge/Discord-%237289DA.svg?logo=discord&logoColor=white)](https://discord.gg/bb2k3w5Q5A)

---

## Author

- **[@Dev-Fahim-Code](https://github.com/dev-fahim-code)** — Creator & Maintainer

---

## Changelog

### Version 0.3

- ✅ Fixed: IPv6 `set`/`add dnsservers` calls now pass `validate=no` (previously only the IPv4 calls did) — prevents a silent hang from an invisible confirmation prompt when IPv6 reachability can't be validated
- ✅ Fixed: every DNS/reset operation now checks the result of each `netsh` call and shows a warning instead of always claiming success
- ✅ Fixed: UAC elevation denial/cancellation now shows a clear message and pauses instead of the window closing silently
- ✅ Improved: clearer warning when no adapters are auto-detected and the tool falls back to guessing "Wi-Fi" as the adapter name
- 📝 Documented (not yet fixed): adapter detection and ping-result parsing depend on English-language Windows output

### Version 0.2

- ✅ Added Option 8: Full Network Reset (Winsock reset, TCP/IP stack reset, IP release/renew, DNS flush)
- ✅ Added confirmation prompt and optional restart flow for Full Network Reset
- ✅ Menu expanded to 9 options; Exit moved to Option 9

### Version 0.1

- ✅ Initial release
- ✅ Auto-elevation via PowerShell UAC
- ✅ Adaptive adapter detection & classification
- ✅ One-click DNS switching for 4 providers (IPv4 + IPv6)
- ✅ Built-in ping test utility
- ✅ DHCP reset option
- ✅ Colored console UI
