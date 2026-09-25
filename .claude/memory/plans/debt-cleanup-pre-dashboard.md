---
type: plan
prompt: debt-cleanup-pre-dashboard
branch: one branch per task (listed below)
created: 2026-09-25
status: in-progress
tags: [plan, debt, security, dashboard]
---
# Plan: close the open debts before the Dashboard improvement

## Goal
Every (a) item of [[sessions/2026-09-24-debt-inventory-pre-dashboard]] closed,
integrated and released as v1.5.0; the (b) items handed to the improvement's first
task; the (c) items tracked in STATE with their triggers.

> A programme, not a single-prompt plan: each task is a BRANCH and a deliverable with
> its own end-of-deliverable cycle (gate where marked → /retro → /checkpoint → printed
> /integrate → stop until the user's go). Sixteen entries exceed docs/01's healthy range
> for one prompt precisely because each entry is a whole prompt; a heavy branch gets its
> own task plan. The decisions it rests on: [[decisions/2026-09-25-debt-cleanup-pre-dashboard]].
> Item ids (#15, N-HANG, …) refer to the inventory note.

## Tasks
- [ ] 1. `chore/imp-022-sensitive-selection` — IMP-022 (`lib/selection.sh` into every
  sensitive list) + #7 (the one-off gitleaks scan of the whole history, recorded);
  persists the inventory, this plan and the decision; Level-1 memory corrections.
  Gate: no (author-verifies, grep DoD with counter-proof). — commit: —
- [ ] 2. `chore/apply-project-imps` — IMP-003, IMP-004, IMP-007, IMP-002, one commit
  each; IMP-002/004 marked `Destination: framework`; IMP-005 → Deferred. Gate: no.
  — commit: —
- [ ] 3. `chore/gitignore-d10` — #20 (`.vault-token`, `vault-keys.json`, `*.iml`).
  Gate: no. — commit: —
- [ ] 4. `fix/startup-brew-env` — N1 + 4b-0: PATH bootstrap for launchd/GUI starts; the
  installer honours `--dry-run` and never starts without a terminal (`_ask`); a NEW exit
  code for the failed environment precondition, added to the docs/04 contract (MINOR);
  the README exit-status paragraph; the real-launchd check with the user. Gate: yes.
  — commit: —
- [ ] 5. `refactor/module-fn-names` — #18: `_module_bk`/`_module_las`/`_module_mas`, a
  generic dispatch, the `las`/`mas` section headers, the wiring guard test; README
  "Adding a new module", CLAUDE.md, new-component.md. Gate: yes (a light adversarial
  lens on the dispatch). — commit: —
- [ ] 6. `fix/headless-prompts` — N-HANG + N-bk-NI: `_handle_log` and the bk/log menus
  through `_read_choice`; the watchdog e2e harness. Gate: yes (mod_bk). — commit: —
- [ ] 7. `fix/cli-flag-values` — #9 residual: exact values at the edge, an ONLY_SET
  marker, empty `--only=` → 1, empty `--skip=` stays valid, non-TTY without a selection
  → 1, the `_ask` display. Gate: yes. — commit: —
- [ ] 8. `fix/mod03-json` — N2: `printf '%s'`, one python pass, a reported parse
  failure. Gate: no. — commit: —
- [ ] 9. `fix/bk-dryrun-check` — #15 (static check in dry-run; in wet mode a
  confirmation naming the Brewfile execution) + N-bk-1 + the bk half of #14. Gate: yes.
  — commit: —
- [ ] 10. `fix/las-dryrun-clean` — #16 (+ `_ask_danger` on [c] in wet mode) + the las
  half of #14; closes #3 and #14. Gate: yes. — commit: —
- [ ] 11. `fix/bk-agent-trust` — #6b + the bk half of #13 + 3b-bk; introduces
  `lib/agents.sh` (label predicate + shared `schedule=` parser, sensitive, added to the
  lists). Gate: yes, adversarial. — commit: —
- [ ] 12. `fix/las-agent-trust` — #12 + the las half of #13 + N-las-recreate; migrates
  las to `lib/agents.sh`. Gate: yes, adversarial. — commit: —
- [ ] 13. `fix/per-run-paths` — #11 + 11-bis: a per-run tmp dir, LOG_FILE computed
  once. Gate: yes. — commit: —
- [ ] 14. `chore/memory-harvest-map` — (i) the brew→framework IMP map. ON HOLD until
  the framework numbers AND the format arrive from the other chat. Gate: no.
  — commit: —
- [ ] 15. `docs/readme-truth` — the README residue (R2, R2b, R3, R4, R5, R10, R11–R13,
  M3), SECURITY.md, the "managed with Claude Code" decision; a claim-by-claim final
  check. Gate: no. — commit: —
- [ ] 16. `chore/release-v1.5.0` — VERSION + CHANGELOG `[1.5.0]` with Known limitations
  (#4b until the improvement, #17 and #3b with their conditions, #6); the tag is the
  user's. — commit: —

## Resumption notes
- Branch names of tasks 4–16 are provisional; each branch's checkpoint records the real
  one and the merge sha here.

## Links
[[STATE]] · [[sessions/2026-09-24-debt-inventory-pre-dashboard]] ·
[[decisions/2026-09-25-debt-cleanup-pre-dashboard]] · [[plans/roadmap-v2]]
