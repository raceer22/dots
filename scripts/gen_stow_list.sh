#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DOTS_DIR="$SCRIPT_DIR/.."

cd "$DOTS_DIR" || exit 1

config_packages=()

for dir in */; do
  dir_name="${dir%/}"
  [[ -d "$dir_name" ]] || continue

  if [[ "$dir_name" != "scripts" && -d "$dir_name/.config" ]]; then
    config_packages+=("$dir_name")
  fi
done

# Print the list
printf '%s\n' "${config_packages[@]}" >>"$DOTS_DIR"/scripts/apps.txt

# To stow them all to your home directory, simply run:
# stow -t ~ "${config_packages[@]}"
