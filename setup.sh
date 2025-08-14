#!/usr/bin/env bash
set -euo pipefail

# Function to print error message and exit
function error_exit {
  echo "$1" >&2
  exit 1
}

# Install Nix
# Official installation link: https://nixos.org/download/
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon || error_exit "Failed to install Nix."
else
  echo "Nix is already installed."
fi

# Install Nix Home Manager
# Official installation link: https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone
echo "Setting up Nix Home Manager..."
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager || error_exit "Failed to add home-manager channel."
nix-channel --update || error_exit "Failed to update nix channels."
nix-shell '<home-manager>' -A install || error_exit "Failed to install Home Manager."

# Enable experimental features in Nix
mkdir -p ~/.config/nix
if ! grep -q "experimental-features = nix-command flakes" ~/.config/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  echo "Enabled Nix experimental features."
else
  echo "Nix experimental features already enabled."
fi

# symbolic links
ln -s $(pwd)/dotfiles/nvim ~/.config/nvim
ln -s $(pwd)/dotfiles/hyprland/config ~/.config/hypr
ln -s $(pwd)/dotfiles/waybar ~/.config/waybar
ln -s $(pwd)/dotfiles/rofi ~/.config/rofi

# Set up Home Manager
echo "Setting up Home Manager..."
home-manager switch || error_exit "Failed to switch Home Manager configuration."

echo "Setup completed successfully."
