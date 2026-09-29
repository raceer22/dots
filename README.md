# Dotfiles Repository

This repository keeps machine-specific package selection, Stow-managed configuration packages, and setup helpers separated so the repo stays easy to reason about and safe to apply.

## Repository layout

- `stow/` — each top-level directory is a Stow package. Files inside each package keep their home-relative paths.
- `hosts/` — one host alias per directory, each with a `stow-packages.txt` manifest.
- `packages/` — package-manager lists such as DNF and Flatpak manifests.
- `scripts/stow/` — host validation and Stow application helpers.
- `scripts/setup/` — environment-specific setup helpers for Zsh and other installation tasks.
- `docs/` — design and migration notes.

This repository intentionally does not keep loose application package trees at the root; packages live under `stow/`, and package-manager outputs stay under `packages/`.

## Host aliases

Each alias maps to a manifest under `hosts/<alias>/stow-packages.txt`. Those manifests are the source of truth for what gets stowed on a machine. They must be updated when adding or removing packages for that host.

## Host manifest selection

A host manifest contains one Stow package name per line. For example, `hosts/fedora/stow-packages.txt` looks like this:

```text
niri
noctalia
doom
nvim
hypr
ranger
kitty
kanshi
zathura
tmux
zsh-fedora
```

Rules:

- One package name per line.
- Blank lines and comments are ignored.
- A host may select only one `zsh-*` stow directory.
- Package names must match a directory under `stow/`.

## Normal setup flow

1. Ensure GNU Stow is installed.
2. Validate a host manifest from the repository or from any working directory.
3. Dry-run the host before linking anything.
4. Apply the host once the dry run is clean.

Examples:

```bash
cd /path/to/dots
./scripts/stow/validate-hosts.sh
./scripts/stow/validate-hosts.sh fedora
./scripts/stow/apply-host.sh --dry-run fedora
./scripts/stow/apply-host.sh --dry-run --backup-conflicts fedora
./scripts/stow/apply-host.sh fedora
```

The helper scripts resolve their repository paths relative to the script location, so they can be run from outside the repo as well:

```bash
/path/to/dots/scripts/stow/validate-hosts.sh fedora
/path/to/dots/scripts/stow/apply-host.sh --dry-run ubuntu
```

## Validation workflow

Use the repository helper scripts rather than ad-hoc symlinks:

- `scripts/stow/validate-hosts.sh` — validates every host manifest, package mappings, and conflict behavior against temporary targets.
- `scripts/stow/validate-packages.sh` — validates the layout and home-relative links of every package under `stow/`.
- `scripts/stow/apply-host.sh` — preflights for conflicts, then applies the selected packages to `$HOME`. Conflicts fail by default; `--backup-conflicts` moves recognized targets under `~/.config/dots-backups` before retrying.
- `scripts/stow/apply_configs_force.sh` — compatibility wrapper that delegates to `apply-host.sh`; it does not delete existing target paths.

## Configuration packages vs setup scripts vs package manifests

These categories are intentionally separate:

- Configuration packages: `stow/<package>/...` for app config such as `kitty`, `niri`, `tmux`, and `zathura`.
- Setup scripts: `scripts/setup/...` for installing dependencies, creating toolchains, and bootstrapping local environments.
- Package manifests: `packages/<manager>/...` for DNF, Flatpak, or other package lists.

Do not mix package-manager output or runtime setup logic into `stow/`.

## Adding a package

1. Create the package directory under `stow/`.
2. Put the application files under the home-relative paths the application expects.
3. Add the package name to the appropriate `hosts/<host>/stow-packages.txt` file.
4. Validate the host and the package tree.
5. Apply the host with a dry run first.

Example:

```bash
mkdir -p /path/to/dots/stow/myapp/.config/myapp
# add files under stow/myapp/.config/myapp/...
printf '%s\n' 'myapp' >> /path/to/dots/hosts/workstation/stow-packages.txt
/path/to/dots/scripts/stow/validate-hosts.sh workstation
/path/to/dots/scripts/stow/apply-host.sh --dry-run workstation
/path/to/dots/scripts/stow/apply-host.sh workstation
```

Keep package contents inside the package directory itself. Avoid creating loose files or directories at the repository root for an app.

## Conflict recovery

Stow is intentionally conservative: conflicts fail by default. To back up recognized conflict paths automatically, explicitly pass `--backup-conflicts`:

```bash
/path/to/dots/scripts/stow/apply-host.sh --dry-run --backup-conflicts fedora
/path/to/dots/scripts/stow/apply-host.sh --backup-conflicts fedora
```

The helper moves only exact conflict paths it can safely identify. Backups are placed under `~/.config/dots-backups/<timestamp>/` with paths relative to `$HOME` preserved; symlinks are moved as links. A dry run reports planned moves without changing files or creating directories. Ambiguous diagnostics stop before any move. If a move or the follow-up preflight fails, the helper attempts to restore paths already moved.