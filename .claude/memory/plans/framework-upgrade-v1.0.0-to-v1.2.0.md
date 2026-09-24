---
type: plan
prompt: framework-upgrade-v1.0.0-to-v1.2.0
branch: chore/framework-upgrade-v1.0.0-to-v1.2.0
created: 2026-09-24
status: in-progress
tags: [plan, framework, upgrade, process, language]
---
# Plan: upgrade the grafted claude-code-framework v1.0.0 → v1.2.0

## Goal
Bring brew-manager's PROCESS layer (CLAUDE.md, docs/, commands/, scripts/, settings,
Makefile, the memory guide READMEs and the LEARNINGS format) from framework v1.0.0 to
v1.2.0 — v1.1.0 translates the whole method to English and adds rule 9 (language),
v1.2.0 adds `model`/`turns` to session notes and the `Origin: [[<session note>]]` IMP
format — while keeping the project memory's content untouched. Third upgrade of the
graft (v0.2.0→v0.5.1, v0.5.1→v1.0.0, v1.0.0→v1.2.0); a jump decided mid-way (a v1.1.0
assessment was superseded before any file was touched). Process-only: no product
change, no tag.

## Decisions (user, FASE 1 approval, 2026-09-24)
- D1 (O2): an IT↔EN map of the memory section titles cited by name, in the technical
  rules of CLAUDE.md, plus a ban on translating memory headings outside a dedicated
  task. DoD: run the /checkpoint "critical debt" check on the current STATE.md through
  the map.
- D2 (1): faithful translation in the rebuilds, then ONE separate Level-1 commit for the
  stale claims. `_module_14` collision → STATE, priority debt and M4 prerequisite;
  `lib/selection.sh` among the sensitive components → debt/IMP; product README out of
  scope.
- D3: memory touches limited to A1–A5 (see Invariant). D4: LEARNINGS header template
  lines in English. D5: components/plans guide READMEs brought over. D6: framework IMP
  numbers pruned (IMP-009 in harvest mandatory; IMP-043 in docs/01; IMP-044 in
  sessions/README); IMP-032 in test-hooks-install kept. D7: the "plan block" (hybrid
  regime of the framework repo) pruned from sessions/README.
- D8: Makefile product section in English, Level 1 only; targets and recipes
  byte-identical (`make -n`). D9: pin `version: 1.2.0`, `commit: 7d6a9f7`, `grafted`
  unchanged, comment in English. D10: `.vault-token`, `vault-keys.json`, `*.iml` out of
  scope; `*.log` omitted on purpose at the graft (decision, not debt).
- D11: docs/04 branching note marker taken verbatim (EN). D12: the framework is read
  ONLY via its tag — `git -C "$FW" show v1.2.0:<path>`, never a bare `git show v1.2.0:`
  (brew has its own v1.2.0 tag); no checkout/write in the framework repo. D13: commits in
  English from the first upgrade commit; STATE per-entry language policy; the
  prospective memory boundary as a second bullet of the language slot. D14: docs/05
  delimiters accepted as-is, IMP for the framework.

## Execution constraints
- Branch in the MAIN worktree (Step 4 fails, or runs the old script, from a linked one).
- Hybrid files: take v1.2.0, re-apply every inventoried customisation with its language
  level (1 translated / 2 identical value / 3 byte-identical string); every item's grep
  is part of the DoD.
- `hooks-install.sh` + `test-hooks-install.sh` in the SAME commit; keep mode 100755.
- Separate commits: M1 (memory guide READMEs), M2 (LEARNINGS format), the Level-1 stale
  claims, the pin — distinct from the METHOD/HYBRID commits.
- Step 4: `make hooks-install` (2 WARNING + 2 `.bak` expected), then real proof:
  gitleaks blocks a fake secret, commitlint rejects a non-conventional message. A
  rollback after Step 4 needs `FORCE_OVERWRITE=1`.
- Security gate not applicable (no sensitive component touched): write the verdict.

## Tasks
- [x] 1. Pure METHOD files → v1.2.0 (docs/05, integrate, retro, security-review, sos, scripts/README.md, commitlint.config.cjs) — commit: e64be5b
- [x] 2. `hooks-install.sh` (3-way, brew formatting block in EN) + `test-hooks-install.sh`, same commit, mode 100755, `make test-scripts` green — commit: c9f1a8b
- [ ] 3. `settings.json` (3-way, hook fallback pruned) + `reset-task.sh` (3-way, `main dev`) — commit: —
- [ ] 4. Makefile (process part = v1.2.0, product section Level 1 in EN, recipes identical) — commit: —
- [ ] 5. CLAUDE.md rebuild (rule 9, language slot + prospective bullet, D1 title map) + the checkpoint-step-3 functional check — commit: —
- [ ] 6. docs/00, 01, 02 rebuild — commit: —
- [ ] 7. docs/03, 04 rebuild (public contract preserved) — commit: —
- [ ] 8. docs/06 rebuild — commit: —
- [ ] 9. commands: checkpoint, harvest-framework, lint-memory, new-component rebuild — commit: —
- [ ] 10. M1 `docs(memory)`: sessions/decisions/components/plans guide READMEs → v1.2.0 — commit: —
- [ ] 11. M2 `docs(memory)`: LEARNINGS header template lines + IMP format comment → v1.2.0 — commit: —
- [ ] 12. Level-1 correction of the stale claims (CLAUDE.md, new-component, docs/02, docs/04) — commit: —
- [ ] 13. Provenance pin → v1.2.0 (Step 6) — commit: —

Closing (no `[task N/T]`): Step 4 hooks + functional proof · Step 5 verification (DoD
greps, IMP-043 old/new title grep, invariant V1–V7, `make check`, `make test`,
`make test-scripts`) · /retro · /checkpoint · print /integrate and stop.

## Invariant (memory)
Allowed in the upgrade commits: A1 sessions/README.md = v1.2.0 minus " (IMP-044)"
(l.53) minus the plan block (l.99-118); A2 decisions/README.md = v1.2.0 + ADR slot
answered in English; A3 components/ and plans/ README.md = v1.2.0; A4 LEARNINGS.md:
header template lines (not brew's l.14-19) + the IMP format comment; A5 this plan.
Everything else untouched; no backfill of `model`/`turns`. Verified end-to-end before
writing (positive run all ok; 8 negative branches all caught).

## Resumption notes
- Session scratchpad (same session only):
  `/private/tmp/claude-501/-Users-seco-Projects-brew-manager/a22fe5fb-b1da-4da4-b9bc-c7873b0c7fa5/scratchpad/`
  — `verify-invariant.sh` (V1–V7), `stage/` (M1/M2 files), `sections/` (the FASE 1
  inventory with the per-item greps).
- Pre-upgrade restore point: `e7c3a56`.

## Links
[[STATE]] · [[LEARNINGS]] · [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]]
