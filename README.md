# hyprsimple

> Clean. Basic. No Fancy. Everything you need.

A **minimal aesthetics** Hyprland dotfiles collection for Arch Linux. This is a personal configuration focused on **simplicity, beauty, and productivity** — stripped down to essentials, refined for daily use.

**Philosophy**: Every element serves a purpose. No unnecessary widgets, no distracting animations, no visual noise. Just a clean, functional workspace that gets out of your way.

---

## Table of Contents

- [Preview](#preview)
- [Core Stack](#core-stack)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Package](#package-philosophy)
- [Architecture](#architecture)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Preview

![Screenshot 1](assets/image1.png)
![Screenshot 2](assets/image2.png)
![Screenshot 3](assets/image3.png)
![Screenshot 4](assets/image4.png)
![Screenshot 5](assets/image5.png)

---

## Core Stack

| Component         | Choice          | Why                                             |
| ----------------- | --------------- | ----------------------------------------------- |
| **WM**            | Hyprland        | Smooth Wayland compositor, minimal yet powerful |
| **Bar**           | Waybar          | Clean, customizable, no bloat                   |
| **Launcher**      | Wofi            | Fast, minimal, keyboard-driven                  |
| **Terminal**      | Kitty           | GPU-accelerated, clean aesthetics               |
| **Shell**         | Bash + Starship | Simple, fast, beautiful prompt                  |
| **Notifications** | Dunst           | Unobtrusive, scriptable OSD                     |
| **Editor**        | Neovim          | Efficient, distraction-free coding              |
| **Browser**       | Firefox         | Customizable, privacy-focused                   |
| **File Manager**  | Thunar          | Lightweight, GTK-based                          |
| **Notes**         | Obsidian        | Markdown-based knowledge management             |

---

## Features

### Minimalist Design Principles

- **Modular Configuration**: Hyprland configs split into 12 files for easy customization
- **Consistent Aesthetics**: Cohesive Catppuccin Mocha color scheme across all components
- **Intelligent Defaults**: Sane settings that work out of the box
- **No Bloat**: Every package and script serves a clear purpose (46 official + 9 AUR packages)
- **Wayland-Native**: All tools are pure Wayland (no X11 dependencies)

### Custom Utilities

All scripts live in `.local/bin/` with consistent design patterns:

#### Visual Feedback

- **`volume-notify.sh`** - Volume OSD with ASCII bar graph (uses PipeWire)
- **`brightness-notify.sh`** - Brightness OSD with visual indicator
- **`capslock-notify.sh`** - Subtle Caps Lock state monitoring

#### System Controls

- **`bluetooth-toggle.sh`** - One-key Bluetooth toggle
- **`screen-record.sh`** - Hardware-accelerated screen recording with GPU auto-detection
  - NVIDIA: Uses `wf-recorder` with libx264
  - AMD/Intel: Uses `wl-screenrec` (more efficient)
  - Signals Waybar (RTMIN+8) to toggle recording indicator
- **`screen-record-active.sh`** - Check recording status (returns true/false)

#### Workflow Enhancements

- **`show-keybindings.sh`** - Interactive keybinding viewer with fuzzy search (SUPER+K)
- **`update-keybindings-json.sh`** - Parses `binding.conf` and generates `keybindings.json`
- **`search_by_keyword.sh`** - Ripgrep + fzf file search, opens in Neovim
- **`networking.sh`** - Comprehensive network management utility (2,072 lines)
  - Supports WiFi, Ethernet, hotspot, DNS management
  - Uses dnsmasq, iptables, hostapd for advanced networking

#### Smart Automation

- **`battery-monitor.sh`** - Intelligent battery management (runs via systemd timer every 30s)
  - Progressive brightness reduction at thresholds: 20%, 15%, 10%, 5%, 3%
  - Smart notification system (prevents spam with flag files)
  - Automatically resets when charging

#### Notification System

All notification scripts use `dunstify` (dunst's native command) with replacement IDs:

- `volume-notify.sh`: ID 9999
- `brightness-notify.sh`: ID 9998
- This prevents notification spam by updating existing notifications

---

## Installation

### Requirements

- **Arch Linux** (script checks for `/etc/arch-release`)
- **base-devel** group installed
- **git** installed

### For Users (Stable)

Standard installation that **copies** all files to your home directory:

```bash
# Clone the repository
git clone https://github.com/rizukirr/hyprsimple.git
cd hyprsimple

# Run the installer
./install.sh
```

**What it does:**

1. Checks for Arch Linux
2. Detects or installs AUR helper (yay/paru)
3. Initializes git submodules (Neovim config from [rrxxyz/nvim-minimal](https://github.com/rrxxyz/nvim-minimal))
4. Installs packages from `packages.txt` (46 packages) and `aur-packages.txt` (9 packages)
5. **Copies** all configuration files to `~/.config/`
6. **Copies** scripts to `~/.local/bin/` with execute permissions
7. **Copies** assets to `~/.local/share/`
8. Generates `keybindings.json` from `binding.conf`
9. Enables systemd services: PipeWire, WirePlumber, battery monitor, Bluetooth
10. Creates `~/Videos` and `~/Pictures` directories

Your configs become **independent** from the repository after installation.

### For Developers (Live Editing)

Developer installation that **symlinks** most files for live editing:

```bash
# Clone the repository
git clone https://github.com/rizukirr/hyprsimple.git
cd hyprsimple

# Run the developer installer
./dev-install.sh
```

**What's different:**

- **Symlinks** most config directories (changes in repo immediately affect your system)
- **Always copies** (never symlinks):
  - `monitors.conf`, `hyprpaper.conf` - Machine-specific hardware configuration
  - `.bashrc` - User-customizable shell configuration
  - `.local/share/` - Binary assets and runtime data
  - `gtk-3.0/`, `gtk-4.0/`, `Kvantum/` - Managed by nwg-look/qt6ct
- **Symlinks** all scripts in `.local/bin/` for instant updates

#### Installation Method Comparison

| Aspect              | `install.sh`                  | `dev-install.sh`                    |
| ------------------- | ----------------------------- | ----------------------------------- |
| **Config Files**    | Copied                        | Symlinked (except machine-specific) |
| **Scripts**         | Copied                        | Symlinked                           |
| **Assets**          | Copied                        | Copied                              |
| **Updates**         | Manual (re-run or copy files) | Automatic (edit repo files)         |
| **Use Case**        | End users, stable snapshot    | Developers, live development        |
| **Git Integration** | Configs separate from repo    | Configs tied to repo                |

### Post-Installation

1. **Customize machine-specific configs:**

   ```bash
   nvim ~/.config/hypr/monitors.conf      # Your display configuration
   nvim ~/.config/hypr/hyprpaper.conf     # Wallpaper paths
   ```

2. **Verify services are running:**

   ```bash
   # Check audio
   systemctl --user status pipewire pipewire-pulse wireplumber

   # Check battery monitor
   systemctl --user list-timers battery-monitor.timer

   # Check Bluetooth
   systemctl status bluetooth
   ```

3. **Log out and select Hyprland** from your display manager

4. **Test keybindings:** Press `SUPER + K` to view the interactive keybinding reference

---

## Usage

### Keybindings

Press **SUPER + K** (or SUPER + /) for an interactive keybinding reference with fuzzy search.

#### Essential Shortcuts

| Binding                 | Action                       | Category  |
| ----------------------- | ---------------------------- | --------- |
| `SUPER + T`             | Terminal (Kitty)             | Launch    |
| `SUPER + B`             | Browser (Firefox)            | Launch    |
| `SUPER + A`             | App Launcher (Wofi)          | Launch    |
| `SUPER + F`             | File Manager (Thunar)        | Launch    |
| `SUPER + N`             | Notes (Obsidian)             | Launch    |
| `SUPER + Q`             | Kill active window           | Window    |
| `SUPER + Space`         | Toggle floating              | Window    |
| `SUPER + G`             | Toggle fullscreen            | Window    |
| `SUPER + [1-9]`         | Switch to workspace 1-9      | Workspace |
| `SUPER + SHIFT + [1-9]` | Move window to workspace 1-9 | Workspace |
| `SUPER + Mouse`         | Move/resize window           | Window    |

#### Utilities

| Binding     | Action                       | Category |
| ----------- | ---------------------------- | -------- |
| `SUPER + E` | Emoji picker (jome)          | Utility  |
| `SUPER + V` | Clipboard history (cliphist) | Utility  |
| `SUPER + M` | Color picker (hyprpicker)    | Utility  |
| `SUPER + K` | Keybindings viewer           | Utility  |
| `SUPER + /` | Keybindings viewer (alt)     | Utility  |

#### Media & Screenshots

| Binding               | Action                        | Category |
| --------------------- | ----------------------------- | -------- |
| `SUPER + P`           | Record screen (select output) | Media    |
| `SUPER + SHIFT + P`   | Record screen (select region) | Media    |
| `Print`               | Screenshot (full screen)      | Media    |
| `SUPER + Print`       | Screenshot (active window)    | Media    |
| `SUPER + ALT + Print` | Screenshot (area selection)   | Media    |
| `XF86AudioPlay`       | Play/Pause media              | Media    |
| `XF86AudioNext`       | Next track                    | Media    |
| `XF86AudioPrev`       | Previous track                | Media    |

#### System Controls

| Binding                 | Action                 | Category |
| ----------------------- | ---------------------- | -------- |
| `SUPER + SHIFT + L`     | Lock screen (hyprlock) | System   |
| `SUPER + ESC`           | Logout menu (wlogout)  | System   |
| `XF86AudioMute`         | Mute/unmute audio      | System   |
| `XF86AudioRaiseVolume`  | Volume up              | System   |
| `XF86AudioLowerVolume`  | Volume down            | System   |
| `XF86MonBrightnessUp`   | Brightness up          | System   |
| `XF86MonBrightnessDown` | Brightness down        | System   |

**Customizing Keybindings:**

1. Edit `~/.config/hypr/binding.conf`
2. Run `~/.local/bin/update-keybindings-json.sh` to regenerate JSON
3. Press `SUPER + K` to test the updated viewer
4. Reload Hyprland: `hyprctl reload`

Format: `bind = MODIFIER, KEY, action, parameters`

- Use `$mainMod` for SUPER (auto-replaced in JSON output)

### Scripts & Utilities

#### Running Scripts

All scripts are in `~/.local/bin/` and should be in your `$PATH`:

```bash
# Check recording status
screen-record-active.sh

# Toggle Bluetooth
bluetooth-toggle.sh

# Search files by keyword
search_by_keyword.sh

# Update keybindings JSON
update-keybindings-json.sh
```

#### Script Organization

| Category            | Scripts                                                              | Purpose                                                    |
| ------------------- | -------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Visual Feedback** | `volume-notify.sh`, `brightness-notify.sh`, `capslock-notify.sh`     | Non-intrusive OSD notifications                            |
| **System Control**  | `bluetooth-toggle.sh`, `screen-record.sh`, `screen-record-active.sh` | Hardware and peripheral management                         |
| **Workflow**        | `show-keybindings.sh`, `search_by_keyword.sh`                        | Productivity enhancements                                  |
| **Automation**      | `battery-monitor.sh`, `update-keybindings-json.sh`                   | Background tasks and sync                                  |
| **Shell**           | `bashrc.sh`                                                          | Bash configuration with completions, zoxide, fzf, starship |
| **Networking**      | `networking.sh`                                                      | Advanced network management (WiFi, hotspot, DNS)           |

---

## Configuration

### Hyprland

Hyprland uses a **modular configuration** sourced from `~/.config/hypr/hyprland.conf`:

```
~/.config/hypr/
├── hyprland.conf          # Main entry point (sources all below)
├── programs.conf          # Program paths ($terminal, $browser, etc.)
├── vars.conf              # Environment variables (Wayland, NVIDIA, Qt)
├── monitors.conf          # Display configuration (MACHINE-SPECIFIC)
├── input.conf             # Keyboard, mouse, touchpad settings
├── binding.conf           # All keybindings
├── looknfeel.conf         # Animations, blur, decorations, gaps
├── windows.conf           # Window rules, workspace behavior
├── autostart.conf         # Programs launched on startup
├── hyprpaper.conf         # Wallpaper configuration (MACHINE-SPECIFIC)
├── hyprlock.conf          # Lock screen appearance
├── hypridle.conf          # Idle management and auto-lock
└── keybindings.json       # AUTO-GENERATED (do not edit manually)
```

**Edit any config file and reload:**

```bash
hyprctl reload
```

### Waybar

Located at `~/.config/waybar/`:

- `config.jsonc` - Module configuration (clock, workspaces, system stats, custom modules)
- `style.css` - Visual styling (colors, fonts, spacing)

**Custom Modules:**

- Screen recording indicator (signals via RTMIN+8)
- Memory, CPU, network, Bluetooth, battery
- Backlight, audio, microphone with click actions

**Waybar Signal Communication:**
Scripts communicate with Waybar using real-time signals:

- `screen-record.sh` sends RTMIN+8 to toggle recording indicator
- Use `pkill -RTMIN+8 waybar` to trigger custom module updates

### Systemd Services

#### Battery Monitor

Located at `~/.config/systemd/user/`:

- `battery-monitor.service` - Oneshot service running the battery script
- `battery-monitor.timer` - Timer triggering every 30 seconds

**Configuration:**

```ini
[Timer]
OnBootSec=30s              # First run 30 seconds after boot
OnUnitActiveSec=30s        # Repeat every 30 seconds
Persistent=true            # Remember last trigger on reboot
```

**Management:**

```bash
# Check timer status
systemctl --user list-timers battery-monitor.timer

# Restart after modifications
systemctl --user daemon-reload
systemctl --user restart battery-monitor.timer

# View logs
journalctl --user -u battery-monitor.service -f
```

#### Audio Services

PipeWire services are enabled automatically during installation:

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

### Customization

#### Changing Colors

1. **Waybar**: Edit `~/.config/waybar/style.css`
2. **Kitty**: Edit `~/.config/kitty/theme.conf`
3. **Dunst**: Edit `~/.config/dunst/dunstrc`
4. **GTK**: Use `nwg-look` (GUI theme manager)
5. **Qt**: Use `qt6ct` (Qt configuration tool)

#### Changing Wallpaper

Edit `~/.config/hypr/hyprpaper.conf`:

```conf
preload = /path/to/your/wallpaper.png
wallpaper = ,/path/to/your/wallpaper.png
```

Then reload: `hyprctl reload`

#### Changing Animations

Edit `~/.config/hypr/looknfeel.conf` - adjust animation curves, speeds, blur, shadows, and gaps.

#### Changing Window Behavior

Edit `~/.config/hypr/windows.conf` - modify window rules, floating rules, workspace assignments.

---

## Package Philosophy

Every package is intentionally chosen. No "just in case" bloat.

### Official Packages (46 total)

**Hyprland Ecosystem:**

```
hyprland hyprpaper hyprlock hypridle hyprpicker hyprpolkitagent
```

**UI & Status Bar:**

```
waybar dunst wofi
```

**Screenshots & Recording:**

```
slurp wf-recorder
```

**System Utilities:**

```
polkit-kde-agent cliphist wl-clipboard playerctl brightnessctl
bluez bluez-utils libnotify thunar unzip zip
```

**Networking (for networking.sh):**

```
dnsmasq iptables hostapd haveged
```

**Applications:**

```
kitty neovim
```

**Audio Stack:**

```
pipewire pipewire-alsa pipewire-audio pipewire-pulse wireplumber alsa-utils ffmpeg
```

**CLI Tools:**

```
fzf zoxide starship fastfetch lsd git jq bash-completion ripgrep lazygit
```

**Fonts:**

```
ttf-jetbrains-mono-nerd noto-fonts-cjk noto-fonts-emoji
```

### AUR Packages (9 total)

**Screenshot & Logout:**

```
grimblast-git wlogout
```

**Screen Recording:**

```
wl-screenrec
```

**Catppuccin Theme:**

```
catppuccin-gtk-theme-mocha
catppuccin-cursors-mocha
papirus-folder-catppuccin-git
kvantum-theme-catppuccin-git
```

**Theme Management:**

```
nwg-look
```

**Installing Additional Packages:**

Add package names to `packages.txt` (official) or `aur-packages.txt` (AUR), one per line. Lines starting with `#` are comments.

---

## Architecture

### Installation Strategy

| Type                             | File Handling       | Use Case                   |
| -------------------------------- | ------------------- | -------------------------- |
| **Regular** (`install.sh`)       | Copies all files    | End users, stable snapshot |
| **Developer** (`dev-install.sh`) | Symlinks most files | Maintainers, live editing  |

**Files always copied (never symlinked in dev mode):**

- `monitors.conf`, `hyprpaper.conf` - Hardware-specific
- `.bashrc` - User-customizable
- `.local/share/` - Binary assets
- `gtk-3.0/`, `gtk-4.0/`, `Kvantum/` - Managed by external tools

### Script Design Patterns

**Notification System:**

- All scripts use `dunstify` (not `notify-send`)
- Replacement IDs prevent spam:
  - Volume: ID 9999
  - Brightness: ID 9998
- Format: `dunstify "Title" "Message" -u urgency -t timeout -r replace_id`

**Hardware Detection:**

- `screen-record.sh` detects GPU vendor for codec selection
- NVIDIA: Uses `wf-recorder` (better compatibility)
- Others: Uses `wl-screenrec` (more efficient)

**Systemd Integration:**

- Battery monitor runs via timer (not cron) for Wayland session access
- Services set proper environment variables for GUI apps

**Waybar Communication:**

- Scripts send signals to Waybar for real-time updates
- Recording indicator: `pkill -RTMIN+8 waybar`

### Configuration Modularity

**Single entry point** (`hyprland.conf`) sources 10+ modular configs:

```bash
source = $HOME/.config/hypr/programs.conf
source = $HOME/.config/hypr/vars.conf
source = $HOME/.config/hypr/autostart.conf
source = $HOME/.config/hypr/looknfeel.conf
source = $HOME/.config/hypr/monitors.conf
source = $HOME/.config/hypr/input.conf
source = $HOME/.config/hypr/binding.conf
source = $HOME/.config/hypr/windows.conf
source = $HOME/.config/hypr/hypridle.conf
```

**Keybinding sync workflow:**

1. User edits `binding.conf`
2. Runs `update-keybindings-json.sh`
3. Parser converts to `keybindings.json`
4. Viewer (`show-keybindings.sh`) reads JSON with fzf

---

## Maintenance

### For Regular Users

Configuration files are **copied** to `~/.config/`. Edit them directly:

```bash
# Edit configs in place
nvim ~/.config/hypr/binding.conf

# Update keybindings JSON after editing
~/.local/bin/update-keybindings-json.sh

# Reload Hyprland
hyprctl reload
```

To get updates from the repository:

```bash
cd ~/path/to/hyprsimple
git pull
./install.sh  # Re-run installer (creates backups)
```

### For Developers

If you used `dev-install.sh`, configs are **symlinked**. Changes in the repo immediately affect your system:

```bash
cd ~/path/to/hyprsimple

# Edit files directly in repo
nvim .config/hypr/binding.conf

# Generate keybindings JSON
.local/bin/update-keybindings-json.sh

# Reload Hyprland
hyprctl reload

# Commit changes
git add .
git commit -m "Update keybindings"
git push
```

**Note**: Machine-specific files (`monitors.conf`, `hyprpaper.conf`) and `.bashrc` are copied, not symlinked. To update them in the repo:

```bash
cp ~/.config/hypr/monitors.conf ~/path/to/hyprsimple/.config/hypr/
```

### Updating Submodules

Neovim config is a git submodule:

```bash
cd ~/path/to/hyprsimple
git submodule update --remote --merge
git commit -am "Update Neovim submodule"
```

---

## Troubleshooting

### Common Issues

| Problem                              | Solution |
|--------------------------------------|---------|
| **Scripts not executing**            | Verify `~/.local/bin` is in `$PATH` (`echo $PATH`). Add to `.bashrc` if missing: `export PATH="$HOME/.local/bin:$PATH"`. Verify permissions: `chmod +x ~/.local/bin/*.sh`. |
| **Keybinding viewer empty**          | Run `~/.local/bin/update-keybindings-json.sh` to regenerate `keybindings.json`. |
| **No audio**                         | Enable PipeWire services: `systemctl --user enable --now pipewire pipewire-pulse wireplumber`. Check status: `systemctl --user status pipewire`. |
| **Battery monitor not running**      | Check timer: `systemctl --user list-timers battery-monitor.timer`. If not listed, reload: `systemctl --user daemon-reload && systemctl --user restart battery-monitor.timer`. |
| **Notifications not working**        | Ensure dunst is running: `pgrep dunst`. Scripts require `dunstify` command from the dunst package. |
| **Screen recording fails**           | For NVIDIA: install `wf-recorder`. For others: install `wl-screenrec` (AUR). Check installation: `which wf-recorder` or `which wl-screenrec`. |
| **Waybar recording indicator stuck** | Manually reset: `pkill -RTMIN+8 waybar`. Check if recording process is running: `pgrep wf-recorder` or `pgrep wl-screenrec`. |
| **Hyprland doesn't start**           | Check logs: `journalctl -b | grep hyprland`. Verify `monitors.conf` syntax. Try minimal config: `cp ~/.config/hypr/monitors.conf ~/.config/hypr/monitors.conf.bak` and create a basic `monitors.conf`. |
| **Submodule not initialized**        | Initialize manually: `git submodule update --init --recursive`. |
| **NVIDIA-specific issues**           | Create `/etc/modprobe.d/nvidia.conf` with the following options: <br>options nvidia-drm modeset=1<br>options nvidia NVreg_PreserveVideoMemoryAllocations=1<br>options nvidia NVreg_TemporaryFilePath=/tmp | 

### Reload Configuration

```bash
# Reload Hyprland config
hyprctl reload

# Restart Waybar
pkill waybar && waybar &

# Restart dunst
pkill dunst && dunst &

# Reload systemd user services
systemctl --user daemon-reload
```

### Debugging

**Check Hyprland logs:**

```bash
# Current session
hyprctl logs

# System logs
journalctl -b | grep hyprland
```

**Check service status:**

```bash
# List all user services
systemctl --user list-units

# List all timers
systemctl --user list-timers

# Check specific service
systemctl --user status battery-monitor.service

# Follow service logs
journalctl --user -u battery-monitor.service -f
```

**Test notification system:**

```bash
# Test dunstify
dunstify "Test" "This is a test notification"

# Test with replacement ID
dunstify "Test" "First message" -r 1234
sleep 2
dunstify "Test" "Replaced message" -r 1234
```

---

## Contributing

This is a **personal configuration**, but suggestions and improvements are welcome.

**How to contribute:**

1. **Report issues**: Open an issue describing the problem
2. **Suggest improvements**: Open an issue with your idea
3. **Submit pull requests**: Fork, make changes, submit PR
4. **Share your setup**: If you forked and customized, share a link

**Guidelines:**

- Keep the "no bloat" philosophy
- Maintain Wayland-only compatibility
- Follow existing script patterns (dunstify, replacement IDs)
- Document new features in README and CLAUDE.md
- Test on fresh Arch Linux installation

---

## License

**MIT License** - Use, modify, and share freely.

See [LICENSE](LICENSE) file for details.

---

💖 **Support This Project**

If you find this project helpful, consider supporting its development:  
☕ [Buy Me a Coffee](https://ko-fi.com/rizukirr)

Made with ❤️ by [rizukirr](https://github.com/rizukirr)

---

**Neovim Configuration**: Separate git submodule from [rrxxyz/nvim-minimal](https://github.com/rrxxyz/nvim-minimal)
