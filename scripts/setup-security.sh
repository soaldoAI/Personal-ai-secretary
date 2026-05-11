#!/usr/bin/env bash
# Configure automatic security updates
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_not_root
check_sudo

section "Automatic Security Updates"

# Install unattended-upgrades
info "Installing unattended-upgrades..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y unattended-upgrades
success "Installed"

# Enable
info "Enabling automatic updates..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
success "Auto-updates enabled"

# Configure auto-reboot
REBOOT_TIME=$(prompt_with_default "Auto-reboot time for kernel updates (HH:MM)" "04:00")

info "Enabling auto-reboot at $REBOOT_TIME..."
sudo sed -i "s|//Unattended-Upgrade::Automatic-Reboot \"false\";|Unattended-Upgrade::Automatic-Reboot \"true\";|" \
  /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i "s|//Unattended-Upgrade::Automatic-Reboot-Time \"02:00\";|Unattended-Upgrade::Automatic-Reboot-Time \"$REBOOT_TIME\";|" \
  /etc/apt/apt.conf.d/50unattended-upgrades

success "Auto-reboot enabled at $REBOOT_TIME (only when kernel updates require it)"

echo ""
info "Security updates will be installed daily."
info "The system will reboot at $REBOOT_TIME only if a kernel update requires it."
