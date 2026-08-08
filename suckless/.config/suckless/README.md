# dwm info

### **Keybindings:**

- `super=win` `ModKey4` - default
- `super + enter` = terminal `kitty`
- `super + c` = web browser `google-chrome-stable`
- `super + s` = editor `sublime-text-4`
- `super + d` = launcher `dmenu`
- `super + p` = launcher `dmenu - powermenu`
- `alt + d` = launcher `rofi -show drun`
- `alt + shift+ d` = launcher `rofi -show run`
- `super + q` = kill window `pkill`
- `super + shift + q` = reload `dwm`

### **Installed theme:**

`lxappearance` - `set your choise`

- `GTK` - `Adwaita, arc-theme, dracula, Catppucin-Mocha`
- `Cursors` - `Adwaita, Qogir-white-cursors`
- `Icons` - `Adwaita, Papirus,`
- `Fonts` - `FiraCode Nerd Font 11`

### **GRUB:**

Detection of other systems and update of grub

*Run os-prober to update-grub*

- edit `sudo nvim /etc/default/grub`

- find os-prober 

- delate # `GRUB_DISABLE_OS_PROBER=false`

- run `update-grub`

or

- `sudo grub-mkconfig -o /boot/grub/grub.cfg` 

---
