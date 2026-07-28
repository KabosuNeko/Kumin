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

def brightness(c):
    return sum(v*v for v in c)

colors = ColorThief(sys.argv[1]).get_palette(color_count=5)
brightest = max(colors, key=brightness)
print("#%02x%02x%02x" % brightest)
' "$WALL"
    )

    r=$(printf "%d" 0x"$(printf '%s' "$ACCENT" | cut -c2-3)")
    g=$(printf "%d" 0x"$(printf '%s' "$ACCENT" | cut -c4-5)")
    b=$(printf "%d" 0x"$(printf '%s' "$ACCENT" | cut -c6-7)")
    if [ $((r + g + b)) -lt 180 ]; then
        ACCENT="#ffffff"
    fi

    ~/.local/bin/kumin-style.sh "$ACCENT"
fi
