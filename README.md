# My dotfiles

[![Build Status](https://travis-ci.org/hockeybuggy/dotfiles.svg)](https://travis-ci.org/hockeybuggy/dotfiles)

This repository is for managing my configuration files.

## Installation

### 1.Clone this repo

Clone the repo. I like to clone put it at `~/.dotfiles`

    git clone git@github.com:hockeybuggy/dotfiles.git .dotfiles && cd .dotfiles

### 2. Automagically Link the files

    ./bootstrap.sh

### 3. May need to install the vim dependencies via [vim-plug](https://github.com/junegunn/vim-plug)

    [within vim]
    :PlugInstall

## Dependencies

### Minimum

1. vim  - 7.4
1. bash - (whatever is installed)
1. git  - 2.24.1+
1. python - 3.6+

### Ideal

1. vim - 8.0
1. neovim
1. tmux - 2.3
1. zsh  - 5.0
1. iterm2
1. node
1. Inconsolata font (nerdfont variant)
1. rustup, cargo, rustc
1. [ripgrep](https://github.com/BurntSushi/ripgrep) -- Grep replacement
1. [fd](https://github.com/sharkdp/fd) -- `find` replacement
1. [fzf](https://github.com/junegunn/fzf) -- Fuzzy finder
1. [bat](https://github.com/sharkdp/bat) -- `cat` replacement
1. [eza](https://eza.rocks/) -- `ls` replacement
1. [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli)
1. hub (command line github)
1. diff-so-fancy
1. reattach-to-user-namespace
1. starship
1. gnupg
1. fnm
1. zoxide
1. gpg-agent
1. uutils-coreutils
