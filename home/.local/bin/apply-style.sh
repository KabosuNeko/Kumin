#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="$HOME/.local/state/kumin_theme"

if command -v gsettings >/dev/null 2>&1 && [[ -f "$STATE_DIR/fonts.css" ]]; then
    # Parse from fonts.css:
    #   font-family: "JetBrainsMono Nerd Font";
    #   font-size: 16px;
    font_family="$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
    font_size="$(sed -nE 's/^\s*font-size:\s*([0-9]+)px.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"

    if [[ -n "${font_family:-}" && -n "${font_size:-}" ]]; then
        gtk_font="${font_family} ${font_size}"
        gsettings set org.gnome.desktop.interface font-name "$gtk_font" || true
        gsettings set org.gnome.desktop.interface monospace-font-name "$gtk_font" || true
    fi
fi

if command -v makoctl >/dev/null 2>&1; then
    makoctl reload || true
fi

pkill -USR1 foot >/dev/null 2>&1 || true

SWAYLOCK_CONFIG="$HOME/.config/swaylock/config"
if [[ -f "$STATE_DIR/fonts.css" && -f "$SWAYLOCK_CONFIG" ]]; then
    FONT_FAMILY="$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
    FONT_SIZE="$(sed -nE 's/^\s*font-size:\s*([0-9]+)px.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
    if [[ -n "${FONT_FAMILY:-}" && -n "${FONT_SIZE:-}" ]]; then
        sed -i "s/^font=.*/font=${FONT_FAMILY} ${FONT_SIZE}/" "$SWAYLOCK_CONFIG"
    fi
fi
