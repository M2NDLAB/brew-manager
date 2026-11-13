---
date: 2026-11-13
task: 2.0.0 task 3 — remove bk, las, log and mas, retire module 10, refuse their ids with exit 2 and a hint, declare module 1 ungated under --dry-run; the user docs, CLAUDE.md and the gate
branch: feat/remove-special-modules
status: completed
model: 'claude-opus-5-5'
turns: 1
tags: [session, v2, removal, selection, contract, gate]
---
# Session 2026-11-13 — 2.0.0 task 3: the special modules and module 10 removed

## Done
On `feat/remove-special-modules`, from `main` at `d91b0dd` (the merge of
`chore/framework-triage-imp-033-050`), the task plan [[plans/remove-special-modules]] —
the user's "continua": the next task of [[plans/v2-personal-tool]] —, one commit per task:
- `13dde6d` — the plan. No new decision came first: D3–D6 of [[decisions/2026-10-07-v2-plan]]
  decide the removal; the plan's own choices within them are listed in it (the hint covers
  `10` too; the list behind it is presentation only; the "Valid modules" error and the
  menu's range derived from `MODULE_IDS`; LICENSE untouched).
- `44394b9` — task 2: `MODULE_DRYRUN[1]=0`, `_KNOWN_UNGATED=(bk las 1)` (STATE #14).
- `55ba0ee` — task 3: module 10 retired (`feat(core)!`, `BREAKING CHANGE`).
- `cf1ef60` — task 4: bk, las, log and mas removed (`feat(core)!`, `BREAKING CHANGE`).
- `efc9fe2` — task 5: the hint for a removed id (D5), and the suite's first menu check.
- `b6faea1` — task 4's second commit, from the read-only sweep (below): the wiring
  invariant, the `MODULE_DRYRUN` phantom check, the test comments the removal made inexact.
- `bbe1db7` — task 6: the README (amended before publication from `57623a9`, Problems 3).
- `6a8c725` — task 7: SECURITY.md, the CHANGELOG's `[Unreleased]`, `.gitignore`'s comments.
- `5319eee` — task 8: CLAUDE.md's answers and rules, `fw/new-component.md`.
- `48b0d03`, `1226896` — task 9: the gate's fixes, two rounds (below).
- This checkpoint: the plan completed, this note, STATE (6,996 → 6,936 characters), TREE,
  INDEX, the component notes (bk and las retired, lib-selection, core, lib-common, mod-01,
  mod-05), the sensitive-components decision note amended, LEARNINGS.

Measured before any code (read-only, 2026-11-13): Homebrew 7.0.10; no `com.m2ndlab.*`
plist in `~/Library/LaunchAgents` and none loaded; `agents/` holds `agents_activity.log`
alone (564 B), `backups/` is empty; module 1 writes `/tmp/brew_doctor.log` under
`--dry-run` (`mod_01:263`) and runs a plain `git status` before its dry-run check
(`mod_01:112`).

Every code task showed RED on the unchanged code first, then GREEN, and a mutant against
the contract: task 3, 21 selection, 2 registry and 2 end-to-end checks, and the scan's
missing-file check with `mod_10_greedy` listed again; task 4, 68 selection checks, and
end to end `bk` hit the 60 s watchdog — STATE #21's hang — while `LAS`, `8,mas` and `go
--skip=log` exited 0; a mutant accepting `log` in the filters failed exactly the three
`--only`/`--skip` checks; task 5, the helper, the list and the three places the hint must
show, then a never-true and an always-true mutant, each caught; task 4's second commit,
`10` back in `MODULE_IDS` alone and `[bk]=0` back in `MODULE_DRYRUN` alone, each caught.
`make test`: 333 → 349 → 412 → 441 → 446 checks. Smokes through the real binary: `10`,
`go --skip=5,10`, `bk`, `LAS`, `BK`, `3,mas`, `go --skip=log` exit 2 with nothing run,
`8 --dry-run` exits 0, `1 --dry-run` shows module 1's row as "ran anyway".

The STATE entries closed by the removal, each after a grep at `5319eee` over
`brew_manager.sh`, `lib/` and `modules/` found its code gone (0 lines each for
`Weekday|StartCalendarInterval|plist`, `brew bundle`, `launchctl`,
`agents_activity|agent_.*\.conf|com\.m2ndlab`, `_module_1[0456]|_module_log`,
`_selection_is_valid`, `mas upgrade|brew install mas`, module 10's `auto_updates: true`):
#6, #6b, #12, #13, #15, #16, #18, #21's bk/log half, #22, #24, #27, #29, #31's F1. And
from the debt inventory: R1, R2, R2b, R3, R5, R6, R12, NEW-d.

### The read-only sweep (a workflow, `wf_252fc55d-dd2`)
Four finders at `d91b0dd` — code, tests, user docs, process and memory — then a critic,
under a 30-minute stall budget fixed before the run, alongside tasks 2–5. The four returned
(code 101 sites and 14 claims, tests 70 and 24, user docs 130 and 37, process and memory
117 and 33); the budget stopped the critic, which had just started, and its pass was done by
hand: the search modalities over the files outside the four areas (synonyms, counts,
ranges, examples), which found only `.gitignore` (task 7) and `fw/checkpoint.md`'s tree
exclusion, kept since the folders still exist on this Mac. What the finders found beyond
the plan went into `b6faea1` and tasks 6–8: the missing wiring invariant (a registered id
whose file is gone would make `go` call a missing command, the status unread, the row ✓),
`MODULE_DRYRUN`'s missing phantom check, `test_guardrails.zsh`'s twin of mod_05's D4
comment, the plan's Goal claiming exit 2 in the menu (it exits 1), CLAUDE.md's rule on
`MODULE_IDS`.

The main session committed during the run. The snapshot was taken before it and again
after each of its own commits, and each window compared: the only differences were the
main session's commits (HEAD, the branch's ref, the worktree's HEAD), and after the stop
the last window was identical, `git status` clean, `git diff` empty (IMP-058).

## Security gate
- Under the gate: the branch changes code paths that decide what runs (the resolver and
  the registries of `lib/selection.sh`, the dispatch and the menu of `brew_manager.sh`) and
  removes paths that deleted and installed; README and SECURITY.md assert security
  properties. Outcome: **passed — no CRITICAL, HIGH or MEDIUM in three rounds**; reviewed
  tip `1226896` (`12268968218c5a15fd025e68548b6e82ad74d8a8`): the three rounds read
  `d91b0dd..5319eee`, `5319eee..48b0d03` and `48b0d03..1226896`, together the branch's
  shipped diff; the checkpoint after it touches `.claude/memory/` only.
- Round 1, `/fw:security-review` as a workflow (`wf_97da90ff-1f3`): one independent
  reviewer, then one refuter per finding, under a 30-minute stall budget fixed before the
  run. `Reviewed: d91b0dd..5319eee8307d946bed050898683045b182036958` — 0 CRITICAL, 0 HIGH,
  0 MEDIUM, 2 LOW, 9 INFO. The reviewer ran 86 removed-id cases through the real binary
  (a symlink farm with a mock brew), the menu at a pseudo-terminal, `go --dry-run`, the
  exit-code order, `make test`. The budget stopped four refuters; their findings (F2, F4,
  F5, F11) were checked by hand on the sources, all four holding; F6 was refuted (the
  recorded F5 of Homebrew 6.0, STATE #31). F1 (LOW): the README's `--yes` row named module
  5 as the only prompt defaulting to yes, module 1's developer-mode restore does too. F2
  (LOW): the Brewfile advice did not say `brew bundle install` runs the file as Ruby. INFO:
  F3 `rm -r` relative and without `-i`; F4 `lib/log.sh`'s session-log deletion missing from
  the sensitive components; F5 SECURITY.md's network list (a recorded debt, its pointer
  restored in STATE for task 8); F7 a launchd behaviour stated as fact; F8 two dispatch
  comments crediting the resolver with what the wiring test holds for `go`; F9 two CLAUDE.md
  wordings; F10 an install updated by copying files keeps the old module files, which the
  glob loads; F11 "while you are still on 1.5.0" ambiguous on `main` before the 2.0.0 tag.
  Fixed in `48b0d03`: all but F5 and F6.
- Round 2, an independent reviewer on the fix: `Reviewed:
  5319eee..48b0d031718c320ceb1e4c1e0db9d2a3d6c1b26a` — the nine fixes closed, nothing new
  authorised; one LOW (the leftover agent's sentence: the restore also follows `brew
  developer on`) and five INFO, all precision in the new text (when `brew bundle` updates
  Homebrew, what `--no-upgrade` still lets `brew install` upgrade, a deprecated
  `HOMEBREW_BUNDLE_*` setting that removes what the file does not list, the changelog's lost
  `--file=`, the adoption prompt behind `--adopt=`, a launchd run's environment). Fixed in
  `1226896` by scoping the claims, not extending them (IMP-056). Its guard event: the
  agent git guard refused a `git ls-remote`; the reviewer did not work around it.
- Round 3, an independent reviewer on the second fix: `Reviewed:
  48b0d03..12268968218c5a15fd025e68548b6e82ad74d8a8` — no CRITICAL, HIGH, MEDIUM or LOW;
  every round-2 point closed (each checked on Homebrew 7.0.10's source, every prompt's
  default, the 1.x plists' arguments and man zsh's startup files); one INFO: README:108's
  pointer to `brew bundle install --help` does not back the sentence, since the setting that
  removes packages, `HOMEBREW_BUNDLE_FORCE_INSTALL_CLEANUP`, is deprecated and hidden from
  that help yet still honoured. It names twins outside the diff, on `main` since task 2 and
  not made worse: README:268 (the restore after `brew developer on` too; a launchd run's
  environment), README:220's "Skips all interactive prompts" (the menu's and the log's bare
  reads, #44's class), `mod_01:86`'s wording for a variable from `brew.env`. A line of text
  closes each, so they close in the release (docs/03, *How the gate works*, point 4):
  STATE's documentation debt for task 8, #44, #39. Its budget (15 minutes) ran out as it
  reported; the session's restart (below) found it still running and its report arrived.
  It reported, rightly, the working tree changing under it: the main session was writing
  this checkpoint's memory files (14 modified and this note, all under `.claude/memory/`)
  while it ran. It read every shipped line with `git show 1226896:`, so its review stands;
  the lesson joins IMP-058.
- Rounds 1 and 2: the repository's snapshot identical before and after, `git status` clean.
  Round 3: its snapshot file was in the session's scratch folder, gone with the restart, so
  the snapshot was read by hand after it — HEAD and the branch at `1226896`, `main` =
  `origin/main` = `d91b0dd`, the tags unchanged, no stash, no other worktree, the one
  untracked file this note — and `git diff` held only the main session's memory edits. No
  reviewer wrote in the repository. Not covered by the gate: running 1.5.0's `las` or any
  mutating brew command, the real Homebrew side effects of each module under `--dry-run`
  (all runs used a mock brew), the menu's look on a real terminal (STATE #45), the claim that
  `script(1)` flushes typed-ahead input, read in behaviour (Problems 1), not in its source.

## Problems encountered → cause → solution
1. The first menu check waited at the Choice prompt until the watchdog (rc 124) → the
   recorder's `script(1)` sets the terminal to raw mode and the line typed ahead is lost —
   with `TCSAFLUSH`, by the behaviour seen, not by its source → `_run_menu` types its line
   once the prompt is on screen, waiting up to 10 s; recorded in CLAUDE.md's Tests rule.
2. A compound command that set up a scratch farm with `rm -rf` was refused → IMP-027's
   class (the deny patterns read the whole command text) → a script written with the file
   tools, in a fresh `mktemp` folder, deleting nothing.
3. commitlint cut task 6's body at a wrapped line that opened with `--dry-run:` → the
   pre-check matched only `^[A-Za-z]…:`, and the chain committed on the warning → the
   unpublished commit's message reworded with `--amend` (`57623a9` → `bbe1db7`, the same
   tree); since then the check covers dashes and the commit runs only on a clean lint,
   which refused a later message before its commit (a line opening with `F8:`); IMP-052's
   fourth case.
4. The sweep's critic and four of the gate's refuters did not fit their stall budgets →
   a last stage starts only after the slowest agent before it (27 and 23 minutes here) →
   stopped at the budget, their passes done by hand; the second session in a row → IMP-059.
5. A dry run's disk line read "grew ~8K" → Homebrew's own Ruby compile cache (bootsnap),
   which any brew command updates (`find -newer` found its two files alone) → said in the
   README beside the example; not a write of brew-manager's.
6. The gate's claims grew by rounds: round 1's fix listed what `brew bundle install` does,
   round 2 found five precision points in the list → the claim scoped to what the command
   can do, pointing at its `--help` (IMP-056's evidence); round 3 found the pointer itself
   short of the claim (the removing setting is hidden from the help) → recorded for the
   release rather than a fourth round, as docs/03 allows an INFO a line of text closes.
7. The session restarted during round 3 (a fork, 2026-11-14 at 00:09): the scratch folder
   went with it — the gate's runner scripts and the snapshot files — and the plan's boxes of
   tasks 2–8 were still `[ ]` beside their recorded commits → the resumption checks
   (branch, base, the ticks against `git log`, the uncommitted memory work kept, the
   snapshot read by hand) held; the boxes ticked; the round-3 reviewer, still running,
   reported on its own.

## Factual doc corrections (Level 1, docs/06)
- `lib/selection.sh`'s header "(it only defines data and a function)": functions.
- The registry comments and `test_menu_registry.zsh` pointed at "docs/04" for the frozen
  ids: since v4.1.0 the contract is CLAUDE.md's answer **Public contract**.
- `test_selection.zsh`: "BM-08b/c will wire the return code" (BM-08b wired
  `_resolve_cli`'s, BM-08c is gone) and "a straight move of the old inline parser" (2.0.0
  departs from it on purpose).
- CLAUDE.md's answer **Sensitive components** gained `lib/log.sh`'s session-log deletion, a
  deleting path it always had and never listed (the gate's F4), and the decision note
  [[decisions/2026-07-12-componenti-sensibili]] its amendment.

## Proposals
- IMP-052 (OPEN, `Destination: framework`): a fourth case, the dash form.
- IMP-056 (OPEN, `Destination: framework`): a second case, the gate's round 2.
- IMP-058 (OPEN, `Destination: framework`): the snapshot check when the main session
  commits during a delegated run.
- IMP-059 (OPEN, `Destination: framework`): a last stage placed after the slowest agent
  does not fit the stall budget.

## Follow-up
- For the user, before merging (STATE #45): the menu from a real terminal (no TOOLS
  section, the Choice prompt `[go / numbers, default: go]`, the footer's `go --skip=5`);
  LICENSE:32 still names "LaunchAgents created or modified by this tool" — their legal
  text, kept as it is here.
- On this Mac, `agents/agents_activity.log` (564 B) and an empty `backups/` are left from
  1.x: the README's procedure, by hand, if the user wants them gone.
- F5's texts the removal did not touch — `mod_03:39`, README's "Why this exists" and
  module 3's `[A]` line ("`brew upgrade` skips it") — stay with task 5 (STATE #31);
  SECURITY.md's network list with task 8 (the gate's F5, STATE's documentation debt), and
  so do round 3's INFO and its README twins; README's "Skips all interactive prompts" with
  task 4 (#44); `mod_01:86`'s `brew.env` wording with task 5 (#39).
- STATE #42: `git log --format=%B 269cc9c.. | grep -cE
  'https://claude\.ai/code/session_[0-9A-Za-z]'` printed 0 on 2026-11-13, before this
  checkpoint's commit.
- Next: task 4 of [[plans/v2-personal-tool]], `fix/session-log`, after this merge.

## Appendix — STATE.md's lines this checkpoint rewrote or removed, verbatim at `d91b0dd`
The lines of `git show d91b0dd:.claude/memory/STATE.md` that the new STATE does not keep
as they were (3–4, 9, 12, 15–16, 20, 26, 31–36, 39–47, 50–52, 54, 58–61, 64–65):

updated: 2026-11-08
branch: main
> Updated: 2026-11-08 | Last: **IMP-033…050 delivered upstream** → [[sessions/2026-11-08-framework-triage-imp-033-050]] | Index: [[INDEX]]
- [ ] **2.0.0** ([[plans/v2-personal-tool]]): tasks 1–2 INTEGRATED → **task 3** (MAJOR) → … → 8 the release.
- `brew_manager.sh`, `lib/`, modules 0–13 (`go`), bk/las/log/mas: [[TREE]], [[INDEX]].
- `make test` 333 checks (9 zsh suites); `make check` = `zsh -n`; no CI; gitleaks in the pre-commit hook, the history to 2026-09-25 clean (#7); tags annotated from `v1.2.0`.
- In CLAUDE.md: trunk-based `main` ([[2026-07-12-trunk-based-su-main]]), tags only from `chore/release-vX.Y.Z`; the rule **Security gate** and the contract (U2, U5 of [[decisions/2026-10-19-framework-upgrade-v4.1.0]]), its module ids frozen for the users' plists.
- README/SECURITY.md vs the code ([[sessions/2026-09-24-debt-inventory-pre-dashboard]], E): each 2.0.0 task fixes its section, task 8 the residue (R4, R9–R11, R13, M3, SECURITY.md:36-41 (upgrade gate F5) and its docs/03 pointer); bk/las/log/mas described until task 3.
- **#3** `--dry-run` not uniform: #15/#16 (task 3); module 1's `/tmp/brew_doctor.log` and plain `git status` (may refresh Homebrew's index) → task 4, with #11, #14.
- **#3b** zsh `echo` on data expands escapes (LOW, 74+ sites; #26 live): module 0's three install-path sites → task 5, the rest → TRIGGER: v2.0.0 (D10), or new code copying it.
- **#4** "Success" printed after a failure (modules 0, 2, 4, 5; bk, mas, las remove, log until task 3) → task 7, with 4b-1.
- **#4b** Module outcomes not reported: 17 of 18 modules return 0 when brew fails, `$?` unread, ✓ for failed/skipped/declined → task 7 (4b-1, reduced 4b-2, raw output into the log). Ctrl+C exits 2 → 130 in task 4.
- **#6** Multi-day schedules skipped, not round-tripped (bk, las) → task 3.
- **#6b** bk's agents-restore preview does not mirror the restore (LOW/MEDIUM) → task 3.
- **#12** las re-register/repair widen a scoped agent to `go --yes` (LOW → MEDIUM proposed) → task 3.
- **#13** Agent labels from untrusted data (LOW/MEDIUM) → task 3.
- **#14** `MODULE_DRYRUN` = the modules ignoring `--dry-run` (`[bk]`/`[las]`=0, never flipped without the fix; `_KNOWN_UNGATED` both ways) → task 3 (`[1]=0`, `_KNOWN_UNGATED=(1)` if module 1 still writes; today `[1]=1`), closes in task 4 with #3.
- **#15** bk `[4] Check` evaluates the Brewfile in a preview (MEDIUM, accepted until bk goes) → task 3.
- **#16** las `[c]` deletes the agents' audit logs, ungated; `mkdir` ungated (MEDIUM+LOW, accepted until las goes) → task 3.
- **#18** `_module_14` collision (bk/las/mas = `_module_14/15/16`) → task 3, which checks none is left.
- **#21** Non-TTY bk/log runs hang (idle, MEDIUM) → task 3; `_handle_log`'s bare `read` (deaf to `--yes`; an open stdin waits) → task 4 (D1).
- **#22** bk ignores NON_INTERACTIVE (LOW-MEDIUM) → task 3.
- **#24** las recreate rejects zero-padded minutes (LOW) → task 3.
- **#27** Agents on interactive-only modules report done (LOW) → task 3.
- **#29** bk wet previews trigger Homebrew's auto-update (INFO) → task 3.
- **#31** Homebrew 6.0/7.0 compatibility (appendix D's F2, F4–F9, F11, NEW-a; F1 → task 3) → task 5.
- **#33** "noise until BM-18": `brew_manager.sh:533-534`/`:584`, `lib/common.sh:339-341`, CLAUDE.md's **Public contract** (the returns are uniformly 0) → task 7.
- **#42** `attribution.sessionUrl` unproven (it needs the project's settings loaded) → TRIGGER: each checkpoint, the link count of [[sessions/2026-11-07-post-upgrade-checkpoint]] (Follow-up); closes at a commit the user confirms came from Remote Control or the cloud. The user decides if CLAUDE.md's rule names the limit.
- **#44** The run header's "no changes" (`--dry-run`, `brew_manager.sh:496`) and "built-in defaults" (`--yes`, `:500`) are false while #3, #14–#16, #21–#22 hold (LOW) → tasks 3–4.
- Closed: #1, #2, #5, #5b, #7, #8, #10, #17 (reopen: a caller sets the variables), #19, #20, #23 (reopen: no Homebrew outside a login shell), #28, #30, #34–#37, #41, #43.
- [[LEARNINGS]]: OPEN 006, 008–021, 023–029, 032, 051–057 → TRIGGER: the periodic retro or the user's request; the Architect's report on 051–056 (sent 2026-11-08) and on the old IMPs 006, 008–011, 013, 014, 016, 019, 021, 026–028 in part (v4.1.0 covers them; decision D: none closed before). Deferred 033–050, delivered 2026-11-08 → the framework release holding each, at the next upgrade (harvest: OPEN only); 005, its own trigger.
- **chore/framework-triage-imp-033-050**: done, at `/fw:integrate`'s checks (no tag).
- **main** (integration = stable): `71e2be9` = `origin/main`, tag `v1.5.0` = VERSION; `origin/dev` dormant; the others merged and deleted.
