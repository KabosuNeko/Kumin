#!/bin/sh
set -eu

option_perf="󰓅  Performance"
option_bal="󰾆  Balanced"
option_save="  Power-saver"

chosen=$(printf '%s\n' "$option_perf" "$option_bal" "$option_save" | rofi -dmenu -i -p "Power Profile")

case "$chosen" in
    "$option_perf")
        powerprofilesctl set performance
        notify-send "Power Profile" "Switched to Performance mode"
        ;;
    "$option_bal")
        powerprofilesctl set balanced
        notify-send "Power Profile" "Switched to Balanced mode"
        ;;
    "$option_save")
        powerprofilesctl set power-saver
        notify-send "Power Profile" "Switched to Power-saver mode"
        ;;
esac
