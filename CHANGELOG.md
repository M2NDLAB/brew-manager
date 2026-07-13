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
