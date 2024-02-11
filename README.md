# My dotfiles

This is the repository of my `zsh`, `tmux`, `kitty` and `neovim` configuration dotfiles. 
The bootstrap procedure is managed by `nix`.

## Installation

1. Firstly, you need to make sure [nix](https://nixos.org/download) is installed on your system.

2. Clone the repository to the proper position:

```shell
git clone https://github.com/inmzhang/dotfiles.git ~/.config/home-manager
cd ~/.config/home-manager
```

3. Check out `flake.nix` and `home.nix`, replace the username/system with yours.

4. Setup [Astronvim](https://docs.astronvim.com) and complete bootstrap:
```shell
chmod +x ./dotfiles/nvim/setup.sh
chmod +x ./setup.sh

./setup.sh
```
