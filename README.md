# Dev-Fahim-Code DNS Tool

A lightweight, interactive Windows batch script for quickly switching your DNS servers between popular public DNS providers, running latency tests, and resetting back to automatic (DHCP) — all from a simple command-line menu.

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
6. Reset DNS to Automatic (DHCP)
7. Exit
```

## How It Works

- **Adapter detection**: parses `netsh interface show interface` to find the first `Connected` adapter. If detection fails, it falls back to an adapter named `Wi-Fi`, then to the first interface listed by `netsh`.
- **Applying DNS**: uses `netsh interface ipv4 set/add dnsservers` and `netsh interface ipv6 set/add dnsservers` to set primary and secondary servers for the detected adapter.
- **Ping test**: runs `ping -n 4` against each provider and extracts the reported average round-trip time, so you can compare latency at a glance.
- **Reset**: switches the adapter back to `dhcp`, restoring automatically assigned DNS servers.

## Notes

- Only the detected active adapter is modified — other adapters are left untouched.
- If your adapter isn't detected correctly, you can edit the fallback name (`Wi-Fi`) near the top of the script to match your system (e.g. `Ethernet`).
- The script only changes DNS server settings; it does not alter any other network configuration.

## Disclaimer

This tool modifies system-level network settings and requires administrator access to run. Use at your own risk. If you experience connectivity issues after a change, use **option 6** at any time to revert to automatic, DHCP-assigned DNS.

## Author

[dev-fahim-code](https://github.com/dev-fahim-code)

## License

MIT License — feel free to use, modify, and distribute.
