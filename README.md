# DNS Switcher Tool

A lightweight Windows batch tool to instantly switch your Ethernet DNS between Google, Quad9, and Cloudflare (or reset to auto/DHCP), with a built-in ping test to compare speeds.

Made by **Dev-Fahim-Code** — [github.com/dev-fahim-code](https://github.com/dev-fahim-code)

---

## Requirements

- Windows 10/11
- Administrator privileges (the script will request this automatically)

## How to Use

1. **Download & run** `DNS_Switcher.bat` — double-click it.
   - Windows will prompt for admin rights via UAC. Click **Yes**. This is required because changing DNS settings needs admin access.

2. **Confirm your network adapter name.**
   - On first launch, the tool asks for your adapter's name and defaults to `"Ethernet"`.
   - Press **Enter** to keep the default, or type your actual adapter name if it's different (e.g. `"Wi-Fi"`).
   - To find your adapter name: **Settings → Network & Internet → Advanced network settings**, or **Control Panel → Network Connections**.

3. **Choose an option from the menu:**

   | Option | Action |
   |--------|--------|
   | `1` | Switch to Google DNS (8.8.8.8 / 8.8.4.4) |
   | `2` | Switch to Quad9 DNS (9.9.9.9 / 149.112.112.112) |
   | `3` | Switch to Cloudflare DNS (1.1.1.1 / 1.0.0.1) |
   | `4` | Reset DNS to Automatic (DHCP) |
   | `5` | Run a ping latency test on all three providers |
   | `6` | Change the adapter name |
   | `7` | Exit |

4. **DNS cache is flushed automatically** after every change — no restart needed.

## Tips

- Not sure which DNS is fastest for you? Run option `5` first to compare ping times, then pick the winner from the menu.
- If a DNS change fails, double-check that your adapter name (option `6`) exactly matches what's shown in Windows network settings.

## Disclaimer

This tool modifies your system's network (DNS) configuration. Use at your own discretion. Always know which adapter you're changing before applying settings.

---

⭐ If you find this useful, check out more tools at [github.com/dev-fahim-code](https://github.com/dev-fahim-code)
