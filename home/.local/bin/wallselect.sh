#!/bin/sh

WALL_DIR="$HOME/Pictures/Wallpapers"

list_walls() {
    cd "$WALL_DIR" || exit
    for file in *.jpg *.jpeg *.png *.gif; do
        [ -e "$file" ] || continue
        printf '%s\0icon\x1f%s\n' "$file" "$WALL_DIR/$file"
    done
}

set_wallpaper() {
    wall="$1"
    pkill swaybg 2>/dev/null || true
    swaybg -i "$wall" -m fill &
}

CHOICE=$(list_walls | rofi -dmenu -i -p "Wallpaper" \
-theme-str "
    window { width: 65%; height: 80%; }
    listview { columns: 4; lines: 2; spacing: 5px; padding: 5px;}
    element { orientation: vertical; padding: 5px; border-radius: 15px; }
    element-icon { size: 250px; horizontal-align: 0.5; }
")

if [ -n "$CHOICE" ]; then
    WALL="$WALL_DIR/$CHOICE"
    set_wallpaper "$WALL"

    ACCENT=$(
        python3 -c '
from colorthief import ColorThief
import sys

colors = ColorThief(sys.argv[1]).get_palette(color_count=5)
brightest = max(colors, key=lambda c: sum(v*v for v in c))
if sum(brightest) < 180:
    print("#ffffff")
else:
    print("#%02x%02x%02x" % tuple(brightest))
' "$WALL"
    )

    ~/.local/bin/kumin-style.sh "$ACCENT"
fi
