# Dotfiles path
dotfiles_path="$HOME/dotfiles"

command -v zen-browser >/dev/null 2>&1 && alias zen="zen-browser"

alias python='python3'

# sudo with environment variables preserved
alias sue='sudo -E'

# Shell configuration
alias zshrc='nvim ~/.zshrc'
alias sc='source ~/.zshrc'
alias aa="nvim $dotfiles_path/config/zsh/aliases.sh"
alias dot="cd $dotfiles_path && nvim ."
if command -v omarchy >/dev/null 2>&1; then
    alias dots="cd $dotfiles_path && make omarchy-link"
else
    alias dots="cd $dotfiles_path && make relink"
fi

# Neovim
alias v='nvim .'
alias vi='nvim'
alias vim='nvim'

# System tools
if command -v lsd >/dev/null 2>&1; then
    alias ls='lsd'
    alias l='lsd -l'
    alias ll='lsd -latrh'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat'
alias t='tmux'
command -v dust >/dev/null 2>&1 && alias du='dust'

# Others
alias cl='clear'
command -v kitten >/dev/null 2>&1 && alias s='kitten ssh'
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

# Claude Code: default to skipping permission prompts
alias claude='claude --dangerously-skip-permissions'

# Open Zotero storage directory with yazi
alias yz='yazi ~/Zotero/storage'

# note taking
alias n='cd ~/Documents/note-taking'
alias td='nvim ~/Documents/note-taking/todos/notes.md'
alias zn='nvim -c "Notes"'
alias zp='nvim -c "ZoteroPaper"'
