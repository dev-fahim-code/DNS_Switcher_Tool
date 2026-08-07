# DNS Switcher Tool

A tiny Windows batch utility to quickly switch your active network adapter's DNS servers between popular public, privacy-focused, and security-focused providers.

This repository contains `dns-tool.bat` — a single-file interactive script that:

- Detects the first connected network adapter (with fallbacks).
- Requests elevation to Administrator when needed.
- Applies IPv4 and IPv6 DNS servers for selected providers.
- Runs simple ping benchmarks against DNS endpoints.
- Resets DNS back to Automatic (DHCP).

---

## Quick start

1. Download or copy `dns-tool.bat` into a folder on your Windows machine.
2. Right-click and choose "Run as administrator" or simply double-click the file — the script will prompt to re-run elevated if required.
3. Choose an option from the menu to apply a DNS provider, run ping tests, or reset to DHCP.

Note: Administrative privileges are required to change network adapter settings.

---

## Menu options

1. Cloudflare DNS — 1.1.1.1 / 1.0.0.1 (IPv6: 2606:4700:4700::1111 / 2606:4700:4700::1001)
2. Google Public DNS — 8.8.8.8 / 8.8.4.4 (IPv6: 2001:4860:4860::8888 / 2001:4860:4860::8844)
3. AdGuard DNS — 94.140.14.14 / 94.140.15.15 (IPv6 entries where available)
4. Quad9 — 9.9.9.9 / 149.112.112.112 (IPv6 entries where available)
5. Ping Test — runs 4 pings and reports average latency for each provider
6. Reset — reset DNS to Automatic (DHCP) for the selected adapter
7. Exit

---

## How it detects the adapter

- The script parses the output of `netsh interface show interface` and selects the first interface listed as "Connected".
- If no connected adapter is found, it falls back to `Wi-Fi`, and finally to the first listed interface.
- If you prefer a specific adapter, edit the script and set `adapter` near the top, e.g. `set "adapter=Ethernet"`.

---

## Notes & troubleshooting

- The script uses `netsh` to set DNS entries and will use `validate=no` on IPv4 commands to avoid validation failures on some systems.
- After changing DNS, you can run `ipconfig /flushdns` to clear the DNS resolver cache.
- If changes do not persist, group policies, VPN clients, or corporate tools may be overriding settings.
- If the ping tests show timeouts, ICMP may be filtered on your network or the DNS endpoint may be unreachable.

---

## Contributing

- Feature requests, bug reports, and PRs are welcome.
- Ideas: better adapter selection UI, list adapters to choose from, extra DNS providers, or PowerShell equivalent script.

---

## License

No license file is included by default. Add a LICENSE file (MIT, Apache-2.0, etc.) if you want to permit reuse or contributions.

---

Author: Dev-Fahim-Code — https://github.com/dev-fahim-code
