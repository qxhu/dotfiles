# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal macOS dotfiles. Everything is symlinked from this repo into `~` via `./setup.sh` — nothing is copied. The bootstrap script also installs Homebrew packages, oh-my-zsh, tmux plugin manager, and sets the default shell.

## Bootstrap / setup

```sh
./setup.sh   # idempotent; safe to re-run on an existing machine
```

There is no build step, test suite, or linter. Validate shell scripts with:

```sh
bash -n <file>      # syntax check
shellcheck <file>   # static analysis (install: brew install shellcheck)
```

## Key conventions

**XDG compliance:** All tool config paths are set in `.zshenv` using `$XDG_CONFIG_HOME` (`~/.config`), `$XDG_DATA_HOME`, etc. `ZDOTDIR` points to `.config/zsh/`, so zsh loads `.config/zsh/.zshrc` instead of `~/.zshrc`.

**Symlink model:** `setup.sh` calls `link src dst` for every tracked file. The `link()` function backs up any existing non-symlink file before overwriting. Never manually copy files — add a `link` call to `setup.sh` instead.

**Claude Code config:** `.config/claude/` is symlinked into `~/.claude/`. The `commands/` subdirectory holds shared slash commands/skills; each file is linked individually so `~/.claude/` can still hold untracked per-machine data.

**Git profiles:** `~/.config/git/config` uses `includeIf` to load per-directory profiles (e.g. `work`). Profile files (e.g. `~/.config/git/work`) are NOT tracked in this repo — they're created interactively by `setup.sh` and hold sensitive email addresses.

**Python:** `PIP_REQUIRE_VIRTUALENV=true` is set globally in `.config/conf_python.sh`. Use `gpip`/`gpip3` aliases for intentional global installs.

**cmux vs tmux:** cmux is for local dev; tmux is kept only for remote/SSH sessions. Tmux prefix is `C-f`.

**Non-CLI app configs:** Use `mackup` (in Brewfile) — not tracked here.
