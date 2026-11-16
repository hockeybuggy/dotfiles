export PATH="$PATH:$HOME/.docker/bin"

# Load RVM into a shell session *as a function*
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

export EDITOR="nvim"
export XDG_CONFIG_HOME="$HOME/.config"

# Load bashrc
[[ -r ~/.bashrc ]] && . ~/.bashrc

export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.cargo/bin
export PATH=$PATH:$HOME/.yarn/bin
export PATH=$PATH:$HOME/.local/bin

export PATH=$PATH:~/Library/Android/sdk/tools
export PATH=$PATH:~/Library/Android/sdk/platform-tools

export EXERCISM_CONFIG_FILE=$XDG_CONFIG_HOME/exercism
export GOPATH=$HOME/go


# Added by Antigravity CLI installer
export PATH="/Users/douglas/.local/bin:$PATH"
