#!/bin/bash

set -euo pipefail

LOCK_CMD="${LOCK_CMD:-swaylock -f}"

confirm() {
    local action="$1"
    local answer
    answer="$(printf "No\nYes" | rofi -dmenu -i -p "$action?")"
    [[ "$answer" == "Yes" ]]
}

lock_screen() {
    sh -c "$LOCK_CMD"
}

sleep_system() {
    sh -c "$LOCK_CMD" &
    sleep 0.6
    systemctl suspend
}

exit_wm() {
    pkill niri
}

execute_action() {
    case "$1" in
        "poweroff" | "shutdown") systemctl poweroff ;;
        "reboot") systemctl reboot ;;
        "hibernate") systemctl hibernate ;;
        "sleep" | "suspend") sleep_system ;;
        "lock") lock_screen ;;
        "exit" | "logout") exit_wm ;;
        *) exit 0 ;;
    esac
}

show_menu() {
    local options="  Power Off\n  Reboot\n󱠩  Hibernate\n󰒲  Sleep\n󱅞  Lock\n󰩈  Exit"
    local choice

    choice="$(echo -e "$options" | rofi -dmenu -p "Power" -i -theme-str 'window { width: 30%; height: 50%; }')"

    case "$choice" in
        *"Power Off"*) confirm "Power Off" && execute_action "poweroff" ;;
        *"Reboot"*) confirm "Reboot" && execute_action "reboot" ;;
        *"Hibernate"*) confirm "Hibernate" && execute_action "hibernate" ;;
        *"Sleep"*) execute_action "sleep" ;;
        *"Lock"*) execute_action "lock" ;;
        *"Exit"*) confirm "Exit" && execute_action "exit" ;;
    esac
}

if [[ $# -gt 0 ]]; then
    execute_action "$1"
else
    show_menu
fi
