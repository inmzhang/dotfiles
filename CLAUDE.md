# Dotfiles

Personal configuration files for Arch Linux and macOS, managed with a Makefile and explicit symlinks.

## Repository Structure

```
~/dotfiles/
├── config/           # Application configs (one directory per app)
│   ├── zsh/          # Zsh shell (.zshrc, aliases, funcs, envars)
│   ├── nvim/         # Neovim (AstroNvim v5 + lazy.nvim)
│   ├── tmux/         # Tmux (C-a prefix, Catppuccin Mocha theme, TPM)
│   ├── git/          # Git (delta pager, proxy, log aliases)
│   ├── ghostty/      # Ghostty terminal (separate linux/macos configs)
│   ├── starship/     # Starship prompt (Nerd Font symbols)
│   ├── hyprland/     # Hyprland WM (JaKooLit setup, Linux only)
│   ├── waybar/       # Waybar status bar (Linux only)
│   ├── rofi/         # Rofi launcher (Linux only)
│   ├── claude/       # Claude Code (settings, hooks, skills, scripts)
│   ├── atuin/        # Atuin shell history (vim-normal keymap)
│   └── ...           # bat, cava, wallust, sioyek, uv, etc.
├── packages/         # Package lists
│   ├── arch.txt      # Arch Linux packages (yay)
│   └── brew.txt      # macOS packages (Homebrew)
├── Makefile          # Symlink & package orchestration
├── setup.sh          # Fresh machine bootstrap
└── CLAUDE.md
```

## Key Commands

| Command | What it does |
|---------|-------------|
| `make link` | Create all config symlinks |
| `make unlink` | Remove all config symlinks |
| `make relink` | Remove + recreate all symlinks |
| `make packages` | Install packages for current platform |
| `make install` | Full setup (packages + link) |
| `make firefox` | Symlink Firefox userChrome.css (Linux) |
| `make hyprland-setup` | Bootstrap Hyprland via JaKooLit installer |
| `./setup.sh` | Full fresh-machine bootstrap |

## Architecture & Conventions

### Symlink Management
- All config symlinks are defined in `Makefile` via the `ln_sf` helper macro
- Common configs (zsh, tmux, nvim, git, starship, etc.) are linked on all platforms
- Platform-specific configs are inside `ifeq ($(UNAME_S),Linux)` / `Darwin` blocks
- Claude Code configs (`settings.json`, `agents/`, `commands/`, `hooks/`, `rules/`, `scripts/`, `skills/`) are symlinked to `~/.claude/`

### Adding a New Config
1. Create directory: `config/<appname>/`
2. Add `$(call ln_sf,...)` line in Makefile `link` target
3. Add matching `rm -f` line in `unlink` target
4. Platform-specific? Put it inside the appropriate `ifeq` block
5. Run `make relink`

### Adding System Packages
- Arch: append to `packages/arch.txt` (one per line, `#` for comments)
- macOS: append to `packages/brew.txt`
- Run `make packages`

### Private Config
- `config/zsh/zsh-private.sh` is sourced by `.zshrc` but gitignored
- Use for API keys, proxy settings, machine-specific env vars

## Key Tool Choices

- **Shell**: zsh with zsh-autosuggestions, zsh-syntax-highlighting, atuin, zoxide, starship, direnv, fzf
- **Editor**: Neovim via AstroNvim v5 (lazy.nvim, leader=Space, localleader=Comma)
- **Terminal**: Ghostty (Gruvbox Dark theme)
- **Multiplexer**: tmux (C-a prefix, vi mode, TPM, Catppuccin Mocha colors)
- **Git**: delta pager, pretty log aliases (`git lg`/`lg1`/`lg2`/`lg3`)
- **File manager**: yazi (with `y()` shell wrapper for cwd tracking)
- **Proxy**: clash-verge on port 7897, auto-enabled on shell start via `proxy_on` (falls back to 7890/7891 without clash-verge)
- **Package managers**: yay (Arch), Homebrew (macOS), uv (Python), cargo (Rust), bun/nvm (JS)
- **WM (Linux)**: Hyprland with waybar, rofi, wallust, wlogout, AGS, swappy

## Shell Functions & Aliases

Key functions in `config/zsh/funcs.sh`:
- `y` - yazi with cwd tracking
- `vv` - open nvim with auto venv activation
- `tp <dir>` - tmux session at directory (zoxide-aware, auto-venv)
- `tcode [dir]` - 3-window tmux layout: Code + Term + Agent (runs claude)
- `tnote [dir]` - 3-window tmux layout: Notes + Term + Agent
- `proxy_on` / `proxy_off` - toggle terminal proxy

Key aliases in `config/zsh/aliases.sh`:
- `v` -> nvim . (opens cwd), `vi`/`vim` -> nvim, `ls` -> lsd, `cat` -> bat, `du` -> dust
- `gs`/`ga`/`gc`/`gcm`/`gco`/`gb`/`gp`/`gP` - git shortcuts
- `dots` - cd to dotfiles + relink
- `dot` - cd to dotfiles + open in nvim

## Claude Code Configuration

Settings are in `config/claude/settings.json`:
- Default model: opus, fast mode enabled, always-thinking enabled
- LSP tool enabled, agent teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Package manager: bun (`CLAUDE_PACKAGE_MANAGER=bun` in envars.sh)
- Auto-allowed tools: Read, Edit, Write, Glob, Grep, WebFetch, WebSearch, NotebookEdit, LSP, Task, Bash(agent-browser *)
- Custom statusLine via `~/.claude/scripts/context-bar.sh`
- Plugins: context7, rust-analyzer-lsp, frontend-design, code-review, feature-dev, code-simplifier, commit-commands, claude-md-management, claude-code-setup, mgrep, hookify

### Claude Hooks (`config/claude/hooks/hooks.json`)
- **PreToolUse**: git push reminder, block random .md file creation, suggest compaction at logical intervals
- **PostToolUse**: log PR URL after `gh pr create`
- **SessionStart**: load previous context and detect package manager
- **SessionEnd**: persist session state + evaluate session for extractable patterns (continuous-learning)
- **PreCompact**: save state before context compaction

### Custom Commands (`config/claude/commands/`)
Slash commands: `/checkpoint`, `/eval`, `/evolve`, `/learn`, `/tdd`, `/sessions`, `/skill-create`, `/instinct-status`, `/instinct-export`, `/instinct-import`

### Custom Agents & Rules
- Agent: `config/claude/agents/tdd-guide.md` - TDD workflow enforcement
- Rule: `config/claude/rules/hooks.md` - hooks system guidelines

## Editing Guidelines

- This is a dotfiles repo: configs are declarative, not application code
- Prefer editing existing files over creating new ones
- Never commit secrets (API keys, tokens) - use `zsh-private.sh` instead
- Test symlinks with `make relink` after changes
- Hyprland config comes from JaKooLit; user customizations go in `UserConfigs/` and `UserScripts/`
- Git uses proxy at 127.0.0.1:7897 (matches clash-verge)
