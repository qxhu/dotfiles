# oh-my-zsh
export ZSH="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/ohmyzsh"
ZSH_THEME="robbyrussell"
plugins=(git)
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# fzf
if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

# zoxide (smarter cd)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Aliases
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons'
  alias ll='eza -la --icons'
fi
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
fi
