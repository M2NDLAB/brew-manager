---
type: component
component: mod-01-health
updated: 2026-10-10
tags: [component]
---
# mod-01-health (modules/mod_01_health.sh)

The Homebrew health check: version, prefix, the date of Homebrew's code, Ruby, Xcode CLI
tools, prefix permissions, disk space, **developer mode**, taps, `brew doctor`. Risk
`write` (`[W]`) since 2026-10-10: it can restore Homebrew from developer mode after a
confirmation. Its restore is a GATED path (IMP-030: it modifies Homebrew's configuration).

## Current state
- Created as a note on 2026-10-10 (task 2 of [[plans/v2-personal-tool]]).
- It reads, never writes, except two things: brew doctor's output to the fixed
  `/tmp/brew_doctor.log` — also under `--dry-run` (STATE #11, task 4) — and the
  developer-mode restore below.

## What it exposes / responsibilities
- `_m01_dev_mode_state` — prints off | setting | pinned | env | unknown, READ-ONLY:
  `HOMEBREW_DEV_CMD_RUN` in the environment → env without asking; otherwise the first
  line of `brew developer state` (a regular command that only prints; the same in
  Homebrew 6.0.21 and 7.0.8). "pinned" = the setting plus `HOMEBREW_UPDATE_TO_TAG`.
  Anything unrecognised → unknown, and nothing is ever offered on unknown.
- `_m01_off_row <version>` — green only when Homebrew is on a plain `X.Y.Z` release;
  yellow with "run brew update" otherwise (advice only).
- `_m01_developer_mode [<version>]` — the report, and for setting/pinned the restore:
  a preview under `--dry-run` (before any confirmation); `_ask_danger` with default `y`
  (`--yes` proceeds, Enter declines, no terminal and no `--yes` declines) whose box shows
  the version Homebrew moves from and a stash warning when Homebrew's repository has
  local changes; then `brew developer off`, then `brew update` (each exit status read;
  a failed `off` stops before the update); then a re-read. The environment's variables
  are only reported (with a hint when the setting is also on).
- The Ruby version comes from `brew config` ("Homebrew Ruby:"); the "Homebrew code dated"
  row is the last commit of Homebrew's repository (not the package index).

## Constraints and pitfalls
- **Never a Homebrew developer command** (`brew ruby`, `brew audit`, …): running one turns
  developer mode on. `tests/test_homebrew_developer.zsh` scans the code (70 names, call
  forms in command position) and, at run time, checks module 1 against a mock brew.
- Homebrew's configuration belongs to the user (CLAUDE.md, IMP-031): any new action on it
  must be shown, confirmed, and never run under `--dry-run`.
- A failure of the restore is reported on screen but the session summary still shows ✓
  for the module (STATE #4b, task 7).

## Sessions that touched it
- [[sessions/2026-10-10-homebrew-developer-mode]] (developer mode: prevention, detection,
  restore)
