---
type: plan
prompt: fix-homebrew-developer-mode
branch: fix/homebrew-developer-mode
created: 2026-10-10
status: in-progress
tags: [plan, homebrew, developer-mode, mod_01, gate]
---
# Plan: task 2 of the 2.0.0 plan — brew-manager never leaves Homebrew in developer mode

## Goal
Module 1 no longer runs a Homebrew developer command; a test keeps every developer command
out of the code; module 1 reports developer mode read-only and, when brew-manager can undo
it, offers `brew developer off` + `brew update` (back to the latest stable release) with a
`--dry-run` preview, a confirmation, and `--yes` proceeding (IMP-031). Decisions:
[[decisions/2026-10-07-v2-plan]] (the user's precisions on B2); STATE #30.

## Verified on the installed Homebrew before any code (2026-10-10, read-only)
- Installed: `Homebrew 7.0.8`, HEAD `a57af19` = tag 7.0.8 on branch `stable`; developer mode
  OFF (`brew developer state`: "Developer mode is disabled."). The Homebrew reflog shows the
  switch "from main to stable" on 2026-10-07 18:37:09 — outside this project's sessions (no
  command of the session or of its agents ran then; the transcripts were checked).
- Developer commands = the files in `Library/Homebrew/dev-cmd/` (68 names, identical in
  6.0.21 and 7.0.8) + the aliases `lc` → livecheck, `tc` → typecheck (`commands.rb`).
  `brew.sh:556-576`: running one as a non-developer writes `homebrew.devcmdrun true` into
  the git config of Homebrew's repository and prints a warning.
- `brew developer [state]` is a REGULAR command (`cmd/developer.rb`): it only prints — run on
  this Mac, `.git/config` kept its mtime and size. First line: "Developer mode is disabled." /
  "Developer mode is enabled because HOMEBREW_DEVELOPER is set." / "Developer mode is enabled
  because a developer command or `brew developer on` was run." (identical in 7.0.8).
- `brew developer off` = `Homebrew::Settings.delete "devcmdrun"` (`git config --unset-all
  homebrew.devcmdrun`); it cannot undo `HOMEBREW_DEVELOPER` in the environment (it says so).
- `brew update` without developer mode sets `HOMEBREW_UPDATE_TO_TAG` and moves Homebrew's
  repository to the latest `X.Y.Z` tag (`cmd/update.sh:547-555`, `:261-273`).
- `brew config` is a regular command; its "Homebrew Ruby:" line gives the Ruby version.

## Tasks
- [x] 1. This plan. — commit: `265bb83`
- [x] 2. Prevention + the root cause: a new suite `tests/test_homebrew_developer.zsh` whose
  static scan fails when a developer command appears in the code (RED shown on `brew ruby`
  at mod_01:32); mod_01 reads the Ruby version from `brew config` and relabels "Last DB
  update" (it is the date of Homebrew's code). — commit: `9f1d672` (RED: the
  scan found exactly mod_01:32; a first matcher also flagged mod_09's label "brew formula",
  so it was narrowed to command position; GREEN 4/4; a real `1 --dry-run` smoke left
  Homebrew's `.git/config` untouched)
- [x] 3. Detection + restore in mod_01 (`_m01_dev_mode_state`, `_m01_developer_mode`): off →
  a green row; the setting → a warning, a preview under `--dry-run`, `_ask_danger` (default
  `y`: `--yes` proceeds, Enter at the prompt declines, non-interactive declines), then `brew
  developer off` and `brew update`, each status read; `HOMEBREW_DEVELOPER` → reported, never
  "fixed" (the environment is the user's); unknown → reported, no offer. `MODULE_RISK[1]` →
  `write`; mod_01 joins the `_ask_danger` wiring scan. Runtime tests against a mock brew
  (every case, call ORDER, and no developer command ever called). — commit: this task's
  commit (16 checks; eight mutants — no dry-run gate, default n, the off status ignored,
  HOMEBREW_DEVELOPER or an unknown state treated as the setting, not wired, update before
  off, `brew ruby` back — each caught; suite 327; a real `1 --dry-run` smoke: [W], "off",
  Homebrew's .git/config untouched); `b478bb2`
- [x] 4. Docs: README (module 1), SECURITY.md (module 1 may change Homebrew's
  configuration and run `brew update` after confirmation), CHANGELOG `[Unreleased]`. —
  commit: this task's commit
- [ ] 5. The gate (IMP-030): one lens on the restore path, as the user asked; fixes. —
  commit: —
- [ ] 6. /checkpoint; the printed /integrate; the user's test sequence on this Mac (with
  developer mode created on purpose, since it is off today) and the manual fallback. —
  commit: —

## Resumption notes
- The user believed the Mac was in developer mode on 2026-10-10; it is not (see above). The
  test sequence starts with `brew developer on` as a deliberate, user-run step.

## Links
[[STATE]] · [[plans/v2-personal-tool]] · [[decisions/2026-10-07-v2-plan]] · [[core-brew-manager]]
