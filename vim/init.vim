" Plugins {{{

call plug#begin('~/.local/share/nvim/plugged')

if has('nvim')
    Plug 'neovim/nvim-lspconfig'
    Plug 'nvim-treesitter/nvim-treesitter'

    if executable('node')
        " Completions
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
    endif

    if executable('global') && executable('ctags')
        Plug 'jsfaint/gen_tags.vim'
    endif
endif

Plug 'michaeljsmith/vim-indent-object'

Plug 'tpope/vim-repeat'

Plug 'tpope/vim-dispatch'

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

" Sets how many lines of history VIM has to remember
set history=500

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","

" Fast saving
nmap <leader>w :w!<cr>

" :W sudo saves the file
" (useful for handling the permission-denied error)
" command W w !sudo tee % > /dev/null

" https://www.johnhawthorn.com/2012/09/vi-escape-delays/
set timeout ttimeout         " separate mapping and keycode timeouts
set timeoutlen=500           " mapping timeout 500ms  (adjust for preference)
set ttimeoutlen=20           " keycode timeout 20ms

" No annoying sound on errors
" set noerrorbells
" set novisualbell

set wildmenu " Enhanced command line completion
" https://www.reddit.com/r/vim/comments/8mi8cm/is_using_in_path_a_good_idea/
" set path+=** " enable recursive find

set ignorecase " Ignore case when searching
set smartcase " When searching try to be smart about cases
set hlsearch " Highlight search results
set incsearch " Makes search act like search in modern browsers

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

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
" Prevent moving the cursor when changing focus to vim
" augroup NO_CURSOR_MOVE_ON_FOCUS
"   au!
"   au FocusLost * let g:oldmouse=&mouse | set mouse=
"   au FocusGained * if exists('g:oldmouse') | let &mouse=g:oldmouse | unlet g:oldmouse | endif
" augroup END

" Smart way to move between windows
map <C-j> <C-W>j
" Doesn't work at the moment because nvim-lsp replaces C-k mapping
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Return to last edit position when opening files (You want this!)
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
set smarttab " Be smart when using tabs
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

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
set so=12

" more natural split opening
set splitbelow
set splitright

if (has('nvim'))
    set inccommand=nosplit " Live preview of substitution results
endif

" automatic relative/absolute line numbering
set number relativenumber
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

" Ignore compiled files
set wildignore=*.o,*~,*.pyc
if has("win16") || has("win32")
    set wildignore+=.git\*,.hg\*,.svn\*
else
    set wildignore+=*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store
endif

set ruler "Always show current position
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

" }}}

" Colors and Fonts {{{

syntax enable " Enable syntax highlighting

" Color scheme
" set Vim-specific sequences for RGB colors
set t_Co=256

if exists('&t_8f') && exists('&t_8b')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif

if exists('&termguicolors')
    set termguicolors
endif

set background=dark
let g:onedark_terminal_italics=1
silent! colorscheme onedark

set encoding=utf8 " Set utf8 as standard encoding and en_US as the standard language
set ffs=unix,dos,mac " Use Unix as the standard file type
set listchars=eol:↲,tab:»\ ,extends:›,precedes:‹,nbsp:‡,trail:·

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

" }}}

" {{{ Language Server
"  vim-test

" make test commands execute using dispatch.vim
let test#strategy = "dispatch"

nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>

lua <<EOF
local lspconfig = require'lspconfig'
local configs = require'lspconfig/configs'

lspconfig.bashls.setup{}
lspconfig.cssls.setup{}
lspconfig.diagnosticls.setup{}
lspconfig.dockerls.setup{}
lspconfig.html.setup{}
lspconfig.intelephense.setup{}
lspconfig.jsonls.setup{}
lspconfig.pyls.setup{}
lspconfig.solargraph.setup{}
lspconfig.tsserver.setup{}
lspconfig.vimls.setup{}
lspconfig.yamlls.setup{}
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

" vim: fdm=marker foldlevel=0
