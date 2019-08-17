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


" ALE - linting and fixing tool
let g:ale_linters = {
\   'css': ['stylelint'],
\   'javascript': ['eslint', 'tsserver'],
\   'typescript': ['tslint', 'tsserver'],
\   'python': ['pylint', 'mypy'],
\   'rust': ['cargo', 'rls'],
\   'scss': ['stylelint'],
\   'sql': ['sqlint'],
\   'vim': ['vint'],
\   'yaml': ['yamllint'],
\   'html': [],
\}
let g:ale_fixers = {
\   'rust': ['rustfmt'],
\   'css': ['prettier'],
\   'typescript': ['prettier'],
\}
let g:ale_fix_on_save = 1

" Unimpaired style mappings for ALE
nmap [w <Plug>(ale_previous_wrap)
nmap ]w <Plug>(ale_next_wrap)
nmap [W <Plug>(ale_first)
nmap ]W <Plug>(ale_last)
nnoremap <leader>x :ALEFix<CR>
nnoremap <leader>d :ALEGoToDefinition<cr>
nnoremap <leader>t :Dispatch<cr>


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
let g:lsp_diagnostics_enabled = 0
set pumheight=8
let g:asyncomplete_auto_popup = 0
let g:asyncomplete_smart_completion = 1
let g:lsp_highlight_references_enabled = 1
highlight lspReference ctermbg=green guibg=green
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

if executable('typescript-language-server')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'typescript-language-server',
        \ 'cmd': {server_info->[&shell, &shellcmdflag, 'typescript-language-server --stdio']},
        \ 'root_uri':{server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'tsconfig.json'))},
        \ 'whitelist': ['typescript'],
        \ })
endif
autocmd FileType typescript setlocal omnifunc=lsp#complete

if executable('pyls')
  " pip install python-language-server
  au User lsp_setup call lsp#register_server({
      \ 'name': 'pyls',
      \ 'cmd': {server_info->['pyls']},
      \ 'whitelist': ['python'],
      \ })
endif
autocmd FileType python setlocal omnifunc=lsp#complete

if executable('rls')
  " rustup update && rustup component add rls-preview rust-analysis rust-src
  au User lsp_setup call lsp#register_server({
      \ 'name': 'rls',
      \ 'cmd': {server_info->['rls']},
      \ 'whitelist': ['rust'],
      \ })
endif
autocmd FileType rust setlocal omnifunc=lsp#complete
autocmd FileType rust let b:dispatch='cargo test --quiet --message-format=short'


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
let g:airline#extensions#ale#enabled = 1
