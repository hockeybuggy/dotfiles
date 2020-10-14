#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

function doIt() {
    rsync --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude "bootstrap.sh" \
        --exclude "scripts" \
        --exclude "xdg_config" \
        --exclude "nvim" \
        --exclude "README.md" \
        --exclude "LICENSE-MIT.txt" \
        -avh --no-perms . ~;

    source ~/.bash_profile;

    # Install Neovim
    if [ ! -d ~/.config/nvim ]; then
        mkdir -p ~/.config/nvim
    else
        rm -rf ~/.config/nvim
    fi
    sh ./scripts/dein-installer.sh ~/.vim/bundles

    ln -sf $(pwd)/xdg_config/nvim/init.vim ~/.config/nvim/init.vim 
    ln -sf $(pwd)/xdg_config/nvim/coc-settings.json ~/.config/nvim/coc-settings.json;

    # Install Starship
    ln -sf $(pwd)/xdg_config/starship.toml ~/.config/starship.toml;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
    doIt;
else
    read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
    echo "";
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        doIt;
    fi;
fi;
unset doIt;



