setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
setlocal colorcolumn=80,100

set makeprg =flake8\ %

map <leader>m :call Pylint()<CR>

if (exists("g:loaded_pylint") && g:loaded_pylint) || v:version < 700
  finish
endif
let g:loaded_pylint = 1

function Pylint()
  echom "Linting"
  silent make
  copen
  redraw!
endfunction
