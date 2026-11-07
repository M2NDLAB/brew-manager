---
type: plan
prompt: post-upgrade-checkpoint
branch: chore/post-upgrade-checkpoint
created: 2026-11-07
status: in-progress
tags: [plan, memory, process, lint, attribution]
---
# Plan: the first checkpoint after the framework upgrade to v4.1.0

## Goal
STATE.md condensed within the 8,000 characters the SessionStart hook shows, every open
entry kept under its number and every closed one moved to a durable note; the framework
architect's decisions A–D of 2026-11-07 applied ([[decisions/2026-11-07-framework-architect-decisions]]);
the claims the upgrade made stale marked; the branch at `/fw:integrate`'s block 0, no tag.

## Tasks
- [x] 1. `make lint` runs `make check`'s `zsh -n` on the same files (decision A); CLAUDE.md's
  two lint clauses; [[2026-07-12-shellcheck-advisory]] superseded; INDEX's line; the
  CHANGELOG `[Unreleased]` line. Verify: `make lint` = `make check`, green; `make test` 333
  — commit: `e9c628f`
- [ ] 2. `.claude/settings.json` in one write, parsed as JSON before it (U21, IMP-034):
  `"attribution": {"sessionUrl": false}` added, `Bash(shellcheck:*)` dropped, nothing else
  (decision B; F6, F7); the technical rule **Commit attribution** in CLAUDE.md, the user's
  words. Verify: the parsed diff is those two changes; `make test-scripts` (the wiring)
  — commit: —
- [ ] 3. The answer **Error format** narrowed to what the code does — text only (U18 d); the
  behaviour stays with tasks 4 and 7 of [[plans/v2-personal-tool]]. Verify: the first
  commit after task 2 carries `Co-Authored-By` and no `Claude-Session:` — commit: —
- [ ] 4. LEARNINGS: IMP-033's and IMP-047's docs/04 quotes in the words docs/04 holds
  (Level 1, found by the 2026-11-07 harvest); IMP-050 (U2), the user's text; nothing marked
  for the harvest (docs/06 prescribes nothing); INDEX's LEARNINGS line — commit: —
- [ ] 5. The claims the upgrade made stale (STATE #37's list): a superseded line in
  [[2026-07-12-componenti-sensibili]] (:38-45, U2), [[2026-09-24-language-rule-prospective]]
  (D1) and [[2026-07-12-trunk-based-su-main]] (:20); the 2.0.0 plan's targets in docs/0N and
  `new-component.md`, "one lens", the command names, task 8's gate; INDEX — commit: —
- [ ] 6. Today's session note with appendix A — STATE's *Caution & open issues* at
  `0b127a9`, verbatim — and appendix B — its *Decisions made* and *Documentation debt*,
  verbatim —, plus the entry-by-entry comparison written BEFORE the rewrite. Verify: each
  appendix byte-identical to `git show 0b127a9:.claude/memory/STATE.md`'s lines — commit: —
- [ ] 7. STATE.md rewritten within 8,000 characters (`scripts/state-inject.sh`): the open
  entries under their numbers, #30 and #34–#37 closed with their declarations, #38–#41 new
  (the two defects of task 2's acceptance run, the working folder, the upstream duplicates),
  the status and Active branches reconciled with git (`0b127a9`, no tag). Verify: the
  measurement's three conditions; independent read-only verifiers against the comparison
  — commit: —
- [ ] 8. After `/fw:security-review` and `/fw:retro`: the checkpoint — the session note's gate
  line (the reviewed tip), STATE's status line, INDEX's new notes, this plan completed
  — commit: —

## Resumption notes
- The order is the user's constraint: the archive (task 6) is committed before STATE loses
  any text (task 7). The gate runs on task 7's tip, so the reviewer reads the closures'
  claims (#34–#36) too; task 8 touches only `.claude/memory/`.
- After task 8: `/fw:integrate` up to block 0 — the gate line and the base checked, the bump
  computed (no tag: the technical rule **Releases**) — then STOP for the user.

## Links
[[STATE]] · [[decisions/2026-11-07-framework-architect-decisions]] ·
[[sessions/2026-10-19-framework-upgrade-v1.2.0-to-v4.1.0]] · [[plans/v2-personal-tool]]
