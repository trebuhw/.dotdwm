#!/usr/bin/env bash

# --- ZMIENNE KONFIGORYJSKIE ---
REMOTE="gdrive:"
MOUNTPOINT="$HOME/GoogleDrive"
# SOURCE_DIR="$HOME/Obrazy/Wallpaper/"
SOURCE_DIR="$HOME/.dotdwm/wallpaper/Obrazy/Wallpaper/"
GDRIVE_TARGET="$MOUNTPOINT/HW/10 Osoby/11 Hubert/11.20 Obrazy/11.22 Tapety/"
ONEDRIVE_TARGET="$HOME/OneDrive/HW/10 Osoby/11 Hubert/11.20 Obrazy/11.22 Tapety/"

ALREADY_MOUNTED=false

# Funkcja wysyłająca powiadomienie do dunst
send_notify() {
  notify-send -u low -t 2000 "Sync Tapet (Mirror)" "$1"
}

# 1. Sprawdzenie i ewentualne zamontowanie Google Drive
if mountpoint -q "$MOUNTPOINT"; then
  echo "Google Drive jest już zamontowany."
  ALREADY_MOUNTED=true
else
  echo "Montowanie Google Drive..."
  send_notify "Montowanie Google Drive..."

  rclone mount "$REMOTE" "$MOUNTPOINT" \
    --vfs-cache-mode full \
    --vfs-cache-max-age 24h \
    --vfs-cache-max-size 10G \
    --dir-cache-time 1h \
    --daemon

  # Czekaj na potwierdzenie montażu (maksymalnie 10 sekund)
  echo "Oczekiwanie na zamontowanie..."
  for i in {1..10}; do
    if mountpoint -q "$MOUNTPOINT"; then
      echo "Zamontowano pomyślnie."
      break
    fi
    sleep 1
  done

  if ! mountpoint -q "$MOUNTPOINT"; then
    echo "BŁĄD: Nie udało się zamontować Google Drive."
    send_notify "BŁĄD: Nie udało się zamontować Google Drive"
    exit 1
  fi
fi

# 2. Wykonanie synchronizacji lustrzanej (rsync z --delete)
echo "Rozpoczynam synchronizację (z usuwaniem usuniętych plików)..."
send_notify "Synchronizowanie i czyszczenie tapet..."

# Rsync do Google Drive (flaga --delete usuwa pliki w celu, których nie ma w źródle)
rsync -av --delete --no-links --progress "$SOURCE_DIR" "$GDRIVE_TARGET"

# Rsync do OneDrive (flaga --delete usuwa pliki w celu, których nie ma w źródle)
rsync -av --delete --no-links --progress "$SOURCE_DIR" "$ONEDRIVE_TARGET"

echo "Synchronizacja zakończona."

# 3. Odmontowanie Google Drive (tylko jeśli został zamontowany przez ten skrypt)
if [ "$ALREADY_MOUNTED" = false ]; then
  echo "Odmontowywanie Google Drive..."
  send_notify "Odmontowywanie Google Drive..."
  fusermount -uz "$MOUNTPOINT"

  if mountpoint -q "$MOUNTPOINT"; then
    echo "Ostrzeżenie: Nie udało się poprawnie odmontować dysku."
    send_notify "Ostrzeżenie: Nie odmontowano poprawnie"
  else
    echo "Odmontowano pomyślnie."
    send_notify "Gotowe! Zsynchronizowano i odmontowano."
  fi
else
  echo "Google Drive był zamontowany wcześniej – pozostawiam zamontowany."
  send_notify "Gotowe! Zsynchronizowano (Drive pozostał zamontowany)."
fi
