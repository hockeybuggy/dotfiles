# The zshrc of Douglas James Anderson
# vim:fdm=marker fdl=1

ZSHDIR=$HOME/.zsh
DOTDIR=$HOME/.dotfiles
SCRIPTDIR=$DOTDIR/scripts
ZDIR=$SCRIPTDIR/z

#------------------------------
# Aliases
#------------------------------
# Common shorthands
alias -r l="less"
alias -r g="git"
alias -r z="z" # Just written so I remember. Performance hit?

mkcd() {
    mkdir -p "$*"
    cd "$*"
}

# Fork Terminals. It's TODO pretty bad..
alias -r rxvt="nohup urxvt &"
alias -r urxvt="nohup urxvt &"

# LS aliases
alias -r ls="ls --color=always -lh"
alias -r la="ls --color=always -lhA"
alias -r ll="ls --color=always -lh"
alias -r lla="ls --color=no -lhA | less"

# Vim
alias -r vimtoc='vim `cat .toc.txt`'
alias -r gvimtoc='gvim `cat .toc.txt`'

# Assorted
alias -r clr="clear"
alias -r clip="xclip -i -selection clipboard"
alias -r server="python -m SimpleHTTPServer"

#------------------------------
# Settings
#------------------------------
eval `dircolors $DOTDIR/dircolors.256dark` 

source $ZSHDIR/git-prompt/zshrc.sh
autoload -U colors && colors
autoload -U compinit promptinit
compinit
promptinit
setopt correct

HISTFILE=$ZSHDIR/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups # ignore duplication command history list
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history # share command history data

#------------------------------
# Scripts
#------------------------------
# z : a file jumper based on Frecency 
export _Z_DATA="$ZDIR/.z"
source $ZDIR/z.sh

#------------------------------
# Prompt 
#------------------------------
RPROMPT=""

setprompt () {
    # load some modules
    autoload -U colors zsh/terminfo # Used in the colour alias below
    colors
    setopt prompt_subst

    # make some aliases for the colours: (could use normal escape sequence's too)
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
        eval PR_$color='%{$fg[${(L)color}]%}'
    done
    PR_NO_COLOR="%{$terminfo[sgr0]%}"

    # Check the UID
    if [[ $UID -ge 1000 ]]; then # normal user
        eval PR_USER='${PR_GREEN}%n${PR_NO_COLOR}'
        eval PR_USER_OP='${PR_RED}➤${PR_NO_COLOR}'
    elif [[ $UID -eq 0 ]]; then # root
        eval PR_USER='${PR_RED}%n${PR_NO_COLOR}'
        eval PR_USER_OP='${PR_RED}➤➤${PR_NO_COLOR}'
    fi

    # Check if we are on SSH or not
    if [[ -n "$SSH_CLIENT" || -n "$SSH2_CLIENT" ]]; then
        eval PR_HOST='${PR_YELLOW}%M${PR_NO_COLOR}' #SSH
    else
        eval PR_HOST='${PR_GREEN}%M${PR_NO_COLOR}' # no SSH
    fi

    # set the prompt
    PS1=$'${PR_CYAN}[${PR_USER}${PR_CYAN}@${PR_HOST}${PR_CYAN}]\ $(git_super_status) %~  \n${PR_USER_OP} '
    PS2=$'%_>'
}
setprompt

# Get Special keys working {{{2

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

# setup key accordingly
[[ -n "${key[Home]}"    ]]  && bindkey  "${key[Home]}"    beginning-of-line
[[ -n "${key[End]}"     ]]  && bindkey  "${key[End]}"     end-of-line
[[ -n "${key[Insert]}"  ]]  && bindkey  "${key[Insert]}"  overwrite-mode
[[ -n "${key[Delete]}"  ]]  && bindkey  "${key[Delete]}"  delete-char
[[ -n "${key[Up]}"      ]]  && bindkey  "${key[Up]}"      up-line-or-history
[[ -n "${key[Down]}"    ]]  && bindkey  "${key[Down]}"    down-line-or-history
[[ -n "${key[Left]}"    ]]  && bindkey  "${key[Left]}"    backward-char
[[ -n "${key[Right]}"   ]]  && bindkey  "${key[Right]}"   forward-char

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
function zle-line-init () {
    echoti smkx
}
function zle-line-finish () {
    echoti rmkx
}

zle -N zle-line-init
zle -N zle-line-finish

