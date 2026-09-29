# Dotfiles Repository Reorganization PRD

## Summary

Reorganize the personal dotfiles repository so Stow-managed configurations, host selection, package manifests, and setup tooling have clear boundaries. Preserve one independently stowable package per application, keep each application's configuration files inside its package, and support multiple machines from one shared branch.

## Problem

The repository currently mixes Stow packages, root-level shell and tmux configurations, setup scripts, and package manifests. This makes the root harder to scan and leaves setup behavior split across scripts. The current apply script also removes target configuration directories before stowing, which can delete user data or unrelated files.

## Goals

- Make the repository root easy to understand at a glance.
- Keep every application configuration in its own Stow package.
- Keep machine-specific package selection explicit while sharing common configuration.
- Separate configuration packages from setup scripts and package manifests.
- Make setup operations predictable and avoid destructive replacement of target directories.
- Preserve existing configuration content and behavior during the structural migration unless a separate change is explicitly planned.

## Non-Goals

- Redesign or consolidate application configurations.
- Replace GNU Stow or change the target home directory.
- Automatically discover host-specific differences inside application configuration files.
- Overhaul package contents, themes, or application setup beyond what is needed for the new paths.
- Create a branch per machine.

## Proposed Repository Layout

```text
dots/
├── stow/
│   ├── doom/
│   ├── hypr/
│   ├── kanshi/
│   ├── kitty/
│   ├── niri/
│   ├── noctalia/
│   ├── nvim/
│   ├── ranger/
│   ├── zathura/
│   ├── tmux/
│   ├── zsh-fedora/
│   └── zsh-ubuntu/
├── hosts/
│   ├── <host-a>/stow-packages.txt
│   └── <host-b>/stow-packages.txt
├── packages/
│   ├── fedora/dnf-packages.txt
│   └── flatpak/flatpak-packages.txt
├── scripts/
│   ├── stow/
│   ├── setup/
│   └── packages/
├── docs/
│   └── dotfiles-reorganization-prd.md
└── README.md
```

The host names are examples. Use the actual machine names or stable aliases when implementing the host manifests.

## Functional Requirements

### Stow packages

- Each top-level directory under `stow/` is an independently selectable Stow package.
- Application packages retain their home-relative paths. For example, `stow/kitty/.config/kitty/kitty.conf` maps to `~/.config/kitty/kitty.conf`.
- Move existing application package directories under `stow/` without changing their contents as part of the structural migration.
- Add a `tmux` package containing `.tmux.conf` at its package root.
- Add separate `zsh-fedora` and `zsh-ubuntu` packages, each containing its intended `.zshrc` at the package root. Do not stow both variants on the same host.
- Place Zathura configuration under the home-relative path expected by the application, such as `.config/zathura/zathurarc`. Preserve and review `noctaliarc` rather than renaming or deleting it without confirming its purpose.
- Keep dynamic theme files and other application assets in the application package that consumes them.

### Host selection

- Store one Stow package name per line in `hosts/<host>/stow-packages.txt`.
- Provide one shared branch for common configuration; host differences are represented by manifests and separate packages where necessary.
- Host manifests must not select conflicting variants, including both Zsh packages.
- A Stow helper must read the selected host manifest and invoke Stow with `stow/` as the package directory and `$HOME` as the target.

### Scripts and manifests

- Organize executable tooling under `scripts/`, grouped by task (`stow`, `setup`, `packages`).
- Keep package manifests under `packages/`, grouped by package manager or distribution where appropriate.
- Move the current application selection list into host manifests or replace it with equivalent host-specific lists.
- Update scripts to resolve paths relative to their own location so they work regardless of the caller's current directory.
- Do not manually create symlinks for files already managed by Stow.
- Setup and Stow scripts must not delete existing target directories as a prerequisite for linking. Handle conflicts by reporting them and requiring an explicit user decision.
- Update references and ignore rules that depend on the old paths.

## Migration Plan

1. Record the current package-to-target mapping and identify files that are not currently Stow-shaped.
2. Create the new `stow/`, `hosts/`, and `scripts/` structure and move existing app packages without changing their contents.
3. Relocate tmux and Zsh configurations into their own Stow packages, retaining distinct host variants.
4. Correct the Zathura package tree to mirror the intended home-relative destination; confirm the role of `noctaliarc` before changing its filename or use.
5. Create host package manifests from the existing application list and verify each selected package exists.
6. Move setup utilities by task, move manifests to their intended locations, and update paths in scripts and `.gitignore`.
7. Replace destructive linking behavior with Stow conflict reporting and non-destructive handling.
8. Validate package link mappings in a temporary target directory, then verify installation on a real host before removing any legacy workflow.
9. Document normal use, host selection, adding a package, and recovery from Stow conflicts in `README.md`.

## Acceptance Criteria

- The repository root contains only high-level organization directories and essential project files, not individual application package trees or loose setup scripts.
- Every application configuration remains inside its corresponding independently stowable package.
- A dry-run or equivalent validation confirms each host manifest contains valid package names and creates only the expected home-relative links.
- Separate validation confirms Fedora and Ubuntu select the correct `.zshrc` package and never select both.
- No setup or Stow script unconditionally removes existing configuration directories or files.
- Scripts work when invoked from outside the repository root.
- Package manifests remain readable and are stored separately from Stow packages.
- Updated ignore rules still ignore generated or machine-specific theme outputs at their new paths.
- The README explains setup, host selection, package management, and conflict handling.
- Existing configuration contents are preserved unless a change is separately reviewed and documented.

## Risks and Decisions

- **Existing target conflicts:** Stow may refuse to link over files already in `$HOME`. The migration must report conflicts and avoid deleting them automatically.
- **Zathura paths:** The current files are at the package root, so their intended installation path must be confirmed and represented explicitly in the package tree.
- **`noctaliarc`:** Its name does not establish whether it is a Zathura config, a theme artifact, or another input; preserve it until verified.
- **Host identifiers:** Host manifest directory names need to be stable and documented.
- **Package lists:** The current DNF manifest is generated from installed user packages; retain that behavior unless package-list policy is decided separately.
- **Legacy script behavior:** The existing forced-apply workflow deletes targets and also handles tmux/Zsh links manually. It must not be carried forward unchanged.

## Out of Scope Follow-Up

Review whether package lists should be strictly reproducible or represent a snapshot of installed applications, and determine whether generated theme files should be committed or produced locally. These policy decisions are not prerequisites for the directory reorganization.
