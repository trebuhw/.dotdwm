#!/bin/bash
# clipboard.sh — schowek z historią dla X11
# Użycie:
#   clipboard.sh --daemon   → uruchom w tle (np. z ~/.xinitrc lub autostart)
#   clipboard.sh            → otwórz menu fzf

HISTFILE="$HOME/.clipboard_history"
SCRIPT="$(realpath "$0")"

touch "$HISTFILE"

# ─── DAEMON ──────────────────────────────────────────────────────────────────
run_daemon() {
  echo "Daemon PID: $$"
  local last=""

  while true; do
    clip=$(xsel --clipboard --output 2>/dev/null)

    if [[ -n "$clip" ]]; then
      # Suma kontrolna zamiast porównania całego tekstu
      cksum=$(printf "%s" "$clip" | md5sum | cut -d' ' -f1)

      if [[ "$cksum" != "$last" ]]; then
        last="$cksum"
        # Jedna linia, bez zbędnych spacji
        line=$(printf "%s" "$clip" | tr '\n\t' '  ' | sed 's/  */ /g; s/^ //; s/ $//')

        if [[ -n "$line" ]]; then
          tmp=$(mktemp)
          # Nowy wpis na górze, bez duplikatów, max 200 wpisów
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
  # Tymczasowy skrypt do usuwania wpisu (fzf execute nie obsługuje {} w sed bez tego)
  local del_script
  del_script=$(mktemp /tmp/clip_del.XXXX)
  chmod +x "$del_script"
  cat >"$del_script" <<'EOF'
#!/bin/bash
# $1 = linia do usunięcia
grep -vxF "$1" "$HOME/.clipboard_history" > /tmp/.clip_tmp && \
  mv /tmp/.clip_tmp "$HOME/.clipboard_history"
EOF

  local clear_script
  clear_script=$(mktemp /tmp/clip_clear.XXXX)
  chmod +x "$clear_script"
  cat >"$clear_script" <<EOF
#!/bin/bash
truncate -s 0 "\$HOME/.clipboard_history"
EOF

  selected=$(fzf \
    --layout=reverse \
    --border=rounded \
    --prompt='📋 Schowek: ' \
    --header='Enter: kopiuj  |  Ctrl-X: usuń wpis  |  Ctrl-L: wyczyść wszystko' \
    --bind "ctrl-x:execute(\"$del_script\" {})+reload(cat \"\$HOME/.clipboard_history\")" \
    --bind "ctrl-l:execute(\"$clear_script\")+reload(cat \"\$HOME/.clipboard_history\")" \
    <"$HISTFILE")

  rm -f "$del_script" "$clear_script"

  if [[ -n "$selected" ]]; then
    printf "%s" "$selected" | xsel --clipboard --input
    printf "%s" "$selected" | xsel --primary --input
    echo "✓ Skopiowano: ${selected:0:60}"
  fi
}

# ─── MAIN ────────────────────────────────────────────────────────────────────
case "$1" in
--daemon) run_daemon ;;
*) show_menu ;;
esac
