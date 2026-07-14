#!/bin/sh
set -eu

PERS_FILE="${PERS_FILE:-$HOME/.config/bookmarks/personal.txt}"
WORK_FILE="${WORK_FILE:-$HOME/.config/bookmarks/work.txt}"

FIREFOX="$(command -v firefox || true)"
FALLBACK="$(command -v xdg-open || command -v firefox || echo xdg-open)"

mkdir -p "$(dirname "$PERS_FILE")"

[ -f "$PERS_FILE" ] || cat >"$PERS_FILE" <<'EOF'
# personal
YouTube :: https://youtube.com
GitHub :: https://github.com
Facebook :: https://facebook.com
Messenger :: https://messenger.com
Instagram :: https://instagram.com
TikTok :: https://tiktok.com
X :: https://x.com
Gmail :: https://mail.google.com
Google Maps :: https://maps.google.com
Google Translate :: https://translate.google.com
EOF

[ -f "$WORK_FILE" ] || cat >"$WORK_FILE" <<'EOF'
# work
GitHub :: https://github.com
Google Drive :: https://drive.google.com
Google Docs :: https://docs.google.com/document/
Google Sheets :: https://docs.google.com/spreadsheets/
Stack Overflow :: https://stackoverflow.com
NixOS Manual :: https://nixos.org/manual/
Arch Wiki :: https://wiki.archlinux.org/
EOF

emit() {
  tag="$1"
  file="$2"
  [ -f "$file" ] || return 0

  grep -vE '^[[:space:]]*(#|$)' "$file" | while IFS= read -r line; do
    case "$line" in
      *"::"*)
        lhs="${line%%::*}"
        rhs="${line#*::}"
        lhs="$(printf '%s' "$lhs" | sed 's/[[:space:]]*$//')"
        rhs="$(printf '%s' "$rhs" | sed 's/^[[:space:]]*//')"
        printf '[%s] %s :: %s\n' "$tag" "$lhs" "$rhs"
        ;;
      *)
        printf '[%s] %s :: %s\n' "$tag" "$line" "$line"
        ;;
    esac
  done
}

choice="$(
  {
    emit personal "$PERS_FILE"
    emit work "$WORK_FILE"
  } | sort | rofi -dmenu -p 'Bookmarks:' || true
)"

[ -n "$choice" ] || exit 0

raw="${choice##* :: }"

raw="$(
  printf '%s' "$raw" | sed \
    -e 's/[[:space:]]\+#.*$//' \
    -e 's/[[:space:]]\/\/.*$//' \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//'
)"

case "$raw" in
  http://*|https://*|file://*|about:*|chrome:*)
    url="$raw"
    ;;
  *)
    url="https://$raw"
    ;;
esac

open_with() {
  cmd="$1"
  if [ -n "$cmd" ]; then
    nohup "$cmd" "$url" >/dev/null 2>&1 &
    exit 0
  fi
}

open_with "$FIREFOX"
nohup "$FALLBACK" "$url" >/dev/null 2>&1 &
