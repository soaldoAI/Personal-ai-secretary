#!/usr/bin/env bash
# Set up Syncthing for file sync
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_not_root
check_sudo

section "Syncthing File Sync Setup"

# Install Syncthing
if ! has_cmd syncthing; then
  info "Installing Syncthing..."
  sudo apt install -y syncthing
  success "Syncthing installed"
else
  success "Syncthing already installed"
fi

# Enable and start
info "Enabling Syncthing service..."
sudo systemctl enable "syncthing@$USER"
sudo systemctl start "syncthing@$USER"
wait_for_service "syncthing@$USER"

# Get device ID
DEVICE_ID=$(syncthing --device-id 2>/dev/null || syncthing -device-id 2>/dev/null || echo "unknown")
echo ""
success "Syncthing is running!"
echo ""
info "This device's ID:"
echo -e "${CYAN}$DEVICE_ID${NC}"
echo ""
info "Web UI: http://localhost:8384"
echo ""
info "Next steps:"
info "  1. Install Syncthing on your laptop:"
info "     Mac:   brew install syncthing && brew services start syncthing"
info "     Linux: sudo apt install syncthing"
info ""
info "  2. Open http://localhost:8384 on BOTH machines"
info ""
info "  3. Add this device ID on your laptop"
info ""
info "  4. On your laptop, get its device ID and add it here"
info ""
info "  5. Create a shared folder on both machines"
info ""
info "  TIP: For the initial sync of large folders, use rsync first:"
info "  rsync -avz --progress ~/Documents/Projects/ user@THIS_IP:~/Documents/Projects/"
