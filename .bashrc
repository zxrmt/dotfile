if [[ $- == *i* ]]; then
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'
fi
export PROMPT_COMMAND='history -a'

export PS1='[\t] \[\033[01;34m\][\h]\[\033[01;32m\]$(pwd) \[\033[0m\]# '

alias ls='ls --color=auto'
alias ll='ls -lah'
alias l='ls -l'
alias vim=nvim
alias hi="history | grep -E -v '^ *[0-9]+ *h ' | grep "
alias h="history | cut -c 8- | grep -E -v '^ *[0-9]+ *h ' | grep "
#eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Copy file to clipboard
z() {
        printf "\033]52;c;%s\a" "$(base64 < $1 | tr -d '\n')"
}

tmux() {
  command tmux -u "$@"
}
