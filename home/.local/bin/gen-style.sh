#!/bin/sh
set -eu

STATE_DIR="$HOME/.local/state/kumin_theme"
mkdir -p "$STATE_DIR"

DEFAULT_ACCENT="#ffffff"
DEFAULT_FONT="monospace"
DEFAULT_SIZE="16"

ACCENT_COLOR="${ACCENT_COLOR:-$DEFAULT_ACCENT}"
FONT_FAMILY="${FONT_FAMILY:-$DEFAULT_FONT}"
FONT_SIZE="${FONT_SIZE:-$DEFAULT_SIZE}"

FONT_PROVIDED=false
SIZE_PROVIDED=false

if [ $# -ge 1 ] && [ "${1#-}" = "$1" ]; then ACCENT_COLOR="$1"; shift; fi
if [ $# -ge 1 ] && [ "${1#-}" = "$1" ]; then FONT_FAMILY="$1"; FONT_PROVIDED=true; shift; fi
if [ $# -ge 1 ] && [ "${1#-}" = "$1" ]; then FONT_SIZE="$1"; SIZE_PROVIDED=true; shift; fi

while [ $# -gt 0 ]; do
    case "$1" in
        --accent|-a) ACCENT_COLOR="${2:?missing value for --accent}"; shift 2 ;;
        --font|-f)   FONT_FAMILY="${2:?missing value for --font}"; FONT_PROVIDED=true; shift 2 ;;
        --size|-s)   FONT_SIZE="${2:?missing value for --size}"; SIZE_PROVIDED=true; shift 2 ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

if [ "$FONT_PROVIDED" = false ] && [ -f "$STATE_DIR/fonts.css" ]; then
    parsed_font=$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1)
    [ -n "$parsed_font" ] && FONT_FAMILY="$parsed_font"
fi

if [ "$SIZE_PROVIDED" = false ] && [ -f "$STATE_DIR/fonts.css" ]; then
    parsed_size=$(sed -nE 's/^\s*font-size:\s*([0-9]+)px.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1)
    [ -n "$parsed_size" ] && FONT_SIZE="$parsed_size"
fi

ACCENT_COLOR=$(printf '%s' "$ACCENT_COLOR" | tr -cd '#0-9a-fA-F')
h='#'
case "$ACCENT_COLOR" in
    ${h}[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;;
    *) ACCENT_COLOR="$DEFAULT_ACCENT" ;;
esac

case "$FONT_SIZE" in
    *[!0-9]*) FONT_SIZE="$DEFAULT_SIZE" ;;
    '') FONT_SIZE="$DEFAULT_SIZE" ;;
    0) FONT_SIZE="$DEFAULT_SIZE" ;;
esac

write_file() {
    file="$1"; content="$2"
    tmp=$(mktemp "$STATE_DIR/${file}.XXXXXX")
    printf '%s\n' "$content" > "$tmp"
    mv "$tmp" "$STATE_DIR/$file"
}

write_file "colors.css" "/* Generated - do not edit */
@define-color accent_color ${ACCENT_COLOR};"

write_file "fonts.css" "/* Generated - do not edit */
* {
    font-family: \"${FONT_FAMILY}\";
    font-size: ${FONT_SIZE}px;
}"

write_file "mako-style.conf" "# Generated - do not edit
font=${FONT_FAMILY} ${FONT_SIZE}
text-color=${ACCENT_COLOR}"

write_file "rofi-style.rasi" "/* Generated - do not edit */
* {
    accent: ${ACCENT_COLOR};
    font: \"${FONT_FAMILY} ${FONT_SIZE}\";
}"

write_file "foot-style.ini" "# Generated - do not edit
[main]
font=${FONT_FAMILY}:size=${FONT_SIZE}

[colors-dark]
foreground=cdd6f4

regular4=$(printf '%s' "$ACCENT_COLOR" | cut -c2-)
bright4=$(printf '%s' "$ACCENT_COLOR" | cut -c2-)

regular5=$(printf '%s' "$ACCENT_COLOR" | cut -c2-)
bright5=$(printf '%s' "$ACCENT_COLOR" | cut -c2-)"

write_file "base.css" "/* Generated - do not edit */
@define-color bg_overlay rgba(18, 18, 22, 0.75);
@define-color bg_surface rgba(255, 255, 255, 0.05);
@define-color bg_divider rgba(255, 255, 255, 0.1);
@define-color fg_primary #e0e0e0;
@define-color fg_muted rgba(224, 224, 224, 0.5);"

echo "Generated theme state in: $STATE_DIR"
