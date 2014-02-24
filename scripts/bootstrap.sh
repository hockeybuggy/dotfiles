#!/bin/sh

DIR="$HOME/.dotfiles"

echo "\nGrabing Vundle\n"

git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

echo "\nInstalling Bundles\n"

vim +BundleInstall +qall

echo "\nLinking dotfiles...\n"

# Shells
ln -s $DIR/bashrc $HOME/.bashrc
ln -s $DIR/bash_profile $HOME/.bash_profile
ln -s $DIR/zshrc $HOME/.zshrc
ln -s $DIR/zlogin $HOME/.zlogin
if [ -d "$HOME/.zsh" ]; then
    mv $HOME/.zsh $HOME/.zsh.bak
fi
ln -s $DIR/zsh $HOME/.zsh

# Vim
ln -s $DIR/vimrc $HOME/.vimrc
ln -s $DIR/gvimrc $HOME/.gvimrc
if [ -d "$HOME/.vim" ]; then
    mv $HOME/.vim $HOME/.vim.bak
fi
ln -s $DIR/vim $HOME/.vim

# Git
ln -s $DIR/gitconfig $HOME/.gitconfig

# Terminals
ln -s $DIR/dircolors.256dark $HOME/.dircolors.256dark
ln -s $DIR/Xdefaults $HOME/.Xdefaults
ln -s $DIR/Xresources $HOME/.Xresources
ln -s $DIR/tmux.conf $HOME/.tmux.conf

mkdir -p $HOME/.terminfo/r
ln -s $DIR/terminfo/rxvt-unicode-256color $HOME/.terminfo/r/rxvt-unicode-256color

# i3
if [ -d "$HOME/.i3" ]; then
    mv $HOME/.i3 $HOME/.i3.bak
fi
ln -s $DIR/i3 $HOME/.i3

echo "Done"
