#! /usr/bin/env bash
set -e
# Install Astronvim
astronvim_setup_path="./dotfiles/nvim/setup.sh"
chmod +x $astronvim_setup_path
$astronvim_setup_path
# Set up home-manager
home-manager switch
