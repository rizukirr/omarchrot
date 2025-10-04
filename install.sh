#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  sudo pacman -S --needed git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
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
  sudo pacman -S --needed "$(grep -v '^#' "$DOTFILES_DIR/packages.txt" | grep -v '^$')"
else
  echo -e "${RED}packages.txt not found!${NC}"
  exit 1
fi

# Install AUR packages
echo -e "${YELLOW}Installing AUR packages...${NC}"
if [ -f "$DOTFILES_DIR/aur-packages.txt" ]; then
  $AUR_HELPER -S --needed "$(grep -v '^#' "$DOTFILES_DIR/aur-packages.txt" | grep -v '^$')"
else
  echo -e "${YELLOW}aur-packages.txt not found, skipping AUR packages${NC}"
fi

# Create symlinks
echo ""
echo -e "${YELLOW}Creating symlinks...${NC}"

# Backup function
backup_if_exists() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo -e "${YELLOW}Backing up existing $1 to $1.backup${NC}"
    mv "$1" "$1.backup"
  fi
}

# Symlink .config directories
for dir in "$DOTFILES_DIR/.config"/*; do
  if [ -d "$dir" ]; then
    target="$HOME/.config/$(basename "$dir")"
    backup_if_exists "$target"
    ln -sf "$dir" "$target"
    echo -e "${GREEN}Linked:${NC} $(basename "$dir")"
  fi
done

# Symlink shell configs
if [ -f "$DOTFILES_DIR/.bashrc" ]; then
  backup_if_exists "$HOME/.bashrc"
  ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
  echo -e "${GREEN}Linked:${NC} .bashrc"
fi

# Symlink scripts
echo ""
echo -e "${YELLOW}Installing scripts to ~/.local/bin...${NC}"
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

echo ""
echo -e "${GREEN}======================================"
echo "  Installation Complete!"
echo "======================================${NC}"
echo ""
echo "Next steps:"
echo "1. Log out and log back in to Hyprland"
echo "2. Customize monitors.conf for your setup"
echo "3. Done"
echo ""
