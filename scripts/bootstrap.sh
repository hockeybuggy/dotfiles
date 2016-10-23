#!/bin/sh

DIR="$HOME/.dotfiles"

if [ ! -d "$HOME/.vim/bundle/vundle" ]; then
    echo "\nGrabing Vundle\n"
    mkdir -p $DIR/vim/bundle
    git clone https://github.com/gmarik/Vundle.git $DIR/vim/bundle/Vundle.vim
fi

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
ln -s $DIR/zsh $HOME/.zsh

# Vim
ln -sf $DIR/vimrc $HOME/.vimrc
ln -sf $DIR/gvimrc $HOME/.gvimrc
if [ -d "$HOME/.vim" ]; then
    mv $HOME/.vim $HOME/.vim.bak
fi
ln -s $DIR/vim $HOME/.vim

# Neovim
ln -sf $DIR/vimrc $XDG_CONFIG_HOME/nvim/init.vim

# Git
ln -sf $DIR/gitconfig $HOME/.gitconfig

# Terminals
ln -sf $DIR/dircolors.256dark $HOME/.dircolors.256dark
ln -sf $DIR/Xdefaults $HOME/.Xdefaults
ln -sf $DIR/Xresources $HOME/.Xresources
ln -sf $DIR/tmux.conf $HOME/.tmux.conf

mkdir -p $HOME/.terminfo/r
ln -sf $DIR/terminfo/rxvt-unicode-256color $HOME/.terminfo/r/rxvt-unicode-256color

ln -s $DIR/bin $HOME/.bin

echo "Done"
