# How I Turned a $300 Intel NUC Into My Always-On AI Secretary

**I wanted an AI assistant that never sleeps.** One that answers emails while I'm at the beach, drafts marketing copy at 3am, and pings me on Telegram when something needs my attention. Not a cloud VM I'm paying hourly for — a quiet little box sitting on my desk, running 24/7, costing pennies in electricity.

Here's how I set it up in an afternoon.

---

## Why a NUC?

For the uninitiated, an Intel NUC (Next Unit of Computing) is a palm-sized mini PC. Mine is a NUC7i7BNH — a dual-core i7 with 30GB of RAM and a 1TB NVMe SSD. You can pick one up second-hand for under $300.

Why not just use a cloud server? Three reasons:

1. **Cost.** A comparable cloud VM runs $50-100/month. The NUC draws about 15-25 watts — roughly $3/month in electricity. It pays for itself in three months.
2. **Privacy.** My emails, documents, and credentials never leave my local network.
3. **Always on.** Unlike my laptop, which sleeps when I close the lid, the NUC runs around the clock. My AI secretary doesn't take breaks.

## The Setup: From Unboxing to AI Secretary

### Step 1: Installing Ubuntu

I flashed Ubuntu Desktop onto a USB drive directly from my Mac's terminal using `dd` — no third-party tools needed.

First, download the Ubuntu Desktop ISO (amd64 — this works for both Intel and AMD processors). Then plug in a USB drive (8GB minimum) and find its device identifier:

```bash
diskutil list
```

Look for your USB drive by size — it'll be something like `/dev/disk4`. Then flash it:

```bash
diskutil unmountDisk /dev/disk4
sudo dd if=~/Downloads/ubuntu-24.04-desktop-amd64.iso of=/dev/rdisk4 bs=4m status=progress
diskutil eject /dev/disk4
```

> **Warning:** Double-check the disk number. `dd` will happily overwrite your Mac's boot drive if you point it at the wrong disk. The `r` prefix in `rdisk4` uses the raw device for much faster writes.

Plug the USB into the NUC, power on, and press **F10** to open the boot menu. Select the USB drive and follow the Ubuntu installer.

I went with Ubuntu Desktop over Server for one reason: remote desktop. When I need a GUI — whether it's reviewing a document or checking something visually — I can connect from my Mac without needing a physical monitor attached to the NUC.

A few decisions I made during setup:

- **LVM enabled** — so I can resize partitions later without reinstalling
- **No disk encryption** — the NUC is headless, and encryption would require a keyboard and monitor on every reboot
- **Static IP** — so I always know where to find it on my network
- **SSH enabled** — my primary way of managing the machine
- **Automatic security updates** — with auto-reboot at 4am if a kernel update requires it

### Step 2: Going Headless

Once Ubuntu was installed, I configured everything for remote management.

**Install SSH** (if you didn't enable it during install):

```bash
sudo apt update && sudo apt install -y openssh-server
```

**Find your NUC on the network.** From your Mac, scan for it using its MAC address (check the sticker on the NUC):

```bash
# Ping sweep to populate ARP table
for i in $(seq 1 254); do ping -c1 -W1 192.168.0.$i &>/dev/null & done; wait
# Find your device by MAC
arp -a | grep "aa:bb:cc:dd:ee:ff"
```

**Set up SSH key auth** so you never need to type a password:

```bash
# Copy your public key to the NUC
ssh-copy-id user@<NUC_IP>
```

**Set up passwordless sudo** on the NUC for remote management:

```bash
echo "yourusername ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/yourusername
sudo chmod 440 /etc/sudoers.d/yourusername
```

**Configure a static IP** so the NUC always lives at the same address. Find your Wi-Fi connection name first:

```bash
nmcli -t -f NAME,DEVICE con show --active
```

Then assign a static IP:

```bash
sudo nmcli con mod "YourWiFiName" \
  ipv4.addresses 192.168.0.50/24 \
  ipv4.gateway 192.168.0.1 \
  ipv4.dns "192.168.0.1,8.8.8.8,8.8.4.4" \
  ipv4.method manual

# Apply the changes
sudo nmcli con down "YourWiFiName" && sudo nmcli con up "YourWiFiName"
```

**Enable automatic security updates:**

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

To enable auto-reboot when kernel updates require it, edit `/etc/apt/apt.conf.d/50unattended-upgrades`:

```
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
```

From this point on, the monitor and keyboard went back in the drawer. Everything happens over SSH.

### Step 3: Installing Claude Code

Claude Code is Anthropic's CLI tool for interacting with Claude directly from the terminal. Installation was straightforward:

```bash
# Install Node.js and npm
sudo apt install -y nodejs npm

# Install Claude Code globally
sudo npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version
```

Then run `claude` for the first time. It will display a URL — open that URL in a browser on any device (your phone works), log in with your Anthropic account, and paste the code back into the terminal. The auth token persists in `~/.claude/` across reboots, so this is truly a set-and-forget step.

You'll also want to install **Bun** — the Telegram plugin needs it:

```bash
curl -fsSL https://bun.sh/install | bash

# Make it available system-wide (important for services)
sudo ln -sf ~/.bun/bin/bun /usr/local/bin/bun
```

### Step 4: The Telegram Bot — AI in My Pocket

This is where it gets interesting. Claude Code has a plugin ecosystem, and one of the plugins is a Telegram bridge. It turns a Telegram bot into a two-way channel: I message the bot from my phone, and Claude Code on the NUC responds.

**Create a Telegram bot.** Open Telegram, message `@BotFather`, send `/newbot`, and follow the prompts. You'll get a token like `123456789:AAH...` — save it.

**Install the Telegram plugin.** Start a Claude Code session and run:

```
/plugin install telegram@claude-plugins-official
```

**Configure the bot token:**

```bash
mkdir -p ~/.claude/channels/telegram
echo "TELEGRAM_BOT_TOKEN=your_token_here" > ~/.claude/channels/telegram/.env
chmod 600 ~/.claude/channels/telegram/.env
```

**Launch Claude Code with the Telegram channel:**

```bash
claude --channels plugin:telegram@claude-plugins-official
```

**Pair your Telegram account.** Message your bot on Telegram — it replies with a 6-character code. In the Claude Code session:

```
/telegram:access pair <code>
```

**Lock it down** so only you can message the bot:

```
/telegram:access policy allowlist
```

**Pre-approve Telegram permissions** so replies don't trigger interactive prompts. Add these to `~/.claude/settings.local.json`:

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

**Run it as a persistent service.** The critical piece was getting Claude Code to run as a background service. Claude Code needs an interactive terminal, so I used `tmux` inside a `systemd` service:

```bash
# Install tmux
sudo apt install -y tmux
```

Create `/etc/systemd/system/claude-telegram.service`:

```ini
[Unit]
Description=Claude Code with Telegram Channel
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=yourusername
Environment=PATH=/home/yourusername/.bun/bin:/usr/local/bin:/usr/bin:/bin
Environment=HOME=/home/yourusername
WorkingDirectory=/home/yourusername
ExecStartPre=-/usr/bin/tmux kill-session -t claude-telegram
ExecStart=/usr/bin/tmux new-session -d -s claude-telegram '/usr/local/bin/claude --channels plugin:telegram@claude-plugins-official --permission-mode acceptEdits'
ExecStop=/usr/bin/tmux kill-session -t claude-telegram
RemainAfterExit=yes
Restart=on-failure
RestartSec=15

[Install]
WantedBy=multi-user.target
```

Enable and start it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable claude-telegram
sudo systemctl start claude-telegram
```

> **Note:** The `--permission-mode acceptEdits` flag auto-approves tool calls, which is essential for headless operation. On first launch, you'll need to accept the trust prompt via tmux:
>
> ```bash
> # Attach to see what's happening
> tmux attach -t claude-telegram
> # Or send a keystroke remotely
> tmux send-keys -t claude-telegram Enter
> ```

Now I can message my AI from anywhere — the train, the couch, or bed at midnight — and get a response in seconds.

### Step 5: File Sync with Syncthing

I keep all my project files in a structured folder on my Mac. I needed those same files accessible to Claude Code on the NUC, and I needed changes to flow both ways — sometimes I work on my laptop, sometimes I work remotely through the NUC.

Syncthing handles this perfectly. It's an open-source, peer-to-peer file sync tool. No cloud, no subscriptions, no file size limits.

**Install on both machines:**

```bash
# Mac
brew install syncthing
brew services start syncthing

# NUC (Ubuntu)
sudo apt install -y syncthing
sudo systemctl enable syncthing@yourusername
sudo systemctl start syncthing@yourusername
```

**Do the initial copy** with rsync (faster than waiting for Syncthing to transfer gigabytes):

```bash
rsync -avz --progress --exclude='.DS_Store' \
  ~/Documents/Projects/ \
  user@NUC_IP:~/Documents/Projects/
```

**Configure Syncthing** via its web UI at `http://localhost:8384` on each machine, or use the REST API:

1. Get each device's ID: `syncthing --device-id`
2. Add each device to the other
3. Create a shared folder pointing to your project directory
4. Set the folder type to "Send & Receive" for two-way sync

Changes sync automatically over the local network. Edit a file on my Mac, and it appears on the NUC within seconds. Work on something through the NUC's Claude Code session, and it syncs back to my laptop.

## What My AI Secretary Actually Does

With this setup running, here's what my typical day looks like:

**Morning.** I message my Telegram bot: "What's on my plate today?" Claude reviews my project files, checks recent notes, and gives me a prioritised summary.

**During meetings.** I forward a quick note to the bot: "Draft a follow-up email to the client about the proposal." By the time the meeting ends, there's a draft waiting.

**Marketing.** "Create social media copy for our new product launch based on the brief in the marketing folder." Claude has access to all my project files through Syncthing, so it knows the context.

**Late at night.** I think of something before bed. Instead of opening my laptop, I message the bot from my phone. The NUC processes it, and the result is waiting for me in the morning.

**While I'm away.** The NUC doesn't sleep. If I set up email monitoring or scheduled tasks, they run whether I'm at my desk or on a flight.

## The Two-Bot Strategy

I actually run two separate Telegram bots — one connected to Claude Code on my Mac, and one on the NUC. Why?

- **The NUC bot is my primary** — it's always on, always reachable
- **The Mac bot is for desk work** — when I'm at my laptop and want tighter integration with my local dev environment
- They're completely independent. Different bot tokens, different sessions, no conflicts

## What About Running Local LLMs?

I explored running Ollama on the NUC for local, offline AI. The verdict: it works, but with limits. Without a discrete GPU, everything runs on CPU. Small models (3B-8B parameters) are usable. Anything larger gets painfully slow.

My recommendation: use the NUC as a reliable host for Claude Code (which calls Anthropic's API) and reserve local models for offline or privacy-sensitive tasks only.

## Hardware Considerations

The NUC7i7BNH is a solid choice for this use case, but here's what matters:

| Component | What You Need | Why |
|---|---|---|
| **RAM** | 16GB minimum, 32GB ideal | Claude Code itself is lightweight, but you'll want headroom for other services |
| **Storage** | 256GB+ NVMe | Fast storage for file sync and project files |
| **CPU** | Any modern i5/i7 | Claude Code is not CPU-intensive — the heavy lifting happens on Anthropic's servers |
| **GPU** | Not needed | No local model training; API-based AI doesn't need local GPU |
| **Network** | Ethernet preferred | More reliable than Wi-Fi for an always-on server |

One thing the NUC7 lacks is Thunderbolt 3, so external GPUs aren't an option. If local LLM performance matters to you, look at NUC8 or newer, or consider a separate GPU-equipped machine.

## Running Costs

Let's talk real numbers:

- **Hardware:** ~$200-300 (used NUC with RAM and SSD)
- **Electricity:** ~$3-5/month (15-25W idle)
- **Claude subscription:** Your existing plan — no additional cost
- **Software:** All free and open-source (Ubuntu, Syncthing, Claude Code)

Compare that to a cloud VM with similar specs: $50-100/month. The NUC pays for itself in 3-6 months and keeps running for years.

## Lessons Learned

**1. The trust prompt is annoying.** Claude Code asks "do you trust this folder?" on every new session. When running headless via systemd, you need to handle this programmatically — I send keystrokes to the tmux session to accept it.

**2. Permission management matters.** Claude Code's tool-use permissions need to be pre-configured for headless operation. Without the right settings, every Telegram reply triggers a permission prompt that nobody's there to approve.

**3. Bun, not Node.** The Telegram plugin runs on Bun, not Node.js. Make sure it's installed and in your system PATH — not just your user profile — or the MCP server won't spawn when running as a service.

**4. Static IP is non-negotiable.** DHCP will change your NUC's IP address periodically. You don't want to hunt for your server every time your router reassigns addresses.

**5. SSH key auth from day one.** Password-based SSH is fine for initial setup, but key auth makes everything smoother — especially for automated scripts and remote management.

## What's Next

This setup is just the foundation. Here's what I'm building on top of it:

- **Email integration** — monitoring and drafting responses automatically
- **Scheduled reports** — daily summaries of project activity
- **Remote desktop** — full GUI access to the NUC from my Mac when needed
- **OpenClaw integration** — an open-source agent framework for more sophisticated automation
- **Multi-agent workflows** — different Claude Code instances handling different responsibilities

## The Bottom Line

For under $300 and an afternoon of setup, I have an AI secretary that:

- Runs 24/7 without babysitting
- Responds to messages on Telegram from anywhere
- Has access to all my project files
- Costs less than a coffee per month to run
- Keeps everything on my local network

The Intel NUC isn't the most powerful machine in the world. But it doesn't need to be. It's a reliable, silent, always-on host for an AI that does the heavy thinking in the cloud. And that combination — cheap local hardware plus powerful cloud AI — is genuinely useful in a way that surprised me.

If you've got a spare NUC collecting dust, give it a purpose. Your future self will thank you.

---

*Have questions about this setup? Want to see a deeper dive into any of these steps? Drop a comment or reach out — happy to share more details.*
