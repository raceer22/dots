#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s [HOST ...]\n' "${0##*/}" >&2
}

if [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
  usage
  exit 0
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
stow_dir="$repo_root/stow"
hosts_dir="$repo_root/hosts"

if ! stow_bin=${STOW_BIN:-$(command -v stow 2>/dev/null)}; then
  printf 'Error: GNU Stow is required but was not found in PATH.\n' >&2
  exit 1
fi

if [[ ! -d $stow_dir ]]; then
  printf 'Error: Stow package directory not found: %s\n' "$stow_dir" >&2
  exit 1
fi

if [[ ! -d $hosts_dir ]]; then
  printf 'Error: host manifest directory not found: %s\n' "$hosts_dir" >&2
  exit 1
fi

has_errors=0

report_error() {
  printf 'ERROR: %s\n' "$*" >&2
  has_errors=1
}

read_manifest() {
  local manifest=$1
  local -n out=$2
  out=()

  while IFS= read -r entry || [[ -n $entry ]]; do
    entry=${entry%%#*}
    entry=${entry#"${entry%%[![:space:]]*}"}
    entry=${entry%"${entry##*[![:space:]]}"}
    [[ -z $entry ]] && continue
    out+=("$entry")
  done < "$manifest"
}

validate_package_mapping() {
  local host=$1
  local package=$2
  local package_path="$stow_dir/$package"
  local tmp_home
  local output
  local -a expected=()
  local -a proposed=()

  if [[ ! -d $package_path ]]; then
    report_error "host $host references package $package, but source directory is missing: $package_path"
    return
  fi

  mapfile -t expected < <(find "$package_path" \( -type f -o -type l \) -printf '%P\n' | sort)
  if ((${#expected[@]} == 0)); then
    report_error "host $host package $package has no files or symlinks to install from $package_path"
    return
  fi

  tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/stow-package-check-${host}-${package}.XXXXXX")
  trap 'rm -rf -- "$tmp_home"' RETURN

  if ! output=$("$stow_bin" --dir="$stow_dir" --target="$tmp_home" --stow --simulate --verbose --no-folding "$package" 2>&1); then
    report_error "host $host package $package failed simulation in temporary home $tmp_home"
    printf '  source: %s\n' "$package_path" >&2
    printf '  target: %s\n' "$tmp_home" >&2
    printf '%s\n' "$output" >&2
    return
  fi

  mapfile -t proposed < <(printf '%s\n' "$output" | sed -n 's/^LINK: \(.*\) => .*$/\1/p' | sort)

  if ! diff -u <(printf '%s\n' "${expected[@]}") <(printf '%s\n' "${proposed[@]}") >/dev/null; then
    report_error "host $host package $package home-relative mapping mismatch"
    printf '  source: %s\n' "$package_path" >&2
    printf '  target root: %s\n' "$tmp_home" >&2
    printf '%s\n' "$output" >&2
    printf '  expected: %s\n' "${expected[*]}" >&2
    printf '  proposed: %s\n' "${proposed[*]}" >&2
  fi

  rm -rf -- "$tmp_home"
  trap - RETURN
}

validate_conflict_behavior() {
  local host=$1
  local package=$2
  local package_path="$stow_dir/$package"
  local tmp_home
  local -a expected=()
  local conflict_target
  local conflict_contents='stow-conflict-check'
  local output

  mapfile -t expected < <(find "$package_path" \( -type f -o -type l \) -printf '%P\n' | sort)
  if ((${#expected[@]} == 0)); then
    report_error "host $host package $package has no files to test for conflict safety"
    return
  fi

  tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/stow-conflict-${host}-${package}.XXXXXX")
  conflict_target="$tmp_home/${expected[0]}"
  conflict_log="$tmp_home/stow-conflict.log"
  mkdir -p -- "$(dirname -- "$conflict_target")"
  printf '%s\n' "$conflict_contents" > "$conflict_target"

  if "$stow_bin" --dir="$stow_dir" --target="$tmp_home" --stow "$package" >"$conflict_log" 2>&1; then
    report_error "host $host package $package unexpectedly succeeded when a pre-existing file should have conflicted"
    printf '  source: %s\n' "$package_path" >&2
    printf '  target path: %s\n' "$conflict_target" >&2
    rm -rf -- "$tmp_home"
    return
  fi

  if [[ $(cat -- "$conflict_target") != "$conflict_contents" ]]; then
    report_error "host $host package $package modified an existing file during conflict testing"
    printf '  source: %s\n' "$package_path" >&2
    printf '  target path: %s\n' "$conflict_target" >&2
    printf '  post-conflict contents: %s\n' "$(cat -- "$conflict_target")" >&2
  fi

  rm -rf -- "$tmp_home"
}

validate_host() {
  local host=$1
  local manifest="$hosts_dir/$host/stow-packages.txt"
  local -a packages=()
  local package
  local tmp_home
  local output
  local has_fedora_zsh=false
  local has_ubuntu_zsh=false

  if [[ ! -f $manifest ]]; then
    report_error "host $host is missing a manifest at $manifest"
    return
  fi

  read_manifest "$manifest" packages
  if ((${#packages[@]} == 0)); then
    report_error "host $host manifest is empty: $manifest"
    return
  fi

  for package in "${packages[@]}"; do
    if [[ ! $package =~ ^[[:alnum:]_.-]+$ ]]; then
      report_error "host $host manifest contains an invalid package name '$package' in $manifest"
      continue
    fi
    if [[ ! -d "$stow_dir/$package" ]]; then
      report_error "host $host manifest references package $package, but it is missing from $stow_dir"
    fi
    case $package in
      zsh-fedora) has_fedora_zsh=true ;;
      zsh-ubuntu) has_ubuntu_zsh=true ;;
    esac
  done

  if $has_fedora_zsh && $has_ubuntu_zsh; then
    report_error "host $host manifest selects conflicting Zsh packages: zsh-fedora and zsh-ubuntu"
  fi

  for package in "${packages[@]}"; do
    validate_package_mapping "$host" "$package"
  done

  tmp_home=$(mktemp -d "${TMPDIR:-/tmp}/stow-host-check-${host}.XXXXXX")
  if ! output=$("$stow_bin" --dir="$stow_dir" --target="$tmp_home" --stow --simulate --verbose --no-folding "${packages[@]}" 2>&1); then
    report_error "host $host simulation failed in temporary home $tmp_home"
    printf '  manifest: %s\n' "$manifest" >&2
    printf '%s\n' "$output" >&2
  fi
  rm -rf -- "$tmp_home"

  for package in "${packages[@]}"; do
    validate_conflict_behavior "$host" "$package"
  done

  printf 'Validated host %s: %s\n' "$host" "${packages[*]}"
}

if (($# == 0)); then
  mapfile -t hosts < <(find "$hosts_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
else
  hosts=("$@")
fi

if ((${#hosts[@]} == 0)); then
  printf 'Error: no host manifests were found under %s\n' "$hosts_dir" >&2
  exit 1
fi

for host in "${hosts[@]}"; do
  validate_host "$host"
done

if (( has_errors > 0 )); then
  printf '\nValidation failed. Fix the host manifests or package mappings above before re-running.\n' >&2
  exit 1
fi

printf '\nAll host manifests passed package, mapping, Zsh, and conflict validation.\n'
