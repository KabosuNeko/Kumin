#!/bin/sh
set -eu

STATE_DIR="$HOME/.local/state/kumin_theme"

if command -v gsettings >/dev/null 2>&1 && [ -f "$STATE_DIR/fonts.css" ]; then
    font_family=$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1)
    font_size=$(sed -nE 's/^\s*font-size:\s*([0-9]+)px.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1)

    if [ -n "${font_family:-}" ] && [ -n "${font_size:-}" ]; then
        gtk_font="${font_family} ${font_size}"
        gsettings set org.gnome.desktop.interface font-name "$gtk_font" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface monospace-font-name "$gtk_font" 2>/dev/null || true
    fi
fi

if command -v makoctl >/dev/null 2>&1; then
    makoctl reload 2>/dev/null || true
fi

ACCENT=$(sed -nE 's/^\s*@define-color\s+accent_color\s+(#[0-9a-fA-F]{6}).*$/\1/p' "$STATE_DIR/colors.css" 2>/dev/null || true)
if [ -n "$ACCENT" ]; then
    sed -i "1s/.*/@define-color accent_color $ACCENT;/" "$HOME/.config/waybar/style.css"
fi
pkill -SIGUSR2 waybar 2>/dev/null || true
pkill -USR1 foot 2>/dev/null || true

SWAYLOCK_CONFIG="$HOME/.config/swaylock/config"
if [ -f "$STATE_DIR/fonts.css" ] && [ -f "$SWAYLOCK_CONFIG" ]; then
    FONT_FAMILY=$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1)
    FONT_SIZE=$(sed -nE 's/^\s*font-size:\s*([0-9]+)px.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1)
    if [ -n "${FONT_FAMILY:-}" ] && [ -n "${FONT_SIZE:-}" ]; then
        sed -i "s/^font=.*/font=${FONT_FAMILY} ${FONT_SIZE}/" "$SWAYLOCK_CONFIG"
    fi
fi
