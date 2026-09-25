---
date: 2026-09-25
task: branch 2 of the pre-dashboard debt cleanup — re-audit branch 1's STATE rewrite, apply IMP-003/004/007/002, defer IMP-005
branch: chore/apply-project-imps
status: completed
model: 'claude-opus-5-5'
turns: 1
tags: [session, debt, process, imp, memory]
---
# Session 2026-09-25 — debt cleanup, branch 2: the approved project IMPs

Branch 1 was integrated by the user (merge `73bc5ee`). Before branch 2 the user asked
to confirm that the /checkpoint critical-debt check (step 3) had passed on branch 1's
STATE rewrite, and to stop if anything was missing. Then: apply IMP-003, 004, 007, 002
(one commit each), record IMP-005 as cut, mark IMP-002/004 `Destination: framework`.
Plan: [[plans/debt-cleanup-pre-dashboard]] (task 2).

## The critical-debt check of branch 1 (verified before starting)
- Entry level (a script over the "Attenzione" section at `e7c3a56` → `8ed9f5c` →
  `73bc5ee`): the upgrade only ADDED #18–#20; branch 1 lost no entry, added #21–#29,
  and closed or moved four with a written reason — #5b (a rule, moved to "Decisioni
  prese"), #7 (the history scan), #10 (by design + BM-02), #19 (IMP-022) — while #4
  was absorbed into #4b with its reason. Every open entry kept an explicit trigger.
- Facet level (a workflow: 5 auditors over every claim of the old entries, each
  "lost" claim challenged by a refuter): no debt, risk, constraint or trigger lost.
  Five minor facets had disappeared without a reason — the BM-08b mechanism that
  closed the resolver case (#3b), the positive fact that the bk preview mirrors the
  invalid-`modules` skip (#6b, and its mention in #9), and the "PRE-EXISTING" marker of
  #12/#13 — plus truth drift in kept text: #14 still said the grep half of
  `test_run_summary.zsh` protects a flip (it only proves the gate is mentioned), #8
  pointed to "#12 mod_02" (a wrong number since `98cdbff`: mod_02's `brew update` was
  in #3), #12 did not state its reachability precondition, #16/#17 kept stale wording
  above their corrections, #18 named no gate. All restored or fixed at this checkpoint
  (Level 1). Verdict: the check had passed; nothing to stop for.

## Done
- `a59d5eb` IMP-003 — CLAUDE.md Code conventions: never pass data through `echo`.
- `a7f309f` IMP-004 — docs/03 "How the gate works": closing a class of defect.
- `225cadd` IMP-007 — CLAUDE.md Tests + `/new-component` step 5: the module smoke.
- `53d4827` IMP-002 — docs/02 "Tests that demonstrate": the contract-surface checklist
  (its message amended before any push: the first version misdated the README
  exit-code episode — the false claim came from BM-08b and was removed before v1.3.0).
- `36aa1b2` — the fixes of the adversarial review (below).
- The checkpoint: IMP-002/003/004/007 → Applied with their shas (IMP-002/004 with
  `- Destination: framework`), IMP-005 → Deferred (cut by the user, with a resumption
  trigger), IMP-025 from the retro; STATE (the branch, the facet repairs, #3b notes
  IMP-003 as applied); INDEX; plan task 2 ticked.

## The adversarial review of the four applications
10 agents: a reviewer per IMP plus a cross-document critic, each followed by a refuter.
Upheld and fixed in `36aa1b2`:
- IMP-003 (high): the first draft called the escape expansion in the output helpers
  "acceptable on screen" — the opposite of the approved proposal and of its BM-09
  reinforcement. Also: the escape list missed `\n` (the #26 case) and `\c`
  (truncation); bare `printf '%s'` drops the last line of a `while read`. The rule now
  binds new and rewritten code, as approved; the existing sites stay in #3b.
- IMP-007 (high, from the critic): the prescribed smoke had no stdin handling and
  would never end for `bk`/`log` (#21), with an unspecified output file a reader
  could put in a fixed /tmp path (#11). Now: stdin from `/dev/null`, a `mktemp` file,
  the #21 caveat, the menu checked by the user from a real terminal; `/new-component`
  step 5 no longer claims the smoke checks the special-module menu loop.
- IMP-004 (low): the re-gate covers the whole branch diff; the class rule applies in
  any module.
- IMP-002 (low): the first draft widened the trigger to "an output contract, a new
  public surface", beyond the approved scope — narrowed back; (d) now breaks the
  implementation, not the contract.
- Refuted or left as they are: "(adversarially)" before its definition, "fix or record"
  without a destination, a pointer to the e2e harness in docs/02, the "default answer"
  bullet of `/new-component` step 5 (pre-existing, see Follow-up).

## Deviations from the letter of the approved IMPs (for the user)
- IMP-007: added stdin from `/dev/null`, a `mktemp` file and the #21 caveat (safety);
  dropped "check the menu by letting the pipe run `go` and interrupting it" (a piped run
  hangs afterwards and an agent cannot interrupt it).
- IMP-002: kept to the approved scope (parity extractions and code built on the same
  contract, down to the exit code the user observes). Covering the Dashboard's JSON
  schema by the letter needs the user's go.
- IMP-003: "never echo on data" as the rule's title (the inventory's approved framing);
  the proposal's own wording spoke of normalising/cleaning.

## Verification
- The prescribed smoke, as written, on read-only module 8:
  `f=$(mktemp) && ./brew_manager.sh 8 --dry-run </dev/null >"$f" 2>&1` → rc 0, the run
  ends ("Log kept"), `pgrep -fl brew_manager.sh` empty afterwards.
- `make check` green; `make test` 268 checks green.
- LEARNINGS: 20 `Destination: framework` markers (15 harvested + IMP-023/024 + IMP-002,
  IMP-004, IMP-025).

## Security gate
**Not applicable.** No code is touched: CLAUDE.md, docs/02, docs/03, one command and
memory. The rule texts went through the adversarial review above instead.

## Framework files now carrying brew customisations
docs/02 (IMP-002), docs/03 (IMP-004 — besides the concrete sensitive list), and
`/new-component` step 5 (IMP-007): re-apply them at the next framework upgrade
(IMP-002/004 travel upstream through `/harvest-framework`).

## Problems encountered → cause → solution
1. Two of four applied rules were defective (an inverted sentence, a command that
   would hang) → the text was written from the proposal's gist, with no
   element-by-element map, and the prescribed command was never run → the review
   caught both; fixed, the command executed → IMP-025.

## Proposals
- IMP-025 (applying an approved IMP: map every element of the proposal, run the
  command a rule prescribes; `Destination: framework`), OPEN in [[LEARNINGS]].

## Follow-up
- Branch 3 (`chore/gitignore-d10`) on the user's go.
- Branch 5 (#18), which rewrites `/new-component` step 5 anyway: the bullet "check that
  with the default answer to the prompts it changes nothing" cannot be checked by a
  non-interactive smoke (every `_ask` is declined there; a `--dry-run` never reaches
  the prompts) — rewrite it as a source check plus the user's terminal check.
- For the user: whether IMP-002 should also cover output contracts and the Dashboard's
  JSON schema (a one-line widening).

## Links
[[STATE]] · [[LEARNINGS]] · [[plans/debt-cleanup-pre-dashboard]] ·
[[sessions/2026-09-25-imp-022-and-history-scan]] ·
[[sessions/2026-09-24-debt-inventory-pre-dashboard]] ·
[[decisions/2026-09-25-debt-cleanup-pre-dashboard]]
