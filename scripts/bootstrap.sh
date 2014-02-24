#!/bin/sh

DIR="$HOME/.dotfiles"

echo "\nGrabing Vundle\n"

git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle

echo "\nInstalling Bundles\n"

vim +BundleInstall +qall

echo "\nLinking dotfiles...\n"

# Shells
ln -sf $DIR/bashrc $HOME/.bashrc
ln -sf $DIR/bash_profile $HOME/.bash_profile
ln -sf $DIR/zshrc $HOME/.zshrc
ln -sf $DIR/zlogin $HOME/.zlogin
if [ -d "$HOME/.zsh" ]; then
    mv $HOME/.zsh $HOME/.zsh.bak
fi
ln -sf $DIR/zsh $HOME/.zsh

# Vim
ln -sf $DIR/vimrc $HOME/.vimrc
ln -sf $DIR/gvimrc $HOME/.gvimrc
if [ -d "$HOME/.vim" ]; then
    mv $HOME/.vim $HOME/.vim.bak
fi
ln -sf $DIR/vim $HOME/.vim

# Git
ln -sf $DIR/gitconfig $HOME/.gitconfig

# Terminals
ln -sf $DIR/dircolors.256dark $HOME/.dircolors.256dark
ln -sf $DIR/Xdefaults $HOME/.Xdefaults
ln -sf $DIR/Xresources $HOME/.Xresources
ln -sf $DIR/tmux.conf $HOME/.tmux.conf

mkdir -p $HOME/.terminfo/r
ln -sf $DIR/terminfo/rxvt-unicode-256color $HOME/.terminfo/r/rxvt-unicode-256color

# i3
if [ -d "$HOME/.i3" ]; then
    mv $HOME/.i3 $HOME/.i3.bak
fi
ln -sf $DIR/i3 $HOME/.i3

echo "Done"
