# Platform detection
case "$(uname -s)" in
    Darwin) _IS_MACOS=1 ;;
    Linux)  _IS_LINUX=1 ;;
esac

# Homebrew (macOS) - must come before completions
if [[ -n "$_IS_MACOS" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)"
    if type brew &>/dev/null; then
        fpath+=($(brew --prefix)/share/zsh/site-functions)
    fi
fi

# Completions & options
autoload -U compinit && compinit
setopt autocd

# Environment
export EDITOR=nvim

# Zsh plugins (platform-specific paths)
if [[ -n "$_IS_LINUX" ]]; then
    _ZSH_AUTOSUGGEST="/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    _ZSH_SYNTAX_HL="/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -n "$_IS_MACOS" ]]; then
    _ZSH_AUTOSUGGEST="$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    _ZSH_SYNTAX_HL="$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
[[ -f "$_ZSH_AUTOSUGGEST" ]] && source "$_ZSH_AUTOSUGGEST"

# Shell integrations
command -v zoxide  >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v direnv  >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# Source user config files
_DOTFILES_ZSH="$HOME/dotfiles/config/zsh"
for f in envars.sh aliases.sh funcs.sh zsh-private.sh fzf-zsh-completion.sh; do
    [[ -f "$_DOTFILES_ZSH/$f" ]] && source "$_DOTFILES_ZSH/$f"
done

# Atuin (after other config, before syntax highlighting)
command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh)"

# FZF completion binding
bindkey '^I' fzf_completion

# Syntax highlighting (MUST be last)
[[ -f "$_ZSH_SYNTAX_HL" ]] && source "$_ZSH_SYNTAX_HL"

# Startup
proxy_on
fastfetch

unset _IS_MACOS _IS_LINUX _ZSH_AUTOSUGGEST _ZSH_SYNTAX_HL _DOTFILES_ZSH
