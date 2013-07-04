## My dotfiles

This repository is for managing my configuration.

### 1.Clone this repo

Currently there are some dependences to the location of this directory.
".dotfiles" is preferred. For example the bootstrap.sh wont work.

    git clone git@github.com:hockeybuggy/dotfiles .dotfiles && cd .dotfiles

### 2. Automagically Link the files

    ./scripts/bootstrap.sh

### 2-alt. Manually link some files

    git submodule init
    git submodule update

    cd ~
    ln -s ~/.dotfiles/bashrc .bashrc
    ln -s ~/.dotfiles/vimrc .vimrc
    ln -s ~/.dotfiles/gvimrc .gvimrc
    ln -s ~/.dotfiles/vim .vim
    ln -s ~/.dotfiles/gitconfig .gitconfig

