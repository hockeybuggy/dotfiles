#!/bin/sh

DIR="$HOME/.dotfiles"

echo "\nGrabing Vundle\n"

git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

echo "\nInstalling Bundles\n"

vim +BundleInstall +qall

echo "\nLinking dotfiles...\n"

# Shells
ln -sb $DIR/bashrc $HOME/.bashrc
ln -sb $DIR/bash_profile $HOME/.bash_profile
ln -sb $DIR/zshrc $HOME/.zshrc
ln -sb $DIR/zlogin $HOME/.zlogin
ln -sb $DIR/zsh $HOME/.zsh

# Vim
ln -sb $DIR/vimrc $HOME/.vimrc
ln -sb $DIR/gvimrc $HOME/.gvimrc
ln -sb $DIR/vim $HOME/.vim

# Git
ln -sb $DIR/gitconfig $HOME/.gitconfig

# Terminals
ln -sb $DIR/dircolors.256dark $HOME/.dircolors.256dark
ln -sb $DIR/Xdefaults $HOME/.Xdefaults
ln -sb $DIR/Xresources $HOME/.Xresources
ln -sb $DIR/tmux.conf $HOME/.tmux.conf

mkdir -p $HOME/.terminfo/r
ln -sb $DIR/terminfo/rxvt-unicode-256color $HOME/.terminfo/r/rxvt-unicode-256color

# i3
ln -sb $DIR/i3 $HOME/.i3

echo "Done"
