DIR="$HOME/.dotfiles"

cd $DIR

echo "\nLinking dotfiles...\n"
# Create local bash config files
ln -sf $DIR/bashrc $HOME/.bashrc.local
ln -sf $DIR/bash_profile $HOME/.bash_profile.local

# Vim
ln -sf $DIR/vimrc $HOME/.vimrc
ln -sf $DIR/gvimrc $HOME/.gvimrc
if [ -d "$HOME/.vim" ]; then
    mv $HOME/.vim $HOME/.vim.bak
fi
ln -s $DIR/vim $HOME/.vim

# Switch back to starting directory
cd -

echo "Done"