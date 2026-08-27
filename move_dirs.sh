#!/bin/bash

while IFS= read -r app || [ -n "$app" ]; do
  [[ -z "$app" || "$app" =~ ^# ]] && continue

  mkdir -p "$app/.config"
  cp -r "$HOME/.config/$app" "$app/.config/"

done <apps.txt
