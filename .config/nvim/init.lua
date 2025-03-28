-- """"""""""""""""""""""""""""""""""""""""""""""""""
-- " The vimrc of Douglas James Anderson
-- """"""""""""""""""""""""""""""""""""""""""""""""""
-- This is a lua config based off of kickstart.nvim and my vimscript vimrc

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Using `,` as a leaderkey
vim.g.mapleader = ','
vim.g.maplocalleader = ','

vim.g.have_nerd_font = true

vim.opt.number = true -- Show current line number rather than zero
vim.opt.relativenumber = true -- Relative numbers are the bomb

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Enable break indent
vim.opt.breakindent = true

-- Don't Save undo history
vim.opt.undofile = false

-- Keep signcolumn on by default
vim.opt.signcolumn = 'yes'

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = '▸ ', trail = '¬', nbsp = '¤' }

vim.opt.spelllang = 'en_ca'
vim.opt.spellfile = '~/.vim/spell/en.utf-8.add'

-- Show which line your cursor is on
vim.opt.cursorline = false

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.opt.confirm = true

-- Configure ripgrep as the grep program
vim.opt.grepprg = 'rg --vimgrep --smart-case --follow'
vim.opt.grepformat = '%f:%l:%c:%m,%f:%l:%m'

-- """"""""""""""""""""""""""""""""""""""""""""""""""
-- " Mappings
-- """"""""""""""""""""""""""""""""""""""""""""""""""

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Disable man mode and ex mode. I was finding them not useful
vim.keymap.set('n', 'K', '<nop>', { desc = 'Disable Manual mode' })
vim.keymap.set('n', 'Q', '<nop>', { desc = 'Disable Ex mode' })

-- Git Blame
vim.keymap.set('n', '<leader>gb', '<cmd>BlameToggle<CR>', { desc = '[G]it [B]lame' })

-- GitHub copy line tool
vim.g.gh_line_map_default = 0
vim.g.gh_line_blame_map_default = 0
vim.g.gh_line_map = '<leader>hh'
vim.g.gh_line_blame_map = '<leader>hb'
vim.g.gh_open_command = 'fn() { echo "$@" | pbcopy; }; fn '

-- LSP plugins
vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
-- Simple navigation between diagnostics with ]w and [w
vim.keymap.set('n', ']w', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[w', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostics' })

-- Window switching
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Map visual selection to ripgrep search via Telescope
vim.keymap.set('v', 'gs', function()
  local saved_reg = vim.fn.getreg('"')
  vim.cmd('noau normal! "vy"')
  local selection = vim.fn.getreg('v')
  vim.fn.setreg('"', saved_reg)

  -- Replace newlines with spaces
  selection = selection:gsub('\n', ' ')
  -- Escape special characters for shell
  selection = selection:gsub('([\'"])', '\\%1')

  -- Execute ripgrep and directly populate quickfix list
  vim.cmd('silent grep! "' .. selection .. '"')
  -- Open the quickfix list
  vim.cmd('copen')
end, { desc = '[S]earch with [G]rep using visual selection' })

-- """"""""""""""""""""""""""""""""""""""""""""""""""
-- " Language Server
-- """"""""""""""""""""""""""""""""""""""""""""""""""

vim.lsp.config['pyright'] = {
  -- Command to start the server
  cmd = { 'basedpyright-langserver', '--stdio' },

  -- Filetypes this server should be used for
  filetypes = { 'python' },

  -- Find project root based on these markers
  root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', '.git' },

  -- Server-specific settings
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'workspace',
        useLibraryCodeForTypes = true,
      },
    },
  },
}
vim.lsp.enable('pyright')

vim.lsp.config['rust_analyzer'] = {
  -- Command to start the server
  cmd = { 'rust-analyzer' },

  -- Filetypes this server should be used for
  filetypes = { 'rust' },

  -- Find project root based on these markers
  root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },

  -- Server-specific settings
  settings = {
    ['rust-analyzer'] = {
      cargo = {
        allFeatures = true,
      },
      checkOnSave = {
        command = 'clippy',
      },
    },
  },
}
vim.lsp.enable('rust_analyzer')

vim.lsp.config['tsserver'] = {
  -- Command to start the server
  cmd = { 'typescript-language-server', '--stdio' },

  -- Filetypes this server should be used for
  filetypes = { 'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx' },

  -- Find project root based on these markers
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },

  -- Server-specific settings
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = 'all',
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
  },

  -- Optional: configure init options
  init_options = {
    hostInfo = 'neovim',
    preferences = {
      includeCompletionsForModuleExports = true,
    },
  },
}
vim.lsp.enable('tsserver')

-- Ruby LSP configuration
vim.lsp.config['solargraph'] = {
  -- Command to start the server
  cmd = { 'solargraph', 'stdio' },

  -- Filetypes this server should be used for
  filetypes = { 'ruby' },

  -- Find project root based on these markers
  root_markers = { 'Gemfile', '.git' },

  -- Server-specific settings
  settings = {
    solargraph = {
      diagnostics = true,
      completion = true,
      useBundler = false, -- Set to true if solargraph is installed via bundle
    },
  },
}
vim.lsp.enable('solargraph')

-- """"""""""""""""""""""""""""""""""""""""""""""""""
-- " Plugins
-- """"""""""""""""""""""""""""""""""""""""""""""""""

require('lazy').setup({
  spec = {
    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

    'tpope/vim-vinegar', -- Improvements to netrw

    {
      'ericbn/vim-solarized',
      priority = 1000, -- Make sure to load this before all the other start plugins.
      config = function()
        vim.cmd.colorscheme('solarized')
      end,
    },

    'ruanyl/vim-gh-line', -- Copy GitHub permalinks

    'christoomey/vim-tmux-navigator', -- Navigate between tmux panes and Vim windows

    { -- Fuzzy Finder (files, lsp, etc)
      'nvim-telescope/telescope.nvim',
      event = 'VimEnter',
      branch = '0.1.x',
      dependencies = {
        'nvim-lua/plenary.nvim',
        { -- If encountering errors, see telescope-fzf-native README for installation instructions
          'nvim-telescope/telescope-fzf-native.nvim',

          -- `build` is used to run some command when the plugin is installed/updated.
          -- This is only run then, not every time Neovim starts up.
          build = 'make',

          -- `cond` is a condition used to determine whether this plugin should be
          -- installed and loaded.
          cond = function()
            return vim.fn.executable('make') == 1
          end,
        },
        { 'nvim-telescope/telescope-ui-select.nvim' },

        -- Useful for getting pretty icons, but requires a Nerd Font.
        { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      },
      config = function()
        -- Telescope is a fuzzy finder that comes with a lot of different things than
        -- it can fuzzy find! It's more than just a "file finder", it can search
        -- many different aspects of Neovim, your workspace, LSP, and more!
        --
        -- The easiest way to use Telescope, is to start by doing something like:
        --  :Telescope help_tags
        --
        -- After running this command, a window will open up and you're able to
        -- type in the prompt window. You'll see a list of `help_tags` options and
        -- a corresponding preview of the help.
        --
        -- Two important keymaps to use while in Telescope are:
        --  - Insert mode: <c-/>
        --  - Normal mode: ?
        --
        -- This opens a window that shows you all of the keymaps for the current
        -- Telescope picker. This is really useful to discover what Telescope can
        -- do as well as how to actually do it!

        -- [[ Configure Telescope ]]
        -- See `:help telescope` and `:help telescope.setup()`
        require('telescope').setup({
          -- You can put your default mappings / updates / etc. in here
          --  All the info you're looking for is in `:help telescope.setup()`
          --
          -- defaults = {
          --   mappings = {
          --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
          --   },
          -- },
          -- pickers = {}
          extensions = {
            ['ui-select'] = {
              require('telescope.themes').get_dropdown(),
            },
          },
        })

        -- Enable Telescope extensions if they are installed
        pcall(require('telescope').load_extension, 'fzf')
        pcall(require('telescope').load_extension, 'ui-select')

        -- See `:help telescope.builtin`
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
        vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
        vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
        vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
        vim.keymap.set('n', '<leader>gw', builtin.grep_string, { desc = '[G]rep current [W]ord' })
        vim.keymap.set('n', '<leader>gs', builtin.live_grep, { desc = '[G]rep [S]earch' })
        vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
        vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
        vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
        vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

        -- Slightly advanced example of overriding default behavior and theme
        vim.keymap.set('n', '<leader>/', function()
          -- You can pass additional configuration to Telescope to change the theme, layout, etc.
          builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
            winblend = 10,
            previewer = false,
          }))
        end, { desc = '[/] Fuzzily search in current buffer' })

        -- It's also possible to pass additional configuration options.
        --  See `:help telescope.builtin.live_grep()` for information about particular keys
        vim.keymap.set('n', '<leader>s/', function()
          builtin.live_grep({
            grep_open_files = true,
            prompt_title = 'Live Grep in Open Files',
          })
        end, { desc = '[S]earch [/] in Open Files' })

        -- Shortcut for searching your Neovim configuration files
        vim.keymap.set('n', '<leader>sn', function()
          builtin.find_files({ cwd = vim.fn.stdpath('config') })
        end, { desc = '[S]earch [N]eovim files' })
      end,
    },

    { -- Autoformat
      'stevearc/conform.nvim',
      event = { 'BufWritePre' },
      cmd = { 'ConformInfo' },
      keys = {
        {
          '<leader>f',
          function()
            require('conform').format({ async = true, lsp_format = 'fallback' })
          end,
          mode = '',
          desc = '[F]ormat buffer',
        },
      },
      opts = {
        notify_on_error = false,
        format_on_save = function(bufnr)
          -- Disable "format_on_save lsp_fallback" for languages that don't
          -- have a well standardized coding style. You can add additional
          -- languages here or re-enable it for the disabled ones.
          local disable_filetypes = { c = true, cpp = true }
          if disable_filetypes[vim.bo[bufnr].filetype] then
            return nil
          else
            return {
              timeout_ms = 500,
              lsp_format = 'fallback',
            }
          end
        end,
        formatters_by_ft = {
          lua = { 'stylua' },
          -- Conform can also run multiple formatters sequentially
          python = { 'black' },
          -- You can use 'stop_after_first' to run the first available formatter from the list
          javascript = { 'prettierd', 'prettier', stop_after_first = true },
          rust = { 'rustfmt' },
          ruby = { 'rubocop' },
        },
      },
    },

    -- Highlight todo, notes, etc in comments
    {
      'folke/todo-comments.nvim',
      event = 'VimEnter',
      dependencies = { 'nvim-lua/plenary.nvim' },
      opts = { signs = false },
    },

    { -- Collection of various small independent plugins/modules
      'echasnovski/mini.nvim',
      config = function()
        -- Better Around/Inside textobjects
        --
        -- Examples:
        --  - va)  - [V]isually select [A]round [)]paren
        --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
        --  - ci'  - [C]hange [I]nside [']quote
        require('mini.ai').setup({ n_lines = 500 })

        -- Add/delete/replace surroundings (brackets, quotes, etc.)
        --
        -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
        -- - sd'   - [S]urround [D]elete [']quotes
        -- - sr)'  - [S]urround [R]eplace [)] [']
        require('mini.surround').setup()

        -- Simple and easy statusline.
        --  You could remove this setup call if you don't like it,
        --  and try some other statusline plugin
        local statusline = require('mini.statusline')
        -- set use_icons to true if you have a Nerd Font
        statusline.setup({ use_icons = vim.g.have_nerd_font })

        -- You can configure sections in the statusline by overriding their
        -- default behavior. For example, here we set the section for
        -- cursor location to LINE:COLUMN
        ---@diagnostic disable-next-line: duplicate-set-field
        statusline.section_location = function()
          return '%2l:%-2v'
        end

        -- ... and there is more!
        --  Check out: https://github.com/echasnovski/mini.nvim
      end,
    },

    { -- Highlight, edit, and navigate code
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate',
      main = 'nvim-treesitter.configs', -- Sets main module to use for opts
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
      opts = {
        ensure_installed = {
          'bash',
          'c',
          'diff',
          'html',
          'lua',
          'luadoc',
          'markdown',
          'markdown_inline',
          'query',
          'vim',
          'vimdoc',
          'rust',
          'python',
          'ruby',
        },
        -- Autoinstall languages that are not installed
        auto_install = true,
        highlight = {
          enable = true,
          -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
          --  If you are experiencing weird indenting issues, add the language to
          --  the list of additional_vim_regex_highlighting and disabled languages for indent.
          additional_vim_regex_highlighting = { 'ruby' },
        },
        indent = { enable = true, disable = { 'ruby' } },
      },
    },

    {
      'FabijanZulj/blame.nvim',
      lazy = false,
      config = function()
        require('blame').setup({
          date_format = '%Y.%m.%d',
          mappings = {
            commit_info = 'i',
            stack_push = '<TAB>',
            stack_pop = '<BS>',
            show_commit = '<CR>',
            close = { '<esc>', 'q' },
          },
        })
      end,
    },
  },

  install = { colorscheme = { 'solarized' } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
