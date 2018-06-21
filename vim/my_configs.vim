let $LANG='en_US.utf8'
let g:syntastic_yaml_checkers = ['yamllint']
nnoremap <F2> :call puppet#align#AlignHashrockets()<CR>
autocmd FileType python nnoremap <buffer> <F9> :exec '!python3' shellescape(@%, 1)<cr>

" bash-like completion for wildmenu
set wildmenu
set wildmode=list:longest

" enable recursive find
set path+=**

" disable vim-go version check warnings
let g:go_version_warning = 0

" more natural split opening
set splitbelow
set splitright

" automatic relative/absolute line numbering
:set number relativenumber
:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
:  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
:augroup END
