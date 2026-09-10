#!/bin/bash

while IFS= read -r app || [ -n "$app" ]; do
  [[ -z "$app" || "$app" =~ ^# ]] && continue

  target_dir="$HOME/.config/$app"
  echo "Deleting: $target_dir"
  echo "Stowing: $app"
done <apps.txt
