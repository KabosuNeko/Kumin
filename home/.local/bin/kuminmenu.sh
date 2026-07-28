#!/bin/sh
set -eu

rofi -show "󰮫 General" \
  -p "Kumin Menu - Search" \
  -i \
  -modes "󰮫 General:~/.local/bin/general.sh, Theme:~/.local/bin/theme.sh, Setting:~/.local/bin/setting.sh"
