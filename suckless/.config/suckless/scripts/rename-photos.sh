#!/bin/bash
# rename_photos.sh
# Zmienia nazwy zdjęć/filmów w katalogu na format: RRRR-MM-DD NNNN.ext
# Data jest dobierana w kolejności: EXIF DateTimeOriginal -> EXIF CreateDate
# -> data modyfikacji pliku -> dzisiejsza data (gdy nic innego się nie uda).
# Numeracja NNNN jest globalna i chronologiczna dla całego katalogu.

TODAY=$(date +%Y-%m-%d)
NOW=$(date +"%Y-%m-%d %H:%M:%S")

echo "======================================================================"
echo " rename_photos.sh - zmiana nazw zdjęć na podstawie daty z EXIF"
echo "======================================================================"
echo "Co robi ten skrypt:"
echo "  - Odczytuje datę wykonania zdjęcia z metadanych EXIF."
echo "  - Jeśli brak EXIF-a, używa daty modyfikacji pliku."
echo "  - Jeśli i tego brak, używa dzisiejszej daty ($TODAY)."
echo "  - Nadaje nazwy w formacie: RRRR-MM-DD NNNN.ext (numeracja 0001, 0002, ...),"
echo "    posortowane chronologicznie od najstarszego do najnowszego pliku."
echo "  - Zapisuje log operacji w katalogu ze zdjęciami jako plik:"
echo "    rename_photos_RRRRMMDD_GGMMSS.log (z datą i godziną uruchomienia)."
echo ""
echo "Zaraz zapytam o:"
echo "  1) Ścieżkę do katalogu ze zdjęciami."
echo "  2) Tryb pracy:"
echo "       [1] Podgląd (dry run) - pokazuje co by się stało, NIC nie zmienia."
echo "       [0] Wykonanie - zmienia nazwy plików naprawdę."
echo "======================================================================"
echo ""

echo "Uruchomiono: $NOW"
echo ""

# --- Krok 1: ścieżka do katalogu ---
read -r -p "Podaj ścieżkę do katalogu ze zdjęciami: " DIR
if [ -z "$DIR" ]; then
    echo "BŁĄD: nie podano ścieżki. Przerywam."
    exit 1
fi
# Ręczne rozwinięcie ~ na początku ścieżki (read nie robi tego automatycznie)
case "$DIR" in
    "~") DIR="$HOME" ;;
    "~/"*) DIR="$HOME/${DIR#\~/}" ;;
esac
if [ ! -d "$DIR" ]; then
    echo "BŁĄD: katalog '$DIR' nie istnieje. Przerywam."
    exit 1
fi

# --- Krok 2: tryb pracy ---
DRY_RUN=""
while [ "$DRY_RUN" != "0" ] && [ "$DRY_RUN" != "1" ]; do
    read -r -p "Wybierz tryb [1 = podgląd / 0 = wykonaj zmiany]: " DRY_RUN
    if [ "$DRY_RUN" != "0" ] && [ "$DRY_RUN" != "1" ]; then
        echo "Niepoprawny wybór - wpisz 1 albo 0."
    fi
done

if [ "$DRY_RUN" = "1" ]; then
    echo ""
    echo ">>> Tryb PODGLĄDU - żaden plik nie zostanie zmieniony. <<<"
else
    echo ""
    echo ">>> Tryb WYKONANIA - nazwy plików zostaną zmienione NAPRAWDĘ. <<<"
    read -r -p "Na pewno kontynuować? (t/n): " confirm
    if [ "$confirm" != "t" ] && [ "$confirm" != "T" ]; then
        echo "Przerwano na życzenie użytkownika."
        exit 0
    fi
fi

cd "$DIR" || { echo "Nie mogę wejść do katalogu: $DIR"; exit 1; }
DIR_ABS="$(pwd)"
echo ""
echo "Katalog roboczy: $DIR_ABS"

if ! command -v exiftool >/dev/null 2>&1; then
    echo "BŁĄD: exiftool nie jest zainstalowany. sudo apt install libimage-exiftool-perl"
    exit 1
fi

# --- Log operacji zapisywany w samym katalogu ze zdjęciami, żeby przetrwał ---
LOG_FILE="$DIR_ABS/rename_photos_$(date +%Y%m%d_%H%M%S).log"
echo "Log tej operacji będzie zapisany w: $LOG_FILE"
echo ""

{
    echo "=== rename_photos.sh - log operacji ==="
    echo "Start: $NOW"
    echo "Katalog: $DIR_ABS"
    echo "Tryb: $([ "$DRY_RUN" = "1" ] && echo "PODGLĄD (dry run)" || echo "WYKONANIE")"
    echo ""
} > "$LOG_FILE"

total_files=$(find . -maxdepth 1 -type f ! -name "*.sh" ! -name "*.log" | wc -l)
echo "Znaleziono $total_files plików. Odczytuję metadane jednym wywołaniem exiftool..."

exiftool -T -q \
    -Filename -DateTimeOriginal -CreateDate \
    -d "%Y-%m-%d" \
    -- . > /tmp/exif_raw.tsv 2>/tmp/exif_errors.log

echo "Odczyt zakończony. Przetwarzam wyniki i dobieram daty..."

: > /tmp/photo_dates.txt
count_exif=0
count_mtime=0
count_today=0

while IFS=$'\t' read -r fname dto cdate; do
    [ -z "$fname" ] && continue
    [ "$fname" = "-" ] && continue

    # Niektóre aparaty (np. Panasonic Lumix) zapisują "0000:00:00 00:00:00"
    # jako placeholder "brak daty" zamiast zostawić pole puste - traktujemy to jak brak.
    case "$dto" in 0000*|-|"") dto="" ;; esac
    case "$cdate" in 0000*|-|"") cdate="" ;; esac

    d=""
    if [ -n "$dto" ]; then
        d="$dto"
        count_exif=$((count_exif+1))
    elif [ -n "$cdate" ]; then
        d="$cdate"
        count_exif=$((count_exif+1))
    else
        d=$(date -r "$fname" +%Y-%m-%d 2>/dev/null)
        if [ -n "$d" ]; then
            count_mtime=$((count_mtime+1))
        else
            d="$TODAY"
            count_today=$((count_today+1))
        fi
    fi

    echo -e "$d\t$fname" >> /tmp/photo_dates.txt
done < /tmp/exif_raw.tsv

echo ""
echo "=== Podsumowanie źródeł dat ==="
echo "Z EXIF (DateTimeOriginal/CreateDate): $count_exif"
echo "Z daty modyfikacji pliku (fallback):  $count_mtime"
echo "Dzisiejsza data (brak innych danych): $count_today"
echo ""

{
    echo "=== Podsumowanie źródeł dat ==="
    echo "Z EXIF (DateTimeOriginal/CreateDate): $count_exif"
    echo "Z daty modyfikacji pliku (fallback):  $count_mtime"
    echo "Dzisiejsza data (brak innych danych): $count_today"
    echo ""
    echo "=== Zmiany nazw ==="
} >> "$LOG_FILE"

echo "=== Wykonywanie zmian nazw (tryb: $([ "$DRY_RUN" = "1" ] && echo "podgląd" || echo "wykonanie")) ==="
counter=0
while IFS=$'\t' read -r date fname; do
    counter=$((counter+1))
    ext="${fname##*.}"
    newname=$(printf "%s %04d.%s" "$date" "$counter" "$ext")
    if [ "$DRY_RUN" = "1" ]; then
        echo "mv '$fname' -> '$newname'"
    else
        mv -n -- "$fname" "$newname"
    fi
    echo "$fname -> $newname" >> "$LOG_FILE"
done < <(sort -t$'\t' -k1,1 /tmp/photo_dates.txt)

{
    echo ""
    echo "Przetworzono: $counter plików"
    echo "Koniec: $(date +"%Y-%m-%d %H:%M:%S")"
} >> "$LOG_FILE"

echo ""
echo "======================================================================"
echo "Gotowe. Przetworzono $counter plików."
if [ "$DRY_RUN" = "1" ]; then
    echo "To był tylko PODGLĄD - żaden plik nie został zmieniony."
    echo "Uruchom skrypt ponownie i wybierz tryb 0, aby wykonać zmiany naprawdę."
else
    echo "Nazwy plików zostały zmienione."
fi
echo "Pełny log tej operacji zapisany w: $LOG_FILE"
echo "======================================================================"
