" The vimrc of Douglas James Anderson

" vim:fdm=marker fdc=3 fdl=1
" My theory is that anyone who is looking at this can use vim and can handle
" the folds. For people reading it outside of Vim I apologize for the fold
" markers.
" NOTE: remember zi & za, & zA. also remember z{motion} to move around

" Preferences {{{1
" Setup & pathogen {{{2
set nocompatible

call pathogen#infect()
call pathogen#helptags()

filetype off
syntax on
filetype plugin indent on

" Basic Preferences {{{2
let mapleader = ','
set nohlsearch
set ruler
set laststatus=2
set number
set history=200
set wildmode=longest,list

set background=dark
colorscheme solarized

" Allow the viewing of invisible characters {{{2
set list
set listchars=tab:▸\ ,eol:¬

" Disables swap files. Enables backups. {{{2
"set swapdir=~/.vim/temp/swap
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

" Set Indentation preferences {{{2
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" Window switching {{{2
nnoremap <C-k> <C-W>k
nnoremap <C-j> <C-W>j
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

" Mappings {{{1
" External copy paste {{{2
nmap <C-P> "+gp
vmap <C-C> "+y

" Toggle highlighting & search, background colour toggle {{{2
" TODO denote this in the status line
nmap <F4> :set hlsearch!<CR>
nmap <F2> :set spell!<CR>
" Toggles the background. Requires solarized.
call togglebg#map("<F3>")

" Toggle folding with space {{{2
nnoremap <Space> za

"Status Line {{{1
" Set the status line {{{2
" Really just put under a level two fold for giggles.
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


