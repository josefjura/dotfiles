#!/usr/bin/env bash
# Bootstrap script for Arch Linux (EndeavourOS) — Hyprland + chezmoi setup
# Run this after first boot. Idempotent — safe to re-run.
set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'
info()  { echo -e "${BLUE}[info]${RESET} $*"; }
ok()    { echo -e "${GREEN}[ok]${RESET}   $*"; }
step()  { echo -e "\n${BOLD}${YELLOW}==> $*${RESET}"; }

# ---------------------------------------------------------------------------
step "Phase 1 — Pacman: system packages"
# ---------------------------------------------------------------------------

info "Updating system"
sudo pacman -Syu --noconfirm

info "Installing Hyprland + Wayland ecosystem"
sudo pacman -S --needed --noconfirm \
  hyprland \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  qt5-wayland \
  qt6-wayland \
  waybar \
  fuzzel \
  swaync \
  hyprlock \
  hypridle \
  grim \
  slurp \
  wl-clipboard \
  cliphist \
  polkit-kde-agent \
  network-manager-applet \
  blueman \
  pavucontrol \
  brightnessctl \
  pipewire \
  wireplumber

info "Installing CLI toolbelt"
sudo pacman -S --needed --noconfirm \
  zsh \
  git \
  neovim \
  ripgrep \
  fd \
  bat \
  fzf \
  eza \
  zoxide \
  lazygit \
  zellij \
  yazi \
  starship \
  chezmoi \
  git-delta \
  btop \
  python \
  python-pip \
  nodejs \
  npm \
  unzip \
  jq \
  curl \
  wget

info "Installing fonts"
sudo pacman -S --needed --noconfirm \
  ttf-jetbrains-mono-nerd \
  noto-fonts \
  noto-fonts-emoji

ok "Pacman installs done"

# ---------------------------------------------------------------------------
step "Phase 2 — AUR packages (via yay)"
# ---------------------------------------------------------------------------

# Install yay if not present
if ! command -v yay &>/dev/null; then
  info "Installing yay (AUR helper)"
  sudo pacman -S --needed --noconfirm git base-devel
  tmp=$(mktemp -d)
  git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  ok "yay installed"
else
  ok "yay already installed"
fi

info "Installing AUR packages"
yay -S --needed --noconfirm \
  swww \
  ghostty \
  visual-studio-code-bin \
  mise-bin

ok "AUR installs done"

# ---------------------------------------------------------------------------
step "Phase 3 — Nvidia setup for Hyprland"
# ---------------------------------------------------------------------------

if lspci | grep -qi nvidia; then
  info "Nvidia GPU detected — configuring for Hyprland"

  # Ensure nvidia-drm.modeset=1 is set (required for Hyprland+Nvidia)
  if ! grep -q "nvidia_drm.modeset=1" /etc/modprobe.d/nvidia.conf 2>/dev/null; then
    echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf
    ok "nvidia_drm.modeset=1 set"
  else
    ok "nvidia_drm.modeset already configured"
  fi

  # Add nvidia modules to initramfs
  if ! grep -q "nvidia" /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P
    ok "nvidia modules added to initramfs"
  else
    ok "nvidia modules already in initramfs"
  fi

  # Enable nvidia systemd services
  sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume 2>/dev/null || true
  ok "nvidia suspend services enabled"
else
  ok "No Nvidia GPU found — skipping Nvidia setup"
fi

# ---------------------------------------------------------------------------
step "Phase 4 — Shell: set zsh as default"
# ---------------------------------------------------------------------------

if [ "$SHELL" = "$(which zsh)" ]; then
  ok "zsh is already the default shell"
else
  info "Changing default shell to zsh"
  chsh -s "$(which zsh)"
  ok "Default shell set to zsh (takes effect on next login)"
fi

# ---------------------------------------------------------------------------
step "Phase 5 — Bat theme (Catppuccin Mocha)"
# ---------------------------------------------------------------------------

BAT_THEMES="$HOME/.config/bat/themes"
mkdir -p "$BAT_THEMES"
if [[ ! -f "$BAT_THEMES/Catppuccin Mocha.tmTheme" ]]; then
  info "Installing Catppuccin Mocha theme for bat"
  curl -sSL \
    "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme" \
    -o "$BAT_THEMES/Catppuccin Mocha.tmTheme"
  bat cache --build >/dev/null 2>&1
  ok "bat Catppuccin Mocha theme installed"
else
  ok "bat Catppuccin Mocha theme already installed"
fi

# ---------------------------------------------------------------------------
step "Phase 6 — Install dotfiles via chezmoi"
# ---------------------------------------------------------------------------

if [[ -d "$HOME/.local/share/chezmoi/.git" ]]; then
  ok "chezmoi repo already initialized — run 'chezmoi apply' to sync"
else
  info "Pulling dotfiles from GitHub"
  chezmoi init --apply josefjura
  ok "Dotfiles applied"
fi

# ---------------------------------------------------------------------------
step "Phase 7 — LazyVim"
# ---------------------------------------------------------------------------

NVIM_CONFIG="$HOME/.config/nvim"
if [[ -f "$NVIM_CONFIG/init.lua" ]]; then
  ok "Neovim config already in place"
else
  info "Cloning LazyVim starter"
  git clone --depth=1 https://github.com/LazyVim/starter "$NVIM_CONFIG"
  rm -rf "$NVIM_CONFIG/.git"
  ok "LazyVim starter cloned"
fi

# ---------------------------------------------------------------------------
step "Summary"
# ---------------------------------------------------------------------------

echo ""
echo "Installed tools:"
for cmd in Hyprland waybar fuzzel swaync hyprlock hypridle zsh nvim lazygit zellij yazi starship mise chezmoi delta fzf rg bat eza zoxide ghostty code; do
  if command -v "$cmd" &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} $cmd"
  else
    echo -e "  ${YELLOW}✗${RESET} $cmd — NOT found"
  fi
done

echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo "  1. Reboot"
echo "  2. Select 'Hyprland' at the login screen"
echo "  3. SUPER+Return → GhostTTY"
echo "  4. Run nvim — LazyVim will bootstrap plugins on first launch"
echo ""
echo -e "${GREEN}Done!${RESET}"
