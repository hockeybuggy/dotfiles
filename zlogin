# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Load virtual env wrapper functions
if [[ -s "/usr/share/virtualenvwrapper/virtualenvwrapper.sh" ]] then
    source "/usr/share/virtualenvwrapper/virtualenvwrapper.sh"
fi
export WORKON_HOME="$HOME/devel/envs"

# Set up terminal and editor
export EDITOR='vim'
export TERMINAL="urxvt"
export GREP_OPTIONS="--color=auto"
export XDG_CONFIG_HOME="~/.config"

if [ -s "/usr/bin/setxkbmap" ]; then
    # Turn off the stupid caps lock key
    /usr/bin/setxkbmap -option 'ctrl:nocaps'
fi

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.cargo/bin
export EXERCISM_CONFIG_FILE=$XDG_CONFIG_HOME/exercism
