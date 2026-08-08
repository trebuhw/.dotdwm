#!/bin/bash
# wersja ze powiadomieniem w języku polskim

DIR1="$HOME/!0 Inbox"
DIR2="$HOME/OneDrive/00 Inbox"

send_notify() {
  notify-send -u low -t 4000 "$1" "$2"
}

SYNC_OUTPUT=$(unison -perms 0 "$DIR1" "$DIR2" -batch 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  if echo "$SYNC_OUTPUT" | grep -q "Nothing to do"; then
    send_notify "Synchronizacja Unison" "Brak zmian. Katalogi są identyczne."
  else
    # 1. Wyciągnięcie tekstu z nawiasów
    SUMMARY=$(echo "$SYNC_OUTPUT" | grep "Synchronization complete" | sed -n 's/.*(\(.*\))/\1/p')

    # 2. Tłumaczenie angielskich fraz na polskie w locie
    SUMMARY=$(echo "$SUMMARY" | sed 's/items transferred/przetworzono/g; s/item transferred/przetworzono/g; s/skipped/pominięto/g; s/failed/błędów/g')

    SUMMARY=${SUMMARY:-"Zakończono pomyślnie, ale statystyki są niedostępne."}

    send_notify "Synchronizacja Unison" "Sukces:\n$SUMMARY"
  fi
elif [ $EXIT_CODE -eq 1 ]; then
  send_notify "⚠️ Unison - Konflikt" "Pominięto pliki ze względu na konflikty edycji! Zobacz terminal."
else
  send_notify "❌ Błąd Unison" "Operacja krytycznie przerwana. Kod: $EXIT_CODE"
fi
