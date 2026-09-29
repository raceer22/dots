#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
package_dir="$repo_root/stow"

if ! stow_bin=$(command -v stow); then
  printf 'Error: GNU Stow is required but was not found in PATH.\n' >&2
  exit 1
fi

if [[ ! -d $package_dir ]]; then
  printf 'Error: Stow package directory not found: %s\n' "$package_dir" >&2
  exit 1
fi

mapfile -t unexpected_entries < <(find "$package_dir" -mindepth 1 -maxdepth 1 ! -type d -print)
if ((${#unexpected_entries[@]} > 0)); then
  printf 'Error: unexpected non-package entries under %s:\n' "$package_dir" >&2
  printf '  %s\n' "${unexpected_entries[@]}" >&2
  exit 1
fi

mapfile -t packages < <(find "$package_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
if ((${#packages[@]} == 0)); then
  printf 'Error: no Stow packages found under %s\n' "$package_dir" >&2
  exit 1
fi

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/stow-package-validation.XXXXXX")
trap 'rm -rf -- "$tmp_root"' EXIT

for package in "${packages[@]}"; do
  package_path="$package_dir/$package"
  mapfile -t expected_links < <(find "$package_path" \( -type f -o -type l \) -printf '%P\n' | sort)
  if ((${#expected_links[@]} == 0)); then
    printf 'Error: package contains no files or symlinks: %s\n' "$package_path" >&2
    exit 1
  fi

  home="$tmp_root/$package"
  mkdir -p "$home"
  if ! output=$("$stow_bin" --dir="$package_dir" --target="$home" --stow --simulate --verbose --no-folding "$package" 2>&1); then
    printf 'Error: Stow simulation failed for package %s:\n%s\n' "$package" "$output" >&2
    exit 1
  fi

  mapfile -t proposed_links < <(printf '%s\n' "$output" | sed -n 's/^LINK: \(.*\) => .*/\1/p' | sort)
  if ! diff -u <(printf '%s\n' "${expected_links[@]}") <(printf '%s\n' "${proposed_links[@]}"); then
    printf 'Error: proposed home-relative links do not match package %s contents.\n' "$package" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi

  printf 'Validated %s (%s home-relative links)\n' "$package" "${#proposed_links[@]}"
done