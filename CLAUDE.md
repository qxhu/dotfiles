# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS. Shell: zsh + oh-my-zsh. Terminal: Ghostty. Multiplexer: tmux (remote/SSH only). AI: Claude Code.

## Deployment

Run `./setup.sh` on a new machine. It installs Homebrew, runs `brew bundle`, and symlinks all configs into place. No manual copying — everything is symlinked from this repo.

## File Layout

```
.zshenv                         # Loaded first; sets XDG dirs and all tool env vars
.zprofile                       # Sources .bash_profile for bash compat
.bash_profile                   # PATH setup; loads ~/.{path,exports,aliases,functions,extra}
.tmux.conf                      # Tmux config (remote/SSH use only)
.config/
  zsh/.zshrc                    # Main zsh config (oh-my-zsh, robbyrussell theme)
  ghostty/config                # Ghostty terminal config
  claude/
    CLAUDE.md                   # Global Claude instructions (synced across machines)
    settings.json               # Claude Code preferences
    keybindings.json            # Claude Code keybindings
    commands/                   # Shared slash commands / skills
  conf_docker.sh                # Docker aliases (source manually)
  conf_python.sh                # Python/pip config (PIP_REQUIRE_VIRTUALENV, gpip)
Brewfile                        # Declarative package list (brew bundle)
setup.sh                        # Bootstrap script for new machines
```

## Key Conventions

**XDG compliance:** All tool config paths in `.zshenv` use `$XDG_CONFIG_HOME` (`~/.config`), `$XDG_DATA_HOME` (`~/.local/share`), etc. ZDOTDIR points to `.config/zsh/`.

**Claude Code sync:** `.config/claude/` is symlinked into `~/.claude/`. The `commands/` dir holds shared skills/slash commands. Per-machine data (`~/.claude/projects/`, `~/.claude/statsig/`) is intentionally NOT tracked here.

**Ghostty vs tmux:** Use Ghostty's native splits/tabs for local development. Keep tmux for remote SSH sessions where session persistence matters.

**Tmux prefix:** `C-f` (not default `C-b`). Vim hjkl for pane navigation. Plugins via tpm.

**Python:** `PIP_REQUIRE_VIRTUALENV=true` globally. Use `gpip`/`gpip3` for global installs.

**Non-CLI apps:** Use `mackup` (included in Brewfile) to sync app configs. Run `mackup backup` to save, `mackup restore` on a new machine.
