#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s [--dry-run|--validate] HOST\n' "${0##*/}" >&2
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
apply_host="$script_dir/apply-host.sh"

if (($# == 1)) && [[ $1 == --help || $1 == -h ]]; then
  usage
  exit 0
fi

if [[ ! -x $apply_host ]]; then
  printf 'Error: required helper not found: %s\n' "$apply_host" >&2
  exit 1
fi

printf 'Note: %s is a compatibility wrapper and does not delete existing files.\n' "${0##*/}" >&2
printf 'Conflicts fail by default; --backup-conflicts moves recognized targets under ~/.config/dots-backups.\n' >&2
exec "$apply_host" "$@"
