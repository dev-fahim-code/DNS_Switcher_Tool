# Dev-Fahim-Code DNS Tool

A lightweight, interactive Windows batch script for quickly switching your DNS servers between popular public DNS providers, running latency tests, and resetting back to automatic (DHCP) — all from a simple menu. No installation required.

## Features

- 🔒 **Auto-elevation** — automatically requests Administrator privileges (required to change network settings)
- 🌐 **Auto-detects** your active network adapter (Wi-Fi, Ethernet, etc.), with sensible fallbacks
- ⚡ **One-click DNS switching** for 4 popular providers, configured for both IPv4 and IPv6
- 📊 **Built-in ping test** to compare latency across all providers before choosing one
- ↩️ **Easy reset** back to automatic, DHCP-assigned DNS
- 🎨 Simple colored console menu — no installation or dependencies required

## Supported DNS Providers

| # | Provider | Primary | Secondary | Best For |
|---|----------|---------|-----------|----------|
| 1 | Cloudflare | `1.1.1.1` | `1.0.0.1` | Gaming & Speed |
| 2 | Google Public DNS | `8.8.8.8` | `8.8.4.4` | General Stability & Routing |
| 3 | AdGuard DNS | `94.140.14.14` | `94.140.15.15` | Blocking Ads & Trackers |
| 4 | Quad9 | `9.9.9.9` | `149.112.112.112` | Security & Threat Prevention |

Each option also configures the matching IPv6 addresses automatically.

## Requirements

- Windows 10 or 11
- Administrator privileges (the script prompts for elevation automatically via UAC)

## Usage

1. Download the script (e.g. `dns-tool.bat`).
2. Double-click to run, or launch it from Command Prompt.
3. Accept the UAC prompt when asked to allow administrative changes.
4. Choose an option from the menu:

```
1. Cloudflare DNS      (Best for Gaming & Speed)
2. Google Public DNS   (Best for General Stability & Routing)
3. AdGuard DNS         (Best for Blocking Ads & Trackers)
4. Quad9 DNS           (Best for Security & Threat Prevention)
5. Ping Test All DNS Servers
6. Change Network Adapter
7. Reset DNS to Automatic (DHCP)
8. Exit
```

## How It Works

- **Adapter detection**: automatically detects all connected network adapters using `netsh interface show interface`, classifying them as Ethernet, Wi-Fi, or Other. The user can select their preferred adapter from the menu, or the script uses the first detected adapter.
- **Applying DNS**: uses `netsh interface ipv4 set/add dnsservers` and `netsh interface ipv6 set/add dnsservers` to set primary and secondary servers for the selected adapter.
- **Ping test**: runs `ping -n 4` against each provider and extracts the reported average round-trip time, so you can compare latency at a glance before choosing a DNS provider.
- **Reset**: switches the adapter back to `dhcp`, restoring automatically assigned DNS servers.

## Features Breakdown

### 1. Auto-Elevation
The script automatically requests Administrator privileges on startup. If not running as admin, it relaunches itself with the `RunAs` verb via PowerShell.

### 2. Adapter Management
- Detects all connected adapters in real-time
- Classifies them by type (Ethernet, Wi-Fi, Other)
- Allows user selection at startup and option to change later
- Displays current DNS settings for the selected adapter

### 3. DNS Switching
- One-command configuration of both IPv4 and IPv6 for each provider
- Validation disabled for faster application (`validate=no`)
- Immediate feedback showing current DNS after each change

### 4. Ping Testing
- Quick latency check against all four providers
- Shows average round-trip time for easy comparison
- Handles timeouts gracefully with "Request timed out" message

### 5. Reset to DHCP
- Cleanly restores automatic DNS assignment
- Works for both IPv4 and IPv6

## Notes

- Only the selected adapter is modified — other adapters are left untouched.
- The script operates entirely in-memory; no registry changes or persistent files are created.
- DNS changes take effect immediately and persist until reset or changed again.
- If your adapter isn't detected correctly, you can manually select from the adapter menu.

## Disclaimer

This tool modifies system-level network settings and requires administrator access to run. Use at your own risk. If you experience connectivity issues after a change, use **option 7** at any time to reset to automatic DNS. Always ensure you have a backup connection method if troubleshooting network settings.

## License

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

## Support

For support, join our community:

[![Discord](https://img.shields.io/badge/Discord-%237289DA.svg?logo=discord&logoColor=white)](https://discord.gg/bb2k3w5Q5A)

## Author

- [@Dev-Fahim-Code](https://github.com/dev-fahim-code)
