if [[ $- == *i* ]]; then
  bind '"\e[A": history-search-backward'
  bind '"\e[B": history-search-forward'
fi
export PROMPT_COMMAND='history -a'

git_prompt_info() {
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local branch commit
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)
  commit=$(git rev-parse --short HEAD 2>/dev/null)

  echo " (${branch}@${commit})"
}

export PS1='[\t] \[\033[01;34m\][\h]\[\033[01;32m\]\w\[\033[33m\]$(git_prompt_info)\[\033[0m\]# '

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


export FZF_DEFAULT_OPTS='--bind ctrl-i:half-page-down,ctrl-e:half-page-up,ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' 

f() {
  fzf --preview 'batcat --style=numbers --color=always {}' 
}

# Using g to see current change, g <commit_id> to see the commit change
c() {
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
# gf "def " -e "py" -i "tests" -i ".git"
gf() {
  local pattern=""
  local -a rg_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i)
        [[ $# -lt 2 ]] && { echo "Missing directory after -i"; return 1; }
        rg_args+=(--glob "!**/$2/**")
        shift 2
        ;;
      -e)
        [[ $# -lt 2 ]] && { echo "Missing extension after -e"; return 1; }
        rg_args+=(--glob "*.${2#.}")
        shift 2
        ;;
      *)
        pattern="$1"
        shift
        ;;
    esac
  done

  # No search pattern: browse files
  if [[ -z "$pattern" ]]; then
    rg --files "${rg_args[@]}" | \
    fzf --ansi \
        --preview 'batcat --color=always -- {}' \
        --preview-window 'up,60%,border-bottom' \
        --bind 'enter:become(nvim -- {})'
    return
  fi

  # Search file contents
  rg --line-number --no-heading --color=always --smart-case \
      "${rg_args[@]}" -- "$pattern" | \
  fzf --ansi \
      --color "hl:-1:underline,hl+:-1:underline:bold" \
      --delimiter : \
      --preview 'batcat --color=always --highlight-line {2} {1}' \
      --preview-window 'up,60%,border-bottom,+{2}+3/3' \
      --bind 'enter:become(nvim {1} +{2})'
}




# Using this to sync the ZAI_API_KEY between tmux panel

# __tmux_sync_myvar() {
#  [[ -n "$TMUX" ]] && tmux set -p -t "$TMUX_PANE" @ZAI_API_KEY "$ZAI_API_KEY" 2>/dev/null
# }
# PROMPT_COMMAND="__tmux_sync_myvar${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

# Alway full permission
alias yolo="claude --dangerously-skip-permissions"
alias codex="codex --yolo"

alias vf='vim "$(fzf)"'
alias bat="batcat"


# Alway full permission
alias yolo="claude --dangerously-skip-permissions"
alias codex="codex --yolo"

export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1
export ENABLE_CLAUDEAI_MCP_SERVERS=false

export PATH="$HOME/.local/bin:$PATH"



