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
    export http_proxy=http://127.0.0.1:7890
    export https_proxy=$http_proxy
    export all_proxy=socks5://127.0.0.1:7891
    echo -e "Set http(s)_proxy=http://127.0.0.1:7890."
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
