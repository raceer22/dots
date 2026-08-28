#!/bin/bash

while IFS= read -r app || [ -n "$app" ]; do
  [[ -z "$app" || "$app" =~ ^# ]] && continue

  target_dir="$HOME/.config/$app"
  echo "Deleting: $target_dir"
  rm -rf "$target_dir"
  echo "Stowing: $app"
  stow -S "$app" -t "$HOME" -v
done <apps.txt
