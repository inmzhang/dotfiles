# Shell configuration
alias zshrc='nvim ~/.zshrc'
alias sc='source ~/.zshrc'

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
alias notes='nvim ~/neorg/main/'
alias journal="nvim -c 'Neorg journal today'"

# Git
alias gi='git init'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
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
