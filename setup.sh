#! /usr/bin/env bash
set -e

# Make a backup of your current nvim and shared folder
mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak

# Install Astronvim
git clone https://github.com/inmzhang/astronvim_config ~/.config/nvim

# Set up home-manager
home-manager switch
