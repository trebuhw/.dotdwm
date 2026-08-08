#!/bin/bash
dnf history list --reverse | grep -i install | awk '{print $1}' | while read id; do
  date=$(dnf history info "$id" 2>/dev/null | awk '/Begin time/ {print $4, $5}')
  dnf history info "$id" 2>/dev/null | awk -v d="$date" '/Install.*User/ {
    split($2, a, "-[0-9]")
    print d, a[1]
  }'
done
