# Changelog

All notable changes to brew-manager are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(annotated tags on `main`).

## [Unreleased]

### Added
- Claude Code process framework (claude-code-framework v0.2.0): `.claude/`
  process docs, slash commands and persistent memory (initialized from a full
  brownfield assessment), `CLAUDE.md` project index, `Makefile` (`run`, `check`,
  hooks targets), git hooks (gitleaks secret scanning + commitlint Conventional
  Commits), `commitlint.config.cjs`, `scripts/hooks-install.sh` and
  `scripts/reset-task.sh`.
- SECURITY.md: "Preventive measures in development" section.

### Fixed
- Cleanup module (5) now honors `--dry-run` (read-only preview via brew's own
  `--dry-run`/`-n` flags, with space estimate) and asks for confirmation before
  `brew autoremove` + `brew cleanup -s`; `--yes`/LaunchAgent runs keep the
  previous automatic behavior. Dry-run always wins over `--yes`.
- Unknown flags (e.g. the typo `--dryrun`, including Unicode dash lookalikes
  from smart-dash copy-paste) now fail fast with an error on stderr and exit 2
  instead of being silently ignored and running with default settings.
- Backup module (`bk`): all three restore paths honor `--dry-run` with a
  read-only preview (the Brewfile is read statically — brew evaluates Brewfiles
  as Ruby, so it is deliberately not invoked during previews). Restore agents
  (`3a`) now asks for confirmation like the other restore options; in
  `--yes`/non-interactive runs it therefore no longer restores silently
  (behavior change, consistent with `3`/`3b`).
- Auto-update casks module (10): confirming the prompt used to run a global
  `brew upgrade --greedy`, which also upgraded formulae and casks that were
  never shown — despite the prompt saying "N cask(s)". Only the casks listed in
  the confirmation are upgraded now (use module 4 for formulae and regular
  casks), each one's exit status is checked and reported, a cask that did not
  actually change version is reported as "no change" instead of "upgraded", and
  `--dry-run` finally previews this module instead of upgrading for real.
- Tracked-binaries module (9): "Total tracked binaries" was always one higher
  than the number of binaries actually listed.
- Scheduler (`las`) and backup restore (`bk`): the weekday mapping was off by one
  — the weekly agent recorded an empty day name, restoring a Sunday agent turned
  it into Monday, and Saturday agents degraded to daily. The integrity check (6)
  now also finds tracked agents with legacy or corrupt data (a mangled `modules`
  value would make the agent exit 2 on every scheduled run) and offers to
  regenerate their conf and plist from the schedule launchd actually uses.
  Agents firing on multiple weekdays are never rewritten by the single-day
  tooling: they are skipped with a warning instead of silently losing days.
  Values coming from an agents bundle or a plist (label, modules, hour, minute,
  weekday) are validated before they reach a plist, and a rejected "Modify" now
  leaves the previous agent untouched.
- Audit module (0): app adoption selection actually works now — on every
  released version the selection channel was dead end to end (`_read_choice`
  polluted the captured value with its own prompt text, and the launcher always
  exported a default that suppressed the interactive prompt), so `--adopt=all`,
  `--adopt=1,2` and interactive selection silently did nothing. On top of that
  the 1-based index is fixed (selecting [2] used to target the app shown as
  [1]), every adoption echoes its target and asks for confirmation first
  (auto-confirmed with `--yes`), `--dry-run` previews without installing,
  whitespace works as a separator, duplicates are deduplicated, invalid tokens
  warn, and flag-shaped `.app` names can no longer reach brew as arguments.

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
