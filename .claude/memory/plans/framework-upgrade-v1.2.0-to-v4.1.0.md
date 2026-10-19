---
type: plan
prompt: framework-upgrade-v1.2.0-to-v4.1.0
branch: chore/framework-upgrade-v1.2.0-to-v4.1.0
created: 2026-10-19
status: in-progress
tags: [plan, framework, upgrade, process, security-gate]
---
# Plan: upgrade the grafted claude-code-framework v1.2.0 → v4.1.0

## Goal
Bring brew-manager's process layer from framework v1.2.0 to v4.1.0 in one jump, by v4.1.0's
SETUP.md (*Upgrading the framework on an already-grafted project*): the core rules out of
CLAUDE.md into `.claude/rules/`, the answers the method reads in CLAUDE.md, the commands in
the `fw:` namespace, the boundary (settings, guard, STATE injection, hooks), the memory's
titles and labels in the method's form — with no product change, the project memory's
content untouched, and no tag. The user's decisions U1–U24:
[[decisions/2026-10-19-framework-upgrade-v4.1.0]].

## Opening (before the plan)
- Step 1: branch from `main` at the restore point
  `8a7e6a207039ab897f2338cbd70b1ed6b8982f17`; hooks photographed into
  `T/hooks-before` (pre-commit, commit-msg); T =
  `/Users/seco/Projects/_upgrade-scratch/brew-manager`, kept until the merge.
- Step 0: the pin's `version: v1.2.0` — commit: 09b7250; preflight again: 0 FAIL, 1 CHECK
  (`grafted`, closed at task 10 by U1).

## Tasks
- [x] 1. Commands to the `fw:` namespace: the eight renames (3-way where customised, v4.1.0's copy where =v1.2.0), `fw/plan.md`, the old files removed; U12, U13, U14 — commit: 2231311
- [x] 2. The core rules (`fw-core.md`, `fw-boundary.md`, `fw-code-quality.md` with U15's globs) and CLAUDE.md rebuilt from v4.1.0: the nine answers carried, the project's technical rules kept, the map removed, the Security gate, Releases and MINOR-examples lines (U2, U5, U14), IMP-002 (U7), anchors (U17) — commit: dbbff76
- [x] 3. docs 00–06 brought over from v4.1.0 (their answers carried by task 2) — commit: 679a33b
- [x] 4. `docs(memory)`: the memory's titles (6 in STATE, 4 in LEARNINGS) and 56 field-label lines to v4.1.0's form, one edit per line — commit: 116adcb
- [x] 5. `docs(memory)`: the memory templates (components, plans, sessions READMEs; the LEARNINGS header and format comment, U16) — commit: 2129ec9
- [ ] 6. The boundary: `scripts/agent-git-guard.mjs`, `scripts/state-inject.sh`, `.claude/settings.json` (3-way in T, checked as JSON, written at once: U6, U21) and their two self-tests — commit: —
- [ ] 7. The Makefile (`PROTECTED_BRANCHES = main dev` carried first, U10), then `reset-task.sh`, `repo-snapshot.sh`, `check-prerequisites.sh`, their self-tests and `scripts/README.md` from v4.1.0; modes 100755 — commit: —
- [ ] 8. `scripts/hooks-install.sh` (3-way, mode 100755) with `scripts/test-hooks-install.sh` in the same commit; `make test-scripts` — commit: —
- [ ] 9. `.gitignore` (`.claude/worktrees/` only, U11) and `.gitattributes` — commit: —
- [ ] 10. The pin to v4.1.0 (`chore: upgrade the framework from v1.2.0 to v4.1.0`; `grafted: 2026-07-12`, U1); then `/fw:security-review` by an independent, delegated reviewer on the branch's diff, this commit the reviewed tip — commit: —
- [ ] 11. `/fw:retro` (the IMPs of the decision record) and `/fw:checkpoint` (the session note; STATE with the framework version and no more; TREE; INDEX); this plan completed — commit: —

Between tasks 9 and 10, with no commit: Step 4 (`make hooks-install` from the main worktree,
the `.bak` files against the photograph, gitleaks and commitlint proofs, the marker grep,
`make test-scripts`) and Step 5 (`invariant`, `post`, `make check`, `make test`, the
titles' functional check) → FERMATA 2. After task 11: `/fw:integrate` → FERMATA 3 at its
block 0, no tag; merge and push are the user's.

## Resumption notes
- The memory's closed list during the upgrade: the templates, the declared title/label
  rename, this plan, the decision record, the session note, and STATE/TREE/INDEX at the
  checkpoint. IMP entries are written only at task 11, after `invariant`.
- The framework is read only by tag: `git -C "${FW:?}" show v4.1.0:<path> > "$T/…"`, FW =
  `/Users/seco/Projects/claude-code-framework-upstream.git` (brew has its own v1.2.0 tag).
- From task 6 on, delegated agents are read-only on git, and file-tool edits to
  `settings.json`, the guard and `state-inject.sh` ask the user.
- STATE.md is not condensed by the upgrade (the user). **The first deliverable after the
  merge** is the first `/fw:checkpoint`, which condenses it and records: (a) task 2's
  acceptance run on the user's Mac on 2026-10-10 (preview with no change, restore confirmed,
  Homebrew 7.0.8 → 7.0.9 stable, a second run without developer mode turning on again);
  (b) two defects — the summary prints "Installed casks 0 / formulae 0 / Available updates 0"
  when only module 1 runs (unmeasured data shown as true → task 7), the restore's
  confirmation box overflows (the "From: ..." line past the frame → task 4 or 5); (c) STATE's
  stale frontmatter; (d) #30 closed by merge 8a7e6a2; (e) the 2.0.0 plan's pointers to
  docs/03, 04, 00 and `new-component.md` → CLAUDE.md's answers and `/fw:new-component`;
  (f) D1's decision note marked superseded; (g) the OPEN IMPs covered upstream, for the
  retro; (h) task 8's gate status (a product asserting a security property); (i) the language
  of condensed entries (U4); (j) `decisions/2026-07-12-trunk-based-su-main.md:20` (the
  protected list now in the Makefile). Before it, the user decides the anchors' form in code
  and tests (U23). Restart Claude Code after the merge.

## Links
[[decisions/2026-10-19-framework-upgrade-v4.1.0]] · [[plans/v2-personal-tool]] · [[STATE]]
