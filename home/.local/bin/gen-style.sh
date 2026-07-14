#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="$HOME/.local/state/kumin_theme"
BTOP_THEME_DIR="$HOME/.config/btop/themes"
mkdir -p "$STATE_DIR"

DEFAULT_ACCENT="#ffffff"
DEFAULT_FONT="monospace"
DEFAULT_SIZE="16"

ACCENT_COLOR="${ACCENT_COLOR:-$DEFAULT_ACCENT}"
FONT_FAMILY="${FONT_FAMILY:-$DEFAULT_FONT}"
FONT_SIZE="${FONT_SIZE:-$DEFAULT_SIZE}"

FONT_PROVIDED=false
SIZE_PROVIDED=false

if [[ "${1-}" != "" && "${1-}" != --* ]]; then ACCENT_COLOR="$1"; shift; fi
if [[ "${1-}" != "" && "${1-}" != --* ]]; then FONT_FAMILY="$1"; FONT_PROVIDED=true; shift; fi
if [[ "${1-}" != "" && "${1-}" != --* ]]; then FONT_SIZE="$1"; SIZE_PROVIDED=true; shift; fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --accent|-a) ACCENT_COLOR="${2:?missing value for --accent}"; shift 2 ;;
        --font|-f)   FONT_FAMILY="${2:?missing value for --font}"; FONT_PROVIDED=true; shift 2 ;;
        --size|-s)   FONT_SIZE="${2:?missing value for --size}"; SIZE_PROVIDED=true; shift 2 ;;
        *) echo "Unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Keep existing font/size from state unless explicitly provided
if [[ "$FONT_PROVIDED" = false && -f "$STATE_DIR/fonts.css" ]]; then
    parsed_font="$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
    [[ -n "$parsed_font" ]] && FONT_FAMILY="$parsed_font"
fi

if [[ "$SIZE_PROVIDED" = false && -f "$STATE_DIR/fonts.css" ]]; then
    parsed_size="$(sed -nE 's/^\s*font-size:\s*([0-9]+)px.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
    [[ -n "$parsed_size" ]] && FONT_SIZE="$parsed_size"
fi

ACCENT_COLOR="$(printf '%s' "$ACCENT_COLOR" | tr -cd '#0-9a-fA-F')"
if ! [[ "$ACCENT_COLOR" =~ ^#[0-9a-fA-F]{6}$ ]]; then
    ACCENT_COLOR="$DEFAULT_ACCENT"
fi

if ! [[ "$FONT_SIZE" =~ ^[0-9]+$ ]] || [[ "$FONT_SIZE" -le 0 ]]; then
    FONT_SIZE="$DEFAULT_SIZE"
fi

# convert accent to rgba(hex8)
hex_to_rgb() {
    local hex="${1:-}"
    hex="${hex#\#}"
    hex="${hex//[^0-9a-fA-F]/}"
    if [[ "$hex" =~ ^[0-9a-fA-F]{6}$ ]]; then
        printf 'rgb(%d, %d, %d)' $((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))
        return 0
    elif [[ "$hex" =~ ^[0-9a-fA-F]{8}$ ]]; then
        printf 'rgb(%d, %d, %d)' $((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))
        return 0
    fi
    printf 'rgb(255, 255, 255)'
}

ACCENT_RGB="$(hex_to_rgb "$ACCENT_COLOR")"

tmp=$(mktemp "$STATE_DIR/colors.css.XXXXXX")
cat > "$tmp" <<EOF
/* Generated - do not edit */
@define-color accent_color ${ACCENT_COLOR};
EOF
mv "$tmp" "$STATE_DIR/colors.css"

tmp=$(mktemp "$STATE_DIR/fonts.css.XXXXXX")
cat > "$tmp" <<EOF
/* Generated - do not edit */
* {
    font-family: "${FONT_FAMILY}";
    font-size: ${FONT_SIZE}px;
}
EOF
mv "$tmp" "$STATE_DIR/fonts.css"

tmp=$(mktemp "$STATE_DIR/mako-style.conf.XXXXXX")
cat > "$tmp" <<EOF
# Generated - do not edit
font=${FONT_FAMILY} ${FONT_SIZE}
text-color=${ACCENT_COLOR}
EOF
mv "$tmp" "$STATE_DIR/mako-style.conf"

tmp=$(mktemp "$STATE_DIR/rofi-style.rasi.XXXXXX")
cat > "$tmp" <<EOF
/* Generated - do not edit */
* {
    accent: ${ACCENT_COLOR};
    font: "${FONT_FAMILY} ${FONT_SIZE}";
}
EOF
mv "$tmp" "$STATE_DIR/rofi-style.rasi"

tmp=$(mktemp "$STATE_DIR/foot-style.ini.XXXXXX")
cat > "$tmp" <<EOF
# Generated - do not edit
[main]
font=${FONT_FAMILY}:size=${FONT_SIZE}

[colors-dark]
foreground=cdd6f4

regular4=${ACCENT_COLOR#\#}
bright4=${ACCENT_COLOR#\#}

regular5=${ACCENT_COLOR#\#}
bright5=${ACCENT_COLOR#\#}
EOF
mv "$tmp" "$STATE_DIR/foot-style.ini"

tmp=$(mktemp "$STATE_DIR/base.css.XXXXXX")
cat > "$tmp" <<EOF
/* Generated - do not edit */
@define-color bg_overlay rgba(18, 18, 22, 0.75);
@define-color bg_surface rgba(255, 255, 255, 0.05);
@define-color bg_divider rgba(255, 255, 255, 0.1);
@define-color fg_primary #e0e0e0;
@define-color fg_muted rgba(224, 224, 224, 0.5);
EOF
mv "$tmp" "$STATE_DIR/base.css"

echo "Generated theme state in: $STATE_DIR"
