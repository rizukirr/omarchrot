#!/bin/bash

set -e

DOTFILES_DIR="$(pwd)"

echo "======================================"
echo "  Omarchrot Developer Installation"
echo "======================================"
echo ""
echo "This script installs packages and creates symlinks for development."
echo "Most configs will be symlinked, but machine-specific and user files will be copied."
echo ""
echo "For regular installation (copy all files), use install.sh instead."
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

# Backup function
backup_if_exists() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo -e "${YELLOW}Backing up existing $1 to $1.backup${NC}"
    mv "$1" "$1.backup"
  fi
}

# Deploy configuration files
echo ""
echo -e "${YELLOW}Deploying configuration files...${NC}"

# Process .config items (symlink most, copy machine-specific)
for item in "$DOTFILES_DIR/.config"/*; do
  basename_item=$(basename "$item")

  # Skip gtk-3.0, gtk-4.0, and Kvantum (managed by nwg-look/qt6ct)
  if [[ "$basename_item" == "gtk-3.0" || "$basename_item" == "gtk-4.0" || "$basename_item" == "Kvantum" ]]; then
    echo -e "${YELLOW}Skipping:${NC} $basename_item"
    continue
  fi

  target="$HOME/.config/$basename_item"

  # Check if this is a machine-specific config file
  if [[ "$basename_item" == "monitors.conf" || "$basename_item" == "hyprpaper.conf" ]]; then
    # Copy machine-specific files
    backup_if_exists "$target"
    if [ -d "$item" ]; then
      cp -r "$item" "$target"
    else
      cp "$item" "$target"
    fi
    echo -e "${GREEN}Copied:${NC} $basename_item (machine-specific)"
  else
    # Symlink everything else
    backup_if_exists "$target"
    ln -sf "$item" "$target"
    echo -e "${GREEN}Linked:${NC} $basename_item"
  fi
done

# Copy .bashrc (user-customizable)
echo ""
echo -e "${YELLOW}Copying .bashrc...${NC}"
if [ -f "$DOTFILES_DIR/.bashrc" ]; then
  backup_if_exists "$HOME/.bashrc"
  cp "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
  echo -e "${GREEN}Copied:${NC} .bashrc (user-customizable)"
fi

# Symlink scripts
echo ""
echo -e "${YELLOW}Symlinking scripts to ~/.local/bin...${NC}"
mkdir -p "$HOME/.local/bin"

for script in "$DOTFILES_DIR/.local/bin"/*.sh; do
  if [ -f "$script" ]; then
    target="$HOME/.local/bin/$(basename "$script")"
    backup_if_exists "$target"
    ln -sf "$script" "$target"
    chmod +x "$target"
    echo -e "${GREEN}Linked:${NC} $(basename "$script")"
  fi
done

# Copy .local/share assets (binary/runtime data)
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
      echo -e "${GREEN}Copied:${NC} .local/share/$basename_item (assets)"
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

echo ""
echo -e "${GREEN}======================================"
echo "  Developer Installation Complete!"
echo "======================================${NC}"
echo ""
echo "Most config files are symlinked to this repository."
echo "Changes in the repo will immediately affect your system."
echo ""
echo "Copied (not symlinked):"
echo "  - .bashrc (user-customizable)"
echo "  - .local/share/ (assets)"
echo "  - monitors.conf, hyprpaper.conf (machine-specific)"
echo ""
echo "Next steps:"
echo "1. Log out and log back in to Hyprland"
echo "2. Customize ~/.config/hypr/monitors.conf for your setup"
echo "3. Edit configs in this repo to see changes immediately"
echo ""
