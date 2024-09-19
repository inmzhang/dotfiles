# Home manager path
hm_path="$HOME/.config/home-manager"

alias python='python3'

# sudo with environment variables preserved
alias sue='sudo -E'

# Shell configuration
alias zshrc='nvim ~/.zshrc'
alias sc='source ~/.zshrc'
alias aa="nvim $hm_path/dotfiles/zsh/aliases.sh"
alias hm="cd $hm_path; nvim ."
alias hms='home-manager switch'
alias hmu="cd $hm_path;nix-channel --update;nix flake update;home-manager switch"

# Neovim
alias v='nvim .'
alias vi='nvim'
alias vim='nvim'

# System tools
alias ls='lsd'
alias l='lsd -l'
alias ll='lsd -latrh'
alias cat='bat'
alias t='tmux'
alias du='dust'

# Others
alias cl='clear'
alias s='kitten ssh'
alias cvenv='python -m venv .venv'
alias avenv='source .venv/bin/activate'
alias ~='cd ~'
# neorg
alias notes='cd ~/neorg; nvim ~/neorg/main/'
alias journal="cd ~/neorg; nvim -c 'Neorg journal today'"

# Git
alias gi='git init'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gcam='git commit -am'
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbm='git branch -m'
alias gcl='git clone'
alias gp='git pull'
alias gP='git push'
alias gra='git remote add'
alias grv='git remote -v'
alias grr='git remote remove'

# Open Zotero storage directory with yazi
alias yz='yazi ~/Zotero/storage'

# Kitty SSH
alias ssharch='kitty +kitten ssh -p 6000 inm@47.115.200.184'
alias sshcpu='kitty +kitten ssh -p 6001 inm@47.115.200.184'
alias sshgpu='kitty +kitten ssh -p 6002 inm@47.115.200.184'
