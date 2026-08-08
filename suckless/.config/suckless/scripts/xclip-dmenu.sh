#!/bin/bash
selected=$(echo -e "Paste from clipboard\nClear clipboard history" | dmenu -i -p "Wybierz opcję:")
if [ "$selected" == "Paste from clipboard" ]; then
  selected_word=$(xsel --clipboard --output 2>/dev/null)
  if [ -n "$selected_word" ]; then
    xdotool type --clearmodifiers "$selected_word"
  fi
elif [ "$selected" == "Clear clipboard history" ]; then
  xsel --clipboard --clear
fi
