#!/bin/bash
set -euo pipefail
spawn() { ( "$@" & ) >/dev/null 2>&1; disown; }

if [[ $# -eq 0 ]]; then
    WALL_STATUS=$(cat "/tmp/random_wallpaper_status" 2>/dev/null || echo "0")
    WALL_TEXT="OFF"
    [[ "$WALL_STATUS" == "1" ]] && WALL_TEXT="ON"

  cat <<EOF
󰁪  Auto Random Wallpaper ($WALL_TEXT)
󰸉  Change Wallpaper
  Change Lively Wallpaper
󰃾  Kill Lively Wallpaper
  Change Theme (Font/Size/Color)
EOF
    exit 0
fi

chosen="$*"
case "$chosen" in
    *"Auto Random Wallpaper"*) spawn ~/.local/bin/random_wallpaper.sh --toggle ;;
    *"Change Wallpaper"*) spawn ~/.local/bin/wallselect.sh ;;
    *"Change Lively Wallpaper"*) spawn ~/.local/bin/wallmpvselect.sh ;;
    *"Kill Lively Wallpaper"*) spawn ~/.local/bin/wallmpvselect.sh --exit ;;
    *"Change Theme"*) spawn ~/.local/bin/changetheme.sh ;;
esac

exit 0
