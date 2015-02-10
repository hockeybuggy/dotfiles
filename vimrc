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
set mouse=""              " I don't really like the mouse much...

" Disable man mode and ex mode. I was finding them not useful
noremap K <nop>
noremap Q <nop>

" Invisible characters
set list
set listchars=tab:▸\ ,eol:¬,trail:¤

" Set Spelling. Proud of my Canadian heritage.
setlocal spell spelllang=en_ca

" My preferred splitting behaviour.
set splitright
set splitbelow

" Set Indentation preferences
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" Turn off automatic comment continuation on newlines.
autocmd FileType * setlocal formatoptions-=o formatoptions-=r

" TODO :%! python -m json.tool

" Colour scheme
if has("gui_running")
    set background=light
else
    set background=dark
endif
if filereadable(expand("~/.vim/bundle/vim-colors-solarized/colors/solarized.vim"))
    colorscheme solarized
    let g:solarized_termcolors = 256
    let g:solarized_termtrans = 1
    let g:solarized_visibility = "high"
    if $TERM_PROGRAM =~ "screen-256color"
        let s:terminal_italic=1
    endif
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

" Current file directory expand (http://vimcasts.org/episodes/the-edit-command/)
cnoremap %% <C-R>=expand('%:h').'/'<CR>
map <leader>ew :e %%
map <leader>es :sp %%
map <leader>ev :vsp %%
map <leader>et :tabe %%

" -----  Shortcuts -----
" List current buffers
map <leader>l :ls<CR>

" Open a new split from an open buffer
map <leader>b :b
map <leader>- :sp<bar>b
map <leader>\ :vsp<bar>b
map <leader>t :tabe<bar>b
map <leader>m :make<CR>


" External copy paste
nmap <C-P> "+gp
vmap <C-C> "+y

""""""""""""""""""""""""""""""""""""""""""""""""""
" Status Line
""""""""""""""""""""""""""""""""""""""""""""""""""
" Airline
set noshowmode " Hide the default mode display
let g:airline_theme="solarized"
"let g:airline_powerline_fonts=1

" Speeds the timeout for the status line
if ! has('gui_running')
    set ttimeoutlen=10
    augroup FastEscape
        autocmd!
        au InsertEnter * set timeoutlen=0
        au InsertLeave * set timeoutlen=1000
    augroup END
endif

