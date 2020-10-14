# The zshrc of Douglas James Anderson
# vim:fdm=marker fdl=1

# Use 'emacs' bindings
bindkey -e

# Set up terminal and editor
export SHELL="/bin/zsh"
export EDITOR="nvim"
export TERMINAL="urxvt"

export PATH="$HOME/.bin:$PATH"
# Add some package managers to the path
export PATH="/usr/local/bin:$PATH"
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/.yarn/bin
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go

# fnm https://github.com/Schniz/fnm
eval "$(fnm env --multi)"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# Set up other config vars
export WORKON_HOME="$HOME/devel/envs"
export GREP_OPTIONS="--color=auto"
export XDG_CONFIG_HOME="$HOME/.config"
export EXERCISM_CONFIG_FILE=$XDG_CONFIG_HOME/exercism
export RUST_SRC_PATH=$HOME/programs/rust/src


#------------------------------
# Aliases
#------------------------------
[[ -f ~/.aliases ]] && source ~/.aliases

# Zsh only piping aliases
alias -g L="| less"
alias -g DN="> /dev/null"

bindkey -s "^T" "^[Isudo ^[A" # "T" for "toughguy". credit -> thoughtbot

#------------------------------
# Settings
#------------------------------

# Style
autoload -U colors && colors
autoload -U compinit promptinit
compinit
promptinit
setopt correct

# History
HISTFILE=~/.zsh_history
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

### Added by RVM
PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

# Setting fd as the default source for fzf
export FZF_DEFAULT_COMMAND='fd --type f'

#------------------------------
# Prompt
#------------------------------

eval "$(starship init zsh)"

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

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /Users/danderson/work/home-showing-calendar/showing/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/danderson/work/home-showing-calendar/showing/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /Users/danderson/work/home-showing-calendar/showing/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/danderson/work/home-showing-calendar/showing/node_modules/tabtab/.completions/sls.zsh
