# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Set up terminal and editor
export SHELL="/bin/zsh"
export EDITOR="nvim"
export TERMINAL="urxvt"
export GREP_OPTIONS="--color=auto"
export XDG_CONFIG_HOME="~/.config"

if [ -s "/usr/bin/setxkbmap" ]; then
    # Turn off the stupid caps lock key
    /usr/bin/setxkbmap -option 'ctrl:nocaps'
fi

# Load bashrc
[[ -r ~/.bashrc ]] && . ~/.bashrc

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/.yarn/bin

export EXERCISM_CONFIG_FILE=$XDG_CONFIG_HOME/exercism
export GOPATH=$HOME/go
