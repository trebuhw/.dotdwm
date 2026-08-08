#!/bin/bash

# echo "Wybierz katalog:"
directory=~/.config/dwm/lns

if [ -d "$directory" ]; then
    selected_file=$(ls "$directory" | dmenu -p "Wybierz plik:")

    if [ -n "$selected_file" ]; then
        filepath="$directory/$selected_file"

        if [ -f "$filepath" ]; then
            kitty -e nvim "$filepath"
        else
            echo "Plik nie istnieje."
        fi
    else
        echo "Nie wybrano żadnego pliku."
    fi
else
    echo "Katalog nie istnieje."
fi
