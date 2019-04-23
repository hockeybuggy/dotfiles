filetype off

set runtimepath+=~/.vim/bundles/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.vim/bundles')
  call dein#begin('~/.vim/bundles')

  " Plugin manager
  call dein#add('~/.vim/bundles/repos/github.com/Shougo/dein.vim')

  " Style
  call dein#add('vim-airline/vim-airline')
  call dein#add('vim-airline/vim-airline-themes')
  call dein#add('lifepillar/vim-solarized8')
  call dein#add('ap/vim-css-color')

  " Language
  call dein#add('tpope/vim-git')
  call dein#add('tpope/vim-fugitive')
  call dein#add('plasticboy/vim-markdown')
  call dein#add('mustache/vim-mustache-handlebars')
  call dein#add('LaTeX-Box-Team/LaTeX-Box')
  call dein#add('andersoncustodio/vim-tmux')
  call dein#add('derekwyatt/vim-scala')
  call dein#add('fatih/vim-go')
  call dein#add('groenewege/vim-less')
  call dein#add('rust-lang/rust.vim')
  call dein#add('cespare/vim-toml')
  call dein#add('pangloss/vim-javascript')
  call dein#add('mxw/vim-jsx')
  call dein#add('leafgarland/typescript-vim')
  call dein#add('tikhomirov/vim-glsl')
  call dein#add('dleonard0/pony-vim-syntax')
  call dein#add('prabirshrestha/asyncomplete.vim')
  call dein#add('prabirshrestha/async.vim')
  call dein#add('prabirshrestha/vim-lsp')
  call dein#add('prabirshrestha/asyncomplete-lsp.vim')
  call dein#add('b4b4r07/vim-hcl')

  " Textobjs
  runtime macros/matchit.vim
  call dein#add('kana/vim-textobj-user')
  call dein#add('kana/vim-textobj-line')
  call dein#add('kana/vim-textobj-indent')
  call dein#add('kana/vim-textobj-entire')
  call dein#add('nelstrom/vim-textobj-rubyblock')
  call dein#add('lucapette/vim-textobj-underscore')

  " Utility
  call dein#add('christoomey/vim-tmux-navigator')
  call dein#add('nelstrom/vim-visual-star-search')
  call dein#add('tpope/vim-unimpaired')
  call dein#add('tpope/vim-surround')
  call dein#add('tpope/vim-repeat')
  call dein#add('tpope/vim-commentary')
  call dein#add('tpope/vim-vinegar')
  call dein#add('tpope/vim-dispatch')
  call dein#add('vim-scripts/gitignore')
  call dein#add('justinmk/vim-sneak')
  call dein#add('w0rp/ale')
  call dein#add('mhinz/vim-grepper')
  call dein#add('junegunn/fzf', { 'build': './install', 'merged': 0 })
  call dein#add('junegunn/fzf.vim')
  call dein#add('ruanyl/vim-gh-line')

  call dein#end()
  call dein#save_state()
endif

syntax enable
filetype plugin indent on
