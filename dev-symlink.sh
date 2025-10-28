#!/bin/bash

set -e

DOTFILES_DIR="$(pwd)"

echo "======================================"
echo "  Developer Symlink Setup"
echo "======================================"
echo ""
echo "This script creates symlinks from this repository to your home directory."
echo "Use this if you want to edit configs in the repo and see changes immediately."
echo ""
echo "For regular installation (copy files), use install.sh instead."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Backup function
backup_if_exists() {
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo -e "${YELLOW}Backing up existing $1 to $1.backup${NC}"
    mv "$1" "$1.backup"
  fi
}

echo -e "${YELLOW}Creating symlinks...${NC}"
echo ""

# Symlink .config directories and files
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
    ln -sf "$item" "$target"
    echo -e "${GREEN}Linked:${NC} $basename_item"
  elif [ -f "$item" ]; then
    target="$HOME/.config/$basename_item"
    backup_if_exists "$target"
    ln -sf "$item" "$target"
    echo -e "${GREEN}Linked:${NC} $basename_item"
  fi
done

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

echo ""
echo -e "${GREEN}======================================"
echo "  Symlink Setup Complete!"
echo "======================================${NC}"
echo ""
echo "Your config files are now symlinked to this repository."
echo "Any changes you make in this repo will immediately affect your system."
echo ""
echo "Next steps:"
echo "1. Reload your window manager/desktop to apply changes"
echo "2. Edit configs in this repo as needed"
echo ""
