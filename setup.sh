#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Flags ─────────────────────────────────────────────────────────────────────
SKIP_MACOS=false
FORCE_MACOS=false
CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --skip-macos)  SKIP_MACOS=true ;;
    --apply-macos) FORCE_MACOS=true ;;
    --check)       CHECK_ONLY=true ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

if [ "$CHECK_ONLY" = true ]; then
  exec "$DOTFILES/check.sh"
fi

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

info "Updating Homebrew..."
brew update

info "Installing and updating packages from Brewfile..."
brew bundle --file="$DOTFILES/Brewfile"

# ── Git identity profiles (per-directory overrides, not tracked) ──────────────
# The default identity (qxhu / no-reply, signed) lives in the tracked
# .config/git/config. Only per-directory includeIf profiles that aren't tracked
# here are prompted for and created locally.
mkdir -p "$HOME/.config/git"

# Prompt for any profiles defined in git/config that don't exist yet
while IFS= read -r profile; do
  # Profiles tracked in this repository are symlinked below and need no prompt.
  [ -f "$DOTFILES/.config/git/$profile" ] && continue
  git_profile_file="$HOME/.config/git/$profile"
  if [ ! -f "$git_profile_file" ]; then
    read -rp "  Email for '$profile' profile: " profile_email
    printf '[user]\n\temail = %s\n' "$profile_email" > "$git_profile_file"
    success "  Created ~/.config/git/$profile"
  fi
done < <(sed -n 's|.*path = ~/\.config/git/||p' "$DOTFILES/.config/git/config" | grep -v -e '^local$' -e '^config$' -e '^ignore$')

# ── SSH config ────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ── Symlinks ──────────────────────────────────────────────────────────────────
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local backup
    backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    local n=1
    while [ -e "$backup" ]; do
      backup="${dst}.bak.$(date +%Y%m%d%H%M%S).$n"
      n=$((n + 1))
    done
    warn "Backing up $dst → $backup"
    mv "$dst" "$backup"
  fi
  ln -sf "$src" "$dst"
  info "  $dst → $src"
}

info "Creating symlinks..."

# Git
link "$DOTFILES/.config/git/config"        "$HOME/.config/git/config"
link "$DOTFILES/.config/git/ignore"        "$HOME/.config/git/ignore"
link "$DOTFILES/.config/git/qxhu-signing.pub" "$HOME/.config/git/qxhu-signing.pub"
link "$DOTFILES/.config/git/allowed_signers" "$HOME/.config/git/allowed_signers"

# 1Password SSH agent (public item selectors only; no key material)
link "$DOTFILES/.config/1Password/ssh/agent.toml" "$HOME/.config/1Password/ssh/agent.toml"

# The Developer setting that enables the agent is intentionally managed by the
# 1Password app. Validate it here and provide an actionable warning if needed.
_ONEPASSWORD_AGENT="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [ ! -S "$_ONEPASSWORD_AGENT" ]; then
  warn "1Password SSH agent is not running. Enable Settings > Developer > Use the SSH agent."
elif _ONEPASSWORD_KEYS="$(SSH_AUTH_SOCK="$_ONEPASSWORD_AGENT" ssh-add -L 2>/dev/null)"; then
  for key_name in qxhu servers; do
    if ! printf '%s\n' "$_ONEPASSWORD_KEYS" | grep -Eq " ${key_name}$"; then
      warn "1Password SSH agent is not exposing the '$key_name' key from the devenv vault."
    fi
  done
else
  warn "1Password SSH agent is unavailable. Unlock 1Password and verify its Developer settings."
fi
unset _ONEPASSWORD_AGENT _ONEPASSWORD_KEYS key_name

# GitHub CLI (hosts.yml remains local authentication state)
link "$DOTFILES/.config/gh/config.yml"      "$HOME/.config/gh/config.yml"

# SSH config (keys themselves are never tracked)
link "$DOTFILES/.ssh/config"               "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"

# Shell
link "$DOTFILES/.zshenv"                    "$HOME/.zshenv"
link "$DOTFILES/.config/zsh/.zprofile"      "$HOME/.config/zsh/.zprofile"
link "$DOTFILES/.bash_profile"              "$HOME/.bash_profile"
link "$DOTFILES/.config/zsh/.zshrc"         "$HOME/.config/zsh/.zshrc"

# Tmux (kept for remote/SSH sessions)
link "$DOTFILES/.tmux.conf"                 "$HOME/.tmux.conf"

# cmux
link "$DOTFILES/.config/cmux/settings.json"  "$HOME/.config/cmux/settings.json"

# Zed
link "$DOTFILES/.config/zed/settings.json"   "$HOME/.config/zed/settings.json"

# Claude Code
link "$DOTFILES/.config/claude/settings.json"    "$HOME/.claude/settings.json"
link "$DOTFILES/.config/claude/CLAUDE.md"        "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/.config/claude/keybindings.json" "$HOME/.claude/keybindings.json"
link "$DOTFILES/.config/claude/statusline.sh"    "$HOME/.claude/statusline.sh"
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
if [ ! -d "$OMZ_DIR/.git" ]; then
  if [ -e "$OMZ_DIR" ]; then
    warn "$OMZ_DIR exists but is not a git checkout; move it aside and re-run setup"
    exit 1
  fi
  info "Installing Oh My Zsh..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_DIR"
else
  info "Updating Oh My Zsh..."
  git -C "$OMZ_DIR" fetch --prune origin
  git -C "$OMZ_DIR" checkout master
  git -C "$OMZ_DIR" merge --ff-only origin/master
fi

# ── Tmux Plugin Manager ───────────────────────────────────────────────────────
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  info "Installing tmux plugin manager..."
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
  info "Updating tmux plugin manager..."
  git -C "$HOME/.tmux/plugins/tpm" pull --ff-only
fi
info "Installing and updating tmux plugins..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins"
"$HOME/.tmux/plugins/tpm/bin/update_plugins" all

# ── Python (via uv) ───────────────────────────────────────────────────────────
if command -v uv &>/dev/null; then
  info "Installing default Python via uv..."
  uv python install 3.13 --default
fi

# ── macOS defaults ────────────────────────────────────────────────────────────
# Reapply automatically when macos.sh changes. --apply-macos forces a run.
_MACOS_STAMP="$HOME/.config/.macos_defaults_applied"
_MACOS_HASH="$(shasum -a 256 "$DOTFILES/macos.sh" | awk '{print $1}')"
_APPLIED_MACOS_HASH="$(cat "$_MACOS_STAMP" 2>/dev/null || true)"
if [ "$SKIP_MACOS" = false ] && { [ "$FORCE_MACOS" = true ] || [ "$_MACOS_HASH" != "$_APPLIED_MACOS_HASH" ]; }; then
  "$DOTFILES/macos.sh"
  printf '%s\n' "$_MACOS_HASH" > "$_MACOS_STAMP"
else
  info "Skipping macOS defaults (unchanged — use --apply-macos to force)"
fi

echo ""
success "Done! Next steps:"
echo "  1. Restart your terminal"
echo "  2. Authenticate GitHub:"
echo "     gh auth login"
echo "     gh auth setup-git  # configure git credential helper"
echo "  3. Run 'claude' to authenticate with Anthropic"
