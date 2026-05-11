#!/usr/bin/env bash
# Shared utility functions for Personal AI Secretary setup scripts

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Detect platform
detect_platform() {
  local arch
  arch=$(uname -m)

  if [[ -f /proc/device-tree/model ]] && grep -qi "raspberry" /proc/device-tree/model 2>/dev/null; then
    echo "raspberry-pi"
  elif [[ "$arch" == "x86_64" ]]; then
    echo "x86_64"
  elif [[ "$arch" == "aarch64" ]]; then
    echo "arm64"
  else
    echo "unknown"
  fi
}

# Detect OS
detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "$ID"
  else
    echo "unknown"
  fi
}

# Check if a command exists
has_cmd() {
  command -v "$1" &>/dev/null
}

# Check if running as root
check_not_root() {
  if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root. Run as your normal user (sudo will be used where needed)."
    exit 1
  fi
}

# Check if sudo is available
check_sudo() {
  if ! has_cmd sudo; then
    error "sudo is required but not installed."
    exit 1
  fi
}

# Prompt for yes/no
confirm() {
  local prompt="${1:-Continue?}"
  local response
  read -rp "$(echo -e "${CYAN}$prompt [y/N]:${NC} ")" response
  [[ "$response" =~ ^[Yy]$ ]]
}

# Prompt for input with default
prompt_with_default() {
  local prompt="$1"
  local default="$2"
  local response
  read -rp "$(echo -e "${CYAN}$prompt [${default}]:${NC} ")" response
  echo "${response:-$default}"
}

# Wait for a service to be ready
wait_for_service() {
  local service="$1"
  local max_wait="${2:-30}"
  local count=0

  info "Waiting for $service to start..."
  while ! systemctl is-active --quiet "$service" 2>/dev/null; do
    sleep 1
    count=$((count + 1))
    if [[ $count -ge $max_wait ]]; then
      error "$service failed to start within ${max_wait}s"
      return 1
    fi
  done
  success "$service is running"
}

# Check minimum RAM
check_ram() {
  local min_mb="${1:-2048}"
  local total_mb
  total_mb=$(awk '/MemTotal/ {printf "%.0f", $2/1024}' /proc/meminfo)

  if [[ $total_mb -lt $min_mb ]]; then
    warn "System has ${total_mb}MB RAM. Minimum recommended is ${min_mb}MB."
    return 1
  fi
  success "RAM: ${total_mb}MB"
}

# Print a section header
section() {
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  $*${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}
