# Source the configuration files
my_shdir=$(dirname "$0")
my_configs=(
    envars.sh
    aliases.sh   
    funcs.sh
)

# Source all the Zsh-specific and sh-generic files.
for f in $my_configs; do
    [[ -f $my_shdir/$f ]] && . $my_shdir/$f
done

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi

if [ -f "$HOME/.rye/env" ]; then
  source "$HOME/.rye/env"
fi

proxy_on

fastfetch
