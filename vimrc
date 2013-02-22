""""""""""""""""""""""""""""""""""""""""""""""""""
" The vimrc of Douglas James Anderson
""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible
filetype off

call pathogen#infect()
call pathogen#helptags()

syntax on
filetype plugin indent on

" Basic Preferences
let mapleader = ','
set incsearch
set nohlsearch
set ruler
set laststatus=2
set number
set history=800
set wildmode=longest,list
set laststatus=2        " Always show the last command
set showcmd             " Show unfinished commands in the status line

" Invisible characters
set list
set listchars=tab:▸\ ,eol:¬

" Set Spelling. Proud of my Canadian heritage.
setlocal spell spelllang=en_ca

set splitright
set splitbelow

" Set Indentation preferences
set tabstop=4
set softtabstop=4
set shiftwidth=4
set smarttab

" Colour scheme
set background=dark
colorscheme solarized
let g:solarized_termcolors = 256
let g:solarized_termtrans = 1
let g:solarized_visibility = "high"

" Disable swap files. Enables backups. Enable undo
set noswapfile
set backupdir=~/.vim/temp/backup
if has('persistent_undo')
    set undodir=~/.vim/temp/undo
    set undofile
    set undolevels=1000
    set undoreload=10000
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
""""""""""""""""""""""""""""""""""""""""""""""""""
" Window switching
nnoremap <C-k> <C-W>k
nnoremap <C-j> <C-W>j
nnoremap <C-h> <C-W>h
nnoremap <C-l> <C-W>l

" current file directory expand (http://vimcasts.org/episodes/the-edit-command/)
cnoremap %% <C-R>=expand('%:h').'/'<CR>
map <leader>ew :e %%
map <leader>es :sp %%
map <leader>ev :vsp %%
map <leader>et :tabe %%

" External copy paste
nmap <C-P> "+gp
vmap <C-C> "+y

" Toggle between light and dark background
call togglebg#map("<F3>")
""""""""""""""""""""""""""""""""""""""""""""""""""
" Status Line
""""""""""""""""""""""""""""""""""""""""""""""""""
if has('statusline')
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


