let g:racer_cmd = "~/.cargo/bin/racer"

autocmd! BufWritePost *.rs Neomake
