# rename_photos.sh

Zmienia nazwy zdjęć/filmów w katalogu na format:

```
RRRR-MM-DD NNNN.ext
```

np. `2016-05-13 0865.JPG`, gdzie `NNNN` to kolejny numer (0001, 0002, ...) nadany
chronologicznie — od najstarszego do najnowszego zdjęcia w całym katalogu.

## Skąd bierze się data

Dla każdego pliku skrypt próbuje po kolei, aż znajdzie sensowną wartość:

1. **EXIF `DateTimeOriginal`** — data zrobienia zdjęcia zapisana przez aparat/telefon.
2. **EXIF `CreateDate`** — jeśli brak powyższego.
3. **Data modyfikacji pliku** (`mtime`) — gdy zdjęcie w ogóle nie ma metadanych EXIF
   (np. stare skany, screenshoty, pliki pobrane/skonwertowane).
4. **Dzisiejsza data** — absolutny ostatni fallback, gdy nic innego się nie uda.

Znaczniki `0000:00:00 00:00:00`, które niektóre aparaty (np. starsze Panasonic
Lumix) zapisują zamiast pustego pola, są traktowane jak brak daty i również
lądują w fallbacku.

## Wymagania

- `exiftool` (`sudo apt install libimage-exiftool-perl`)
- Bash

## Użycie

```bash
chmod +x rename_photos.sh
./rename_photos.sh "/ścieżka/do/zdjęć" 1   # podgląd - nic nie zmienia
./rename_photos.sh "/ścieżka/do/zdjęć" 0   # wykonuje zmiany naprawdę
```

**Argumenty:**

| # | Znaczenie                                              | Domyślnie |
|---|---------------------------------------------------------|-----------|
| 1 | Ścieżka do katalogu ze zdjęciami                         | `.`       |
| 2 | `1` = tylko podgląd (dry run), `0` = rzeczywiste zmiany  | `1`       |

**Zawsze najpierw uruchom z `1`**, sprawdź podsumowanie i wynik, dopiero potem
uruchom z `0`.

## Co pokazuje na ekranie

- Liczbę znalezionych plików.
- Podsumowanie źródeł dat: ile plików wzięło datę z EXIF, ile z daty
  modyfikacji pliku, ile z dzisiejszej daty (fallback).
- Listę planowanych/wykonanych zmian nazw.

## Pliki tymczasowe (w `/tmp`)

- `/tmp/exif_raw.tsv` — surowe metadane odczytane z exiftool.
- `/tmp/exif_errors.log` — ewentualne błędy/ostrzeżenia z exiftool.
- `/tmp/photo_dates.txt` — dobrana data dla każdego pliku (przed sortowaniem).
- `/tmp/rename_log.txt` — pełny log wykonanych (lub planowanych) zmian nazw,
  przydatny do ręcznego sprawdzenia lub cofnięcia zmian.

## Bezpieczeństwo

- Skrypt używa `mv -n`, więc **nigdy nie nadpisze** istniejącego pliku o tej
  samej docelowej nazwie — w razie kolizji operacja dla danego pliku zostanie
  po cichu pominięta (oryginalny plik zostanie pod starą nazwą).
- Działa tylko na jednym poziomie katalogu (`-maxdepth 1`) — nie wchodzi
  w podkatalogi.
- **Zrób kopię zapasową przed uruchomieniem z argumentem `0`** — zmiana nazw
  na dużym zbiorze plików jest trudna do ręcznego cofnięcia bez logu i backupu.

## Ograniczenia

- Numeracja `NNNN` jest **globalna** dla całego katalogu (nie zaczyna się od
  nowa każdego dnia) — pliki z tego samego dnia dostają kolejne numery w
  ramach całej sekwencji 0001–NNNN.
- Jeśli dwa pliki mają dokładnie tę samą docelową nazwę (ta sama data i numer
  — w praktyce nie powinno się zdarzyć przy poprawnej numeracji, ale przy
  ręcznej edycji danych warto o tym pamiętać), `mv -n` zignoruje drugą zmianę.
