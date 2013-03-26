""""""""""""""""""""""""""""""""""""""""""""""""""
" The vimrc of Douglas James Anderson
""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible        " Pffft... vi... Please...
filetype off            " Turning filetype detection apparently speeds up pathogen

call pathogen#infect()
call pathogen#helptags()

syntax on
filetype plugin indent on


""""""""""""""""""""""""""""""""""""""""""""""""""
" General Preferences

""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader = ','
set incsearch
set nohlsearch
set hidden              " Allow navigating away from unsaved buffers
set number              " Show line numbers
set history=800         " This may be a bit extreme
set wildmode=longest,list
set laststatus=2        " Always show the last command
set showcmd             " Show unfinished commands in the status line
set mouse=a             " Makes the mouse work in urxvt

" Invisible characters
set list
set listchars=tab:▸\ ,eol:¬

" Set Spelling. Proud of my Canadian heritage.
setlocal spell spelllang=en_ca

" Change the splitting behaviour.
set splitright
set splitbelow

" Set Indentation preferences
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

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
    set statusline=                      " Useful if re-source-ing
    set statusline+=%w%h%m%r             " Flags
    set statusline+=%=                   " Right align
    set statusline+=%#Special#
    set statusline+=[%f]                 " File name
    set statusline+=%*                   " Reset colour
    set statusline+=\ %#Identifier#
    set statusline+=[%{fugitive#head()}] " Branch name
    set statusline+=%*                   " Reset colour
    set statusline+=\ %#Statement#
    set statusline+=[%Y]                 " File type
    set statusline+=%*                   " Reset colour
    set statusline+=\ %#Constant#
    set statusline+=b:%n\                " Buffer number
    set statusline+=%(%l,%c%V%)\ %p%%    " Positional info
    set statusline+=%*\                  " End the status line in style
endif


