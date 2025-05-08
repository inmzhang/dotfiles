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

# Search paper in Zotero database and open it in firefox
function fdp() {
    ZOTERO_DB="$HOME/Zotero/storage"
    # Select paper interactively with sk
    selected_paper=$(fd -e pdf . "$ZOTERO_DB" --exec basename | sk)

    # Check if a paper was selected
    if [ -z "$selected_paper" ]; then
        return
    fi

    # Extract the full path to the selected paper using fd again
    selected_path=$(fd -e pdf "$selected_paper" "$ZOTERO_DB")
    # Extract and print the paper name (basename without .pdf extension)
    paper_name=$(basename "$selected_path")
    echo "* filepath: $selected_path"

    # Extract the directory name (unique item ID)
    item_id=$(basename $(dirname "$selected_path"))
    # Create Zotero open link
    zotero_link="zotero://open-pdf/library/items/$item_id"
    zotero_entry="{$zotero_link}[$paper_name]"
    echo "* zotero link: $zotero_entry"

    # Detect OS and copy to clipboard
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -n "$zotero_entry" | xclip -selection clipboard
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -n "$zotero_entry" | pbcopy
    else
        echo "Unsupported OS: $OSTYPE"
    fi

    # Open the selected paper in firefox
    firefox "$selected_path"
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
