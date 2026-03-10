# dotfiles

Personal configuration files for Arch Linux and macOS, managed with a
Makefile and explicit symlinks.

## Structure

```
~/dotfiles/
├── config/            # Application configs (one directory per app)
│   ├── nvim/          #   Neovim
│   ├── zsh/           #   Zsh (.zshrc + helper scripts)
│   ├── git/           #   Git (config)
│   ├── hyprland/      #   Hyprland (Linux only)
│   ├── ...
│   ├── claude/        #   Claude Code (settings, scripts, skills)
│   └── codex/         #   Codex CLI (config, rules, memories, skills)
├── packages/          # Package lists
│   ├── arch.txt       #   Arch Linux (yay)
│   └── brew.txt       #   macOS (Homebrew)
├── scripts/           # Project-agnostic local automation
├── Makefile           # Symlink & package orchestration
├── setup.sh           # Fresh machine bootstrap
└── README.md
```

Each directory under `config/` holds the raw config files for one
application. The `Makefile` maps each to its target location under `$HOME`.

## Fresh machine setup

```sh
git clone https://github.com/inmzhang/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x setup.sh
./setup.sh
```

`setup.sh` will:
1. Install the package manager (`yay` on Arch, Homebrew on macOS)
2. Install all packages from `packages/{arch,brew}.txt`
3. Install Claude Code
4. Symlink every config via `make link`
5. Set zsh as the default shell

## Day-to-day usage

| Command | Description |
|---------|-------------|
| `make link` | Create all symlinks |
| `make unlink` | Remove all symlinks |
| `make relink` | Remove + recreate symlinks |
| `make packages` | Install packages for current platform |
| `make firefox` | Symlink Firefox userChrome.css (Linux) |
| `make hyprland-setup` | Bootstrap Hyprland via JaKooLit installer |
| `make codex-skills-link` | Sync Codex skills from this repo into `~/.codex/skills` |
| `make codex-skills-unlink` | Remove Codex skill symlinks that came from this repo |

## Local automation

Project-agnostic helper scripts live under `scripts/`.

- `scripts/continuous-run/continuous-codex.sh` runs Codex continuously against
  the repo in your current working tree or a `--repo` target.
- `scripts/continuous-run/continuous-claude.sh` does the same for Claude Code.
- `--parallel` or `CONTINUOUS_RUN_ENABLE_PARALLEL=1` enables the opt-in
  parallel-agent prompt guidance.
- In zsh, `continuous-codex` and `continuous-claude` call those launchers
  directly from your shell config.

## Codex skills

`make link` automatically runs `make codex-skills-link`, which symlinks every
skill directory in `config/codex/skills/` into `~/.codex/skills/`.

Current local Codex skills:
- `ask-user-question`: Structured requirement interviews using option-based questions.
- `gh-fix-ci`: Diagnose and fix failing GitHub Actions PR checks with `gh`.
- `ideas`: Research brainstorming conversations from the `sci-brain` project.
- `pdf`: Read/create/review PDFs with layout-aware validation.
- `quicknote`: Save the last substantial research exchange as a markdown note.
- `researchstyle`: Build a research profile from Zotero or Google Scholar context.
- `survey`: Map literature and adjacent work before brainstorming.
- `tuicr`: Review local git changes with tuicr in a tmux split pane.
- `writer`: Turn prior brainstorming sessions into a structured write-up.

## Codex MCP servers

`config/codex/config.toml` is symlinked into `~/.codex/config.toml` and tracks
the Codex MCP server configuration for this machine.

Current tracked MCP servers:
- `context7`: Library and framework documentation lookup.
- `arxiv`: Search arXiv papers and download paper PDFs into a dedicated cache.
- `paper_search`: Search multiple academic sources including PubMed and preprint servers.
- `semantic_scholar`: Query citation graphs, related work, and recommendations.
- `zotero`: Search the local Zotero library through Zotero's local API.

## Adding a new application config

1. Create a directory under `config/`:

   ```sh
   mkdir -p config/myapp
   ```

2. Place the config files inside. Use the flat structure &mdash; no need to
   mirror `~/.config/`:

   ```
   config/myapp/
   └── settings.toml
   ```

3. Add a symlink mapping in the `Makefile` `link` target:

   ```makefile
   $(call ln_sf,$(DOTDIR)/config/myapp/settings.toml,$(HOME)/.config/myapp/settings.toml)
   ```

   For platform-specific configs, place the line inside the
   `ifeq ($(UNAME_S),Linux)` or `Darwin` block.

4. Add the matching `rm -f` line in the `unlink` target:

   ```makefile
   rm -f $(HOME)/.config/myapp/settings.toml
   ```

5. Run `make relink` to activate.

## Adding system packages

Append the package name to the appropriate list:

- **Arch Linux**: `packages/arch.txt` (one package per line, `#` for comments)
- **macOS**: `packages/brew.txt`

Then run:

```sh
make packages
```

## Private / machine-specific config

`config/zsh/zsh-private.sh` is sourced by `.zshrc` but gitignored.
Use it for API keys, proxy settings, or anything machine-specific:

```sh
# config/zsh/zsh-private.sh (not tracked)
export OPENAI_API_KEY="sk-..."
```
