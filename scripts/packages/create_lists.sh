#!/usr/bin/env bash

set -euo pipefail

if (($# == 1)) && [[ $1 == --help || $1 == -h ]]; then
	printf 'Usage: %s\n' "${0##*/}"
	exit 0
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd -- "$script_dir/../.." && pwd)

dnf repoquery --userinstalled --qf "%{name}\n" | sort > "$repo_root/packages/fedora/dnf-packages.txt"
flatpak list --app --columns=application | sort > "$repo_root/packages/flatpak/flatpak-packages.txt"
