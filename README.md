## My dotfiles

This repository is for managing my configuration.

The dotlinker requires python and the submodules requires git for submodules.

### Clone this repo

Currently there are some dependances to the location of this directory.
".dotfiles" is preferred.

    git clone git@github.com:hockeybuggy/dotfiles .dotfiles

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
