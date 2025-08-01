{ config, pkgs, ... }:
let
commonFiles = {
  ".tmux.conf".source = dotfiles/tmux/tmux.conf;
  ".config/ghostty/config".source = if pkgs.stdenv.isLinux then dotfiles/ghostty/linux else dotfiles/ghostty/macos;
  ".config/sioyek".source = dotfiles/sioyek;
  ".config/starship.toml".source = dotfiles/starship/starship.toml;
  ".config/ncspot/config.toml".source = dotfiles/ncspot/config.toml;
  ".config/uv".source = dotfiles/uv;
  ".config/fastfetch".source = dotfiles/fastfetch;
};
linuxFiles = {
  ".config/hypr".source = dotfiles/hyprland/config;
  ".config/waybar".source = dotfiles/waybar;
  ".config/Kvantum".source = dotfiles/Kvantum;
  ".config/ags".source = dotfiles/ags;
  ".config/cava".source = dotfiles/cava;
  ".config/qt5ct".source = dotfiles/qt5ct;
  ".config/qt6ct".source = dotfiles/qt6ct;
  ".config/rofi".source = dotfiles/rofi;
  ".config/wallust".source = dotfiles/wallust;
  ".config/wlogout".source = dotfiles/wlogout;
  "Pictures/wallpapers".source = dotfiles/wallpapers;
};
macosFiles = {};
platformFiles = if pkgs.stdenv.isLinux then linuxFiles else macosFiles;
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  # TODO: Change these values to match your username and home directory.
  home.username = "inm";
  home.homeDirectory = if pkgs.stdenv.isLinux then "/home/inm" else "/Users/inm";

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
    du-dust
    ripgrep
    lsd
    bottom
    tmux
    tree-sitter
    lazygit
    gdu
    rm-improved
    just
    rustup
    ruff
    yt-dlp
    hyperfine
    gh
    onefetch
    fastfetch
    tealdeer
    fd
    skim
    parallel
    bacon
    uv
    serie
    bottom
    gitui
    nerd-fonts.jetbrains-mono
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = commonFiles // platformFiles;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  
  # ZSH
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd= true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
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
    delta.enable = true;
    extraConfig.credential.helper = "store";
    aliases = {
      lg = "lg1";
      lg1 = "lg1-specific --all";
      lg2 = "lg2-specific --all";
      lg3 = "lg3-specific --all";
      lg1-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'";
      lg2-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
      lg3-specific = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset) %C(bold cyan)(committed: %cD)%C(reset) %C(auto)%d%C(reset)%n''          %C(white)%s%C(reset)%n''          %C(dim white)- %an <%ae> %C(reset) %C(dim white)(committer: %cn <%ce>)%C(reset)'";
    };
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
  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
    };
  };
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      ctrl_n_shortcuts = true;
      enter_accept = false;
      keymap_mode = "vim-normal";
    };
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
}
