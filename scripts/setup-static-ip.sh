#!/usr/bin/env bash
# Configure a static IP address via NetworkManager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_not_root
check_sudo

section "Static IP Configuration"

# Get active connection
ACTIVE_CON=$(nmcli -t -f NAME,DEVICE con show --active | grep -v "^lo:" | head -1)
CON_NAME=$(echo "$ACTIVE_CON" | cut -d: -f1)
CON_DEV=$(echo "$ACTIVE_CON" | cut -d: -f2)

if [[ -z "$CON_NAME" ]]; then
  error "No active network connection found."
  exit 1
fi

info "Active connection: $CON_NAME (device: $CON_DEV)"

# Get current settings
CURRENT_IP=$(ip -4 addr show "$CON_DEV" | grep inet | awk '{print $2}' | head -1)
CURRENT_GW=$(ip route | grep default | awk '{print $3}' | head -1)

info "Current IP: $CURRENT_IP"
info "Current Gateway: $CURRENT_GW"

# Prompt for new settings
STATIC_IP=$(prompt_with_default "Static IP address (with /24)" "${CURRENT_IP}")
GATEWAY=$(prompt_with_default "Gateway" "${CURRENT_GW}")
DNS=$(prompt_with_default "DNS servers (comma-separated)" "${CURRENT_GW},8.8.8.8,8.8.4.4")

echo ""
info "Will configure:"
info "  IP:      $STATIC_IP"
info "  Gateway: $GATEWAY"
info "  DNS:     $DNS"
echo ""

if ! confirm "Apply these settings?"; then
  info "Cancelled."
  exit 0
fi

# Apply
sudo nmcli con mod "$CON_NAME" \
  ipv4.addresses "$STATIC_IP" \
  ipv4.gateway "$GATEWAY" \
  ipv4.dns "$DNS" \
  ipv4.method manual

info "Restarting connection..."
sudo nmcli con down "$CON_NAME" && sudo nmcli con up "$CON_NAME"

# Verify
sleep 2
NEW_IP=$(ip -4 addr show "$CON_DEV" | grep inet | awk '{print $2}' | head -1)
success "Static IP configured: $NEW_IP"

# Test connectivity
if ping -c1 -W3 8.8.8.8 &>/dev/null; then
  success "Internet connectivity verified"
else
  warn "Cannot reach 8.8.8.8 — check your gateway settings"
fi

if nslookup google.com &>/dev/null; then
  success "DNS resolution verified"
else
  warn "DNS resolution failed — check your DNS settings"
fi
