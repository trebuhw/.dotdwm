#!/bin/bash
# Zapisz jako ~/.config/suckless/scripts/screenshot-save-inbox.sh

# Jeśli przekazano flagę "-s", to używamy trybu zaznaczenia, w przeciwnym razie full
MODE=$1
TARGET="$HOME/!0 Inbox"
NAME="screenshot"

mkdir -p "$TARGET"

if [ "$MODE" == "-s" ]; then
  scrot -s '/tmp/%Y-%m-%d-%H%M%S-'$NAME'-$wx$h.jpg' -e "mv \$f '$TARGET/'"
else
  scrot '/tmp/%Y-%m-%d-%H%M%S-'$NAME'-$wx$h.jpg' -e "mv \$f '$TARGET/'"
fi
