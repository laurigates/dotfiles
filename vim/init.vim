" Plugins {{{

call plug#begin('~/.local/share/nvim/plugged')

Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Completion
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-nvim-lua'
Plug 'saadparwaiz1/cmp_luasnip'

Plug 'L3MON4D3/LuaSnip'

if executable('global') && executable('ctags')
	Plug 'jsfaint/gen_tags.vim'
endif

Plug 'michaeljsmith/vim-indent-object'

Plug 'tpope/vim-repeat'

" Plug 'tpope/vim-dispatch'

Plug 'tpope/vim-eunuch'

" Enhanced terminal integration
Plug 'wincent/terminus'

" insert mode completion of words in adjacent tmux panes
" Plug 'wellle/tmux-complete.vim'
Plug 'wellle/targets.vim'

Plug 'godlygeek/tabular'

" Plug 'mrk21/yaml-vim'

Plug 'justinmk/vim-sneak'

" Ruby support (plays nicely with tpope/rbenv-ctags)
" Plug 'vim-ruby/vim-ruby'

" Browse tags of current file
" Plug 'majutsushi/tagbar'

" phpstan integration
" Plug 'phpstan/vim-phpstan'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" Commenting support (gc)
Plug 'tpope/vim-commentary'

" Unit testing
" Plug 'vim-test/vim-test'

" Rspec tests
" Plug 'thoughtbot/vim-rspec'

" Javascript support
" Plug 'pangloss/vim-javascript'

" JSON Syntax file
" Plug 'elzr/vim-json'

" Puppet syntax
" Plug 'rodjek/vim-puppet'
" Plug 'puppetlabs/puppet-editor-services'

" Show changed lines in the sign column
Plug 'mhinz/vim-signify'

" vim-fugitive
Plug 'tpope/vim-fugitive'

" vim-unimpaired
Plug 'tpope/vim-unimpaired'

" Surround (cs"')
Plug 'tpope/vim-surround'

Plug 'nvim-lualine/lualine.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'SmiteshP/nvim-gps'

" One
Plug 'joshdick/onedark.vim'

" Markdown Preview
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }

Plug 'mbbill/undotree'

call plug#end()

set nocompatible

" }}}

" General {{{

" Space is a convenient leader map
let mapleader = " "
imap jj <Esc>

set timeoutlen=500 " mapping timeout 500ms  (adjust for preference)
set ttimeoutlen=20 " keycode timeout 20ms

set ignorecase " Ignore case when searching
set smartcase " When searching try to be smart about cases

" Don't redraw while executing macros (good performance config)
set lazyredraw

" }}}

" File types {{{

" autocmd BufRead,BufNewFile *.eyaml set filetype=yaml
" autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType terraform setlocal ts=2 sts=2 sw=2 expandtab
autocmd BufRead,BufNewFile *.md setlocal textwidth=80
" a bit annoying since the focus stays on the toc after opening a file
"autocmd FileType markdown Toc

" }}}

" Files, backups and undo {{{

" Turn off backup
set nobackup
set nowritebackup
set noswapfile

" Hide buffers instead of closing them.
" This means that you can have unwritten changes to a file and open a new file using :e,
" without being forced to write or undo your changes first.
" Undo buffers and marks are preserved while the buffer is open.
set hidden

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Moving around, tabs, windows and buffers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Smart way to move between windows
map <C-j> <C-W>j
" Doesn't work at the moment because nvim-lsp replaces C-k mapping
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Return to last edit position when opening files
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Turn persistent undo on
" means that you can undo even when you close a buffer/VIM
try
    set undodir=~/.vim/temp_dirs/undodir
    set undofile
catch
endtry

" }}}

" Text, tab and indent related {{{

set expandtab " Use spaces instead of tabs

" Linebreak on 500 characters
" set lbr
" set tw=500

" highlight Whitespace ctermbg=darkred guibg=darkred
" highlight NonText ctermfg=153 guifg=lightskyblue

" Make extra whitespaces clearly visible
highlight ExtraWhitespace ctermbg=darkred guibg=darkred
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" }}}

" Appearance {{{

" Set 12 lines to the cursor - when moving vertically using j/k
set scrolloff=12

" more natural split opening
set splitbelow
set splitright

set inccommand=nosplit " Live preview of substitution results

" automatic relative/absolute line numbering
set number relativenumber
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

set showmatch " Show matching brackets when text indicator is over them
set mat=2 " How many tenths of a second to blink when matching brackets
set diffopt+=vertical,iwhite,algorithm:patience,hiddenoff

" Transparency for completion menu
if exists('pumblend')
    set pumblend=10
endif

set cmdheight=2 " Better display for messages
set updatetime=300 " You will have bad experience for diagnostic messages when it's default 4000.
set shortmess+=c " don't give |ins-completion-menu| messages.
set signcolumn=yes " always show signcolumns
set completeopt=menuone,noinsert,noselect

" }}}

" Colors and Fonts {{{

set termguicolors

set background=dark
let g:onedark_terminal_italics=1
silent! colorscheme onedark

set encoding=utf8 " Set utf8 as standard encoding and en_US as the standard language
set ffs=unix,dos,mac " Use Unix as the standard file type
set listchars=eol:↲,tab:»\ ,extends:›,precedes:‹,nbsp:☠,trail:·

" }}}

" Terminal mode {{{

" Escape terminal mode using Esc
" This could be improved. It currently breaks exiting the fzf-tmux window
tnoremap <Esc> <C-\><C-n>

" }}}

" Command mode related {{{

" Bash like keys for the command line
cnoremap <C-A> <Home>
cnoremap <C-E> <End>
cnoremap <C-K> <C-U>

cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

map § ^
cmap § ^
imap § ^
map ½ $
cmap ½ $
imap ½ $

" " RSpec.vim mappings
" map <Leader>t :call RunCurrentSpecFile()<CR>
" map <Leader>s :call RunNearestSpec()<CR>
" map <Leader>l :call RunLastSpec()<CR>
" map <Leader>a :call RunAllSpecs()<CR>

" }}}

"{{{ Undotree

let g:undotree_WindowLayout = 2
nnoremap <F5> :UndotreeToggle<CR>

"}}}

" Sneak {{{

let g:sneak#label = 1

" }}}

" vim-test {{{

" make test commands execute using dispatch.vim
let test#strategy = "dispatch"

" }}}

" Telescope {{{
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
" }}}

" {{{ Language Server

lua << EOF
-- Telescope
require('telescope').setup {
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  }
}
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')

-- nvim-gps
require("nvim-gps").setup()
local gps = require("nvim-gps")

require("lualine").setup({
sections = {
        lualine_c = {
                { gps.get_location, cond = gps.is_available },
                }
        }
})
-- https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
--vim.lsp.set_log_level("debug")
--Remap space as leader key
vim.api.nvim_set_keymap('', '<Space>', '<Nop>', { noremap = true, silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Diagnostic keymaps
vim.api.nvim_set_keymap('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float(0, { scope = "line" })<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', { noremap = true, silent = true })

-- LSP settings
local lspconfig = require 'lspconfig'
local on_attach = function(_, bufnr)
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>so', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]], opts)
  vim.cmd [[ command! Format execute 'lua vim.lsp.buf.formatting()' ]]
end

-- nvim-cmp supports additional completion capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

-- Enable the following language servers
local servers = { "bashls", "diagnosticls", "dockerls", "yamlls", "jsonls", "tsserver", "terraformls" }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- https://github.com/hrsh7th/nvim-cmp
-- https://github.com/neovim/nvim-lspconfig/wiki/Autocompletion
-- Setup nvim-cmp.
local cmp = require 'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = {
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = 'nvim_lua' },
    { name = 'nvim_lsp' },
    { name = 'path' },
    { name = 'luasnip' },
    { name = 'buffer', keyword_length = 5 },
  }
})

require'nvim-treesitter.configs'.setup {
  ensure_installed = "maintained",
  highlight = {
    enable = true
  },
  indent = {
    enable = true
  }
}
EOF

" }}}

"{{{ Scripts
" https://benjamincongdon.me/blog/2020/06/27/Vim-Tip-Paste-Markdown-Link-with-Automatic-Title-Fetching/
" https://vim.fandom.com/wiki/Make_an_HTML_anchor_and_href_tag
" https://stackoverflow.com/questions/1115447/how-can-i-get-the-word-under-the-cursor-and-the-text-of-the-current-line-in-vim
function! GetURLTitle(url)
    let html = system('wget -q -O - ' . shellescape(a:url))
    let regex = '\c.*head.*<title[^>]*>\_s*\zs.\{-}\ze\_s*<\/title>'
    let title = substitute(matchstr(html, regex), "\n", ' ', 'g')
    return title
endfunction

function! PasteMDLink()
    let url = getreg("+")
    " let url = expand("<cWORD>")
    let title = GetURLTitle(url)
    put = printf('[%s](%s)', title, url)
    " exe '%s/\<' . url . '\>/' . printf('[%s](%s)', title, url)
endfunction

" Make a keybinding (mnemonic: "mark down paste")
nmap <Leader>mdp :call PasteMDLink()<cr>

"}}}
" vim: fdm=marker foldlevel=0
