#!/usr/bin/env bash

set -euo pipefail

if (($# == 1)) && [[ $1 == --help || $1 == -h ]]; then
  printf 'Usage: %s HOST\n' "${0##*/}"
  exit 0
fi

if (($# != 1)); then
  printf 'Usage: %s HOST\n' "${0##*/}" >&2
  exit 2
fi

host=$1
if [[ ! $host =~ ^[[:alnum:]_.-]+$ ]]; then
  printf 'Error: invalid host alias: %s\n' "$host" >&2
  exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
manifest="$repo_root/hosts/$host/stow-packages.txt"

if [[ ! -f $manifest ]]; then
  printf 'Error: host manifest not found: %s\n' "$manifest" >&2
  exit 1
fi

while IFS= read -r package || [[ -n $package ]]; do
  package=${package%%#*}
  package="${package#"${package%%[![:space:]]*}"}"
  package="${package%"${package##*[![:space:]]}"}"
  [[ -z $package ]] && continue

  package_dir="$repo_root/stow/$package"
  source_dir="$HOME/.config/$package"
  [[ -d $package_dir ]] || { printf 'Error: Stow package not found: %s\n' "$package" >&2; exit 1; }
  [[ -d $source_dir ]] || continue

  mkdir -p "$package_dir/.config"
  cp -r -- "$source_dir" "$package_dir/.config/"
done < "$manifest"
