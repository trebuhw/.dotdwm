#!/usr/bin/env bash

# Interaktywny skrypt do monitorowania temperatury CPU i prędkości wentylatorów

# Szerokość etykiety (lewa kolumna)
LABEL_WIDTH=20

# Funkcja do wyrównania — etykieta po lewej, wartość po prawej
print_row() {
  local label="$1"
  local value="$2"
  printf "%-${LABEL_WIDTH}s %s\n" "$label" "$value"
}

# Pobierz głośność (%)
get_volume() {
  local vol
  # PipeWire / PulseAudio
  if command -v wpctl &>/dev/null; then
    vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null |
      awk '{printf "%d", $2 * 100}')
  elif command -v pactl &>/dev/null; then
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null |
      grep -oP '\d+(?=%)' | head -1)
  elif command -v amixer &>/dev/null; then
    vol=$(amixer get Master 2>/dev/null |
      grep -oP '\[\d+%\]' | head -1 | tr -d '[]%')
  fi
  echo "${vol:-N/A}"
}

# Pobierz jasność ekranu (%)
get_brightness() {
  local brightness_path cur max val
  # Szukaj pierwszego dostępnego backlighta
  brightness_path=$(ls /sys/class/backlight/ 2>/dev/null | head -1)
  if [ -n "$brightness_path" ]; then
    cur=$(cat "/sys/class/backlight/$brightness_path/brightness" 2>/dev/null)
    max=$(cat "/sys/class/backlight/$brightness_path/max_brightness" 2>/dev/null)
    if [ -n "$cur" ] && [ -n "$max" ] && [ "$max" -gt 0 ]; then
      val=$(awk "BEGIN {printf \"%d\", ($cur/$max)*100}")
      echo "$val"
      return
    fi
  fi
  # Fallback: brightnessctl
  if command -v brightnessctl &>/dev/null; then
    brightnessctl -m 2>/dev/null | awk -F',' '{gsub(/%/,"",$4); print int($4)}'
    return
  fi
  echo "N/A"
}

# Pobierz siłę sygnału WiFi (%)
get_wifi() {
  local wifi_strength iface
  # Przez iw
  if command -v iw &>/dev/null; then
    iface=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | head -1)
    if [ -n "$iface" ]; then
      local signal
      signal=$(iw dev "$iface" link 2>/dev/null | awk '/signal:/{print $2}')
      if [ -n "$signal" ]; then
        # dBm → procent (zakres: -100 dBm = 0%, -50 dBm = 100%)
        wifi_strength=$(awk "BEGIN {
          v = $signal
          if (v <= -100) { print 0 }
          else if (v >= -50) { print 100 }
          else { printf \"%d\", (v + 100) * 2 }
        }")
        echo "$wifi_strength"
        return
      fi
    fi
  fi
  # Fallback: /proc/net/wireless
  if [ -f /proc/net/wireless ]; then
    local link
    link=$(awk 'NR>2 {print $3}' /proc/net/wireless | head -1 | tr -d '.')
    if [ -n "$link" ]; then
      echo $((link * 100 / 70))
      return
    fi
  fi
  echo "N/A"
}

# Pobierz liczbę podłączonych urządzeń Bluetooth
get_bluetooth() {
  local count
  if command -v bluetoothctl &>/dev/null; then
    count=$(bluetoothctl devices Connected 2>/dev/null | grep -c "^Device")
    echo "$count"
    return
  fi
  # Fallback: sprawdź przez /sys/class/bluetooth
  if [ -d /sys/class/bluetooth ]; then
    count=$(ls /sys/class/bluetooth/ 2>/dev/null | grep -c "^hci")
    # hci to adaptery, nie urządzenia – zwracamy N/A gdy nie ma bluetoothctl
    echo "N/A"
    return
  fi
  echo "N/A"
}

# Pobierz naładowanie baterii podłączonych urządzeń Bluetooth
# Wynik: "NazwaUrządzenia: XX%" per linia, lub "N/A" gdy brak danych
get_bluetooth_battery() {
  if ! command -v bluetoothctl &>/dev/null; then
    echo "N/A"
    return
  fi

  local devices result=""
  devices=$(bluetoothctl devices Connected 2>/dev/null | grep "^Device")
  if [ -z "$devices" ]; then
    echo "N/A"
    return
  fi

  while IFS= read -r line; do
    local mac name bat_pct bat_line
    mac=$(echo "$line" | awk '{print $2}')
    name=$(echo "$line" | cut -d' ' -f3-)

    # Próba 1: bluetoothctl info (BlueZ 5.48+, jeśli urządzenie raportuje baterię)
    bat_line=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Battery Percentage")
    if [ -n "$bat_line" ]; then
      bat_pct=$(echo "$bat_line" | grep -oP '(?<=\()\d+(?=\))' | head -1)
      if [ -n "$bat_pct" ]; then
        result="${result}${name}: ${bat_pct}%\n"
        continue
      fi
    fi

    # Próba 2: upower
    if command -v upower &>/dev/null; then
      local mac_under dev_path
      mac_under=$(echo "$mac" | tr ':' '_')
      dev_path=$(upower -e 2>/dev/null | grep -i "bluetooth.*${mac_under}" | head -1)
      if [ -n "$dev_path" ]; then
        bat_pct=$(upower -i "$dev_path" 2>/dev/null |
          awk '/percentage:/{gsub(/%/,"",$2); print int($2)}')
        if [ -n "$bat_pct" ]; then
          result="${result}${name}: ${bat_pct}%\n"
          continue
        fi
      fi
    fi

    # Próba 3: /sys/class/power_supply (niektóre sterowniki HID)
    local mac_sys
    mac_sys=$(echo "$mac" | tr ':' '_' | tr '[:upper:]' '[:lower:]')
    local sys_path
    sys_path=$(find /sys/class/power_supply/ -maxdepth 1 -iname "*${mac_sys}*" 2>/dev/null | head -1)
    if [ -n "$sys_path" ]; then
      bat_pct=$(cat "${sys_path}/capacity" 2>/dev/null)
      if [ -n "$bat_pct" ]; then
        result="${result}${name}: ${bat_pct}%\n"
        continue
      fi
    fi

    # Brak danych dla tego urządzenia
    result="${result}${name}: N/A\n"
  done <<< "$devices"

  if [ -z "$result" ]; then
    echo "N/A"
  else
    printf "%b" "$result" | sed 's/\\n$//'
  fi
}

# Pobierz poziom baterii (%)
get_battery() {
  local bat_path cap status short result
  bat_path=$(ls /sys/class/power_supply/ 2>/dev/null |
    grep -iE '^BAT' | head -1)
  if [ -n "$bat_path" ]; then
    cap=$(cat "/sys/class/power_supply/$bat_path/capacity" 2>/dev/null)
    status=$(cat "/sys/class/power_supply/$bat_path/status" 2>/dev/null)
    if [ -n "$cap" ]; then
      case "$status" in
        Charging)     short="Charging" ;;
        Discharging)  short="DC" ;;
        "Not charging") short="DC" ;;
        Full)         short="Full" ;;
        *)            short="$status" ;;
      esac
      result="$cap%"
      [ -n "$short" ] && result="$result ($short)"
      echo "$result"
      return
    fi
  fi
  echo "N/A"
}

# Szerokość wewnętrzna ramki (liczba widocznych znaków między ║ a ║)
# ║  <label 12>  <value prawa>  ║  => 2+12+pad+value+2 = BOX_INNER=34
BOX_INNER=34

# Liczy widoczną szerokość stringa (znaki, nie bajty) przez wc -m
_vlen() { printf '%s' "$1" | wc -m | tr -d ' '; }

# Usuwa znaki CJK (wide/fullwidth) z nazwy urządzenia
_strip_cjk() {
  python3 -c "
import sys, unicodedata
print(''.join(c for c in sys.argv[1]
  if unicodedata.east_asian_width(c) not in ('W','F')), end='')
" "$1"
}

# Generuje string złożony z n spacji
_spaces() {
  local n="$1"
  [ "$n" -le 0 ] && return
  printf '%*s' "$n" ""
}

box_row_kv() {
  local label="$1"
  local value="$2"
  local label_col=12
  local pad_left=2
  local pad_right=2

  local llen vlen pad_label pad_mid
  llen=$(_vlen "$label")
  vlen=$(_vlen "$value")

  pad_label=$(( label_col - llen ))
  [ "$pad_label" -lt 0 ] && pad_label=0

  pad_mid=$(( BOX_INNER - pad_left - label_col - vlen - pad_right ))
  [ "$pad_mid" -lt 1 ] && pad_mid=1

  printf "║%s%s%s%s%s%s║\n" \
    "$(_spaces $pad_left)" \
    "$label" \
    "$(_spaces $pad_label)" \
    "$(_spaces $pad_mid)" \
    "$value" \
    "$(_spaces $pad_right)"
}

box_separator() {
  # Długość kreski = BOX_INNER + 2 (same ║ nie wliczamy, ale ╠╣ tak)
  printf "╠"
  printf '═%.0s' $(seq 1 $BOX_INNER)
  printf "╣\n"
}

# Funkcja do pobierania i wyświetlania danych
show_sensors_data() {
  local sensors_output cpu_temp fan1_rpm fan2_rpm
  sensors_output=$(sensors 2>/dev/null)

  cpu_temp=$(echo "$sensors_output" | grep "Package id 0:" | awk '{print $4}' | tr -d '+')
  fan1_rpm=$(echo "$sensors_output" | grep "fan1:" | awk '{print $2, $3}')
  fan2_rpm=$(echo "$sensors_output" | grep "fan2:" | awk '{print $2, $3}')

  if [ -z "$cpu_temp" ] || [ -z "$fan1_rpm" ] || [ -z "$fan2_rpm" ]; then
    echo "Blad: Nie udalo sie pobrac danych z sensors"
    return 1
  fi

  local volume brightness wifi bluetooth bt_battery battery ram_used
  volume=$(get_volume)
  brightness=$(get_brightness)
  wifi=$(get_wifi)
  bluetooth=$(get_bluetooth)
  bt_battery=$(get_bluetooth_battery)
  battery=$(get_battery)
  ram_used=$(awk '/^MemTotal/{t=$2} /^MemFree/{f=$2} /^Buffers/{b=$2} /^Cached:/{c=$2} END{printf "%.1f GiB", (t-f-b-c)/1024/1024}' /proc/meminfo)

  # Formatowanie wartości z jednostką % (N/A bez %)
  fmt_pct() {
    local v="$1"
    if [ "$v" = "N/A" ]; then echo "N/A"; else echo "${v}%"; fi
  }

  clear
  printf "╔"
  printf '═%.0s' $(seq 1 $BOX_INNER)
  printf "╗\n"
  printf "║%-${BOX_INNER}s║\n" "      MONITOR SYSTEMU"
  box_separator
  printf "║  %-$((BOX_INNER-4))s  ║\n" "Czas: $(date '+%H:%M:%S')"
  box_separator
  box_row_kv "CPU:"       "$cpu_temp"
  box_row_kv "Fan1:"      "$fan1_rpm"
  box_row_kv "Fan2:"      "$fan2_rpm"
  box_row_kv "RAM:"       "$ram_used"
  box_separator
  box_row_kv "Dźwięk:"    "$(fmt_pct "$volume")"
  box_row_kv "Ekran:"     "$(fmt_pct "$brightness")"
  box_row_kv "WiFi:"      "$(fmt_pct "$wifi")"
  if [ "$bluetooth" = "N/A" ]; then
    box_row_kv "Bluetooth:" "N/A"
    box_row_kv "└ bat.:"    "N/A"
  else
    box_row_kv "Bluetooth:" "$bluetooth urządz."
    # Pokaż naładowanie baterii każdego urządzenia BT
    # Etykieta: └ + skrócona nazwa (max 8 znaków), wartość: sam %
    if [ "$bt_battery" != "N/A" ]; then
      while IFS= read -r bt_line; do
        [ -z "$bt_line" ] && continue
        # bt_line ma format "NazwaUrządzenia: XX%"
        local bt_name bt_pct clean_name short_name
        bt_name=$(echo "$bt_line" | sed 's/: [^:]*$//')
        bt_pct=$(echo  "$bt_line" | grep -oP '[\d]+%|N/A' | tail -1)
        # Usuń znaki CJK, skróć do max 7 znaków + … (łącznie etykieta = 11 kolumn)
        clean_name=$(_strip_cjk "$bt_name")
        if [ "${#clean_name}" -gt 7 ]; then
          short_name="${clean_name:0:7}…"
        else
          short_name="$clean_name"
        fi
        box_row_kv "└ ${short_name}:" "${bt_pct:-N/A}"
      done <<< "$bt_battery"
    else
      box_row_kv "└ bat.:"    "N/A"
    fi
  fi
  box_row_kv "Bateria:"   "$battery"
  printf "╚"
  printf '═%.0s' $(seq 1 $BOX_INNER)
  printf "╝\n"
  echo ""
  echo "  Nacisnij Ctrl+C aby zakonczyc..."
}

# Sprawdź parametry
case "${1:-console}" in
"console" | "c")
  echo "Uruchamianie monitora w konsoli..."
  echo "Odswiezanie co 2 sekundy. Nacisnij Ctrl+C aby zakonczyc."
  echo ""
  while true; do
    show_sensors_data
    sleep 2
  done
  ;;

"notify" | "n")
  echo "Uruchamianie monitora z powiadomieniami..."
  echo "Powiadomienia co 5 sekund. Skrypt konczy sie po zamknieciu powiadomienia."

  while true; do
    sensors_output=$(sensors 2>/dev/null)
    cpu_temp=$(echo "$sensors_output" | grep "Package id 0:" | awk '{print $4}' | tr -d '+')
    fan1_rpm=$(echo "$sensors_output" | grep "fan1:" | awk '{print $2, $3}')
    fan2_rpm=$(echo "$sensors_output" | grep "fan2:" | awk '{print $2, $3}')
    volume=$(get_volume)
    brightness=$(get_brightness)
    wifi=$(get_wifi)
    bluetooth=$(get_bluetooth)
    bt_battery=$(get_bluetooth_battery)
    battery=$(get_battery)

    # RAM: aktualnie uzywana (w GiB)
    ram_used=$(awk '/^MemTotal/{t=$2} /^MemFree/{f=$2} /^Buffers/{b=$2} /^Cached:/{c=$2} END{printf "%.1f GiB", (t-f-b-c)/1024/1024}' /proc/meminfo)

    if [ -n "$cpu_temp" ] && [ -n "$fan1_rpm" ] && [ -n "$fan2_rpm" ]; then
      # Pomocnicza funkcja: etykieta wyrównana do 11 znaków (nie bajtów)
      _nrow() {
        local lbl="$1" val="$2"
        local llen pad
        llen=$(_vlen "$lbl")
        pad=$(( 11 - llen ))
        [ "$pad" -lt 0 ] && pad=0
        printf " %s%s %s" "$lbl" "$(_spaces $pad)" "$val"
      }

      bt_val="$( [ "$bluetooth" = "N/A" ] && echo "N/A" || echo "$bluetooth urządz." )"

      # Zbuduj sekcję baterii BT: jedna linia na urządzenie
      bt_bat_lines=""
      if [ "$bt_battery" != "N/A" ]; then
        while IFS= read -r bt_line; do
          [ -z "$bt_line" ] && continue
          local bt_name bt_pct clean_name short_name
          bt_name=$(echo "$bt_line" | sed 's/: [^:]*$//')
          bt_pct=$(echo  "$bt_line" | grep -oP '[\d]+%|N/A' | tail -1)
          clean_name=$(_strip_cjk "$bt_name")
          if [ "${#clean_name}" -gt 7 ]; then
            short_name="${clean_name:0:7}…"
          else
            short_name="$clean_name"
          fi
          bt_bat_lines="${bt_bat_lines}
$(_nrow "└ ${short_name}:" "${bt_pct:-N/A}")"
        done <<< "$bt_battery"
      else
        bt_bat_lines="
$(_nrow "└ bat.:" "N/A")"
      fi

      notify-send --wait " Monitor Systemu" \
        "$(_nrow "CPU:"        "$cpu_temp")
$(_nrow "Fan1:"       "$fan1_rpm")
$(_nrow "Fan2:"       "$fan2_rpm")
$(_nrow "RAM:"        "$ram_used")
─────────────────────────
$(_nrow "Dźwięk:"    "${volume}%")
$(_nrow "Ekran:"      "${brightness}%")
$(_nrow "WiFi:"       "${wifi}%")
$(_nrow "Bluetooth:"  "$bt_val")${bt_bat_lines}
$(_nrow "Bateria:"    "$battery")

Kliknij aby zamknąć monitor"

      if [ $? -eq 0 ]; then
        echo "Powiadomienie zostalo zamkniete. Koncze monitor."
        break
      fi
    fi
    sleep 5
  done
  ;;

"once" | "o")
  echo "Jednorazowe sprawdzenie:"
  show_sensors_data
  ;;

"help" | "h" | *)
  echo "Uzycie: $0 [opcja]"
  echo ""
  echo "Opcje:"
  echo "  console, c    - Monitor w konsoli (domyslnie, odswiezanie co 2s)"
  echo "  notify, n     - Powiadomienia systemowe (co 5s)"
  echo "  once, o       - Jednorazowe sprawdzenie"
  echo "  help, h       - Pomoc"
  echo ""
  echo "Przyklady:"
  echo "  $0            - Uruchom w trybie konsoli"
  echo "  $0 console    - Uruchom w trybie konsoli"
  echo "  $0 notify     - Uruchom z powiadomieniami"
  echo "  $0 once       - Sprawdz raz"
  ;;
esac
