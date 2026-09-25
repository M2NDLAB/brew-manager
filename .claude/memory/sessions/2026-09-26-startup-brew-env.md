---
date: 2026-09-26
task: branch 4 of the pre-dashboard debt cleanup — N1 + 4b-0 (Homebrew's PATH under launchd, a new exit code, an installer that honours --dry-run and never starts without a terminal); phase 1: the real-launchd verification
branch: fix/startup-brew-env
status: in-progress
model: 'claude-opus-5-5'
turns: 4
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

## Outcome of the real-launchd run — CONFIRMED (with a poll race declared)
- **Block A (run by the user)**: exactly as expected — `278ce8f`, a clean status, macOS 27.0
  arm64, brew only in /opt/homebrew/bin, no /etc/zshenv or ~/.zshenv, an empty
  `launchctl getenv PATH`, no brew_manager process, no verify_n1 files, "Could not find
  service", `plutil` OK, sha256 `84e60212…66ff29`, one `--dry-run`, zero
  `--yes`/StartCalendarInterval/StandardInPath/EnvironmentVariables.
- **Block B (run by the user), verbatim essentials**: `service spawned with pid: 49799`;
  then `state = running`, `runs = 1`, `pid = 49799`, `last exit code = (never exited)`;
  `default environment = { PATH => /usr/bin:/bin:/usr/sbin:/sbin`; `cat` of verify_n1.out
  and .err printed nothing; `find` printed nothing; the last line printed `STILL RUNNING -
  STOP HERE, NO CLEANUP`. By the plan's rule the reading of block B was INCONCLUSIVE, so no
  cleanup was run.
- **Why block B saw a running job with empty output — a poll race, not a hang.** The agent
  re-read the evidence read-only about a minute later (00:26:42), without touching the job:
  verify_n1.out and .err were born AND last modified at 00:25:45 — the job was spawned,
  wrote everything and exited within one second, so it never ran for 120 s: the poll loop
  must have exited on its first check. Most likely cause (an inference, not observed):
  right after `kickstart` launchd still reported a transitional state, not `state =
  running`, so `grep -q 'state = running' || break` broke at once; the next `print` caught
  the process running and `cat` read the files before the first write. The STOP line fired
  correctly for the rule; the rule was fed by a wrong poll. Fixed in the plan: poll until
  `last exit code` is a number (it says "(never exited)" until the job ends).
- **The job's final record and output (read by the agent at 00:26:42)**: `state = not
  running`, `runs = 1`, `last exit code = 0`; `default environment = { PATH =>
  /usr/bin:/bin:/usr/sbin:/sbin }`, `environment` = only `OSLogRateLimit` and
  `XPC_SERVICE_NAME`, `inherited environment` = only `SSH_AUTH_SOCK` (no PATH override
  anywhere); verify_n1.out (333 bytes) = the banner, "x  Homebrew is not installed on
  this system.", "Install Homebrew now? (y/N)", "->  Choice: " left unanswered (EOF),
  then "Homebrew not installed — brew-manager cannot continue." and "Install manually:
  https://brew.sh" (the ASCII glyphs confirm the level-0 TUI of a run without a tty);
  verify_n1.err = 0 bytes; no `logs/brew_report_*` newer than the plist (the run stopped
  before `script(1)`); no process left (the tree of pid 49799 is empty).
- **Verdict: CONFIRMED.** Every CONFIRMED criterion of the plan holds on the job's final
  record: under a REAL launchd job, with the invocation environment of a las/bk agent,
  brew is not on PATH, the tool says Homebrew is not installed, declines the installer at
  EOF (no curl), and exits 0 — so the installed LaunchAgents never run brew and look
  successful. STATE #23 updated. The cleanup (block C) is still the user's, after this
  record; the fix waits for the user's go.

## Links
[[STATE]] · [[plans/debt-cleanup-pre-dashboard]] ·
[[sessions/2026-09-26-gitignore-and-launchd-plan]] ·
[[sessions/2026-09-24-debt-inventory-pre-dashboard]]
