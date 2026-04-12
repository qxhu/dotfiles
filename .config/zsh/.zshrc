# oh-my-zsh
export ZSH="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/ohmyzsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# fzf
eval "$(fzf --zsh)"

# zoxide (smarter cd)
eval "$(zoxide init zsh)"

# Aliases
alias ls='eza --icons'
alias ll='eza -la --icons'
alias cat='bat --paging=never'
