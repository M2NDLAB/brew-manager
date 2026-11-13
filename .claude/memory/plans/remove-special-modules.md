---
type: plan
prompt: remove-special-modules
branch: feat/remove-special-modules
created: 2026-11-13
status: in-progress
tags: [plan, v2, removal, selection, contract, gate]
---
# Plan: task 3 of the 2.0.0 plan — remove bk, las, log, mas and module 10

## Goal
bk, las, log and mas gone from the code, the registries, the resolver, the dispatch and the
menu; module 10 retired; the five ids rejected with exit 2 everywhere (lone, any case, in a
list, in `--only`/`--skip`, in the menu) and announced by one constant hint; module 1
declared honestly under `--dry-run`; README, SECURITY.md, CHANGELOG, CLAUDE.md and
`fw/new-component.md` true; the gate passed; the STATE entries the removal moots closed after
a grep proves their code gone.

## Decisions it applies (not re-litigated)
- [[decisions/2026-10-07-v2-plan]]: **D3** «module 10 (greedy) is RETIRED in 2.0.0; the
  number 10 stays reserved», what `--greedy` still adds «is left to `brew upgrade --cask
  --greedy` by hand»; **D4** «module 5's cleanup keeps its default `y` under `--yes`; its
  "LaunchAgents" justification is reworded in B3»; **D5** «the removed names `bk`, `las`,
  `log`, `mas` exit 2 with a constant hint ("removed in 2.0.0 — see CHANGELOG.md"); they
  stay reserved forever»; **D6** «no startup notice for leftover agents (none installed on
  this Mac); the removal procedure is documented»; the rule and contract edits approved with
  the plan.
- [[plans/v2-personal-tool]], task 3: its work list and its gate — one independent reviewer,
  «selection still fails safe» (the exposure only shrinks).
- The user, 2026-11-08 ([[sessions/2026-11-07-post-upgrade-checkpoint]], *Work for task 3's
  branch*): CLAUDE.md's rule **Commit attribution** gets its limit, «vale solo per le sessioni
  cloud e Remote Control», under this branch's gate; STATE ≤ 7,000 characters at its
  checkpoint.
- Design choices of this plan, within those decisions: the hint covers `10` too (D3 reserves
  it, and `go --skip=5,10` — the menu's own footer example — now exits 2); the list behind
  the hint is presentation-only and never feeds the resolver, which rejects a removed id
  only because it is absent from `MODULE_DESC`; the "Valid modules" error and the menu's
  `0→13` hint are derived from `MODULE_IDS` instead of written by hand (R1); LICENSE's
  disclaimer on LaunchAgents (`LICENSE:32`) is the user's legal text and stays as it is.

## Verified before any code (2026-11-13, read-only, at `d91b0dd`)
- Homebrew 7.0.10 installed (7.0.x, as D9 asks). No `com.m2ndlab.*` plist in
  `~/Library/LaunchAgents`, none loaded; `agents/` holds only `agents_activity.log` (564 B),
  `backups/` is empty.
- Module 1 still writes under `--dry-run`: brew doctor's output to `/tmp/brew_doctor.log`
  (`mod_01:263`) and a plain `git status` in Homebrew's repository (`mod_01:112`, before its
  dry-run check), which may refresh that repository's index — so `MODULE_DRYRUN[1]=0` with
  `_KNOWN_UNGATED` naming it, until task 4 (STATE #3, #14).
- References outside the five files: 215 lines in 20 tracked files (README 65, CHANGELOG 31,
  `lib/selection.sh` 30, the tests 40, CLAUDE.md 18, `brew_manager.sh` 12, SECURITY.md 7, …);
  docs/00, docs/03 and docs/04 hold none since the v4.1.0 upgrade (brew's text lives in
  CLAUDE.md's answers).

## Tasks
- [x] 1. This plan. — commit: `13dde6d`
- [ ] 2. Module 1 declared ungated under `--dry-run` (#14): `MODULE_DRYRUN[1]=0` with its
  reason; `_KNOWN_UNGATED=(bk las 1)`. The summary marks a `1 --dry-run` row "ran anyway",
  which is what it does. Verification: `make test`; a `1 --dry-run` smoke shows the row. —
  commit: —
- [ ] 3. Retire module 10 (D3): delete `modules/mod_10_greedy.sh`; its entries in the four
  registries and `MODULE_IDS` (`go` = 0–9, 11–13); the menu footer's `go --skip=5,10`;
  module 4's About text (no module 10; `brew upgrade --cask --greedy` by hand); the core's
  comments that name it. Tests: `_ALL`, the `10,13` and `--skip=5,10` cases, `10` rejected
  lone, in a list, in `--only`, in `--skip`; the danger list; the `_ask_danger` wiring scan,
  which now fails on a missing file; the frozen key set; `MODULE_IDS` = 13; the three
  `>= 18` guards → `>= 13`. RED first (the rejection checks fail on the base). Verification:
  `make check`, `make test`, smokes `10` → 2 and `8 --dry-run` → 0. — commit: —
- [ ] 4. Remove bk, las, log and mas: the four files; their registry entries; the resolver's
  whole-token arms and lowercase-special checks, with the quirk notes they carried;
  `_selection_is_valid` (NEW-d); the dispatch to `"_module_${_mod}"` alone (#18); the TOOLS
  menu, the Choice hint, the footer's `bk`; the "Valid modules" error and the `0→13` hint
  from `MODULE_IDS`; the comments that name the modules or the agents (`brew_manager.sh`,
  `lib/selection.sh`, `lib/common.sh` and `_risk_caption`'s "schedules" — R12 —, mod_05:69 —
  D4). Tests: the named positives removed or flipped, `assert_valid_sel` and the BM-08c block
  gone, every removed name rejected in every position (lone, upper and mixed case, first,
  middle and last of a list, `--only`, `--skip`, the lenient menu path), the write, danger and
  sensitive lists, the key set, the `MODULE_DRYRUN[mas]` check, `_KNOWN_UNGATED=(1)`, the mas
  half of `test_dryrun_gates.zsh`. RED first. Verification: `make test`; smokes `bk`, `LAS`,
  `3,mas`, `go --skip=log` → 2 with nothing run, `8 --dry-run` → 0. — commit: —
- [ ] 5. The hint (D5): `RETIRED_MODULE_IDS=(10 bk las log mas)` and `_retired_in` in
  `lib/selection.sh`; the CLI error and the menu warning print the constant line. Tests: the
  helper, the reservation (no retired id in `MODULE_DESC`), the resolver never reads the list,
  and end to end through the real binary: `bk` and `go --skip=10` → 2 with the hint and no
  run, `99` → 2 without it. Verification: `make test`, a mutation of the hint's guard. —
  commit: —
- [ ] 6. README: the special modules and module 10 gone; the menu, the summary example, the
  flags (`--yes`, `--dry-run` and module 1), module 5's default (D4), Session logging (no
  `log`: the logs are plain files, pruned by hand), Project structure, Adding a new module
  (R1, no named-module recipe); an "Upgrading from 1.x" section — remove the agents with
  `las` while on 1.5.0, the `launchctl bootout` block as the fallback, the leftover folders.
  Closes R1, R3, R5, R12. — commit: —
- [ ] 7. SECURITY.md (footprint, network, scope; the gate list), CHANGELOG `[Unreleased]`
  (Removed, Changed, the upgrade procedure), `.gitignore` comments (the entries kept). —
  commit: —
- [ ] 8. CLAUDE.md — the answers **Sensitive components**, **Public contract** (the names and
  10 removed and reserved, the plist item deleted), **Error format**; the technical rules
  (Stack's runtime dependencies, the module structure, the Tests rule's bk/las/log caveat,
  **Commit attribution**'s limit) — and `fw/new-component.md` (no named-module path; never a
  retired id). — commit: —
- [ ] 9. The gate, `/fw:security-review`: one independent reviewer on the branch's diff,
  «selection still fails safe», the CLAUDE.md edits included; its findings resolved or
  recorded. — commit: —
- [ ] 10. `/fw:retro`, `/fw:checkpoint` (the session note; the component notes of bk and las
  retired, lib-selection and core; TREE, INDEX, the sensitive-components decision note; STATE
  reconciled with the triage's merge, the entries closed after a grep — #6, #6b, #12, #13,
  #15, #16, #18, #21's bk/log half, #22, #24, #27, #29, #31-F1, R1, R3, R5, R6, R12, NEW-d —,
  ≤ 7,000 characters), the printed `/fw:integrate`; the user checks the menu from a real
  terminal. — commit: —

## Resumption notes
- Base: `main` at `d91b0dd` (the triage's merge), which this branch's first checkpoint
  reconciles in STATE.
- `mod_03:39`'s "[A] … brew upgrade skips it (use --greedy)" is F5 (Homebrew 6.0), not module
  10: task 5 of the 2.0.0 plan.

## Links
[[STATE]] · [[plans/v2-personal-tool]] · [[decisions/2026-10-07-v2-plan]] ·
[[sessions/2026-10-07-replan-v2-assessment]] (appendix A) · [[lib-selection]] ·
[[core-brew-manager]] · [[mod-bk-brewfile]] · [[mod-las-scheduler]]
