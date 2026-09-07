#!/bin/sh
set -eu

sessions=$(tmux list-sessions -F '#S' 2>/dev/null || true)
[ -n "${sessions}" ] || exit 0

chosen=$(printf '%s\n' "$sessions" | rofi -dmenu -i -p 'tmux sessions:' -lines 10 \
    -kb-row-down "Down,Control+n,j" -kb-row-up "Up,Control+p,k")

[ -n "$chosen" ] || exit 0

if [ "${TMUX-}" ]; then
    exec tmux switch-client -t "${chosen}"
fi

exec foot -e tmux attach -t "${chosen}"
