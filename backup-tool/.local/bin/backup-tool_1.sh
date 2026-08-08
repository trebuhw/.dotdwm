#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# ==============================================================================
# SAMO-URUCHOMIENIE W TERMINALU (dla rofi / .desktop, gdzie brak TTY)
# ==============================================================================
if [[ ! -t 1 ]]; then
  SCRIPT_PATH="$(readlink -f "$0")"
  TERMINAL_CANDIDATES=(ghostty alacritty kitty foot st xterm)
  for t in "${TERMINAL_CANDIDATES[@]}"; do
    if command -v "$t" &>/dev/null; then
      exec "$t" -e "$SCRIPT_PATH" "$@"
    fi
  done
  echo "❌ Nie znaleziono żadnego emulatora terminala (sprawdzano: ${TERMINAL_CANDIDATES[*]})." >&2
  exit 1
fi

# ==============================================================================
# KONFIGURACJA I ZMIENNE GŁÓWNE
# ==============================================================================
DISTRO_NAME=$(lsb_release -si 2>/dev/null || grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"' || echo "linux")
DATE_STAMP=$(date +%Y-%m-%d)

LOCAL_ARCHIVE_BASE="$HOME/Archiwum"
FALLBACK_ARCHIVE_BASE="$HOME/Archiwum-awaryjne"
BACKUP_SUBDIR="Backup"
CLOUD_ARCHIVE_BASE="$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR/Cloud-Backup"
INCREMENTAL_ARCHIVE_BASE="$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR/Przyrostowy"
RETAIN_VERSIONS=3

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$XDG_CONFIG_HOME/backup-tool"
CUSTOM_CONF="$CONFIG_DIR/custom-locations.conf"
SOURCE_NAMES_CONF="$CONFIG_DIR/source-names.conf"

LOG_DIR="$HOME/.local/log/backup-tool"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/backup-tool.log"
: >"$LOG_FILE" # log zawsze zaczyna się od zera przy każdym uruchomieniu

# Opcje rsync (bez -v: pełny output tylko na ekranie, do logu tylko --stats)
RSYNC_POSIX_OPTS=(-a --delete --stats)
RSYNC_EXFAT_OPTS=(-rt --size-only --delete --stats)

# ==============================================================================
# KOLORY WHIPTAIL/NEWT - poprawione przez użytkownika: aktywny przycisk ma
# wyraźnie odróżnialne tło (zielone), reszta w uniwersalnym mono-schemacie.
# ==============================================================================
export NEWT_COLORS='
root=white,black
window=white,black
border=white,black
button=black,white
actbutton=white,green
label=white,black
title=white,black
shadow=black,black
compactbutton=white,black
checkbox=white,black
actcheckbox=black,white
entry=white,black
listbox=white,black
actlistbox=black,white
sellistbox=white,black
actsellistbox=black,white
textbox=white,black
acttextbox=black,white
helpline=white,black
roottext=white,black
emptyscale=white,black
disabledentry=white,black
'

# ==============================================================================
# WBUDOWANA TABLICA LOKALIZACJI
# Format (7 pól rozdzielonych '|'):
# TAG|SRC|DEST_SUBDIR|EXTRA_RSYNC_OPTS|BASE_TYPE|LABEL|DEFAULT_ON
#
# SRC może zawierać kilku kandydatów rozdzielonych ':' - skrypt użyje
# pierwszego istniejącego (np. różne nazwy dotfiles na różnych dystrybucjach).
# DEST_SUBDIR="." oznacza root folderu docelowego (dla pojedynczych plików).
# BASE_TYPE: distro (rotacja $RETAIN_VERSIONS wersji) | cloud (1 wersja, nadpisywana)
#          | incremental (bez usuwania - tylko dopisywanie/aktualizacja plików)
# ==============================================================================
BACKUP_ITEMS_BUILTIN=(
  "SZABLONY|$HOME/Szablony|Szablony||distro|Katalog ~/Szablony|ON"
  "DOKUMENTY|$HOME/Dokumenty|Dokumenty|--exclude=tmp --exclude=sekret.txt|distro|Katalog ~/Dokumenty|ON"
  "OBRAZY|$HOME/Obrazy|Obrazy||distro|Katalog ~/Obrazy|ON"
  "GIT_CONF|$HOME/.gitconfig|.||distro|Pliki ~/.gitconfig i .git-credentials|ON"
  "GIT_CONF|$HOME/.git-credentials|.||distro|Pliki ~/.gitconfig i .git-credentials|ON"
  "SSH_KEYS|$HOME/.ssh|.ssh||distro|Katalog ~/.ssh|ON"
  "ONEDRIVE|$HOME/OneDrive|OneDrive||cloud|Kopia folderu ~/OneDrive|ON"
  "GDRIVE|$HOME/GoogleDrive|GoogleDrive||cloud|Kopia folderu ~/GoogleDrive|OFF"
)

declare -a BACKUP_ITEMS=()
CURRENT_DISTRO_DIR=""

# ==============================================================================
# POMOCNICZE FUNKCJE SYSTEMOWE
# ==============================================================================
log() {
  echo -e "$1" | tee -a "$LOG_FILE"
}

# Powiadomienie desktopowe (dunst/mako/inne demony zgodne z org.freedesktop.Notifications).
# Jeśli notify-send nie jest zainstalowane, po prostu nic nie robi (bez błędu).
notify() {
  local title="$1" body="$2" urgency="${3:-normal}"
  command -v notify-send &>/dev/null || return 0
  notify-send -u "$urgency" -a "backup-tool" -- "$title" "$body" 2>/dev/null || true
}

get_fs_type() {
  local path="$1"
  df -T "$path" 2>/dev/null | tail -n 1 | awk '{print $2}' || echo "unknown"
}

get_rsync_opts() {
  local path="$1"
  local exec_mode="$2"
  local delete_mode="${3:-true}"
  local fs_type
  fs_type=$(get_fs_type "$path")
  local opts=()

  if [[ "$fs_type" =~ ^(exfat|vfat|ntfs|fuseblk)$ ]]; then
    opts=("${RSYNC_EXFAT_OPTS[@]}")
  else
    opts=("${RSYNC_POSIX_OPTS[@]}")
  fi

  # Tryb przyrostowy (incremental): nigdy nie usuwamy plików z archiwum,
  # nawet jeśli zniknęły ze źródła - tylko dopisujemy/aktualizujemy.
  if [[ "$delete_mode" == "false" ]]; then
    local filtered=() o
    for o in "${opts[@]}"; do
      [[ "$o" == "--delete" ]] && continue
      filtered+=("$o")
    done
    opts=("${filtered[@]}")
  fi

  if [[ "$exec_mode" == "SYMULACJA" ]]; then
    opts+=("--dry-run")
  fi

  echo "${opts[@]}"
}

fix_ssh_permissions() {
  if [[ -d "$HOME/.ssh" ]]; then
    log "🔒 Utwardzanie uprawnień dla ~/.ssh..."
    chmod 700 "$HOME/.ssh"
    find "$HOME/.ssh" -type f -exec chmod 600 {} +
    find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} +
  fi
}

# Czy ścieżkę można bezpiecznie nadpisać przy RESTORE?
is_restorable() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return 0
  fi
  if [[ -d "$path" ]]; then
    [[ -z "$(ls -A "$path" 2>/dev/null)" ]] && return 0 || return 1
  elif [[ -f "$path" ]]; then
    [[ ! -s "$path" ]] && return 0 || return 1
  fi
  return 1
}

# Uruchamia rsync: output (w tym pasek postępu) widoczny NA ŻYWO na ekranie,
# jednocześnie zapisywany do pliku tymczasowego. Do LOG_FILE trafia tylko
# zwięzłe podsumowanie (sukces) albo PEŁNA treść (błąd).
run_rsync_logged() {
  local label="$1"
  shift
  local tmp_out status
  tmp_out=$(mktemp)

  echo "⏳ [$label] Synchronizuję - to może chwilę potrwać przy dużych folderach..."

  # --info=progress2: łączny postęp (%, ETA, szybkość) zamiast pliku-po-pliku,
  # żeby przy dużych archiwach było widać że coś się dzieje, a nie "zawieszenie".
  set +e
  rsync --info=progress2 --human-readable "$@" 2>&1 | tee "$tmp_out"
  status=${PIPESTATUS[0]}
  set -e

  if [[ $status -eq 0 ]]; then
    {
      echo ">>> [$label] OK"
      grep -E '^(Number of|Total transferred|Total file size|sent )' "$tmp_out" || true
    } >>"$LOG_FILE"
  else
    {
      echo ">>> [$label] BŁĄD (kod wyjścia: $status)"
      cat "$tmp_out"
    } >>"$LOG_FILE"
  fi

  rm -f "$tmp_out"
  return "$status"
}

# ==============================================================================
# ŁADOWANIE LOKALIZACJI (wbudowane + ~/.config/backup-tool/custom-locations.conf)
# ==============================================================================
ensure_custom_conf() {
  mkdir -p "$CONFIG_DIR"
  if [[ ! -f "$CUSTOM_CONF" ]]; then
    cat >"$CUSTOM_CONF" <<EOF
# Plik konfiguracyjny własnych lokalizacji backup-tool
# Format (7 pól rozdzielonych znakiem '|'):
# TAG|SRC|DEST_SUBDIR|EXTRA_RSYNC_OPTS|BASE_TYPE|LABEL|DEFAULT_ON
#
# SRC może zawierać kilku kandydatów rozdzielonych ':' - skrypt użyje
# pierwszego istniejącego (przydatne np. gdy nazwa folderu różni się
# między dystrybucjami/środowiskami).
#
# BASE_TYPE: distro (rotacja $RETAIN_VERSIONS wersji) | cloud (1 wersja, nadpisywana)
#          | incremental (bez usuwania - tylko dopisywanie/aktualizacja plików)
# DEFAULT_ON: ON lub OFF (domyślne zaznaczenie w checkliście)
#
# Możesz edytować ten plik ręcznie albo dodawać wpisy z poziomu skryptu
# (opcja "dodaj nową lokalizację" podczas backupu w trybie ZAPIS).

DOTFILES|\$HOME/.dotdwm:\$HOME/.dotfiles|Dotfiles||distro|Repozytorium dotfiles (.dotdwm lub .dotfiles)|ON
EOF
    log "ℹ️ Utworzono domyślny plik konfiguracyjny: $CUSTOM_CONF"
  fi
}

ensure_source_names_conf() {
  mkdir -p "$CONFIG_DIR"
  [[ -f "$SOURCE_NAMES_CONF" ]] || : >"$SOURCE_NAMES_CONF"
}

# Odczytuje zapamiętaną, faktycznie użytą ścieżkę dla danego tagu (jeśli jest)
get_source_name() {
  local tag="$1"
  ensure_source_names_conf
  awk -F'|' -v t="$tag" '$1==t {v=$2} END{print v}' "$SOURCE_NAMES_CONF"
}

# Zapamiętuje ścieżkę użytą przy backupie - TYLKO w trybie ZAPIS
set_source_name() {
  local tag="$1" path="$2" exec_mode="$3"
  [[ "$exec_mode" == "ZAPIS" ]] || return 0
  ensure_source_names_conf
  local tmp
  tmp=$(mktemp)
  grep -v "^${tag}|" "$SOURCE_NAMES_CONF" >"$tmp" 2>/dev/null || true
  echo "${tag}|${path}" >>"$tmp"
  mv "$tmp" "$SOURCE_NAMES_CONF"
}

load_backup_items() {
  BACKUP_ITEMS=("${BACKUP_ITEMS_BUILTIN[@]}")
  ensure_custom_conf
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    line="${line//\$HOME/$HOME}"
    BACKUP_ITEMS+=("$line")
  done <"$CUSTOM_CONF"
}

# ==============================================================================
# EKRAN INFORMACYJNY I INICJALIZACJA ŚRODOWISKA
# ==============================================================================
setup_environment() {
  local info_text="System Kopii Zapasowej i Przywracania Danych\n\n"
  info_text+="ZASADY I WYMAGANIA:\n"
  info_text+="1. Partycja archiwum powinna być zamontowana w [$LOCAL_ARCHIVE_BASE].\n"
  info_text+="2. Kopie trafiają do podfolderu: $LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR/\n"
  info_text+="3. Kopie dystrybucji: rotacja ostatnich $RETAIN_VERSIONS wersji.\n"
  info_text+="4. Kopie chmur (Cloud-Backup): zawsze 1 wersja, nadpisywana.\n"
  info_text+="5. Kopie przyrostowe (Przyrostowy): nigdy nic nie usuwają, tylko dopisują/aktualizują.\n"
  info_text+="6. Logi (tylko z ostatniego uruchomienia): $LOG_FILE\n"
  info_text+="7. Własne lokalizacje: $CUSTOM_CONF\n\n"
  info_text+="Kliknij OK, aby zweryfikować środowisko i kontynuować."

  if ! whiptail --title "Instrukcja i Zasady Działania" --msgbox "$info_text" 20 78; then
    echo "Anulowano przez użytkownika."
    exit 0
  fi

  if ! mountpoint -q "$LOCAL_ARCHIVE_BASE"; then
    if whiptail --title "Ostrzeżenie: partycja niezamontowana" --yesno \
      "Partycja Archiwum ([$LOCAL_ARCHIVE_BASE]) nie jest zamontowana!\n\nTo NIE jest to samo co Twoja dedykowana partycja archiwum - kontynuacja zapisze dane do zwykłego folderu na dysku systemowym:\n\n$FALLBACK_ARCHIVE_BASE\n\nCzy mimo to kontynuować awaryjnie?" \
      --defaultno 16 74; then
      LOCAL_ARCHIVE_BASE="$FALLBACK_ARCHIVE_BASE"
      CLOUD_ARCHIVE_BASE="$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR/Cloud-Backup"
      INCREMENTAL_ARCHIVE_BASE="$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR/Przyrostowy"
      log "⚠️ Partycja Archiwum niezamontowana - używam folderu awaryjnego: $LOCAL_ARCHIVE_BASE"
    else
      echo "❌ Anulowano: partycja Archiwum niezamontowana."
      exit 1
    fi
  fi

}

# ==============================================================================
# MENU I SELEKCJA
# ==============================================================================
select_execution_mode() {
  whiptail --title "Tryb Wykonania" --radiolist \
    "Wybierz sposób przeprowadzania operacji:" 15 65 2 \
    "SYMULACJA" "Test (Dry-Run) - podgląd bez zmian na dysku" ON \
    "ZAPIS" "Wykonanie realne - zapis i modyfikacja plików" OFF \
    3>&1 1>&2 2>&3
}

select_action_mode() {
  whiptail --title "Wybór Zadania" --menu "Co chcesz zrobić?" 15 60 2 \
    "BACKUP" "Utwórz kopię zapasową z tego systemu" \
    "RESTORE" "Przywróć dane z archiwum do systemu" \
    3>&1 1>&2 2>&3
}

select_backup_scope() {
  whiptail --title "Zakres backupu" --menu \
    "Jaki zakres backupu wykonać?" 15 70 3 \
    "BIEZACY" "Stan bieżący (dystrybucja + chmury) - jak dotychczas" \
    "PRZYROSTOWY" "Przyrostowy - dopisuje/aktualizuje, nic nie usuwa" \
    "OBA" "Wykonaj oba - dwa oddzielne przebiegi po kolei" \
    3>&1 1>&2 2>&3
}

# allowed_types: opcjonalna lista base_type oddzielona spacjami (np. "distro cloud").
# Puste = bez filtrowania (pokaż wszystkie typy).
select_modules() {
  local title="$1" prompt="$2" force_off="$3" allowed_types="${4:-}"
  local args=()
  local seen=""
  local item tag src dest opts base label default state
  for item in "${BACKUP_ITEMS[@]}"; do
    IFS='|' read -r tag src dest opts base label default <<<"$item"
    [[ " $seen " == *" $tag "* ]] && continue
    seen+=" $tag"
    if [[ -n "$allowed_types" ]]; then
      [[ " $allowed_types " == *" $base "* ]] || continue
    fi
    state="$default"
    [[ "$force_off" == "true" ]] && state="OFF"
    args+=("$tag" "$label" "$state")
  done
  local count=$((${#args[@]} / 3))
  if ((count == 0)); then
    echo ""
    return
  fi
  whiptail --title "$title" --checklist "$prompt" $((count + 9)) 78 "$count" "${args[@]}" \
    3>&1 1>&2 2>&3
}

# ==============================================================================
# WYKRYWANIE NOŚNIKÓW ZEWNĘTRZNYCH (tylko auto-mount)
# ==============================================================================
detect_removable_mounts() {
  local dirs=() base d
  for base in "/run/media/$USER" "/media/$USER"; do
    [[ -d "$base" ]] || continue
    for d in "$base"/*; do
      [[ -d "$d" ]] && mountpoint -q "$d" && dirs+=("$d")
    done
  done
  printf '%s\n' "${dirs[@]}" | sort -u
}

select_external_target() {
  local mounts=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && mounts+=("$line")
  done < <(detect_removable_mounts)

  if ((${#mounts[@]} == 0)); then
    echo ""
    return
  fi

  local args=() m size first="ON"
  for m in "${mounts[@]}"; do
    size=$(df -h --output=avail "$m" 2>/dev/null | tail -1 | tr -d ' ')
    args+=("$m" "Wolne miejsce: ${size:-?}" "$first")
    first="OFF"
  done
  args+=("POMIN" "Nie kopiuj na nośnik zewnętrzny" "OFF")

  local choice
  choice=$(whiptail --title "Nośnik zewnętrzny" --radiolist \
    "Wykryto podłączone/zamontowane nośniki. Wybierz cel kopii lustrzanej (Archiwum/Backup):" \
    18 74 $((${#mounts[@]} + 1)) "${args[@]}" 3>&1 1>&2 2>&3) || choice="POMIN"

  [[ "$choice" == "POMIN" ]] && choice=""
  echo "$choice"
}

mirror_to_external() {
  local target_mount="$1" exec_mode="$2"
  if [[ -z "$target_mount" ]]; then
    log "ℹ️ Pominięto kopię na nośnik zewnętrzny."
    return
  fi

  local dest="$target_mount/Archiwum/$BACKUP_SUBDIR"
  local src="$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR"
  log "\n>>> [NOŚNIK ZEWNĘTRZNY] Synchronizacja: $src -> $dest"

  local opts=(-rt --delete --stats --no-perms --no-owner --no-group --copy-unsafe-links)
  [[ "$exec_mode" == "SYMULACJA" ]] && opts+=(--dry-run)

  [[ "$exec_mode" == "ZAPIS" ]] && mkdir -p "$dest"
  run_rsync_logged "NOŚNIK ZEWNĘTRZNY" "${opts[@]}" "$src/" "$dest/" || true
}

# ==============================================================================
# ROTACJA WERSJI DYSTRYBUCJI
# ==============================================================================
resolve_backup_target_dir() {
  echo "$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR/${DATE_STAMP}_${DISTRO_NAME}-backup"
}

resolve_restore_source_dir() {
  local dirs=() d
  for d in "$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR"/*_"${DISTRO_NAME}"-backup; do
    [[ -d "$d" ]] && dirs+=("$d")
  done
  if ((${#dirs[@]} == 0)); then
    echo ""
    return
  fi

  local sorted=()
  while IFS= read -r d; do sorted+=("$d"); done < <(printf '%s\n' "${dirs[@]}" | sort -r)

  # Jeśli jest tylko jedna wersja, nie ma czego wybierać.
  if ((${#sorted[@]} == 1)); then
    echo "${sorted[0]}"
    return
  fi

  local menu_args=() base
  for d in "${sorted[@]}"; do
    base=$(basename "$d")
    menu_args+=("$d" "$base")
  done

  local list_height=${#sorted[@]}
  ((list_height > 8)) && list_height=8

  whiptail --title "Wybór wersji do przywrócenia" --menu \
    "Znaleziono ${#sorted[@]} zapisane wersje dla [$DISTRO_NAME]. Którą przywrócić?\n(najnowsza na górze)" \
    18 78 "$list_height" "${menu_args[@]}" \
    3>&1 1>&2 2>&3 || echo "${sorted[0]}"
}

prune_old_distro_backups() {
  local exec_mode="$1"
  local dirs=() d
  for d in "$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR"/*_"${DISTRO_NAME}"-backup; do
    [[ -d "$d" ]] && dirs+=("$d")
  done
  local sorted=()
  while IFS= read -r line; do sorted+=("$line"); done < <(printf '%s\n' "${dirs[@]}" | sort -r)

  local i=0
  for d in "${sorted[@]}"; do
    i=$((i + 1))
    if ((i > RETAIN_VERSIONS)); then
      log "🗑️  Przekroczono limit $RETAIN_VERSIONS wersji - usuwam starą kopię: $d"
      [[ "$exec_mode" == "ZAPIS" ]] && rm -rf "$d"
    fi
  done
}

# ==============================================================================
# PODSUMOWANIE PRZED WYKONANIEM
# ==============================================================================
show_summary() {
  local action_mode="$1" exec_mode="$2" ext_target="$3" scope="${4:-}"
  local tmp
  tmp=$(mktemp)
  {
    echo "Tryb: $action_mode | $exec_mode"
    [[ -n "$scope" ]] && echo "Zakres tego przebiegu: $scope"
    echo ""
    if [[ "$action_mode" == "BACKUP" ]]; then
      if [[ "$scope" == "PRZYROSTOWY" ]]; then
        echo "Cel przyrostowy (bez usuwania - tylko dopisywanie/aktualizacja): $INCREMENTAL_ARCHIVE_BASE"
      else
        echo "Cel lokalny (dystrybucja, rotacja $RETAIN_VERSIONS wersji): $CURRENT_DISTRO_DIR"
        echo "Cel chmur (1 wersja, nadpisywana): $CLOUD_ARCHIVE_BASE"
      fi
    else
      echo "Źródło lokalne (wybrana kopia dystrybucji): $CURRENT_DISTRO_DIR"
      echo "Źródło chmur (1 wersja, nadpisywana): $CLOUD_ARCHIVE_BASE"
    fi
    echo "Nośnik zewnętrzny: ${ext_target:-brak / pominięto}"
    echo ""
    echo "Skonfigurowane lokalizacje w tym przebiegu:"
    echo "--------------------------------------------"
    local allowed_types=""
    if [[ "$action_mode" == "BACKUP" ]]; then
      [[ "$scope" == "PRZYROSTOWY" ]] && allowed_types="incremental" || allowed_types="distro cloud"
    else
      allowed_types="distro cloud"
    fi
    local seen="" item tag src dest opts base label default
    for item in "${BACKUP_ITEMS[@]}"; do
      IFS='|' read -r tag src dest opts base label default <<<"$item"
      [[ " $seen " == *" $tag "* ]] && continue
      seen+=" $tag"
      [[ " $allowed_types " == *" $base "* ]] || continue
      echo "[$tag] $label (typ: $base)"
      echo "   ścieżka(i): $src"
    done
  } >"$tmp"
  whiptail --title "Podsumowanie zadania" --scrolltext --textbox "$tmp" 26 90
  rm -f "$tmp"
}

# ==============================================================================
# DODAWANIE NOWYCH LOKALIZACJI W TRAKCIE SESJI
# ==============================================================================
add_new_locations_loop() {
  local exec_mode="$1"

  while whiptail --title "Nowa lokalizacja" --yesno \
    "Czy chcesz dodać nową lokalizację do backupu?" 10 60; do

    local path
    path=$(whiptail --title "Nowa lokalizacja" --inputbox \
      "Podaj pełną ścieżkę (np. $HOME/Muzyka):" 10 70 3>&1 1>&2 2>&3) || break
    [[ -z "$path" ]] && continue

    if [[ ! -e "$path" ]]; then
      whiptail --title "Błąd" --msgbox "Ścieżka nie istnieje:\n$path" 10 70
      continue
    fi

    local base_type
    base_type=$(whiptail --title "Typ lokalizacji" --menu \
      "Jaki typ backupu dla tej lokalizacji?" 13 74 3 \
      "distro" "Rotacja $RETAIN_VERSIONS ostatnich wersji (rekomendowane)" \
      "cloud" "Zawsze nadpisywane, 1 wersja" \
      "incremental" "Przyrostowy - nic nie usuwane, tylko dopisywanie" \
      3>&1 1>&2 2>&3) || continue

    local base_name tag dest_sub
    base_name=$(basename "$path")
    tag=$(echo "$base_name" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9_')
    [[ -z "$tag" ]] && tag="CUSTOM_$(date +%s)"
    dest_sub="$base_name"

    if grep -q "^${tag}|" "$CUSTOM_CONF" 2>/dev/null ||
      printf '%s\n' "${BACKUP_ITEMS[@]}" | grep -q "^${tag}|"; then
      tag="${tag}_$(date +%s)"
    fi

    local entry="${tag}|${path}|${dest_sub}||${base_type}|Własna lokalizacja: ${path}|OFF"
    BACKUP_ITEMS+=("$entry")

    if [[ "$exec_mode" == "ZAPIS" ]]; then
      echo "$entry" >>"$CUSTOM_CONF"
      log "✔ Zapisano nową lokalizację do $CUSTOM_CONF: [$tag] $path"
    else
      log "ℹ️ [SYMULACJA] Lokalizacja [$tag] $path dodana tylko na czas tej sesji (nie zapisano na dysk)."
    fi
  done
}

# ==============================================================================
# PRZETWARZANIE POJEDYNCZEJ LOKALIZACJI
# ==============================================================================
process_backup_item() {
  local tag="$1" src_field="$2" dest_sub="$3" opts_field="$4" base_type="$5" exec_mode="$6"

  local target_base
  if [[ "$base_type" == "cloud" ]]; then
    target_base="$CLOUD_ARCHIVE_BASE"
  elif [[ "$base_type" == "incremental" ]]; then
    target_base="$INCREMENTAL_ARCHIVE_BASE"
  else
    target_base="$CURRENT_DISTRO_DIR"
  fi

  local candidates=() c resolved_src=""
  IFS=':' read -ra candidates <<<"$src_field"
  for c in "${candidates[@]}"; do
    if [[ -e "$c" ]]; then
      resolved_src="$c"
      break
    fi
  done

  if [[ -z "$resolved_src" ]]; then
    log "⚠️ [$tag] Żadna ze ścieżek nie istnieje – pomijam: $src_field"
    return
  fi

  local dest_path="$target_base"
  [[ "$dest_sub" != "." ]] && dest_path="$target_base/$dest_sub"

  log "\n>>> [BACKUP][$tag] $resolved_src -> $dest_path"
  [[ "$exec_mode" == "ZAPIS" ]] && mkdir -p "$dest_path"

  local delete_mode="true"
  [[ "$base_type" == "incremental" ]] && delete_mode="false"

  local current_opts=()
  read -r -a current_opts <<<"$(get_rsync_opts "$LOCAL_ARCHIVE_BASE" "$exec_mode" "$delete_mode")"
  if [[ -n "$opts_field" ]]; then
    local extra_arr=()
    IFS=' ' read -r -a extra_arr <<<"$opts_field"
    current_opts+=("${extra_arr[@]}")
  fi

  if [[ -d "$resolved_src" ]]; then
    run_rsync_logged "BACKUP][$tag" "${current_opts[@]}" "$resolved_src/" "$dest_path/" || true
  else
    run_rsync_logged "BACKUP][$tag" "${current_opts[@]}" "$resolved_src" "$dest_path/" || true
  fi

  if ((${#candidates[@]} > 1)); then
    set_source_name "$tag" "$resolved_src" "$exec_mode"
  fi
}

process_restore_item() {
  local tag="$1" src_field="$2" dest_sub="$3" opts_field="$4" base_type="$5" exec_mode="$6"

  if [[ "$base_type" == "incremental" ]]; then
    log "ℹ️ [$tag] Lokalizacje przyrostowe nie są (na razie) obsługiwane przy RESTORE – pomijam."
    return
  fi

  local target_base
  if [[ "$base_type" == "cloud" ]]; then
    target_base="$CLOUD_ARCHIVE_BASE"
  else
    target_base="$CURRENT_DISTRO_DIR"
  fi
  [[ -z "$target_base" ]] && {
    log "⚠️ [$tag] Brak dostępnego źródła kopii – pomijam."
    return
  }

  local src_dir="$target_base"
  [[ "$dest_sub" != "." ]] && src_dir="$target_base/$dest_sub"

  local candidates=() c restore_target=""
  IFS=':' read -ra candidates <<<"$src_field"
  for c in "${candidates[@]}"; do
    if [[ -e "$c" ]]; then
      restore_target="$c"
      break
    fi
  done

  if [[ -z "$restore_target" ]]; then
    local remembered
    remembered=$(get_source_name "$tag")
    if [[ -n "$remembered" ]]; then
      restore_target="$remembered"
    elif ((${#candidates[@]} > 1)); then
      local menu_args=()
      for c in "${candidates[@]}"; do menu_args+=("$c" " "); done
      restore_target=$(whiptail --title "Wybór nazwy" --menu \
        "Do której lokalizacji przywrócić [$tag]?" 15 70 "${#candidates[@]}" "${menu_args[@]}" \
        3>&1 1>&2 2>&3) || restore_target="${candidates[0]}"
    else
      restore_target="${candidates[0]}"
    fi
  fi

  local actual_src="$src_dir"
  if [[ "$dest_sub" == "." ]]; then
    actual_src="$src_dir/$(basename "$restore_target")"
  fi

  if [[ ! -e "$actual_src" ]]; then
    log "⚠️ [$tag] Brak kopii w $actual_src – pomijam."
    return
  fi

  if ! is_restorable "$restore_target"; then
    log "ℹ️ [$tag] $restore_target już istnieje i ma zawartość – pomijam (bezpieczeństwo)."
    return
  fi

  log "\n>>> [RESTORE][$tag] $actual_src -> $restore_target"

  local current_opts=()
  read -r -a current_opts <<<"$(get_rsync_opts "$LOCAL_ARCHIVE_BASE" "$exec_mode")"
  if [[ -n "$opts_field" ]]; then
    local extra_arr=()
    IFS=' ' read -r -a extra_arr <<<"$opts_field"
    current_opts+=("${extra_arr[@]}")
  fi

  if [[ -d "$actual_src" ]]; then
    [[ "$exec_mode" == "ZAPIS" ]] && mkdir -p "$restore_target"
    run_rsync_logged "RESTORE][$tag" "${current_opts[@]}" --exclude='.source-name' "$actual_src/" "$restore_target/" || true
  else
    [[ "$exec_mode" == "ZAPIS" ]] && mkdir -p "$(dirname "$restore_target")"
    run_rsync_logged "RESTORE][$tag" "${current_opts[@]}" "$actual_src" "$restore_target" || true
  fi

  if [[ "$tag" == "SSH_KEYS" && "$exec_mode" == "ZAPIS" ]]; then
    fix_ssh_permissions
  fi
}

# ==============================================================================
# GŁÓWNA PĘTLA WYKONANIA
# ==============================================================================
run_task() {
  local action_mode="$1" exec_mode="$2"
  shift 2
  local selected=("$@")

  contains() {
    local e
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
    return 1
  }

  log "\n=========================================================="
  log "📌 ZADANIE: $action_mode | TRYB: $exec_mode"
  log "Wybrane moduły: ${selected[*]}"
  log "=========================================================="

  notify "Backup-tool: start" "$action_mode ($exec_mode)\nModuły: ${selected[*]}"

  local item tag src dest opts base label default
  for item in "${BACKUP_ITEMS[@]}"; do
    IFS='|' read -r tag src dest opts base label default <<<"$item"
    contains "$tag" "${selected[@]}" || continue

    if [[ "$action_mode" == "BACKUP" ]]; then
      process_backup_item "$tag" "$src" "$dest" "$opts" "$base" "$exec_mode"
    else
      process_restore_item "$tag" "$src" "$dest" "$opts" "$base" "$exec_mode"
    fi
  done

  log "\n✔ Zakończono pomyślnie!"
  notify "Backup-tool: koniec" "✔ $action_mode ($exec_mode) zakończony pomyślnie."
}

# ==============================================================================
# MAIN
# ==============================================================================
main() {
  if ! command -v whiptail &>/dev/null; then
    echo "❌ BŁĄD: Zainstaluj 'whiptail', aby uruchomić skrypt."
    exit 1
  fi

  trap 'notify "Backup-tool: błąd" "❌ Skrypt przerwany niespodziewanie - sprawdź terminal i log:\n$LOG_FILE" critical' ERR

  load_backup_items
  setup_environment

  EXEC_MODE=$(select_execution_mode || true)
  [[ -z "$EXEC_MODE" ]] && exit 0

  if [[ "$EXEC_MODE" == "ZAPIS" ]]; then
    mkdir -p "$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR"
    mkdir -p "$CLOUD_ARCHIVE_BASE"
    mkdir -p "$INCREMENTAL_ARCHIVE_BASE"
  fi

  ACTION_MODE=$(select_action_mode || true)
  [[ -z "$ACTION_MODE" ]] && exit 0

  local PASSES=()
  if [[ "$ACTION_MODE" == "BACKUP" ]]; then
    CURRENT_DISTRO_DIR=$(resolve_backup_target_dir)

    local scope_choice
    scope_choice=$(select_backup_scope || true)
    [[ -z "$scope_choice" ]] && exit 0

    case "$scope_choice" in
    BIEZACY) PASSES=(BIEZACY) ;;
    PRZYROSTOWY) PASSES=(PRZYROSTOWY) ;;
    OBA) PASSES=(BIEZACY PRZYROSTOWY) ;;
    esac
  else
    CURRENT_DISTRO_DIR=$(resolve_restore_source_dir)
    if [[ -z "$CURRENT_DISTRO_DIR" ]]; then
      whiptail --title "Brak kopii" --msgbox \
        "Nie znaleziono żadnej kopii dla dystrybucji [$DISTRO_NAME] w:\n$LOCAL_ARCHIVE_BASE/$BACKUP_SUBDIR" 10 70
      exit 1
    fi
    PASSES=(RESTORE)
  fi

  EXT_TARGET=""
  if [[ "$ACTION_MODE" == "BACKUP" ]]; then
    EXT_TARGET=$(select_external_target)
    add_new_locations_loop "$EXEC_MODE"
  fi

  notify "Backup-tool" "🚀 Rozpoczynam: $ACTION_MODE ($EXEC_MODE)..."

  local any_ran="false" pass allowed_types title_suffix scope_for_summary

  for pass in "${PASSES[@]}"; do
    if [[ "$ACTION_MODE" == "BACKUP" ]]; then
      if [[ "$pass" == "BIEZACY" ]]; then
        allowed_types="distro cloud"
        title_suffix="BIEŻĄCY"
      else
        allowed_types="incremental"
        title_suffix="PRZYROSTOWY"
      fi
      scope_for_summary="$pass"
      show_summary "$ACTION_MODE" "$EXEC_MODE" "$EXT_TARGET" "$scope_for_summary"
    else
      allowed_types="distro cloud"
      title_suffix="RESTORE"
      show_summary "$ACTION_MODE" "$EXEC_MODE" "$EXT_TARGET" ""
    fi

    local raw_modules=""
    if [[ "$ACTION_MODE" == "BACKUP" ]]; then
      raw_modules=$(select_modules "Wybór modułów [$title_suffix]" \
        "Zaznacz SPACJĄ elementy do ZAPISANIA ($title_suffix):" "false" "$allowed_types" || true)
    else
      raw_modules=$(select_modules "Wybór modułów [RESTORE]" \
        "Zaznacz SPACJĄ elementy do PRZYWRÓCENIA:" "true" "$allowed_types" || true)
    fi

    if [[ -z "$raw_modules" ]]; then
      log "ℹ️ [$title_suffix] Nie zaznaczono żadnych modułów - pomijam ten przebieg."
      continue
    fi

    local MODULES=()
    eval "MODULES=($raw_modules)"

    run_task "$ACTION_MODE" "$EXEC_MODE" "${MODULES[@]}"
    any_ran="true"
  done

  if [[ "$any_ran" == "false" ]]; then
    echo "ℹ️  Nie wykonano żadnego przebiegu (brak zaznaczonych modułów)."
    notify "Backup-tool" "ℹ️ Anulowano - nie zaznaczono żadnych modułów."
    exit 0
  fi

  if [[ "$ACTION_MODE" == "BACKUP" ]]; then
    prune_old_distro_backups "$EXEC_MODE"
    mirror_to_external "$EXT_TARGET" "$EXEC_MODE"
  fi

  trap - ERR
  notify "Backup-tool" "✅ Wszystko gotowe: $ACTION_MODE ($EXEC_MODE) zakończony."
}

main "$@"
