#!/bin/bash
# clipboard.sh — schowek z historią dla X11
# Użycie:
#   clipboard.sh --daemon   → uruchom w tle (np. z ~/.xinitrc lub autostart)
#   clipboard.sh            → otwórz menu dmenu

HISTFILE="$HOME/.clipboard_history"

touch "$HISTFILE"

# ─── DAEMON ──────────────────────────────────────────────────────────────────
run_daemon() {
  local last=""

  while true; do
    clip=$(xsel --clipboard --output 2>/dev/null)

    if [[ -n "$clip" ]]; then
      cksum=$(printf "%s" "$clip" | md5sum | cut -d' ' -f1)

      if [[ "$cksum" != "$last" ]]; then
        last="$cksum"
        line=$(printf "%s" "$clip" | tr '\n\t' '  ' | sed 's/  */ /g; s/^ //; s/ $//')

        if [[ -n "$line" ]]; then
          tmp=$(mktemp)
          {
            echo "$line"
            cat "$HISTFILE"
          } |
            awk '!seen[$0]++' |
            head -n 200 >"$tmp"
          mv "$tmp" "$HISTFILE"
        fi
      fi
    fi

    sleep 2
  done
}

# ─── MENU ────────────────────────────────────────────────────────────────────
show_menu() {
  selected=$({
    echo "--- Clear clipboard history ---"
    cat "$HISTFILE"
  } |
    dmenu -i -l 20 -p "Schowek:")

  case "$selected" in
  "--- Clear clipboard history ---")
    truncate -s 0 "$HISTFILE"
    xsel --clipboard --clear
    ;;
  "")
    ;;
  *)
    printf "%s" "$selected" | xsel --clipboard --input
    printf "%s" "$selected" | xsel --primary --input
    xdotool type --clearmodifiers "$selected"
    ;;
  esac
}

# ─── MAIN ────────────────────────────────────────────────────────────────────
case "$1" in
--daemon) run_daemon ;;
*) show_menu ;;
esac
