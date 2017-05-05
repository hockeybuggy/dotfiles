setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
setlocal colorcolumn=80,100

set makeprg =flake8\ %
autocmd! BufWritePost,BufRead *.py Neomake

abbreviate ipdb_trace import ipdb; ipdb.sset_trace()
