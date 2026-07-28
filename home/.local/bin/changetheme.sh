#!/bin/sh
set -eu

STATE_DIR="$HOME/.local/state/kumin_theme"
GEN="$HOME/.local/bin/gen-style.sh"
APPLY="$HOME/.local/bin/apply-style.sh"

mkdir -p "$STATE_DIR"

get_current_accent() {
    accent="#ffffff"
    if [ -f "$STATE_DIR/colors.css" ]; then
        parsed=$(sed -nE 's/^\s*@define-color\s+accent_color\s+(#[0-9a-fA-F]{6})\s*;.*$/\1/p' "$STATE_DIR/colors.css" | head -n1)
        [ -n "${parsed:-}" ] && accent="$parsed"
    fi
    printf '%s\n' "$accent"
}

get_current_size() {
    size="16"
    if [ -f "$STATE_DIR/fonts.css" ]; then
        parsed=$(sed -nE 's/^\s*font-size:\s*([0-9]+)px\s*;.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1)
        [ -n "${parsed:-}" ] && size="$parsed"
    fi
    printf '%s\n' "$size"
}

get_current_font() {
    font="monospace"
    if [ -f "$STATE_DIR/fonts.css" ]; then
        parsed=$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1)
        [ -n "${parsed:-}" ] && font="$parsed"
    fi
    printf '%s\n' "$font"
}

ACCENT=$(get_current_accent)
FONT_FAMILY=$(get_current_font)
FONT_SIZE=$(get_current_size)

choice=$(cat <<EOF | rofi -dmenu -p "Change Theme - Choose an option:" -i
  Change font
  Change font size
  Change color
EOF
)
[ -z "${choice:-}" ] && exit 0

case "$choice" in
    "  Change font")
        fonts=$(fc-list : family 2>/dev/null | sed 's/,.*//' | sort -u || true)
        [ -z "$fonts" ] && { echo "No fonts found via fc-list" >&2; exit 1; }
        new_font=$(printf '%s\n' "$fonts" | rofi -dmenu -p "  Current: ${FONT_FAMILY}" -i)
        [ -z "${new_font:-}" ] && exit 0
        FONT_FAMILY="$new_font"
        ;;

    "  Change font size")
        new_size=$(printf '%s\n' "$FONT_SIZE" | rofi -dmenu -p "  Current: ${FONT_SIZE}px" -theme-str 'entry { placeholder: "Type font size here"; }' -i)
        [ -z "${new_size:-}" ] && exit 0
        case "$new_size" in
            *[!0-9]*) exit 0 ;;
        esac
        FONT_SIZE="$new_size"
        ;;

    "  Change color")
        accent_choice=$(cat <<'EOF' | rofi -dmenu -p "  Current: ${ACCENT}" -theme-str 'entry { placeholder: "Type hex color here #xxxxxx"; }' -i
Slate Blue   #7288AE
Green        #A2CB8B
Peach        #FFB399
Yellow       #efbf04
Pink         #F9B2D7
White        #ffffff
Grey         #BFC9D1
Custom       (type hex in prompt)
EOF
        )
        [ -z "${accent_choice:-}" ] && exit 0

        case "$accent_choice" in
            *"Custom       (type hex in prompt)")
                custom_hex=$(printf '%s\n' "$ACCENT" | rofi -dmenu -p "Hex (#RRGGBB)" -theme-str 'entry { placeholder: "Type hex color here #xxxxxx"; }' -i)
                [ -z "${custom_hex:-}" ] && exit 0
                custom_hex=$(printf '%s' "$custom_hex" | tr -cd '#0-9a-fA-F')
                h='#'
                case "$custom_hex" in
                    ${h}[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;;
                    *) exit 0 ;;
                esac
                ACCENT="$custom_hex"
                ;;
            *)
                picked_hex=$(printf '%s\n' "$accent_choice" | grep -oE '#[0-9a-fA-F]{6}' | head -n1)
                [ -n "$picked_hex" ] && ACCENT="$picked_hex"
                ;;
        esac
        ;;
esac

"$GEN" "$ACCENT" "$FONT_FAMILY" "$FONT_SIZE"
"$APPLY"
