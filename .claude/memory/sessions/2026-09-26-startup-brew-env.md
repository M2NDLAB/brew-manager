---
date: 2026-09-26
task: branch 4 of the pre-dashboard debt cleanup — N1 + 4b-0 (Homebrew's PATH under launchd, a new exit code, an installer that honours --dry-run and never starts without a terminal); phase 1: the real-launchd verification
branch: fix/startup-brew-env
status: in-progress
model: 'claude-opus-5-5'
turns: 5
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
  successful. STATE #23 updated.
- **Seen by the user, then cleaned up.** The user ran a read-only block E with the same
  commands and got the same evidence verbatim (`state = not running`, `runs = 1`, `last
  exit code = 0`; the default PATH with no override; the full verify_n1.out; `0` bytes of
  stderr; born = modified = 00:25:45; `find` and `pgrep` empty). Then block C: `bootout`,
  "Could not find service", no process in the `ps` line (block D not needed), the plist
  and both outputs removed. The agent re-checked read-only: the service is gone, the three
  files are gone, no process, nothing in ~/Library/LaunchAgents, the repo is clean.
- Next: the fix, only on the user's go.

## The fix (2026-09-27, tasks 1–4 of [[plans/fix-startup-brew-env]])
The user gave the go with six requirements (PATH bootstrap independent of the login
shell; a new exit code outside 1–31 and 126–255, chosen from sysexits.h with a reason;
an installer that honours `--dry-run` and never starts, nor prompts, without a
terminal; e2e tests in a minimal environment; the re-verification under a real launchd
job; an honest CHANGELOG entry).
- `c277e20` (task 1) — `_brew_bootstrap_path`: when `brew` is not on PATH, probe
  `BREW_BIN_CANDIDATES=(/opt/homebrew/bin/brew /usr/local/bin/brew)` in order and
  prepend the first regular executable's `bin` and `sbin` to PATH (exported, so the
  `script(1)` child inherits it). No `eval "$(brew shellenv)"`: nothing reads
  HOMEBREW_PREFIX & co., and startup never runs a binary's output. RED: with the probe
  disabled, 2 checks fail.
- `ae022d9` (task 2) — exit **69** (`EX_UNAVAILABLE`: "a support program or file does
  not exist") on every "Homebrew unavailable" path; 78 `EX_CONFIG`, 72 `EX_OSFILE` and 1
  (overloaded) were discarded (the plan has the reasons). The installer: never offered
  under `--dry-run`; with no terminal (`NON_INTERACTIVE`, stdout not a TTY, or the
  recorded child) no prompt at all; at a terminal `_ask` with default `n`, so `--yes`
  never installs Homebrew. RED on the task-1 code: 6 checks fail.
- `df8c0ec` (task 3) — 69 in docs/04's exit-code contract (MINOR → v1.5.0); README
  (Homebrew lookup, exit status, scheduling); SECURITY.md (the installer).
- `b1c78f6` (task 4) — CHANGELOG `[Unreleased]`: agents installed with v1.3.0 and v1.4.0
  (and every earlier release with the scheduler) never ran brew under launchd while
  looking successful.

## Security gate (task 5) — docs/03, adversarial (`brew_manager.sh` is sensitive)
- **The gate: two runs of the same five lenses**, started two minutes apart around the
  restart (installer-consent, path-trust, exit-contract, claims-vs-behaviour,
  tests-and-class), each lens challenged by a refuter that had to reproduce or
  disprove every finding. Both completed. **No CRITICAL or HIGH.**
- **MEDIUM (upheld in the second run, graded LOW in the first):** the fix makes the
  dormant agents reachable, and an agent that selects `bk` or `log` then blocks forever
  on a bare `read` (the class of STATE #21). Not fixed here: #21 is branch 6 of
  [[plans/debt-cleanup-pre-dashboard]], before the release. Disclosed in the CHANGELOG
  upgrade note; the acceptance is the user's decision (below).
- **MEDIUM → fixed:** "existing agents need no change" hid that every installed agent
  starts making changes, unattended, at its next run → the CHANGELOG upgrade note
  (review your agents first; the presets run `go --yes`, i.e. `brew update` and module
  5's cleanup) and the README blockquote.
- **LOW → fixed** (`b34e719` code, `1c6105d` tests, `45c5fd2` docs): the no-terminal
  guard's clauses untested one by one; the production candidates and "69 on every way
  out" not pinned (the failed-install path cannot run e2e without confirming the
  installer, so it is pinned statically); the second candidate, the Intel symlink layout
  and the order never exercised; the script(1) runs without a watchdog (and a naive
  alarm would orphan script(1)'s session → a process-group watchdog); "the only
  exception" ignored `~/.zshenv`; HOMEBREW_* settings from the login profile do not
  reach scheduled runs (documented); `command -v` counted a function or alias → `whence
  -p`; the download ran with no status check and no timeout, so a partial script could
  reach bash → `curl -fsSL --connect-timeout 15 --max-time 300`, run only a successful,
  non-empty download; "Homebrew is not installed" → "was not found".
- **INFO → applied:** the exit precedence documented (docs/04, README) and tested; the
  old piped-"y" defect named in the CHANGELOG; test comments that claimed more than they
  proved; SECURITY.md sentences next to the edited bullet; the new messages go through
  the lib/common.sh helpers (the static banner lines stay as they were: no data in
  them, so IMP-003 does not apply).
- **INFO → recorded, not fixed here** (outside the branch's scope): the recorder's `zsh`
  and `script` are resolved through PATH, which the bootstrap now prefixes (a planted
  binary in a Homebrew prefix already owns brew itself); exit `1` is overloaded by
  startup failures of the tool's own files; the logs fallback reports a log path that
  holds no file (pre-existing); the installer prompt is a plain `_ask` (default `n`),
  not BM-10's `_ask_danger` frame — presentation only, consent unchanged; exit 69 is
  proven in the launchd-shaped `env -i` e2e, not under a real launchd job (the user's
  job exercises the found path). Refuted: "a pty wrapper counts as a terminal" (a pty
  IS a terminal: the prompt is the documented behaviour).
- **Re-gate (IMP-004) on the whole branch diff, the same three review areas of the
  fixes** (installer and download, probe and exit contract, docs and tests), each with a
  refuter. The first run completed only the probe lens: the other two stalled on all 6
  attempts, even on trivial greps, over a 9.5-hour run (the machine most likely slept) —
  reported as incomplete, not as clean (docs/03: reconcile the count first). They were
  rerun on the final diff. **No CRITICAL, HIGH or MEDIUM in any lens.** Upheld and fixed:
  - `3657cc3`/`1317307` — LOW: no test told `whence -p` from `command -v` → a brew that is
    only a `~/.zshenv` function or alias must still give 69 (and never be called), and with
    Homebrew at a prefix the prefix still goes first on PATH; INFO: `--version` first in
    the exit order was untested and missing from the README → tests (0 even next to an
    unknown flag; an empty selection yields to 69) and wording; INFO: the CHANGELOG line
    on a function or alias brew.
  - `b7b56e7` — LOW: the installer's exit status was ignored, so an installer failing
    after leaving `bin/brew` (its last step is `brew update`; the refuter checked the
    upstream script) printed "installed successfully" and re-exec'd. The step moved into
    `_brew_install`, which reads the status and fails closed; the script lives in a local.
  - `f68d114` — LOW: the download hardening had no pin (three mutants passed) → the suite
    extracts `_brew_install` and `_brew_bootstrap_path` from the source and runs them
    alone against a mock curl (failed, empty, half-install, no-brew and good installs;
    one curl call with both timeouts and the official URL). LOW: the watchdog orphaned a
    blocked run on Ctrl-C, because `setpgrp` puts it out of the terminal's reach → perl
    kills the group on INT/TERM/HUP and cleanup sweeps the sandbox path (RED: an orphaned
    `sleep`; GREEN: none). INFO: the exit pin matched a substring → a whole-line match.
    INFO: a system `/etc/zshenv` reaching a brew would make the suite run the real one →
    a precondition stops the suite first; "a brew on PATH is used as it is" got a sandbox
    check. INFO: the perl dependency is stated (stock `/usr/bin/perl`; no third-party
    deps — CLAUDE.md's "zero dependencies" still holds in that sense).
  - `3c1f76c` — INFO: the README no longer reads as if a function or alias brew were
    bypassed; the CHANGELOG names the half-install case.
  - Every fix was shown RED first: two mutants for `3657cc3` (3 and 2 checks fail), nine
    for `b7b56e7`/`f68d114` (each caught by at least one check), and the Ctrl-C orphan.
    The "probe before PATH" mutant ran the Mac's real brew in the old `assert_exit`
    runs (module 8, `--dry-run`, read-only) before the new sandbox check existed.
- **Final re-gate of `b7b56e7`/`f68d114`/`3c1f76c`** (a reviewer and a refuter, because
  `b7b56e7` changed sensitive code): the code correct, nothing new authorised
  (`_brew_install` has one call site, behind the unchanged guards and `_ask` with default
  `n`; `exec zsh "$0" "$@"` stays at top level, where `$0` is the script; the URL and the
  script body cannot be pre-seeded), the docs match. One LOW upheld: the harness could not
  tell `return 1` from `exit 1` inside `_brew_install`, so turning the returns into exits
  (production: exit 1 instead of 69) passed 48/48 → the failure checks require the line
  the harness prints after the function returned, and a static pin forbids an `exit`
  command in the function's body (a first regex also matched "(exit status …)" in a
  message; narrowed to `exit` as a command). RED: the `exit 1` mutant fails 5 checks, an
  `&& exit 1` mutant 3; GREEN 49.
- The suite: `tests/test_exit_codes.zsh` 32 → 49 checks; `make test` 311 green; the smoke
  of module 1 in `--dry-run` under launchd's environment (`env -i`, launchd's PATH, stdin
  `/dev/null`) ran the real brew read-only: rc 0 in 7 s, "Running modules: 1", DRY-RUN, one
  session log, no process left.

## Links
[[STATE]] · [[plans/debt-cleanup-pre-dashboard]] ·
[[sessions/2026-09-26-gitignore-and-launchd-plan]] ·
[[sessions/2026-09-24-debt-inventory-pre-dashboard]]
