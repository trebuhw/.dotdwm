#!/bin/sh

pkill slstatus
pkill nm-applet

(
  slstatus
) &
(
  sleep 0.5
  nm-applet
) &
(
  sleep 1
  blueman-applet
) &
