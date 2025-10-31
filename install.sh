#!/bin/bash

set -e

DOTFILES_DIR="$(pwd)"

echo "======================================"
echo "  Omarchrot Installation Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ]; then
  echo -e "${RED}This script is designed for Arch Linux only!${NC}"
  exit 1
fi

# Check for AUR helper
if command -v yay &>/dev/null; then
  AUR_HELPER="yay"
elif command -v paru &>/dev/null; then
  AUR_HELPER="paru"
else
  echo -e "${YELLOW}No AUR helper found. Installing yay...${NC}"
  sudo pacman -Syu
  sudo pacman -S --needed git base-devel
  if [[ ! -d "/tmp/yay" ]]; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
  fi

  cd /tmp/yay
  makepkg -si --noconfirm
  cd "$DOTFILES_DIR"
  AUR_HELPER="yay"
fi

echo -e "${GREEN}Using AUR helper: $AUR_HELPER${NC}"
echo ""

# Initialize git submodules (for neovim config)
echo -e "${YELLOW}Initializing git submodules...${NC}"
git submodule update --init --recursive

# Install official packages
echo -e "${YELLOW}Installing official packages...${NC}"
if [ -f "$DOTFILES_DIR/packages.txt" ]; then
  sudo pacman -Syu
  sudo pacman -S --needed $(grep -v '^#' "$DOTFILES_DIR/packages.txt" | grep -v '^$')
else
  echo -e "${RED}packages.txt not found!${NC}"
  exit 1
fi

# Install AUR packages
echo -e "${YELLOW}Installing AUR packages...${NC}"
if [ -f "$DOTFILES_DIR/aur-packages.txt" ]; then
  $AUR_HELPER -Syu
  $AUR_HELPER -S --needed $(grep -v '^#' "$DOTFILES_DIR/aur-packages.txt" | grep -v '^$')
else
  echo -e "${YELLOW}aur-packages.txt not found, skipping AUR packages${NC}"
fi

# Copy configuration files
echo ""
echo -e "${YELLOW}Copying configuration files...${NC}"

# Backup function
backup_if_exists() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo -e "${YELLOW}Backing up existing $1 to $1.backup${NC}"
    mv "$1" "$1.backup"
  fi
}

# Copy .config directories and files
for item in "$DOTFILES_DIR/.config"/*; do
  basename_item=$(basename "$item")

  # Skip gtk-3.0, gtk-4.0, and Kvantum
  if [[ "$basename_item" == "gtk-3.0" || "$basename_item" == "gtk-4.0" || "$basename_item" == "Kvantum" ]]; then
    echo -e "${YELLOW}Skipping:${NC} $basename_item"
    continue
  fi

  if [ -d "$item" ]; then
    target="$HOME/.config/$basename_item"
    backup_if_exists "$target"
    cp -r "$item" "$target"
    echo -e "${GREEN}Copied:${NC} $basename_item"
  elif [ -f "$item" ]; then
    target="$HOME/.config/$basename_item"
    backup_if_exists "$target"
    cp "$item" "$target"
    echo -e "${GREEN}Copied:${NC} $basename_item"
  fi
done

# Copy scripts
echo ""
echo -e "${YELLOW}Installing scripts to ~/.local/bin...${NC}"
mkdir -p "$HOME/.local/bin"

for script in "$DOTFILES_DIR/.local/bin"/*.sh; do
  if [ -f "$script" ]; then
    target="$HOME/.local/bin/$(basename "$script")"
    backup_if_exists "$target"
    cp "$script" "$target"
    chmod +x "$target"
    echo -e "${GREEN}Copied:${NC} $(basename "$script")"
  fi
done

# Copy .local/share assets
if [ -d "$DOTFILES_DIR/.local/share" ]; then
  echo ""
  echo -e "${YELLOW}Copying .local/share assets...${NC}"
  mkdir -p "$HOME/.local/share"
  for item in "$DOTFILES_DIR/.local/share"/*; do
    if [ -e "$item" ]; then
      basename_item=$(basename "$item")
      target="$HOME/.local/share/$basename_item"
      backup_if_exists "$target"
      cp -r "$item" "$target"
      echo -e "${GREEN}Copied:${NC} .local/share/$basename_item"
    fi
  done
fi

# Generate keybindings.json
if [ -f "$HOME/.local/bin/update-keybindings-json.sh" ]; then
  echo ""
  echo -e "${YELLOW}Generating keybindings.json...${NC}"
  bash "$HOME/.local/bin/update-keybindings-json.sh"
fi

# Enable and start services
echo ""
echo -e "${YELLOW}Enabling system services...${NC}"
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Enable battery monitor timer (if systemd files exist)
if [ -f "$HOME/.config/systemd/user/battery-monitor.timer" ]; then
  echo -e "${YELLOW}Enabling battery monitor timer...${NC}"
  systemctl --user daemon-reload
  systemctl --user enable --now battery-monitor.timer
  echo -e "${GREEN}Battery monitor enabled${NC}"
fi

if command -v bluetoothctl &>/dev/null; then
  sudo systemctl enable bluetooth
  sudo systemctl start bluetooth
fi

mkdir ~/Videos
mkdir ~/Pictures

echo ""
echo -e "${GREEN}======================================"
echo "  Installation Complete!"
echo "======================================${NC}"
echo ""
echo "Configuration files have been copied to your home directory."
echo "To update configs, edit files in ~/.config/ directly."
echo ""
echo "For developers: Use ./dev-install.sh to symlink configs instead."
echo ""
echo "Next steps:"
echo "1. Log out and log back in to Hyprland"
echo "2. Customize ~/.config/hypr/monitors.conf for your setup"
echo "3. Done"
echo ""
