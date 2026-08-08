#!/bin/bash

# Konfiguracja - UWAGA: Sprawdź najpierw czy masz BAT0 czy BAT1
BAT_PATH="/sys/class/power_supply/BAT0"
CHECK_INTERVAL=60 # sprawdzanie co 60 sekund

# Weryfikacja czy ścieżka istnieje
if [ ! -d "$BAT_PATH" ]; then
    echo "Błąd: Bateria $BAT_PATH nie istnieje. Uruchom 'ls /sys/class/power_supply/' aby sprawdzić poprawną nazwę."
    exit 1
fi

# Flagi zapobiegające powtarzaniu powiadomień
W15=0
W10=0
W5=0

while true; do
    STATUS=$(cat "$BAT_PATH/status")
    CAPACITY=$(cat "$BAT_PATH/capacity")

    if [ "$STATUS" = "Discharging" ]; then
        if [ "$CAPACITY" -le 5 ] && [ "$W5" -eq 0 ]; then
            notify-send -u critical "⚠️ Bateria: 5%" "Podłącz zasilanie, system zaraz się wyłączy!"
            W5=1
        elif [ "$CAPACITY" -le 10 ] && [ "$CAPACITY" -gt 5 ] && [ "$W10" -eq 0 ]; then
            notify-send -u critical "⚠️ Bateria: 10%" "Poziom krytyczny."
            W10=1
        elif [ "$CAPACITY" -le 15 ] && [ "$CAPACITY" -gt 10 ] && [ "$W15" -eq 0 ]; then
            notify-send -u normal "⚠️ Bateria: 15%" "Zalecane podłączenie zasilacza."
            W15=1
        fi
    else
        # Reset flag, gdy zasilacz zostanie podłączony
        W15=0
        W10=0
        W5=0
    fi

    sleep "$CHECK_INTERVAL"
done