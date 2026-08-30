export http_proxy=http://127.0.0.1:7897
export https_proxy=$http_proxy
export all_proxy=socks5://127.0.0.1:7897

[[ -r "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
[[ -r "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
[[ -r "$HOME/.bashrc" ]] && . "$HOME/.bashrc"
