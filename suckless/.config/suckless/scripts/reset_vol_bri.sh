#!/usr/bin/bash

amixer sset 'Master' 50% &
brightnessctl set 30% &
wait

notify-send -t 3000 "Volume : 50
Screen : 30"
