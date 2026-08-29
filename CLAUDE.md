# Dotfiles repository guidance

This repository manages personal configurations for Omarchy and macOS.

## Omarchy boundaries

- Treat Omarchy as the owner of Hyprland, Waybar, launchers, logout UI, Qt
  theming, screenshots, themes, and other desktop integration.
- Never edit or track `/usr/share/omarchy`; it is package-owned.
- Do not track generated content from `~/.local/state/omarchy`.
- Track only deliberate user deltas under `config/omarchy/`. The current delta
  is `config/omarchy/hypr/monitors.lua`, applied as a regular file with
  `make omarchy-apply`.
- The Linux Ghostty wrapper and its separate personal include are copied into
  `~/.config/ghostty`; the personal include prevents Omarchy's global text-size
  control from rewriting the terminal-only size.
- Validate Hyprland edits with `hyprctl reload` and `hyprctl configerrors`.

## Primary commands

| Command | Purpose |
|---|---|
| `make omarchy-link` | Activate the curated Zsh, tmux, Neovim, Ghostty, and monitor overrides |
| `make omarchy-apply` | Copy and validate tracked Ghostty and monitor overrides |
| `make omarchy-diff` | Compare tracked and live Omarchy-managed copies |
| `make packages` | Install the platform's package manifests |
| `make link` | Link the complete config set, including optional AI tooling |
| `make unlink` | Remove only repository-owned symlinks |
| `make firefox` | Link Firefox `userChrome.css` after a profile exists |

## Conventions

- Use the Makefile's `ln_sf` and `unlink_sf` helpers. Existing targets are
  backed up; regular files must never be silently deleted.
- On Omarchy, preserve the official `omarchy-zsh` Bash-to-Zsh handoff. Bash
  remains the login shell; the tracked `.zshrc` sources the package layer and
  then applies personal overrides.
- The repository Neovim config is vanilla Neovim 0.12+ using `vim.pack`, not
  LazyVim or AstroNvim.
- `config/zsh/zsh-private.sh` is ignored and is the place for secrets and
  machine-specific values.
- Arch packages belong in `packages/arch.txt`, AUR-only packages in
  `packages/arch-aur.txt`, Omarchy integrations in `packages/omarchy.txt`, and
  macOS packages in `packages/brew.txt`.
- Never commit credentials, runtime databases, generated themes, caches, or
  downloaded plugins.

See `README.md` for the setup and Git synchronization workflow.
