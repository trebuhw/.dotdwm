#!/usr/bin/env bash
#
# rclone-gdrive-start.sh
#
# Montuje/odmontowuje Google Drive przez rclone (toggle).
# Dokumenty Google (Docs/Sheets/Slides) pojawiają się jako pliki .url
# (link do przeglądarki), NIGDY jako wyeksportowane .docx/.xlsx/.pptx.
#
# Użycie:
# ~/.config/suckless/scripts/rclone-gdrive-start.sh  # pierwsze uruchomienie: montuje
# ~/.config/suckless/scripts/rclone-gdrive-start.sh # drugie uruchomienie: odmontowuje
#
# Autostart w dwm: dodaj do ~/.xinitrc PRZED `exec dwm` lub do
# autostart w DWM : ~/.config/suckless/dwm/autostart.sh
# ~/.config/suckless/scripts/rclone-gdrive-start.sh &
# pełna ścieżka lub jeśli w ~/.config/suckless/scripts/ jest PATH wystarczy nazwa skryptu

# Procedura awaryjna na wypadek przyszłego zawieszenia
# lsof +D ~/GoogleDrive          # sprawdź co blokuje
# fusermount -u ~/GoogleDrive     # zwykła próba
# fusermount -uz ~/GoogleDrive    # lazy unmount, jeśli zwykła nie działa
# pkill -x rclone                 # ostateczność, jeśli nic innego nie pomaga

set -uo pipefail

REMOTE="gdrive:"
MOUNTPOINT="$HOME/GoogleDrive"
LOGDIR="$HOME/.local/log"
LOGFILE="$LOGDIR/rclone-mount.log"

mkdir -p "$MOUNTPOINT" "$LOGDIR"

notify() {
  # $1 = pilność (low/normal/critical), $2 = tytuł, $3 = treść
  notify-send -u "$1" "$2" "$3"
}

# --- Jeśli już zamontowane, ODMONTUJ (toggle) ---
if mountpoint -q "$MOUNTPOINT"; then

  # Sprawdź, czy są zaległe uploady (vfs-write-back jeszcze nie skończył).
  # Bez tego fusermount może dostać "Device or resource busy", jeśli
  # np. właśnie skasowałeś plik (trafia do .Trash-*, rclone wysyła to na Drive).
  WAITED=0
  MAX_WAIT=30
  while [ "$WAITED" -lt "$MAX_WAIT" ]; do
    PENDING=$(tail -n 5 "$LOGFILE" 2>/dev/null | grep -c "queuing for upload\|uploading 0, total" || true)
    UPLOADING=$(tail -n 1 "$LOGFILE" 2>/dev/null | grep -oP 'to upload \K[0-9]+' || echo 0)
    if [ "${UPLOADING:-0}" = "0" ]; then
      break
    fi
    echo "$(date): Czekam na zakończenie uploadu przed odmontowaniem (${WAITED}s)..." >>"$LOGFILE"
    sleep 2
    WAITED=$((WAITED + 2))
  done

  notify normal "Google Drive" "Odmontowuję..."
  echo "$(date): Rozpoczynam odmontowanie" >>"$LOGFILE"

  if fusermount -u "$MOUNTPOINT" 2>>"$LOGFILE"; then
    notify normal "Google Drive" "Odmontowano pomyślnie."
    echo "$(date): Odmontowano pomyślnie" >>"$LOGFILE"
  else
    # Jedna dodatkowa próba po krótkim odczekaniu -
    # czasem upload kończy się chwilę po pierwszej próbie.
    echo "$(date): Pierwsza próba nieudana, czekam 5s i próbuję ponownie" >>"$LOGFILE"
    sleep 5
    if fusermount -u "$MOUNTPOINT" 2>>"$LOGFILE"; then
      notify normal "Google Drive" "Odmontowano pomyślnie (druga próba)."
      echo "$(date): Odmontowano pomyślnie (druga próba)" >>"$LOGFILE"
    else
      notify critical "Google Drive — BŁĄD" "Odmontowanie nie powiodło się (folder w użyciu?). Sprawdź: $LOGFILE"
      echo "$(date): BŁĄD — odmontowanie nie powiodło się, prawdopodobnie folder w użyciu (sprawdź: lsof +D $MOUNTPOINT)" >>"$LOGFILE"
      exit 1
    fi
  fi
  exit 0
fi

# --- Nie zamontowane — montujemy ---
notify normal "Google Drive" "Rozpoczynam montowanie..."
echo "$(date): Start montowania $REMOTE -> $MOUNTPOINT" >>"$LOGFILE"

rclone mount "$REMOTE" "$MOUNTPOINT" \
  --vfs-cache-mode writes \
  --vfs-write-back 10s \
  --vfs-cache-max-age 24h \
  --dir-cache-time 1m \
  --poll-interval 15s \
  --attr-timeout 1m \
  --buffer-size 16M \
  --transfers 4 \
  --checkers 8 \
  --tpslimit 10 \
  --drive-export-formats url \
  --log-file "$LOGFILE" \
  --log-level INFO \
  --daemon

# --- Czekamy chwilę i sprawdzamy, czy mount faktycznie ruszył ---
SUCCESS=0
for i in $(seq 1 15); do
  if mountpoint -q "$MOUNTPOINT"; then
    SUCCESS=1
    break
  fi
  sleep 1
done

if [ "$SUCCESS" -eq 1 ]; then
  notify normal "Google Drive" "Zamontowano pomyślnie: $MOUNTPOINT"
  echo "$(date): Zamontowano pomyślnie" >>"$LOGFILE"
else
  notify critical "Google Drive — BŁĄD" "Montowanie nie powiodło się. Sprawdź: $LOGFILE"
  echo "$(date): BŁĄD — montowanie nie powiodło się w oczekiwanym czasie" >>"$LOGFILE"
  exit 1
fi
