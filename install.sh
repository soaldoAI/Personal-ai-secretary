#!/usr/bin/env bash
# Personal AI Secretary — One-Line Installer
# https://github.com/soaldoAI/Personal-ai-secretary

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If running from curl pipe, clone the repo first
if [[ ! -f "$REPO_DIR/scripts/utils.sh" ]]; then
  echo "[INFO] Cloning repository..."
  REPO_DIR="$HOME/personal-ai-secretary"
  if [[ -d "$REPO_DIR" ]]; then
    cd "$REPO_DIR" && git pull
  else
    git clone https://github.com/soaldoAI/Personal-ai-secretary.git "$REPO_DIR"
  fi
  cd "$REPO_DIR"
fi

source "$REPO_DIR/scripts/utils.sh"

check_not_root
check_sudo

# ─────────────────────────────────────────────────────────────
section "Personal AI Secretary — Installer"
# ─────────────────────────────────────────────────────────────

PLATFORM=$(detect_platform)
OS=$(detect_os)
info "Platform: $PLATFORM"
info "OS: $OS"
check_ram 2048 || true

echo ""
info "This script will install:"
info "  - Node.js, npm, and Bun"
info "  - Claude Code"
info "  - Telegram plugin"
info "  - tmux, curl, git"
info "  - Docker (optional)"
info "  - Syncthing (optional)"
info "  - Automatic security updates"
echo ""

if ! confirm "Continue with installation?"; then
  info "Cancelled."
  exit 0
fi

# ─────────────────────────────────────────────────────────────
section "Step 1: System Packages"
# ─────────────────────────────────────────────────────────────

info "Updating package lists..."
sudo apt update -y

info "Installing base packages..."
sudo apt install -y \
  curl \
  git \
  tmux \
  nodejs \
  npm \
  openssh-server

success "System packages installed"

# ─────────────────────────────────────────────────────────────
section "Step 2: Bun"
# ─────────────────────────────────────────────────────────────

if has_cmd bun; then
  success "Bun already installed: $(bun --version)"
else
  info "Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
  sudo ln -sf "$HOME/.bun/bin/bun" /usr/local/bin/bun
  success "Bun installed: $(bun --version)"
fi

# ─────────────────────────────────────────────────────────────
section "Step 3: Claude Code"
# ─────────────────────────────────────────────────────────────

if has_cmd claude; then
  success "Claude Code already installed: $(claude --version 2>/dev/null || echo 'installed')"
else
  info "Installing Claude Code..."
  sudo npm install -g @anthropic-ai/claude-code
  success "Claude Code installed: $(claude --version)"
fi

echo ""
info "You need to authenticate Claude Code."
info "Run 'claude' — it will show a URL to open in your browser."
echo ""

if confirm "Authenticate Claude Code now?"; then
  claude
fi

# ─────────────────────────────────────────────────────────────
section "Step 4: Docker (Optional)"
# ─────────────────────────────────────────────────────────────

if has_cmd docker; then
  success "Docker already installed: $(docker --version)"
else
  if confirm "Install Docker?"; then
    info "Installing Docker..."
    sudo apt install -y docker.io docker-compose-v2
    sudo usermod -aG docker "$USER"
    success "Docker installed (log out and back in for group changes)"
  else
    info "Skipping Docker"
  fi
fi

# ─────────────────────────────────────────────────────────────
section "Step 5: Security Updates"
# ─────────────────────────────────────────────────────────────

bash "$REPO_DIR/scripts/setup-security.sh"

# ─────────────────────────────────────────────────────────────
section "Step 6: Static IP (Optional)"
# ─────────────────────────────────────────────────────────────

if confirm "Configure a static IP address?"; then
  bash "$REPO_DIR/scripts/setup-static-ip.sh"
else
  info "Skipping static IP"
fi

# ─────────────────────────────────────────────────────────────
section "Step 7: Telegram Bot"
# ─────────────────────────────────────────────────────────────

if confirm "Set up a Telegram bot?"; then
  bash "$REPO_DIR/scripts/setup-telegram.sh"
else
  info "Skipping Telegram setup. Run ./scripts/setup-telegram.sh later."
fi

# ─────────────────────────────────────────────────────────────
section "Step 8: Syncthing (Optional)"
# ─────────────────────────────────────────────────────────────

if confirm "Set up Syncthing file sync?"; then
  bash "$REPO_DIR/scripts/setup-syncthing.sh"
else
  info "Skipping Syncthing"
fi

# ─────────────────────────────────────────────────────────────
section "Installation Complete!"
# ─────────────────────────────────────────────────────────────

echo ""
success "Your Personal AI Secretary is ready!"
echo ""
info "What's installed:"
info "  Node.js:     $(node --version 2>/dev/null || echo 'not found')"
info "  npm:         $(npm --version 2>/dev/null || echo 'not found')"
info "  Bun:         $(bun --version 2>/dev/null || echo 'not found')"
info "  Claude Code: $(claude --version 2>/dev/null || echo 'not found')"
info "  Docker:      $(docker --version 2>/dev/null || echo 'not installed')"
info "  tmux:        $(tmux -V 2>/dev/null || echo 'not found')"
info "  Git:         $(git --version 2>/dev/null || echo 'not found')"
echo ""
info "Next steps:"
info "  1. If you haven't yet: authenticate Claude Code with 'claude'"
info "  2. Set up Telegram: ./scripts/setup-telegram.sh"
info "  3. Start the service: ./scripts/setup-service.sh"
info "  4. Set up file sync: ./scripts/setup-syncthing.sh"
echo ""
info "Full documentation: https://github.com/soaldoAI/Personal-ai-secretary"
echo ""
