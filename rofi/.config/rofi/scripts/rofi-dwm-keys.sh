#!/usr/bin/env bash
# dwm-keys.sh — przeglądarka skrótów klawiszowych dwm przez rofi

CONFIG="${DWM_CONFIG:-$HOME/.config/suckless/dwm/config.def.h}"
ROFI_THEME="${DWM_ROFI_THEME:-$HOME/.config/rofi/dwm-keys.rasi}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dwm-keys.cache"

[[ ! -f "$CONFIG" ]] && {
  notify-send "dwm-keys" "Nie znaleziono: $CONFIG"
  exit 1
}

# --- mapowanie modyfikatorów ---
mod_name() {
  local m="$1"
  local result=""

  [[ "$m" == *MODKEY* ]] && result+="Super+"
  [[ "$m" == *ShiftMask* ]] && result+="Shift+"
  [[ "$m" == *ControlMask* ]] && result+="Ctrl+"
  [[ "$m" == *Mod1Mask* ]] && result+="Alt+"

  [[ -z "$result" ]] && result="(brak)+"
  echo "${result%+}"
}

# --- mapowanie klawiszy ---
key_name() {
  local k="${1#XK_}"
  k="${k#XF86XK_}"

  case "$k" in
  Return) echo "Enter" ;;
  space) echo "Space" ;;
  Print) echo "PrtSc" ;;
  minus) echo "-" ;;
  equal) echo "=" ;;
  comma) echo "," ;;
  period) echo "." ;;
  Up) echo "↑" ;;
  Down) echo "↓" ;;
  Left) echo "←" ;;
  Right) echo "→" ;;
  AudioRaiseVolume) echo "Vol+" ;;
  AudioLowerVolume) echo "Vol-" ;;
  AudioMute) echo "Mute" ;;
  AudioPlay) echo "Play" ;;
  AudioNext) echo "Next" ;;
  AudioPrev) echo "Prev" ;;
  AudioStop) echo "Stop" ;;
  MonBrightnessUp) echo "Bright+" ;;
  MonBrightnessDown) echo "Bright-" ;;
  *) echo "$k" ;;
  esac
}

# --- parsowanie keys[] ---
parse_keys() {
  local in_keys=0
  local depth=0

  while IFS= read -r line; do

    [[ "$line" =~ static.*Key.*keys\[\] ]] && in_keys=1
    [[ $in_keys -eq 0 ]] && continue

    local open close
    open=$(grep -o '{' <<<"$line" | wc -l)
    close=$(grep -o '}' <<<"$line" | wc -l)
    depth=$((depth + open - close))

    [[ $depth -lt 0 ]] && break
    [[ "$line" != *XK_* ]] && continue
    [[ "$line" =~ TAGKEYS ]] && continue

    local desc=""
    local mod key combo

    # ##opis
    if [[ "$line" == *"##"* ]]; then
      desc=$(sed 's/.*##[[:space:]]*//' <<<"$line")

    # /*opis*/
    elif [[ "$line" == *"/*"* && "$line" == *"*/"* ]]; then
      desc=$(grep -o '/\*.*\*/' <<<"$line" | sed 's|/\*||; s|\*/||')
    fi

    mod=$(sed 's/.*{\s*\([^,]*\)\s*,\s*XK.*/\1/' <<<"$line" | tr -d ' ')
    key=$(grep -o 'XF86XK_[A-Za-z]*\|XK_[A-Za-z0-9_]*' <<<"$line" | head -1)

    [[ -z "$key" ]] && continue

    combo="$(mod_name "$mod")+$(key_name "$key")"

    echo "$combo|$desc"

  done <"$CONFIG"

  # TAGKEYS
  echo "Super+[1-9]|przełącz tag"
  echo "Super+Ctrl+[1-9]|pokaż/ukryj tag"
  echo "Super+Shift+[1-9]|przenieś okno do tagu"
  echo "Super+Ctrl+Shift+[1-9]|dodaj okno do tagu"
}

# --- cache ---
if [[ ! -f "$CACHE" || "$CONFIG" -nt "$CACHE" ]]; then
  parse_keys >"$CACHE.raw"

  awk -F'|' '
  {
    printf "%-32s - %s\n", $1, $2
  }
  ' "$CACHE.raw" >"$CACHE"
fi

# --- rofi ---
rofi_args=(
  -dmenu
  -i
  -p " skróty dwm"
  -no-custom
  -no-lazy-grab
)

[[ -f "$ROFI_THEME" ]] && rofi_args+=(-theme "$ROFI_THEME")

cat "$CACHE" | rofi "${rofi_args[@]}"
