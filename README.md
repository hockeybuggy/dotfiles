## My dotfiles

This repository is for managing my configuration.

### 1.Clone this repo

Currently there are some dependences to the location of this directory.
".dotfiles" is preferred. For example the bootstrap.sh wont work.

    git clone https://github.com/hockeybuggy/dotfiles.git .dotfiles && cd .dotfiles

### 2. Automagically Link the files

    ./scripts/bootstrap.sh

### 2-alt. Manually link some files

For some more minimal systems run these:

    git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
    vim +BundleInstall +qall

    cd ~
    ln -s ~/.dotfiles/bash_profile .bash_profile
    ln -s ~/.dotfiles/bashrc .bashrc
    ln -s ~/.dotfiles/vimrc .vimrc
    ln -s ~/.dotfiles/gvimrc .gvimrc
    ln -s ~/.dotfiles/vim .vim
    ln -s ~/.dotfiles/gitconfig .gitconfig


