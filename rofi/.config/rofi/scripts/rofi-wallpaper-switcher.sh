#!/usr/bin/env bash

ROFI_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/rofi"
WALL_DIR="$HOME/Pictures/Wallpaper"
CACHE_DIR="$HOME/.cache/wallpaper-rofi"
CURRENT_LINK="$WALL_DIR/!current.png"

# 0 = zamknij rofi od razu po wyborze tapety
# 1 = zostaw rofi otwarte po wyborze (podgląd na żywo kolejnych tapet,
#     zamknięcie dopiero przez Escape) - dotychczasowe zachowanie
KEEP_OPEN=0

# Blokada - jeśli skrypt już działa (np. czeka w pętli poniżej, bo
# zapomniałeś nacisnąć Escape), drugie wywołanie (np. przez ten sam
# skrót klawiszowy) po prostu nic nie robi, zamiast odpalać drugą,
# niezależną instancję i drugie okno rofi.
LOCK_FILE="/tmp/rofi-wallpaper-switcher.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
  notify-send "Wallpaper" "Switcher już jest otwarty (Escape, żeby zamknąć)." 2>/dev/null
  exit 0
fi

[[ -d "$WALL_DIR" ]] || exit 0
mkdir -p "$CACHE_DIR"

# ImageMagick 7 to "magick", starsze systemy mają tylko "convert" (IM6).
# Bierzemy to, co jest dostępne.
CONVERT_CMD="convert"
command -v magick >/dev/null 2>&1 && CONVERT_CMD="magick"

declare -a img_names
declare -a thumb_paths

for img_path in "$WALL_DIR"/*; do
  [[ -f "$img_path" ]] || continue
  img_name=$(basename "$img_path")

  [[ "$img_name" == "!current.png" ]] && continue
  # tylko realne pliki obrazów - inaczej próbujemy robić miniatury
  # z przypadkowych plików (np. .rasi, .txt) i tylko marnujemy czas
  case "$img_name" in
  *.jpg | *.JPG | *.jpeg | *.JPEG | *.png | *.PNG | *.webp | *.WEBP | *.bmp | *.BMP) ;;
  *) continue ;;
  esac

  # Miniatura ZAWSZE jako .png, niezależnie od formatu źródłowego.
  # Bez tego: "-background none" nie ma efektu dla plików zapisywanych
  # jako .jpg (JPG nie ma kanału alfa), więc przezroczyste tło
  # renderuje się jako czarne pasy przy niekwadratowych zdjęciach.
  thumb_path="$CACHE_DIR/${img_name%.*}.png"

  if [[ ! -f "$thumb_path" ]]; then
    "$CONVERT_CMD" "$img_path" -thumbnail 400x400 -background none -gravity center -extent 400x400 "$thumb_path" 2>/dev/null
  fi

  img_names+=("$img_name")
  thumb_paths+=("$thumb_path")
done

[[ ${#img_names[@]} -eq 0 ]] && exit 0

# Rofi w -dmenu nie ma trybu "zastosuj i nie zamykaj", więc odtwarzamy to
# pętlą: Enter stosuje tapetę i (przy KEEP_OPEN=1) OD RAZU otwiera rofi
# ponownie - wygląda jak "nie zamknęło się", dając podgląd na żywo
# kolejnych tapet. Przy KEEP_OPEN=0 pętla i tak istnieje (dla Escape
# poniżej), ale wykonuje się tylko raz - patrz break po feh.
# Escape -> puste "selected" (zweryfikowane) -> wychodzimy z pętli,
# rofi faktycznie się zamyka - niezależnie od KEEP_OPEN.
while true; do
  selected=$(
    for i in "${!img_names[@]}"; do
      printf '%s\0icon\037%s\n' "${img_names[$i]}" "${thumb_paths[$i]}"
    done | rofi -dmenu -i -p "󰥸 : " -theme "$ROFI_CONFIG_DIR/wallpaper.rasi"
  )

  [[ -z "$selected" ]] && break

  ln -sf "$WALL_DIR/$selected" "$CURRENT_LINK"
  feh --bg-fill "$CURRENT_LINK"

  # KEEP_OPEN=0 -> tapeta zastosowana, kończymy od razu (jedno okno rofi)
  # KEEP_OPEN=1 -> wracamy na górę pętli i pokazujemy rofi ponownie
  [[ "$KEEP_OPEN" -eq 0 ]] && break
done
