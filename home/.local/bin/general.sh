#!/bin/bash
set -euo pipefail

spawn() { ( "$@" & ) >/dev/null 2>&1; disown; }

if [[ $# -eq 0 ]]; then
  cat <<'EOF'
󰚥  Power Profiles
󰇧  Browser
󰑋  Screen Record
  Local Send
  File Manager
EOF
    exit 0
fi

chosen="$*"
case "$chosen" in
  *"Power Profiles"*) spawn ~/.local/bin/powerprofiles.sh ;;
  *"Browser"*) spawn firefox ;;
  *"Screen Record"*) spawn ~/.local/bin/record.sh ;;
  *"Local Send"*) spawn localsend ;;
  *"File Manager"*) spawn thunar ;;
esac
