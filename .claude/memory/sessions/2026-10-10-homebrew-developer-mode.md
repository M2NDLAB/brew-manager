---
date: 2026-10-10
task: task 2 of the 2.0.0 plan — brew-manager never leaves Homebrew in developer mode (prevention test, read-only detection, restore with preview and confirmation)
branch: fix/homebrew-developer-mode
status: completed
model: 'claude-opus-5-5'
turns: 1
tags: [session, homebrew, developer-mode, mod_01, gate]
---
# Session 2026-10-10 — task 2: Homebrew developer mode

The user integrated task 1 (merge `f232f12`) and gave the go for task 2 as planned
([[plans/v2-personal-tool]], [[plans/fix-homebrew-developer-mode]]): prevention with a
test on developer commands, detection in module 1, a restore with preview and
confirmation, a one-lens gate on the restore path; after the merge, a test sequence on
this Mac with the expected outcomes and a manual fallback.

## Found before any code (read-only)
- **This Mac is NOT in developer mode today**, contrary to the user's message: `brew
  developer state` → "Developer mode is disabled."; `Homebrew 7.0.8`, HEAD `a57af19` = tag
  7.0.8 on branch `stable`. Homebrew's reflog: "checkout: moving from main to stable" on
  2026-10-07 18:37:09 (+0200), `.git/config` modified at the same second. No command of
  the session or of its agents ran then (the main transcript and every workflow agent's
  shell commands were checked: the session was idle between 16:26 and 16:40 UTC, waiting
  for the user's approval). Most likely the user ran `brew developer off` + `brew update`
  after reading the plan. The test sequence therefore creates the condition on purpose.
- A Level-1 correction of my own record: the D3 check of 2026-10-07 said "verified on the
  installed brew (6.0.21)"; it was already 7.0.8 by then. The conclusion stands (the
  5.1.6/6.0.0 facts come from the tags) — corrected in the assessment note and the
  decision record.
- Homebrew's behaviour, verified in its source (identical in 6.0.21 and 7.0.8) and on the
  real install: the developer commands are the 68 files of `dev-cmd/` plus the aliases
  `lc` and `tc`; `brew.sh:556-576` writes `homebrew.devcmdrun true` when one runs; `brew
  developer state` only prints (`.git/config` mtime and size unchanged after running it);
  `brew developer off` = `git config --unset-all homebrew.devcmdrun`; `brew update`
  without developer mode checks out the latest `X.Y.Z` tag.

## Done
- `265bb83` — the task plan.
- `9f1d672` — the root cause and the prevention: module 1's `brew ruby --version` (a
  developer command) replaced by the "Homebrew Ruby:" line of `brew config`; "Last DB
  update" → "Homebrew code dated"; the new suite `tests/test_homebrew_developer.zsh` scans
  the code for developer commands in command position. RED on main: exactly `mod_01:32`
  (a first matcher also flagged mod_09's label "brew formula" — narrowed to command
  position). GREEN.
- `b478bb2` — detection and restore in module 1 (`_m01_dev_mode_state`,
  `_m01_developer_mode`), `MODULE_RISK[1]` → `write`, module 1 in the `_ask_danger` wiring
  scan, runtime tests against a mock brew (call order, no developer command ever called).
  Eight mutants, each caught.
- `5309684` — README (module 1, the `[W]` legend), SECURITY.md (Homebrew's configuration
  only by a confirmed action; module 1's `brew update`), CHANGELOG `[Unreleased]`.
- `ded74f6` — the gate fixes (below). Six mutants, each caught.

## Security gate (IMP-030, one lens on the restore path — the user's instruction)
- **No CRITICAL, HIGH or MEDIUM**: the path does only what was approved (setting only, a
  preview under `--dry-run` before any confirmation, `_ask` fail-closed without a
  terminal and `--yes`, the injected `BREW_MANAGER_*` overwritten by the flags, the state
  classification failing safe, no echo on data).
- **LOW, fixed**: (1) the consent text understated the effect → "set by a developer
  command or 'brew developer on'", the box shows the version Homebrew moves from (the
  latest tag can be older than a main commit), a read-only `git status` warns that `brew
  update` stashes local changes and does not restore them, the CHANGELOG says `--yes`
  agents will run the restore; (2) "off" was green on the setting alone →
  `HOMEBREW_DEV_CMD_RUN` counts as environment, and both off rows check for a plain X.Y.Z
  release (advice only otherwise); (3) the matcher missed call forms (VAR= prefixes,
  env/sudo/timeout/arch, a path or a variable for brew, a quoted subcommand) → 14 probe
  forms.
- **INFO, fixed**: the dry-run test now proves no confirmation is reached;
  `HOMEBREW_UPDATE_TO_TAG` no longer reported as "follows main"; both the variable and the
  setting named; the `[W]` caption covers Homebrew's settings. **Recorded**: a failed
  restore still shows ✓ in the summary (STATE #4b, task 7); the "runtime tripwire over
  every module" idea is not taken (the static scan plus module 1's run-time check cover
  the code that exists).

## Verification
- `make check` green; `make test` 333 checks green (the new suite: 22); no process left;
  `/tmp/brew_doctor.log` restored by the suite.
- Real smokes of `./brew_manager.sh 1 --dry-run` on this Mac (developer mode off): rc 0,
  "Developer mode — off — Homebrew 7.0.8, a stable release", `[W]`, Ruby 4.0.7, and
  Homebrew's `.git/config` unchanged (mtime, size, no `devcmdrun`) — before the fix the
  module wrote it on every run.

## The user's test sequence (after the merge; blocks in the session reply)
1. The initial state (read-only): version, `brew developer state`, tag, branch,
   `devcmdrun`. Today: 7.0.8, disabled, `stable`, empty.
1b. Developer mode is off today, so it is created on purpose: `brew developer on` (it only
   writes the setting; the code stays at 7.0.8 until an update). No brew
   install/upgrade/outdated/bundle/update elsewhere until step 3 — an auto-update would
   follow `main`.
2. `./brew_manager.sh 1 --dry-run`: the ON row and the "would run" preview, no box; the
   setting and HEAD identical before and after.
3. `./brew_manager.sh 1` at the terminal: the box, answer `y`; `brew update` output; "off —
   Homebrew 7.0.x, a stable release".
4. The final check: a plain 7.0.x, disabled, `describe` = the version, `stable`, no
   setting; a second `./brew_manager.sh 1` shows "off" and does not turn it on again.
- Fallback by hand: `brew developer off`, `brew update`, then the same checks.

## Problems encountered → cause → solution
1. The user's premise (developer mode on) was false today → the state changed outside
   the session → verified read-only before any code; the test sequence adapted.
2. My D3 record named the wrong Homebrew version → I wrote down a remembered version
   instead of reading it at verification time → Level-1 correction; IMP-032.
3. A python heredoc holding test code cut short → its text contained a line `EOF`, which
   closed the outer heredoc → the Edit tool for such content (the IMP-027 family).

## Proposals
- IMP-032 (a verification record reads the environment at that moment), OPEN in
  [[LEARNINGS]].

## Links
[[STATE]] · [[plans/v2-personal-tool]] · [[plans/fix-homebrew-developer-mode]] ·
[[mod-01-health]] · [[decisions/2026-10-07-v2-plan]]
