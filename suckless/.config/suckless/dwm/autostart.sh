#!/bin/bash
echo "autostart uruchomiony $(date)" >>/tmp/autostart.log

# Funkcja uruchamiająca procesy pojedynczo (sprawdza basename, eliminuje błędy ze ścieżkami)
function run {
  local proc_name
  proc_name=$(basename "$1")
  if ! pgrep -f "$proc_name" >/dev/null; then
    "$@" &
  fi
}

# Display - Monitor
# run "xrandr --output eDP1 --mode 1920x1080 --pos 0x0 --rotate normal"
# sleep 3 && xrandr --output Virtual-1 --mode 1920x1080 --pos 0x0 --rotate normal &

# Ustawienia wyglądu
xrdb -merge ~/.Xresources
feh --bg-fill "$HOME/Pictures/Wallpaper/!current.png"

# Bezpieczny restart kompozytora (eliminuje Race Condition)
killall -q picom
while pgrep -x picom >/dev/null; do sleep 0.1; done
picom -b --config ~/.config/suckless/picom/picom.conf

# Usługi działające w pętli wywoływane przez funkcję run
# Monitor poziomu baterii
run ~/.config/suckless/scripts/battery-monitor.sh

# Demony same zarządzające starymi sesjami
~/.config/suckless/scripts/restart-dunst.sh &

# Schowek systemowy
pkill -f clipboard.sh
clipboard.sh --daemon &

# Google Drive (rclone) - mount + rozgrzewanie cache w tle
# ~/.config/suckless/scripts/rclone-gdrive-start.sh &

# OneDrive (rclone) - mount + rozgrzewanie cache w tle
# ~/.config/suckless/scripts/rclone-onedrive-start.sh &

# Włączenie klawisza numloc
numlockx on
