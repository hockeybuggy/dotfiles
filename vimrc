" The vimrc of Douglas Anderson

"Preferences{{{1
set nocompatible

call pathogen#infect()
call pathogen#helptags()

filetype off
syntax on
filetype plugin indent on

let mapleader = ','
set hlsearch
set ruler
set laststatus=2
set number
set history=200
set wildmode=longest,list

set background=dark
colorscheme solarized
" Toggles the background. Requires solarized.
call togglebg#map("<F3>")

"Invisible character
set list
set listchars=tab:▸\ ,eol:¬

" Disables swap files and backups. Living on the edge.
set backup
if has('persistent_undo')
    set undofile
    set undolevels=1000
    set undoreload=10000
endif

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
nmap <F2> :set spell!<CR>

"Status Line {{{1
if has('statusline')
    set laststatus=2
    set statusline+=%w%h%m%r " Options
    set statusline+=%=
    set statusline+=%#Identifier#
    set statusline+=\ [%{fugitive#head()}]
    set statusline+=\ %*
    set statusline+=\ %#Special#
    set statusline+=\ [%{getcwd()}\/%f]
    set statusline+=\ %*
    set statusline+=\ \ %#Constant#
    set statusline+=\ %(%l,%c%V%)\ %p%%
    set statusline+=\ %*\ 
endif


