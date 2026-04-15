# Homebrew (must come first so brew is available for all subsequent config)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || true)"

# XDG base dirs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_RUNTIME_DIR="/tmp"

# Shell
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# Local binaries (uv-managed Python, etc.)
export PATH="$HOME/.local/bin:$PATH"

# Node
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"

# Cloud credentials
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
export GOOGLE_APPLICATION_CREDENTIALS="$XDG_CONFIG_HOME/gcp/credentials.json"
