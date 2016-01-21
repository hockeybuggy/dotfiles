setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

set makeprg =jshint\ %

map <leader>m :call Jslint()<CR>

if (exists("g:loaded_jshint") && g:loaded_jshint) || v:version < 700
  finish
endif
let g:loaded_jshint = 1

function Jslint()
  echom "Linting"
  silent make
  copen
  redraw!
endfunction
