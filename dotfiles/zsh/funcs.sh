# provides the ability to change the current working directory when exiting Yazi
function ya() {
    tmp="$(mktemp -t "yazi-cwd.XXXXX")"
    yazi --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# clash-verge defaults port to 7897
function proxy_on() {
    export http_proxy=http://127.0.0.1:7897
    export https_proxy=$http_proxy
    export all_proxy=socks5://127.0.0.1:7897
    echo -e "Set http(s)_proxy=http://127.0.0.1:7897."
}

function proxy_off(){
    unset http_proxy https_proxy all_proxy
    echo -e "Terminal proxy is off."
}

# open the current directory with nvim
# if there is virtual environment, activate it
function vv() {
  if [ -d "venv" ] || [ -d ".venv" ]; then
    source "$( [ -d "venv" ] && echo "venv" || echo ".venv" )/bin/activate"
  fi
  nvim .
}

# Search paper in Zotero database and open it in firefox
function fdp() {
    ZOTERO_DB="$HOME/Zotero/storage"
    # Check if Zotero is installed
    if ! command -v zotero &> /dev/null
    then
        echo "Zotero could not be found. Please install it or ensure it's in your PATH."
        return
    fi
    # Select paper interactively with sk
    selected_paper=$(fd -e pdf . "$ZOTERO_DB" --exec basename | sk)

    # Check if a paper was selected
    if [ -z "$selected_paper" ]; then
        return
    fi

    # Extract the full path to the selected paper using fd again
    selected_path=$(fd -e pdf "$selected_paper" "$ZOTERO_DB")

    # Open the selected paper in firefox
    firefox "$selected_path"
}
