#!/usr/bin/env bash

# Ścieżka do folderu z notatkami
NOTES_DIR="$HOME/Documents/Notes"

# Utworzenie folderu, jeśli nie istnieje
mkdir -p "$NOTES_DIR"

# Sprawdza, czy fzf jest zainstalowany
if ! command -v fzf &>/dev/null; then
  echo "Błąd: fzf nie jest zainstalowany."
  exit 1
fi

# Ustawia komendę podglądu
if command -v bat &>/dev/null; then
  preview_cmd="bat --style=numbers --color=always --line-range :500 {}"
else
  preview_cmd="cat {}"
fi

# Przejście do katalogu z notatkami
cd "$NOTES_DIR" || exit 1

# Uruchomienie fzf z obsługą akcji wewnątrz
# ctrl-d = usuwanie pliku
# ctrl-r = zmiana nazwy pliku
# Enter  = otwarcie/utworzenie pliku i wyjście
TARGET=$(find . -type f -not -path '*/\.git/*' -not -path '*/node_modules/*' 2>/dev/null |
  sed 's|^\./||' |
  sort |
  fzf --print-query \
    --prompt=" Nowa notatka: " \
    --header="ctrl-d: usuń  |  ctrl-r: zmień nazwę" \
    --preview "$preview_cmd" \
    --preview-window=right:50%:wrap \
    --bind="ctrl-d:execute(
      if [ -n {} ]; then
        read -r -p 'Usunąć {}? [T/n] ' confirm
        if [[ ! \"\$confirm\" =~ ^[nN]$ ]]; then
          rm {} && echo '✓ Usunięto {}'
        fi
      fi
    )+reload(find . -type f -not -path '*/\.git/*' -not -path '*/node_modules/*' 2>/dev/null | sed 's|^\./||' | sort)" \
    --bind="ctrl-r:execute(
      if [ -n {} ]; then
        NOTE_DIR=\$(dirname {})
        NOTE_BASE=\$(basename {})
        read -r -e -i \"\$NOTE_BASE\" -p 'Zmień nazwę: ' NEW_NAME
        if [ -n \"\$NEW_NAME\" ]; then
          if [ \"\$NOTE_DIR\" = '.' ]; then
            NEW_PATH=\"\$NEW_NAME\"
          else
            NEW_PATH=\"\$NOTE_DIR/\$NEW_NAME\"
          fi
          mv {} \"\$NEW_PATH\" && echo '✓ Zmieniono nazwę: {} → \$NEW_PATH'
        fi
      fi
    )+reload(find . -type f -not -path '*/\.git/*' -not -path '*/node_modules/*' 2>/dev/null | sed 's|^\./||' | sort)" |
  tail -n 1)

# Jeśli nic nie wybrano ani nie wpisano (np. ESC w fzf) - wyjdź
if [ -z "$TARGET" ]; then
  exit 0
fi

# Utwórz podfoldery, jeśli ścieżka zawiera katalogi
mkdir -p "$(dirname "$TARGET")"

# Otwarcie pliku w Neovim
nvim "$TARGET"
