#!/usr/bin/env bash

# Ikony i nazwy dla profili w Tuned
performance_icon="󱓞"
balanced_icon="󰓅"
powersave_icon="󰁻"
throughput_icon="󰓔"

ROFI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"

# Pobieranie aktualnego aktywnego profilu tuned
get_current_profile() {
  tuned-adm active 2>/dev/null | awk -F': ' '{print $2}' || echo "unknown"
}

# Ustawianie profilu za pomocą tuned-adm
set_tuned_profile() {
  local profile="$1"

  if sudo tuned-adm profile "$profile" 2>/dev/null; then
    notify-send "⚡ Tuned Profile" "Set to: $profile" --expire-time=2000 -u normal
  else
    notify-send "❌ Błąd" "Nie udało się zmienić profilu (brak uprawnień?)" --expire-time=3000 -u critical
  fi
}

# Główne menu
main() {
  local current_profile
  current_profile=$(get_current_profile)

  # Definiujemy opcje na sztywno: ikona + nazwa profilu tuned
  # Możesz łatwo dopisać lub usunąć odpowiednie linie
  local options=""
  options+="$performance_icon performance\n"
  options+="$balanced_icon balanced\n"
  options+="$powersave_icon powersave\n"
  options+="$throughput_icon throughput-performance"

  # Wywołanie Rofi
  local selected
  selected=$(echo -e "$options" | rofi -dmenu \
    -i \
    -p "Tuned Profile" \
    -mesg "Aktywny: $current_profile" \
    -theme "$ROFI_CONFIG_DIR/performance-profile.rasi")

  # Wyciągnięcie nazwy profilu (drugie słowo w wybranej linijce)
  local profile_mode
  profile_mode=$(echo "$selected" | awk '{print $2}')

  # Mapowanie skróconej nazwy przycisku na faktyczną nazwę profilu w tuned-adm
  if [[ "$profile_mode" == "performance" ]]; then
    profile_mode="latency-performance"
  fi

  if [[ -n "$profile_mode" ]]; then
    set_tuned_profile "$profile_mode"
  fi
}

main
