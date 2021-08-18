" Plugins {{{

call plug#begin('~/.local/share/nvim/plugged')

Plug 'neovim/nvim-lspconfig'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-lua/completion-nvim'

if executable('node')
	" Completions
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
endif

if executable('global') && executable('ctags')
	Plug 'jsfaint/gen_tags.vim'
endif

Plug 'michaeljsmith/vim-indent-object'

Plug 'tpope/vim-repeat'

Plug 'tpope/vim-dispatch'

Plug 'tpope/vim-eunuch'

" Enhanced terminal integration
Plug 'wincent/terminus'

" insert mode completion of words in adjacent tmux panes
" Plug 'wellle/tmux-complete.vim'
Plug 'wellle/targets.vim'

Plug 'godlygeek/tabular'

Plug 'mrk21/yaml-vim'

Plug 'justinmk/vim-sneak'

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

" Ruby support (plays nicely with tpope/rbenv-ctags)
Plug 'vim-ruby/vim-ruby'

" Browse tags of current file
Plug 'majutsushi/tagbar'

" phpstan integration
Plug 'phpstan/vim-phpstan'

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Vimwiki
Plug 'vimwiki/vimwiki'

" Commenting support (gc)
Plug 'tpope/vim-commentary'

" Unit testing
Plug 'vim-test/vim-test'

" Rspec tests
Plug 'thoughtbot/vim-rspec'

" Javascript support
Plug 'pangloss/vim-javascript'

" JSON Syntax file
Plug 'elzr/vim-json'

" Puppet syntax
Plug 'rodjek/vim-puppet'
Plug 'puppetlabs/puppet-editor-services'

" Show changed lines in the sign column
Plug 'mhinz/vim-signify'

" vim-fugitive
Plug 'tpope/vim-fugitive'

" vim-unimpaired
Plug 'tpope/vim-unimpaired'

" Surround (cs"')
Plug 'tpope/vim-surround'

" Airline
Plug 'vim-airline/vim-airline'

" Devicons for Airline
Plug 'ryanoasis/vim-devicons'

" Gotham theme
Plug 'whatyouhide/vim-gotham'

" One
Plug 'joshdick/onedark.vim'

" Markdown Preview
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }

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
autocmd BufRead,BufNewFile *.md setlocal textwidth=80
" Mediawiki filetype
autocmd BufRead,BufNewFile *.mw set filetype=vimwiki
" a bit annoying since the focus stays on the toc after opening a file
"autocmd FileType markdown Toc

" Disable temporary wiki's so that the vimwiki filetype won't apply to all wiki and md files
let g:vimwiki_global_ext = 0

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

" Open fzf file search
nnoremap <C-F> :Files<CR>

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

"{{{ Completions menu

" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<TAB>"

" Use enter to select highlighted item
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

"}}}

" Coc {{{

let g:coc_global_extensions = [
            \'coc-emmet',
            \'coc-eslint',
            \'coc-git',
            \'coc-highlight',
            \'coc-pairs',
            \'coc-tag',
            \'coc-yank',
            \]

" }}}

"{{{ Undotree

let g:undotree_WindowLayout = 2
nnoremap <F5> :UndotreeToggle<CR>

"}}}

" Sneak {{{

let g:sneak#label = 1

" }}}

" Airline {{{

set noshowmode " The mode is already shown by Airline

let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
" show tab numbers
let g:airline#extensions#tabline#tab_nr_type = 1
" let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#coc#enabled = 1
let g:airline#extensions#gen_tags#enabled = 1
let g:airline#extensions#fzf#enabled = 1
let g:airline#extensions#fugitiveline#enabled = 1
let g:airline#extensions#hunks#enabled = 1
let g:airline#extensions#nvimlsp#enabled = 1

" }}}

" vim-test {{{

" make test commands execute using dispatch.vim
let test#strategy = "dispatch"

" }}}

" {{{ Language Server

lua << EOF
local nvim_lsp = require('lspconfig')
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)

  -- Set some keybinds conditional on server capabilities
  if client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  elseif client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
  end

  -- Set autocommands conditional on server_capabilities
  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec([[
      hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
      hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
      hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]], false)
  end
end

-- Use a loop to conveniently both setup defined servers 
-- and map buffer local keybindings when the language server attaches
local servers = { "bashls", "cssls", "diagnosticls", "dockerls", "html", "intelephense", "jsonls", "pyls", "solargraph", "tsserver", "vimls", "yamlls" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = require'completion'.on_attach }
  --nvim_lsp[lsp].setup { on_attach = on_attach }
end

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
