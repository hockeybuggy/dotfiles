
call pathogen#infect()

syntax on
set ruler
set laststatus=2
set nu!

"comment was too blue in my blue terminal
"highlight Comment ctermfg=green

set background=dark
colorscheme solarized

"Nerd commenter want this enabled
filetype plugin on

"Invisible character colors
set list
set listchars=tab:▸\ ,eol:¬
highlight NonText guifg=#dddddd
highlight SpecialKey guifg=#dddddd

" Indentation
set ts=4
set sts=4
set sw=4
set expandtab

"Proud of my heritage. But I find it a little sad it might give me trouble
"   with colour...
setlocal spell spelllang=en_ca

"External copy paste
nmap <C-P> "+gP
vmap <C-C> "+y

