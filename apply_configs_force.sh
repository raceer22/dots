#!/bin/bash

while IFS= read -r app || [ -n "$app" ]; do
  [[ -z "$app" || "$app" =~ ^# ]] && continue

  target_dir="$HOME/.config/$app"
  echo "Deleting: $target_dir"
  rm -rf "$target_dir"
  echo "Stowing: $app"
  stow -S "$app" -t "$HOME" -v
done <apps.txt

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TMUX_DEST="$HOME/.tmux.conf"
ZSH_DEST="$HOME/.zshrc"

rm -f "$TMUX_DEST" "$ZSH_DEST"

ln -sfr tmux.conf "$TMUX_DEST"
ln -sfr .zshrc.fedora "$ZSH_DEST"
