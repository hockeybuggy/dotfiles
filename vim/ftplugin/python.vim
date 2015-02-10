setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
setlocal colorcolumn=80,100

set makeprg =flake8\ %

map <leader>m :call Pylint()<CR>

function Pylint()
  echom "Linting"
  silent make
  copen
  redraw!
endfunction
