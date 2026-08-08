#!/usr/bin/env bash
# ~/.config/suckless/scripts/nowa-notatka.sh

# Preferowany terminal — zmień tu, jeśli chcesz użyć innego niż ghostty.
# Jeśli podany terminal nie zostanie znaleziony w systemie, skrypt sam
# spróbuje kolejnych opcji (TERMINAL ze zmiennej środowiskowej, potem
# x-terminal-emulator, na końcu xterm).
#PREFERRED_TERMINAL="ghostty"
PREFERRED_TERMINAL="st"

# Ścieżka do samego siebie (potrzebna do ponownego uruchomienia w terminalu)
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"

# Jeśli stdin NIE jest terminalem (czyli odpalono z dwm/.desktop bez terminala),
# otwórz terminal i uruchom siebie ponownie w jego wnętrzu.
if [ ! -t 0 ]; then
  if command -v "$PREFERRED_TERMINAL" &>/dev/null; then
    exec "$PREFERRED_TERMINAL" -e "$SCRIPT_PATH"
  elif [ -n "$TERMINAL" ] && command -v "$TERMINAL" &>/dev/null; then
    exec "$TERMINAL" -e "$SCRIPT_PATH"
  elif command -v x-terminal-emulator &>/dev/null; then
    exec x-terminal-emulator -e "$SCRIPT_PATH"
  elif command -v xterm &>/dev/null; then
    exec xterm -e "$SCRIPT_PATH"
  else
    notify-send "Błąd" "Nie znaleziono żadnego terminala" 2>/dev/null
    exit 1
  fi
fi

NOTES_DIR="$HOME/!0 Inbox"
EXT=".md"

mkdir -p "$NOTES_DIR"

read -rp "Tytuł: " TITLE

SAFE_TITLE=$(echo "$TITLE" | tr -d '/\\:')
SAFE_TITLE=$(echo "$SAFE_TITLE" | tr ' ' '-')
SAFE_TITLE=$(echo "$SAFE_TITLE" | tr -cd '[:alnum:]-')
SAFE_TITLE=$(echo "$SAFE_TITLE" | sed 's/^-*//; s/-*$//')
SAFE_TITLE="${SAFE_TITLE:0:50}"

DATESTAMP=$(date +%Y-%m-%d-%H%M%S)

if [ -z "$SAFE_TITLE" ]; then
  FILENAME="$NOTES_DIR/${DATESTAMP}${EXT}"
else
  FILENAME="$NOTES_DIR/${DATESTAMP}-${SAFE_TITLE}${EXT}"
fi

{
  echo "## $TITLE"
  echo ""
  echo "*Utworzono: $(date +'%Y-%m-%d %H:%M')*"
  echo "*Autor: Hubert Wrześniak*"
  echo ""
  echo ""
} >"$FILENAME"

nvim + "$FILENAME"
