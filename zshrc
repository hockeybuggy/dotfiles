# The zshrc of Douglas James Anderson
# vim:fdm=marker fdl=1

# Use 'emacs' bindings
bindkey -e

ZSHDIR=$HOME/.zsh
DOTDIR=$HOME/.dotfiles
SCRIPTDIR=$DOTDIR/scripts
ZDIR=$SCRIPTDIR/z

# Set up terminal and editor
export SHELL="/bin/zsh"
export EDITOR="nvim"
export TERMINAL="urxvt"

export PATH="$HOME/.bin:$PATH"
# Add some package managers to the path
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/.yarn/bin
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

eval "$(nodenv init -)"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Set up other config vars
export WORKON_HOME="$HOME/devel/envs"
export GREP_OPTIONS="--color=auto"
export XDG_CONFIG_HOME="~/.config"
export EXERCISM_CONFIG_FILE=$XDG_CONFIG_HOME/exercism
export RUST_SRC_PATH=$HOME/programs/rust/src


#------------------------------
# Aliases
#------------------------------
[[ -f $DOTDIR/aliases ]] && source $DOTDIR/aliases

# Zsh only piping aliases
alias -g L="| less"
alias -g DN="> /dev/null"

bindkey -s "^T" "^[Isudo ^[A" # "T" for "toughguy". credit -> thoughtbot

#------------------------------
# Settings
#------------------------------

# Style
if [ "$(uname)" != "Darwin" ]; then
    eval `dircolors $DOTDIR/dircolors.256dark`
fi

source $ZSHDIR/git-prompt/zshrc.sh

autoload -U colors && colors
autoload -U compinit promptinit
compinit
promptinit
setopt correct

# History
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
# Program Specific
#------------------------------
# z : a file jumper based on Frecency
export _Z_DATA="$ZDIR/.z"
source $ZDIR/z.sh

### Added by RVM
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

# Setting fd as the default source for fzf
export FZF_DEFAULT_COMMAND='fd --type f'

#------------------------------
# Prompt
#------------------------------

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

    eval PR_USER='%(!.${PR_RED}.${PR_GREEN})%n${PR_NO_COLOR}'
    eval PR_USER_OP='${PR_RED}%(!.#.➤)${PR_NO_COLOR}'

    # Check if we are on SSH or not
    if [[ -n "$SSH_CLIENT" || -n "$SSH2_CLIENT" ]]; then
        eval PR_HOST='${PR_YELLOW}%M${PR_NO_COLOR}' #SSH
    else
        eval PR_HOST='${PR_GREEN}%M${PR_NO_COLOR}' # no SSH
    fi

    # set the prompt
    PS1=$'${PR_CYAN}[${PR_USER}${PR_CYAN}@${PR_HOST}${PR_CYAN}]${PR_NO_COLOR}\ $(git_super_status) ${PR_CYAN}%~${PR_NO_COLOR}  \n${PR_USER_OP} '
    PS2=$'%_>'

    RPROMPT="${PR_GREEN}%T${PR_NO_COLOR}"
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
[[ -n "${key[Up]}"      ]]  && bindkey  "${key[Up]}"      history-beginning-search-backward
[[ -n "${key[Down]}"    ]]  && bindkey  "${key[Down]}"    history-beginning-search-forward
[[ -n "${key[Left]}"    ]]  && bindkey  "${key[Left]}"    backward-char
[[ -n "${key[Right]}"   ]]  && bindkey  "${key[Right]}"   forward-char

bindkey "^E" end-of-line
bindkey "^A" beginning-of-line

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

# added by travis gem
[ -f $HOME/.travis/travis.sh ] && source $HOME/.travis/travis.sh

# wave autocomplete setup
WAVE_AC_ZSH_SETUP_PATH=/Users/danderson/Library/Caches/wave/autocomplete/zsh_setup && test -f $WAVE_AC_ZSH_SETUP_PATH && source $WAVE_AC_ZSH_SETUP_PATH;