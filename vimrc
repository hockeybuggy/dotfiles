""""""""""""""""""""""""""""""""""""""""""""""""""
" The vimrc of Douglas James Anderson
""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible    " Pffft... vi... Please...

" Load plugins
if filereadable(expand('~/.vim/bundle.vim'))
  source ~/.vim/bundle.vim
endif


""""""""""""""""""""""""""""""""""""""""""""""""""
" General Preferences
""""""""""""""""""""""""""""""""""""""""""""""""""
let g:mapleader      = ','
let g:maplocalleader = ','

set incsearch                  " Incremental search
set inccommand=nosplit         " Incremental substitute preview
set nohlsearch                 " Don't highlight searches
set hidden                     " Allow navigating away from unsaved buffers
set relativenumber             " Relative numbers are the bomb
set number                     " Show current line number rather than zero
set history=800                " This may be a bit extreme
set wildmode=longest,list      " List completions
set laststatus=2               " Always show the last command
set showcmd                    " Show unfinished commands in the status line
set mouse=""                   " I don't really like the mouse much...
set ttyfast                    " Send characters to the screen faster
set backspace=indent,eol,start " Change the backspace mode
set autoread                   " Update the buffer when the file changed externally
set scrolloff=1                " Always show at least one line above the cursor

" Disable man mode and ex mode. I was finding them not useful
noremap K <nop>
noremap Q <nop>

" Invisible characters
set list
set listchars=tab:▸\ ,eol:¬,trail:¤

" Set Spelling. Proud of my Canadian heritage.
set spelllang=en_ca
set spellfile=~/.vim/spell/en.utf-8.add

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

" Alias Ls to ls
cnoreabbrev Ls ls

" Colour scheme
set background=dark
let g:solarized_use16 = 1
colorscheme solarized8_high
syntax on

if $TERM_PROGRAM =~? 'screen-256color'
    let s:terminal_italic=1
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

if has('nvim')
  tnoremap <Esc> <C-\><C-n>
  " mnemonic verbatium e
  tnoremap <C-v><Esc> <Esc>
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

" List current buffers
map <leader>l :ls<CR>

" Open a new split from an open buffer
map <leader>b :b
map <leader>- :sp<bar>b
map <leader>\ :vsp<bar>b
map <leader>t :tabe<bar>b

" Search tools
let g:grepper = {}
let g:grepper.tools = ['rg']
" Grep for selection
nnoremap <leader>g :Grepper -tool rg<cr>
nnoremap <leader>G :Grepper -tool rg -buffers<cr>
" Grep for word under cursor
nnoremap <leader>* :Grepper -cword -noprompt<CR>
" Grep for selection
nmap gs <plug>(GrepperOperator)
xmap gs <plug>(GrepperOperator)
" Grep outstanding items
command! Todo :Grepper -tool rg -query 'TODO'

" Enable syntax highlighting of Pipfiles
autocmd BufNewFile,BufRead Pipfile set ft=toml
autocmd BufNewFile,BufRead Pipfile.lock set ft=javascript

" Linting tools
let g:ale_linters = {
\   'css': ['stylelint'],
\   'javascript': ['eslint'],
\   'python': ['flake8'],
\   'rust': ['cargo', 'rls'],
\   'scss': ['stylelint'],
\   'sql': ['sqlint'],
\   'vim': ['vint'],
\   'yaml': ['yaml'],
\   'html': [],
\}
let g:ale_fixers = {
\   'javascript': ['eslint'],
\   'rust': ['rustfmt'],
\}
let g:ale_fix_on_save = 0
" Unimpaired style mappings for ALE
nmap [w <Plug>(ale_previous_wrap)
nmap ]w <Plug>(ale_next_wrap)
nmap [W <Plug>(ale_first)
nmap ]W <Plug>(ale_last)
nnoremap <leader>f :ALEFix<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""
" Status Line
""""""""""""""""""""""""""""""""""""""""""""""""""
" Airline
set noshowmode " Hide the default mode display
let g:airline_theme='solarized'
let g:airline_powerline_fonts=1

" Speeds the timeout for the status line
if ! has('gui_running')
  set ttimeoutlen=10
  augroup FastEscape
    autocmd!
    au InsertEnter * set timeoutlen=0
    au InsertLeave * set timeoutlen=1000
  augroup END
endif

let g:airline#extensions#ale#enabled = 1
