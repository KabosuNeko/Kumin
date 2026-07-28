#!/bin/sh

if ! command -v wl-screenrec > /dev/null 2>&1; then
    notify-send -u critical "Recording System" "Error: wl-screenrec is not installed." -i dialog-error
    exit 1
fi

PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/kumin_recording.pid"

SAVE_DIR="$HOME/Videos"
mkdir -p "$SAVE_DIR"

REC_OPTS="--max-fps 60"

stop_recording() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill -INT "$PID"
        while kill -0 "$PID" 2>/dev/null; do sleep 0.1; done
        rm -f "$PID_FILE"
        notify-send -u normal "Recording System" "Saved Video" -i video-display
    fi
}

start_recording() {
    options="󰑊 Only Sound\n󰍬 Micro and Sound\n󰔊 No Sound"
    chosen=$(printf '%b' "$options" | rofi -dmenu -i -p "Select Mode:" \
        -theme-str "window { width: 35%; }")

    if [ -z "$chosen" ]; then
        exit 0
    fi

    FILENAME="recording_$(date +%Y%m%d_%H%M%S).mp4"
    FILEPATH="$SAVE_DIR/$FILENAME"

    case "$chosen" in
        *"Only Sound")
            wl-screenrec $REC_OPTS --audio --audio-device default.monitor -f "$FILEPATH" &
            MSG="Recording: System Audio"
            ;;
        *"Micro and Sound")
            wl-screenrec $REC_OPTS --audio -f "$FILEPATH" &
            MSG="Recording: Microphone/Default"
            ;;
        *"No Sound")
            wl-screenrec $REC_OPTS -f "$FILEPATH" &
            MSG="Recording: No Sound"
            ;;
    esac

    echo $! > "$PID_FILE"
    notify-send "Recording System" "$MSG" -i video-display

    while [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; do
        sleep 1
    done

    rm -f "$PID_FILE"
}

if [ -f "$PID_FILE" ]; then
    stop_recording
else
    start_recording
fi
