# Homebrew (handles both Apple Silicon and Intel)
# Must run after /etc/zprofile's path_helper, which is why this lives here
# in $ZDOTDIR rather than ~/.zprofile (which zsh never reads once ZDOTDIR is set).
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

source ~/.bash_profile
