# WireGuard ProtonVPN Rotator

A secure, automated script that rotates your ProtonVPN WireGuard configuration daily.

---

## 🔄 What It Does

- Switches to a random ProtonVPN WireGuard server daily
- Avoids using the same server consecutively
- Detects and isolates broken config files
- Sends notifications (via [ntfy](https://ntfy.sh)) when a server switch is successful
- Logs new IP and geolocation info

---

## 📦 Install

1. Download the `.deb` file:
   ```bash
   wget https://github.com/radpi42/wireguard-rotator/releases/latest/download/wireguard-rotator_1.0_all.deb
   ```

2. Install it:
   ```bash
   sudo dpkg -i wireguard-rotator_1.0_all.deb
   ```

3. Install required dependencies:
   ```bash
   sudo apt install wireguard jq resolvconf curl
   ```

---

## 📁 Installed Structure

| Path                                     | Purpose                                 |
|------------------------------------------|------------------------------------------|
| `/usr/local/bin/rotate-vpn.sh`          | Main script                              |
| `/etc/wireguard-rotator/wg-configs/`    | Active WireGuard config files            |
| `/etc/wireguard-rotator/wg-configs/broken_configs/` | Auto-moved invalid configs    |
| `/etc/wireguard-rotator/logs/`          | Log file (`rotate-vpn.log`)              |
| `/etc/wireguard-rotator/state/`         | State files to track last config used    |

---

## 🚀 Usage

1. Add your `.conf` files (from ProtonVPN dashboard) to:
   ```
   /etc/wireguard-rotator/wg-configs/
   ```

2. Run manually:
   ```bash
   sudo rotate-vpn.sh
   ```

3. Add to cron for daily auto-rotation:
   ```bash
   crontab -e
   ```

   Example:
   ```cron
   0 3 * * * /usr/local/bin/rotate-vpn.sh
   ```

---

## 🔔 Notifications

Edit `/usr/local/bin/rotate-vpn.sh` to set:

```bash
NTFY_TOPIC="vpn-rotate"
NTFY_URL="https://ntfy.sh"
```

---

## 🧼 Broken Config Handling

Broken `.conf` files are moved to:

```
/etc/wireguard-rotator/wg-configs/broken_configs/
```

Validation runs automatically every 24 hours.

---

## ✅ License

MIT License

---


