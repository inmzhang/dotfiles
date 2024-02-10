# Source the configuration files
my_shdir="$HOME/.config/shell"
my_configs=(
    zap_plugins.sh
    envars.sh
    aliases.sh   
    vendors.sh
    funcs.sh
)

# Source all the Zsh-specific and sh-generic files.
for f in $my_configs; do
    [[ -f $my_shdir/$f ]] && . $my_shdir/$f
done
