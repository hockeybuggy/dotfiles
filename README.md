# My dotfiles

[![Build Status](https://travis-ci.org/hockeybuggy/dotfiles.svg)](https://travis-ci.org/hockeybuggy/dotfiles)

This repository is for managing my configuration files.


## Installation

### 1.Clone this repo

Clone dah repo. I like to clone put it at `~/.dotlinker`

    git clone git@github.com:hockeybuggy/dotfiles.git .dotfiles && cd .dotfiles

### 2. Automagically Link the files

    ./scripts/bootstrap.sh

### 3. May need to install the vim deps via [dein](https://github.com/Shougo/dein.vim)

    [within vim]
    :call dein#install()


## Dependencies

#### Minimum:

1. vim  - 7.4
1. bash - (whatever is installed)
1. git  - 2.*
1. python - 2.7 and 3.6

#### Ideal:

1. vim - 8.0
1. neovim
1. tmux - 2.3
1. zsh  - 5.0
1. iterm2 or urxvt
1. Inconsolata font (maybe patched with powerline font)
1. rustup, cargo, rustc
1. ripgrep
1. hub (command line github)
