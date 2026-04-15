# Homebrew — re-run after /etc/zprofile's path_helper reorders PATH
# (ZDOTDIR is set in .zshenv, so zsh reads this file, not ~/.zprofile)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || true)"
