#!/usr/bin/env bash

# ===================== KONFIGURACJA =====================
# Domyślna przeglądarka - musi być zainstalowana i dostępna w $PATH.
# Podmień tę jedną linię, żeby zmienić domyślną przeglądarkę.
# Dostępne u Ciebie (przykłady, odkomentuj/wpisz właściwą):
#   google-chrome
#   firefox
#   chromium
BROWSER="google-chrome"

# Domyślna wyszukiwarka - prefiks URL, do którego dopisywane jest
# zakodowane zapytanie wpisane w rofi.
# Inne wyszukiwarki (podmień SEARCH_URL_PREFIX niżej, żeby zmienić):
#   Google:      https://www.google.com/search?q=
#   DuckDuckGo:  https://duckduckgo.com/?q=
#   Bing:        https://www.bing.com/search?q=
SEARCH_URL_PREFIX="https://www.google.com/search?q="
# ==========================================================

ROFI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"

if ! command -v "$BROWSER" >/dev/null 2>&1; then
  notify-send "rofi-web-search" "Przeglądarka '$BROWSER' nie została znaleziona w PATH." 2>/dev/null
  exit 1
fi

# Puste stdin -> rofi działa jako czyste pole wpisywania, bez listy
# do wyboru. "-theme-str listview{lines:0;}" wyłącza zarezerwowane,
# puste miejsce pod polem (które normalnie theme.rasi rezerwuje dla
# 8 wierszy listy) - bez tego byłby duży, pusty prostokąt pod "Szukaj".
# Enter na pustym polu po prostu nic nie robi (patrz niżej).
# share.rasi (importowane przez theme.rasi) ustawia globalnie
# configuration{timeout{delay:10; action:"kb-cancel";}} - to twardy
# zegar liczony od otwarcia okna, NIE resetowany przez pisanie, więc
# okno zamykało się po 10s nawet w trakcie wpisywania zapytania.
# Nadpisujemy to tylko lokalnie (delay:0 = wyłączony timeout),
# nie dotykając share.rasi, żeby inne menu rofi (drun/run/window)
# nadal miały swój timeout.
query=$(echo -n "" | rofi -dmenu -p "Google 󱦞:" \
  -theme "$ROFI_CONFIG_DIR/theme.rasi" \
  -theme-str "listview{lines:0;}" \
  -theme-str "configuration{timeout{delay:0;}}")

[[ -z "$query" ]] && exit 0

encoded_query=$(python3 -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))' "$query")

# Jeśli przeglądarka już działa, standardowe zachowanie google-chrome/
# firefox/chromium po podaniu URL-a to otwarcie nowej karty w istniejącym
# oknie (a nie druga instancja) - nic dodatkowego nie trzeba robić.
"$BROWSER" "${SEARCH_URL_PREFIX}${encoded_query}" >/dev/null 2>&1 &
disown 2>/dev/null
