#!/bin/sh
set -eu

spawn() { ( "$@" & ) >/dev/null 2>&1; }

if [ $# -eq 0 ]; then
  cat <<EOF
󰸉  Change Wallpaper
  Change Theme (Font/Size/Color)
EOF
    exit 0
fi

chosen="$*"
case "$chosen" in
    *"Change Wallpaper"*) spawn ~/.local/bin/wallselect.sh ;;
    *"Change Theme"*) spawn ~/.local/bin/changetheme.sh ;;
esac
