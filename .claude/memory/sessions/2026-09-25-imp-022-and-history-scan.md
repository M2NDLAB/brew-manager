---
date: 2026-09-25
task: branch 1 of the pre-dashboard debt cleanup — persist the inventory, apply IMP-022, close #7
branch: chore/imp-022-sensitive-selection
status: completed
model: 'claude-opus-5-5'
turns: 1
tags: [session, debt, security, process, memory]
---
# Session 2026-09-25 — debt cleanup, branch 1: IMP-022 and the history scan

The user approved the read-only inventory
([[sessions/2026-09-24-debt-inventory-pre-dashboard]]) with changes and decisions
([[decisions/2026-09-25-debt-cleanup-pre-dashboard]]) and asked for one branch at a
time ([[plans/debt-cleanup-pre-dashboard]]). This is branch 1: docs and memory only.

## Done
- `6b1e5f6` — the full inventory persisted as a session note, FIRST, as the user asked:
  it lived only in the session scratchpad (in Italian); rewritten in English per rule 9,
  every item with its verifier corrections and code references.
- `aa54a51` — the decision note and the programme plan (16 branches in order).
- `90cb34c` — **IMP-022 applied**: `lib/selection.sh` added to CLAUDE.md rule 8 and the
  technical rules, docs/03 (the concrete list; "input parsing" → "flag parsing" for
  `brew_manager.sh`, since the flags stay there), docs/00 (the end-of-deliverable
  cycle), the 2026-07-12 decision (an English amendment: seven components), INDEX and
  STATE; `/new-component` step 6 now names every list (it named only two).
- `5fa7159` — **#7 closed**: the one-off gitleaks scan of the whole history recorded in
  STATE and in docs/03 (which still called it debt).
- The checkpoint commit: STATE rewritten per the inventory (the Level-1 corrections
  below, entries #21–#29 added, the (c) conditions on #17 and #3b written into their
  entries), INDEX, LEARNINGS (IMP-022 → Applied; IMP-023/024 from the retro), four
  component notes, task 1 ticked in the plan.

## Verification
- IMP-022 DoD — a grep over the 8 sites (rule 8, technical rules, docs/03, docs/00, the
  decision, INDEX, STATE, new-component step 6): 8/8 green on the branch, and 8/8
  MISSING on the parent commit (counter-proof: the check has teeth). No text left
  claiming six components except the Italian original of the decision, explicitly
  superseded by its amendment.
- #7 — gitleaks 8.30.1, default rules (no `.gitleaks.toml`, no `.gitleaksignore`):
  `gitleaks detect --redact --log-opts="--all -m"` → "155 commits scanned … no leaks
  found", 0 findings in the JSON report; `git rev-list --all --count` = 155 (124
  non-merge + 31 merges, each merge diffed against its parents; the three extra commits
  over the inventory's 152 are this branch's). `git ls-remote origin`: HEAD/main
  `8ed9f5c`, dev `c0f456f`, tags v1.1.1, v1.1.2, v1.1.2-baseline, v1.2.0, v1.3.0,
  v1.4.0 — all 11 published objects resolve to local commits, so the scan covers the
  published history.
- The component-note corrections were checked on the code before writing them:
  mod_bk:203-209 (the 1-based weekday map with `i - 1`), mod_bk:486-489 (`_ask_danger`
  on [3a]), mod_las:396-398 (Modify does not delete the conf), lib/log.sh:20-21 (the
  bare `read`); and two STATE claims: `exit 0` at `brew_manager.sh:233` with no DRY_RUN
  check in :185-235, and `_resolve_cli go "" ""` → the whole sequence.
- `make check` green; `make test` 268 checks green (30+18+6+9+8+38+72+87).

## Security gate
**Not applicable.** No sensitive component's code is touched: the branch changes
docs, commands and memory. IMP-022 changes the gate's LIST itself; per the inventory
this is author-verifies (docs/03), done with the DoD grep and its counter-proof above.

## Factual doc corrections (Level 1, docs/06)
- docs/03: the #7 history scan is no longer "recorded as debt" — run on 2026-09-25, 0
  findings.
- docs/03: `brew_manager.sh` does "flag parsing", not "input parsing" (the selection
  parsing moved to `lib/selection.sh`).
- new-component.md step 6: the sensitive lists are five, not two.
- Memory: STATE frontmatter and "Active branches" (the post-upgrade checkpoint was
  already merged in `8ed9f5c`; the `.bak` hooks are gone), `brew_manager.sh:152` →
  :160, the #3b scope, the #4/#4b cause (returns uniformly 0, not "noise"), #10 closed,
  #5b moved to Decisions, the #6b/#12/#13/#16/#17/#18 corrections;
  components/lib-selection.md (74 → 87 checks), mod-las-scheduler.md (Modify does not
  delete the conf), mod-bk-brewfile.md (the weekday bug is closed; [3a] does confirm),
  lib-common.md (the `_handle_log` cause). In the inventory note, written earlier in
  this session: the `\065` bypass is one of BM-08b's two MEDIUM findings, not a third.

## Problems encountered → cause → solution
1. The inventory existed only in Italian in the scratchpad → the delegated agents had
   been briefed in the interaction language → rewritten in English before anything else
   (→ IMP-024).
2. 8 processes left hanging by the inventory's sandboxes, reparented to PID 1 → a
   watchdog killed only the direct child of each run → killed by the main session;
   the defect itself is STATE #21 (→ IMP-023).

## Proposals
- IMP-023 (delegated sandbox runs must not leave processes behind) and IMP-024 (brief
  delegated agents in the artifact language when their output will be persisted), both
  `Destination: framework`, OPEN in [[LEARNINGS]].

## Follow-up
- Branch 2 (`chore/apply-project-imps`: IMP-003, 004, 007, 002; IMP-002/004 also
  `Destination: framework`; IMP-005 → Deferred) on the user's go.
- `lib/agents.sh` (branches 11–12): the user asked to be told BEFORE if the extraction
  is too wide. Assessment: it is not, if the lib holds only pure parsing and validation
  (the label predicate, the `schedule=` parser, the bundle-line verdict) with no I/O and
  no launchctl — the plist writer stays in las. It is a cross-module extraction
  (docs/01): introduce it with its first consumer in branch 11 (bk), migrate las in
  branch 12, both suites green at each step, and add it to every sensitive list in
  branch 11.
- The harvest map (branch 14) waits for the framework numbers and the format.

## Links
[[STATE]] · [[LEARNINGS]] · [[plans/debt-cleanup-pre-dashboard]] ·
[[decisions/2026-09-25-debt-cleanup-pre-dashboard]] ·
[[sessions/2026-09-24-debt-inventory-pre-dashboard]] · [[2026-07-12-componenti-sensibili]]
