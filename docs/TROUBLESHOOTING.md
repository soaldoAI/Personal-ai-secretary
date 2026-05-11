# Troubleshooting

## Telegram Bot Not Responding

**Symptom:** You message the bot but get no reply.

**Check the tmux session:**
```bash
tmux capture-pane -t claude-telegram -p
```

- **Stuck on "trust this folder"** — Accept it: `tmux send-keys -t claude-telegram Enter`
- **Permission prompt** — Your `settings.local.json` may be missing the tool names. See [config/settings.local.json](../config/settings.local.json)
- **No tmux session** — Service crashed. Check: `sudo journalctl -u claude-telegram -n 50`
- **"bun: command not found" in logs** — Symlink bun: `sudo ln -sf ~/.bun/bin/bun /usr/local/bin/bun`

## Permission Prompt on Every Message

**Symptom:** Bot replies but shows "Permission: mcp__plugin_telegram_telegram__reply" in the chat.

**Fix:** Ensure `~/.claude/settings.local.json` contains:

```json
{
  "permissions": {
    "allow": [
      "mcp__plugin_telegram_telegram__reply",
      "mcp__plugin_telegram_telegram__react",
      "mcp__plugin_telegram_telegram__edit_message"
    ]
  }
}
```

Then restart: `sudo systemctl restart claude-telegram`

Also ensure you're using `--permission-mode acceptEdits` in the service file.

## Service Won't Start

**Check logs:**
```bash
sudo journalctl -u claude-telegram --no-pager -n 30
```

**Common causes:**
- tmux not installed: `sudo apt install -y tmux`
- Claude Code not authenticated: SSH in and run `claude` to re-auth
- Wrong paths in service file: Check `which claude` and `which tmux`

## IP Address Keeps Changing

Run the static IP setup script:
```bash
./scripts/setup-static-ip.sh
```

Or configure manually with `nmcli` — see the README.

## SSH Connection Refused

```bash
# Install SSH server
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```

## Claude Code Authentication Expired

SSH in and re-authenticate:
```bash
ssh user@DEVICE_IP
claude
# Follow the browser auth flow
```

## Syncthing Not Syncing

**Check service:**
```bash
sudo systemctl status syncthing@$USER
```

**Check web UI:** Open `http://localhost:8384` — are both devices connected?

**Common issues:**
- Firewall blocking port 22000: `sudo ufw allow 22000`
- Devices not added to each other: Use the web UI to add device IDs

## NUC Runs Hot

Check temperature:
```bash
cat /sys/class/thermal/thermal_zone*/temp
# Divide by 1000 for Celsius
```

If above 80C:
- Ensure airflow is not blocked
- Clean dust from the fan/vents
- Consider a cooling pad

## Raspberry Pi Specific Issues

### Low Memory Warnings

The Pi 4 with 4GB can be tight. Reduce memory usage:
- Use `--permission-mode acceptEdits` to avoid spawning extra processes
- Don't run Docker alongside Claude Code
- Consider swapping to a Pi 5 with 8GB

### SD Card Wear

SD cards have limited write cycles. For a 24/7 server:
- Boot from USB SSD instead (faster and more durable)
- Reduce logging: `sudo journalctl --vacuum-size=100M`
