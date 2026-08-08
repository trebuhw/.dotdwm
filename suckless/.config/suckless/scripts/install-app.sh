#!/bin/bash
sudo pacman -S  firefox git vim
#packer="sudo pacman -S --noconfirm --needed"
packer="sudo zypper install --no-recommends"

## Xorg & DWM

### Programs

$packer xorg-server
$packer xorg-xinit
$packer xorg-xrandr
$packer xorg-xsetroot
$packer xdg-user-dirs
$packer bash-completion
$packer kitty
$packer thunar
$packer firefox
$packer git
$packer vim
$packer feh
$packer dunst
$packer btop
$packer fish
$packer starship
$packer flameshot
$packer lsd
$packer neofetch
$packer fastfetch
$packer neovim
#$packer pdfarranger
$packer ranger
$packer rclone
$packer rsync
$packer tldr
$packer zathura
$packer sxiv
$packer rofi
$packer i3lock
$packer i3color
$packer gcolor2
$packer brigtnessctl
$packer lm-sensors
$packer polkit
$packer polkit-gnome
$packer cups
$packer sublime-text
$packer libreoffice
$packer libreoffice-l10n-pl

### DWM




## Wayland & Hyprland

#$packer wayland
#$packer xwayland
#$packer wlroots
#$packer waybar
#$packer hyprland
#$packer hyprpaper
#$packer xdg-desktop-portal-hyprland
$packer libreoffice
$packer libreoffice-l10n-pl

## YAY

#$packer github-desktop
#$packer google-chrome


exit 0




