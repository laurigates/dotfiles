call plug#begin('~/.local/share/nvim/plugged')
" Yank stack
Plug 'maxbrunsfeld/vim-yankstack'

Plug 'michaeljsmith/vim-indent-object'

Plug 'tpope/vim-repeat'

" Enhanced terminal integration
Plug 'wincent/terminus'

" insert mode completion of words in adjacent tmux panes
" Plug 'wellle/tmux-complete.vim'
Plug 'wellle/targets.vim'

" Insert or delete brackets, parens, quotes in pair.
" Plug 'jiangmiao/auto-pairs'

Plug 'godlygeek/tabular'
" markdown plugin is currently broken, folds open and close randomly on other actions
" Plug 'plasticboy/vim-markdown'
Plug 'mrk21/yaml-vim'

" vim-easymotion
" Plug 'easymotion/vim-easymotion'

" snipmate dependencies
Plug 'tomtom/tlib_vim'
Plug 'marcweber/vim-addon-mw-utils'
Plug 'garbas/vim-snipmate'
Plug 'honza/vim-snippets'

if has('nvim')
" LanguageClient-neovim
Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }

Plug 'roxma/nvim-yarp'

" NCM2
Plug 'ncm2/ncm2'
Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-tmux'
Plug 'ncm2/ncm2-path'
Plug 'ncm2/ncm2-jedi'
Plug 'ncm2/ncm2-tern',  {'do': 'npm install'}
Plug 'ncm2/ncm2-cssomni'
Plug 'ncm2/ncm2-vim' | Plug 'Shougo/neco-vim'
Plug 'ncm2/ncm2-snipmate'
Plug 'ncm2/ncm2-html-subscope'
Plug 'ncm2/ncm2-tagprefix'
Plug 'jsfaint/gen_tags.vim'
" Dictionary completion
Plug 'filipekiss/ncm2-look.vim'

" PHP
Plug 'roxma/LanguageServer-php-neovim',  {'do': 'composer install && composer run-script parse-stubs'}

" vim-lsp
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'

" ncm2-vim-lsp
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'ncm2/ncm2-vim-lsp'

" asyncomplete
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" Include Phpactor
Plug 'phpactor/phpactor' ,  {'do': 'composer install', 'for': 'php'}
Plug 'phpactor/ncm2-phpactor'
endif

" Plugin outside ~/.vim/plugged with post-update hook
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" Run ack in vim
" Plug 'mileszs/ack.vim'

" Vimwiki
Plug 'vimwiki/vimwiki'

" Commenting support (gc)
Plug 'tpope/vim-commentary'

" Unit testing
Plug 'janko/vim-test'

" Ruby support (plays nicely with tpope/rbenv-ctags)
Plug 'vim-ruby/vim-ruby'

" Javascript support
Plug 'pangloss/vim-javascript'

" JSON Syntax file
Plug 'elzr/vim-json'

" Puppet syntax
Plug 'rodjek/vim-puppet'

" Git changes shown on line numbers
Plug 'airblade/vim-gitgutter'

" vim-fugitive
Plug 'tpope/vim-fugitive'

" vim-unimpaired
Plug 'tpope/vim-unimpaired'

" Browse tags of current file
Plug 'majutsushi/tagbar'

" Surround (cs"')
Plug 'tpope/vim-surround'

" Airline
Plug 'vim-airline/vim-airline'

" Gotham theme
Plug 'whatyouhide/vim-gotham'

" One
Plug 'joshdick/onedark.vim'

" Markdown Preview
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() } }

call plug#end()

set nocompatible

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""
" vim-unimpaired
"""""""""""""""""""""""""""""""""""
" nmap < [
" nmap > ]
" omap < [
" omap > ]
" xmap < [
" xmap > ]

"""""""""""""""""""""""""""""""""""
" LanguageClient & LanguageServer
"""""""""""""""""""""""""""""""""""
" Required for operations modifying multiple buffers like rename.
set hidden

if has('nvim')
" Automatically start language servers.
let g:LanguageClient_autoStart = 1
nnoremap <F5> :call LanguageClient_contextMenu()<CR>

let g:lsp_signs_enabled = 1         " enable signs
let g:lsp_diagnostics_echo_cursor = 1 " enable echo under cursor when in normal mode

" Register javascript language server
let g:LanguageClient_serverCommands = {
    \'javascript': ['javascript-typescript-stdio'],
    \'python': ['pyls']
    \}
endif

"""""""""""""""""""""""""""""""""""
" NCM2
"""""""""""""""""""""""""""""""""""
if has('nvim')
" enable ncm2 for all buffers
autocmd BufEnter * call ncm2#enable_for_buffer()

" IMPORTANTE: :help Ncm2PopupOpen for more information
set completeopt=noinsert,menuone,noselect
endif

" suppress the annoying 'match x of y', 'The only match' and 'Pattern not
" found' messages
set shortmess+=c

" Use <TAB> to select the popup menu:
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

"""""""""""""""""""""""""""""""""""
" fzf
"""""""""""""""""""""""""""""""""""
" Disable mappings that override fzf mapping
" let g:comfortable_motion_no_default_key_mappings = 1

" Open fzf file search
nnoremap <C-F> :Files<CR>

"""""""""""""""""""""""""""""""""""
" Airline
"""""""""""""""""""""""""""""""""""
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
" show tab numbers
let g:airline#extensions#tabline#tab_nr_type = 1
" let g:airline#extensions#tabline#buffer_nr_show = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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

" Integrate vim clipboard with system clipboard
" set clipboard+=unnamedplus

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => FileType autocmds
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
" a bit annoying since the focus stays on the toc after opening a file
"autocmd FileType markdown Toc

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => VIM user interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set 12 lines to the cursor - when moving vertically using j/k
set so=12

" let $LANG='en_US.utf8'

" set langmenu=en

" more natural split opening
set splitbelow
set splitright

" Turn on the Wild menu
set wildmenu

" enable recursive find
set path+=**

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

"Always show current position
set ruler

" Height of the command bar
set cmdheight=2

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases 
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch 

" Don't redraw while executing macros (good performance config)
set lazyredraw 

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch 
" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

set noshowmode

" Add a bit extra margin to the left
" set foldcolumn=1

" Vertical diff in Gdiff
set diffopt+=vertical

" Markdown display options
" let g:vim_markdown_folding_level = 2
" let g:vim_markdown_toc_autofit = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable syntax highlighting
syntax enable 

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
colorscheme onedark

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

set listchars=eol:↲,tab:»\ ,extends:›,precedes:‹,nbsp:‡,trail:·
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile

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
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

" Let 'tl' toggle between this and the last accessed tab
let g:lasttab = 1
nmap <Leader>tl :exe "tabn ".g:lasttab<CR>
au TabLeave * let g:lasttab = tabpagenr()

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

""""""""""""""""""""""""""""""
" => Status line
""""""""""""""""""""""""""""""
" Always show the status line
set laststatus=2

" Format the status line
"set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Turn persistent undo on 
"    means that you can undo even when you close a buffer/VIM
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
try
    set undodir=~/.vim/temp_dirs/undodir
    set undofile
catch
endtry

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Command mode related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Bash like keys for the command line
cnoremap <C-A> <Home>
cnoremap <C-E> <End>
cnoremap <C-K> <C-U>

cnoremap <C-P> <Up>
cnoremap <C-N> <Down>

" Map ½ to something useful
map § $
cmap § $
imap § $
