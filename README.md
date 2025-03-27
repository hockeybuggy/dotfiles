# My dotfiles

This repository is for managing my configuration files.

## Installation

### 1.Clone this repo

Clone the repo. I like to clone put it at `~/.dotfiles`

    git clone git@github.com:hockeybuggy/dotfiles.git .dotfiles && cd .dotfiles

### 2. Automagically Link the files

    ./bootstrap.sh

## Dependencies

1. Executables
    1. neovim - 11.0
    1. tmux - 3.5
    1. iterm2
1. command line utils
    1. zsh  - 5.0
    1. reattach-to-user-namespace
    1. Inconsolata font (nerdfont variant)
    1. starship
    1. zoxide
    1. uutils-coreutils
    1. [ripgrep](https://github.com/BurntSushi/ripgrep) -- Grep replacement
    1. [fd](https://github.com/sharkdp/fd) -- `find` replacement
    1. [fzf](https://github.com/junegunn/fzf) -- Fuzzy finder
    1. [bat](https://github.com/sharkdp/bat) -- `cat` replacement
    1. [eza](https://eza.rocks/) -- `ls` replacement
1. Language things
    1. rustup, cargo, rustc
    1. python
    1. node
    1. fnm
1. code formatters
    1. stylua
    1. black
1. [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli)
1. Git related
    1. gnupg
    1. gpg-agent
    1. diff-so-fancy
