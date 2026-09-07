#!/bin/sh
set -eu

terminal="foot"

configs=$(find "$HOME/Projects" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null)
[ -n "$configs" ] || exit 0
chosen=$(printf '%s\n' "$configs" | rofi -dmenu -p 'Projects:')
[ -n "$chosen" ] || exit 0
dir="$HOME/Projects/$chosen"

exec $terminal -e tmux new-session -As "$chosen" -c "$dir"
