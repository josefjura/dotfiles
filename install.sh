#!/usr/bin/env bash
# Bootstrap script for Ubuntu 24.04 LTS — Hyprland + chezmoi setup
# Run this on a fresh install. It's idempotent — safe to re-run.
set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'
info()  { echo -e "${BLUE}[info]${RESET} $*"; }
ok()    { echo -e "${GREEN}[ok]${RESET}   $*"; }
step()  { echo -e "\n${BOLD}${YELLOW}==> $*${RESET}"; }

# ---------------------------------------------------------------------------
step "Phase 1 — APT: PPAs and system packages"
# ---------------------------------------------------------------------------

info "Adding Neovim unstable PPA (for latest neovim)"
sudo add-apt-repository ppa:neovim-ppa/unstable -y

info "Updating package lists"
sudo apt update

info "Installing Sway + Wayland ecosystem"
sudo apt install -y \
  sway \
  swaylock \
  swayidle \
  swaybg \
  xdg-desktop-portal-wlr \
  xdg-desktop-portal-gtk \
  qtwayland5 \
  qt6-wayland \
  waybar \
  fuzzel \
  sway-notification-center \
  grim \
  slurp \
  wl-clipboard \
  cliphist \
  polkit-kde-agent-1 \
  network-manager-gnome \
  blueman \
  pavucontrol

info "Installing CLI toolbelt from apt"
sudo apt install -y \
  zsh \
  git \
  neovim \
  ripgrep \
  fd-find \
  bat \
  fzf \
  zoxide \
  eza \
  python3 \
  python3-pip \
  unzip \
  jq \
  curl \
  wget \
  xdg-utils \
  ca-certificates

ok "APT installs done"

# ---------------------------------------------------------------------------
step "Phase 2 — Binary installs (GitHub releases)"
# ---------------------------------------------------------------------------

BIN="$HOME/.local/bin"
mkdir -p "$BIN"

# Helper: install a binary from a URL (tar.gz or zip)
install_tar_bin() {
  local name=$1 url=$2 inner=$3
  if command -v "$name" &>/dev/null; then
    ok "$name already installed, skipping"
    return
  fi
  info "Installing $name"
  local tmp; tmp=$(mktemp -d)
  curl -sSL "$url" | tar -xz -C "$tmp"
  install "$tmp/$inner" "$BIN/$name"
  rm -rf "$tmp"
  ok "$name installed → $BIN/$name"
}

# Lazygit
if ! command -v lazygit &>/dev/null; then
  info "Installing lazygit"
  LG_VER=$(curl -sSf "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r '.tag_name' | tr -d 'v')
  tmp=$(mktemp -d)
  curl -sSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_x86_64.tar.gz" | tar -xz -C "$tmp"
  sudo install "$tmp/lazygit" /usr/local/bin/lazygit
  rm -rf "$tmp"
  ok "lazygit installed"
else
  ok "lazygit already installed"
fi

# Zellij
if ! command -v zellij &>/dev/null; then
  info "Installing zellij"
  curl -sSL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" \
    | tar -xz -C "$BIN" zellij
  ok "zellij installed → $BIN/zellij"
else
  ok "zellij already installed"
fi

# Yazi (TUI file manager)
if ! command -v yazi &>/dev/null; then
  info "Installing yazi"
  tmp=$(mktemp -d)
  curl -sSL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip" -o "$tmp/yazi.zip"
  unzip -q "$tmp/yazi.zip" -d "$tmp"
  install "$tmp/yazi-x86_64-unknown-linux-gnu/yazi" "$BIN/yazi"
  rm -rf "$tmp"
  ok "yazi installed → $BIN/yazi"
else
  ok "yazi already installed"
fi

# git-delta (better git diffs)
if ! command -v delta &>/dev/null; then
  info "Installing git-delta"
  DELTA_VER=$(curl -sSf "https://api.github.com/repos/dandavison/delta/releases/latest" | jq -r '.tag_name')
  tmp=$(mktemp -d)
  curl -sSL "https://github.com/dandavison/delta/releases/latest/download/delta-${DELTA_VER}-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C "$tmp"
  install "$tmp/delta-${DELTA_VER}-x86_64-unknown-linux-gnu/delta" "$BIN/delta"
  rm -rf "$tmp"
  ok "git-delta installed → $BIN/delta"
else
  ok "git-delta already installed"
fi

# swaybg handles wallpaper for Sway — already installed via apt above

# Starship prompt
if ! command -v starship &>/dev/null; then
  info "Installing starship"
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  ok "starship installed"
else
  ok "starship already installed"
fi

# mise (language version manager)
if ! command -v mise &>/dev/null; then
  info "Installing mise"
  curl -sSf https://mise.run | sh
  ok "mise installed"
else
  ok "mise already installed"
fi

# chezmoi
if ! command -v chezmoi &>/dev/null; then
  info "Installing chezmoi"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN"
  ok "chezmoi installed → $BIN/chezmoi"
else
  ok "chezmoi already installed"
fi

ok "Binary installs done"

# ---------------------------------------------------------------------------
step "Phase 3 — Fonts (JetBrainsMono Nerd Font)"
# ---------------------------------------------------------------------------

FONTS_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONTS_DIR"

if ls "$FONTS_DIR/JetBrainsMono"* &>/dev/null 2>&1; then
  ok "JetBrainsMono Nerd Font already installed"
else
  info "Downloading JetBrainsMono Nerd Font"
  tmp=$(mktemp -d)
  curl -sSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$tmp/JetBrainsMono.zip"
  unzip -q "$tmp/JetBrainsMono.zip" -d "$tmp/JetBrainsMono"
  cp "$tmp/JetBrainsMono"/*.ttf "$FONTS_DIR/"
  rm -rf "$tmp"
  fc-cache -fv "$FONTS_DIR" >/dev/null 2>&1
  ok "JetBrainsMono Nerd Font installed"
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
step "Phase 5 — VS Code"
# ---------------------------------------------------------------------------

if command -v code &>/dev/null; then
  ok "VS Code already installed"
else
  info "Installing VS Code via snap"
  sudo snap install code --classic
  ok "VS Code installed"
fi

# ---------------------------------------------------------------------------
step "Phase 6 — GhostTTY"
# ---------------------------------------------------------------------------

if command -v ghostty &>/dev/null; then
  ok "GhostTTY already installed"
else
  info "Attempting GhostTTY install via snap"
  if sudo snap install ghostty --classic 2>/dev/null; then
    ok "GhostTTY installed via snap"
  else
    echo ""
    echo -e "${YELLOW}GhostTTY not available via snap.${RESET}"
    echo "Install it manually from: https://ghostty.org/download"
    echo "Or use: sudo apt install ghostty (if a PPA has been added)"
  fi
fi

# ---------------------------------------------------------------------------
step "Summary"
# ---------------------------------------------------------------------------

echo ""
echo "Installed tools:"
for cmd in sway swaylock swayidle swaybg waybar fuzzel swaync zsh nvim lazygit zellij yazi starship mise chezmoi delta fzf rg batcat eza zoxide; do
  if command -v "$cmd" &>/dev/null; then
    echo -e "  ${GREEN}✓${RESET} $cmd ($(command -v "$cmd"))"
  else
    echo -e "  ${YELLOW}✗${RESET} $cmd — NOT found"
  fi
done

echo ""
echo -e "${BOLD}Next steps:${RESET}"
echo "  1. Log out and select 'Sway' at the login screen"
echo "  2. Open GhostTTY — Sway default keybind: SUPER+Return"
echo "  3. Run: git clone https://github.com/LazyVim/starter ~/.config/nvim && nvim"
echo "  4. Run: chezmoi init  (to begin capturing your dotfiles)"
echo ""
echo -e "${GREEN}Phase 1 complete!${RESET} See ~/.config/sway/config for WM config."
