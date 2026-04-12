#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()    { printf '\033[0;34m[setup]\033[0m %s\n' "$*"; }
success() { printf '\033[0;32m[setup]\033[0m %s\n' "$*"; }
warn()    { printf '\033[0;33m[setup]\033[0m %s\n' "$*"; }

# ── Xcode CLI Tools ───────────────────────────────────────────────────────────
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode CLI tools..."
  xcode-select --install
  read -rp "Press Enter once the Xcode CLI tools installer has finished..."
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH (handles both Apple Silicon and Intel)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

info "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES/Brewfile"

# ── Git local config (sensitive — not tracked in dotfiles) ────────────────────
GIT_LOCAL="$HOME/.config/git/local"
GIT_LITTLEIST="$HOME/.config/git/littleist"
GIT_QXHU="$HOME/.config/git/qxhu"
mkdir -p "$HOME/.config/git"

if [ ! -f "$GIT_LOCAL" ]; then
  info "Creating ~/.config/git/local (not tracked in dotfiles)..."
  read -rp "  Your full name: " git_name
  read -rp "  Default email (used when no profile matches): " git_email
  printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email" > "$GIT_LOCAL"
  success "  Created $GIT_LOCAL"
fi

if [ ! -f "$GIT_LITTLEIST" ]; then
  read -rp "  Email for littleist profile: " littleist_email
  printf '[user]\n\temail = %s\n' "$littleist_email" > "$GIT_LITTLEIST"
  success "  Created $GIT_LITTLEIST"
fi

if [ ! -f "$GIT_QXHU" ]; then
  read -rp "  Email for qxhu profile: " qxhu_email
  printf '[user]\n\temail = %s\n' "$qxhu_email" > "$GIT_QXHU"
  success "  Created $GIT_QXHU"
fi

# ── SSH config ────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ── Symlinks ──────────────────────────────────────────────────────────────────
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    warn "Backing up $dst → ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  ln -sf "$src" "$dst"
  info "  $dst → $src"
}

info "Creating symlinks..."

# Git
link "$DOTFILES/.config/git/config"        "$HOME/.config/git/config"
link "$DOTFILES/.config/git/ignore"        "$HOME/.config/git/ignore"

# SSH config (keys themselves are never tracked)
link "$DOTFILES/.ssh/config"               "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# Shell
link "$DOTFILES/.zshenv"                    "$HOME/.zshenv"
link "$DOTFILES/.zprofile"                  "$HOME/.zprofile"
link "$DOTFILES/.bash_profile"              "$HOME/.bash_profile"
link "$DOTFILES/.config/zsh/.zshrc"         "$HOME/.config/zsh/.zshrc"

# Tmux (kept for remote/SSH sessions)
link "$DOTFILES/.tmux.conf"                 "$HOME/.tmux.conf"

# cmux
link "$DOTFILES/.config/cmux/settings.json"  "$HOME/.config/cmux/settings.json"

# Claude Code
link "$DOTFILES/.config/claude/settings.json"  "$HOME/.claude/settings.json"
link "$DOTFILES/.config/claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/.config/claude/keybindings.json" "$HOME/.claude/keybindings.json"
# Commands dir (shared skills/slash commands) — link contents, not the dir itself,
# so Claude can still write per-machine data into ~/.claude/
mkdir -p "$HOME/.claude/commands"
for f in "$DOTFILES/.config/claude/commands/"*; do
  [ -e "$f" ] || continue
  link "$f" "$HOME/.claude/commands/$(basename "$f")"
done

# ── Default Shell ─────────────────────────────────────────────────────────────
BREW_ZSH="$(brew --prefix)/bin/zsh"
if ! grep -qF "$BREW_ZSH" /etc/shells 2>/dev/null; then
  info "Adding Homebrew zsh to /etc/shells..."
  echo "$BREW_ZSH" | sudo tee -a /etc/shells
fi
if [ "$SHELL" != "$BREW_ZSH" ]; then
  info "Setting default shell to zsh..."
  chsh -s "$BREW_ZSH"
fi

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
OMZ_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/ohmyzsh"
if [ ! -d "$OMZ_DIR" ]; then
  info "Installing oh-my-zsh..."
  ZSH="$OMZ_DIR" RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  # Restore symlink that oh-my-zsh installer overwrites
  ln -sf "$DOTFILES/.config/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"
fi

# ── Tmux Plugin Manager ───────────────────────────────────────────────────────
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  info "Installing tmux plugin manager..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ── Claude Code ───────────────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
  info "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
fi

# ── fzf shell integration ─────────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish 2>/dev/null || true
fi

echo ""
success "Done! Next steps:"
echo "  1. Restart your terminal"
echo "  2. Authenticate GitHub accounts:"
echo "     gh auth login   # run twice, once per account (choose HTTPS)"
echo "     gh auth setup-git  # configure git credential helper"
echo "  3. Run 'claude' to authenticate with Anthropic"
echo "  4. In tmux, press prefix + I to install tmux plugins"
