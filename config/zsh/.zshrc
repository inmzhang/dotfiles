# If not running interactively, don't do anything.
[[ $- != *i* ]] && return

_DOTFILES_ZSH="$HOME/dotfiles/config/zsh"
_OMARCHY_ZSH_ROOT="/usr/share/omarchy-zsh/shell"

if [[ -r "$_OMARCHY_ZSH_ROOT/all" ]]; then
    # Omarchy's packaged Zsh layer stays updateable under /usr/share. Remove
    # personal aliases that collide with packaged functions before re-sourcing.
    unalias ga gd 2>/dev/null
    source "$_OMARCHY_ZSH_ROOT/zoptions"
    source "$_OMARCHY_ZSH_ROOT/all"
else
    # Portable fallback for macOS and non-Omarchy systems.
    if [[ "$(uname -s)" == Darwin ]] && [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        fpath+=("$(brew --prefix)/share/zsh/site-functions")
        _ZSH_AUTOSUGGEST="$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        _ZSH_SYNTAX_HL="$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    else
        _ZSH_AUTOSUGGEST="/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
        _ZSH_SYNTAX_HL="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi

    autoload -Uz compinit && compinit
    setopt AUTO_CD
    [[ -r "$_ZSH_AUTOSUGGEST" ]] && source "$_ZSH_AUTOSUGGEST"
    command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
    command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
    command -v fzf >/dev/null 2>&1 && [[ -r "$_DOTFILES_ZSH/fzf-zsh-completion.sh" ]] && source "$_DOTFILES_ZSH/fzf-zsh-completion.sh"
fi

export EDITOR=nvim

# Personal overrides load after Omarchy so they always win.
for f in envars.sh aliases.sh funcs.sh zsh-private.sh; do
    [[ -r "$_DOTFILES_ZSH/$f" ]] && source "$_DOTFILES_ZSH/$f"
done

command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh)"
bindkey -v

# The portable fallback has not loaded syntax highlighting yet.
[[ ! -r "$_OMARCHY_ZSH_ROOT/all" ]] && [[ -r "${_ZSH_SYNTAX_HL:-}" ]] && source "$_ZSH_SYNTAX_HL"

proxy_on
command -v fastfetch >/dev/null 2>&1 && fastfetch

unset _DOTFILES_ZSH _OMARCHY_ZSH_ROOT _ZSH_AUTOSUGGEST _ZSH_SYNTAX_HL

. "$HOME/.local/share/../bin/env"
