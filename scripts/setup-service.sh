#!/usr/bin/env bash
# Set up Claude Code + Telegram as a systemd service
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_not_root
check_sudo

section "Claude Code Telegram Service Setup"

# Check prerequisites
if ! has_cmd claude; then
  error "Claude Code is not installed."
  exit 1
fi

if ! has_cmd tmux; then
  info "Installing tmux..."
  sudo apt install -y tmux
fi

if ! has_cmd bun; then
  error "Bun is not installed."
  exit 1
fi

# Check that Telegram is configured
if [[ ! -f ~/.claude/channels/telegram/.env ]]; then
  error "Telegram bot token not configured. Run ./scripts/setup-telegram.sh first."
  exit 1
fi

# Resolve paths
CLAUDE_BIN=$(which claude)
TMUX_BIN=$(which tmux)
BUN_DIR="$HOME/.bun/bin"

info "Claude: $CLAUDE_BIN"
info "Tmux: $TMUX_BIN"
info "Bun dir: $BUN_DIR"
info "User: $USER"
info "Home: $HOME"

# Create the service
info "Creating systemd service..."
sudo tee /etc/systemd/system/claude-telegram.service > /dev/null << EOF
[Unit]
Description=Claude Code with Telegram Channel
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=$USER
Environment=PATH=$BUN_DIR:/usr/local/bin:/usr/bin:/bin
Environment=HOME=$HOME
WorkingDirectory=$HOME
ExecStartPre=-$TMUX_BIN kill-session -t claude-telegram
ExecStart=$TMUX_BIN new-session -d -s claude-telegram '$CLAUDE_BIN --channels plugin:telegram@claude-plugins-official --permission-mode acceptEdits'
ExecStop=$TMUX_BIN kill-session -t claude-telegram
RemainAfterExit=yes
Restart=on-failure
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable claude-telegram
sudo systemctl start claude-telegram

sleep 5

# Check status
if systemctl is-active --quiet claude-telegram; then
  success "Service is running!"
else
  warn "Service may not have started correctly. Checking logs..."
  sudo journalctl -u claude-telegram --no-pager -n 10
fi

# Handle trust prompt
info "Checking for trust prompt..."
sleep 3
PANE_CONTENT=$(tmux capture-pane -t claude-telegram -p 2>/dev/null || echo "")

if echo "$PANE_CONTENT" | grep -q "trust this folder"; then
  info "Accepting trust prompt..."
  tmux send-keys -t claude-telegram Enter
  sleep 5
  success "Trust prompt accepted"
fi

# Check for bypass permissions prompt
PANE_CONTENT=$(tmux capture-pane -t claude-telegram -p 2>/dev/null || echo "")
if echo "$PANE_CONTENT" | grep -q "Yes, I accept"; then
  tmux send-keys -t claude-telegram Down Enter
  sleep 3
fi

echo ""
section "Done!"
info "Your AI secretary is running 24/7!"
info ""
info "Useful commands:"
info "  View session:   tmux attach -t claude-telegram"
info "  Detach:         Ctrl+B then D"
info "  Check status:   sudo systemctl status claude-telegram"
info "  View logs:      sudo journalctl -u claude-telegram -f"
info "  Restart:        sudo systemctl restart claude-telegram"
