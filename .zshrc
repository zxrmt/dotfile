export ZSH="$HOME/.oh-my-zsh"



bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
export PROMPT='%{$fg[green]%}${${:-$(printf "/%.1s" ${(s./.)PWD:h})/${PWD:t}}/\/\///}%{$reset_color%} # '


ssh() {
  local target=""
  # Find the first argument that isn't an option flag (like -p or -i)
  for arg in "$@"; do
    if [[ "$arg" != -* ]]; then
      target="$arg"
      break
    fi
  done

  # Save it to ~/.ssh/fzf_hosts if it's not already there
  if [ -n "$target" ]; then
    touch ~/.ssh/fzf_hosts
    grep -qxF "$target" ~/.ssh/fzf_hosts 2>/dev/null || echo "$target" >> ~/.ssh/fzf_hosts
  fi

  # Run the actual system ssh command
  command ssh "$@"
}

fsh() {
  local selected host
  selected=$(
    {
      # Read fzf_hosts, ignoring empty lines and lines starting with #
      [ -f ~/.ssh/fzf_hosts ] && grep -vE '^[[:space:]]*(#|$)' ~/.ssh/fzf_hosts
      [ -f ~/.ssh/config ] && awk '$1=="Host" {print $2}' ~/.ssh/config
    } | grep -vE '^\*|^\-' | sort -u | fzf
  )

  if [ -n "$selected" ]; then
    # Extract only the first column (the host/user@host), stripping out any trailing # comments
    host=$(echo "$selected" | awk '{print $1}')
    ssh "$host"
  fi
}
