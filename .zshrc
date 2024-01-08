# Zap managed plugins
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-syntax-highlighting"
plug "zsh-users/zsh-history-substring-search"

# Load and initialise completion system
autoload -Uz compinit
compinit

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# oh-my-zsh theme
ZSH_THEME="agnoster"

source $ZSH/oh-my-zsh.sh

plugins=( git )

# alias
alias v='nvim .'
alias vi='nvim'
alias vim='nvim'
alias zshrc='nvim ~/.zshrc'
alias sc='source ~/.zshrc'
alias ls='lsd'
alias cat='bat'
alias cl='clear'
alias t='tmux'
alias du='dust'
alias s='kitten ssh'
alias notes='nvim ~/neorg'
alias journal="nvim -c 'Neorg journal today'"

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

# starship
eval $(starship init zsh)

