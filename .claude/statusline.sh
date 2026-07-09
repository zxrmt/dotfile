#!/usr/bin/env bash
# Claude Code status line: model · reasoning effort · context · 5h limit · weekly limit
# Reads the status JSON from stdin (see https://code.claude.com/docs/en/statusline.md)

input=$(cat)

# --- Extract fields with jq (fall back gracefully when absent) ---
model=$(printf '%s' "$input" | jq -r '.model.display_name // "?"')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')

used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
used_tok=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // empty')
win_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty')

# Usage limits: 5-hour rolling window and 7-day (weekly) window
h5_pct=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
h5_reset=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
wk_pct=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
wk_reset=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- Format context size, e.g. "42.3k/200k (21%)" ---
fmt_k() { # tokens -> "12.3k" / "1.0M"
  awk -v n="$1" 'BEGIN{
    if (n=="" ) { print "?"; exit }
    if (n>=1000000) printf "%.1fM", n/1000000;
    else if (n>=1000) printf "%.1fk", n/1000;
    else printf "%d", n;
  }'
}

if [ -n "$used_tok" ] && [ -n "$win_size" ]; then
  ctx="$(fmt_k "$used_tok")/$(fmt_k "$win_size")"
  if [ -n "$used_pct" ]; then
    pct=$(awk -v p="$used_pct" 'BEGIN{printf "%d", p+0.5}')
    ctx="$ctx (${pct}%)"
  fi
else
  ctx="context n/a"
fi

# --- ANSI colors ---
DIM=$'\033[2m'; RESET=$'\033[0m'
CYAN=$'\033[36m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; RED=$'\033[31m'

# Pick a color for a 0-100 percentage (green < 60 <= yellow < 80 <= red)
pct_color() {
  awk -v p="$1" 'BEGIN{
    p=int(p+0.5);
    if (p>=80) printf "\033[31m";
    else if (p>=60) printf "\033[33m";
    else printf "\033[32m";
  }'
}

# resets_at (epoch seconds, epoch ms, or ISO) -> short "1h12m" / "3d4h" until reset
fmt_reset() {
  local v="$1" now epoch delta
  [ -z "$v" ] && return
  now=$(date +%s)
  if [[ "$v" =~ ^[0-9]+$ ]]; then
    epoch="$v"; [ "${#v}" -ge 13 ] && epoch=$(( v / 1000 ))
  else
    epoch=$(date -d "$v" +%s 2>/dev/null) || return
  fi
  delta=$(( epoch - now ))
  [ "$delta" -lt 0 ] && delta=0
  if   [ "$delta" -ge 86400 ]; then printf '%dd%dh' "$(( delta/86400 ))" "$(( (delta%86400)/3600 ))";
  elif [ "$delta" -ge 3600 ];  then printf '%dh%dm' "$(( delta/3600 ))"  "$(( (delta%3600)/60 ))";
  else printf '%dm' "$(( delta/60 ))"; fi
}

# Color the context by fullness
if [ -n "$used_pct" ]; then
  ctx_color=$(pct_color "$used_pct")
else
  ctx_color="$DIM"
fi

# --- Assemble ---
out="${CYAN}${model}${RESET}"
[ -n "$effort" ] && out="${out} ${DIM}·${RESET} ${YELLOW}${effort}${RESET}"
out="${out} ${DIM}·${RESET} ${ctx_color}${ctx}${RESET}"

# 5-hour limit
if [ -n "$h5_pct" ]; then
  p=$(awk -v p="$h5_pct" 'BEGIN{printf "%d", p+0.5}')
  seg="$(pct_color "$h5_pct")5h ${p}%${RESET}"
  r=$(fmt_reset "$h5_reset"); [ -n "$r" ] && seg="${seg} ${DIM}${r}${RESET}"
  out="${out} ${DIM}·${RESET} ${seg}"
fi

# Weekly (7-day) limit
if [ -n "$wk_pct" ]; then
  p=$(awk -v p="$wk_pct" 'BEGIN{printf "%d", p+0.5}')
  seg="$(pct_color "$wk_pct")wk ${p}%${RESET}"
  r=$(fmt_reset "$wk_reset"); [ -n "$r" ] && seg="${seg} ${DIM}${r}${RESET}"
  out="${out} ${DIM}·${RESET} ${seg}"
fi

printf '%s' "$out"
