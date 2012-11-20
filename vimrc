
set nocompatible

call pathogen#infect()
call pathogen#helptags()

syntax on
filetype plugin indent on

set hlsearch
set ruler
set laststatus=2
set number
set history=50
set wildmode=longest,list

set background=dark
colorscheme solarized


"Invisible character colors
set list
set listchars=tab:▸\ ,eol:¬

" Indentation
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" Disables swapfiles and backups. Living on the edge.
set nobackup
set noswapfile

"Proud of my Canadian heritage. But I find it a little sad it might give me
"trouble with colour...
setlocal spell spelllang=en_ca

"External copy paste
nmap <C-P> "+gP
vmap <C-C> "+y

