#!/bin/bash


cd ~/Pobrane && mkdir -p Suckless && cd Suckless

git clone https://git.suckless.org/dwm
git clone https://git.suckless.org/st
git clone https://git.suckless.org/dmenu
git clone https://git.suckless.org/slstatus

cd dwm && make && sudo make clean install && cd ..
cd st && make && sudo make clean install && cd ..
cd dmenu && make && sudo make clean install && cd ..
cd slstatus && make && sudo make clean install && cd ..

exit 0




