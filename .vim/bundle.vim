
" This requires that the plug is installed first see: https://github.com/junegunn/vim-plug#neovim

call plug#begin()

" Style
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'ericbn/vim-solarized'
Plug 'ap/vim-css-color'

" Language
Plug 'tpope/vim-git'
Plug 'plasticboy/vim-markdown'
Plug 'mustache/vim-mustache-handlebars'
Plug 'andersoncustodio/vim-tmux'
Plug 'derekwyatt/vim-scala'
Plug 'fatih/vim-go'
Plug 'groenewege/vim-less'
Plug 'rust-lang/rust.vim'
Plug 'cespare/vim-toml'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'leafgarland/typescript-vim'
Plug 'tikhomirov/vim-glsl'
Plug 'dleonard0/pony-vim-syntax'
Plug 'b4b4r07/vim-hcl'
Plug 'elmcast/elm-vim'

" Textobjs
runtime macros/matchit.vim
Plug 'kana/vim-textobj-user'
Plug 'kana/vim-textobj-line'
Plug 'kana/vim-textobj-indent'
Plug 'kana/vim-textobj-entire'
Plug 'nelstrom/vim-textobj-rubyblock'
Plug 'lucapette/vim-textobj-underscore'

" Utility
Plug 'christoomey/vim-tmux-navigator'
Plug 'nelstrom/vim-visual-star-search'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
Plug 'justinmk/vim-sneak'
Plug 'mhinz/vim-grepper'
Plug 'junegunn/fzf', { 'build': './install', 'merged': 0 }
Plug 'junegunn/fzf.vim'
Plug 'ruanyl/vim-gh-line'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install --frozen-lockfile'}

call plug#end()
