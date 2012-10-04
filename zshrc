
#FILE: .zshrc
#AUTHOR: Douglas Anderson
#DATE: 12/10/03

ZSH=$HOME/.zsh

#------------------------------
# Alias
#------------------------------
alias -r ls="ls --color=always -lh"
alias -r la="ls --color=always -lhA"
alias -r ll="ls --color=always -lh"
alias -r lla="ls --color=no -lhA | less"
alias -r cbrow="chromium-browser"
alias -r fbrow="firefox"


eval `dircolors $HOME/.dotfiles/dircolors.256dark` 
autoload -U colors && colors
autoload -U compinit promptinit
compinit
promptinit

setopt correct

#------------------------------
# Prompt
#------------------------------
setprompt () {
    # load some modules
    autoload -U colors zsh/terminfo # Used in the colour alias below
    colors
    setopt prompt_subst

    # make some aliases for the colours: (coud use normal escap.seq's too)
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
        eval PR_$color='%{$fg[${(L)color}]%}'
    done
    PR_NO_COLOR="%{$terminfo[sgr0]%}"

    # Check the UID
    if [[ $UID -ge 1000 ]]; then # normal user
        eval PR_USER='${PR_GREEN}%n${PR_NO_COLOR}'
        eval PR_USER_OP='${PR_RED}\ ➤${PR_NO_COLOR}'
    elif [[ $UID -eq 0 ]]; then # root
        eval PR_USER='${PR_RED}%n${PR_NO_COLOR}'
        eval PR_USER_OP='${PR_RED}\ ➤➤${PR_NO_COLOR}'
    elif [[ $UID -eq 0 ]]; then # root
        eval PR_USER='${PR_RED}%n${PR_NO_COLOR}'
        eval PR_USER_OP='${PR_RED}\ ➤➤${PR_NO_COLOR}'
    fi

    # Check if we are on SSH or not
    if [[ -n "$SSH_CLIENT" || -n "$SSH2_CLIENT" ]]; then
        eval PR_HOST='${PR_YELLOW}%M${PR_NO_COLOR}' #SSH
    else
        eval PR_HOST='${PR_GREEN}%M${PR_NO_COLOR}' # no SSH
    fi


    # set the prompt
    PS1=$'${PR_CYAN}[${PR_USER}${PR_CYAN}@${PR_HOST}${PR_CYAN}]\ %~${PR_USER_OP} '
   # PS1=$'${PR_CYAN}[${PR_USER}${PR_CYAN}@${PR_HOST}${PR_CYAN}][${PR_BLUE}%~${PR_CYAN}]${PR_USER_OP} '
    PS2=$'%_>'
}
setprompt


