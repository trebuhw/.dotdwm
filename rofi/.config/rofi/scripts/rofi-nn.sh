#!/usr/bin/env bash

NOTES_DIR="$HOME/!0 Inbox/"
mkdir -p "$NOTES_DIR"
cd "$NOTES_DIR" || exit 1

NOTE=$(find . -type f -not -path '*/\.git/*' -not -path '*/node_modules/*' 2>/dev/null |
  sed 's|^\./||' |
  sort |
  {
    echo "--- Usuń notatkę ---"
    cat
  } |
  rofi -dmenu -i -p "Notatki:")

case "$NOTE" in
"--- Usuń notatkę ---")
  # Drugi wybór — która notatka do usunięcia
  TO_DELETE=$(find . -type f -not -path '*/\.git/*' -not -path '*/node_modules/*' 2>/dev/null |
    sed 's|^\./||' |
    sort |
    rofi -dmenu -i -p "Usuń notatkę:")
  if [ -n "$TO_DELETE" ]; then
    rm "$NOTES_DIR/$TO_DELETE"
  fi
  ;;
"")
  exit 0
  ;;
*)
  # Nowa lub istniejąca — nvim otworzy lub utworzy
  nvim "$NOTES_DIR/$NOTE"
  ;;
esac
