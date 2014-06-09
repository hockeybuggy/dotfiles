""""""""""""""""""""""""""""""""""""""""""""""""""
" The vimrc of Douglas James Anderson
""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible    " Pffft... vi... Please...

if filereadable(expand("~/.vim/vimrc.bundle"))
    source ~/.vim/vimrc.bundle
endif


""""""""""""""""""""""""""""""""""""""""""""""""""
" General Preferences
""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader      = ','
let maplocalleader = ','

set incsearch             " Incremental search
set nohlsearch            " Don't highlight searches
set hidden                " Allow navigating away from unsaved buffers
set number                " Show line numbers
set history=800           " This may be a bit extreme
set wildmode=longest,list " List completions
set laststatus=2          " Always show the last command
set showcmd               " Show unfinished commands in the status line
set mouse=a               " Makes the mouse work in rxvt

" Disable man mode and ex mode. I was finding them not useful
noremap K <nop>
noremap Q <nop>

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

"Automatic comment continuation on newlines.
"http://tilvim.com/2013/05/29/comment-prefix.html TODO fix this
set formatoptions-=or

" Colour scheme
if filereadable(expand("~/.vim/bundle/vim-colors-solarized/colors/solarized.vim"))
    set background=dark
    colorscheme solarized
    let g:solarized_termcolors = 256
    let g:solarized_termtrans = 1
    let g:solarized_visibility = "high"
else
    colorscheme desert
endif

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

" list current buffers
map <leader>l :ls<CR>

" Open a new split from an open buffer
map <leader>- :sp<bar>b
map <leader>\ :vsp<bar>b

" External copy paste
nmap <C-P> "+gp
vmap <C-C> "+y

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
    if filereadable(expand("~/.vim/bundle/vim-fugitive/plugin/fugitive.vim"))
        set statusline+=\ %#Identifier#
        set statusline+=[%{fugitive#head()}] " Branch name
        set statusline+=%*                   " Reset colour
    endif
    set statusline+=\ %#Statement#
    set statusline+=[%Y]                 " File type
    set statusline+=%*                   " Reset colour
    set statusline+=\ %#Constant#
    set statusline+=b:%n\                " Buffer number
    set statusline+=%(%l,%c%V%)\ %p%%    " Positional info
    set statusline+=%*\                  " End the status line in style
endif

