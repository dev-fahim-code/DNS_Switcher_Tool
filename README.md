# DNS Tool

A small interactive Windows batch script to quickly switch your active network adapter's DNS settings to popular public DNS providers, run ping tests against them, or reset DNS back to automatic (DHCP). The script detects an active adapter, requests elevation if not run as Administrator, and provides a simple menu-driven interface.

## Features

- Apply Cloudflare, Google, AdGuard, or Quad9 DNS (IPv4 and where provided, IPv6)
- Ping-test all DNS providers (averaged response) using PowerShell's Test-Connection
- Automatically detect the first active (Connected) network adapter, with fallbacks
- Reset DNS to automatic (DHCP)
- Displays a GitHub link and a colored console header

## Requirements

- Windows 10 / 11 (or other modern Windows with netsh and PowerShell)
- Must be run with Administrative privileges (the script requests elevation automatically)
- netsh and PowerShell must be available on PATH (default on Windows)

## Installation

1. Copy the script contents into a file named `dns-tool.bat` (or any `.bat` filename).
2. Place the file where you want to run it (e.g., your user folder or desktop).
3. Right-click and Run as administrator, or simply run the file — the script will request elevation if needed.

## Usage

1. Run `dns-tool.bat` (run elevated).
2. Use the numbered menu to choose:
   - 1: Cloudflare DNS (1.1.1.1, 1.0.0.1; IPv6: 2606:4700:4700::1111, 2606:4700:4700::1001)
   - 2: Google Public DNS (8.8.8.8, 8.8.4.4; IPv6: 2001:4860:4860::8888, 2001:4860:4860::8844)
   - 3: AdGuard DNS (94.140.14.14, 94.140.15.15)
   - 4: Quad9 DNS (9.9.9.9, 149.112.112.112)
   - 5: Ping Test All DNS Servers (runs four pings and shows average response time)
   - 6: Reset DNS to Automatic (DHCP)
   - 7: Exit

After applying a change, the script pauses so you can view status messages.

## How adapter detection works

The script attempts to find the first interface listed as "Connected" using `netsh interface show interface`. It parses that output for the first interface name and uses it as the target adapter. If no connected interface is found, it falls back to the named adapter "Wi-Fi". If the inferred adapter name doesn't exist, the script falls back again to the first listed interface in the `netsh` output.

If the script picks the wrong adapter for your system, you can:
- Edit the script and set the preferred adapter string manually by adding a line near the top:
  set "adapter=Ethernet" (replace with your adapter's exact name)
- Or run `netsh interface show interface` in a command prompt to find the correct adapter name and then re-run the script.

## Implementation notes & safety

- The script requires Administrator privileges because it modifies network interface settings.
- It uses `netsh interface ipv4 set dnsservers ...` and `netsh interface ipv6 set dnsservers ...` to apply DNS server addresses.
- The `validate=no` flag is used for IPv4 netsh calls to avoid DNS server reachability validation during the change.
- Running this script will change network configuration for the selected adapter. Only run it if you are comfortable modifying network settings.
- If you rely on corporate VPNs, static DNS pushed by system policy, or domain-joined group policy, this script may be overridden by system or network policies.

## Ping tests

The script uses PowerShell's `Test-Connection` to ping each DNS provider 4 times and prints the average response time (ms). Lower average is better for latency-sensitive tasks like gaming or interactive apps.

## Troubleshooting

- "Adapter not found" or unexpected adapter selected:
  - Run `netsh interface show interface` and verify interface names.
  - Edit the script to set the adapter variable explicitly if needed.
- DNS change doesn't take effect:
  - Verify you ran the script as Administrator.
  - Some enterprise/network policies may block or override DNS settings.
  - Try disabling/re-enabling the adapter or restarting the machine.
- Ping tests show "Request timed out or host unreachable":
  - There may be network-level blocking, firewalls, or the host may be unreachable from your network.

## Supported DNS providers and addresses

- Cloudflare
  - IPv4: 1.1.1.1 (primary), 1.0.0.1 (secondary)
  - IPv6: 2606:4700:4700::1111, 2606:4700:4700::1001
- Google Public DNS
  - IPv4: 8.8.8.8 (primary), 8.8.4.4 (secondary)
  - IPv6: 2001:4860:4860::8888, 2001:4860:4860::8844
- AdGuard
  - IPv4: 94.140.14.14 (primary), 94.140.15.15 (secondary)
- Quad9
  - IPv4: 9.9.9.9 (primary), 149.112.112.112 (secondary)

## Contributing

- Pull requests and suggestions are welcome. If you want a new provider added or an enhancement (like listing adapters to choose from interactively), open an issue or submit a PR to the repository.
- Keep changes Windows-compatible and keep the elevation/request flow intact.

## License

MIT License — see LICENSE file (or add your preferred license).

## Acknowledgements

Script header prints a GitHub link:
https://github.com/dev-fahim-code

---
