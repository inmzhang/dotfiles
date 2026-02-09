#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname -s)"

info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m  %s\n" "$*"; }
error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*" >&2; exit 1; }
ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$*"; }

info "Detected platform: $OS"

# ── Install prerequisites ───────────────────────────────────────────────────

if [[ "$OS" == "Linux" ]]; then
    if ! command -v yay >/dev/null 2>&1; then
        info "Installing yay (AUR helper)..."
        sudo pacman -S --needed --noconfirm base-devel git
        tmpdir="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
        (cd "$tmpdir/yay" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
        ok "yay installed."
    else
        ok "yay already installed."
    fi
elif [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        ok "Homebrew installed."
    else
        ok "Homebrew already installed."
    fi
fi

# ── Install packages ────────────────────────────────────────────────────────

info "Installing packages..."
cd "$REPO_DIR"
make packages

# ── Install Claude Code ────────────────────────────────────────────────────

if ! command -v claude >/dev/null 2>&1; then
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
    ok "Claude Code installed."
else
    ok "Claude Code already installed."
fi

# ── Link all dotfiles ───────────────────────────────────────────────────────
info "Linking dotfiles..."
make link

# ── Firefox (Linux only) ────────────────────────────────────────────────────

if [[ "$OS" == "Linux" ]]; then
    make firefox 2>/dev/null || warn "Firefox profile not found. Run 'make firefox' later."
fi

# ── Default shell ───────────────────────────────────────────────────────────

if [[ "$SHELL" != *zsh* ]]; then
    info "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
    ok "Default shell changed. Log out and back in."
fi

# ── Done ────────────────────────────────────────────────────────────────────

echo ""
ok "Setup complete!"
echo ""
echo "  Next steps:"
echo "    1. Log out and log back in (or run: exec zsh)"
echo "    2. Run 'tldr --update' to populate tealdeer cache"
echo ""
echo "  To update packages:"
if [[ "$OS" == "Linux" ]]; then
    echo "    yay -Syu"
else
    echo "    brew update && brew upgrade"
fi
echo ""
echo "  To re-link dotfiles after changes:"
echo "    make relink"
