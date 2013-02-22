" The vimrc of Douglas James Anderson

" Preferences {{{1
" Setup & pathogen {{{2
set nocompatible
filetype off

call pathogen#infect()
call pathogen#helptags()

syntax on
filetype plugin indent on

" Basic Preferences {{{2
let mapleader = ','
set nohlsearch
set ruler
set laststatus=2
set number
set history=800
set wildmode=longest,list
set showcmd

" Invisible characters {{{2
set list
set listchars=tab:▸\ ,eol:¬

" Disables swap files. Enables backups. {{{2
set noswapfile
set backupdir=~/.vim/temp/backup
if has('persistent_undo')
    set undodir=~/.vim/temp/undo
    set undofile
    set undolevels=1000
    set undoreload=10000
endif

" Set Spelling. Proud of my Canadian heritage.  {{{2
setlocal spell spelllang=en_ca

set splitright
set splitbelow

" Set Indentation preferences {{{2
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab

" Window switching {{{2
nnoremap <C-k> <C-W>k
nnoremap <C-j> <C-W>j
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

" Mappings {{{1
" External copy paste {{{2
nmap <C-P> "+gp
vmap <C-C> "+y

" Colour scheme {{{2
colorscheme solarized
set background=dark
let g:solarized_termcolors = 256
let g:solarized_termtrans = 1
let g:solarized_visibility = "high"
call togglebg#map("<F3>")

"Status Line {{{1
if has('statusline')
    set laststatus=2
    set statusline+=%w%h%m%r " Options
    set statusline+=%=
    set statusline+=%#Identifier#
    set statusline+=[%{fugitive#head()}]
    set statusline+=%*
    set statusline+=\ %#Special#
    set statusline+=[%f]
    set statusline+=%*
    set statusline+=\ %#Constant#
    set statusline+=%(%l,%c%V%)\ %p%%
    set statusline+=%*\ 
endif


