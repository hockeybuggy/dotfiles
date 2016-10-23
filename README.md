# My dotfiles

[![Build Status](https://travis-ci.org/hockeybuggy/dotfiles.svg)](https://travis-ci.org/hockeybuggy/dotfiles)

This repository is for managing my configuration files.


## Installation

### 1.Clone this repo

Clone dah repo. I like to clone put it at `~/.dotlinker`

    git clone git@github.com:hockeybuggy/dotfiles.git .dotfiles && cd .dotfiles

### 2. Automagically Link the files

    ./scripts/bootstrap.sh

### 3. May need to install the vim deps via Vundle

    ./scripts/vundle.sh


## Dependencies

#### Minimum:

1. vim  - 7.4
2. bash - (whatever is installed)
3. git  - 2.*
4. python - 2.7 and 3.5

#### Ideal:

1. tmux - 1.9
2. zsh  - 5.0
3. urxvt or iter2
4. ripgrep
5. silver searcher
6. inconsolata font
