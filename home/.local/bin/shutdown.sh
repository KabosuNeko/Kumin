#!/bin/sh
set -eu

LOCK_CMD="${LOCK_CMD:-swaylock -f}"

lock_screen() {
    $LOCK_CMD
}

sleep_system() {
    $LOCK_CMD &
    sleep 0.6
    systemctl suspend
}

exit_wm() {
    pkill niri
}

execute_action() {
    case "$1" in
        poweroff|shutdown) systemctl poweroff ;;
        reboot) systemctl reboot ;;
        hibernate) systemctl hibernate ;;
        sleep|suspend) sleep_system ;;
        lock) lock_screen ;;
        exit|logout) exit_wm ;;
    esac
}

show_menu() {
    options="  Power Off\n  Reboot\n󱠩  Hibernate\n󰒲  Sleep\n󱅞  Lock\n󰩈  Exit"
    choice=$(printf '%b' "$options" | rofi -dmenu -p "Power" -i -theme-str 'window { width: 30%; height: 50%; }')

    case "$choice" in
        *"Power Off"*) execute_action "poweroff" ;;
        *"Reboot"*) execute_action "reboot" ;;
        *"Hibernate"*) execute_action "hibernate" ;;
        *"Sleep"*) execute_action "sleep" ;;
        *"Lock"*) execute_action "lock" ;;
        *"Exit"*) execute_action "exit" ;;
    esac
}

if [ $# -gt 0 ]; then
    execute_action "$1"
else
    show_menu
fi
