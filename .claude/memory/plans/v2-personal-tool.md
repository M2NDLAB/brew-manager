---
type: plan
prompt: v2-personal-tool
branch: one branch per task (listed below)
created: 2026-10-07
status: in-progress
tags: [plan, v2, scope, homebrew, release]
---
# Plan: brew-manager 2.0.0, a personal terminal tool

## Goal
v2.0.0 released: bk, las, the log module and mas removed, module 10 retired; Homebrew
never left in developer mode; the remaining modules correct on Homebrew 6.0–7.0.x; no wait
at the end of a session; strict flag values; truthful module outcomes; the README true.

> A programme: each task is a BRANCH with its own end-of-deliverable cycle (the gate where
> marked → /retro → /checkpoint → a printed /integrate → stop until the user's go). A heavy
> branch gets its own task plan. Decisions: [[decisions/2026-10-07-v2-plan]] (D1–D11 and
> the user's precisions). Evidence, with file:line at `37b8db5`:
> [[sessions/2026-10-07-replan-v2-assessment]]. Each branch adds its own CHANGELOG
> `[Unreleased]` line and fixes the line numbers of the STATE entries it touches.
> The gate (D11, IMP-030): one lens on paths that delete, install, modify Homebrew's
> configuration or decide what runs; a refuter only where a change widens what such a path
> authorises; no multi-hour workflows.

## Tasks
- [ ] 1. `chore/replan-v2` — memory and process only; no gate, no tag. Tasks:
  - [ ] 1.1 this plan, the decision record, the assessment note — commit: —
  - [ ] 1.2 the v1.5.0 reconciliation (STATE front matter, header, progress, decisions,
    branches; INDEX; the old plan's task 16; the release note's outcome) and the triage
    BY DECISION (#17 and #28 accepted, 4b-3, the Dashboard/GUI items, roadmap-v2 and the
    pre-Dashboard plan superseded); module-bound entries pointed at B3; new entries with
    their branch — commit: —
  - [ ] 1.3 IMP-030 applied: the path-based gate (CLAUDE.md rule 8 and the sensitive
    paragraph, docs/03, docs/00, the 2026-07-12 decision) — commit: —
  - [ ] 1.4 IMP-031 applied: the Homebrew-configuration rule in CLAUDE.md — commit: —
  - [ ] 1.5 /checkpoint and the printed /integrate — commit: —
- [ ] 2. `fix/homebrew-developer-mode` — module 1 never leaves Homebrew in developer mode;
  heavy enough for its own task plan; gate: one lens on the restore path. (a) Remove
  `brew ruby --version` (mod_01:32, a developer command: always blank, and it turns
  developer mode on, also under `--dry-run`); read the Ruby version read-only (e.g. the
  "Homebrew Ruby:" line of `brew config`); fix the "Last DB update" label (mod_01:33).
  (b) Prevention: a test that fails when a Homebrew developer command appears in the code
  (the list from the installed brew — its `dev-cmd/` commands or `brew developer --help` —
  pinned with its source and date). (c) Detection, read-only: module 1 reports developer
  mode as a problem when on, whatever the cause. (d) Restore: when on, module 1 offers
  `brew developer off` and `brew update` back to the latest stable release — a preview
  under `--dry-run`, a confirmation, done under `--yes` (IMP-031); `MODULE_RISK[1]` and
  `MODULE_DRYRUN[1]` re-decided honestly. Every command and its output verified on the
  installed brew BEFORE use. After the merge: the user runs module 1 on this Mac
  (developer mode on today); the manual fallback commands are printed with their expected
  outcome. Then every later branch is built and smoked on Homebrew 7.0.x. — commit: —
- [ ] 3. `feat/remove-special-modules` — MAJOR, own task plan; gate: one lens "selection
  still fails safe" (the exposure only shrinks). Remove bk, las, log, mas and module 10:
  code, registries, resolver, dispatch, the TOOLS menu, the dead `_selection_is_valid`;
  tests (the `>= 18` guards, scans that fail on a missing file, rejection checks for every
  removed name in every position, an e2e exit 2 with the D5 hint); `_KNOWN_UNGATED=(1)` with
  `[1]=0` until task 4 if module 1 still writes `/tmp` under `--dry-run`. Docs: README
  (special modules, module 10; "Upgrading from 1.x": remove agents with `las` while on
  1.5.0 first, the `launchctl bootout` block as the fallback), SECURITY.md, docs/04 (names
  and 10 removed and reserved; the plist item deleted), docs/03, docs/00, CLAUDE.md,
  new-component.md, `.gitignore` comments (entries kept), mod_05:69 wording (D4). Closes,
  after a grep proves the code gone: #6, #6b, #12, #13, #15, #16, #18, #21 (the bk/log
  half), #22, #24, #27, #29, #31-F1, R1, R3, R5, R6, R12, NEW-d. — commit: —
- [ ] 4. `fix/session-log` — D1 and D2; gate: one lens (the only new deletion is the
  parent's own mktemp dir; the INT trap). The `_handle_log` prompt goes; `LOG_FILE` once,
  unique; a per-run dir for modules 0, 1 and 2; #28's hardening (the child trusts
  RECORDING only with the LOG_FILE handoff). Docs: README Session logging and the
  unattended/exit lines, SECURITY.md footprint, CLAUDE.md (`open(1)` goes; the smoke rule),
  docs/02 (the "session log" sentence), docs/04 (130). Closes #11, #25 (11-bis), #21's
  residue (N-HANG-r), #32 (NEW-L1), R2b, R7, then #3 and #14 (`MODULE_DRYRUN[1]` decided
  honestly). — commit: —
- [ ] 5. `fix/homebrew-6-7-compat` — on 7.0.x; own task plan; gate: one lens on D7/D8.
  D7 and D8 ONLY after verifying on the installed brew that `HOMEBREW_NO_ASK` and
  `--no-quit` exist and do what is needed (otherwise STOP and propose the alternative);
  N2/#26 fixed in place (`printf '%s'` at mod_03:82); deprecated/disabled read from JSON
  per item (mod_12 never matches, mod_11 matches loosely); the index age reads
  `api/internal`; tap trust made visible (stop hiding mod_04's stderr; trust state in
  module 1); the "4.x" texts and the D9 constraint (README, CLAUDE.md Stack line, modules
  1 and 2); NEW-a (module 2's tap age); module 0's three #3b sites; F9 (module 3 shows the
  version in its description column — a wrong value today, fixed locally without a shared
  JSON). User checks: a Tier-1 `go --dry-run` smoke; Tier-2 one real upgrade and one
  cleanup. Closes #26, #31. — commit: —
- [ ] 6. `fix/cli-flag-values` — #9 and #10's residue; gate: one lens (it decides whether
  modules 4 and 5 act under `--yes`). docs/04: an invalid flag value → 2, a non-TTY run
  without a selection → 1, the `--upgrade` semantics, the exit order; README. Closes #9,
  #10's residue. — commit: —
- [ ] 7. `fix/module-outcomes` — 4b-1 + a reduced 4b-2 + #4 + #33 (NEW-b: the stale
  "noise"/"BM-18" comments and the docs/04 clause) + the raw output on failure into the
  log + README :124; gate: one lens (`test_guardrails` as the consent proof). Closes #4,
  #4b, #33. — commit: —
- [ ] 8. `chore/release-v2.0.0` — the README/SECURITY residue (R4, R9–R11, R13, M3, the
  Intel wording); VERSION 2.0.0; CHANGELOG `[2.0.0]` from the branches' lines; version-check
  in a clone; no gate; the user tags. — commit: —

## Not planned (reconsider only on a concrete need)
- F10: one shared `brew info --json=v2` per run (the Dashboard's foundation). Its only use
  for the personal tool is speed (modules 11 and 12 spend about 95 s per run on per-item
  `brew info`).
- #3b's remaining echo sites (after 2.0.0, D10); module 6's ~69 `brew uses` calls (speed);
  BM-15/16/18 of the old roadmap; T14 (the harvest map, on hold).

## Resumption notes
- Supersedes [[plans/debt-cleanup-pre-dashboard]] (tasks 5–15) and [[plans/roadmap-v2]].

## Links
[[STATE]] · [[decisions/2026-10-07-v2-plan]] · [[decisions/2026-09-27-personal-terminal-tool]] ·
[[sessions/2026-10-07-replan-v2-assessment]]
