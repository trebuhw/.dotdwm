#!/usr/bin/env bash

# Ikony (kolejność: wygaś, blokuj, wyloguj, uśpij, restart, wyłącz)
sleep_screen_icon="󰍹"
lock_icon=""
logout_icon="󰗽"
suspend_icon="󰒲"
reboot_icon=""
shutdown_icon=""

yes_icon=""
no_icon=""

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCK_COLOR="1e1e2e"

# Pobieranie uptime
get_uptime() {
  uptime -p | sed 's/up //'
}

# Wykrywanie systemu init
get_init_system() {
  if [[ -f /proc/1/comm ]]; then
    cat /proc/1/comm
  else
    ps --pid 1 -o comm= 2>/dev/null || echo "unknown"
  fi
}

# Główne menu rofi
main_menu() {
  local uptime
  uptime=$(get_uptime)

  printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
    "$sleep_screen_icon" \
    "$lock_icon" \
    "$logout_icon" \
    "$suspend_icon" \
    "$reboot_icon" \
    "$shutdown_icon" |
    rofi -dmenu \
      -p "Uptime: $uptime" \
      -mesg "Uptime: $uptime" \
      -theme "$CONFIG_DIR/rofi/common.rasi"
}

# Menu potwierdzenia
confirm() {
  local choice
  choice=$(printf "%s\n%s\n" "$yes_icon" "$no_icon" |
    rofi -theme "$CONFIG_DIR/rofi/common.rasi" \
      -theme-str "listview {columns: 2; lines: 1;}" \
      -dmenu \
      -p "Confirmation" \
      -mesg "Confirm?")

  [[ "$choice" == "$yes_icon" ]]
}

# Wykonanie akcji
power() {
  local selected
  selected=$(main_menu | awk '{print $1}')

  [[ -z "$selected" ]] && exit 0

  # Ustalanie komend dla zasilania w zależności od init
  local init
  init=$(get_init_system)

  local shutdown_cmd reboot_cmd suspend_cmd
  if [[ "$init" == "systemd" ]]; then
    shutdown_cmd="sync; systemctl poweroff"
    reboot_cmd="sync; systemctl reboot"
    suspend_cmd="systemctl suspend"
  else
    shutdown_cmd="sync; loginctl poweroff"
    reboot_cmd="sync; loginctl reboot"
    suspend_cmd="loginctl suspend"
  fi

  case "$selected" in
  "$sleep_screen_icon")
    if confirm; then
      i3lock -c "$LOCK_COLOR" && sleep 1 && xset dpms force off && pkill -9 dunst
    fi
    ;;
  "$lock_icon")
    i3lock -c "$LOCK_COLOR"
    ;;
  "$logout_icon")
    if confirm; then
      pkill -9 dunst
      sync
      pkill -KILL -u "$USER"
    fi
    ;;
  "$suspend_icon")
    if confirm; then
      # Blokujemy ekran przed uśpieniem (opcjonalnie, ale bardzo przydatne)
      i3lock -c "$LOCK_COLOR"
      eval "$suspend_cmd"
    fi
    ;;
  "$reboot_icon")
    if confirm; then
      eval "$reboot_cmd"
    fi
    ;;
  "$shutdown_icon")
    if confirm; then
      eval "$shutdown_cmd"
    fi
    ;;
  esac
}

power
