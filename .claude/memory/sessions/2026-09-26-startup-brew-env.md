---
date: 2026-09-26
task: branch 4 of the pre-dashboard debt cleanup — N1 + 4b-0 (Homebrew's PATH under launchd, a new exit code, an installer that honours --dry-run and never starts without a terminal); phase 1: the real-launchd verification
branch: fix/startup-brew-env
status: in-progress
model: 'claude-opus-5-5'
turns: 3
tags: [session, debt, launchd, startup, security]
---
# Session 2026-09-26 — debt cleanup, branch 4: startup without Homebrew on PATH (in progress)

Branch 3 was integrated by the user (merge `050ea6d`). The user approved the real-launchd
verification plan of [[plans/debt-cleanup-pre-dashboard]] (section "Task 4 — the
real-launchd verification") with three additions, to complete BEFORE handing over blocks
B–D. The outcome goes into this note and STATE #23 before any code; the fix itself (with
the docs/03 security gate) needs a further go from the user.

## Addition 1 — what the installer does at EOF (proved from the code)
- Nothing reads stdin before `brew_manager.sh:186`: no `set -e`/`setopt`; the `read`s of
  the libs sourced at :175-180 live inside functions (`_handle_log` lib/log.sh:21, `_ask`
  lib/common.sh:439, `_read_choice` :476); the first top-level read is :393.
- `:199` `read -r _brew_install_choice`: with stdin from /dev/null, closed, or an empty
  pipe, `/bin/zsh` 5.9 returns 1 and leaves the variable EMPTY — also when the environment
  pre-set it to `Y` (tested).
- `:201` `[[ "$_brew_install_choice" =~ ^[Yy]$ ]]` is false on the empty string → the
  `else` at :228-233 prints "cannot continue" and runs `exit 0`. `curl` (:205) and
  `exec zsh` (:220) exist only inside that `if`. EOF can never count as a confirmation, so
  the test was not stopped.

## Addition 2 — the test plist vs the plist las would write
- The las plist was produced by the REAL `_install_agent` (`mod_las_scheduler.sh:163-266`,
  its helpers :48-266 sourced into a sandbox with a mock `launchctl` and a fake HOME;
  `launchctl` recorded only `unload`/`load` of the sandbox path; the repo's agents/ and
  git status untouched) for modules `1` and a daily 03:07 schedule.
- The final diff, las → test: Label `com.m2ndlab.brew-manager.verify-n1` →
  `com.m2ndlab.verify-n1`; `--yes` → `--dry-run`; the StartCalendarInterval block removed;
  StandardOutPath/StandardErrorPath → `logs/verify_n1.out`/`.err`. Both files: no
  StandardInPath, no EnvironmentVariables (counted: 0); `plutil -lint` OK. The test file
  is `logs/com.m2ndlab.verify-n1.plist`, sha256
  `84e60212317e0595b05d56f28f8ca081ee6418fbcf3bab0f4dc73e4c8766ff29`.
- **The user's condition, clarified by the user**: "only Label and path differ" was
  over-specified; the intent was the SAME INVOCATION ENVIRONMENT — the shell, the shape of
  ProgramArguments, no EnvironmentVariables, no StandardInPath — which the approved plist
  keeps. The argument and the schedule are not read on the measured path
  (`brew_manager.sh:186-233`), as proved above.
- A las-identical variant (`1 --yes` with the 03:07 schedule) was selected by mistake in a
  question to the user, written to logs/ and committed in the plan (`1022c64`); the user
  corrected it before running any block, and the approved plist replaced it.

## Addition 3 — the blocks
- Blocks A–D are self-contained, with literal values and no comments (IMP-026); each
  passes `zsh -n`. Block A now also checks the plist is the approved one (its sha256, one
  `--dry-run`, no `--yes`, no StartCalendarInterval). Block B ends with a line that prints
  `STILL RUNNING - STOP HERE, NO CLEANUP` if the job has not finished after the 120 s poll;
  then there is no cleanup.
- The agent ran block A's read-only commands as a baseline: `278ce8f`, a clean status,
  macOS 27.0 arm64, brew only in /opt/homebrew/bin, no /etc/zshenv or ~/.zshenv, an empty
  `launchctl getenv PATH`, no brew_manager process, no verify_n1 output, "Could not find
  service", `plutil` OK. The run itself is the user's.

## Outcome of the real-launchd run
_(pending — the user runs blocks A and B and pastes the output; it is recorded here and in
STATE #23 before any code.)_

## Links
[[STATE]] · [[plans/debt-cleanup-pre-dashboard]] ·
[[sessions/2026-09-26-gitignore-and-launchd-plan]] ·
[[sessions/2026-09-24-debt-inventory-pre-dashboard]]
