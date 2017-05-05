""""""""""""""""""""""""""""""""""""""""""""""""""
" The vimrc of Douglas James Anderson
""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible    " Pffft... vi... Please...

" Load plugins
if filereadable(expand("~/.vim/bundle.vim"))
  source ~/.vim/bundle.vim
endif

""""""""""""""""""""""""""""""""""""""""""""""""""
" General Preferences
""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader      = ','
let maplocalleader = ','

set incsearch                  " Incremental search
set nohlsearch                 " Don't highlight searches
set hidden                     " Allow navigating away from unsaved buffers
set relativenumber             " Relative numbers are the bomb
set history=800                " This may be a bit extreme
set wildmode=longest,list      " List completions
set laststatus=2               " Always show the last command
set showcmd                    " Show unfinished commands in the status line
set mouse=""                   " I don't really like the mouse much...
set ttyfast                    " Send characters to the screen faster
set backspace=indent,eol,start " Change the backspace mode

" Disable man mode and ex mode. I was finding them not useful
noremap K <nop>
noremap Q <nop>

" Invisible characters
set list
set listchars=tab:▸\ ,eol:¬,trail:¤

" Set Spelling. Proud of my Canadian heritage.
set spell spelllang=en_ca
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
if has("gui_running")
    set background=light
else
    set background=dark
endif

colorscheme solarized
let g:solarized_termcolors = 256
let g:solarized_termtrans = 1
let g:solarized_visibility = "high"
if $TERM_PROGRAM =~ "screen-256color"
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

" -----  Shortcuts -----
" List current buffers
map <leader>l :ls<CR>

" Open a new split from an open buffer
map <leader>b :b
map <leader>- :sp<bar>b
map <leader>\ :vsp<bar>b
map <leader>t :tabe<bar>b
map <leader>m :Neomake<CR>

" External copy paste
nmap <C-P> "+gp
vmap <C-C> "+y

if executable('rg')
  let g:ackprg='rg --vimgrep'
elseif executable('ag')
  let g:ackprg='ag --vimgrep'
endif
cnoreabbrev Ag Ack

""""""""""""""""""""""""""""""""""""""""""""""""""
" Status Line
""""""""""""""""""""""""""""""""""""""""""""""""""
" Airline
set noshowmode " Hide the default mode display
let g:airline_theme="solarized"
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


""""""""""""""""""""""""""""""""""""""""""""""""""
" Language Specific settings
""""""""""""""""""""""""""""""""""""""""""""""""""
let g:neomake_highlight_lines = 0
let g:neomake_highlight_columns = 0

" JavaScript
autocmd BufNewFile,BufRead *.json set ft=javascript
autocmd! BufWritePost,BufRead *.js Neomake

" Python
autocmd! BufWritePost,BufRead *.py Neomake

" Rust
autocmd! BufWritePost *.rs Neomake

" Markdown
let g:vim_markdown_conceal = 0
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_fenced_languages = ['python=python', 'bash=sh']
