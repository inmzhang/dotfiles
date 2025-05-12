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
    if command -v clash-verge >/dev/null 2>&1; then
        export http_proxy=http://127.0.0.1:7897
        export https_proxy=$http_proxy
        export all_proxy=socks5://127.0.0.1:7897
        echo -e "Set http(s)_proxy=http://127.0.0.1:7897."
    else
        export http_proxy=http://127.0.0.1:7890
        export https_proxy=$http_proxy
        export all_proxy=socks5://127.0.0.1:7891
        echo -e "Set http(s)_proxy=http://127.0.0.1:7890."
    fi
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

# Attach tmux session at some directory and activate venv if possible 
tp () {
    local query="$1"                             # what the user typed
    local session="${2:-$(basename "$query")}"   # default tmux name

    if [[ -z "$query" ]]; then
        echo "Usage: tp <dir|zoxide query> [session_name]" >&2
        return 1
    fi

    # Step 1 – let zoxide translate the query to a real path (fallback: literal path)
    local dir
    if command -v zoxide >/dev/null 2>&1; then
        dir="$(zoxide query "$query" 2>/dev/null || echo "$query")"
    else
        dir="$query"
    fi

    if [[ ! -d "$dir" ]]; then
        echo "tp: directory '$dir' not found" >&2
        return 1
    fi

    # Step 2 – reattach if the tmux session already exists
    if tmux has-session -t "$session" 2>/dev/null; then
        tmux attach -t "$session"
        return
    fi

    # Step 3 – start a detached session rooted in the resolved directory
    tmux new-session -d -s "$session" -c "$dir"

    # Step 4 – activate .venv when present
    if [[ -f "$dir/.venv/bin/activate" ]]; then
        tmux send-keys -t "$session" "source \"$dir/.venv/bin/activate\"" C-m
    fi

    # Step 5 – give a clean prompt
    tmux send-keys -t "$session" "clear" C-m
    tmux attach -t "$session"
}

n() {
    cd ~/Documents/note-taking
}
