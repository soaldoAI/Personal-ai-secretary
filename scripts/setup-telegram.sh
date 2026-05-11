#!/usr/bin/env bash
# Set up Telegram bot for Claude Code
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_not_root

section "Telegram Bot Setup"

# Check prerequisites
if ! has_cmd claude; then
  error "Claude Code is not installed. Run the main installer first."
  exit 1
fi

if ! has_cmd bun; then
  error "Bun is not installed. Run the main installer first."
  exit 1
fi

# Install Telegram plugin
info "Installing Telegram plugin..."
claude plugin install telegram@claude-plugins-official 2>/dev/null && success "Plugin installed" || warn "Plugin may already be installed"

# Get bot token
echo ""
info "You need a Telegram bot token from @BotFather."
info "Open Telegram, message @BotFather, send /newbot, and follow the prompts."
echo ""
read -rp "$(echo -e "${CYAN}Paste your bot token:${NC} ")" BOT_TOKEN

if [[ -z "$BOT_TOKEN" ]]; then
  error "No token provided."
  exit 1
fi

# Validate token format (number:string)
if [[ ! "$BOT_TOKEN" =~ ^[0-9]+:.+ ]]; then
  error "Invalid token format. Expected format: 123456789:AAH..."
  exit 1
fi

# Save token
mkdir -p ~/.claude/channels/telegram
echo "TELEGRAM_BOT_TOKEN=$BOT_TOKEN" > ~/.claude/channels/telegram/.env
chmod 600 ~/.claude/channels/telegram/.env
success "Bot token saved"

# Set up permissions
info "Configuring permissions..."
cat > ~/.claude/settings.local.json << 'ENDJSON'
{
  "permissions": {
    "allow": [
      "mcp__plugin_telegram_telegram__reply",
      "mcp__plugin_telegram_telegram__react",
      "mcp__plugin_telegram_telegram__edit_message",
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)"
    ]
  }
}
ENDJSON
success "Permissions configured"

echo ""
section "Pairing"
info "Now you need to pair your Telegram account."
info ""
info "1. Run this command:"
info "   claude --channels plugin:telegram@claude-plugins-official"
info ""
info "2. Accept the trust prompt"
info ""
info "3. Message your bot on Telegram — it will reply with a 6-char code"
info ""
info "4. In the Claude Code session, type:"
info "   /telegram:access pair YOUR_CODE"
info ""
info "5. Then lock it down:"
info "   /telegram:access policy allowlist"
info ""
info "6. Exit Claude Code and run:"
info "   ./scripts/setup-service.sh"
info ""

if confirm "Start Claude Code now for pairing?"; then
  claude --channels plugin:telegram@claude-plugins-official
fi
