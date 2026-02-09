#!/bin/bash

start_flag ()
{
    touch ~/.cache/.wf-recording
}

stop_flag ()
{
    rm -f ~/.cache/.wf-recording
}

# Stop wf-recorder if already running
pgrep -x "wf-recorder" && pkill -INT -x wf-recorder && notify-send -h string:wf-recorder:record -t 1000 "Finished Recording" && stop_flag && exit 0

# Gather monitor names
outputs=$(hyprctl monitors | grep '^Monitor' | awk '{print $2}' | paste -sd'|' -)
if [[ -z "$outputs" ]]; then
    zenity --error --text="No monitors detected via hyprctl!"
    exit 1
fi

form_result=$(zenity --forms --title="wf-recorder" \
    --text="Screen Recording Options" \
    --add-combo="Monitor" --combo-values="$outputs" \
    --add-combo="Audio" --combo-values="Record Audio|No Audio")

if [[ -z "$form_result" ]]; then
    notify-send "wf-recorder" "No selection made, cancelled."
    exit 1
fi

selected_output=$(echo "$form_result" | cut -d'|' -f1)
audio_choice=$(echo "$form_result" | cut -d'|' -f2)

if [[ "$audio_choice" == "Record Audio" ]]; then
    AUDIO_OPTS="--audio --audio-source=auto"
else
    AUDIO_OPTS=""
fi

notify-send -h string:wf-recorder:record -t 950 "Recording is ready to start!"
sleep 1

start_flag
dateTime=$(date +%m-%d-%Y-%H:%M:%S)
wf-recorder --bframes max_b_frames $AUDIO_OPTS -o "$selected_output" -f "$HOME/Videos/$dateTime.mp4"
