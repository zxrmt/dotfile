
# bind this key to moving around using arrow key
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
# PROMT show one digit
export PROMPT='%{$fg[green]%}${${:-$(printf "/%.1s" ${(s./.)PWD:h})/${PWD:t}}/\/\///}%{$reset_color%} # '
