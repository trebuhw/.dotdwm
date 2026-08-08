#!/usr/bin/env bash
#
#Claude
# gdrive-on-off.sh
# Skrypt do ręcznego montowania/odmontowywania Google Drive z optymalizacjami.
# Podpięty pod MODKEY+Ctrl+g w dwm.

REMOTE="gdrive:"
MOUNTPOINT="$HOME/GoogleDrive"
LOGFILE="$HOME/.local/log/rclone-toggle.log"
LOCKFILE="$HOME/.local/log/gdrive-toggle.lock"
RC_ADDR="127.0.0.1:5572"

mkdir -p "$MOUNTPOINT" "$(dirname "$LOGFILE")"

# Blokada przed równoległym uruchomieniem (np. dwukrotny szybki klik skrótu)
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  notify-send -u low -t 1500 "Google Drive" "Operacja już w toku, poczekaj..."
  exit 1
fi

# Funkcja wysyłająca powiadomienie do dunst
send_notify() {
  notify-send -u low -t 2000 "Google Drive" "$1"
}

unmount_drive() {
  echo "$(date): Próba odmontowania..." >>"$LOGFILE"

  # Najpierw próba grzecznego zamknięcia przez rc — flushuje VFS cache
  # zanim mount zostanie odłączony (ważne jeśli coś było edytowane lokalnie).
  rclone rc core/quit --rc-addr="$RC_ADDR" >>"$LOGFILE" 2>&1
  sleep 1

  if mountpoint -q "$MOUNTPOINT"; then
    fusermount -u "$MOUNTPOINT" 2>>"$LOGFILE"
  fi

  # Jeśli nadal zajęte, wymuszamy lazy unmount
  if mountpoint -q "$MOUNTPOINT"; then
    fusermount -uz "$MOUNTPOINT" 2>>"$LOGFILE"
  fi

  if ! mountpoint -q "$MOUNTPOINT"; then
    send_notify "Odmontowano pomyślnie"
  else
    send_notify "BŁĄD: Nie udało się odmontować"
  fi
}

mount_drive() {
  # Sprawdzenie czy rclone jest zainstalowany
  if ! command -v rclone &>/dev/null; then
    send_notify "BŁĄD: Brak rclone w systemie"
    exit 1
  fi

  send_notify "Montowanie..."

  rclone mount "$REMOTE" "$MOUNTPOINT" \
    --vfs-cache-mode full \
    --vfs-cache-max-age 24h \
    --vfs-cache-max-size 10G \
    --dir-cache-time 1h \
    --vfs-read-ahead 128M \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 512M \
    --no-modtime \
    --buffer-size 16M \
    --rc --rc-addr="$RC_ADDR" --rc-no-auth \
    --log-file "$LOGFILE" \
    --log-level INFO \
    --daemon 2>>"$LOGFILE"

  # Czekaj aż mount faktycznie się pojawi (do ~15s), zamiast sztywnego sleep 2
  for i in $(seq 1 15); do
    mountpoint -q "$MOUNTPOINT" && break
    sleep 1
  done

  if mountpoint -q "$MOUNTPOINT"; then
    send_notify "Zamontowano pomyślnie"
  else
    send_notify "BŁĄD: Sprawdź logi"
  fi
}

# Główna logika przełącznika
if mountpoint -q "$MOUNTPOINT"; then
  unmount_drive
else
  mount_drive
fi
