#!/bin/sh
set -eu

STATE_DIR="$HOME/.local/state/kumin_theme"
mkdir -p "$STATE_DIR"

if [ $# -ge 1 ] && [ -n "$1" ]; then
    case "$1" in
        left|vertical)
            echo "left" > "$STATE_DIR/bar_layout"
            ;;
        top|horizontal)
            echo "top" > "$STATE_DIR/bar_layout"
            ;;
        --reload|-r)
            ;;
    esac
fi

LAYOUT=$(cat "$STATE_DIR/bar_layout" 2>/dev/null || echo "top")

# Terminate existing waybar instances
pkill -x waybar 2>/dev/null || true
while pgrep -x waybar >/dev/null 2>&1; do
    sleep 0.1
done

case "$LAYOUT" in
    left|vertical)
        CONFIG="$HOME/.config/waybar/config-vertical"
        STYLE="$HOME/.config/waybar/style-vertical.css"
        ;;
    top|horizontal|*)
        CONFIG="$HOME/.config/waybar/config"
        STYLE="$HOME/.config/waybar/style.css"
        ;;
esac

CONFIG=$(realpath "$CONFIG")
STYLE=$(realpath "$STYLE")

exec waybar -c "$CONFIG" -s "$STYLE"
