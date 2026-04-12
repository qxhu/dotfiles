# dotfiles

Personal macOS dotfiles. Shell: zsh + oh-my-zsh. Terminal: cmux. AI: Claude Code.

## Bootstrap

```sh
git clone https://github.com/qxhu/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
./setup.sh
```

`setup.sh` will:
1. Install Xcode CLI tools (if missing)
2. Install Homebrew and run `brew bundle`
3. Prompt for git identities (per-profile)
4. Symlink all configs into place
5. Set Homebrew zsh as default shell
6. Install oh-my-zsh, tmux plugin manager, Claude Code, fzf shell integration

## Layout

```
.zshenv                     # Loaded first; XDG dirs and tool env vars
.zprofile / .bash_profile   # PATH setup
.config/
  zsh/.zshrc                # oh-my-zsh config (robbyrussell theme)
  cmux/settings.json        # cmux terminal config
  git/config                # Git config (multi-profile support)
  git/ignore                # Global gitignore
  claude/
    CLAUDE.md               # Global Claude Code instructions
    settings.json           # Claude Code preferences
    keybindings.json        # Claude Code keybindings
    commands/               # Shared slash commands / skills
  conf_docker.sh            # Docker aliases (source manually)
  conf_python.sh            # Python config (PIP_REQUIRE_VIRTUALENV, gpip)
.ssh/config                 # SSH config (keys not tracked)
.tmux.conf                  # Tmux (remote/SSH sessions only)
Brewfile                    # Declarative package list
setup.sh                    # Bootstrap script
```

## Key tools

| Tool | Purpose |
|------|---------|
| cmux | Terminal multiplexer for local dev |
| tmux | Multiplexer for remote/SSH sessions only |
| Raycast | App launcher |
| fzf + zoxide | Fuzzy find + smart `cd` |
| ripgrep + bat + eza | Better grep, cat, ls |
| Claude Code | AI coding assistant (installed via brew cask) |
| mackup | Sync non-CLI app configs |

## Non-tracked app configs

Use `mackup` for GUI app preferences:

```sh
mackup backup    # save
mackup restore   # on a new machine
```

## After setup

1. Restart terminal
2. Authenticate GitHub: `gh auth login` (once per account)
3. Run `claude` to authenticate with Anthropic
4. In tmux: `prefix + I` to install plugins (`C-f` is the prefix)
