---
date: 2026-09-24
task: upgrade the grafted claude-code-framework from v1.0.0 to v1.2.0 (FASE 1 assessment + FASE 2 execution)
branch: chore/framework-upgrade-v1.0.0-to-v1.2.0
status: completed
model: 'claude-opus-5-5'
turns: 3
tags: [session, framework, upgrade, process, language, memory]
---
# Session 2026-09-24 — framework upgrade v1.0.0 → v1.2.0

The THIRD upgrade executed on brew's graft (v0.2.0→v0.5.1, v0.5.1→v1.0.0, now
v1.0.0→v1.2.0), and a jump decided mid-way: an assessment at v1.1.0 had been completed
read-only and was superseded before FASE 2 (no file touched, it does not count as an
upgrade). v1.1.0 translates the whole method to English and adds rule 9 (language);
v1.2.0 adds `model`/`turns` to session notes and the `Origin: [[<session note>]]` IMP
format. This is the first brew session note written in English and with `model`/`turns`
(nothing backfilled). Pre-upgrade restore point: `e7c3a56`. All the work, including
~40 delegated agents (FASE 1 assessment, translation-fidelity review), ran on the same
model.

## Done
- **FASE 1 — read-only assessment** (multi-agent: 7 per-group inventories, each with an
  adversarial verifier; 3 cross-cutting analyses; a completeness critic; gap fillers).
  Inventory of every brew customisation with its language level (1 prose translated /
  2 values identical / 3 strings read by code byte-identical) and a DoD grep with
  "teeth" per item. 2 of 27 agents stalled (memory invariant, title matrix): declared
  as uncovered and checked by hand. User decisions D1–D14 →
  [[plans/framework-upgrade-v1.0.0-to-v1.2.0]].
- **First check of FASE 2, before writing**: the unified memory-invariant script
  (V1–V7) run end-to-end on a throw-away clone — positive simulated upgrade all ok,
  8 negative branches all caught.
- **FASE 2 — 13 task commits** (`e64be5b` … `7e78453`, plan `f846490`):
  METHOD overwrites (docs/05, integrate, retro, security-review, sos, scripts/README,
  commitlint); `hooks-install.sh` + `test-hooks-install.sh` in one commit (mode
  100755 kept); real 3-way for settings.json and reset-task.sh (`main dev` kept);
  Makefile union (product section Level 1 in English, recipes byte-identical, hash
  `3e4b66ad3178`); rebuilds of CLAUDE.md, docs/00-04, docs/06 and the four customised
  commands; M1 (memory guide READMEs) and M2 (LEARNINGS header + IMP format) as
  `docs(memory)` commits; a separate Level-1 commit for the stale claims (`e8ae4ce`);
  the provenance pin → 1.2.0 / `7d6a9f7`.
- **Translation-fidelity review** (6 reviewers + 6 skeptics, original vs rebuilt vs
  template): no high finding; confirmed low/medium ones fixed in `3a4fe9b` (MODULE_IDS
  wording, special-module wiring list, pin comment mistranslation, a Makefile blank
  line).
- **D1**: the CLAUDE.md technical rules map the English section titles cited by the
  method to STATE/LEARNINGS' Italian headings, frozen as identifiers. Functional DoD:
  the /checkpoint "critical debt" check resolves "Caution & open issues" through the
  map on the real STATE.md (21 entries), and catches a rewrite that drops one.
- **D13**: interaction language Italian; project boundary for the existing Italian
  memory; commits in English from the first upgrade commit →
  [[decisions/2026-09-24-language-rule-prospective]].

## Verification (upgrade Steps 4–5)
- **Step 4 hooks**: first `make hooks-install` → exactly 2 WARNING and 2 `.bak`
  (byte-identical to the Italian hooks, sha `2821d239`/`986afa02`); second run clean.
  Real proof: commitlint (the installed hook) rejects a non-conventional message (rc=1)
  and accepts a conventional one; gitleaks (brew's hooks copied byte-identical into a
  throw-away clone) blocks a fake GitHub token (`leaks found: 1`, no commit created).
- **Rollback after Step 4** (edge case 4): the old v1.0.0 script does not recognise the
  English marker and stops with rc=1 — restore the hooks from `main` with
  `FORCE_OVERWRITE=1 make hooks-install` (it rewrites the `.bak`, harmless). The
  "re-run hooks-install from main" instruction of the two previous upgrade notes no
  longer suffices (→ IMP-013).
- **Marker audit**: sentinel clean; the dual grep finds only known false positives —
  4 historical memory lines, docs/04 branching note (D11, verbatim), integrate.md:17
  (runtime slot, R5), lint-memory prose/greps, rule-9 prose in CLAUDE.md. The only new
  slot ("Interaction language") never resurfaces in the grep: filled by checklist
  (→ IMP-015).
- **IMP-043 check**: 0 old Italian method titles left in method files; every English
  title cited by name exists as a heading; all 10 memory headings of the D1 map
  resolve.
- **Tests**: `make check` ok, `make test` 268 checks green (8 suites), `make
  test-scripts` PASS, `make version-check` ok. Only legitimate Italian left outside the
  memory (real memory headings, level 2/3).
- **Memory invariant**: V1–V3 green up to `3a4fe9b`; V4–V7 run on the checkpoint
  commit (see below).

## Security gate
**Not applicable.** The upgrade touches none of the six sensitive components
([[2026-07-12-componenti-sensibili]]); it touches the level-1 baseline of docs/03
(`hooks-install.sh`, `settings.json`, `reset-task.sh`). Executable delta: only the
hook-marker guard (English `MARKER` + Italian `LEGACY_MARKER`, `grep -qF` on both); the
generated hooks run the same commands; allow/deny unchanged; `PROTECTED_BRANCHES="main
dev"` preserved (main and dev refused in a sandbox). Author-verifies level, with the
functional proof above. In the two previous upgrades the gate was skipped silently
(→ IMP-017).

## Deviations from the letter of the procedure (declared)
- **Step 3**: on this translation release the 3-way merge of the hybrids conflicts on
  80–100% of each file (IT vs EN blocks): it degenerates into "take v1.2.0 and re-apply
  the customisations". Real 3-way used only where it worked (settings.json,
  hooks-install.sh, reset-task.sh, harvest-framework, Makefile union).
- **Step 5 invariant**: "empty diff on memory/" replaced by the A1–A5 allow-list
  (Exception A, framework IMP-046) and verified by content (V1–V7). `sessions/README`
  in brew was stuck at the v0.5.0 template (never brought over by the two previous
  upgrades): its 20-line lag was exactly the framework-repo "plan block", pruned again
  (D7).
- The framework is read ONLY via its tag with `-C` (D12): brew has its own `v1.2.0`
  tag, and the framework's HEAD moved during FASE 1 (a parallel user commit, IMP-048,
  touching only the framework's memory; the tag and the payload were unaffected).

## Problems encountered → cause → solution
1. FASE 1 agents reported rule 9 as "undecided, blocking" → the brief quoted only one of
   the user's language decisions → retracted in the report; lesson → IMP-021.
2. Mac sleep interrupted the reading of the FASE 1 results → none (the workflow had
   finished, the output was on disk) → read by sections, uncovered items re-checked.
3. The review found Level-1 rewrites that overstated facts (MODULE_IDS, menu rows) →
   corrections written from a partial code read → fixed in `3a4fe9b` after checking
   the code again.

## Factual doc corrections (Level 1, docs/06)
- `e8ae4ce` (+ `3a4fe9b`): tests exist (`make test`), `make check`/`make lint`, CLI
  selection in Run, registries in `lib/selection.sh`, `_about_risk`, /tmp cleanup list,
  the `_module_14` collision warning, `git show` in the docs/04 allow-list. Left out on
  purpose: the IMP-007 smoke sentence, any `mktemp` prescription (debt #11).

## Memory pointers to renamed method titles (not touched)
The memory keeps these Italian names; the method now uses the English ones:
"Comandi rapidi" → "Quick commands" · "Regole tecniche specifiche del progetto" →
"Project-specific technical rules" · "Convenzioni di codice" → "Code conventions" ·
"Verifica minima" (Regole tecniche → Test) → "Minimal verification" (Tests) ·
"Test che dimostrano" → "Tests that demonstrate (not just green tests)" ·
"Prevenzione by-convention" → "Prevention *by convention*" · "Il ponte verso il
framework" → "The bridge to the framework" · "Livello 1/2" → "LEVEL 1/2" · "Confine di
esecuzione" → "Execution boundary and blocks for the user". Live pointers fixed at this
checkpoint: TREE (legend, pin line), STATE (framework entry). IMP-002/003/005/007/009
keep the Italian names (their entries are frozen): read them through this table.

## Proposals
- IMP-012…IMP-021 (`Destination: framework`) and IMP-022 (project) in [[LEARNINGS]];
  the "classify content before rewriting" lesson is NOT registered: it is the
  framework's IMP-048.

## Follow-up
- Integration by the user (no tag: process-only). Caution #18 (`_module_14` collision)
  is a prerequisite of M4; #19 (`lib/selection.sh` sensitive, IMP-022) awaits a
  decision; README "Adding a new module" drift on a future docs branch.

## Integration (post-merge checkpoint)
- Merged by the user: `0725ae6` "chore(claude): merge
  framework-upgrade-v1.0.0-to-v1.2.0 into main" (`--no-ff`, parents `e7c3a56` +
  `9b813e7`), pushed (`main` == `origin/main` == `0725ae6`), branch deleted. No tag
  (process-only upgrade). Framework v1.2.0 is active on main.
- Post-merge check on main: the public contract of docs/04 passes its inventory greps
  (C04-3: flags 2/2, frozen ids 6/6, references 5/5, exit codes 0/1/2, no "tooling"
  bullet), with teeth against the v1.2.0 template, and it matches the code (the seven
  flags of the parser, exit codes pinned by `tests/test_exit_codes.zsh`).
- The installed git hooks (English marker, from the upgrade branch) are the ones main's
  `hooks-install.sh` now generates: no rollback needed. `.git/hooks/*.bak` keep the old
  Italian hooks (untracked; the user may delete them).
- The integration is not counted in `turns` (sessions/README).

## Links
[[STATE]] · [[LEARNINGS]] · [[plans/framework-upgrade-v1.0.0-to-v1.2.0]] ·
[[decisions/2026-09-24-language-rule-prospective]] ·
[[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]] ·
[[sessions/2026-07-17-framework-upgrade-v0.2-to-v0.5.1]]
