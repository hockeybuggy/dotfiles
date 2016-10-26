# Set up terminal and editor
export EDITOR="vim"
export TERMINAL="urxvt"

# Set up some package managers
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/.yarn/bin
export PATH=$PATH:/usr/local/go/bin

export NVM_DIR="/Users/dev1/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Set up other things
export WORKON_HOME="$HOME/devel/envs"
export GREP_OPTIONS="--color=auto"
export XDG_CONFIG_HOME="~/.config"
export EXERCISM_CONFIG_FILE=$XDG_CONFIG_HOME/exercism
