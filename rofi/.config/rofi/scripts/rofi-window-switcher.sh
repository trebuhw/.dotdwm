#!/usr/bin/env bash

ROFI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"

windows=$(wmctrl -lx)
[[ -z "$windows" ]] && exit 0

# Sortujemy po numerze tagu (kolumna ws z wmctrl) - dzięki patchowi
# _NET_WM_DESKTOP w dwm ta wartość jest teraz prawdziwym numerem tagu,
# nie stałym 0.
windows=$(echo "$windows" | sort -k2 -n)

declare -a display_lines
declare -a window_ids

while read -r id ws class host title; do
  [[ -z "$id" || -z "$title" ]] && continue

  # Wyciągamy ładniejszą nazwę aplikacji z klasy
  app_raw=$(echo "$class" | awk -F'.' '{print $NF}')
  [[ -z "$app_raw" || "$app_raw" == "NIL" ]] && app_raw=$(echo "$class" | awk -F'.' '{print $1}')

  # Zamiana pierwszej litery na wielką dla estetyki
  app_name="$(tr '[:lower:]' '[:upper:]' <<<"${app_raw:0:1}")${app_raw:1}"

  full_title=$(wmctrl -l | grep "^$id" | cut -d' ' -f5-)
  [[ -z "$full_title" ]] && continue

  tag_num=$((ws + 1))

  # ID okna NIE jest częścią wyświetlanego tekstu - trafia tylko
  # do window_ids, w tej samej pozycji co odpowiadająca mu linia.
  display_lines+=("[$tag_num] $app_name — $full_title")
  window_ids+=("$id")
done <<<"$windows"

[[ ${#display_lines[@]} -eq 0 ]] && exit 0

selected=$(printf '%s\n' "${display_lines[@]}" | rofi -dmenu \
  -i \
  -p "Windows 󱁵 : " \
  -theme "$ROFI_CONFIG_DIR/window-switcher.rasi")

if [[ -n "$selected" ]]; then
  for i in "${!display_lines[@]}"; do
    if [[ "${display_lines[$i]}" == "$selected" ]]; then
      target_id="${window_ids[$i]}"
      break
    fi
  done

  if [[ -n "$target_id" ]]; then
    # dwm (po patchach focusonnetactive + updatewmdesktop) obsługuje
    # _NET_ACTIVE_WINDOW poprawnie: sam znajduje tag klienta,
    # przełącza widok i fokusuje.
    xdotool windowactivate "$target_id"
  fi
fi
