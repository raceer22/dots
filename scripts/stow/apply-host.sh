#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s [--dry-run] [--validate] [--backup-conflicts] HOST\n' "${0##*/}" >&2
}

dry_run=false
validate_only=false
backup_conflicts=false
host=''

while (($# > 0)); do
  case $1 in
    --dry-run)
      dry_run=true
      ;;
    --validate)
      validate_only=true
      ;;
    --backup-conflicts)
      backup_conflicts=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      printf 'Error: unknown option: %s\n' "$1" >&2
      usage
      exit 2
      ;;
    *)
      if [[ -n $host ]]; then
        printf 'Error: more than one host was provided.\n' >&2
        usage
        exit 2
      fi
      host=$1
      ;;
  esac
  shift
done

if [[ -z $host || ! $host =~ ^[[:alnum:]_.-]+$ ]]; then
  printf 'Error: provide a valid host alias.\n' >&2
  usage
  exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)
manifest="$repo_root/hosts/$host/stow-packages.txt"
package_dir="$repo_root/stow"

if [[ ! -f $manifest ]]; then
  printf 'Error: host manifest not found: %s\n' "$manifest" >&2
  exit 1
fi

if [[ ! -d $package_dir ]]; then
  printf 'Error: Stow package directory not found: %s\n' "$package_dir" >&2
  exit 1
fi

if ! stow_bin=$(command -v stow); then
  printf 'Error: GNU Stow is required but was not found in PATH.\n' >&2
  exit 1
fi

packages=()
while IFS= read -r package || [[ -n $package ]]; do
  package=${package%%#*}
  package="${package#"${package%%[![:space:]]*}"}"
  package="${package%"${package##*[![:space:]]}"}"
  [[ -z $package ]] && continue

  if [[ ! $package =~ ^[[:alnum:]_.-]+$ || ! -d "$package_dir/$package" ]]; then
    printf 'Error: invalid Stow package in %s: %s\n' "$manifest" "$package" >&2
    exit 1
  fi
  packages+=("$package")
done < "$manifest"

if ((${#packages[@]} == 0)); then
  printf 'Error: host manifest contains no Stow packages: %s\n' "$manifest" >&2
  exit 1
fi

has_fedora_zsh=false
has_ubuntu_zsh=false
for package in "${packages[@]}"; do
  case $package in
    zsh-fedora) has_fedora_zsh=true ;;
    zsh-ubuntu) has_ubuntu_zsh=true ;;
  esac
done

if $has_fedora_zsh && $has_ubuntu_zsh; then
  printf 'Error: host manifest selects conflicting Zsh packages: zsh-fedora and zsh-ubuntu.\n' >&2
  exit 1
fi

if $validate_only; then
  if $backup_conflicts || $dry_run; then
    printf 'Error: --validate cannot be combined with --dry-run or --backup-conflicts.\n' >&2
    exit 2
  fi
  printf 'Validated host %s: %s\n' "$host" "${packages[*]}"
  exit 0
fi

stow_args=(--dir="$package_dir" --target="$HOME" --stow --verbose)
preflight_args=("${stow_args[@]}" --simulate)
conflict_paths=()
backup_dir=''
moved_originals=()
moved_backups=()

validate_conflict_path() {
  local relative=$1
  local component
  local current="$HOME"
  local -a components=()

  [[ -n $relative && $relative != /* ]] || return 1
  [[ $relative != .config/dots-backups && $relative != .config/dots-backups/* ]] || return 1
  IFS='/' read -r -a components <<< "$relative"

  for component in "${components[@]}"; do
    [[ -n $component && $component != . && $component != .. ]] || return 1
  done

  for ((component_index = 0; component_index < ${#components[@]} - 1; component_index++)); do
    current="$current/${components[component_index]}"
    [[ ! -L $current ]] || return 1
  done

  [[ -e "$HOME/$relative" || -L "$HOME/$relative" ]]
}

parse_conflict_paths() {
  local line
  local relative
  local in_conflict_section=false
  local saw_abort=false
  local -a parsed_paths=()

  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line == WARNING\!\ stowing\ *\ would\ cause\ conflicts: ]]; then
      in_conflict_section=true
      continue
    fi
    if [[ $in_conflict_section != true ]]; then
      continue
    fi
    if [[ $line == 'All operations aborted.' ]]; then
      saw_abort=true
      in_conflict_section=false
      continue
    fi
    [[ -n $line ]] || continue

    if [[ $line =~ ^[[:space:]]+\*[[:space:]]+cannot\ stow\ .+\ over\ existing\ target\ (.+)\ since\ .+$ ]]; then
      relative=${BASH_REMATCH[1]}
    elif [[ $line =~ ^[[:space:]]+\*[[:space:]]+existing\ target\ is\ not\ owned\ by\ stow:\ (.+)$ ]]; then
      relative=${BASH_REMATCH[1]}
    else
      if [[ $line =~ ^[[:space:]]+\*[[:space:]] ]]; then
        printf 'Error: cannot safely interpret Stow conflict diagnostic: %s\n' "$line" >&2
        return 1
      fi
      printf 'Error: cannot safely interpret Stow conflict output: %s\n' "$line" >&2
      return 1
    fi

    if [[ -n $relative ]]; then
      if ! validate_conflict_path "$relative"; then
        printf 'Error: refusing unsafe or missing Stow conflict path: %s\n' "$relative" >&2
        return 1
      fi
      parsed_paths+=("$relative")
    fi
  done <<< "$output"

  if [[ $in_conflict_section == true || $saw_abort != true || ${#parsed_paths[@]} == 0 ]]; then
    printf 'Error: Stow conflict output was incomplete or unrecognized; no paths were moved.\n' >&2
    return 1
  fi

  # Keep only the highest reported path when Stow lists nested conflicts.
  local path existing skip
  for path in "${parsed_paths[@]}"; do
    skip=false
    for existing in "${conflict_paths[@]}"; do
      if [[ $path == "$existing" || $path == "$existing/"* ]]; then
        skip=true
        break
      fi
    done
    if ! $skip; then
      local -a remaining=()
      for existing in "${conflict_paths[@]}"; do
        [[ $existing == "$path/"* ]] || remaining+=("$existing")
      done
      conflict_paths=("${remaining[@]}" "$path")
    fi
  done
}

restore_moved_paths() {
  local index restore_failed=false
  for ((index = ${#moved_originals[@]} - 1; index >= 0; index--)); do
    if [[ -e ${moved_originals[index]} || -L ${moved_originals[index]} ]]; then
      printf 'Error: cannot restore %s because the original path now exists. Backup remains at %s\n' \
        "${moved_originals[index]}" "${moved_backups[index]}" >&2
      restore_failed=true
      continue
    fi
    if ! mkdir -p -- "$(dirname -- "${moved_originals[index]}")" ||
      ! mv -- "${moved_backups[index]}" "${moved_originals[index]}"; then
      printf 'Error: failed to restore %s from %s\n' \
        "${moved_originals[index]}" "${moved_backups[index]}" >&2
      restore_failed=true
    fi
  done
  $restore_failed && return 1
  return 0
}

prune_empty_package_directories() {
  local package source_directory relative target_directory
  local -a source_directories=()

  for package in "${packages[@]}"; do
    mapfile -d '' source_directories < <(find "$package_dir/$package" -mindepth 1 -type d -print0 | sort -zr)
    for source_directory in "${source_directories[@]}"; do
      relative=${source_directory#"$package_dir/$package"/}
      [[ $relative == .config ]] && continue
      target_directory="$HOME/$relative"
      rmdir -- "$target_directory" 2>/dev/null || true
    done
  done
}

printf 'Preflight: checking %s for conflicts before linking any target paths...\n' "$host"
if ! output=$("$stow_bin" "${preflight_args[@]}" "${packages[@]}" 2>&1); then
  if ! $backup_conflicts; then
    printf '%s\n' "$output" >&2
    printf 'Error: Stow preflight detected conflicts for host %s. No files were changed.\n' "$host" >&2
    printf 'Resolve the conflicting target(s) explicitly, or rerun with --backup-conflicts.\n' >&2
    exit 1
  fi

  if ! parse_conflict_paths; then
    printf '%s\n' "$output" >&2
    exit 1
  fi

  if $dry_run; then
    printf '%s\n' "$output"
    printf 'Would move these conflicts to %s: %s\n' "$HOME/.config/dots-backups/<timestamp>" "${conflict_paths[*]}"
    printf 'Dry run complete; no files or directories were changed.\n'
    exit 0
  fi

  if [[ -L "$HOME/.config" || ( -e "$HOME/.config" && ! -d "$HOME/.config" ) ]]; then
    printf 'Error: %s/.config must be a real directory to create the backup folder.\n' "$HOME" >&2
    exit 1
  fi
  backup_root="$HOME/.config/dots-backups"
  if [[ -L $backup_root || ( -e $backup_root && ! -d $backup_root ) ]]; then
    printf 'Error: backup path is not a real directory: %s\n' "$backup_root" >&2
    exit 1
  fi
  if ! mkdir -p -- "$backup_root"; then
    printf 'Error: could not create backup directory: %s\n' "$backup_root" >&2
    exit 1
  fi
  if ! backup_dir=$(mktemp -d "$backup_root/$(date +%Y%m%d-%H%M%S).XXXXXX"); then
    printf 'Error: could not create a unique backup directory under %s\n' "$backup_root" >&2
    exit 1
  fi

  for relative in "${conflict_paths[@]}"; do
    original="$HOME/$relative"
    backup="$backup_dir/$relative"
    if ! mkdir -p -- "$(dirname -- "$backup")" ||
      ! mv -- "$original" "$backup"; then
      printf 'Error: failed to move conflict %s into the backup.\n' "$original" >&2
      if ! restore_moved_paths; then
        printf 'Error: some paths could not be restored; inspect backups under %s\n' "$backup_dir" >&2
      fi
      exit 1
    fi
    moved_originals+=("$original")
    moved_backups+=("$backup")
  done

  printf 'Backed up conflicting paths under %s\n' "$backup_dir"
  if ! output=$("$stow_bin" "${preflight_args[@]}" "${packages[@]}" 2>&1); then
    printf '%s\n' "$output" >&2
    printf 'Error: Stow preflight still fails after backing up conflicts; restoring original paths.\n' >&2
    if ! restore_moved_paths; then
      printf 'Error: some paths could not be restored; inspect backups under %s\n' "$backup_dir" >&2
    fi
    exit 1
  fi
fi

if $dry_run; then
  printf '%s\n' "$output"
  printf 'Dry run for host %s succeeded without conflicts.\n' "$host"
  exit 0
fi

printf 'Applying host %s...\n' "$host"
if ! "$stow_bin" --dir="$package_dir" --target="$HOME" --delete --verbose --no-folding "${packages[@]}"; then
  printf 'Error: could not remove existing Stow links for host %s; no new links were applied.\n' "$host" >&2
  exit 1
fi
prune_empty_package_directories

if ! $backup_conflicts || ((${#moved_originals[@]} == 0)); then
  exec "$stow_bin" "${stow_args[@]}" "${packages[@]}"
fi

if "$stow_bin" "${stow_args[@]}" "${packages[@]}"; then
  exit 0
else
  stow_status=$?
  printf 'Error: Stow failed after backups were created; original paths remain under %s\n' "$backup_dir" >&2
  exit "$stow_status"
fi