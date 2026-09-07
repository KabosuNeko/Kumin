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
    printf '%s' "$WALL" > "$HOME/.local/state/kumin_theme/wallpaper"

    ACCENT=$(
        python3 -c '
from colorthief import ColorThief
import colorsys
import sys

def pick_accent(wall):
    ct = ColorThief(wall)
    palette = ct.get_palette(color_count=9)
    scored = []
    for rgb in palette:
        r, g, b = [x / 255.0 for x in rgb]
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        
        # Penalize colors that are too dark for dark-themed UI
        v_factor = 1.0 if v >= 0.55 else (v / 0.55) ** 2
        # Prefer saturated, distinct colors over washed out grey/white
        s_factor = s if s >= 0.15 else (s / 0.15 * 0.3)
        score = s_factor * 1.5 + v * v_factor
        scored.append((score, s, v, rgb))
        
    scored.sort(key=lambda x: x[0], reverse=True)
    best_score, s, v, best_rgb = scored[0]
    
    # If the wallpaper is completely black & white / monochrome
    if s < 0.10:
        brightest = max(palette, key=lambda c: sum(c))
        return "#%02x%02x%02x" % tuple(brightest)
        
    # Ensure minimum luminance for dark background contrast
    r, g, b = [x / 255.0 for x in best_rgb]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    if v < 0.65:
        v = 0.75
        r, g, b = colorsys.hsv_to_rgb(h, s, v)
        best_rgb = (int(r * 255), int(g * 255), int(b * 255))
        
    return "#%02x%02x%02x" % tuple(best_rgb)

print(pick_accent(sys.argv[1]))
' "$WALL"
    )

    ~/.local/bin/kumin-theme.sh --accent "$ACCENT"
fi
