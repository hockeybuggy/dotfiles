# Load virtual env wrapper functions
if [[ -s "/usr/share/virtualenvwrapper/virtualenvwrapper.sh" ]] then
    source "/usr/share/virtualenvwrapper/virtualenvwrapper.sh"
fi

if [ -s "/usr/bin/setxkbmap" ]; then
    # Turn off the stupid caps lock key
    /usr/bin/setxkbmap -option 'ctrl:nocaps'
fi

### Start up a gpg-agent to avoid typing it repeatedly.
export GPG_TTY=`tty`
eval $(gpg-agent --daemon)

# Load hub
eval "$(hub alias -s)"
