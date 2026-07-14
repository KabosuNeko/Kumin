#!/bin/bash

if [ "$1" = "--wipe" ]; then
    cliphist wipe
    notify-send "Clipboard" "History cleared" -t 2000
    exit 0
fi

if ! pgrep -x "wl-paste" > /dev/null; then
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
fi

result=$(cliphist list | rofi -dmenu \
    -p "󰅌 Clipboard" \
    -theme-str "window { width: 50%; } \
                listview { lines: 10; }")

if [ ! -z "$result" ]; then
    echo "$result" | cliphist decode | wl-copy
    notify-send "Clipboard" "Copied" -t 2000
fi
