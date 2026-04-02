#!/usr/bin/env bash

set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
    echo "[*] Installing git..."
    sudo pacman -S --needed git --noconfirm
fi

REPO_URL="https://github.com/maust-3/ArchDotfiles.git"
REPO_DIR="$HOME/ArchDotfiles"

echo "[*] Restoring custom configs..."

# Clone or update repo
if [[ -d "$REPO_DIR" ]]; then
    echo "[*] Repo exists, pulling latest..."
    git -C "$REPO_DIR" pull
else
    echo "[*] Cloning repo..."
    git clone "$REPO_URL" "$REPO_DIR"
fi

echo "[*] Applying configs..."

# Waybar
echo "[*] Applying Waybar custom configs..."

# Base dir
mkdir -p "$HOME/.config/waybar"

# Themes dir
mkdir -p "$HOME/.config/waybar/themes/ml4w-modern"

# Copy main custom modules
cp -n "$REPO_DIR/waybar/custom-modules.json" \
      "$HOME/.config/waybar/custom-modules.json"

# Copy theme-specific files
cp -n "$REPO_DIR/waybar/config-custom" \
      "$HOME/.config/waybar/themes/ml4w-modern/config-custom"

cp -n "$REPO_DIR/waybar/style-custom.css" \
      "$HOME/.config/waybar/themes/ml4w-modern/style-custom.css"

# Fastfetch
echo "[*] Applying Fastfetch config..."
mkdir -p "$HOME/.config/fastfetch-custom"
cp -rn "$REPO_DIR/fastfetch/"* "$HOME/.config/fastfetch-custom/"

# Hyprland
echo "[*] Applying Hypr configs..."
mkdir -p "$HOME/.config/hypr/conf/monitors"
cp -rn "$REPO_DIR/hypr/conf/"* "$HOME/.config/hypr/conf/"

# ZSH main custom file
echo "[*] Applying ZSH custom configs..."
cp -n "$REPO_DIR/zsh/.zshrc_custom" "$HOME/.zshrc_custom"

# ZSH modular custom scripts
echo "[*] Applying ZSH modular scripts..."
mkdir -p "$HOME/.config/zshrc/custom"
cp -rn "$REPO_DIR/zsh/"*.zsh "$HOME/.config/zshrc/custom/" 2>/dev/null || true

# MPD
echo "[*] Setting up MPD..."

if ! command -v mpd >/dev/null 2>&1; then
    echo "[*] Installing MPD..."
    sudo pacman -S --needed mpd mpc ncmpcpp --noconfirm
else
    echo "[*] MPD already installed"
fi

mkdir -p "$HOME/.config/mpd"
cp -rn "$REPO_DIR/mpd/"* "$HOME/.config/mpd/"

# Start and enable MPD (user service)
echo "[*] Enabling and starting MPD service..."

if systemctl --user is-enabled mpd.service >/dev/null 2>&1; then
    echo "[*] MPD already enabled"
else
    echo "[*] Enabling MPD service..."
    systemctl --user enable --now mpd.service
fi

# RMPC
echo "[*] Setting up rmpc..."

# Install if missing
if ! command -v rmpc >/dev/null 2>&1; then
    echo "[*] Installing rmpc..."
    sudo pacman -S --needed rmpc --noconfirm
else
    echo "[*] rmpc already installed"
fi

# Create config directory
mkdir -p "$HOME/.config/rmpc"

# Copy config + themes (safe, no overwrite)
cp -rn "$REPO_DIR/rmpc/"* "$HOME/.config/rmpc/" 2>/dev/null || true

#Oh-my-posh
echo "[*] Applying Oh My Posh theme..."
mkdir -p "$HOME/.config/ohmyposh"
cp -n "$REPO_DIR/ohmyposh/arch-catppuccin.json" \
      "$HOME/.config/ohmyposh/arch-catppuccin.json"

# Misc scripts
echo "[*] Copying misc scripts..."

SCRIPTS=(
    "custom-now-playing.sh"
    "mpd-next.sh"
    "mpd-prev.sh"
    "mpd-toggle.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -f "$REPO_DIR/misc/$script" ]]; then
        cp -n "$REPO_DIR/misc/$script" "$HOME/$script"
        chmod +x "$HOME/$script"
        echo "[*] Installed $script"
    else
        echo "[!] Missing $script in repo"
    fi
done

if command -v hyprctl >/dev/null 2>&1 && pgrep -x Hyprland >/dev/null; then
    echo "[*] Reloading Hyprland..."
    hyprctl reload
fi

echo "[*] Done! 🎉"
