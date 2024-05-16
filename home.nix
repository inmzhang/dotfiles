{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  # TODO: Change these values to match your username and home directory.
  home.username = "inm";
  home.homeDirectory = "/Users/inm";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    xclip
    nodejs
    du-dust
    ripgrep
    lsd
    bat
    bottom
    tmux
    kitty
    tree-sitter
    lazygit
    gdu
    rm-improved
    just
    yt-dlp
    hyperfine
    gh
    onefetch
    fastfetch
    tealdeer
    btop
    fd
    skim
    p7zip
    parallel
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".tmux.conf".source = dotfiles/tmux/tmux.conf;
    ".config/kitty".source = dotfiles/kitty;
    ".config/starship.toml".source = dotfiles/starship/starship.toml;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  # ZSH
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;
    initExtra = ''
      if [ -f $HOME/.config/home-manager/dotfiles/zsh/.zshrc ];
      then
        source $HOME/.config/home-manager/dotfiles/zsh/.zshrc
      fi
      '';
  };
  # Git
  programs.git = {
    enable = true;
    userName = "Yiming Zhang";
    userEmail = "zhangyiming21@mail.ustc.edu.cn";
  };
  # others
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };
  # programs.atuin = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   settings = {
  #     auto_sync = true;
  #     ctrl_n_shortcuts = true;
  #     enter_accept = false;
  #     keymap_mode = "vim-normal";
  #   };
  # };
  programs.pyenv = {
    enable = true;
    enableZshIntegration = true;
  };
}
