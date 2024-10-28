export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
export PROMPT='%{$fg[green]%}${${:-$(printf "/%.1s" ${(s./.)PWD:h})/${PWD:t}}/\/\///}%{$reset_color%} # '
