---
date: 2026-09-26
task: branch 3 of the pre-dashboard debt cleanup — verify LEARNINGS, hand IMP-002's widening to the improvement, the .gitignore patterns, the real-launchd verification plan for branch 4
branch: chore/gitignore-d10
status: completed
model: 'claude-opus-5-5'
turns: 1
tags: [session, debt, gitignore, launchd, memory]
---
# Session 2026-09-26 — debt cleanup, branch 3: .gitignore and the launchd verification plan

Branch 2 was integrated by the user (merge `9e4f2b4`). Before branch 3 the user asked for
two things, then branch 3 itself, and — before branch 4 (N1 + 4b-0) may start — the plan
of the verification under a REAL launchd job. Work started late on 2026-09-25 and was
committed after midnight.

## Done
- **LEARNINGS after branch 2's reorganisation — verified** (a script over the file at
  `73bc5ee` and `9e4f2b4`): IMP-001…IMP-025 all present, each exactly once; every
  status coherent with its section (18 OPEN, 6 Applied with "applied on" titles, IMP-005
  in Deferred); the body and title of every moved entry contained verbatim in the new
  one; 20 `Destination: framework` markers where expected (the 15 harvested + IMP-002,
  004, 023, 024, 025). Nothing to stop for.
- **IMP-002 not widened now** (user decision): "extend IMP-002 to the output surfaces when
  the schema is defined" is recorded as an item of the improvement's first task, in a new
  plan section "Handed to the improvement's first task (category b)" that also lists the
  other (b) items, and in IMP-002's Applied entry.
- `7ef025b` — **#20 closed**: `.vault-token` and `vault-keys.json` in the secrets block,
  `*.iml` with `.idea/`; `*.log` NOT added (the graft's decision D10). DoD:
  `git check-ignore -v` of the three names now points at the repo's `.gitignore` (lines
  91, 92, 38) — on `main` none of them was there; `x.log` is still ignored only by the
  user's global gitignore; no tracked file matches.
- **The real-launchd verification plan for branch 4** — drafted, then reviewed
  adversarially by two agents (a safety lens and a validity lens, read-only, forbidden to
  run launchctl): both "sound with fixes". The hypothesis and the discriminator hold (the
  not-found path is byte-identical for `1 --dry-run` and a real `<modules> --yes` agent;
  this Mac already shows the default launchd PATH and brew only in /opt/homebrew/bin).
  Fixes applied: literal values in every block (the draft had a `<scratchpad>`
  placeholder, which zsh parses as redirections, and a cleanup depending on variables of
  an earlier block); no inline comments (interactive zsh here has INTERACTIVE_COMMENTS
  off); a bounded poll instead of `sleep 5`, with "still running → no cleanup"; a
  recorded preflight (the revision `278ce8f`, machine facts, no other session, no stale
  output); CONFIRMED needs `runs = 1`, `last exit code = 0`, an empty stderr and no new
  session log; REFUTED needs the source of the PATH entry and never drops the PATH
  bootstrap on one Mac's evidence; the plist lives in the git-ignored logs/ (the
  scratchpad is session-scoped); cleanup only after the output is pasted back, with the
  orphan check AFTER the bootout and a conditional `kill` by PID. Persisted in
  [[plans/debt-cleanup-pre-dashboard]], section "Task 4 — the real-launchd verification";
  nothing was written into ~/Library or loaded into launchd.
- The checkpoint: STATE (branch 3, #20 closed, #23 points at the procedure, branch 2
  integrated), INDEX, LEARNINGS (IMP-026), plan tasks 2–3 ticked.

## Verification
- `make check` green; `make test` 268 checks green.
- The persisted block B parses under `zsh -n`; the block-C `ps` pattern does not match
  its own `grep`.

## Security gate
**Not applicable.** `.gitignore` and memory only; no rule-8 component touched.

## Problems encountered → cause → solution
1. The first draft of the user's command blocks carried a placeholder, cross-block
   variables and inline comments → docs/04 forbids only placeholders; the other traps
   are written nowhere → fixed after the review → IMP-026.

## Proposals
- IMP-026 (command blocks for the user: self-contained, literal, with no inline
  comments; `Destination: framework`), OPEN in [[LEARNINGS]]. Related: the `/integrate`
  template's `# 1. …` lines print "command not found: #" in a zsh without
  INTERACTIVE_COMMENTS (harmless; the template is not changed without approval).

## Follow-up
- Branch 4 (N1 + 4b-0) only on the user's go: the agent writes the plist, prints blocks
  A–B, records their output (STATE #23 confirmed/refuted/inconclusive), prints block C,
  and only then writes code.

## Links
[[STATE]] · [[LEARNINGS]] · [[plans/debt-cleanup-pre-dashboard]] ·
[[sessions/2026-09-25-apply-project-imps]] ·
[[sessions/2026-09-24-debt-inventory-pre-dashboard]]
