#!/usr/bin/env bash
# mc-keys.sh — przeglądarka skrótów klawiszowych Midnight Commander przez rofi
# Czyta ręcznie opisany plik mc-key.md (analogicznie do dwm-key.md) i pokazuje w rofi.

KEYFILE="${MC_KEYFILE:-$HOME/.config/mc/mc-key.md}"
ROFI_THEME="${MC_ROFI_THEME:-$HOME/.config/rofi/dwm-keys.rasi}"

[[ ! -f "$KEYFILE" ]] && {
  notify-send "mc-keys" "Nie znaleziono: $KEYFILE"
  exit 1
}

rofi_args=(
  -dmenu
  -i
  -p " skróty mc"
  -no-custom
  -no-lazy-grab
)
[[ -f "$ROFI_THEME" ]] && rofi_args+=(-theme "$ROFI_THEME")

# pomiń linie komentarzy (#) i puste, pokaż resztę tak jak jest sformatowana
grep -v '^[[:space:]]*#' "$KEYFILE" | grep -v '^[[:space:]]*$' | rofi "${rofi_args[@]}"
