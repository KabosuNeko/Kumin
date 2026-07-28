#!/bin/sh

if ! command -v wl-screenrec > /dev/null 2>&1; then
    notify-send -u critical "Recording System" "Error: wl-screenrec is not installed." -i dialog-error
    exit 1
fi

PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/kumin_recording.pid"
SAVE_DIR="$HOME/Videos"
mkdir -p "$SAVE_DIR"

stop_recording() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill -INT "$PID"
        wait "$PID" 2>/dev/null
        rm -f "$PID_FILE"
        notify-send -u normal "Recording System" "Saved Video" -i video-display
    fi
}

start_recording() {
    chosen=$(printf 'Only Sound\nMicro and Sound\nNo Sound' | rofi -dmenu -i -p "Select Mode:" \
        -theme-str "window { width: 35%; }")

    [ -z "$chosen" ] && exit 0

    FILEPATH="$SAVE_DIR/recording_$(date +%Y%m%d_%H%M%S).mp4"

    case "$chosen" in
        "Only Sound")
            wl-screenrec --max-fps 60 --audio --audio-device default.monitor -f "$FILEPATH" &
            MSG="Recording: System Audio"
            ;;
        "Micro and Sound")
            wl-screenrec --max-fps 60 --audio -f "$FILEPATH" &
            MSG="Recording: Microphone/Default"
            ;;
        "No Sound")
            wl-screenrec --max-fps 60 -f "$FILEPATH" &
            MSG="Recording: No Sound"
            ;;
    esac

    echo $! > "$PID_FILE"
    notify-send "Recording System" "$MSG" -i video-display

    wait $!
    rm -f "$PID_FILE"
}

if [ -f "$PID_FILE" ]; then
    stop_recording
else
    start_recording
fi
