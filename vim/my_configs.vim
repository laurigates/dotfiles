let $LANG='en_US.utf8'
let g:syntastic_yaml_checkers = ['yamllint']
nnoremap <F2> gg=GggvG:call puppet#align#AlignHashrockets()<CR>
autocmd FileType python nnoremap <buffer> <F9> :exec '!python3' shellescape(@%, 1)<cr>

# bash-like completion for wildmenu
set wildmode=list:longest
