# Raspberry Pi Setup Guide

This guide covers Pi-specific steps. The main [README](../README.md) applies to both NUC and Pi.

## Supported Models

| Model | RAM | Status |
|---|---|---|
| Raspberry Pi 5 (8GB) | 8GB | Recommended |
| Raspberry Pi 5 (4GB) | 4GB | Supported |
| Raspberry Pi 4 (8GB) | 8GB | Supported |
| Raspberry Pi 4 (4GB) | 4GB | Minimum (tight) |
| Raspberry Pi 4 (2GB) | 2GB | Not recommended |

## OS Installation

### Option 1: Raspberry Pi Imager (Recommended)

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Select **Ubuntu Server 24.04 LTS (64-bit)** or **Raspberry Pi OS (64-bit)**
3. Click the gear icon to pre-configure:
   - Enable SSH
   - Set username and password
   - Configure Wi-Fi
   - Set hostname
4. Flash to your SD card or USB SSD

### Option 2: Manual Flash

```bash
# Download Ubuntu Server for Pi
# Flash with dd (same as NUC, but use the ARM64 image)
diskutil unmountDisk /dev/diskX
sudo dd if=ubuntu-24.04-preinstalled-server-arm64+raspi.img of=/dev/rdiskX bs=4m status=progress
```

## Post-Install

### Boot from USB SSD (Recommended)

SD cards wear out with constant writes. An SSD is faster and more durable:

1. Flash the OS to a USB SSD using Pi Imager
2. Connect the SSD to a USB 3.0 port
3. Update the bootloader to prefer USB: `sudo raspi-config` > Advanced > Boot Order

### Increase Swap (4GB models)

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
```

### Reduce Memory Usage

Edit `/boot/firmware/config.txt`:

```
# Reduce GPU memory (headless server doesn't need it)
gpu_mem=16
```

## Then Follow the Main Guide

Once your Pi is running and you can SSH in, follow the main [README](../README.md) or run:

```bash
curl -fsSL https://raw.githubusercontent.com/soaldoAI/Personal-ai-secretary/main/install.sh | bash
```

The installer auto-detects Raspberry Pi and adjusts accordingly.

## Performance Expectations

| Task | Pi 4 (4GB) | Pi 4 (8GB) | Pi 5 (8GB) |
|---|---|---|---|
| Claude Code + Telegram | Works | Good | Great |
| + Syncthing | Tight | Good | Great |
| + Docker | Not recommended | Possible | Good |
| + Ollama (3B model) | Very slow | Slow | Usable |
