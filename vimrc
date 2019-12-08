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

" Set default indentation preferences
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

" Turn off automatic comment continuation on newlines.
autocmd FileType * setlocal formatoptions-=o formatoptions-=r
" Enable syntax highlighting of Pipfile.lock files
autocmd BufNewFile,BufRead Pipfile.lock set filetype=javascript
autocmd BufNewFile,BufRead *.workflow   set filetype=tf


" Alias Ls to ls
cnoreabbrev Ls ls

" Colour scheme
set background=dark
if $BACKGROUND_COLOR ==? 'light'
  set background=light
endif
let g:solarized_use16 = 1
colorscheme solarized8
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

" Some things to make terminal buffers a little easier
if has('nvim')
  tnoremap <Esc> <C-\><C-n>
  tnoremap <A-]> <C-\><C-n>

  " mnemonic verbatium esc
  tnoremap <C-v><Esc> <Esc>

  " move around terminal buffers
  tnoremap <A-h> <C-\><C-N><C-w>h
  tnoremap <A-j> <C-\><C-N><C-w>j
  tnoremap <A-k> <C-\><C-N><C-w>k
  tnoremap <A-l> <C-\><C-N><C-w>l
  inoremap <A-h> <C-\><C-N><C-w>h
  inoremap <A-j> <C-\><C-N><C-w>j
  inoremap <A-k> <C-\><C-N><C-w>k
  inoremap <A-l> <C-\><C-N><C-w>l
  nnoremap <A-h> <C-w>h
  nnoremap <A-j> <C-w>j
  nnoremap <A-k> <C-w>k
  nnoremap <A-l> <C-w>l
endif
au TermOpen * setlocal norelativenumber nonumber


""""""""""""""""""""""""""""""""""""""""""""""""""
" Tools
""""""""""""""""""""""""""""""""""""""""""""""""""
" Grepper - a search tools
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


" fzf - a fuzzy finder tool
let g:fzf_nvim_statusline = 0 " disable statusline overwriting
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }
nnoremap <leader>ff :FZF<cr>
nnoremap <leader>fb :Buffers<cr>
" Disable my remapping for escape for terminal buffers.
autocmd! FileType fzf tnoremap <ESC> <ESC>

let g:gh_line_map_default = 0
let g:gh_line_blame_map_default = 0
let g:gh_line_map = '<leader>hh'
let g:gh_line_blame_map = '<leader>hb'
let g:gh_open_command = 'fn() { echo "$@" | pbcopy; }; fn '


" Language Server
" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
inoremap <expr> <TAB> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<TAB>"
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Slightly faster rechecking for the dianostics
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c

" always show signcolumns
set signcolumn=yes

" Unimpaired style mappings for CoC
nmap <silent> [w <Plug>(coc-diagnostic-prev)
nmap <silent> ]w <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" show documentation
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
nnoremap <silent> K :call <SID>show_documentation()<CR>

" I was having trouble with getting `coc.preferences.formatOnSaveFiletypes`
" working. This is a bit of a cheap work around for now
autocmd BufWritePre *.css call CocAction("format")
autocmd BufWritePre *.js call CocAction("format")
autocmd BufWritePre *.jsx call CocAction("format")
autocmd BufWritePre *.ts call CocAction("format")
autocmd BufWritePre *.tsx call CocAction("format")


" Airline - a Status Line
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
