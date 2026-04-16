#!/bin/sh
# Claude Code status line — mirrors Starship config (dir + git + model)
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Truncate directory: show up to 4 path components, shorten home to ~
home="$HOME"
short_dir="${cwd/#$home/\~}"
# Keep last 4 components
dir=$(echo "$short_dir" | awk -F/ '{
  n=NF; if(n<=4) {print $0} else {
    out=""; for(i=n-3;i<=n;i++) out=(i==n-3?$i:out"/"$i); print "..."out
  }
}')

# Git branch + status (skip optional locks)
branch=""
status_str=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  staged=$(git -C "$cwd" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git -C "$cwd" diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
  ahead=$(git -C "$cwd" rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  behind=$(git -C "$cwd" rev-list HEAD..@{u} 2>/dev/null | wc -l | tr -d ' ')
  [ "$staged" -gt 0 ]    && status_str="$status_str +$staged"
  [ "$modified" -gt 0 ]  && status_str="$status_str !$modified"
  [ "$untracked" -gt 0 ] && status_str="$status_str ?$untracked"
  [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ] && status_str="$status_str ⇡${ahead}⇣${behind}"
  [ "$ahead" -gt 0 ] && [ "$behind" -eq 0 ] && status_str="$status_str ⇡$ahead"
  [ "$behind" -gt 0 ] && [ "$ahead" -eq 0 ] && status_str="$status_str ⇣$behind"
fi

# Build output
out="$dir"
[ -n "$branch" ] && out="$out  $branch$status_str"
out="$out  $model"
[ -n "$ctx" ] && out="$out (ctx: $(printf '%.0f' "$ctx")%)"

printf '%s' "$out"
