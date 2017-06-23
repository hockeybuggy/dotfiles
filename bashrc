# The bashrc of Douglas James Anderson

DOTDIR=$HOME/.dotfiles
SCRIPTDIR=$DOTDIR/scripts
ZDIR=$SCRIPTDIR/z

export PATH="$HOME/.bin:$PATH"


#------------------------------
# Aliases
#------------------------------
[[ -f $DOTDIR/aliases ]] && source $DOTDIR/aliases


#------------------------------
# Settings
#------------------------------
# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignoredups
# ... and ignore same successive entries.
export HISTCONTROL=ignoreboth
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(lesspipe)"
color_prompt=yes

# enable programmable completion features
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

#------------------------------
# Program specific
#------------------------------
# z : a file jumper based on Frecency
export _Z_DATA="$ZDIR/.z"
source $ZDIR/z.sh

## Added by the Heroku Toolbelt
PATH="$PATH:/usr/local/heroku/bin"

## Added by RVM
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
#------------------------------
# Prompt
#------------------------------
case "$TERM" in
    xterm-color|rxvt-unicode-256color|screen-256color)
        PS1='[\[\033[01;32m\]\u@\h\[\033[00m\]] \[\033[01;34m\]\w\[\033[00m\]\]\033[01;31m\]\]\n➤\033[00m\]\] '
        ;;
    *)
        PS1='[\u@\h:\w] > '
        ;;
esac

case "$TERM" in
    xterm*|rxvt*)
        PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'
        ;;
    *)
        ;;
esac

# added by travis gem
[ -f /Users/dev1/.travis/travis.sh ] && source /Users/dev1/.travis/travis.sh
