#!/bin/bash

function powermenu {
  options="lock\nlogout\nscreenoff\nrestart\nshutdown"
  selected=$(echo -e $options | dmenu -p ">>> " -i) # demenu skonfigurowane i zainstalowane z ~/.config/dwm/dmenu/ sudo make clean install
  # selected=$(echo -e $options | dmenu -p ">>> " -nb '#1e1e2e' -nf '#cdd6f4' -sb '#313244' -sf '#cdd6f4' -fn 'JetBrainsMono Nerd Font:size=11')
  if [[ $selected = "shutdown" ]]; then
    sync
    systemctl poweroff
  elif [[ $selected = "restart" ]]; then
    sync
    systemctl reboot
  elif [[ $selected = "logout" ]]; then
    ~/.config/suckless/scripts/logout
  elif [[ $selected = "lock" ]]; then
    ~/.config/suckless/scripts/lock.sh
  elif [[ $selected = "screenoff" ]]; then
    ~/.config/suckless/scripts/screenoff.sh
  fi
}

powermenu
