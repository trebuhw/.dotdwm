#!/bin/bash

# Sprawdza, czy podano argument (ścieżkę)
if [ -z "$1" ]; then
  # Jeśli nie podano ścieżki, przeszukuje od /
  search_path="/"
else
  # Jeśli podano ścieżkę, używa jej (sprawdza, czy istnieje)
  search_path="$1"
  if [ ! -d "$search_path" ]; then
    echo "Błąd: Ścieżka '$search_path' nie istnieje lub nie jest katalogiem."
    exit 1
  fi
fi

# Przeszukuje pliki (w tym ukryte) i otwiera wybrany w nvim
find "$search_path" -type f -not -path '*/\.git/*' | fzf --preview 'bat --style=numbers --color=always {}' | xargs -r nvim