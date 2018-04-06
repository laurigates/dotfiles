let $LANG='en_US.utf8'
let g:syntastic_yaml_checkers = ['yamllint']
nnoremap <F2> gg=GggvG:call puppet#align#AlignHashrockets()<CR>

# bash-like completion for wildmenu
set wildmode=list:longest
