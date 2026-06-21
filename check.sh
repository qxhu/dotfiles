#!/usr/bin/env bash
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0
checks=0

pass() { printf '\033[0;32m[pass]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[warn]\033[0m %s\n' "$*"; }
fail() { printf '\033[0;31m[fail]\033[0m %s\n' "$*"; failures=$((failures + 1)); }

check_command() {
  checks=$((checks + 1))
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 is installed"
  else
    fail "$1 is not installed"
  fi
}

check_link() {
  local src="$1" dst="$2" actual
  checks=$((checks + 1))
  if [ ! -L "$dst" ]; then
    fail "$dst is not a symlink"
    return
  fi
  actual="$(readlink "$dst")"
  if [ "$actual" = "$src" ]; then
    pass "$dst"
  else
    fail "$dst points to $actual instead of $src"
  fi
}

printf '\nChecking commands...\n'
for command_name in brew git gh zsh jq tmux uv ssh-add; do
  check_command "$command_name"
done

printf '\nChecking managed symlinks...\n'
while IFS='|' read -r src dst; do
  check_link "$DOTFILES/$src" "$HOME/$dst"
done <<'EOF'
.config/git/config|.config/git/config
.config/git/ignore|.config/git/ignore
.config/git/qxhu|.config/git/qxhu
.config/git/qxhu-signing.pub|.config/git/qxhu-signing.pub
.config/git/allowed_signers|.config/git/allowed_signers
.config/1Password/ssh/agent.toml|.config/1Password/ssh/agent.toml
.config/gh/config.yml|.config/gh/config.yml
.ssh/config|.ssh/config
.zshenv|.zshenv
.config/zsh/.zprofile|.config/zsh/.zprofile
.bash_profile|.bash_profile
.config/zsh/.zshrc|.config/zsh/.zshrc
.tmux.conf|.tmux.conf
.config/cmux/settings.json|.config/cmux/settings.json
.config/zed/settings.json|.config/zed/settings.json
.config/claude/settings.json|.claude/settings.json
.config/claude/CLAUDE.md|.claude/CLAUDE.md
.config/claude/keybindings.json|.claude/keybindings.json
.config/claude/statusline.sh|.claude/statusline.sh
EOF

printf '\nChecking Git and GitHub...\n'
checks=$((checks + 1))
if git -C "$DOTFILES" var GIT_AUTHOR_IDENT 2>/dev/null | grep -q '^qxhu <qxhu@users\.noreply\.github\.com> '; then
  pass "Git uses the qxhu no-reply identity"
else
  fail "Git is not using qxhu <qxhu@users.noreply.github.com>"
fi

checks=$((checks + 1))
if git -C "$DOTFILES" verify-commit HEAD >/dev/null 2>&1; then
  pass "HEAD has a valid local signature"
else
  fail "HEAD does not have a valid local signature"
fi

checks=$((checks + 1))
if gh auth status --hostname github.com >/dev/null 2>&1; then
  pass "GitHub CLI is authenticated"
else
  fail "GitHub CLI is not authenticated; run gh auth login"
fi

printf '\nChecking 1Password...\n'
agent_socket="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
checks=$((checks + 1))
if [ ! -S "$agent_socket" ]; then
  fail "1Password SSH agent is not running"
elif agent_keys="$(SSH_AUTH_SOCK="$agent_socket" ssh-add -L 2>/dev/null)"; then
  pass "1Password SSH agent is running"
  for key_name in qxhu servers; do
    checks=$((checks + 1))
    if printf '%s\n' "$agent_keys" | grep -Eq " ${key_name}$"; then
      pass "1Password exposes $key_name"
    else
      fail "1Password does not expose $key_name"
    fi
  done
else
  fail "1Password SSH agent is unavailable; unlock 1Password"
fi

printf '\nChecking managed dependencies...\n'
for app_name in 1Password ChatGPT; do
  checks=$((checks + 1))
  if [ -d "/Applications/${app_name}.app" ]; then
    pass "${app_name}.app is installed"
  else
    fail "${app_name}.app is missing; run ./setup.sh"
  fi
done

checks=$((checks + 1))
if brew bundle check --file="$DOTFILES/Brewfile" >/dev/null 2>&1; then
  pass "Brewfile dependencies are installed"
else
  fail "Brewfile dependencies are incomplete; run ./setup.sh"
fi

for repo in "$HOME/.config/zsh/ohmyzsh" "$HOME/.tmux/plugins/tpm"; do
  checks=$((checks + 1))
  if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    pass "$repo is a Git checkout"
  else
    fail "$repo is missing or invalid"
  fi
done

printf '\n%d checks, %d failures\n' "$checks" "$failures"
if [ "$failures" -ne 0 ]; then
  exit 1
fi
