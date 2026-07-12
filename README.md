# My dotfiles

This repository is for managing my configuration files.

## Installation

### 1. Clone this repo

Clone the repo. I like to put it at `~/.dotfiles`

    git clone git@github.com:hockeybuggy/dotfiles.git .dotfiles && cd .dotfiles

### 2. Install the tools

`setup.sh` installs the dependencies listed below. It works on macOS (via
Homebrew) and Debian/Ubuntu (via apt plus a few official installers). It
only installs tools -- it does not link any config.

    ./setup.sh

### 3. Automagically Link the files

    ./bootstrap.sh

## Checking a machine with `doctor.sh`

Run the doctor after installation to check required tools, linked config,
shell setup, environment variables, Git configuration, and optional
dependencies:

    ./doctor.sh

Checks report OK, WARN, or FAIL with a suggested fix. The command exits
non-zero for any required failure. Use `--strict` to also treat warnings as
failures, or `--ci` to skip checks that only apply to a personal machine.

## Testing `setup.sh`

You can exercise `setup.sh` on a clean Debian container. This builds a minimal
image, runs `setup.sh` and `bootstrap.sh` inside it, then drives a tmux session
to confirm each tool actually runs:

    ./test/run.sh

Pass `--interactive` to provision the container and drop into a shell so you
can poke around in tmux yourself:

    ./test/run.sh --interactive

## Dependencies

1. Executables
    1. neovim - 11.0
    1. tmux - 3.5
    1. iterm2
1. command line utils
    1. zsh  - 5.0
    1. reattach-to-user-namespace
    1. Inconsolata font (nerdfont variant)
    1. starship
    1. zoxide
    1. uutils-coreutils
    1. [ripgrep](https://github.com/BurntSushi/ripgrep) -- Grep replacement
    1. [fd](https://github.com/sharkdp/fd) -- `find` replacement
    1. [fzf](https://github.com/junegunn/fzf) -- Fuzzy finder
    1. [bat](https://github.com/sharkdp/bat) -- `cat` replacement
    1. [eza](https://eza.rocks/) -- `ls` replacement
    1. [bottom](https://github.com/ClementTsang/bottom) -- `top` replacement (`btm`)
1. Language things
    1. rustup, cargo, rustc
    1. Python 3.14, ruff, ty
    1. node, fnm, prettier
    1. luarocks, stylua
    1. rbenv, rubocop, solargraph
1. Coding Agents
    1. [agent-stuff](https://github.com/hockeybuggy/agent-stuff)
1. [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli)
1. Git related
    1. gnupg
    1. gpg-agent
    1. diff-so-fancy
