#!/usr/bin/env bash

NOTES_DIR="$HOME/Dokumenty/Hubert/Notes/"
mkdir -p "$NOTES_DIR"
cd "$NOTES_DIR" || exit 1

NOTE=$(find . -type f -not -path '*/\.git/*' -not -path '*/node_modules/*' 2>/dev/null |
  sed 's|^\./||' |
  sort |
  { echo "--- Usuń notatkę ---"; cat; } |
  dmenu -i -l 20 -p "Notatki:")

case "$NOTE" in
  "--- Usuń notatkę ---")
    # Drugi wybór — która notatka do usunięcia
    TO_DELETE=$(find . -type f -not -path '*/\.git/*' -not -path '*/node_modules/*' 2>/dev/null |
      sed 's|^\./||' |
      sort |
      dmenu -i -l 20 -p "Usuń notatkę:")
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
