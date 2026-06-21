# dotfiles

Personal dotfiles for Ubuntu 24.04 — managed by [chezmoi](https://chezmoi.io).

**Stack:** Sway · Waybar · Fuzzel · SwayNC · GhostTTY · zsh + Starship · Zellij · Neovim/LazyVim · Yazi  
**Theme:** Catppuccin Mocha throughout

## Bootstrap (new machine)

```bash
# 1. Install everything
curl -sSL https://raw.githubusercontent.com/josefjura/dotfiles/master/install.sh | bash

# 2. Apply dotfiles
chezmoi init --apply josefjura
```

## Key bindings (Sway)

| Key | Action |
|-----|--------|
| `SUPER+Return` | Terminal (GhostTTY) |
| `SUPER+Space` | App launcher (Fuzzel) |
| `SUPER+H/J/K/L` | Focus window |
| `SUPER+SHIFT+H/J/K/L` | Move window |
| `SUPER+1-9` | Switch workspace |
| `SUPER+SHIFT+1-9` | Move to workspace |
| `SUPER+F` | Fullscreen |
| `SUPER+SHIFT+F` | Toggle float |
| `SUPER+N` | Neovim |
| `SUPER+E` | Yazi (file manager) |
| `SUPER+G` | Lazygit |
| `SUPER+V` | Clipboard history |
| `SUPER+Backspace` | Notification center |
| `Print` | Screenshot (full) |
| `SHIFT+Print` | Screenshot (region) |
