#!/bin/sh

DIR="~/.dotfiles"

echo "Linking dotfiles..."

# Shells
ln -sb $DIR/bashrc .bashrc
ln -sb $DIR/zshrc .zshrc
ln -sb $DIR/zsh .zsh

# Vim
ln -sb $DIR/vimrc .vimrc
ln -sb $DIR/gvimrc .gvimrc
ln -sb $DIR/vim .vim

# Git
ln -sb $DIR/gitconfig .gitconfig

# Terminals
ln -sb $DIR/dircolors.256dark .dircolors.256dark
ln -sb $DIR/Xdefaults .Xdefaults
ln -sb $DIR/Xreasources .Xreasources
ln -sb $DIR/tmux.conf .tmux.conf

# i3
ln -sb $DIR/i3 .i3

echo "Done"
