# DNS_Switcher_Tool

A lightweight, interactive Windows batch script for quickly switching your DNS servers between popular public DNS providers, running latency tests, and resetting back to automatic (DHCP) — all from a simple colored console menu.

**GitHub**: https://github.com/dev-fahim-code

## Features

- 🔒 **Auto-elevation** — automatically requests Administrator privileges via UAC (required to modify network settings)
- 🌐 **Smart adapter detection** — auto-detects active network adapters (Wi-Fi, Ethernet, Other) with manual selection fallback
- ⚡ **One-click DNS switching** — instantly apply DNS settings for 4 popular providers, configured for both IPv4 and IPv6
- 📊 **Built-in ping test** — compare latency across all DNS providers to find the fastest option
- ↩️ **Easy reset** — restore automatic, DHCP-assigned DNS with a single command
- 🎨 **Simple colored console UI** — red text on black background, no installation or dependencies required
- ✅ **Zero persistence** — all changes are in-memory and can be reset anytime

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

1. **UAC Prompt** — Accept the Administrator access request
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
              DNS_Switcher_Tool
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
8. Exit
```

### Option 1-4: Apply DNS

Select a DNS provider to immediately apply both IPv4 and IPv6 servers to your active adapter:

- Sends both primary and secondary DNS servers
- Applies to the currently selected network adapter only
- Takes effect immediately (no restart needed)
- Displays the new DNS configuration after applying
- Press any key to return to menu

**Example: Choosing Option 1 (Cloudflare)**
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

### Option 5: Ping Test All DNS Servers

Runs a latency test against all 4 DNS providers using `ping -n 4` (4 ICMP packets):

- **Output**: Shows average round-trip time (RTT) in milliseconds for each provider
- **Interpretation**: Lower average = faster DNS lookups for your location
- **Failures**: Shows "Request timed out or host unreachable" if the DNS server is unreachable
- **Use case**: Run before choosing a DNS provider to pick the fastest one for your network

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

### Option 7: Reset DNS to Automatic (DHCP)

Restores your adapter to automatically assigned (DHCP) DNS servers:

- Resets both IPv4 and IPv6 to DHCP
- Takes effect immediately
- Useful if you want to go back to your ISP's DNS or if you experience issues
- Displays current DNS after reset

### Option 8: Exit

Closes the script cleanly.

---

## How It Works

### 1. Admin Check & Elevation

The script starts by checking if it's running with Administrator privileges:

```batch
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
```

If not admin, it relaunches itself via PowerShell with the `RunAs` verb, triggering the UAC prompt.

### 2. Adapter Detection (`:EnumerateAdapters`)

Queries all connected network adapters using `netsh`:

```batch
netsh interface show interface | findstr /C:"Connected"
```

- Extracts adapter names from the output
- Stores them in indexed variables (`adapterName_1`, `adapterName_2`, etc.)
- Counts total adapters

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

User selects by number; the chosen adapter name is stored in the `%adapter%` variable for all subsequent operations.

### 5. DNS Configuration

Each DNS option (1-4) performs the same pattern:

**IPv4:**
```batch
netsh interface ipv4 set dnsservers name="%adapter%" static [PRIMARY] primary validate=no
netsh interface ipv4 add dnsservers name="%adapter%" [SECONDARY] index=2 validate=no
```

**IPv6:**
```batch
netsh interface ipv6 set dnsservers name="%adapter%" static [PRIMARY]
netsh interface ipv6 add dnsservers name="%adapter%" [SECONDARY] index=2
```

- `set dnsservers` — replaces all existing DNS servers with the primary
- `add dnsservers` — appends the secondary server at index 2
- `validate=no` — skips validation for faster execution
- Applies only to the selected adapter

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

Extracts and displays the average RTT. If no average is found (timeout), displays an error message.

### 8. Reset DNS (`:Reset`)

Restores DHCP assignment:

```batch
netsh interface ipv4 set dnsservers name="%adapter%" dhcp
netsh interface ipv6 set dnsservers name="%adapter%" dhcp
```

---

## Important Notes

### Scope of Changes

- **Only the selected adapter is modified** — other network adapters remain untouched
- All changes are applied immediately without requiring a system restart
- Changes persist until manually reset or modified again

### Safety & Reversibility

- **No registry modifications** — all changes use `netsh` commands which are temporary and reversible
- **No persistent files** — everything runs in-memory
- **Easy reset** — use Option 7 at any time to restore DHCP assignment
- **No auto-persistence** — settings are lost if the adapter is disabled/re-enabled or the system reboots (unless you run the script again)

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Script won't run | Make sure you're on Windows 10/11 and double-click (or run `cmd` as Administrator) |
| No adapters detected | Ensure at least one network adapter is connected; check Device Manager |
| DNS not changing | Run as Administrator (the script will prompt via UAC if needed) |
| No internet after DNS change | Use Option 7 to reset to DHCP, or restart your router |
| Adapter not recognized | Use Option 6 to manually select from the list, or check adapter name in Network Settings |
| Ping test shows timeout | The DNS provider may be unreachable on your network; try a different one |

---

## Technical Details

### Variables & Arrays

The script uses several naming conventions for array management:

- `adapterName_1`, `adapterName_2`, ... — all connected adapters
- `ethName_1`, `ethName_2`, ... — Ethernet adapters
- `wifiName_1`, `wifiName_2`, ... — Wi-Fi adapters
- `otherName_1`, `otherName_2`, ... — other adapter types
- `opt_1`, `opt_2`, ... — menu options mapped to adapter names

Arrays are cleared at the start of `:EnumerateAdapters` to prevent variable pollution.

### Delayed Expansion

The script uses `setlocal EnableDelayedExpansion` to support dynamic variable access with `!variable!` syntax within loops — necessary for proper array iteration.

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
5. **IPv6 Validation** — IPv6 DNS validation is not disabled (`validate=yes` by default), which may cause slower application on some systems

---

## Disclaimer

⚠️ **This tool modifies system-level network settings and requires administrator access to run.**

- Use at your own risk
- Ensure you understand the DNS provider you're switching to
- If you experience connectivity issues after a change, **use Option 7** to reset to DHCP
- Always test with Option 5 before committing to a new DNS provider
- Some networks or ISPs may block or throttle certain DNS providers

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

### Version 1.0

- ✅ Initial release
- ✅ Auto-elevation via PowerShell UAC
- ✅ Adaptive adapter detection & classification
- ✅ One-click DNS switching for 4 providers (IPv4 + IPv6)
- ✅ Built-in ping test utility
- ✅ DHCP reset option
- ✅ Colored console UI
