#!/usr/bin/env bash
#
# Gemini
# gdrive-toggle.sh
# Skrypt do ręcznego montowania/odmontowywania Google Drive z optymalizacjami.

REMOTE="gdrive:"
MOUNTPOINT="$HOME/GoogleDrive"
LOGFILE="$HOME/.local/log/rclone-toggle.log"

mkdir -p "$MOUNTPOINT" "$(dirname "$LOGFILE")"

# Funkcja wysyłająca powiadomienie do dunst
send_notify() {
  notify-send -u low -t 2000 "Google Drive" "$1"
}

unmount_drive() {
  echo "$(date): Próba odmontowania..." >>"$LOGFILE"
  fusermount -u "$MOUNTPOINT" 2>>"$LOGFILE"

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
    --log-file "$LOGFILE" \
    --log-level INFO \
    --daemon 2>>"$LOGFILE"

  # Czekaj na potwierdzenie montażu
  sleep 2
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
