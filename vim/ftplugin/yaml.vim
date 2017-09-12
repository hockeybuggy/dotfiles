setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

autocmd! BufWritePost,BufRead *.ya?ml Neomake
