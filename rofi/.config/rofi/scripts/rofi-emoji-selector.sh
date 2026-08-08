#!/usr/bin/env bash

# Get user selection via rofi from emoji file.
chosen=$(cat ~/.config/suckless/scripts/emoji | rofi -dmenu -p "EMOJI" | awk '{print $1}')

# Exit if none chosen.
[ -z "$chosen" ] && exit

printf "%s" "$chosen" | xsel --clipboard --input
printf "%s" "$chosen" | xsel --primary --input
sleep 0.2
xdotool key --clearmodifiers ctrl+v
notify-send "'$chosen' copied to clipboard." &
