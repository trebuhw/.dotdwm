# My dotfiles to dwm

### **Keybindings:**

- `super=win` `ModKey4` - default
- `super + shift + ?` = show `Keybindings`
- `super + enter` = terminal `ghostty`
- `super + shift + return` = web browser `google-chrome`
- `super + space` = launcher `rofi`
- `super + shift + space` = launcher `dmenu`
- `super + escape` = launcher `rofi - powermenu`
- `alt + escape` = launcher `dmenu - powermenu`
- `super + q` = kill window `pkill`
- `super + shift + q` = reload `dwm`

### **Installed theme:**

`nwg-look` - `set your choise`

- `GTK` - `Adwaita, Catppucin-Mocha`
- `Cursors` - `Adwaita, Yaru`
- `Icons` - `Adwaita, Colloid-Grey-Dracula`
- `Fonts` - `Adwaita Sans, JetBrains Mono Nerd Font`

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

### **Fedora - install dwm, config, .dotdwm:**

Scripts install:

`git clone --depth=1 https://github.com/trebuhw/fedora.git`

more info readme.md

---

