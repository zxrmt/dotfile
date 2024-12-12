if [[ $- == *i* ]]
then
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi
export PROMPT_COMMAND='history -a'
export PS1='\[\033[01;32m\]$(pwd) \[\033[0m\]# '
