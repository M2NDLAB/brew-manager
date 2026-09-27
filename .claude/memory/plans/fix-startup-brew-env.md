---
type: plan
prompt: fix-startup-brew-env
branch: fix/startup-brew-env
created: 2026-09-27
status: completed
tags: [plan, startup, launchd, contract, security]
---
# Plan: branch 4 — Homebrew's PATH under launchd, a new exit code, a safe installer

## Goal
`brew_manager.sh` finds Homebrew with the minimal environment of launchd and of a GUI app
(STATE #23, CONFIRMED under a real launchd job on 2026-09-26); when Homebrew is really
missing it exits with a NEW dedicated code instead of 0; the built-in installer honours
`--dry-run` and never runs — nor even prompts — without a terminal. Then the fix is proved
end-to-end in a sandbox and under a REAL launchd job. Decisions:
[[decisions/2026-09-25-debt-cleanup-pre-dashboard]] (the new code is MINOR → v1.5.0).

## Design (decided before the code)
- **PATH bootstrap**: only when `brew` is not on PATH, probe the standard prefixes in a
  named constant (`/opt/homebrew/bin/brew` Apple Silicon, `/usr/local/bin/brew` Intel);
  the first regular executable file wins and its prefix's `bin` and `sbin` are prepended
  to PATH (exported, so the `script(1)` child inherits it). No `eval "$(brew shellenv)"`:
  nothing in the tool reads HOMEBREW_PREFIX & co. (grep: none), brew computes them itself,
  and startup never executes a binary's output. A PATH that already has brew is respected.
- **Exit code 69** = sysexits.h `EX_UNAVAILABLE` ("A service is unavailable. This can occur
  if a support program or file does not exist."): Homebrew unavailable — not on PATH nor
  at the standard prefixes; the installer not offered (`--dry-run`, no terminal), declined,
  or failed. Outside 1–31 (raw signal numbers from macOS `script(1)`) and 126–255 (shell
  conventions: not executable / not found / signal deaths). Discarded: 78 `EX_CONFIG`
  (after the bootstrap, a PATH gap is no longer an error), 72 `EX_OSFILE` (OS files), 1
  (already overloaded; "selection resolves to empty" in the contract). The old
  "install failed" exit 1 moves to 69 too (same precondition; it was never pinned).
- **Installer**: `--dry-run` → never offered, exit 69. No terminal (`NON_INTERACTIVE`, or
  stdout not a TTY, or inside the recorded child) → no prompt at all, exit 69. With a
  terminal → `_ask` with default `n`, so `--yes` never installs Homebrew.
- **Tests**: e2e in `tests/test_exit_codes.zsh`, minimal environment (`env -i`, launchd's
  PATH), the farm running a copy of `brew_manager.sh` whose candidate constant points into
  the sandbox (no test hook in production code; the substitution is asserted), tripwires
  on a mock `curl` and on the mock `brew`, the TTY case through `script(1)`.

## Tasks
- [x] 1. PATH bootstrap (candidate constant + probe) + e2e: minimal env with brew only at a
  probed prefix → the run starts, reaches the mock brew through `script(1)`, exits 0.
  — commit: `c277e20` (RED shown with the probe disabled: 2 checks fail)
- [x] 2. Installer rework + exit code 69 on every "Homebrew unavailable" path + e2e: no
  brew and no terminal → 69, no prompt, no curl; `--dry-run` → 69, no prompt, no curl; a
  terminal (via `script(1)`) and EOF → the prompt is shown, declined, 69, no curl.
  — commit: this task's commit (RED shown on the task-1 code: 6 checks fail)
- [x] 3. Contract and docs: docs/04 (code 69 in the exit-code contract), README (exit
  status, requirements/scheduling, the dry-run claim), SECURITY.md (the installer).
  — commit: this task's commit
- [x] 4. CHANGELOG `[Unreleased]`: the honest entry (agents never ran brew under launchd
  while looking successful). — commit: this task's commit
- [x] 5. Security gate (docs/03, adversarial — `brew_manager.sh`): /security-review of the
  branch diff; fixes. — commits: gate `b34e719` `1c6105d` `45c5fd2`; re-gate `3657cc3`
  `1317307` `b7b56e7` `f68d114` `3c1f76c`; final re-gate `ec6da37`; recorded `e14ad02`
  (no CRITICAL/HIGH; the MEDIUM on #21 resolves with the removal of bk and log — see
  [[decisions/2026-09-27-personal-terminal-tool]])
- [-] 6. ~~Re-verification under a REAL launchd job with the same test plist~~ —
  **DROPPED by the user on 2026-09-27** (scope change: the scheduled agents it verified
  will be removed; blocks A and B were not run). The found path is covered by the e2e
  suite in launchd's environment and by the smoke of module 1 with the real brew.
- [x] 7. /checkpoint and the printed /integrate. — commit: the checkpoint commit

## Resumption notes
- Session note: [[sessions/2026-09-26-startup-brew-env]] (the verification before the fix,
  the fix, the gate and the re-gate rounds).
- Task 5 grew past its single commit: the gate and two re-gate rounds (IMP-004) each fixed
  what their refuters upheld. The install step is now `_brew_install`, extracted and run
  alone by the suite — no test ever answers the installer prompt.
- Task 6 was dropped before any block ran; the approved plist
  `logs/com.m2ndlab.verify-n1.plist` (sha256 `84e60212…66ff29`, git-ignored) stays unused.

## Links
[[STATE]] · [[plans/debt-cleanup-pre-dashboard]] · [[core-brew-manager]]
