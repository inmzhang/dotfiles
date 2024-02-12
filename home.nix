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
    python3
    nodejs
    rustup
    libllvm
    cmake
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
    ruff
    yt-dlp
    hyperfine
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".config/tmux/tmux.conf".source = dotfiles/tmux/tmux.conf;
    ".config/kitty".source = dotfiles/kitty;
    ".config/nvim/lua/user".source = dotfiles/nvim/user;
    ".config/starship.toml".source = dotfiles/starship/starship.toml;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/inm/etc/profile.d/hm-session-vars.sh
  #
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
  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
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
  programs.pyenv = {
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
  #     ctrl_n_shortcuts = true;
  #     enter_accept = false;
  #     keymap_mode = "vim-normal";
  #   };
  # };
}
