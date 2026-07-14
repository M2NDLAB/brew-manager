# Changelog

All notable changes to brew-manager are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(annotated tags on `main`).

## [Unreleased]

## [1.2.0] - 2026-07-14

A safety release. Several actions did not honour `--dry-run`, one module
upgraded far more than it said it would, and app adoption never worked at all.
Everything that touches your system now previews under `--dry-run`, asks before
acting, and reports what it actually did.

### Added
- `--version` / `-V` (it did not exist before) and the version in the TUI header.
  A `VERSION` file at the root is now the single source of truth, so the version
  is correct from a git clone, a GitHub tarball or a plain copy; inside a work
  tree the output also shows the distance from the latest release tag.
- Scheduler integrity check (`las`, option 6): finds tracked agents whose stored
  data no longer matches the schedule launchd really uses, or whose module list
  was mangled by an older version (which made the agent fail on every scheduled
  run), and offers to regenerate their files from the plist.
- `SECURITY.md`: "Preventive measures in development" section.
- Development tooling for the project itself: `CLAUDE.md`, `.claude/`, `Makefile`
  (`run`, `check`, `lint`, `version-check`), git hooks (secret scanning +
  Conventional Commits) and `scripts/`. None of it is needed to run the tool.

### Changed
- **Auto-update casks (10) upgrade only the casks you confirmed.** Confirming the
  prompt used to run a global `brew upgrade --greedy`, which also upgraded
  formulae and casks that were never shown — despite the prompt saying
  "N cask(s)". Use module `4` for formulae and regular casks.
- **Backup restores (`bk` 3 / 3b / 3a) all ask before writing.** Restoring agents
  (`3a`) used to write plists and load them without confirmation; in an
  unattended run (`--yes`) the restores therefore now do nothing, consistently
  with the other two.
- **Cleanup (5) asks before removing.** It used to run `brew autoremove` and
  `brew cleanup -s` immediately on entering the module.
- README reconciled with what the tool actually does. Two features it had always
  advertised do **not** exist and are now marked as such: selecting modules from
  the command line (`./brew_manager.sh 1,4,5` — arguments are ignored) and
  per-agent module scheduling (every scheduled agent runs the full `go`
  sequence). Both are planned for a future release.

### Fixed
- **App adoption (0) works.** On every released version the selection channel was
  dead end to end, so `--adopt=all`, `--adopt=1,2` and interactive selection
  silently did nothing. The 1-based index is fixed too (selecting `[2]` used to
  target the app shown as `[1]`), every adoption echoes its target and asks
  first, whitespace works as a separator, duplicates are deduplicated, and
  flag-shaped `.app` names can no longer reach brew as arguments.
- **`--dry-run` is honoured everywhere.** Cleanup (5) deleted for real, the
  backup restores installed packages and loaded agents for real, and the greedy
  module (10) upgraded for real — all of them despite the flag. Dry-run now also
  always wins over `--yes`.
- **Unknown flags are rejected** instead of being silently ignored: a typo such
  as `--dryrun` (including Unicode dash look-alikes from smart-dash copy-paste)
  used to leave the tool running in real mode while you believed it was a dry
  run. It now fails with an error and a non-zero exit status.
- **Scheduler weekday mapping was off by one**: the weekly agent recorded an
  empty day name, restoring a Sunday agent turned it into Monday, and Saturday
  agents degraded to daily. Agents firing on multiple weekdays are now left
  untouched by the single-day tooling instead of silently losing days, and values
  coming from a backup bundle or a plist are validated before they reach a plist.
- Selecting an agent to modify or remove acted on the wrong one (same 1-based
  index bug), and a rejected "Modify" used to lose the agent's configuration.
- Tracked-binaries module (9): "Total tracked binaries" was always one higher
  than the number of binaries actually listed.
- The version reported by the tool no longer drifts from the released tags (it
  was stuck at 1.1.0 while the tags were already at v1.1.2).

## [1.1.2] — 2026-03-15
> Retro-populated at framework adoption; tag `v1.1.2` on commit `c0f456f`.

### Added
- `SECURITY.md` security policy.
- Homebrew availability check with guided installer.
- LaunchAgent integrity check (orphan plists ↔ pending confs) in the scheduler
  module.
- Backup module: split preview/restore menu entries (brew-only and agents-only
  variants).

### Changed
- README completed (modules catalog, flags, project structure).

## [1.1.1] — 2026-03-15
> Retro-populated at framework adoption; tag `v1.1.1` on commit `d3aee0b`
> ("initial release brew-manager v1.1.0" — the in-script version constant says
> 1.1.0; known drift, tracked in `.claude/memory/STATE.md`).

### Added
- Initial public release: zsh TUI with 14 standard modules (`go` sequence 0–13)
  and 4 named modules (`log`, `bk`, `las`, `mas`), session recording via
  `script(1)`, `--dry-run`/`--yes`/`--adopt`/`--upgrade` flags.
