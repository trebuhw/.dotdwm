#!/usr/bin/env bash

# Dependencies: rofi, bluez (bluetoothctl), bluez-utils, notify-send (libnotify)

# --- Cleanup: ONLY kill scan process, never touch power ---
cleanup() {
    [ -n "$SCAN_PID" ] && kill "$SCAN_PID" &>/dev/null
}
trap cleanup EXIT

# --- Bluetooth toggle option ---
bt_status=$(bluetoothctl show 2>/dev/null | grep "Powered" | awk '{print $2}')

if [[ "$bt_status" == "yes" ]]; then
    toggle="  Disable Bluetooth"
else
    toggle="  Enable Bluetooth"
fi

# --- Short background scan to refresh device list ---
if [[ "$bt_status" == "yes" ]]; then
    bluetoothctl scan on &>/dev/null &
    SCAN_PID=$!
    sleep 3
    kill "$SCAN_PID" &>/dev/null
    SCAN_PID=""
fi

# --- Build device list ---
final_list=""
while IFS= read -r dev_line; do
    mac=$(echo "$dev_line" | awk '{print $2}')
    name=$(echo "$dev_line" | cut -d' ' -f3-)

    [ -z "$mac" ] && continue

    if timeout 2 bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
        final_list+="  $name [$mac]\n"
    else
        final_list+="  $name [$mac]\n"
    fi
done < <(bluetoothctl devices 2>/dev/null)

scan_option="  Scan for new devices"

# --- Show rofi menu ---
chosen=$(printf "%s\n%s\n%b" "$toggle" "$scan_option" "$final_list" \
    | grep -v "^$" \
    | rofi -dmenu -i -selected-row 1 -p "󰂯 Bluetooth ")

[ -z "$chosen" ] && exit 0

# --- Handle selection ---
if [ "$chosen" = "  Enable Bluetooth" ]; then
    bluetoothctl power on
    notify-send "Bluetooth" "Bluetooth has been enabled."

elif [ "$chosen" = "  Disable Bluetooth" ]; then
    bluetoothctl power off
    notify-send "Bluetooth" "Bluetooth has been disabled."

elif [ "$chosen" = "  Scan for new devices" ]; then
    notify-send "Bluetooth" "Scanning for 8 seconds..."
    bluetoothctl scan on &>/dev/null &
    SCAN_PID=$!
    sleep 8
    kill "$SCAN_PID" &>/dev/null
    SCAN_PID=""
    notify-send "Bluetooth" "Scan complete. Reopen menu to see new devices."

else
    chosen_mac=$(echo "$chosen" | grep -oP '[0-9A-Fa-f:]{17}')
    chosen_name=$(echo "$chosen" | sed 's/ \[.*\]//' | sed 's/^....//' | xargs)

    if [ -z "$chosen_mac" ]; then
        notify-send "Bluetooth" "Could not determine device MAC address."
        exit 1
    fi

    dev_info=$(timeout 3 bluetoothctl info "$chosen_mac" 2>/dev/null)

    if echo "$dev_info" | grep -q "Connected: yes"; then
        action=$(printf "Disconnect\nCancel" | rofi -dmenu -i -p "  $chosen_name ")
        if [ "$action" = "Disconnect" ]; then
            bluetoothctl disconnect "$chosen_mac" && \
                notify-send "Bluetooth" "Disconnected from \"$chosen_name\"."
        fi
    elif echo "$dev_info" | grep -q "Paired: yes"; then
        notify-send "Bluetooth" "Connecting to \"$chosen_name\"..."
        bluetoothctl connect "$chosen_mac" && \
            notify-send "Bluetooth Connected" "Connected to \"$chosen_name\"." || \
            notify-send "Bluetooth Error" "Failed to connect to \"$chosen_name\"."
    else
        notify-send "Bluetooth" "Pairing with \"$chosen_name\"..."
        bluetoothctl pair "$chosen_mac" && \
        bluetoothctl trust "$chosen_mac" && \
        bluetoothctl connect "$chosen_mac" && \
            notify-send "Bluetooth Connected" "Paired and connected to \"$chosen_name\"." || \
            notify-send "Bluetooth Error" "Failed to pair/connect to \"$chosen_name\"."
    fi
fi
