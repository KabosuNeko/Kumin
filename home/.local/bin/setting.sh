#!/bin/bash
set -euo pipefail
spawn() { ( "$@" & ) >/dev/null 2>&1; disown; }

if [[ $# -eq 0 ]]; then
    cat <<'EOF'
󰖩  Wifi
󰂯  Bluetooth
  System Monitor
󰋊  Storage Manager
󰓃  Audio Control
EOF
    exit 0
fi

chosen="$*"
case "$chosen" in
    *"Wifi"*) spawn foot -e nmtui ;;
    *"Bluetooth"*) spawn foot -e bluetoothctl ;;
    *"System Monitor"*) spawn foot -e btm ;;
    *"Storage Manager"*) spawn foot --app-id=ncdu -e sudo ncdu / ;;
    *"Audio Control"*) spawn foot -e pulsemixer ;;
esac

exit 0
