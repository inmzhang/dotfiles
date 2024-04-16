# My dotfiles

This is the repository of my `zsh`, `tmux`, `kitty` and `neovim` configuration dotfiles. 
The bootstrap procedure is managed by `nix`. The process should work well on linux, macos
or even wsl.

## Installation

1. Firstly, you need to make sure [nix](https://nixos.org/download) is installed on your system 
and setup the `home-manager`.

2. Clone the repository to the proper position:

```shell
git clone https://github.com/inmzhang/dotfiles.git ~/.config/home-manager
cd ~/.config/home-manager
```

3. Check out `flake.nix` and `home.nix`, replace the username/system with yours.

4. Setup [Astronvim](https://docs.astronvim.com) and complete bootstrap:
```shell
chmod +x ./setup.sh

./setup.sh
```

5. Whenever you changed `home.nix` or other configurations, you need to run `home-manager switch` to
the change.
