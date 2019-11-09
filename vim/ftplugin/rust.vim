" mnemonic: (u)nit test
" This leader command will run only the tests for this one file (with the
" intention of being faster than running all of the tests for the project.
nnoremap <buffer> <localleader>u :Dispatch cargo test <C-R>=expand('%:t:r')<cr><cr>

" mnemonic: (a)ll tests
" This leader command will run all the tests for the project
nnoremap <buffer> <localleader>a :Dispatch cargo test<cr>
