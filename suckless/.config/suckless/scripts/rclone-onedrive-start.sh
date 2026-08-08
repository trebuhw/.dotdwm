#!/usr/bin/env bash
#
# rclone-onedrive-start.sh
# Montuje OneDrive przez rclone i w tle "rozgrzewa" cache,
# ściągając wszystkie pliki lokalnie (pełna kopia w VFS cache).
#
# Użycie: dodaj do autostart.sh (obok wpisu dla Google Drive):
#   ~/.config/suckless/scripts/rclone-onedrive-start.sh &

set -u

REMOTE="onedrive:" # nazwa remote z `rclone config`
MOUNTPOINT="$HOME/OneDrive"
LOGDIR="$HOME/.local/log"
LOGFILE="$LOGDIR/rclone-onedrive-mount.log"
WARMUP_LOG="$LOGDIR/rclone-onedrive-warmup.log"

mkdir -p "$MOUNTPOINT" "$LOGDIR"

# --- Zabezpieczenie przed podwójnym mountem ---
if mountpoint -q "$MOUNTPOINT"; then
  echo "$(date): $MOUNTPOINT już zamontowany, pomijam mount." >>"$LOGFILE"
else
  echo "$(date): Montuję $REMOTE -> $MOUNTPOINT" >>"$LOGFILE"

  rclone mount "$REMOTE" "$MOUNTPOINT" \
    --vfs-cache-mode full \
    --vfs-cache-max-age 720h \
    --vfs-cache-max-size 50G \
    --vfs-read-chunk-size 32M \
    --vfs-read-chunk-size-limit 512M \
    --buffer-size 32M \
    --dir-cache-time 5m \
    --poll-interval 30s \
    --transfers 4 \
    --checkers 8 \
    --tpslimit 10 \
    --log-file "$LOGFILE" \
    --log-level INFO \
    --daemon

  for i in $(seq 1 30); do
    mountpoint -q "$MOUNTPOINT" && break
    sleep 1
  done
fi

# --- Rozgrzewanie cache ---
(
  echo "$(date): Start rozgrzewania cache" >>"$WARMUP_LOG"

  nice -n 19 ionice -c3 find "$MOUNTPOINT" -type f -print0 2>>"$WARMUP_LOG" |
    xargs -0 -P 4 -I{} sh -c 'cat "{}" > /dev/null 2>>"'"$WARMUP_LOG"'"'

  echo "$(date): Zakończono rozgrzewanie cache" >>"$WARMUP_LOG"
) &

disown

exit 0
