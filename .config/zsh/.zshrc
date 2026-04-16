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

# Plugins (installed via Homebrew)
_brew_prefix="$(brew --prefix)"
[[ -f "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "$_brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$_brew_prefix/share/zsh-history-substring-search/zsh-history-substring-search.zsh" ]] && {
  source "$_brew_prefix/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}
# syntax-highlighting must be sourced last
[[ -f "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
  source "$_brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
unset _brew_prefix
