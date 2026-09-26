# Changelog

All notable changes to brew-manager are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(annotated tags on `main`).

## [Unreleased]

### Fixed
- **Scheduled runs never ran Homebrew.** LaunchAgents installed with v1.3.0 and
  v1.4.0 — and with every earlier release that had the scheduler (v1.1.x, v1.2.0) —
  never ran brew under launchd, while looking successful. launchd starts a job with
  `PATH=/usr/bin:/bin:/usr/sbin:/sbin`, and a non-login zsh never reads
  `~/.zprofile`, so the tool found no `brew`, printed "Homebrew is not installed",
  declined its own installer prompt and exited `0`: every scheduled run ended before
  any module, and launchd recorded a success. Confirmed under a real launchd job
  before the fix. The exceptions are Macs where Homebrew's prefix reached launchd jobs
  some other way: a launchd `PATH` (for example `launchctl config user path`), or a
  `~/.zshenv` or `/etc/zshenv` that sets `PATH` or runs `brew shellenv` — zsh reads it
  even as launchd's non-login shell.
  brew-manager now finds Homebrew at its standard prefix (`/opt/homebrew` on Apple
  Silicon, `/usr/local` on Intel) when `PATH` lacks it, which also covers an app
  started from the Finder.
  **Upgrade note — review your agents before updating.** Existing agents need no
  reinstall: they run `brew_manager.sh`, which now finds Homebrew by itself. That is
  exactly why they should be reviewed first: at its next scheduled time every agent
  runs its modules for real — for most of them, the first time. The weekly and daily
  presets run `go --yes`, which includes module 2 (`brew update`) and module 5's
  cleanup (`brew autoremove` and `brew cleanup -s`, auto-confirmed under `--yes`).
  List them with `./brew_manager.sh las` and remove the ones you no longer want. An
  agent that selects `bk` or `log` can now start and then wait forever on a prompt
  (a known issue, to be fixed before the next release).
- **The built-in Homebrew installer honours `--dry-run` and never runs unattended.**
  It used to be offered even in a dry run, and without a terminal it took its answer
  from standard input — so a pipe carrying "y" could start it with nobody watching.
  Now it is never offered under `--dry-run`, a run without a terminal gets no prompt
  at all, and at a terminal it needs an explicit "y" — `--yes` never installs
  Homebrew. The install script is downloaded with timeouts and run only if the
  download succeeded: a failed or partial download used to be handed to bash.

### Added
- **Exit status `69` — Homebrew unavailable** (sysexits `EX_UNAVAILABLE`): Homebrew
  is neither on `PATH` nor at a standard prefix, and the installer was not offered,
  was declined or failed. Part of the exit-code contract, next to `0`, `1` and `2`.

### Changed
- A run that cannot start because Homebrew is missing now exits `69` instead of `0`
  (and a failed Homebrew installation exits `69` instead of `1`). A script or CI job
  that treated such a run as a success will now see it as a failure — which it is.

## [1.4.0] - 2026-07-23

The interface release. brew-manager now renders itself for the terminal it is
actually running in — colour and Unicode where they are supported, plain ASCII
when piped — puts a risk badge on every module, redraws the banner and menu, spins
while a long operation runs, and prints a summary of what each module did when the
session ends.

### Added
- **Capability-aware terminal rendering.** The tool detects colour and Unicode
  support and adapts: a semantic palette on a capable terminal, degrading to plain
  ASCII when output is piped or `NO_COLOR` is set. Piped output now carries zero
  ANSI escapes.
- **A risk badge on every module.** `[RO]` (read-only), `[W]` (writes only the
  tool's own files) and `[!]` (can change your system) appear in the menu — with a
  legend — and in each module's "About" block; destructive prompts are drawn in a
  distinct danger frame. Levels come from an audited per-module classification.
- **Redesigned banner and menu.** Modules are shown as aligned cards
  (badge · id · name · description) inside 80 columns, with the menu help
  compressed into a three-line footer.
- **A spinner while long operations run** (only on a real terminal; Unicode or
  ASCII frames) and **an end-of-session summary**: one outcome line per module run
  — in order, repeats included — plus tap/package statistics, the disk space
  reclaimed, and an identity footer.

### Fixed
- **`--dry-run` is honoured by `brew update` (module 2) and the `mas` install.**
  Both used to run even in a preview; they now sit behind the dry-run gate, which
  is checked before the confirmation prompt, so `--dry-run` wins over `--yes`.
- **Homebrew's implicit auto-update no longer runs under `--dry-run`.** Before an
  `install` / `outdated` / `upgrade` / `bundle`, Homebrew re-runs `brew update` by
  itself and rewrites its package index — which a preview must not do.
  `HOMEBREW_NO_AUTO_UPDATE=1` is now set for the duration of a `--dry-run` session.

### Known limitations
- **Two menu actions still act under `--dry-run`, and the summary now says so.**
  `bk` option [4] (Check) runs `brew bundle check`, and `las` option [c] (Clear
  logs) deletes the agent logs — both even in a preview. The end-of-session summary
  marks these with a warning (the `⚠` / `[!]` "ran" status: "dry-run was requested
  but this module acted anyway") instead of claiming the run changed nothing. Both
  are pre-existing and tracked for a dedicated hardening task.

## [1.3.0] - 2026-07-18

The scheduler release. The command line now takes a module selection, scheduled
agents finally run exactly the modules you configured, and unattended runs are
fail-closed: without `--yes` nothing on your system is modified, and the exit
code now tells launchd and scripts how the run really ended.

### Added
- Command-line module selection. `./brew_manager.sh 0,4,5` (or `go`) now runs
  those modules non-interactively, skipping the menu; `--only=ids` / `--skip=ids`
  filter the selection. An unknown module token is rejected with a non-zero exit
  rather than silently skipped, so a typo cannot run a different set of modules
  than intended. The interactive menu is unchanged when no selection is passed.

### Fixed
- Scheduled LaunchAgents now run the modules they were configured for, instead of
  always falling back to the full sequence. An agent — or a restored agents backup
  — whose stored module selection is invalid is refused/skipped rather than
  silently rewritten to run everything.
- A non-interactive run (a pipe, cron, `ssh host cmd`) without `--yes` now
  declines every confirmation prompt, so nothing on your system is modified unless
  you explicitly pass `--yes`. Only an explicit `--yes` — as the scheduled agents
  use — authorises the tool to act on the built-in defaults.
- The exit status of the process now reflects how the run actually ended: the
  session recorder (`script(1)` wrapper) no longer swallows the child's exit
  code, so an invalid selection (`./brew_manager.sh 99`) exits `2` and a
  selection that resolves to nothing exits `1` — visible to launchd, shell
  scripts and CI. A run interrupted by a signal now exits with the raw signal
  number (`script(1)` semantics: Ctrl+C → `2`), no longer `0`. (A failure
  *inside* a module still exits `0`: pre-existing behaviour, tracked
  separately.)

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
