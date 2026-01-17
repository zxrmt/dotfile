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



export FZF_DEFAULT_OPTS='--bind ctrl-i:half-page-down,ctrl-e:half-page-up,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' 

f() {
  fzf --preview 'batcat --style=numbers --color=always {}' 
}

# Using g to see current change, g <commit_id> to see the commit change
g() {
  if [ $# -eq 0 ]; then
    # Unstaged changes
    git diff --name-only |
      fzf --ansi \
          --preview 'git diff --color=always -- {}'
  elif [ $# -eq 1 ]; then
    # One commit only
    local commit="$1"
    git show --pretty="" --name-only "$commit" |
      fzf --ansi \
          --preview "git show --color=always '$commit' -- {}"
  else
    echo "usage: fp [commit-ish]" >&2
    return 2
  fi
}

# Using this to sync the ZAI_API_KEY between tmux panel

# __tmux_sync_myvar() {
#  [[ -n "$TMUX" ]] && tmux set -p -t "$TMUX_PANE" @ZAI_API_KEY "$ZAI_API_KEY" 2>/dev/null
# }
# PROMPT_COMMAND="__tmux_sync_myvar${PROMPT_COMMAND:+;$PROMPT_COMMAND}"



