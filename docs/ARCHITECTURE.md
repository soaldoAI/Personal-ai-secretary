# Architecture

## How It All Fits Together

```
                    ┌─────────────────┐
                    │   Your Phone    │
                    │   (Telegram)    │
                    └────────┬────────┘
                             │
                    Telegram Bot API
                             │
┌────────────────────────────┼────────────────────────────┐
│  NUC / Raspberry Pi        │                            │
│                            │                            │
│  ┌─────────────────────────▼──────────────────────┐     │
│  │  systemd: claude-telegram.service              │     │
│  │  └─ tmux session: claude-telegram              │     │
│  │     └─ claude --channels plugin:telegram       │     │
│  │        ├─ Claude Code CLI                      │     │
│  │        │  └─ Anthropic API (cloud) ◄──────────────── Claude AI
│  │        └─ Telegram MCP Server (bun)            │     │
│  │           └─ Receives/sends Telegram messages  │     │
│  └────────────────────────────────────────────────┘     │
│                                                         │
│  ┌────────────────────┐  ┌──────────────────────┐       │
│  │  Syncthing         │  │  unattended-upgrades │       │
│  │  (file sync)       │  │  (auto security)     │       │
│  └─────────┬──────────┘  └──────────────────────┘       │
│            │                                            │
└────────────┼────────────────────────────────────────────┘
             │
        LAN / Wi-Fi
             │
┌────────────▼──────────┐
│  Your Laptop          │
│  ├─ Syncthing         │
│  │  (two-way sync)    │
│  └─ SSH access        │
└───────────────────────┘
```

## Components

### Claude Code
The core AI engine. Runs as a CLI tool that connects to Anthropic's API. All AI processing happens in the cloud — the local machine just runs the lightweight client.

### Telegram Plugin (MCP Server)
A Model Context Protocol server that bridges Telegram and Claude Code. Runs on Bun. Receives messages from the Telegram Bot API, forwards them to Claude Code, and sends responses back.

### tmux
Provides the pseudo-terminal that Claude Code requires. Without it, Claude Code can't run as a background service because it expects an interactive terminal.

### systemd
Manages the lifecycle — starts on boot, restarts on failure, stops cleanly. The service runs tmux, which runs Claude Code.

### Syncthing
Peer-to-peer file sync. No cloud relay. Files sync directly between your laptop and the server over your local network. Two-way by default.

### unattended-upgrades
Automatically installs security patches daily. Optionally reboots at a configured time if a kernel update requires it.

## Data Flow

### Inbound Message (Phone → AI)

1. You send a message to your Telegram bot
2. Telegram Bot API delivers it to the MCP server (bun process)
3. MCP server pushes it into the Claude Code session
4. Claude Code sends it to Anthropic's API
5. Claude processes and returns a response
6. Claude Code calls the `reply` tool via MCP
7. MCP server sends the reply through Telegram Bot API
8. You see the reply in Telegram

### File Sync

1. You save a file on your laptop
2. Syncthing detects the change (filesystem watcher)
3. Syncthing transfers the file to the server over LAN
4. Claude Code on the server can now read/edit the file
5. Changes made by Claude Code sync back to your laptop

## Security Model

- **Telegram access:** Locked to an allowlist of Telegram user IDs
- **SSH:** Key-based authentication only (password auth can be disabled)
- **Sudo:** Passwordless for the service user only
- **Bot token:** Stored with 600 permissions (owner-only read)
- **Network:** Everything stays on your local network (except Anthropic API calls and Telegram API)
- **Updates:** Security patches applied automatically
