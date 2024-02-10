# Zap managed plugins
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-syntax-highlighting"
plug "zsh-users/zsh-history-substring-search"

# alias
alias v='nvim .'
alias vi='nvim'
alias vim='nvim'
alias zshrc='nvim ~/.zshrc'
alias sc='source ~/.zshrc'
alias ls='lsd'
alias l='lsd -l'
alias ll='lsd -latrh'
alias cat='bat'
alias cl='clear'
alias t='tmux'
alias du='dust'
alias s='kitten ssh'
alias notes='nvim ~/neorg/main/'
alias journal="nvim -c 'Neorg journal today'"
# git alias
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

# autojump
eval "$(zoxide init zsh)"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# copilot cli
# eval "$(github-copilot-cli alias -- "$0")"

# alias venv activate
alias cvenv='python -m venv .venv'
alias avenv='source .venv/bin/activate'

# provides the ability to change the current working directory when exiting Yazi
function ya() {
    tmp="$(mktemp -t "yazi-cwd.XXXXX")"
    yazi --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

export EDITOR="nvim"
 
# Julia mirror
export JULIA_PKG_SERVER=https://mirrors.ustc.edu.cn/julia

# juliaup
export PATH="$HOME/.juliaup/bin:$PATH"

source ~/.zshrc_system

eval "$(atuin init zsh)"

eval "$(starship init zsh)"
