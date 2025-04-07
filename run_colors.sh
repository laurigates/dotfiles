#!/bin/sh
awk -v term_cols="${width:-$(tput cols)}" 'BEGIN{
    s="  ";
    for (colnum = 0; colnum<term_cols; colnum++) {
        r = 255-(colnum*255/term_cols);
        g = (colnum*510/term_cols);
        b = (colnum*255/term_cols);
        if (g>255) g = 510-g;
        printf "\033[48;2;%d;%d;%dm", r,g,b;
        printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "%s\033[0m", substr(s,colnum%2+1,1);
    }
    printf "\033[1mbold\033[0m\n";
    printf "\033[3mitalic\033[0m\n";
    printf "\033[3m\033[1mbold italic\033[0m\n";
    printf "\033[4munderline\033[0m\n";
    printf "\033[9mstrikethrough\033[0m\n";
    printf "\033[31mred text\033[0m\n";
}'
