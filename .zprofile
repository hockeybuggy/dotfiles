export PATH="$PATH:$HOME/.docker/bin"

eval "$(/opt/homebrew/bin/brew shellenv)"

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
