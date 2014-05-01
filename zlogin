# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Set up terminal and editor
export EDITOR='vim'
export TERMINAL="urxvt"

# Turn off the stupid caps lock key
/usr/bin/setxkbmap -option 'ctrl:nocaps'
