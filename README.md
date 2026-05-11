# Personal AI Secretary

Turn any Intel NUC or Raspberry Pi into a 24/7 AI-powered personal secretary using Claude Code — with Telegram messaging, file sync, and automated setup scripts.

![Platform](https://img.shields.io/badge/platform-Intel%20NUC%20%7C%20Raspberry%20Pi-blue)
![OS](https://img.shields.io/badge/OS-Ubuntu%2022.04%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## How It Works

```
  YOU (anywhere)                          CLOUD
  ┌──────────┐                    ┌──────────────────┐
  │  Phone   │──── Telegram ────►│  Telegram Bot API │
  │(Telegram)│◄── Bot API  ─────│                    │
  └──────────┘                    └────────┬─────────┘
                                           │
       ┌──────────┐               ┌────────▼─────────────────────────────┐
       │  Laptop  │               │  NUC / Raspberry Pi (always on)     │
       │          │               │                                      │
       │ Syncthing│◄─── LAN ────►│  ┌──────────────────────────────┐    │
       │ SSH      │               │  │ Claude Code + Telegram Plugin│    │
       └──────────┘               │  │ (runs in tmux via systemd)   │    │
                                  │  └──────────┬───────────────────┘    │
                                  │             │                        │
                                  │  ┌──────────▼───────────────┐        │
                                  │  │  Syncthing (file sync)   │        │
                                  │  │  Auto security updates   │        │
                                  │  └──────────────────────────┘        │
                                  └──────────────┬───────────────────────┘
                                                 │
                                        Anthropic API
                                                 │
                                  ┌──────────────▼───────────────┐
                                  │     Claude AI (cloud)        │
                                  │  (does the heavy thinking)   │
                                  └──────────────────────────────┘
```

**The idea is simple:** cheap local hardware runs the client, powerful cloud AI does the thinking. Your phone talks to it via Telegram. Your files stay synced. It never sleeps.

## What You Get

- **Always-on AI assistant** that runs 24/7 on cheap hardware (~$3/month electricity)
- **Telegram bot** — message your AI from your phone, anywhere
- **File sync** — two-way sync between your laptop and the server via Syncthing
- **Auto-updates** — security patches applied automatically
- **One-command install** — get everything running in minutes

## Quick Start

### One-Line Install

SSH into your NUC or Raspberry Pi and run:

```bash
curl -fsSL https://raw.githubusercontent.com/soaldoAI/Personal-ai-secretary/main/install.sh | bash
```

Or clone and run manually:

```bash
git clone https://github.com/soaldoAI/Personal-ai-secretary.git
cd Personal-ai-secretary
./install.sh
```

### What the Installer Does

1. Installs system dependencies (Node.js, npm, Bun, tmux, Docker, Syncthing)
2. Installs Claude Code
3. Installs the Telegram plugin
4. Configures systemd services for 24/7 operation
5. Sets up automatic security updates
6. Optionally configures a static IP and Syncthing file sync

## Requirements

### Hardware

| | Intel NUC | Raspberry Pi 4/5 |
|---|---|---|
| **RAM** | 8GB+ recommended | 4GB+ (8GB recommended) |
| **Storage** | 128GB+ SSD | 64GB+ SD card or SSD |
| **Network** | Ethernet or Wi-Fi | Ethernet or Wi-Fi |
| **Cost** | ~$200-300 used | ~$50-100 new |
| **Power** | ~15-25W | ~5-15W |

### Software

- Ubuntu 22.04+ (or Raspberry Pi OS 64-bit)
- Internet connection
- [Anthropic account](https://console.anthropic.com/) with Claude Code access
- Telegram account (for the bot)

## Manual Setup Guide

If you prefer to set things up step by step, follow the guides below.

### 1. Flash Ubuntu & Initial Setup

<details>
<summary>Click to expand</summary>

#### From a Mac

```bash
# Find your USB drive
diskutil list

# Flash Ubuntu ISO (replace disk4 with your USB disk number)
diskutil unmountDisk /dev/disk4
sudo dd if=~/Downloads/ubuntu-24.04-desktop-amd64.iso of=/dev/rdisk4 bs=4m status=progress
diskutil eject /dev/disk4
```

> **Warning:** Double-check the disk number. `dd` will overwrite whatever disk you point it at.

#### From Linux

```bash
# Find your USB drive
lsblk

# Flash Ubuntu ISO (replace sdX with your USB device)
sudo dd if=~/Downloads/ubuntu-24.04-desktop-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

#### Installer Options

- **LVM:** Yes (allows resizing partitions later)
- **Encryption:** No (headless machines need unattended boot)
- **SSH:** Enable OpenSSH server during install

Boot the NUC/Pi from USB (press **F10** on NUC for boot menu) and follow the installer.

</details>

### 2. SSH & Headless Configuration

<details>
<summary>Click to expand</summary>

#### Install SSH (if not done during install)

```bash
sudo apt update && sudo apt install -y openssh-server
```

#### Find Your Device on the Network

From another machine, scan your network:

```bash
# Ping sweep to populate ARP table
for i in $(seq 1 254); do ping -c1 -W1 192.168.1.$i &>/dev/null & done; wait

# Find your device by MAC address (check the sticker on your device)
arp -a | grep "your:mac:address"
```

#### Set Up SSH Key Auth

```bash
# Generate a key if you don't have one
ssh-keygen -t ed25519

# Copy it to your device
ssh-copy-id user@DEVICE_IP
```

#### Set Up Passwordless Sudo

```bash
ssh user@DEVICE_IP
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
sudo chmod 440 /etc/sudoers.d/$USER
```

</details>

### 3. Static IP Configuration

<details>
<summary>Click to expand</summary>

Or run the helper script:

```bash
./scripts/setup-static-ip.sh
```

Manually:

```bash
# Find your connection name
nmcli -t -f NAME,DEVICE con show --active

# Set static IP (adjust values for your network)
sudo nmcli con mod "YourConnectionName" \
  ipv4.addresses 192.168.1.50/24 \
  ipv4.gateway 192.168.1.1 \
  ipv4.dns "192.168.1.1,8.8.8.8,8.8.4.4" \
  ipv4.method manual

# Apply
sudo nmcli con down "YourConnectionName" && sudo nmcli con up "YourConnectionName"

# Verify
ip addr show
ping -c2 8.8.8.8
```

</details>

### 4. Install Claude Code

<details>
<summary>Click to expand</summary>

```bash
# Install Node.js and npm
sudo apt install -y nodejs npm

# Install Claude Code
sudo npm install -g @anthropic-ai/claude-code

# Verify
claude --version

# Authenticate (opens a URL — complete in your browser)
claude
```

</details>

### 5. Install Bun

<details>
<summary>Click to expand</summary>

The Telegram plugin requires Bun:

```bash
curl -fsSL https://bun.sh/install | bash

# Make available system-wide (required for services)
sudo ln -sf ~/.bun/bin/bun /usr/local/bin/bun

# Verify
bun --version
```

</details>

### 6. Telegram Bot Setup

<details>
<summary>Click to expand</summary>

Or run the helper script:

```bash
./scripts/setup-telegram.sh
```

Manually:

#### Create Your Bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Choose a name and username
4. Copy the bot token (looks like `123456789:AAH...`)

#### Install the Plugin

```bash
# Start Claude Code
claude

# In the Claude Code session:
/plugin install telegram@claude-plugins-official
```

#### Configure the Token

```bash
mkdir -p ~/.claude/channels/telegram
echo "TELEGRAM_BOT_TOKEN=YOUR_TOKEN_HERE" > ~/.claude/channels/telegram/.env
chmod 600 ~/.claude/channels/telegram/.env
```

#### Pair Your Account

```bash
# Start Claude Code with the Telegram channel
claude --channels plugin:telegram@claude-plugins-official

# Message your bot on Telegram — it replies with a 6-char code
# In the Claude Code session:
/telegram:access pair YOUR_CODE

# Lock it down
/telegram:access policy allowlist
```

#### Pre-Approve Permissions

Create or edit `~/.claude/settings.local.json`:

```json
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
```

</details>

### 7. Run as a 24/7 Service

<details>
<summary>Click to expand</summary>

Or run the helper script:

```bash
./scripts/setup-service.sh
```

Manually:

#### Install tmux

```bash
sudo apt install -y tmux
```

#### Create the Service

```bash
sudo tee /etc/systemd/system/claude-telegram.service << EOF
[Unit]
Description=Claude Code with Telegram Channel
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=$USER
Environment=PATH=$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin
Environment=HOME=$HOME
WorkingDirectory=$HOME
ExecStartPre=-/usr/bin/tmux kill-session -t claude-telegram
ExecStart=/usr/bin/tmux new-session -d -s claude-telegram '/usr/local/bin/claude --channels plugin:telegram@claude-plugins-official --permission-mode acceptEdits'
ExecStop=/usr/bin/tmux kill-session -t claude-telegram
RemainAfterExit=yes
Restart=on-failure
RestartSec=15

[Install]
WantedBy=multi-user.target
EOF
```

#### Enable and Start

```bash
sudo systemctl daemon-reload
sudo systemctl enable claude-telegram
sudo systemctl start claude-telegram
```

#### Accept the Trust Prompt (first time only)

```bash
# Check what Claude Code is showing
tmux capture-pane -t claude-telegram -p

# Accept the trust prompt
tmux send-keys -t claude-telegram Enter
```

#### Manage the Service

```bash
# Check status
sudo systemctl status claude-telegram

# View Claude Code session
tmux attach -t claude-telegram
# (Press Ctrl+B then D to detach without stopping)

# Restart
sudo systemctl restart claude-telegram

# View logs
sudo journalctl -u claude-telegram -f
```

</details>

### 8. File Sync with Syncthing

<details>
<summary>Click to expand</summary>

Or run the helper script:

```bash
./scripts/setup-syncthing.sh
```

Manually:

#### Install on Server (NUC/Pi)

```bash
sudo apt install -y syncthing
sudo systemctl enable syncthing@$USER
sudo systemctl start syncthing@$USER
```

#### Install on Your Laptop

```bash
# Mac
brew install syncthing
brew services start syncthing

# Linux
sudo apt install -y syncthing
sudo systemctl enable syncthing@$USER
sudo systemctl start syncthing@$USER
```

#### Initial Copy (faster than Syncthing for large folders)

```bash
rsync -avz --progress --exclude='.DS_Store' \
  ~/Documents/Projects/ \
  user@DEVICE_IP:~/Documents/Projects/
```

#### Configure

1. Open `http://localhost:8384` on both machines
2. Add each device to the other (use device IDs)
3. Create a shared folder pointing to your project directory
4. Set folder type to "Send & Receive"

</details>

### 9. Automatic Security Updates

<details>
<summary>Click to expand</summary>

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Enable auto-reboot at 4am for kernel updates
sudo sed -i 's|//Unattended-Upgrade::Automatic-Reboot "false";|Unattended-Upgrade::Automatic-Reboot "true";|' \
  /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's|//Unattended-Upgrade::Automatic-Reboot-Time "02:00";|Unattended-Upgrade::Automatic-Reboot-Time "04:00";|' \
  /etc/apt/apt.conf.d/50unattended-upgrades
```

</details>

## Project Structure

```
personal-ai-secretary/
├── install.sh                    # One-line installer
├── scripts/
│   ├── setup-static-ip.sh       # Interactive static IP configuration
│   ├── setup-telegram.sh        # Telegram bot setup helper
│   ├── setup-service.sh         # systemd service setup
│   ├── setup-syncthing.sh       # Syncthing file sync setup
│   ├── setup-security.sh        # Auto-update configuration
│   └── utils.sh                 # Shared utility functions
├── config/
│   ├── claude-telegram.service  # systemd service template
│   ├── settings.local.json      # Claude Code permissions template
│   └── access.json              # Telegram access control template
├── docs/
│   ├── BLOG.md                  # Full blog post / detailed walkthrough
│   ├── TROUBLESHOOTING.md       # Common issues and fixes
│   ├── RASPBERRY_PI.md          # Pi-specific instructions
│   └── ARCHITECTURE.md          # How it all fits together
└── README.md                    # This file
```

## Troubleshooting

| Problem | Solution |
|---|---|
| Telegram bot not responding | Check `tmux capture-pane -t claude-telegram -p` — may be stuck on trust prompt |
| Permission prompts on every message | Ensure `settings.local.json` has the correct tool names and restart the session |
| `bun: command not found` | Run `sudo ln -sf ~/.bun/bin/bun /usr/local/bin/bun` |
| SSH connection refused | Run `sudo apt install openssh-server && sudo systemctl start ssh` |
| IP address keeps changing | Run `./scripts/setup-static-ip.sh` to configure a static IP |
| Claude Code auth expired | SSH in and run `claude` to re-authenticate |

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more.

## Supported Platforms

| Platform | Status | Notes |
|---|---|---|
| Intel NUC (any gen) | Fully supported | Recommended for best performance |
| Raspberry Pi 5 | Fully supported | 8GB model recommended |
| Raspberry Pi 4 | Supported | 4GB minimum, 8GB recommended |
| Any x86_64 Linux | Should work | Tested on Ubuntu 22.04+ |
| Any ARM64 Linux | Should work | Tested on Raspberry Pi OS |

## Running Costs

| Item | Cost |
|---|---|
| Hardware (used NUC) | ~$200-300 one-time |
| Hardware (Raspberry Pi 5) | ~$80-100 one-time |
| Electricity (NUC) | ~$3-5/month |
| Electricity (Pi) | ~$1-2/month |
| Claude subscription | Your existing plan |
| Software | Free (all open-source) |

## Contributing

Contributions welcome! Please open an issue or PR.

## License

MIT License — see [LICENSE](LICENSE) for details.
