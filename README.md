# dotfiles

Personal configuration for Omarchy and macOS. On Omarchy this repository is a
thin user-owned layer over the distribution defaults, not a replacement
Hyprland distribution.

## Omarchy ownership model

| Path | Owner | Git strategy |
|---|---|---|
| `/usr/share/omarchy` | Omarchy packages | Never edit or track |
| `~/.config/hypr`, `~/.config/omarchy` | Omarchy user overrides | Track only intentional deltas |
| `~/.config/nvim`, `~/.config/tmux`, `~/.bash_profile`, `~/.zshrc` | Personal | Symlink from this repository |
| `~/.local/state/omarchy` | Generated theme/runtime state | Never track |

The only tracked Hyprland delta is
`config/omarchy/hypr/monitors.lua`. `make omarchy-apply` copies it into the
live Omarchy config and checks Hyprland for configuration errors. It is copied
instead of symlinked so an Omarchy refresh cannot accidentally write into the
Git checkout.

Ghostty is also a thin overlay. `config/ghostty/linux` loads Omarchy's packaged
configuration and then `~/.config/ghostty/dotfiles.conf`, copied from
`config/ghostty/linux-overrides`. Keeping the terminal font size in that
second file prevents Omarchy's global text-size control from rewriting it.

## Set up an Omarchy machine

```sh
git clone https://github.com/inmzhang/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script installs packages through `omarchy pkg`, enables the official
`omarchy-zsh` Bash-to-Zsh handoff, and runs the curated migration target. Any
existing config replaced by a symlink or managed copy is first preserved at a
timestamped `.bak.YYYYmmdd-HHMMSS` path.

If packages and Zsh are already installed, activate just the intended personal
overrides with:

```sh
make omarchy-link
```

This activates:

- the repository's vanilla Neovim 0.12+ configuration instead of LazyVim;
- the personal tmux configuration under `~/.config/tmux/tmux.conf`;
- the Bash login profile, including terminal proxy variables;
- the personal Zsh layer on top of `omarchy-zsh`;
- the Ghostty overlay on top of Omarchy's packaged config;
- the tracked monitor override.

The rest of Hyprland, Waybar, launchers, logout UI, Qt theming, screenshots,
themes, and wallpaper integration remain owned by Omarchy.

## Zsh on Omarchy

Omarchy intentionally leaves Bash as the login shell and launches Zsh from its
interactive Bash startup. Do not use `chsh` on Omarchy. The tracked `.zshrc`
sources `/usr/share/omarchy-zsh/shell/{zoptions,all}` first and then loads the
personal aliases, functions, environment, and optional private file.
The tracked `.bash_profile` exports the terminal proxy before that handoff, so
commands launched directly through a Bash login shell inherit it too.

`config/zsh/zsh-private.sh` is ignored by Git. Use it for machine-local values
or secrets:

```sh
# config/zsh/zsh-private.sh
export OPENAI_API_KEY="..."
```

## Everyday commands

| Command | Description |
|---|---|
| `make omarchy-link` | Activate the curated Omarchy config set with backups |
| `make omarchy-apply` | Copy Ghostty/monitor overrides and reload affected apps |
| `make omarchy-diff` | Compare tracked and live Omarchy-managed copies |
| `make packages` | Install packages for the current platform |
| `make link` | Link the complete config collection, including AI tooling |
| `make unlink` | Remove only symlinks that point into this repository |
| `make relink` | Recreate the complete non-curated symlink set |
| `make firefox` | Link Firefox `userChrome.css` after a profile exists |

Use Omarchy's own menus and commands for desktop settings. Refresh commands can
replace user configuration from packaged defaults; `make omarchy-apply`
restores the tracked Ghostty and monitor deltas afterward.

## Git sync workflow

Only this repository is synchronized. Do not turn the whole home directory or
Omarchy's generated state into a dotfiles repository.

```sh
# On the source machine
git add -A
git commit -m "Update dotfiles"
git push

# On another Omarchy machine
git pull --ff-only
make omarchy-link
make omarchy-diff
```

Inspect changes and backups before committing. Secrets, state databases,
downloaded plugins, theme state, and caches should stay outside Git.

## Package lists

- `packages/arch.txt`: packages available through Omarchy/Arch repositories;
- `packages/arch-aur.txt`: AUR-only packages;
- `packages/omarchy.txt`: Omarchy-specific integrations such as
  `omarchy-zsh`;
- `packages/brew.txt`: macOS Homebrew packages.

Run `make packages` after editing a list. On Omarchy, package installation may
prompt for the user's sudo password.

## Repository structure

```text
config/
├── omarchy/hypr/     # Deliberately tracked Omarchy overrides
├── ghostty/          # Linux overlay and macOS config
├── nvim/             # Vanilla Neovim configuration
├── tmux/             # tmux configuration
├── zsh/              # Personal Zsh layer
├── claude/           # Optional Claude Code configuration
└── codex/             # Optional Codex configuration, agents, and skills
packages/               # Platform-specific package manifests
Makefile                # Safe linking, backup, and apply targets
setup.sh                # Fresh-machine bootstrap
```

## macOS and non-Omarchy Arch

`make link` retains the complete, cross-platform symlink behavior. On macOS,
`setup.sh` uses Homebrew and changes the login shell to Zsh. On a non-Omarchy
Arch system it uses `yay` and also changes the login shell.

## Adding another personal config

Place the file under `config/<application>/`, then add matching `ln_sf` and
`unlink_sf` calls to the Makefile. `ln_sf` backs up an existing target;
`unlink_sf` removes only a symlink that points to the expected repository
source. Add it to `omarchy-link` only if the application is genuinely
user-owned rather than part of Omarchy's desktop stack.
