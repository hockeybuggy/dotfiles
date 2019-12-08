" Created becase leafgarland/typescript-vim wasn't setting `tsx` correctly.
autocmd BufNewFile,BufRead *.ts  set filetype=typescript
autocmd BufNewFile,BufRead *.tsx set filetype=typescript.tsx
