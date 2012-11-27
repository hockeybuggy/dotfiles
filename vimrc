" vim: foldmethod=marker

set nocompatible
syntax on
filetype plugin indent on

"Preferences{{{1
call pathogen#infect()
call pathogen#helptags()

set hlsearch
set ruler
set laststatus=2
set number
set history=50
set wildmode=longest,list

set background=dark
colorscheme solarized

"Invisible character
set list
set listchars=tab:▸\ ,eol:¬

" Disables swap files and backups. Living on the edge.
set nobackup
set noswapfile

"Proud of my Canadian heritage.
setlocal spell spelllang=en_ca

" Indentation
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab


"Mappings {{{1
"External copy paste
nmap <C-P> "+gP
vmap <C-C> "+y

nmap <F4> :set hlsearch!<CR>
