setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

autocmd BufNewFile,BufRead *.json set ft=javascript
autocmd! BufWritePost,BufRead *.js Neomake
