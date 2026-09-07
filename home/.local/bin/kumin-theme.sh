#!/bin/sh
set -eu

STATE_DIR="$HOME/.local/state/kumin_theme"
mkdir -p "$STATE_DIR"

DEFAULT_ACCENT="#ffffff"
DEFAULT_FONT="monospace"
DEFAULT_SIZE="16"

spawn() {
    ( unset ROFI_RETV ROFI_OUT; nohup "$@" >/dev/null 2>&1 & )
}

# --- State Readers ---
get_accent() {
    val=$(sed -nE 's/^\s*@define-color\s+accent_color\s+(#[0-9a-fA-F]{6})\s*;.*$/\1/p' "$STATE_DIR/colors.css" 2>/dev/null || true)
    echo "${val:-$DEFAULT_ACCENT}"
}

get_font() {
    val=$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" 2>/dev/null || true)
    echo "${val:-$DEFAULT_FONT}"
}

get_size() {
    val=$(sed -nE 's/^\s*font-size:\s*([0-9]+)px.*$/\1/p' "$STATE_DIR/fonts.css" 2>/dev/null || true)
    echo "${val:-$DEFAULT_SIZE}"
}

get_bar_layout() {
    cat "$STATE_DIR/bar_layout" 2>/dev/null || echo "top"
}

# --- Core Theme Apply Engine ---
apply_style() {
    accent="${1:-$(get_accent)}"
    font_family="${2:-$(get_font)}"
    font_size="${3:-$(get_size)}"

    # Validate accent
    accent=$(printf '%s' "$accent" | tr -cd '#0-9a-fA-F')
    case "$accent" in
        '#'[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;;
        *) accent="$DEFAULT_ACCENT" ;;
    esac

    # Validate size
    case "$font_size" in
        *[!0-9]*) font_size="$DEFAULT_SIZE" ;;
        ''|0) font_size="$DEFAULT_SIZE" ;;
    esac

    # In-place write to preserve inode for inotify watchers
    printf '/* Generated - do not edit */\n@define-color accent_color %s;\n' "$accent" > "$STATE_DIR/colors.css"
    if [ -d "$HOME/.config/waybar" ]; then
        printf '/* Generated - do not edit */\n@define-color accent_color %s;\n' "$accent" > "$HOME/.config/waybar/colors.css"
    fi

    printf '/* Generated - do not edit */\n* {\n    font-family: "%s";\n    font-size: %spx;\n}\n' "$font_family" "$font_size" > "$STATE_DIR/fonts.css"

    printf '# Generated - do not edit\nfont=%s %s\ntext-color=%s\n' "$font_family" "$font_size" "$accent" > "$STATE_DIR/mako-style.conf"

    printf '/* Generated - do not edit */\n* {\n    accent: %s;\n    font: "%s %s";\n}\n' "$accent" "$font_family" "$font_size" > "$STATE_DIR/rofi-style.rasi"

    reg4=$(printf '%s' "$accent" | cut -c2-)
    cat <<FOO > "$STATE_DIR/foot-style.ini"
# Generated - do not edit
[main]
font=${font_family}:size=${font_size}

[colors-dark]
foreground=cdd6f4

regular4=${reg4}
bright4=${reg4}

regular5=${reg4}
bright5=${reg4}
FOO
    cp "$STATE_DIR/foot-style.ini" "$STATE_DIR/foot.ini" 2>/dev/null || true

    # Apply to GTK if gsettings is available
    if command -v gsettings >/dev/null 2>&1; then
        gtk_font="${font_family} ${font_size}"
        gsettings set org.gnome.desktop.interface font-name "$gtk_font" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface monospace-font-name "$gtk_font" 2>/dev/null || true
    fi

    # Reload Mako notification daemon
    if command -v makoctl >/dev/null 2>&1; then
        makoctl reload 2>/dev/null || true
    fi

    # Ensure Waybar imports current user's state colors.css portably
    for scss in "$HOME/.config/waybar/style.css" "$HOME/.config/waybar/style-vertical.css"; do
        if [ -f "$scss" ]; then
            sed -i --follow-symlinks "1s|^@import .*;|@import '${STATE_DIR}/colors.css';|" "$scss" 2>/dev/null || true
        fi
    done

    # Trigger Waybar inotify hot-reload (ZERO kill / pkill)
    touch -c "$HOME/.config/waybar/style.css" "$HOME/.config/waybar/style-vertical.css" 2>/dev/null || true
    if [ -d "$HOME/Kumin/home/.config/waybar" ]; then
        touch -c "$HOME/Kumin/home/.config/waybar/style.css" "$HOME/Kumin/home/.config/waybar/style-vertical.css" 2>/dev/null || true
    fi


    # Update swaylock font
    swaylock_cfg="$HOME/.config/swaylock/config"
    if [ -f "$swaylock_cfg" ]; then
        sed -i --follow-symlinks "s/^font=.*/font=${font_family} ${font_size}/" "$swaylock_cfg" 2>/dev/null || true
    fi

    echo "Applied theme: accent=$accent, font=\"$font_family\", size=${font_size}px"
}

# --- Actions / Pickers ---
action_wallpaper() {
    if [ -x "$HOME/.local/bin/wallselect.sh" ]; then
        spawn "$HOME/.local/bin/wallselect.sh"
    else
        echo "wallselect.sh not found" >&2
    fi
}

action_color() {
    target_hex="${1:-}"
    if [ -z "$target_hex" ]; then
        current_accent=$(get_accent)
        choice=$(cat <<'CLR' | rofi -dmenu -p "  Current: ${current_accent}" -theme-str 'entry { placeholder: "Type hex color here #xxxxxx"; }' -i
Slate Blue   #7288AE
Green        #A2CB8B
Peach        #FFB399
Yellow       #efbf04
Pink         #F9B2D7
White        #ffffff
Grey         #BFC9D1
Custom       (type hex in prompt)
CLR
        )
        [ -z "${choice:-}" ] && return 0

        case "$choice" in
            *"Custom"*)
                target_hex=$(printf '%s\n' "$current_accent" | rofi -dmenu -p "Hex (#RRGGBB)" -theme-str 'entry { placeholder: "Type hex color here #xxxxxx"; }' -i)
                ;;
            *)
                target_hex=$(printf '%s\n' "$choice" | grep -oE '#[0-9a-fA-F]{6}' | head -n1)
                ;;
        esac
    fi

    [ -z "${target_hex:-}" ] && return 0
    apply_style "$target_hex" "$(get_font)" "$(get_size)"
}

action_font() {
    target_font="${1:-}"
    if [ -z "$target_font" ]; then
        current_font=$(get_font)
        fonts=$(fc-list : family 2>/dev/null | sed 's/,.*//' | sort -u || true)
        [ -z "$fonts" ] && { echo "No fonts found via fc-list" >&2; return 1; }
        target_font=$(printf '%s\n' "$fonts" | rofi -dmenu -p "  Current: ${current_font}" -i)
    fi

    [ -z "${target_font:-}" ] && return 0
    apply_style "$(get_accent)" "$target_font" "$(get_size)"
}

action_size() {
    target_size="${1:-}"
    if [ -z "$target_size" ]; then
        current_size=$(get_size)
        target_size=$(printf '%s\n' "$current_size" | rofi -dmenu -p "  Current: ${current_size}px" -theme-str 'entry { placeholder: "Type font size here"; }' -i)
    fi

    [ -z "${target_size:-}" ] && return 0
    case "$target_size" in
        *[!0-9]*) return 0 ;;
    esac
    apply_style "$(get_accent)" "$(get_font)" "$target_size"
}

action_bar() {
    target_layout="${1:-}"
    current_layout=$(get_bar_layout)

    if [ -z "$target_layout" ]; then
        choice=$(cat <<BAR | rofi -dmenu -p "Bar Layout (Current: ${current_layout})" -i
󰹪  Horizontal (Top)
󱒔  Vertical (Left)
BAR
        )
        [ -z "${choice:-}" ] && return 0
        case "$choice" in
            *"Horizontal"*) target_layout="top" ;;
            *"Vertical"*)   target_layout="left" ;;
            *) return 0 ;;
        esac
    elif [ "$target_layout" = "toggle" ]; then
        case "$current_layout" in
            left|vertical) target_layout="top" ;;
            *)             target_layout="left" ;;
        esac
    fi

    case "$target_layout" in
        top|horizontal)
            target_layout="top"
            desc="Horizontal (Top)"
            ;;
        left|vertical)
            target_layout="left"
            desc="Vertical (Left)"
            ;;
        *)
            echo "Unknown layout: $target_layout" >&2
            return 1
            ;;
    esac

    echo "$target_layout" > "$STATE_DIR/bar_layout"
    spawn "$HOME/.local/bin/kumin-bar.sh"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Kumin" "Bar Layout" "Switched to $desc" 2>/dev/null || true
    fi
}

action_menu() {
    cur_color=$(get_accent)
    cur_font=$(get_font)
    cur_size=$(get_size)
    cur_bar=$(get_bar_layout)

    choice=$(cat <<MNU | rofi -dmenu -p "Theme & Style Manager" -i
󰸉  Change Wallpaper
  Change Color (Current: ${cur_color})
  Change Font (Current: ${cur_font})
  Change Font Size (Current: ${cur_size}px)
󱗼  Change Bar Layout (Current: ${cur_bar})
MNU
    )
    [ -z "${choice:-}" ] && return 0

    case "$choice" in
        *"Change Wallpaper"*)  action_wallpaper ;;
        *"Change Color"*)      action_color ;;
        *"Change Font Size"*)  action_size ;;
        *"Change Font"*)       action_font ;;
        *"Change Bar Layout"*) action_bar ;;
    esac
}

# --- Entrypoint & Mode Detection ---

# Check if called as a Rofi mode (e.g. from kuminmenu.sh: -modes "...,Theme:~/.local/bin/kumin-theme.sh,...")
if [ -n "${ROFI_RETV:-}" ] || [ -n "${ROFI_OUT:-}" ]; then
    if [ $# -eq 0 ]; then
        cur_color=$(get_accent)
        cur_bar=$(get_bar_layout)
        cat <<ROFI_EOF
󰸉  Change Wallpaper
  Change Color (${cur_color})
  Change Font
  Change Font Size
󱗼  Change Bar Layout (${cur_bar})
ROFI_EOF
        exit 0
    else
        selected="$*"
        case "$selected" in
            *"Change Wallpaper"*)  spawn "$HOME/.local/bin/kumin-theme.sh" wallpaper ;;
            *"Change Color"*)      spawn "$HOME/.local/bin/kumin-theme.sh" color ;;
            *"Change Font Size"*)  spawn "$HOME/.local/bin/kumin-theme.sh" size ;;
            *"Change Font"*)       spawn "$HOME/.local/bin/kumin-theme.sh" font ;;
            *"Change Bar Layout"*) spawn "$HOME/.local/bin/kumin-theme.sh" bar ;;
        esac
        exit 0
    fi
fi

# If invoked with no arguments
if [ $# -eq 0 ]; then
    action_menu
    exit 0
fi

# Subcommands & Flags
while [ $# -gt 0 ]; do
    case "$1" in
        menu|--menu|-m)
            action_menu
            exit 0
            ;;
        wallpaper|--wallpaper)
            action_wallpaper
            exit 0
            ;;
        color|accent|--color|--accent|-a)
            if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then
                action_color "$2"
                shift 2
            else
                action_color ""
                shift 1
            fi
            exit 0
            ;;
        font|--font|-f)
            if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then
                action_font "$2"
                shift 2
            else
                action_font ""
                shift 1
            fi
            exit 0
            ;;
        size|--size|-s)
            if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then
                action_size "$2"
                shift 2
            else
                action_size ""
                shift 1
            fi
            exit 0
            ;;
        bar|--bar|-b)
            if [ $# -ge 2 ] && [ "${2#-}" = "$2" ]; then
                action_bar "$2"
                shift 2
            else
                action_bar ""
                shift 1
            fi
            exit 0
            ;;
        apply|--apply)
            apply_style "$(get_accent)" "$(get_font)" "$(get_size)"
            exit 0
            ;;
        # Positional arguments compatibility for kumin-style.sh [ACCENT] [FONT] [SIZE]
        '#'*)
            acc="$1"
            fnt="${2:-$(get_font)}"
            siz="${3:-$(get_size)}"
            apply_style "$acc" "$fnt" "$siz"
            exit 0
            ;;
        *)
            echo "Usage: $(basename "$0") [menu|wallpaper|color|font|size|bar|apply] [options]" >&2
            echo "       $(basename "$0") --accent <#hex> [--font <name>] [--size <px>]" >&2
            echo "       $(basename "$0") <#hex> [font] [size]" >&2
            exit 2
            ;;
    esac
done
