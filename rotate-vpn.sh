#!/bin/bash

# =======================
# CONFIGURATION VARIABLES
# =======================

BASE_DIR="$HOME/wireguard-rotator"
WG_INTERFACE="wg0"
WG_CONFIG_DIR="$BASE_DIR/wg-configs"
BROKEN_DIR="$WG_CONFIG_DIR/broken_configs"
STATE_DIR="$BASE_DIR/state"
LOG_DIR="$BASE_DIR/logs"
LAST_USED_FILE="$STATE_DIR/.last_used_vpn"
LAST_VALIDATION_FILE="$STATE_DIR/.last_config_validation"
NTFY_TOPIC="vpn-rotate"
NTFY_URL="https://alert.radlabv2.xyz"
LOG_FILE="$LOG_DIR/rotate-vpn.log"

# =====================
# UTILITY FUNCTIONS
# =====================

log() {
    echo "[$(date)] $*" | tee -a "$LOG_FILE" >&2
}

send_ntfy() {
    local title="$1"
    local message="$2"
    curl -s -H "Title: $title" -d "$message" "$NTFY_URL/$NTFY_TOPIC" >/dev/null
}

validate_configs_once_daily() {
    if [ -f "$LAST_VALIDATION_FILE" ]; then
        last_run=$(stat -c %Y "$LAST_VALIDATION_FILE")
        now=$(date +%s)
        if (( now - last_run < 86400 )); then
            log "⏳ Skipping validation — last run was less than 24h ago."
            return
        fi
    fi

    log "🔍 Validating and moving broken WireGuard configs..."

    mkdir -p "$BROKEN_DIR"

    for file in "$WG_CONFIG_DIR"/*.conf; do
        [[ -f "$file" ]] || continue
        if grep -qE "^PrivateKey = [A-Za-z0-9+/=]{44}$" "$file" && grep -qE "^PublicKey = [A-Za-z0-9+/=]{44}$" "$file"; then
            continue
        else
            log "❌ Moving broken config: $(basename "$file")"
            mv "$file" "$BROKEN_DIR/"
        fi
    done

    date +%s > "$LAST_VALIDATION_FILE"
}

get_valid_configs() {
    find "$WG_CONFIG_DIR" -maxdepth 1 -name "*.conf" -type f
}

get_public_ip_info() {
    curl -s https://ipinfo.io/json
}

# =====================
# MAIN ROTATION PROCESS
# =====================

log "===== Starting VPN Rotation ====="

validate_configs_once_daily
mapfile -t valid_configs < <(get_valid_configs)

if [ ${#valid_configs[@]} -eq 0 ]; then
    log "❌ No valid configs available."
    send_ntfy "WireGuard Error" "No valid configs found in $WG_CONFIG_DIR"
    exit 1
fi

last_used=$(<"$LAST_USED_FILE" 2>/dev/null || echo "")

# Choose new config
chosen=""
attempts=0
while [[ -z "$chosen" || "$chosen" == "$last_used" ]]; do
    chosen="${valid_configs[RANDOM % ${#valid_configs[@]}]}"
    ((attempts++))
    [[ $attempts -ge 10 ]] && break
done

if [[ -z "$chosen" ]]; then
    log "❌ Could not find a new config to rotate to."
    send_ntfy "WireGuard Error" "Failed to choose a new config"
    exit 1
fi

sudo wg-quick down "$WG_INTERFACE" &>/dev/null
sudo cp "$chosen" "/etc/wireguard/$WG_INTERFACE.conf"

if ! sudo wg-quick up "$WG_INTERFACE" &>/dev/null; then
    log "❌ Failed to activate WireGuard using: $(basename "$chosen")"
    send_ntfy "WireGuard Error" "Failed to start VPN with: $(basename "$chosen")"
    exit 1
fi

sleep 3

ip_info=$(get_public_ip_info)
public_ip=$(echo "$ip_info" | jq -r .ip)
city=$(echo "$ip_info" | jq -r .city)
country=$(echo "$ip_info" | jq -r .country)
server_name=$(basename "$chosen" .conf)

log "✅ Connected to $server_name — IP: $public_ip ($city, $country)"
send_ntfy "WireGuard Switched" "Connected to: $server_name\nIP: $public_ip\nLocation: $city, $country"

echo "$chosen" > "$LAST_USED_FILE"
log "===== VPN Rotation Complete ====="
