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
