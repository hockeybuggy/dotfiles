## My dotfiles

This repository is for managing my configuration.

The dotlinker requires python and the submodules requires git for submodules.

### Clone this repo

Currently there are some dependances to the location of this directory.
".dotfiles" is preferred.

    git clone git@github.com:hockeybuggy/dotfiles .dotfiles && cd .dotfiles

### Update submodules

    git submodule init
    git submodule update

### Run the Linker

To run the linker in automatic mode run:

    ./dotlinker.py -a

To run the linker in interactive mode run:

    ./dotlinker.py -i

It will ask you some questions and you should answer them to set up your files.
The questions will be yes or no.

***

### No python?

What alien cruel machine have stumbled upon? This is an ok alternative after
cloneing:

    cd ~
    ln -s ~/.dotfiles/bashrc .bashrc
    ln -s ~/.dotfiles/vimrc .vimrc
    ln -s ~/.dotfiles/gvimrc .gvimrc
    ln -s ~/.dotfiles/vim .vim
    ln -s ~/.dotfiles/gitconfig .gitconfig

