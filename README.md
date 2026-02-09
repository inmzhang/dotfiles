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
│   └── claude/        #   Claude Code (settings, scripts, skills)
├── packages/          # Package lists
│   ├── arch.txt       #   Arch Linux (yay)
│   └── brew.txt       #   macOS (Homebrew)
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
