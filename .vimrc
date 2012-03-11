
call pathogen#infect()

syntax on
set ruler
set laststatus=2
set nu!

set background=dark
colorscheme solarized

" markdown filetype file
au BufRead,BufNewFile *.{md,mdown,mkd,mkdn,markdown,mdwn}   set filetype=mkd

"Invisible character colors
set list
set listchars=tab:▸\ ,eol:¬
highlight NonText guifg=#dddddd
highlight SpecialKey guifg=#dddddd


set ts=4 sts=4 sw=4 expandtab

nmap <C-P> "+gP
vmap <C-C> "+y

" I can have these back once I don't want them anymore
noremap  <Up> ""
noremap! <Up> <Esc>
noremap  <Down> ""
noremap! <Down> <Esc>
noremap  <Left> ""
noremap! <Left> <Esc>
noremap  <Right> ""
noremap! <Right> <Esc>

