# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# oh-my-zsh theme
ZSH_THEME="agnoster"

plugins=(
	git
	zsh-syntax-highlighting
	zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

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

# starship
eval $(starship init zsh)

# autojump
eval "$(zoxide init zsh)"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# pyenv
eval "$(pyenv init -)"

# copilot cli
eval "$(github-copilot-cli alias -- "$0")"

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
path=('$HOME/.juliaup/bin' $path)
export PATH

source ~/.zshrc_system

