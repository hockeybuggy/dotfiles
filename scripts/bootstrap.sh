#!/bin/sh

DIR="$HOME/.dotfiles"

echo "\nInstalling Vim Bundler Dein\n"
sh $DIR/scripts/dein-installer.sh $DIR/vim/bundles
vim "+call dein#install()"

echo "\nLinking dotfiles...\n"

# Shells
ln -sf $DIR/bashrc $HOME/.bashrc
ln -sf $DIR/bash_profile $HOME/.bash_profile
ln -sf $DIR/zshrc $HOME/.zshrc
ln -sf $DIR/zshenv $HOME/.zshenv
ln -sf $DIR/zlogin $HOME/.zlogin
if [ -d "$HOME/.zsh" ]; then
    mv $HOME/.zsh $HOME/.zsh.bak
fi
ln -s $DIR/zsh $HOME/.zsh
ln -s $DIR/starship $XDG_CONFIG_HOME/starship.toml

# Vim
ln -sf $DIR/vimrc $HOME/.vimrc
ln -sf $DIR/gvimrc $HOME/.gvimrc
if [ -d "$HOME/.vim" ]; then
    mv $HOME/.vim $HOME/.vim.bak
fi
ln -s $DIR/vim $HOME/.vim

# Neovim
mkdir $XDG_CONFIG_HOME/nvim
ln -sf $DIR/nvimrc $XDG_CONFIG_HOME/nvim/init.vim
ln -sf $DIR/coc-settings.json $XDG_CONFIG_HOME/nvim/coc-settings.json

# Git
ln -sf $DIR/gitconfig $HOME/.gitconfig
ln -sf $DIR/gitmessage $HOME/.gitmessage

# Terminals
ln -sf $DIR/dircolors.256dark $HOME/.dircolors.256dark
ln -sf $DIR/Xdefaults $HOME/.Xdefaults
ln -sf $DIR/Xresources $HOME/.Xresources
mkdir -p $HOME/.terminfo/r
ln -sf $DIR/terminfo/rxvt-unicode-256color $HOME/.terminfo/r/rxvt-unicode-256color

# Tmux
ln -sf $DIR/tmux.conf $HOME/.tmux.conf
ln -sf $DIR/tmux-osx.conf $HOME/.tmux-osx.conf

# Executables
ln -s $DIR/bin $HOME/.bin

# Linters
ln -sf ~/.dotfiles/flake8 ~/.config/flake8
ln -sf ~/.dotfiles/markdownlintrc ~/.config/markdownlint
ln -sf ~/.dotfiles/yamllintrc ~/.config/yamllint

echo "Done"
