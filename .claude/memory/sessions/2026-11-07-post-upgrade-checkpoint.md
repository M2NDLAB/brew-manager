---
date: 2026-11-07
task: the first checkpoint after the framework upgrade to v4.1.0 — STATE condensed, the architect's decisions A–D applied
branch: chore/post-upgrade-checkpoint
status: completed
model: 'claude-opus-5-5'
turns: 2
tags: [session, memory, checkpoint, lint, attribution, security-gate]
---
# Session 2026-11-07 — the first checkpoint after the framework upgrade

The deliverable right after the upgrade's merge (`0b127a9`, no tag), as the user decided at
the upgrade (STATE #37): condense STATE.md and work #37's list, with the framework
architect's decisions A–D of 2026-11-07 and the user's answer on the anchors (U23), all
verbatim in [[decisions/2026-11-07-framework-architect-decisions]]. Plan:
[[plans/post-upgrade-checkpoint]] (eight tasks). Branch `chore/post-upgrade-checkpoint` from
`main` at `0b127a9`; one commit per task; no push, merge or tag.

## Done
- Baseline on the branch: `make check` 31 files, `make test` 333 checks (30+18+49+9+22+8+38+72+87).
- Plan and decision record: `3c47119`.
- Task 1 `e9c628f` — `make lint` (decision A). Before: `lint` sat in the Makefile's PROJECT
  part (below "brew-manager-specific targets", line 36 on; the framework's targets are
  help, hooks-install, reset-task and test-scripts), and ran `shellcheck --shell=bash
  --severity=warning brew_manager.sh lib/*.sh modules/*.sh` as advisory when shellcheck was
  installed, else printed "skip: shellcheck not installed (optional: brew install
  shellcheck)" and exited 0 — what it printed here (shellcheck is not on PATH). After:
  `lint: check`, no recipe of its own, so it runs `zsh -n` on check's files
  (`brew_manager.sh lib/*.sh modules/*.sh tests/*.zsh`). Measured: `make lint` and `make
  check` print the same 31 `ok` lines, rc 0; in a throwaway copy of the tree a syntax error
  appended to `lib/log.sh` makes `make lint` exit 2; `make test` 333. CLAUDE.md's two lint
  clauses, the CHANGELOG `[Unreleased]` (Changed) and the superseded line of
  [[2026-07-12-shellcheck-advisory]] say the same.
- Task 2 `269cc9c` — `.claude/settings.json` (decision B; the 2026-10-19 gate's F6, F7): written once from a copy in
  the scratchpad, parsed by node and python first; the parsed comparison with the old file
  shows `Bash(shellcheck:*)` removed from `allow`, `"attribution": {"sessionUrl": false}`
  added, `env`, `ask`, `deny` and both hooks identical; the file in place equals the parsed
  copy. `make test-scripts`: 13 PASS, 0 FAIL (the guard's self-test reads the wiring from the
  file). The technical rule **Commit attribution** in CLAUDE.md, the user's words.
- The key at its source — Claude Code's settings reference
  (`https://code.claude.com/docs/en/settings-reference.md`, fetched on 2026-11-07),
  *`attribution.sessionUrl`*: "Choose whether Claude Code appends the claude.ai session link
  when it commits or opens a pull request from a cloud or Remote Control session. Claude Code
  adds the link as a `Claude-Session` trailer on commits and as a link in pull request
  descriptions. Set it to `false` to omit the link." Scope "Any file", type Boolean, default
  `true`. *`attribution`*: "object with `commit` and `pr` strings and a `sessionUrl`
  Boolean"; "Once you set `commit` or `pr`, Claude Code ignores the deprecated
  `includeCoAuthoredBy` setting and uses its default text for whichever of the two you left
  unset." — setting `sessionUrl` alone leaves the `Co-Authored-By` default in place.
- The trailer check (the user's point 5): `269cc9c`, the commit that carries the change, and
  `32069dc`, the first commit after it, each end with `Co-Authored-By: Claude Opus 5.5
  <noreply@anthropic.com>` and hold no `Claude-Session:` line. The limit of that proof: this
  session's commit instructions, given at its start, never named a session link, and the key
  acts only on commits from a cloud or Remote Control session. The upgrade's 13 commits
  (`09b7250`…`0d17829`) were made in this clone — the reflog records each — by a session
  that, it is inferred, was connected through Remote Control (see *Follow-up*),
  and carry `Claude-Session: https://claude.ai/code/session_017D…`; they stay as they are. So
  the two commits agree with the rule without proving the key's effect, and the key holds
  only in a session that loads `.claude/settings.json`, started at the repository's root
  (docs/04): the check repeats at each checkpoint (#42).
- Task 3 `32069dc` — the answer **Error format** (U18 d), text only. Read in the code: modules
  4 and 5 show a failed command's output on screen (so in the session log `script(1)`
  records); modules 0, 1 and 2 first write it to fixed `/tmp/brew_*.log` files
  (`mod_00:215`, `mod_01:263`, `mod_02:96`), which module 1 prints, module 0 shows the last
  line of and module 2 only greps; many queries send stderr to `/dev/null`. The answer now
  says so and names tasks 7 and 4 of [[plans/v2-personal-tool]], where the behaviour changes.
- Task 4 `d2f5211` — LEARNINGS (Level 1): IMP-033 and IMP-047 quote docs/04 in its own words,
  as the 2026-11-07 harvest found them — "clean and specific" (`docs/04:450`) and "a script
  path or flag the rule's prefix didn't anticipate" (`:463-465`) for IMP-033, "prompt, or
  meet auto mode's classifier" for `git switch -C` and `git checkout -B` (`:268-269`) for
  IMP-047. IMP-050 added, the user's text, `Destination: framework`. After a harvest docs/06
  prescribes nothing for the project's entries (*The bridge to the framework*: the command
  only reads and prints; the framework counts a lesson harvested twice once, by its number
  and date) and `fw/harvest-framework.md` step 5 says not to mark anything: nothing marked on
  IMP-033…050. The user sent IMP-033…049 and IMP-050's text to the Architect on 2026-11-07
  ("ho mandato IMP-033…049 e questa nuova all'Architetto").
- Task 5 `d0acd2d` — #37's list of stale claims: one dated "superseded" line in
  [[2026-07-12-componenti-sensibili]] (the list's home, lines 8-40, and the gate's size,
  lines 43-45, both U2), [[2026-09-24-language-rule-prospective]] (D1) and
  [[2026-07-12-trunk-based-su-main]] (line 20); the 2.0.0 plan's open tasks re-pointed to
  CLAUDE.md's answers and `fw/new-component.md`, "one independent reviewer" for "one lens",
  the `/fw:` commands, task 8 under the gate, #38 in task 7 and #39 in task 5, task 2
  integrated; INDEX's stale lines. Ticked tasks and past notes keep their wording: they
  record what was done then.
- Task 6 `97c841c` — this note, with the comparison written before the rewrite and the
  archive: appendices A and B, then C (added in task 7, after the verification asked for the
  remaining sections) — together the whole of STATE.md at `0b127a9` from its title on, each
  part compared byte by byte with `git show 0b127a9:.claude/memory/STATE.md` (462 + 56 + 40
  + 5 + 208 + 88 + 53 lines).
- The gate's fixes, each in a commit of its own: `80cb567` (the project's targets phony),
  `bef57f3`, `25da1ad` and `36b0cdd` (the answer Error format, narrowed, then scoped),
  `de8e017`, `e79f80d` and `4e8149d` (memory). Task 8: this checkpoint — STATE 7,950
  characters (`wc -m`; 8,094 bytes), the measurement passed again, the archive re-compared
  (7 parts identical).
- Task 7 — STATE.md rewritten: 76,088 → 7,877 characters (`wc -m`; 8,025 bytes). The
  measurement of `/fw:checkpoint` step 3, `bash scripts/state-inject.sh`, prints the banner on
  line 1, `## Caution & open issues` on line 2, and no other line opening with `===`. 30 open
  entries under their numbers (24 kept, #38–#43 new); the closed ones in one pointer line;
  then the independent verification below, and its fixes.
- Task 2's acceptance run (#37, item a), on the user's Mac on 2026-10-10, after the merge
  `8a7e6a2`: the preview changed nothing, the restore was confirmed, Homebrew went from 7.0.8
  to 7.0.9 stable, and a second run did not turn developer mode back on. Two defects → #38
  and #39.
- The user's local permissions (#35, the 2026-10-19 gate's F2, F3): `.claude/settings.local.json` re-read read-only
  on 2026-11-07 — none of `git checkout *`, `git tag *`, `gh repo *`, `git ls-remote *`,
  `make check *`, `make test *` is left; `Bash(make check)` and `Bash(make test)` are there in
  exact form, the user's. The other rules are exact-form or a read of the framework
  repository, outside F2/F3.
- The anchors (U23): every open entry keeps its number; the new ones take 38–41; no number is
  reused; code and tests are not touched. Measured on 2026-11-07 (`git grep` outside the
  memory): 20 comment lines in 8 code and test files and 10 lines of CLAUDE.md cite #2, #3,
  #3b, #4b, #11, #14, #21, #23, #26 and #30 — four of them a bare `#N`
  (`CLAUDE.md:64`, `tests/test_exit_codes.zsh:11/:130/:143`); the upgrade counted 21 lines in
  9 files.
- The language of condensed entries (U4): CLAUDE.md's boundary — "new or rewritten text is
  English, while entries carried over as they are stay Italian" — applies; a condensed entry
  is rewritten, so English, and its Italian original stays verbatim in appendix A.
- STATE.md's size before: 76,088 characters (`wc -m`; 76,803 bytes), the count the hook gave
  at this session's start ("68088 of 76088 characters not shown"). The 71.6K the upgrade's
  note gave is its memory lint's measure at `d9e86ef` (71,584); the upgrade's own checkpoint
  (`0d17829`) then added its status line, its progress entry and #34–#37.

## Entry-by-entry comparison, written before the rewrite
Every entry of *Caution & open issues* at `0b127a9` and what the rewrite makes of it. "Open"
keeps the number and the trigger; "closed" leaves one pointer line; appendix A holds each
entry's text as it was.

| # | At `0b127a9` | After the rewrite | Trigger, or where the detail is |
|---|---|---|---|
| 1 | closed (M2, BM-08b/c) | closed — the pointer line | appendix A; [[sessions/2026-07-17-bm08c-agent-selection]] |
| 2 | closed (zsh 1-based arrays) | closed — the pointer line | appendix A; CLAUDE.md cites "STATE #2" |
| 3 | open | open, condensed; module 1's plain `git status` under `--dry-run` added (the verification) | task 4, with #11 and #14 (#15/#16 in task 3) |
| 3b | open | open, condensed | after 2.0.0 (D10); module 0's three sites → task 5; TRIGGER the v2.0.0 release or new code copying it |
| 4 | mod_10 resolved; the wider pattern open | open, condensed (modules 0, 2, 4, 5; bk, mas, las, log until task 3) | task 7, with 4b-1 |
| 4b | open (4b-3 closed) | open, condensed | task 7; Ctrl+C → 130 in task 4 |
| 5 | closed (a convention in force) | closed — the pointer line; the tags in *What exists now* | appendix A |
| 5b | closed (moved to the decisions) | closed — the pointer line | appendix A and B |
| 6 | open | open | task 3 |
| 6b | open | open | task 3 |
| 7 | closed (history scan) | closed — the pointer line | appendix A; [[sessions/2026-09-25-imp-022-and-history-scan]] |
| 8 | closed (BM-08c) | closed — the pointer line; its invariant in *Decisions made* | appendix A; [[2026-07-17-consent-vs-noninteractive]] |
| 9 | open | open, with #10's residue | task 6 |
| 10 | closed; its residue in #9 | closed — the pointer line | appendix A; the residue in #9 → task 6 |
| 11 | open | open | task 4 |
| 12 | open | open | task 3 |
| 13 | open | open | task 3 |
| 14 | open | open | bk/las in task 3; closes in task 4 with #3 |
| 15 | open (MEDIUM, accepted) | open | task 3 |
| 16 | open (MEDIUM+LOW, accepted) | open | task 3 |
| 17 | closed (accepted, 2026-10-07) | closed — the pointer line | appendix A (its reopen condition is there) |
| IMP bullet 1 | IMP-001…011, a stale status | replaced by the IMP line | appendix A; [[LEARNINGS]] |
| 18 | open | open | task 3 |
| 19 | closed (IMP-022) | closed — the pointer line | appendix A |
| 20 | closed (`.gitignore`) | closed — the pointer line | appendix A |
| 21 | open | open | bk/log half in task 3; `_handle_log` in task 4 |
| 22 | open | open | task 3 |
| 23 | closed (fixed, v1.5.0) | closed — the pointer line | appendix A; code and tests cite "#23" |
| 24 | open | open | task 3 |
| 25 | open | open | task 4 |
| 26 | open | open | task 5 |
| 27 | open | open | task 3 |
| 28 | closed (accepted, 2026-10-07) | closed — the pointer line | appendix A; its hardening is in task 4 of the 2.0.0 plan |
| 29 | open | open | task 3 |
| 30 | fixed, "closes at its merge" | CLOSED — the merge `8a7e6a2` | appendix A; [[sessions/2026-10-10-homebrew-developer-mode]] |
| 31 | open | open | task 5 (F1 of the assessment's appendix D → task 3) |
| 32 | open | open | task 4 |
| 33 | open, pointer to docs/04:143-145 | open, re-pointed to CLAUDE.md's answer **Public contract** | task 7 |
| 34 | open, the user's three options | CLOSED — in the pointer line; its declaration in *Decisions made*, where it outlives the next condensation | [[decisions/2026-11-07-framework-architect-decisions]] |
| 35 | open, the user narrows or accepts | CLOSED — narrowed by the user, re-read read-only; in the pointer line | this note, *Done* |
| 36 | open, the user decides before the push | CLOSED — in the pointer line; its declaration (the commits published before 2026-11-07 keep their trailer) in *Decisions made* | the decision; CLAUDE.md, **Commit attribution** |
| 37 | open, this checkpoint | CLOSED — this deliverable; in the pointer line | this note; [[plans/post-upgrade-checkpoint]] |
| IMP bullet 2 | IMP-012…049 OPEN, with 022, 030, 031 applied and 002–007's statuses | replaced by the IMP line | appendix A; [[LEARNINGS]] |
| 38 | — | NEW, open: the run summary's unmeasured counters | task 7 (#4b) |
| 39 | — | NEW, open: module 1's restore box overflows | task 5 (see below) |
| 40 | — | NEW, open: the upgrade's working folder | the framework's triage closes (decision C) |
| 41 | — | NEW, open: the upstream duplicates among the OPEN IMPs | the Architect's report (decision D) |
| 42 | — | NEW, open: `attribution.sessionUrl`'s effect, still to measure (the verification) | the first commit from a cloud or Remote Control session |
| 43 | — | NEW, open: `/fw:lint-memory` after a wide STATE rewrite (the core's table; the verification) | the user runs it |

The two blockquotes that opened the section (the 2.0.0 plan's triage of 2026-10-07; the
upgrade's "not condensed on purpose") go to appendix A; the first survives as the new
section's one-paragraph header, the second is spent. The entries are written as bullets with
a literal label (`- **#N**`): an ordered list that starts at 3 right after a blockquote is,
in CommonMark, part of the quote's paragraph, and a renderer would renumber the rest.

#39 goes to **task 5**, not task 4: `_box` (`lib/common.sh:215-250`) never truncates a line by
design ("never hide content such as what a destructive action will remove"), so the overflow
is module 1's own fixed text — "From: Homebrew <version> — to its latest release tag (it can
be older than a main-branch commit)", 88–104 columns by the version, and the local-changes
line, 91 — wider than the box's text field, `TERM_WIDTH - 6`: 74 columns on an 80-column
terminal. Task 5 already rewrites module 1's Homebrew texts; task 4 touches module 1 only for
its `/tmp` file. Fixing it in module 1 keeps the shared `_box`, which draws every consent box,
out of the change. The box appears only on a real run with developer mode on, so task 5
checks it on the restore run of `tests/test_homebrew_developer.zsh`'s mock brew at 80
columns (every line within the frame), or the user's own run; its gate reads the rewritten
details too (every disclosure kept, wrapped, not cut).

## The independent verification of the rewrite
Before task 7's commit, four delegated read-only agents checked the new STATE against
`0b127a9`, this note and the repository: three lenses (the open entries; the closed entries,
numbering and citations; the claims and `/fw:checkpoint`'s rules) and a completeness critic,
with a fixed budget of four agents and no rerun. The repository's snapshot
(`scripts/repo-snapshot.sh`) was identical before and after, and the working tree's diff kept
its hash. Their verdict: no open entry lost, renumbered or left without its trigger, no number
reused, every number cited by code and tests resolved. Fixed from their findings: #4's scope
(modules 2 and mas were missing); the IMP line's trigger (the periodic retro or the user's
request, not only #41); an entry for the measurement still to take (#42) and for
`/fw:lint-memory` (#43); Active branches no longer ahead of the work; the declarations of #34
and #36 moved into *Decisions made*, which a later condensation keeps; the labels; and the
nuances of #9, #12, #14, #15, #16, #17, #23, #31, #38, #39, #40 and the header. Their claim that
"IMP-033…050 sent" contradicts the decision record is settled by the user's own words — "il
2026-11-07 ho mandato IMP-033…049 e questa nuova all'Architetto" —: the record was the
inaccurate one, and is corrected. The critic also found module 1's plain `git status` in
Homebrew's repository, run before its `--dry-run` return (`mod_01_health.sh:112-113`): git's
own documentation (git 2.54.0, `GIT_OPTIONAL_LOCKS`) says the optional locks let "git status"
refresh "the index as a side effect" — a write under `--dry-run`, inferred from the
documentation and not measured on Homebrew's repository → #3, task 4. Not covered by them:
the tests and `brew_manager.sh` were not run (forbidden by the brief; this note's runs stand),
the live remote (no fetch), the user-level settings, and the Markdown rendering (no renderer
installed; the CommonMark rule only).

## Security gate
- `/fw:security-review`, **Reviewed: `0b127a9283169f02067738130d2ae8b765e04879..4e8149d1cba456761d959205a1901a13072b94e6`**
  (reviewed tip `4e8149d`) — **under the gate**: the branch changes `.claude/settings.json`,
  the method's boundary (the core's rule 8, "the enforcement edge (this method's guard, hooks
  and settings included)"; `/fw:integrate` names the file). The Makefile, CLAUDE.md, the
  CHANGELOG and the memory touch no code path of the answer **Sensitive components**; they were
  reviewed as part of the branch's diff and as claims. Per the technical rule **Security
  gate**: one independent, delegated, read-only reviewer per round, "what does this now
  AUTHORISE?" asked of every file — nothing authorises more: one allow rule fewer, an
  attribution key that grants no permission, a lint that runs `make check` — and one refuter
  per finding of LOW or above. Each round's repository snapshot was identical before and
  after. **Outcome: 0 CRITICAL, 0 HIGH, 0 MEDIUM** over four rounds, the later three on the
  fixes committed after the round before (a shipped file changed after a reviewed tip):
  - Round 1, `0b127a9..160b109`: F1 LOW → INFO by its refuter (CLAUDE.md's Error format kept
    "errors ONLY through `_err`/`_warn`"), **closed** by `bef57f3` and then `36b0cdd`; F2 LOW,
    upheld (STATE #42's "local commits never had the link"), **closed** in `de8e017`, the
    limit **declared** in #42 and the decision record; F3 INFO (the gate-scope restatements)
    **closed** `de8e017`; F4 INFO (#7's range) **closed** `de8e017`; F5 INFO (task 7's tick)
    **closed** `de8e017`; F6 INFO (no `.PHONY`: a stray `check` file passes the gate unrun,
    shown RED then GREEN) **closed** `80cb567`.
  - Round 2, `160b109..de8e017`, all INFO: N1 (the exception list) **closed** `25da1ad`, then
    `36b0cdd`; N2 (the framework part's targets, same class) **declared** as IMP-054 — the
    project does not edit the framework's part; N3 (the Commit attribution rule reads
    unconditional) **declared** in the decision record the rule cites — the rule's words are
    the user's, asked of them below; N4 (#42's trigger) **closed** `e79f80d`; N5 (F labels of
    two gates) **closed** `e79f80d`.
  - Round 3, `de8e017..e79f80d`, all INFO: Q1 (#42's count) **closed** `4e8149d`; Q2 (the
    dry-run notice, the relaying modules) **closed** `36b0cdd`, the rule scoped to where it
    holds; Q3, Q4 **closed** `4e8149d`.
  - Round 4, `e79f80d..4e8149d`: Q1–Q4 confirmed closed. N1 **LOW, pre-existing** (since
    v1.1.0, outside the diff): the run header's "no changes will be made" under `--dry-run`
    and "all prompts use built-in defaults" under `--yes` (`brew_manager.sh:496`, `:500`)
    are false while the recorded debts #3, #14–#16 and #21–#22 hold — **declared** as STATE
    #44, closing with tasks 3–4; a fix of its own would touch `brew_manager.sh` and go
    through the gate. N2–N4 INFO (#42 names its note; a quoted link counts; row 31's label)
    **closed** in this checkpoint's commit, memory only.
  - After the reviewed tip only `.claude/memory/` changes (this checkpoint).
  - Not covered by the reviews: no tests, `make` or `brew_manager.sh` run by the reviewers
    (the author's runs stand); the live remote (no fetch); the user-level and managed settings
    beyond the keys named; how Markdown renders; `attribution.sessionUrl`'s effect, which no
    session here could show (#42).
  - A brief breached: round 1's reviewer wrote one helper script into this session's scratch
    folder, outside the repository, never ran it and reported it; left in place for the user
    (IMP-055).

## Problems encountered → cause → solution
1. A verification command that cleared a scratch folder with `rm -rf` was refused → the
   project's `deny` rule `Bash(rm -rf:*)` matches it wherever it points → the check ran in a
   fresh `mktemp -d` folder, nothing deleted.
2. commitlint refused task 2's first commit, header 101 characters → the limit is 100 → a
   shorter header; nothing had been committed.
3. commitlint warned "footer must have leading blank line" on task 4's commit → a body line
   began with `it:`, which its parser reads as a footer (docs/04 says so) → the local,
   unpublished commit's message reworded (`git commit --amend`, `d2f5211`).
4. Saving the working tree's diff for the snapshot, `git diff > <a file in the scratchpad>`,
   was refused by the guard as "`git diff <path> <path>`" (also in its minimal form) → the
   guard's implicit no-index check counts the words after `diff`, the redirection among them
   → the diff kept by its hash (`git diff | shasum`); an IMP at the retro.
5. A loop re-checking the appendices printed "7 of 7" on empty input → zsh does not split an
   unquoted `set -- $spec` (docs/04's line on zsh), so every `sed` failed and `cmp` compared
   two empty streams → redone with explicit ranges and a guard against empty input; the false
   pass decided nothing.

## Factual doc corrections (Level 1, docs/06)
- IMP-033's and IMP-047's quotes of docs/04 (task 4).
- CLAUDE.md's answer **Error format** (task 3).
- The 2.0.0 plan's targets and gate wording, and INDEX's lines, made stale by the upgrade
  (task 5).

## Proposals
- IMP-050 (the user's text, decided at U2), `Destination: framework`.
- From `/fw:retro`, all `Destination: framework`, OPEN: IMP-051 (the guard reads a redirection
  after `git diff` as its operands), IMP-052 (commitlint's footer rule as an error), IMP-053
  (a read-only command's Level 1 findings handed over), IMP-054 (the framework's Makefile
  targets phony), IMP-055 (a delegated agent's writes outside the repository), IMP-056 (close
  a list-claim finding by scoping the claim).

## Follow-up
- The upgrade's working folder T, `/Users/seco/Projects/_upgrade-scratch/brew-manager`: kept
  until the framework closes its triage, then deleted by the user (decision C) → STATE #40.
- The OPEN IMPs v4.1.0 covers upstream (006, 008, 009, 010, 011, 013, 014, 016, 019, 021;
  026–028 in part): the Architect flags the duplicates after the harvest session; none is
  closed before (decision D) → STATE #41.
- `attribution.sessionUrl`'s effect is still to measure → STATE #42. At each checkpoint:
  `git log --format=%B 269cc9c.. | grep -cE 'https://claude\.ai/code/session_[0-9A-Za-z]'`,
  expected the count recorded here — 0 on 2026-11-07. The pattern needs a session id after
  the path, so a message that quotes the check does not count. A link means the key did not
  hold for that commit — a session that did not load the project's settings, most likely —:
  it is recorded here with its sha, and the expected count goes up by one — once git's
  trailer parser shows it as a trailer (`git log -1 --format='%(trailers:key=Claude-Session,valueonly)'
  <sha>`); a link only quoted in a message is recorded as a quote, not as the key failing. The entry closes
  at a commit the user confirms came from a Remote Control or cloud session, carrying
  `Co-Authored-By` and no link, the user's words quoted in that session's note. That the
  2026-10-19 commits came through Remote Control is inferred (local commits in the reflog;
  `remoteControlAtStartup` is on today, its value that day unrecorded).
- `/fw:lint-memory` after this wide rewrite of STATE (the core's table): the user runs it →
  STATE #43. Known for it: `components/mod-00-audit.md` still calls the off-by-one (#2) and
  the dry-run gap (#3) open, an Italian note left as written.
- Module 1's plain `git status` in Homebrew's repository under `--dry-run` → STATE #3, task 4:
  `git --no-optional-locks` keeps it read-only.
- The run header's two claims (`brew_manager.sh:496`, `:500`), found by the gate's last round
  → STATE #44, tasks 3–4, or a fix branch of their own through the gate.
- For the user: whether the technical rule **Commit attribution** — their words — should name
  its limit (the key holds only in a session that loads the project's settings) → STATE #42;
  `/fw:lint-memory` → STATE #43. Session-local, reported in the session and not tracked:
  round 1's reviewer's helper file in this session's scratch folder.

## Follow-up of 2026-11-08 — the user's answers and the memory lint

The user's answers to the five points the report left open (2026-11-08):
- **Commit attribution** (point 1): the rule gets its limit — "vale solo per le sessioni
  cloud e Remote Control", the user's words — in task 3's branch, not here, so CLAUDE.md is
  not reviewed again on this branch; in STATE, #42 stays as it is.
- **#34 and #36** (point 2): their declarations stay in STATE's *Decisions made*.
- **#44** (point 3): it waits for tasks 3–4.
- **`/fw:lint-memory`** (point 4): run read-only; what touches only the memory and adds no
  character to STATE is fixed on this branch, the rest goes to task 3's branch.
- **Round 1's helper file** in this session's scratch folder (point 5): the user deletes it.
- **STATE's size**, in the user's words: «a ogni checkpoint STATE va condensato, non solo
  esteso; obiettivo ≤ 7.000 caratteri per lasciare margine» — at every checkpoint STATE is
  condensed, not only extended, to 7,000 characters at most, a margin under the 8,000 the
  hook shows. Recorded here and not in STATE, as the user decided; STATE stands at 7,950.

### Work for task 3's branch
- CLAUDE.md's technical rule **Commit attribution** names its limit: the key acts only in
  cloud and Remote Control sessions (the user's words above). The decision record
  ([[decisions/2026-11-07-framework-architect-decisions]]) names a second one: only a
  session that loads the project's settings applies the key (STATE #42). Under task 3's
  gate.
- Task 3's checkpoint condenses STATE to 7,000 characters at most (the target above).

### `/fw:lint-memory`, read-only (2026-11-08)
The whole memory, the command's thirteen checks; then the fixes, memory only and none
adding a character to STATE (the user's bounds): `3409469`, `20b3657` and this record.
- Clean: 1 (STATE against git: the two local branches, `main` = `origin/main` = `0b127a9`,
  `v1.5.0` = VERSION, `origin/dev` merged), 8 (TREE.md = `tree`'s output, its non-breaking
  spaces aside), 9 (OPEN, Applied and Deferred agree in LEARNINGS, STATE and INDEX; the
  gate's accepted debt carries its reason, every entry its trigger), 10 (no setup marker),
  11 (commands, process targets, scripts), 12 (7,950 characters, all shown: the banner,
  then `## Caution & open issues`), 13 (every glob matches a tracked file; no `@` import).
- Not findings: the two `[[<session note>]]` (check 7) are placeholders in LEARNINGS'
  format comment; the four folder READMEs (check 4) are the template's guides, which
  `/fw:checkpoint` and `/fw:integrate` read.
- Fixed, stale claims and one contradiction (checks 2–3, `3409469`), the component notes
  read against the code: mod-00-audit's two defects still open (fixed in BM-04,
  `430f322`); core-brew-manager's `--yes` "on without a TTY" (false since BM-08c, and
  against its own section further down), "v1.3.0 released", "the rest of the core
  untested"; lib-selection's return codes "not load-bearing" and BM-08b's move of the
  source; lib-common's six wired modules (seven), its mod_02 example (gated since
  2026-07-21), "branch 6" (task 4) and "until BM-18" (task 7); mod-bk-brewfile's closed
  plan's branches (task 3); mod-01-health's writes without the `git status` index refresh
  (#3); INDEX's "12 modules, read-only or low/medium risk" (13, four on the gate's list).
- Fixed, missing links (checks 3 and 6, `3409469`, `20b3657`): 22 sessions that changed a
  component's code, absent from its note; INDEX without the v0.2.0 → v0.5.1 upgrade's plan;
  the decision of 2026-09-25 without its superseded line; IMP-005's trigger naming M4,
  without the fact that M4 went with roadmap-v2.
- A page to write (check 5): module 4 (`danger`, on the gate's list; #4 and #4b → task 7)
  has no note — components/README writes one at its first substantial change, task 7.
  Modules 10, mas and log go in task 3.
- Left for task 3's branch: nothing from the lint; the user's two items above.
- STATE: #43 closed, its trigger run; 7,911 characters after this record, all shown.

## Appendix A — STATE.md's *Caution & open issues* at `0b127a9`, verbatim
The section's text from the line after its title to its end (lines 416–877 of
`git show 0b127a9:.claude/memory/STATE.md`), Italian where it was written in Italian.

> **The 2.0.0 plan, 2026-10-07** ([[plans/v2-personal-tool]], [[decisions/2026-10-07-v2-plan]]): every open
> entry below now carries the TASK of that plan that closes it ("→ task N"). Its trigger is
> that task; the older triggers that name a branch of the pre-Dashboard plan, the
> Dashboard, the GUI or "the improvement's first task" are superseded. Entries that concern
> only a removed module close in **task 3**, after a grep proves the code is gone. Closed
> by decision on 2026-10-07: #17 and #28 (accepted), 4b-3. The evidence for every verdict,
> with file:line at `37b8db5`: [[sessions/2026-10-07-replan-v2-assessment]] (appendix C).
> **Framework upgrade v4.1.0, 2026-10-19**: this file is over its 8,000-character budget and
> NOT condensed on purpose — the first `/fw:checkpoint` after the upgrade's merge condenses it
> and works its list (#37); the upgrade's open threads are #34–#37, at the end of this section.
1. ~~**CLI posizionale + plist scheduler**~~ **CHIUSO (M2, BM-08b+BM-08c)**: il
   dispatch posizionale esiste (BM-08b) e gli agenti lo instradano davvero via
   `_resolve_cli` (BM-08c) — un agente esegue la selezione salvata, non più `go`.
   Un valore invalido è RIFIUTATO all'install (non più fallback-`go`). Il rischio
   "non-TTY punta un modulo mutante" è neutralizzato da #8 (consenso): senza
   `--yes` ogni `_ask` è negata. → residuo README SALDATO (2026-07-18,
   `docs/readme-v1.3.0`): anche lo scheduling per-modulo è ora documentato come
   reale, con l'invariante di consenso. Nessun residuo.
2. ~~**Off-by-one zsh (array 1-based)**~~ **CHIUSO**: adozione mod_00 (BM-04, col
   canale di selezione morto su tutte le release), weekday in las/bk + selezione
   Modify/Remove dello scheduler (BM-05a), contatore mod_09 (BM-05b). La regola
   by-convention resta in CLAUDE.md per il codice nuovo.
3. **DRY_RUN non uniforme**: ~~mod_05~~ (BM-02), ~~restore bk [3]/[3b]~~ (BM-03),
   ~~`brew install mas`~~ e ~~`brew update` incondizionato in mod_02~~ **CHIUSI**
   dal micro-task 2026-07-21 (`fix/dryrun-mod02-mas`): entrambi i comandi sono
   dietro il gate, che precede esecuzione E conferma (`--dry-run` batte `--yes`),
   dimostrato da `tests/test_dryrun_gates.zsh` con tripwire su mock brew.
   Chiuso anche l'**auto-update implicito di Homebrew** (era il difetto più
   diffuso, trovato dal gate: `brew` esegue `brew update --auto-update` da sé
   prima di `install|outdated|upgrade|bundle|release`, e il `--dry-run` DI BREW
   non lo ferma) → `HOMEBREW_NO_AUTO_UPDATE=1` esportato solo sotto `--dry-run`
   in `brew_manager.sh:160`, verificato end-to-end attraverso il re-exec di
   `script(1)`. RESIDUI APERTI, entrambi dichiarati onestamente nel registry:
   vedi #15 (mod_bk `[4]`) e #16 (mod_las `[c]` + `mkdir`).
   Debt inventory 2026-09-24: a full sweep of the mutating commands confirms the
   residual is exactly #15 + #16; mod_01's fixed `/tmp/brew_doctor.log` write also runs
   under --dry-run → #11. Closed with branches 9 and 10. **→ task 4** (2.0.0 plan): with every remaining mutating command gated and #15/#16 gone in task 3, it closes when module 1's `/tmp` write under `--dry-run` moves into the per-run dir (with #14).
3b. **Echo on data expands escapes** (LOW, BM-03 gate; scope measured by the debt
   inventory 2026-09-24): zsh's builtin `echo` expands `\e`/`\0NN`/`\x..` even
   without `-e`. The resolver instance was CLOSED in BM-08b (the MEDIUM `\065`→mod_05
   bypass; closed with parameter expansion, `${(@s:,:)}`/`${// /}`). The class is
   wide: 74 `echo "$var" |` sites in 14 module files (mostly
   grep/counting, but mod_00:53/70 validate a token on the expanded value), the five
   renderers `_ok/_warn/_err/_info/_item` are `echo -e "$msg"` (59 calls interpolate
   data), ~38 `echo -e` lines with data, mod_05 on both the dry-run and the real path,
   bk `_restore_agents` and [5] View, las [v]; mod_02:88 and mas:46 rely on the
   expansion (a palette inside `_item`); untrusted data also reaches the text of a
   consent question (mod_00:208 puts the app name into `_ask_danger`, rendered by
   `_ask` through `echo -e`); #26 (mod_03) is a live JSON corruption.
   Category (c) for the class, **deferrable ONLY if the JSON layer is built from
   structured data, never from the modules' screen output** (user condition,
   2026-09-25). Prevention = IMP-003, APPLIED in the CLAUDE.md Code conventions
   (2026-09-25, branch 2); the bk-restore half is fixed in
   branch 11, mod_03 in branch 8. → TRIGGER: the JSON layer reuses screen output, or
   new code copies the pattern. **→ after 2.0.0** (D10), except module 0's three sites on the install path (`mod_00:53/:70/:208`) → task 5. TRIGGER: the v2.0.0 release, or new code that copies the pattern.
4. ~~**mod_10 greedy**: scope globale + exit code non verificato~~ **RISOLTO** in
   BM-06. The "success printed anyway" pattern is wider than mod_02/mas (debt
   inventory 2026-09-24): mod_04, mod_05, mod_bk (dump, restore, `_restore_agents`,
   `_backup_agents`), mod_00, the las remove, mod_log → absorbed by #4b (4b-1),
   category (b). **→ task 7** (2.0.0 plan), with 4b-1.
4b. **Module outcomes are not reported** (LOW at BM-06; re-assessed by the debt
   inventory 2026-09-24). ~~The parent losing the child's exit in the ANSI strip~~
   CLOSED by the exit-code micro-task (2026-07-18: `99`→2, empty selection→1, a signal
   → its raw number, pinned by `tests/test_exit_codes.zsh`). OPEN, the modules' half,
   with a corrected cause: today's returns are not "noise" (the "mod_02 returns 1"
   sample is not reproducible) but UNIFORMLY 0 — 17 of 18 modules return 0 even with
   brew failing on every verb; only mod_10 returns 1, and the dispatcher never reads
   `$?` (`_run_status` is a pure function of the registries; `failed` is reserved,
   never assigned). The summary shows ✓ for failed, skipped and declined modules.
   Split: **4b-1** (truthful minimal outcomes) + **4b-2** (the full outcome contract:
   states, a `_mod_outcome` channel, "unmeasured" counters, an audit of the 18
   modules) → category **(b)**, the improvement's first task, designed with the JSON
   schema; **4b-3** (a non-zero process exit when a module fails: MINOR with a new
   code outside 1–31) → **(c)**, TRIGGER: the Dashboard must show launchd-run outcomes
   through LastExitStatus, or BM-17 is brought forward. Idiosyncrasy: Ctrl+C → exit 2
   (the raw signal number of macOS `script(1)`), indistinguishable from "unknown
   token". → [[sessions/2026-09-24-debt-inventory-pre-dashboard]] (section C).
   **2026-10-10**: module 1's developer-mode restore is a new mutating path with the same
   blind spot — a failed `brew developer off` or `brew update` is reported on screen, but
   the summary shows ✓ (gate INFO, task 2).
   **2.0.0 plan (2026-10-07)**: 4b-1 and a reduced 4b-2 (declined/skipped/failed/unmeasured states; no JSON schema, no `_mod_outcome` channel) → **task 7**, with the raw output on failure into the log. **4b-3 CLOSED** by decision: its triggers (the Dashboard's LastExitStatus, BM-17) are gone; it can come back as a MINOR.
5. ~~**Tag esistenti lightweight**~~ **CONVENZIONE IN VIGORE da v1.2.0**: `v1.2.0`
   è il primo tag di release **annotato** (i legacy v1.1.1/v1.1.2 restano
   lightweight, com'erano). Ogni release futura usa `git tag -a`. Nota:
   `v1.1.2-baseline` è annotato ed è un tag HELPER, escluso dal `git describe` del
   tool (vedi BM-07).
5b. ~~**VERSION and the tag must stay aligned**~~ → moved to "Decisioni prese" (a
   permanent, mechanised rule, not a debt — debt inventory 2026-09-24).
6. ~~`_install_agent_multi` codice morto~~ **RIMOSSA** in BM-07 (108 righe). Gli
   schedule multi-giorno NON fanno round-trip: vengono SALTATI con warning
   (restore bk, re-register, migrazione, recreate) invece di degradare a
   daily/singolo giorno. → TRIGGER: se si vuole davvero la feature multi-giorno,
   va riscritta da zero (serve un writer multi-intervallo anche nel restore).
   Debt inventory 2026-09-24: a feature, not a debt → category (c); re-evaluate in the
   Dashboard design (a multi-day picker would be an M4 feat, MINOR). **→ closes in task 3** of [[plans/v2-personal-tool]] (las and bk removed).
6b. **bk: the agents-restore preview does not mirror the restore, and the restore
   degrades silently** (INFO at BM-05a → LOW/MEDIUM, widened by the debt inventory
   2026-09-24): the preview mirrors the skip of an invalid `modules=` value, but it
   lists entries the restore skips (label shape, multi-day, and an empty label skipped
   SILENTLY); an unknown day or a missing schedule becomes a
   DAILY agent; an out-of-range time is clamped in the plist while the conf keeps the
   raw value; and on AUTHENTIC backups the minute clamp rejects the zero-padded
   "00"–"09" brew-manager itself writes (an agent at 9:05 is restored at 9:00,
   silently). README :390 and the code comment "the preview never lies" are false. →
   branch 11 (`fix/bk-agent-trust`: one verdict shared by preview and restore, in
   `lib/agents.sh`). **→ closes in task 3** of [[plans/v2-personal-tool]] (bk removed).
7. ~~The pre-existing git history was never scanned~~ **CLOSED** (2026-09-25, branch
   `chore/imp-022-sensitive-selection`): `gitleaks detect --redact --log-opts="--all
   -m"` with gitleaks 8.30.1 and the default rules (no `.gitleaks.toml`, no
   `.gitleaksignore`) scanned 155 commits = `git rev-list --all --count` (every commit
   of every ref, each of the 31 merges diffed against its parents) → **0 findings**.
   Every public ref (`git ls-remote origin`: main, dev, 6 tags) resolves to a local
   commit, so the published history is covered; nothing to rotate. The pre-commit
   hook keeps covering new commits. → [[sessions/2026-09-25-imp-022-and-history-scan]].
8. ~~**YES_MODE perso nel re-exec script(1)**~~ **CHIUSO (BM-08c)**, ma NON col fix
   "candidato" originale — che il gate ha bocciato come CRITICAL (avrebbe
   auto-confermato i default distruttivi senza --yes). Chiuso separando
   **NON_INTERACTIVE** (solo anti-blocco) da **YES_MODE** (solo --yes): una run
   non-TTY senza --yes ora NEGA ogni `_ask` (fail-closed, anche default `y`); un
   `BREW_MANAGER_YES` stale in env è sovrascritto. I LaunchAgent (--yes) eseguono
   la loro selezione. Decisione: [[2026-07-17-consent-vs-noninteractive]].
   INVARIANTE nuova: "non c'è tty" ≠ "consenso" — un modulo che muta SENZA passare
   per `_ask` NON è coperto (see #3: mod_02's `brew update` — the pointer said "#12",
   a wrong number since it was written in 98cdbff).
9. ~~Unknown CLI flags ignored silently~~ RESOLVED (0e48373). ~~A legacy plist with a
   corrupt `modules` → exit 2 on every run~~ CLOSED (BM-08c: the scheduler, the bk
   restore and its preview validate with `_selection_is_valid` and refuse or skip).
   RESIDUAL, OPEN and wider
   than recorded (debt inventory 2026-09-24): flag VALUES are not validated —
   `--upgrade=yes`/`Y`/`true` prints `[auto: yes]` and then declines (exit 0);
   `--upgrade=y` without --yes pre-answers nothing (README :166/:181 false); an EMPTY
   `--only=` counts as absent, so `go --only=` runs the WHOLE sequence, cleanup
   included, even on a tty (a destructive fail-open); a non-TTY run without a
   selection falls to the menu's default `go`. → branch 7 (`fix/cli-flag-values`),
   PATCH only with the recorded formulation: invalid values → 2, an empty `--only=` →
   1, an empty `--skip=` stays valid, `--adopt=` mirrors mod_00's grammar, no aliases,
   no consent from `--upgrade=y`. **→ task 6** (2.0.0 plan: `fix/cli-flag-values`; the PATCH-only wording no longer binds inside a MAJOR).
10. ~~`_ask` shows "(y/N)" even with default y; "Runs only after confirmation" holds
   only interactively~~ **CLOSED** (debt inventory 2026-09-24): the interactive
   "(y/N)" is true by design (Enter = No, an explicit `y` is needed,
   common.sh:438-440), and the mod_05 wording was already fixed in 2fcb1f8 (BM-02). The
   only residue (`[auto: <raw default>]` for a default other than y/n) goes into #9.
   The real GUI gap — all-or-nothing consent, no flags for default-n actions — is a
   design topic (BM-16), category (b). The GUI gap is CLOSED with the Dashboard; the `[auto: …]` residue → task 6.
11. **Fixed, predictable /tmp paths** (`/tmp/brew_*.log`, INFO at BM-04 → LOW;
   re-assessed 2026-09-24): mod_00, mod_01 (also under --dry-run) and mod_02 write
   fixed paths; O_TRUNC follows a symlink planted by another local user; 2 of the 5
   paths in the final `rm` (brew_manager.sh:564-565) are dead; kills and hangs leak
   the files; concurrent sessions (a GUI plus agents) delete each other's files and
   report false states. → branch 13 (`fix/per-run-paths`, with #25): a per-run
   `mktemp -d`. **→ task 4** (2.0.0 plan: the per-run dir owned by the parent; the `rm` list is now at `brew_manager.sh:645-646`).
12. **Re-register/repair widen a scoped agent to `go --yes`** (PRE-EXISTING, found by
   the BM-08c gate as LOW → MEDIUM proposed; the recorded "the listing under-reports; it
   does not change execution"
   is FALSE, and so is the code comment mod_las:125-127 — debt inventory
   2026-09-24): the plist reader keeps only the first `<string>` (`35` for two strings
   on one line); an argv the current grammar accepts (`--only=1 --yes`) is flagged as
   legacy-corrupt; the re-register writes the placeholder `modules=go`; and a Repair —
   or a plain [4] Modify that keeps the shown value `go` — rewrites the plist as `go
   --yes`. Reachable today only through a plist not written by brew-manager; directly
   reachable once the Dashboard or the BM-15 presets write agents with
   `--only`/`--skip`. README :417 is false. → branch 12 (`fix/las-agent-trust`): read
   the whole
   argv, validate it with the real grammar, drop the `go` placeholder. **→ closes in task 3** of [[plans/v2-personal-tool]] (las removed).
13. **Agent labels from untrusted data** (PRE-EXISTING, found by the BM-08c gate as
   LOW → LOW/MEDIUM, widened
   2026-09-24): no label validation on las's data paths (recreate, repair, Modify,
   Remove; the re-register only by shape) and no prefix enforcement in las or in the
   bk restore — a third-party LaunchAgent was overwritten on both paths in a sandbox,
   and a `../` label makes [5] Remove `rm` any writable `*.plist` outside
   ~/Library/LaunchAgents. → one predicate `^com\.m2ndlab\.brew-manager\.[A-Za-z0-9._-]+$`
   in the new sensitive `lib/agents.sh`: the bk half in branch 11, the las half in
   branch 12. **→ closes in task 3** of [[plans/v2-personal-tool]] (bk and las removed).
14. **`MODULE_DRYRUN` è la lista dei moduli che NON rispettano `--dry-run`**
   (BM-12). ~~`[2]=0` e `[mas]=0`~~ **CHIUSI** (micro-task 2026-07-21: entrambi
   ora `1`, gate dimostrato). Al loro posto `[bk]=0` e `[las]=0`, che erano `1`
   da sempre — **dichiarati, mai verificati**: il gate del micro-task ha
   confrontato l'INTERO registry col codice e li ha trovati falsi (#15, #16). Il
   summary li marca `⚠ ran anyway` — vero, e visibile a ogni dry-run.
   **Non flippare un valore a 1 senza fixare il modulo**: `test_run_summary.zsh`
   fallisce on the allow-list only — its grep half just proves the gate is MENTIONED
   (mod_bk mentions `BREW_MANAGER_DRY_RUN` 7 times, mod_las 6), so the behavioural
   proof is the tripwire tests (debt inventory 2026-09-24) — e si tornerebbe alla falsa
   attestazione "nothing changed". L'allow-list è bidirezionale: un `0` fuori
   lista fallisce, e una voce che non è più debito fallisce pure — quindi al fix
   di #15/#16 va aggiornata `_KNOWN_UNGATED` in `tests/test_run_summary.zsh`.
   → TRIGGER: fix di #15 o #16. Closed inside branches 9 and 10 of the debt cleanup
   (each flips its own entry). **→ the bk/las entries go in task 3** of [[plans/v2-personal-tool]] (`_KNOWN_UNGATED=(1)` with `[1]=0` there if module 1 still writes `/tmp` under `--dry-run`); the entry **closes in task 4** with #3. Before: for bk and las (their `MODULE_DRYRUN` entries and the `_KNOWN_UNGATED` allow-list entries go with them; the allow-list must then be empty and the test adjusted).
15. **`mod_bk [4] Check` esegue il Brewfile come DSL Ruby in una preview**
   (MEDIUM, gate 2026-07-21, PRE-ESISTENTE — accettato come debito, non fixato
   qui perché `mod_bk` è componente sensibile e merita task+review propri):
   `brew bundle check` (`mod_bk_brewfile.sh:499`/`:503`) valuta il contenuto del
   Brewfile, mentre lo stesso file documenta a `:96-99` perché la preview del
   restore lo legge STATICAMENTE ("even a check would execute code from a hostile
   Brewfile"). Richiede un `backups/Brewfile` manomesso (attaccante locale).
   Dichiarato con `MODULE_DRYRUN[bk]=0`. → TRIGGER: task dedicato su mod_bk (o
   BM-14 viste report): gatare `[4]` o riusare la lettura statica.
   Debt inventory 2026-09-24: also reachable WITHOUT a tty (bk reads its menu with a
   bare `read`, so a non-TTY caller writing the answer after the prompt reaches [4]).
   → branch 9 (`fix/bk-dryrun-check`): a static check only in dry-run; in wet mode
   `brew bundle check` behind a confirmation that names the Brewfile execution, with
   `HOMEBREW_NO_AUTO_UPDATE=1` (user decision). **→ closes in task 3** of [[plans/v2-personal-tool]] (bk removed).
16. **`mod_las [c]` cancella i log di audit senza gate + `mkdir` ungated**
   (MEDIUM+LOW, gate 2026-07-21, PRE-ESISTENTE — stesso motivo di #15):
   il case `c|C` fa `rm -f` su `agents_activity.log` e su tutti i
   `logs/agent_*.log` (`mod_las_scheduler.sh:817-819`) senza gate `--dry-run`,
   mentre `mod_log` gata gli `rm` equivalenti; l'audit trail degli agent è
   irreversibile. In più `mkdir -p "$HOME/Library/LaunchAgents"` (`:15`) gira
   anche in dry-run e anche sul path che esce subito in non-interattivo
   (`mod_bk:18` creates the tool's own `backups/`; the `mod_log:15` case is a no-op,
   see below).
   Dichiarato con `MODULE_DRYRUN[las]=0`. → TRIGGER: task dedicato su mod_las
   (o hardening #12/#13, che toccano lo stesso modulo).
   Debt inventory 2026-09-24: the "mkdir in mod_log:15" part is a no-op
   (brew_manager.sh:67-70 always creates `logs/`); the only mkdir outside the tool is
   `~/Library/LaunchAgents`; [c] has no confirmation in wet mode either. → branch 10
   (`fix/las-dryrun-clean`), with `_ask_danger` before [c] in wet mode (user decision). **→ closes in task 3** of [[plans/v2-personal-tool]] (las removed).
17. **`(( BREW_MANAGER_DRY_RUN ))` è aritmetica su una stringa d'ambiente**
   (INFO, gate 2026-07-21, PRE-ESISTENTE on every site — 27, see below): in zsh
   `y`/`yes`/`true` valgono "gate spento" e una stringa `NAME=value` in contesto
   aritmetico ESEGUE l'assegnazione. **Non raggiungibile oggi**: il core esporta
   `BREW_MANAGER_DRY_RUN` ∈ {0,1} da parsing dei flag (`brew_manager.sh:151`)
   prima di sorgere lib/ e modules/, e il figlio sotto `script(1)` ri-parsa gli
   stessi `"$@"`. Hardening a costo zero se si tocca la classe:
   `[[ "$BREW_MANAGER_DRY_RUN" == 1 ]]`. Nota collaterale: esportare a mano
   `BREW_MANAGER_DRY_RUN=1` SENZA passare `--dry-run` dà una run reale (l'export
   la sovrascrive). → TRIGGER: pass di hardening sui guard-rail, o prima
   segnalazione utente sul comportamento della variabile d'ambiente.
   Debt inventory 2026-09-24: 27 sites, not ~18 (22 on DRY_RUN — 4 of them negated,
   fail-open in the dangerous direction — plus 5 consent sites), 35 with the TUI_*
   sites; and with an existing array name a subscript EXECUTES a command substitution,
   not only an assignment. Category (c), **deferrable ONLY while the GUI invocation
   contract (b) imposes a clean environment — if the GUI passes environment variables,
   #17 returns to (a)** (user condition, 2026-09-25).
   **CLOSED (accepted) on 2026-10-07** by the 2.0.0 plan: after the removals 9 sites remain (5 on DRY_RUN, 4 consent sites), all unreachable because both parent and child overwrite the values from argv; the `TUI_*` sites are reachable only through an inherited RECORDING (#28). For a personal tool, whoever sets the environment already owns the shell. Reopen if a caller ever passes these variables.
- [[LEARNINGS]]: IMP-001 APPLICATA; **IMP-002** (checklist superficie del
  contratto per i test), **IMP-003** (mai echo su dati — rafforzata dal gate BM-09),
  **IMP-004** (chiudi la CLASSE: grep tutti i siti + verifica adversariale + re-gate),
  **IMP-005** (output di controllo terminale gata su `TUI_TTY`, non solo sul
  colore — origine BM-09), **IMP-006** (review-workflow su un git-range: isola gli
  agenti o vietali dal `checkout` — origine gate BM-10, `Destinazione: framework`)
  **IMP-007** (smoke moduli = selezione CLI posizionale, mai pipe sul prompt né
  `head` sull'output — origine BM-11, estesa da BM-12) e **IMP-008** (lente di gate
  "affermazioni, non solo azioni": un summary/badge che ASSERISCE una proprietà di
  sicurezza va verificato contro il comportamento reale — origine gate BM-12,
  `Destinazione: framework`), **IMP-009** (un test che asserisce l'ASSENZA di
  debito inverte l'incentivo: allow-list bidirezionale, non insieme vuoto),
  **IMP-010** (promuovere un fix locale a CLAIM globale allarga l'insieme da
  verificare oltre il diff) e **IMP-011** (gatare un comando esterno non basta:
  verifica se lo STRUMENTO lo riesegue da sé — origine auto-update di Homebrew;
  le tre `Destinazione: framework`, origine gate del micro-task dry-run
  2026-07-21) APERTE, propose-only, in attesa di decisione (retro periodica o su
  richiesta).
18. **`_module_14` collision** (latent; PRIORITY, a PREREQUISITE of M4 — decision D2):
   bk/las/mas are `_module_14`/`_module_15`/`_module_16` and the alphabetical glob
   (`brew_manager.sh:241`) sources `mod_bk_*` after `mod_14_*`, so bk's function
   replaces a future module 14 (likewise 15/16). Reproduced END-TO-END by the debt
   inventory (2026-09-24), with a corrected damage: under --yes without a tty bk does
   nothing, but the new module NEVER runs, the summary attests a state computed for the
   wrong module, the run HANGS without a tty (#21), and interactively bk's
   Restore/Delete menu appears. The visible headers `_section "15"`/`"16"` of las/mas
   belong to the same fix. README :565 ("any number is fine internally") is the trap.
   → branch 5 (`refactor/module-fn-names`, through the security gate — dispatch, bk,
   las): `_module_bk/las/mas`, a generic dispatch, a wiring guard test. Details:
   [[sessions/2026-09-24-debt-inventory-pre-dashboard]] (section B). **→ closes in task 3** of [[plans/v2-personal-tool]]: `_module_14/15/16` are bk/las/mas, all removed — the 2.0.0 task checks that no `_module_14`–`16` and no `bk|las|mas` dispatch case is left.
19. ~~**`lib/selection.sh` missing from the sensitive components**~~ **CLOSED**: IMP-022
   applied on 2026-09-25 (`90cb34c`) — it is in CLAUDE.md rule 8 and the technical
   rules, docs/03, docs/00, [[2026-07-12-componenti-sensibili]] and INDEX, and
   `/new-component` step 6 names every list.
20. ~~**`.gitignore` lacks three template patterns**~~ **CLOSED** (2026-09-26, `7ef025b`:
   `.vault-token` and `vault-keys.json` in the secrets block, `*.iml` with `.idea/`;
   `git check-ignore -v` now points at the repo's `.gitignore`) (LOW, out of the
   upgrade's scope,
   D10): `.vault-token` and `vault-keys.json` (the template's secrets block) and
   `*.iml` were never added at the graft; nothing of the kind is tracked
   (`git ls-files` empty). `*.log` is not debt (see Decisions). Done in branch 3 of the
   debt cleanup (`chore/gitignore-d10`).
21. **Non-TTY runs of bk/log hang forever** (HIGH for the GUI, MEDIUM today — found by
   the debt inventory 2026-09-24): `script(1)` forwards ONE EOF when stdin is closed;
   the bare `read`s of the bk/log menus consume it, then `_handle_log`'s own bare
   `read` (lib/log.sh:21, run at the end of EVERY session, ignoring YES and
   NONINTERACTIVE) waits forever — the LaunchAgent shape `bk --yes </dev/null` hangs,
   and the hung child survives its parent (reparented to PID 1). With stdin on an open
   pipe EVERY run waits at the log prompt; on a terminal `go --yes` stops there (README
   :162 false). [[lib-common]] recorded a false cause (fixed). → branch 6
   (`fix/headless-prompts`).
   **2026-09-27 — made reachable by branch 4, then its nature checked.** The gate of
   branch 4 (MEDIUM, upheld): with Homebrew now found under launchd, installed agents
   that select bk or log start and hang. The user asked whether that hang burns CPU.
   **It does not — an idle block** (the user's question; a code trace, a first sandbox
   run, then two independent refuters — [[sessions/2026-09-26-startup-brew-env]]): each
   menu reads once and an empty answer takes the default `n` and breaks
   (`mod_bk_brewfile.sh:286`/`:318`/`:655-659`, `mod_log_manager.sh:75`/`:89`/`:190-192`);
   the wait is the NEXT menu-driven read — `_handle_log` (lib/log.sh:21) for `bk` or
   `log` alone, the log menu (`mod_log_manager.sh:89`) for `bk,log`, which then never
   reaches the summary. Measured over 95 s in launchd's shape: the parent zsh (in
   `sigsuspend`) and the child zsh (in `read`) made 0 syscalls and 0 context switches;
   `script(1)` wakes only on its 30 s flush timer (1–2 syscalls, tens to hundreds of µs
   per tick; per Apple's `script.c` it stops polling stdin after forwarding the EOF);
   nothing grows after the first flush. Stopping the job (launchd kills the process
   group) leaves nothing; killing only the parent orphans `script` and the child, still
   idle. By launchd's one-instance-per-label model (inferred, not tested) a hung agent
   misses its own later runs, and instances do not pile up. Severity stays MEDIUM.
   **Decision (the user, 2026-09-27)**: the debt resolves with the removal of bk and log
   in 2.0.0 ([[decisions/2026-09-27-personal-terminal-tool]]); the same day's earlier
   choice (accept it and move branch 6 before #18) is superseded. **What survives the
   removal**: `_handle_log`'s bare `read` is not the log module — it runs at the end of
   every session and ignores `--yes`, so a terminal run with `--yes` stops at the log
   prompt and a run whose stdin is an open pipe waits there. → TRIGGER: the 2.0.0 task
   (bk and log go; re-check `_handle_log` then). **→ the bk/log half closes in task 3; the `_handle_log` residue (N-HANG-r) in task 4**, where the prompt goes (D1).
22. **mod_bk ignores NON_INTERACTIVE** (LOW-MEDIUM, 2026-09-24): its menu and the
   Delete selection read stdin directly and there is no guard like las:19, so a non-TTY
   run WITHOUT --yes, with piped answers, deleted the Brewfile and the agents bundle
   under a banner saying "every prompt is declined, nothing is modified". → branch 6,
   with #21. **→ closes in task 3** of [[plans/v2-personal-tool]] (bk removed).
23. ~~**Startup without Homebrew on PATH; the built-in installer**~~ **FIXED on
   `fix/startup-brew-env` (2026-09-27), CLOSED at its merge `bc114b9`, released in
   v1.5.0** — the PATH bootstrap
   (`/opt/homebrew`, then `/usr/local`, only when no brew executable is on PATH), exit
   **69** on every "Homebrew unavailable" way out (docs/04 contract), the installer
   never offered under `--dry-run` nor without a terminal, `_ask` default `n`, the
   download with timeouts and the installer's status read (`_brew_install`); the gate and
   three re-gate rounds; 49 checks in `tests/test_exit_codes.zsh` and a smoke under
   launchd's environment with the real brew. The post-fix run under a real launchd job
   was DROPPED by the user (the scope change: the agents go in 2.0.0). → TRIGGER for the
   residue: none — reopen only if a start outside a login shell fails to find Homebrew.
   The original entry (MEDIUM, 2026-09-24):
   no PATH bootstrap (`/opt/homebrew/bin`, `/usr/local/bin`) — under launchd or from a
   GUI launched by the Finder (PATH=/usr/bin:/bin:/usr/sbin:/sbin) the tool says
   "Homebrew is not installed" and exits **0**, so the installed LaunchAgents never run
   brew and look successful — **CONFIRMED under a REAL launchd job on 2026-09-26** (an
   on-demand job with a las agent's invocation environment: `runs = 1`, `last exit code =
   0`, the default PATH `/usr/bin:/bin:/usr/sbin:/sbin` with no override, "Homebrew is not
   installed" + "cannot continue" at EOF, stderr empty, no session log →
   [[sessions/2026-09-26-startup-brew-env]]); the installer (brew_manager.sh:185-235) ignores
   --dry-run, uses a bare `read` and runs before the `script(1)` re-exec. → branch 4,
   the first code branch: PATH bootstrap, the installer honours --dry-run and never
   starts without a terminal, a NEW exit code for the failed environment precondition
   added to the docs/04 contract (MINOR → v1.5.0). The reviewed procedure (preflight, run, reading,
   cleanup) is in [[plans/debt-cleanup-pre-dashboard]], section "Task 4 — the
   real-launchd verification".
24. **The las recreate fails on zero-padded minutes** (LOW, 2026-09-24): recreating a
   pending conf passes "00"–"09" to `_install_agent`, whose regex rejects them — the
   default agents at 09:00 included; an unknown day becomes a silent daily agent. →
   branch 12, with the parser shared through `lib/agents.sh`. **→ closes in task 3** of [[plans/v2-personal-tool]] (las removed).
25. **The child recomputes LOG_FILE** (LOW, 2026-09-24): it is computed in the parent
   and again in the re-executed child, so across a second boundary (3 of 32 real logs)
   or in the mktemp fallback (always) the banner, the summary and "[3] Delete" point to
   a different file than the one written ("Log deleted" while the log stays); two runs
   started in the same second share one file. → branch 13, with #11. **→ task 4** (2.0.0 plan; this is the inventory's "11-bis").
26. **mod_03 corrupts brew's JSON through echo** (MEDIUM, 2026-09-24): `echo` turns
   `\n` inside JSON strings into control characters, `json.load` fails silently
   (`2>/dev/null`) and every formula falls back to its own `brew info` — reproduced on
   a real 384 KB payload; the proof that echo breaks JSON. → branch 8
   (`fix/mod03-json`), the first application of IMP-003. **→ task 5** (2.0.0 plan: fixed in place, `printf '%s'` at `mod_03:82`; reproduced again on 2026-10-07 with a 384 KB payload).
27. **Agents on interactive-only modules do nothing and report done** (LOW,
   2026-09-24): the scheduler accepts, and even suggests, `bk`/`log`/`las`/`mas` as an
   agent selection; non-interactively their menus take the default n (las returns on
   purpose). Refuse them in `_install_agent` and the bk restore, or document it →
   TRIGGER: the improvement's first task (category (b)), with the outcome contract. **→ closes in task 3** of [[plans/v2-personal-tool]] (las removed: no agents).
28. **Handoff variables trusted from the environment on a fresh start** (INFO/LOW,
   2026-09-24): an inherited `BREW_MANAGER_RECORDING=1` skips the `script(1)` re-exec
   (no session log, while `_handle_log` names one) and lets TUI_*/NONINTERACTIVE come
   from the environment; `BREW_MANAGER_SCRIPT_DIR` is always accepted and can load
   `lib/` and `modules/` from another checkout. Not a privilege boundary → TRIGGER:
   the improvement's first task (category (b)), in the GUI invocation contract (a
   clean environment); related to #17 and #25.
   **CLOSED (accepted) on 2026-10-07** by the 2.0.0 plan: its GUI trigger is gone and it is not a privilege boundary; the cheap hardening (the child trusts RECORDING only with the LOG_FILE handoff) rides task 4.
29. **bk wet previews trigger Homebrew's auto-update** (INFO, 2026-09-24): `bundle` is
   one of Homebrew's auto-update commands, so the read-only `brew bundle dump`/`check`
   of [2]/[2b]/[4] may rewrite the index despite "no disk writes". → branch 9 (user
   decision: `HOMEBREW_NO_AUTO_UPDATE=1` on those calls). **→ closes in task 3** of [[plans/v2-personal-tool]] (bk removed).
30. **Module 1 leaves Homebrew in developer mode** (MEDIUM, found 2026-10-07 —
   [[sessions/2026-10-07-replan-v2-assessment]], appendix D, F3): `mod_01:32` runs `brew
   ruby --version`, a Homebrew DEVELOPER command (and its value is always blank:
   `--version` is not an option of `brew ruby`). Running a developer command as a
   non-developer turns developer mode on (`homebrew.devcmdrun = true`, Homebrew's
   `brew.sh`), and then `brew update` follows Homebrew's `main` branch instead of the
   release tags — this Mac is on `6.0.21-70-g2316567` with developer mode on (the cause is
   inferred; the call exists since v1.1.0 and runs under `--dry-run` too, so
   `MODULE_DRYRUN[1]=1` attests something false). `mod_01:33` also labels the last commit
   of Homebrew's code as "Last DB update". → **task 2** of [[plans/v2-personal-tool]]: a prevention test, a
   read-only detection, a restore with preview and confirmation (the user's precisions).
   **FIXED on `fix/homebrew-developer-mode` (2026-10-10), closes at its merge**: `brew ruby`
   gone (Ruby from `brew config`), the label fixed, `tests/test_homebrew_developer.zsh`, the
   detection and the confirmed restore in module 1 ([[mod-01-health]]). The cause on this Mac
   is moot: it was already back on stable 7.0.8 with developer mode off (2026-10-07 18:37,
   outside the session). → [[sessions/2026-10-10-homebrew-developer-mode]].
31. **Homebrew 6.0/7.0 compatibility of the remaining modules** (2026-10-07; appendix D of
   the assessment; the installed brew is 6.0.21, upstream 7.0.8): F1 module 10's detection
   never matched (it greps `auto_updates: true`; brew prints `(auto_updates)`), so its
   upgrade path never ran → the module is retired in **task 3** (D3); F2 brew's ask mode
   (6.0+) can add its own `[y/n]` after brew-manager's confirmation — module 0's adopt runs
   on the `script(1)` pty, even under `--yes` (D7); F4 module 12 never detects deprecated or
   disabled casks, module 11 matches loosely; F6 module 2's index age reads the wrong
   files (`api/internal/` since 6.0); F7 formulae from an untrusted tap drop silently out
   of module 4's list (its stderr is discarded); F8 `brew upgrade` quits running cask apps
   (6.0+, D8); F5/F11 stale texts ("Homebrew 4.x", "brew upgrade skips auto_updates",
   "Pinned formulae"); F9 module 3 shows the version in its description column; NEW-a
   module 2's tap age always says "updated". → **task 5** (F1 → task 3).
32. **The log prompt's `[3] Delete` lies** (NEW-L1, LOW, 2026-10-07, reproduced in a
   sandbox): it deletes the log while `script(1)` still holds it open; the parent's strip
   then fails and prints "log cleanup failed … raw log kept at <path>", which is false;
   with #25's mismatched paths the opposite happens ("Log deleted" while the log stays).
   → **task 4** (the prompt goes, D1).
33. **A stale cause and a wrong id in comments and docs/04** (NEW-b, INFO, 2026-10-07):
   `brew_manager.sh:533-534`/`:584` and `lib/common.sh:339-341` call the modules' returns
   "noise" until "BM-18"; the inventory found they are uniformly 0, and BM-18 is the
   doctor self-check of the old roadmap, not the return contract; docs/04:143-145 repeats
   the id. → **task 7**.
34. **`make lint` does not run** (2026-10-19, the user): shellcheck is absent — at the
   restore point too, the recipe unchanged — and it does not support zsh anyway (SC1071),
   while the project is all zsh. Options: remove the target (and `Bash(shellcheck:*)` with
   it); keep it with `--shell=bash` and motivated directives; accept that the static check
   is `zsh -n` alone (`make check`). → TRIGGER: the user decides after the upgrade's merge.
35. **The user's local permissions are wider than docs/04 claims** (the upgrade's gate, F2
   LOW + F3 INFO, pre-existing): `.claude/settings.local.json` allows `git checkout *`,
   `git tag *`, `gh repo *`, `git ls-remote *`, `make check *`, `make test *` — discards
   (`git checkout -- …`, `make check reset-task YES=1`), tags, forge writes with no prompt
   and, in auto mode, unseen by the classifier; docs/04:268-269 and :537 do not hold here.
   The file is the user's (U24, three rules already removed). → TRIGGER: the user narrows
   them (e.g. `gh repo view *`, `git tag -l *`, exact `make check`/`make test`, no
   `git checkout *`) or accepts them; [[sessions/2026-10-19-framework-upgrade-v1.2.0-to-v4.1.0]].
36. **The upgrade's commits carry a `Claude-Session:` URL trailer** (the gate, F6 INFO): the
   first in the repository's public history; docs/04 keeps external references out of
   shared history. → TRIGGER: the user decides before the push — keep and declare, or
   reword the local commits (that rewrites the reviewed tip `56d3b1a`: the gate runs again).
37. **The first `/fw:checkpoint` after the framework upgrade's merge** — the next deliverable
   (the user's decision): condense this file and work the list in
   [[sessions/2026-10-19-framework-upgrade-v1.2.0-to-v4.1.0]] (*Follow-up*) — task 2's
   acceptance run of 2026-10-10 and its two defects (→ tasks 7 and 4/5), STATE's
   frontmatter, #30 closed, the memory claims the upgrade made stale (the gate and language
   decisions, two decision notes, D1 superseded, the 2.0.0 plan's targets in docs/0N and "one
   lens", INDEX:197), task 8's gate status, the language of condensed entries; BEFORE it the
   user decides the form of the anchors that code and tests use for STATE entries (U23). →
   TRIGGER: the merge of `chore/framework-upgrade-v1.2.0-to-v4.1.0`.
- [[LEARNINGS]] (retro of the upgrade, 2026-09-24; OPEN, propose-only): **IMP-012**
  hooks-install vs linked worktrees; **IMP-013** the edge-case-4 rollback needs
  `FORCE_OVERWRITE=1`; **IMP-014** docs/05 delimiters without the promised legacy
  reader; **IMP-015** new slots invisible to the Step 4 grep; **IMP-016** a translation
  release vs name-cited section titles; **IMP-017** a written gate verdict for upgrades
  touching the baseline; **IMP-018** read the framework only via its tag, with `-C`;
  **IMP-019** `wip:` rejected by commitlint; **IMP-020** content-based memory
  invariant checks; **IMP-021** delegation briefs quote the user's decisions
  verbatim — all `Destination: framework`; ~~**IMP-022**~~ APPLIED (2026-09-25,
  `90cb34c`). Retro of branch 1 of the debt cleanup (2026-09-25; OPEN): **IMP-023**
  delegated sandbox runs must not leave processes behind; **IMP-024** brief delegated
  agents in the artifact language when their output will be persisted — both
  `Destination: framework`. Branch 2 (2026-09-25): IMP-002, 003, 004, 007 APPLIED
  (IMP-002/004 also `Destination: framework`), IMP-005 DEFERRED (cut by the user: the
  code already complies); retro: **IMP-025** (applying an IMP: map the proposal, run
  what the rule prescribes; `Destination: framework`), OPEN. Branch 3 (2026-09-26):
  **IMP-026** (command blocks for the user: self-contained, literal, no inline comments;
  `Destination: framework`), OPEN. Branch 4 (2026-09-27): **IMP-027** (the Bash deny patterns
  match heredoc bodies: write such content with the editor tools), **IMP-028** (a stalled
  gate lens is a hole: rerun it on the CURRENT diff), **IMP-029** (mutation checks also
  change HOW a unit fails) — all `Destination: framework`, OPEN. The 2.0.0 plan
  (2026-10-07): **IMP-030** (a path-based gate) and **IMP-031** (Homebrew's configuration
  is the user's) APPLIED. Task 2 (2026-10-10): **IMP-032** (a verification record reads the
  environment at that moment; `Destination: framework`), OPEN. The framework upgrade v4.1.0
  (2026-10-19): **IMP-033…IMP-049**, all `Destination: framework`, OPEN — the decisions at the
  periodic retrospective after the merge, with the OPEN IMPs v4.1.0 covers upstream.

## Appendix B — STATE.md's *Decisions made* and *Documentation debt* at `0b127a9`, verbatim
Each section's text from the line after its title (lines 316–371 and 374–413 of the same
file).

### Decisions made (not obvious from the code)
- Trunk-based su `main` (integrazione = stabile); `origin/dev` dormiente, non è
  l'integrazione → [[2026-07-12-trunk-based-su-main]].
- The security gate is PATH-BASED since IMP-030 (2026-10-07): one lens on a change to a
  path that deletes, installs, modifies Homebrew's configuration or decides what runs (a
  refuter only where the change widens what the path authorises); the paths in docs/03,
  the components that hold them in CLAUDE.md — mod_00, mod_04, mod_05, mod_10, mod_01 (from
  task 2), bk/las/log/mas until 2.0.0, `brew_manager.sh`, `lib/common.sh`,
  `lib/selection.sh` → [[2026-07-12-componenti-sensibili]].
- commitlint mantenuto benché il progetto non usi Node (npx risolve al volo, zero
  footprint nel repo); formattazione hook lasciata commentata (shfmt non installato).
- Language (since the framework v1.2.0 upgrade, 2026-09-24): artifacts in English
  (rule 9), interaction in Italian; the memory written in Italian before the upgrade is
  not translated (per-entry policy for the living files); STATE/LEARNINGS headings are
  frozen identifiers, mapped in CLAUDE.md →
  [[decisions/2026-09-24-language-rule-prospective]].
- `.gitignore`: the template's `*.log` pattern was omitted on purpose at the graft —
  brew's logs are already ignored through `logs/` and `brew_report_*.log` (user
  decision D10, 2026-09-24). It is not debt.
- ~~README not modified at the graft~~ **CLOSED as superseded** (2026-10-07, the 2.0.0 plan): README
  :531 already names the tooling. The original entry: the "managed with Claude Code" note remained an
  open option (Contributing or footer); README :516 already cites the tooling, so it
  is partly superseded → decided (yes/no, or closed as superseded) in branch 15 of
  the debt cleanup ([[plans/debt-cleanup-pre-dashboard]]).
- SLA di risposta (72h/7gg) RIMOSSI da SECURITY.md dall'utente a mano (commit
  9b7e874): la policy ora promette solo "as soon as reasonably possible". Il
  subject di quel commit è rimasto un placeholder, per scelta dell'utente:
  storia pushata, NON riscrivere.
- **Contratto pubblico di brew-manager** (criterio del MAJOR, in `docs/04`, deciso
  all'upgrade framework v1.0.0): flag CLI, grammatica di selezione, exit-code `0/1/2`,
  formato plist/LaunchAgent, e **identificatori di modulo CONGELATI** (numeri `0–13`/`go`/
  nomi speciali `bk/las/log/mas` — rinumerare/riassegnare/rinominare = MAJOR, nuovi moduli
  solo in append). Motivo: i numeri sono persistiti nei plist LaunchAgent sui Mac utenti
  (#12). L'exit-code runtime dei moduli (#4b) è FUORI dal contratto, in ingresso additivo
  con BM-18. → [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]].
- **VERSION and the release tag move together** (formerly Caution #5b — a permanent,
  mechanised rule, not a debt): `VERSION` and the tag are updated in the SAME commit,
  `[Unreleased]` moves under the new version, and `make version-check` fails on drift
  → [[2026-07-14-versione-fonte-unica]]. Applied for v1.5.0 (2026-10-07, `6815a5c`); next
  application: 2.0.0.
- **Debt cleanup before the Dashboard** (2026-09-25): the categories, the order, the
  new exit code for a failed environment precondition (MINOR → v1.5.0),
  `lib/agents.sh`, the bk [4] and las [c] wet-mode behaviour, and the conditions that
  keep #17 and #3b deferred → [[decisions/2026-09-25-debt-cleanup-pre-dashboard]].
  **Superseded in part on 2026-09-27** by the scope change below.
- **Scope change (2026-09-27)**: brew-manager becomes a **personal terminal tool for the
  maintenance of the user's Mac — no Dashboard**; **bk, las, the log module and mas will
  be removed in 2.0.0** (a later task; removing frozen module names is a MAJOR); the PATH
  fix of branch 4 stays; its launchd regression was dropped; #21 resolves with the
  removal → [[decisions/2026-09-27-personal-terminal-tool]]. Its open points are settled: v1.5.0
  was cut first (2026-10-07), and the re-plan is approved (next entry).
- **The 2.0.0 plan (2026-10-07)**: B1–B8 and D1–D11 as recommended — recording kept as
  corroboration without the end prompt, Ctrl+C → 130, module 10 retired, module 5 keeps `y`,
  removed names exit 2 with a hint, `HOMEBREW_NO_ASK` and `--no-quit` once verified on the
  installed brew, Homebrew 6.0+, #3b after 2.0.0, a path-based gate (IMP-030); the user's
  precisions: B2 never leaves Homebrew in developer mode, a Homebrew-configuration rule
  (IMP-031), F10 not planned → [[decisions/2026-10-07-v2-plan]].

### Documentation debt
- ~~README vs realtà di v1.2.0~~ **SALDATO** in BM-19 ristretto (7f7f90d): rimossi
  gli over-claim (CLI posizionale, scheduling per-modulo, esempi `./brew_manager.sh
  bk`), aggiornati i comportamenti (adozione, cleanup, restore, greedy, integrity),
  documentati `--version`/`-V` e SECURITY.md/VERSION/CHANGELOG.
- ~~Residuo BM-19: README da riaggiornare quando M2 avrebbe implementato CLI e
  scheduling per-modulo~~ **SALDATO** (2026-07-18, `docs/readme-v1.3.0` 9ceb69b):
  scheduling per-modulo documentato come reale (callout las riscritto), invariante
  fail-closed documentata, validazione restore agenti in bk. La CLI posizionale
  era già documentata da BM-19+BM-08b. → [[sessions/2026-07-18-readme-v1.3.0]].
- ~~README "Project structure": non cita SECURITY.md né i file del framework~~ e
  ~~"Adding a new module": promette CLI inesistente~~ — **voci STALE, già a posto**
  (verificato 2026-07-18 sul file reale: SECURITY.md e il tooling sono citati;
  la sezione moduli descrive il resolver reale). Chiuse.
- ~~`BREW_MANAGER_VERSION="1.1.0"` vs tag v1.1.2~~ **RISOLTO** in BM-07 (file
  VERSION + `make version-check`).
- **README and SECURITY.md vs the code** (registered by the upgrade assessment,
  2026-09-24, D2; widened by the debt inventory the same day): besides "Adding a new
  module" (four registries, not three; the key-set pin; the hand-written id lists; the
  `_module_14` trap) and "Project structure" (`lib/selection.sh`, `tests/`), a full
  re-read against the code found R2b–R13 and M3 — the log is per run, the prompt text is
  stale, a CLI selection is not "non-interactive" on a tty, the summary example is
  impossible, las [c] deletes more than stated, the dry-run and exit-status claims are
  too wide, mod_03 is not a single call, the helpers do NOT implement DRY_RUN, las has
  no `[!]` confirmation, mod_02 updates without one — and SECURITY.md :18-25/:73
  under-states the footprint and the network traffic. Full list:
  [[sessions/2026-09-24-debt-inventory-pre-dashboard]] (section E). Every fix branch
  rewrites its own section (rule 5); the residue goes in branch 15
  (`docs/readme-truth`), last. Scope change 2026-09-27: the items about bk, las, the log
  module and mas go with those modules in 2.0.0; the rest is re-planned. → TRIGGER: each
  branch of [[plans/v2-personal-tool]] rewrites its own section (rule 5); the residue (R4, R9–R11, R13,
  M3, SECURITY.md) in its task 8. Added by the framework upgrade's gate (F5, LOW, 2026-10-19):
  SECURITY.md:36-41 says secret scanning runs "on every commit" and sensitive changes get a
  security review, wider than v4.1.0's docs/03 declares (the hook's limits; the gate's
  scope) → task 8, narrowed to what holds.
- ~~**"Added in v1.5.0"**~~ **SETTLED** (2026-10-07): the user cut v1.5.0 first, so
  docs/04's "added in v1.5.0" is true; the CHANGELOG's "fixed before the next release"
  for the bk/log agent hang was replaced by a Known limitation in `[1.5.0]` (`6815a5c`).
- **README and SECURITY.md describe bk, las, the log module and mas** (the scope change,
  2026-09-27): true until they are removed. → TRIGGER: task 3 of [[plans/v2-personal-tool]] (rule 5: the
  removal and its docs in the same branch).

## Appendix C — the rest of STATE.md at `0b127a9`, verbatim
The status lines (lines 9–13), then *Progress*, *What exists now* and *Active branches*, each
from the line after its title (lines 16–223, 226–313 and 880–932 of the same file): with
appendices A and B, the whole file from its title on.

### The status lines
> Updated: 2026-10-19 | Last: **framework upgrade v1.2.0 → v4.1.0 done** (`chore/framework-upgrade-v1.2.0-to-v4.1.0`, process only): the core rules in `.claude/rules/fw-core.md`, CLAUDE.md = the answers the method reads + the technical rules, commands `/fw:…`, the boundary (guard, state-inject, pre-push), the memory's titles and labels in the method's English form; gate passed (reviewed tip `56d3b1a`: 0 C/H/M); 333 tests. Ready for integration (no tag). STATE not condensed on purpose: the first checkpoint after the merge does it (#37). → [[sessions/2026-10-19-framework-upgrade-v1.2.0-to-v4.1.0]] | Index: [[INDEX]]

> **Previous**: task 2 of the 2.0.0 plan (`fix/homebrew-developer-mode`) → INTEGRATED (merge `8a7e6a2`). Its status line, kept: **task 2 of the 2.0.0 plan done** (`fix/homebrew-developer-mode`): module 1 no longer runs `brew ruby` (a Homebrew developer command that turned developer mode on at every run since v1.1.0, also under `--dry-run`); a new suite keeps developer commands out of the code; module 1 reports developer mode read-only and offers to restore it (`brew developer off` + `brew update`, previewed under `--dry-run`, confirmed or `--yes`; the environment only reported); `[W]`; the one-lens gate (no C/H/M; 3 LOW + 7 INFO fixed or recorded); 333 tests. #30 FIXED (closes at the merge). Found: this Mac was already back on stable 7.0.8 with developer mode off (since 2026-10-07 18:37, outside the session), so the user's test sequence creates the condition on purpose. Task 1 INTEGRATED (merge `f232f12`). Ready for integration (no tag). → [[sessions/2026-10-10-homebrew-developer-mode]] | Index: [[INDEX]]

> **Previous**: task 1 of the 2.0.0 plan (`chore/replan-v2`: the v1.5.0 reconciliation, the plan and decisions, the triage by decision, IMP-030 and IMP-031) → INTEGRATED (merge `f232f12`) → [[sessions/2026-10-07-replan-v2-assessment]].

### Progress
- [x] Progetto maturo e rilasciato: v1.1.2 su `main` (TUI zsh per audit/cleanup di
  Homebrew, 14 moduli standard + 4 speciali, LaunchAgent scheduler, backup Brewfile).
- [x] Innesto del claude-code-framework v0.2.0 — branch `chore/innesto-framework`
  (questo checkpoint). Memoria inizializzata dall'assessment, non da template vuoto.
- [x] Integrazione del branch di innesto in `main` — merge 7893f87 eseguito
  dall'utente; tag baseline `v1.1.2-baseline` creato.
- [x] ~~Roadmap v2~~ **SUPERSEDED on 2026-10-07** by the 2.0.0 plan [[plans/v2-personal-tool]] (BM-17 goes with las; BM-15/16/18 are post-2.0.0 candidates). The original entry: Roadmap v2 ([[plans/roadmap-v2]]): BM-01…BM-20 in ordine di dipendenza —
  M1 copre la bonifica dei difetti in "Attenzione". Un task per volta, ok utente
  tra un task e il successivo.
  - [x] BM-01 `make check`/`make lint` — INTEGRATO in main (merge 3d3af76,
    pushato; branch eliminato). Nota: `check` esisteva già dall'innesto; lint è
    ADVISORY ([[2026-07-12-shellcheck-advisory]]).
  - [x] BM-02 fix --dry-run in mod_05_cleanup — INTEGRATO in main (merge 3ae5d41).
  - [x] Micro-task (fuori roadmap, richiesto dall'utente): parser rifiuta i flag
    ignoti, inclusi lookalike Unicode — branch `fix/parser-unknown-flags`,
    commit 0e48373, gate passato, in attesa di integrazione. Chiude Attenzione #9.
  - [x] Micro-task parser: INTEGRATO in main (merge fafa9da). IMP-001 applicata
    (commit ae6cfb6 su questo branch).
  - [x] BM-03: INTEGRATO in main (merge 12dada6).
  - [x] BM-04: INTEGRATO in main (merge 22e0c52).
  - [x] BM-05a: INTEGRATO in main (merge 5d51b14).
  - [x] BM-05b: INTEGRATO in main (merge d555f54).
  - [x] BM-06: INTEGRATO in main (merge cb234fd).
  - [x] BM-07 versione a fonte unica + codice morto — INTEGRATO in main
    (commit 3a35309 in main, verificato 2026-07-18; la voce era stale).
  - [x] **M1 CHIUSO** (BM-01…BM-07): tutti i difetti dell'assessment sanati.
  - [x] Decisione utente 2026-07-14: **si rilascia v1.2.0 ORA** (strada A), M2 dopo.
  - [x] BM-19 RISTRETTO: INTEGRATO in main (merge 3e7b462).
  - [x] Release v1.2.0 **RILASCIATA** (2026-07-17): merge `c5dc3a5` in main, tag
    **annotato** `v1.2.0` (→ c5dc3a5) creato e pushato; `origin/main == main`, tag
    su origin; branch `chore/release-v1.2.0` eliminato; `make version-check` verde.
    Merge/tag/push eseguiti dall'utente.
  - [x] Via libera esplicita dell'utente al gate ⛔ pre-M2 (2026-07-17): M2 avviato.
  - [x] **M2 — resolver di selezione (BM-08a/b/c): CHIUSO.** Chiude Attenzione #1
    (CLI posizionali + plist scheduler), #8 (consenso) e #9 (grammatica agenti).
    - [x] **BM-08a** estrazione `_resolve_selection` (parità pura) — INTEGRATO in
      main (merge `f1e1029`). [[2026-07-17-selection-resolver-contract]].
    - [x] **BM-08b** dispatch posizionale + `--only`/`--skip` — INTEGRATO in main
      (merge `3ac3f63`). 2 MEDIUM fail-open del tokenizer fixati.
      → [[sessions/2026-07-17-bm08b-positional-dispatch]].
    - [x] **BM-08c** agenti attraverso il resolver + consenso fail-closed — branch
      `fix/agent-selection`, commit `7f4f218` (NON_INTERACTIVE≠consenso) +
      `cd110d4` (scheduler refuse) + `d1a5e2b` (bk refuse). 96 test (87 selection +
      9 guardrails). **Gate + RE-gate PASSATI**: il 1° fix #8 introdusse un
      **CRITICAL** (auto-conferma di cleanup distruttivo senza --yes) → branch
      resettato e rifatto col fix corretto (separare NON_INTERACTIVE da YES_MODE,
      [[2026-07-17-consent-vs-noninteractive]]); re-gate confermò corretto+completo
      salvo il gemello bk (fixato). INTEGRATO in main (merge `b929a23`,
      branch eliminato). → [[sessions/2026-07-17-bm08c-agent-selection]].
  - [x] Upgrade framework v0.2.0 → v0.5.1: INTEGRATO in main (merge `45bf4bc`,
    branch eliminato). → [[sessions/2026-07-17-framework-upgrade-v0.2-to-v0.5.1]].
  - [x] **README ↔ realtà di v1.3.0** (2026-07-18, task 1 pre-release): scheduler
    per-modulo e invariante fail-closed documentati, 2 claim corretti perché
    smentiti dalla verifica dal vivo (exit del parent, default `y` di mod_05 sotto
    `--yes`). INTEGRATO in main (merge `56cf64d`).
    → [[sessions/2026-07-18-readme-v1.3.0]].
  - [x] **Micro-task exit-code propagation** (2026-07-18, inserito dall'utente
    pre-release): il parent propaga l'rc del figlio attraverso script(1)
    (`_run_rc` prima della strip ANSI) — `99`→2, selezione vuota→1, segnale→
    numero grezzo; strip fallita = WARNING, rc invariato. Scope deciso
    dall'utente: SOLO metà parent di #4b (la metà moduli → BM-18). Gate
    adversariale passato (0 C/H/M; 2 LOW + 4 INFO applicati). Test end-to-end
    nuovi (102 totali). README: claim non-zero RIPRISTINATO (ora vero). Branch
    `fix/exit-code-propagation` (4cef18c+a6d1be9+a3a4ad1), in attesa di
    integrazione. → [[sessions/2026-07-18-exit-code-propagation]].
  - [x] Micro-task exit-code: INTEGRATO in main (merge `1fa521a`, branch
    eliminato).
  - [x] **Release v1.3.0 RILASCIATA** (2026-07-18): merge `c6c80c0` in main,
    tag **annotato** `v1.3.0` (→ c6c80c0) creato e pushato; `main ==
    origin/main`; branch `chore/release-v1.3.0` eliminato; `make
    version-check` verde. Bump MINOR (feat BM-08b nel set); verificata da
    clone pulito prima del rilascio (version-check + 102 test + `--version`).
    Merge/tag/push eseguiti dall'utente.
    → [[sessions/2026-07-18-release-v1.3.0]].
  - [x] **M3 — TUI bella + funzionale (BM-09…BM-12): COMPLETA e INTEGRATA in main**
    (BM-12 mergiato in `21c956b`); resta da fare la release v1.4.0, che
    impacchetterà i quattro task.
    - [x] **BM-09** fondazione TUI in `lib/common.sh` — branch
      `feat/tui-foundation` (feat `bab07d0` + fix `b2d7b62` + docs `910d551`).
      Rendering capability-aware (detection colore/Unicode, handoff parent→child
      come NON_INTERACTIVE, palette semantica, degradazione a ASCII puro alla
      fonte, primitivi `_box`/`_repeat`/`_pad`/`_clear`); 0 moduli modificati;
      escape grezzi → palette (NO_COLOR pulito ovunque). Guard-rail
      byte-identici. **Gate adversariale PASSATO** (6 lenti + verifica
      per-finding): 1 LOW fixato (precedenza `LC_ALL` in `_tui_unicode`) + 1
      hardening (echo-on-data in `_box`, IMP-003), 5 refutati; consent-invariance
      e correctness-regression puliti. `tests/test_capabilities.zsh` (30 check,
      e2e "pipato = zero ANSI"); suite 132 verde. **INTEGRATO in main** (merge
      `5867137`, branch `feat/tui-foundation` eliminato).
      → [[sessions/2026-07-19-bm09-tui-foundation]].
    - [x] **BM-10** badge di rischio `[RO]`/`[W]`/`[!]` + cornici di conferma
      distruttiva — branch `feat/risk-badges` (6 commit: `985ffd4` piano +
      `bb520a9`+`60a1969`+`03a4f33`+`5b52e02`+`baaf11b`). `MODULE_RISK` (single
      source of truth, classificazione verificata adversarialmente: raise=0) +
      `_risk_badge`/`_risk_caption`/`_about_risk` (renderer puri, palette BM-09) +
      `_ask_danger` (box `C_DANGER` → `_ask` INTATTO, consenso byte-identico). Badge
      nel menu (+legenda) e nei 18 About; 9 cornici distruttive (00/04/05/10/bk×3/
      mas×2); `las` escluso (nessun `_ask` — flusso a menu; sarebbe cambio di
      consenso). `mod_00`=`[!]` (adotta), non `[RO]` del mockup. Presentazione pura,
      contratto pubblico intatto. **Gate adversariale PASSATO** (5 lenti, 0 finding).
      33+5 test → 170 verdi. **INTEGRATO in main** (merge `2dd1f7c`, branch
      eliminato). → [[sessions/2026-07-20-bm10-risk-badges]].
    - [x] **BM-11** banner + redesign menu — branch `feat/menu-redesign` (3 commit:
      `597281e` registry `MODULE_NAME`+test, `27acf1e` banner+menu, `6b7df8b`
      README). Mockup a 2 varianti proposti PRIMA del codice (richiesta utente) →
      decisione: **flat + footer 3 righe**. Card `badge(4)·id(3)·nome(17)·
      desc(≤46)` ≤78 col, cap pinnati da `tests/test_menu_registry.zsh` (8 check);
      `_header_main` rimossa da common.sh (solo-rimozione). Presentazione pura,
      contratto intatto. **Gate PASSATO** (0 finding). **178 test verdi**.
      **In attesa di integrazione** (bump MINOR).
      → [[sessions/2026-07-20-bm11-menu-redesign]].
    - [x] **BM-12** spinner + summary di sessione — branch `feat/progress-summary`
      (5 commit: `5968904` spinner+renderer, `7adcc20` cablaggio summary,
      `d84b651`+`73f905c` README, `13dc359` fix del gate). Mockup prima del codice
      → decisione utente: **summary variante B (completa) + spinner sui soli 2
      siti già cablati** (mod_01/mod_02). `_spinner` gata su `TUI_TTY` — era
      **morto in pratica** su RECORDING (la TUI gira sempre sotto script(1)) —
      con frame Unicode/ASCII, secondi da `$SECONDS` e rc del figlio propagato;
      summary con righe di esito per POSIZIONE (ripetizioni ok), stat, riga disco
      e footer. **Gate adversariale a 2 lenti: comportamento pulito, ma 4 difetti
      di VERITÀ** (vedi Attenzione #14) tutti FIXATI in `13dc359`; test 42→70
      (**suite 248** — la vecchia voce «247» era imprecisa di 1, misurato su main
      il 2026-07-21). **INTEGRATO in main** (merge `21c956b`, branch eliminato).
      → [[sessions/2026-07-21-bm12-progress-summary]].
  - [x] **Micro-task `--dry-run` mod_02 + mas** (2026-07-21, fuori roadmap,
    strada B decisa dall'utente dopo l'integrazione di BM-12): branch
    `fix/dryrun-mod02-mas`, 8 commit. `brew update` (mod_02) e `brew install mas`
    ora gatati — il gate precede esecuzione E conferma, quindi `--dry-run` batte
    `--yes`; preview con tabella repository + età della cache API. **Gate
    adversariale a 2 lenti: 0 finding sul codice nuovo, ma l'AFFERMAZIONE globale
    del branch REFUTATA** (4 difetti pre-esistenti che il branch attestava come
    verificati → Attenzione #3, #14, #15, #16). Via di mezzo decisa dall'utente:
    `HOMEBREW_NO_AUTO_UPDATE=1` sotto dry-run (una riga, chiude l'HIGH ovunque) +
    `[bk]`/`[las]` dichiarati 0 + allow-list al posto dell'invariante tautologica
    + README ristretto al vero. Nuovo `tests/test_dryrun_gates.zsh` (18 check:
    tripwire su mock brew con controlli "denti" in wet, e2e dell'auto-update
    attraverso `script(1)`); **suite 268**. **INTEGRATO in main** (merge
    `dc47ae4`, branch eliminato). → [[sessions/2026-07-21-dryrun-mod02-mas]].
  - [x] **Release v1.4.0 RILASCIATA** (2026-07-23): merge `ab45323` in main, tag
    **annotato** `v1.4.0` (oggetto `d4901b3` → commit `ab45323`) creato e pushato;
    `main == origin/main`; `make version-check` verde; branch
    `chore/release-v1.4.0` eliminato. Merge/tag/push eseguiti dall'utente. Bump
    **MINOR** (13 `feat` nel set `v1.3.0..main`): impacchetta tutta M3 (BM-09→12) +
    il micro-task dry-run. CHANGELOG `[1.4.0]` con **Known limitations** onesta per
    #15/#16 (**decisione utente: rilascia ORA col debito dichiarato**, scartate le
    opzioni "chiudi prima"). 268 test verdi. → [[sessions/2026-07-23-release-v1.4.0]].
- [x] **Upgrade framework v0.5.1 → v1.0.0** (2026-07-19, fuori roadmap, solo
  processo): procedura SETUP formale, attraversa la 1.0. 4 file riconciliati (docs/04,
  lint-memory, CLAUDE.md, scripts/README) + retrofit del pin; contratto pubblico di brew
  compilato in docs/04 (moduli CONGELATI, decisione utente); invariante memoria VUOTA;
  132 test verdi. **INTEGRATO in main** (merge `126bc7d`, pushato; bump "nessun tag").
  → [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]].
- [x] **Framework upgrade v1.0.0 → v1.2.0** (2026-09-24, out of roadmap, process only;
  the THIRD upgrade of the graft, a jump decided mid-way: a v1.1.0 assessment was
  superseded before any file was touched). FASE 1 read-only multi-agent assessment →
  user decisions D1–D14 → FASE 2 on `chore/framework-upgrade-v1.0.0-to-v1.2.0`:
  13 task commits, hooks reinstalled and proven (gitleaks blocks, commitlint rejects),
  translation fidelity reviewed adversarially. Stale claims corrected in a separate
  Level-1 commit; security gate not applicable (verdict in the note). 268 tests green.
  **INTEGRATED into main** (merge `0725ae6`, pushed; no tag). →
  [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] ·
  [[plans/framework-upgrade-v1.0.0-to-v1.2.0]].
- [x] **Framework upgrade v1.2.0 → v4.1.0** (2026-10-19, process only; the FOURTH upgrade,
  one jump): FERMATA 1 read-only assessment → the user's decisions U1–U24 → 11 task
  commits on `chore/framework-upgrade-v1.2.0-to-v4.1.0`; FERMATA 2: 131 answers verified,
  0 lost; the gate on the boundary passed (reviewed tip `56d3b1a`). Ready for the user's
  integration (no tag). → [[sessions/2026-10-19-framework-upgrade-v1.2.0-to-v4.1.0]] ·
  [[plans/framework-upgrade-v1.2.0-to-v4.1.0]] · [[decisions/2026-10-19-framework-upgrade-v4.1.0]].
- [x] **Debt cleanup before the Dashboard** — **CLOSED on 2026-10-07, superseded by [[plans/v2-personal-tool]]** (branches 1–4 and the v1.5.0 release done; tasks 5–15 re-planned there). It was SUSPENDED by the scope change of
  2026-09-27** (no Dashboard; bk/las/log/mas removed in 2.0.0 →
  [[decisions/2026-09-27-personal-terminal-tool]]): branches 1–4 done, tasks 5–16
  re-planned with the user before anything else starts. (From 2026-09-25; decided by the user after
  a read-only multi-agent inventory → [[sessions/2026-09-24-debt-inventory-pre-dashboard]]):
  16 branches in order ([[plans/debt-cleanup-pre-dashboard]]; decisions
  [[decisions/2026-09-25-debt-cleanup-pre-dashboard]]), one at a time, the security
  gate where marked, a printed /integrate after each; it ends with release **v1.5.0**.
  - [x] Branch 1 `chore/imp-022-sensitive-selection`: inventory persisted (`6b1e5f6`),
    plan and decisions (`aa54a51`), IMP-022 applied (`90cb34c`), #7 closed
    (`5fa7159`), Level-1 memory corrections at the checkpoint (`2ef3c21`).
    **INTEGRATED** (merge `73bc5ee`; no tag). →
    [[sessions/2026-09-25-imp-022-and-history-scan]].
  - [x] Branch 2 `chore/apply-project-imps`: IMP-003 (`a59d5eb`), IMP-004 (`a7f309f`),
    IMP-007 (`225cadd`), IMP-002 (`53d4827`), the adversarial review's fixes
    (`36aa1b2`), checkpoint `3d36cf4`; IMP-005 deferred. **INTEGRATED** (merge
    `9e4f2b4`; no tag). → [[sessions/2026-09-25-apply-project-imps]].
  - [x] Branch 3 `chore/gitignore-d10`: the three template patterns (`7ef025b`), the
    IMP-002 hand-over and the reviewed real-launchd verification plan for branch 4
    (memory), checkpoint. **INTEGRATED** (merge `050ea6d`; no tag). →
    [[sessions/2026-09-26-gitignore-and-launchd-plan]].
  - [x] Branch 4 `fix/startup-brew-env` (N1 + 4b-0, #23; [[plans/fix-startup-brew-env]]):
    the pre-fix run under a REAL launchd job CONFIRMED #23 (2026-09-26); the PATH
    bootstrap (`c277e20`), exit 69 and the installer only at a terminal (`ae022d9`,
    `feat` → MINOR), the contract and docs (`df8c0ec`), the CHANGELOG (`b1c78f6`); the
    docs/03 gate (two runs of five lenses) and three IMP-004 re-gate rounds, each finding
    challenged by a refuter — no CRITICAL/HIGH, the upheld LOW/INFO fixed with RED first
    (`b34e719` `1c6105d` `45c5fd2` `3657cc3` `1317307` `b7b56e7` `f68d114` `3c1f76c`
    `ec6da37`); the post-fix launchd regression DROPPED by the user (scope change); 311
    tests. **INTEGRATED** (merge `bc114b9`; no tag). → [[sessions/2026-09-26-startup-brew-env]].
  - [x] **Release v1.5.0 RELEASED** (merge `37b8db5`, annotated tag `v1.5.0` → object
    `deb8f61`, pushed by the user; `make version-check` green). Task 16 of the old plan, brought forward by the user on
    2026-10-07, before the re-plan): `chore/release-v1.5.0`, `6815a5c` (VERSION 1.5.0,
    CHANGELOG `[1.5.0]` with Deprecated and Known limitations); version-check proven in a
    clone. → [[sessions/2026-10-07-release-v1.5.0]].
- [ ] **brew-manager 2.0.0, a personal terminal tool** (approved 2026-10-07):
  [[plans/v2-personal-tool]] — B1 `chore/replan-v2` (INTEGRATED, merge `f232f12`) → B2 `fix/homebrew-developer-mode` (done, ready for integration) → B3 remove
  bk/las/log/mas and module 10 (MAJOR) → B4 session log → B5 Homebrew 6/7 compatibility →
  B6 flag values → B7 module outcomes → B8 release v2.0.0. Decisions:
  [[decisions/2026-10-07-v2-plan]].

### What exists now
- Albero directory: vedi [[TREE]].
- `brew_manager.sh` — entry point TUI, stabile; dispatch, parsing flag, recording
  sessione via script(1). Selezione da CLI (posizionale + `--only`/`--skip`,
  BM-08b) o dal menu interattivo. Dal **BM-11** banner flat (brand line
  right-aligned, Unicode-gated) e menu a card allineate con helper LOCALI
  `_menu_row`/`_menu_section`; summary con `MODULE_NAME`; help del menu compresso
  in footer 3 righe. Dal **BM-12** il dispatch traccia stato+durata per POSIZIONE
  (`RUN_STATUS`/`RUN_SECS`) e il summary di fine sessione rende righe di esito,
  stat, delta disco e footer identità. Dal **micro-task dry-run** (2026-07-21)
  esporta `HOMEBREW_NO_AUTO_UPDATE=1` SOLO sotto `--dry-run` (riga 160): senza,
  brew rieseguiva `brew update` da sé prima di `outdated`/`upgrade`/`bundle` e
  una preview riscriveva comunque l'indice. Since **branch 4** (2026-09-27) it finds
  Homebrew by itself when PATH lacks it (`_brew_bootstrap_path`: a brew executable on
  PATH, else `/opt/homebrew`, then `/usr/local`), exits **69** when Homebrew is
  unavailable (the exit order: `--version` 0 → unknown flag 2 → Homebrew 69 → selection
  2/1), and offers the installer only to a person at a terminal (`_brew_install`). Vedi [[core-brew-manager]].
- `lib/common.sh` + `lib/log.sh` — infrastruttura TUI e guard-rail condivisi
  (`_ask`, `_read_choice`, YES_MODE, DRY_RUN). Dal **BM-09** rendering
  capability-aware: detection colore/Unicode + handoff `TUI_{LEVEL,UNICODE,TTY}`,
  palette semantica (degrada a ASCII puro su pipe/NO_COLOR), primitivi
  `_box`/`_clear`. Dal **BM-10** i renderer di rischio `_risk_badge`/`_risk_caption`
  (puri) e `_ask_danger` (box `C_DANGER` → `_ask` INTATTO — presentazione, consenso
  invariato). Dal **BM-11** `_header_main` RIMOSSA (orfana dopo il banner flat del
  core — igiene codice morto). Dal **BM-12** `_spinner` gata su `TUI_TTY` (era
  morto-in-pratica su RECORDING) e ritorna l'rc del figlio, più i renderer del
  summary `_run_glyph`/`_fmt_secs`/`_fmt_kb`/`_fmt_kb_or_na`/`_du_kb` (puri;
  `_du_kb` valida al bordo e ritorna VUOTO, mai 0). Vedi [[lib-common]].
- `lib/selection.sh` (BM-08a/b) — registry `MODULE_DESC`/`MODULE_IDS` +
  `_resolve_selection` (lenient) + `_resolve_cli`/`_collect_module_tokens`
  (stretto, per la CLI); infrastruttura di dispatch condivisa (sensibile). Dal
  **BM-10** anche `MODULE_RISK` (id→ro/write/danger, single source of truth del
  badge, presentazione — NON alimenta il resolver) + `_about_risk`. Dal **BM-11**
  `MODULE_NAME` (nome breve da menu, presentation-only) e testi `MODULE_DESC` da
  sottotitolo (≤46 col ASCII; le CHIAVI restano il contratto congelato). Dal
  **BM-12** `MODULE_DRYRUN` (id→1 se una run `--dry-run` non cambia NULLA
  eseguendo il modulo): dal micro-task 2026-07-21 `[2]`/`[mas]` sono 1 (gate
  dimostrato) e `[bk]`/`[las]` 0 (dichiarati onestamente, #15/#16). Vedi
  [[lib-selection]].
- 14 moduli standard `mod_00`–`mod_13` (sequenza `go`) + 4 speciali `bk`/`las`/
  `log`/`mas` (per nome). 8 read-only modules (module 1 is `write` since 2026-10-10: its developer-mode restore); mutating: 00, 01, 02, 04, 05, 10, bk,
  las, log, mas. Module 1's note: [[mod-01-health]]. Note dei sensibili: [[mod-00-audit]], [[mod-05-cleanup]],
  [[mod-bk-brewfile]], [[mod-las-scheduler]].
- The `.claude/` process framework (rules, docs, commands, memory), CLAUDE.md, Makefile,
  git hooks (gitleaks + commitlint + the pre-push push boundary), CHANGELOG.md. **Method at
  framework v4.1.0** (from v1.2.0, 2026-10-19, on its branch until the merge): the core in
  `.claude/rules/fw-core.md` (loaded at every launch), CLAUDE.md = *The answers the method
  reads* (brew's public contract, sensitive components as code paths, branches, merge …) +
  the technical rules; commands `/fw:…`; the PreToolUse guard and the SessionStart
  injection (`scripts/state-inject.sh`) wired in `settings.json`; the memory's titles and
  labels in the method's English form, the content as written. Provenance pin
  `.claude/framework-version` at v4.1.0 / `18c04a1…`, grafted 2026-07-12. History:
  [[sessions/2026-07-11-innesto-note]] (graft v0.2.0),
  [[sessions/2026-07-17-framework-upgrade-v0.2-to-v0.5.1]] (→v0.5.1),
  [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]] (→v1.0.0),
  [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] (→v1.2.0),
  [[sessions/2026-10-19-framework-upgrade-v1.2.0-to-v4.1.0]] (→v4.1.0).
- Test: `tests/` (zsh puro, zero-dip, `make test`, **333 check** con anti-vacuità — 268
  before branch 4, which took `test_exit_codes.zsh` from 6 to 49; 311 before task 2 of the
  2.0.0 plan, which added `test_homebrew_developer.zsh` (22): no Homebrew developer command in
  the code, and module 1's developer-mode detection and restore against a mock brew):
  `test_selection.zsh` (87) copre `_resolve_selection`/`_resolve_cli`/
  `_selection_is_valid`; `test_guardrails.zsh` (9) fissa l'invariante di consenso
  (`_ask`/`_read_choice` sotto NON_INTERACTIVE vs `--yes`);
  `test_exit_codes.zsh` (49; 6 before branch 4) fissa l'exit end-to-end del binario reale (sandbox
  symlink-farm + mock brew con tripwire) — since branch 4 also the launchd-shaped
  minimal environment, every way out of the Homebrew check (69), the exit order, and
  `_brew_install` extracted and run against a mock curl (no test answers the installer
  prompt), through a process-group watchdog (stock `/usr/bin/perl`); `test_capabilities.zsh` (30, BM-09) fissa
  detection colore/Unicode, ladder di degradazione, purezza ASCII fallback e l'e2e
  "pipato = zero ANSI" via il vero re-exec `script(1)`; `test_risk_badges.zsh` (38,
  BM-10) fissa la completezza di `MODULE_RISK` vs `MODULE_DESC`, la classificazione,
  la degradazione L0/larghezza del badge e l'**invarianza del consenso** di
  `_ask_danger` (== `_ask` sotto --yes/non-interactive); `test_menu_registry.zsh`
  (8, BM-11) fissa il layout 80-col del menu come invariante di DATI (lockstep
  `MODULE_NAME`↔`MODULE_DESC`, cap 17/46 colonne, ASCII-only, chiavi congelate);
  `test_run_summary.zsh` (72, BM-12 + micro-task dry-run) fissa lo spinner gated su
  `TUI_TTY` (non-TTY: zero `\r`/ANSI + riga statica) con **rc del figlio
  preservato**, i formatter/glifi puri, l'**invariante di wiring**
  `DU_AFTER`↔twin KB sul sorgente di mod_05, e la coerenza di `MODULE_DRYRUN`
  (grep del gate nel sorgente + **allow-list bidirezionale** `_KNOWN_UNGATED`:
  un `0` fuori lista fallisce, una voce stantia pure — vedi IMP-009);
  `test_dryrun_gates.zsh` (18, micro-task 2026-07-21) esegue mod_02 e mas contro
  un **mock brew con tripwire** e prova che in dry-run i comandi mutanti non sono
  invocati, con i controlli "denti" in wet (per mas: stesso `y` su stdin,
  `--dry-run` unica variabile), più l'e2e che `HOMEBREW_NO_AUTO_UPDATE` raggiunge
  davvero brew **attraverso il re-exec di `script(1)`**.
  Resto del codice non coperto. Linter/formatter: ASSENTI (shellcheck/shfmt non installati; blocco
  formattazione predisposto ma commentato nell'hook). CI: assente.

### Active branches
- **chore/framework-upgrade-v1.2.0-to-v4.1.0** (the framework upgrade, process only) =
  **READY for the user's integration** (`/fw:integrate`, no tag; the gate's reviewed tip
  `56d3b1a`).
- **fix/homebrew-developer-mode** (task 2 of the 2.0.0 plan) = **INTEGRATED into main**
  (merge `8a7e6a2`; no tag), branch deleted.
- **main** = integration + stable (trunk-based); HEAD `8a7e6a2` (merge of task 2; below it
  `f232f12`, task 1, and `37b8db5`, the v1.5.0 release merge), aligned with
  `origin/main`; tags **`v1.5.0`** (annotated, object `deb8f61` → `37b8db5`) + `v1.4.0`
  (annotated, object `d4901b3` → `ab45323`) + `v1.3.0` + `v1.2.0` (annotated) +
  `v1.1.2-baseline` (helper). `CHANGELOG [Unreleased]` on main: empty. `make
  version-check` green (VERSION 1.5.0).
- **chore/replan-v2** (task 1 of the 2.0.0 plan) = **INTEGRATED into main** (merge
  `f232f12`, pushed; no tag), branch deleted.
- **chore/release-v1.5.0** (the release) = **RELEASED** (merge `37b8db5`, annotated tag
  `v1.5.0`, both pushed by the user), branch deleted.
- **fix/startup-brew-env** (branch 4 of the debt cleanup) = **INTEGRATED into main**
  (merge `bc114b9`, pushed; no tag), branch deleted.
- **chore/gitignore-d10** (branch 3 of the debt cleanup) = **INTEGRATED into main**
  (merge `050ea6d`; no tag), branch deleted.
- **chore/framework-upgrade-v1.0.0-to-v1.2.0** (framework upgrade, process only) =
  **INTEGRATED into main** (merge `0725ae6`, pushed; no tag), branch deleted. The git
  hooks installed from it (English marker) are the ones `main` now generates; the two
  `.bak` of the old Italian hooks have been removed by the user.
- **chore/apply-project-imps** (branch 2 of the debt cleanup) = **INTEGRATED into main**
  (merge `9e4f2b4`, pushed; no tag), branch deleted.
- **chore/imp-022-sensitive-selection** (branch 1 of the debt cleanup) = **INTEGRATED
  into main** (merge `73bc5ee`, pushed; no tag), branch deleted.
- **chore/checkpoint-post-fw-v1.2.0** (post-merge memory checkpoint) = **INTEGRATED into
  main** (merge `8ed9f5c`, pushed; no tag), branch deleted.
- **chore/checkpoint-post-v1.4.0** (post-release memory checkpoint) = **INTEGRATED into
  main** (merge `e7c3a56`), branch deleted.
- **chore/release-v1.4.0** (release) = **INTEGRATO in main** (merge `ab45323`,
  tag annotato `v1.4.0`), branch eliminato.
- **fix/dryrun-mod02-mas** (micro-task dry-run) = **INTEGRATO in main** (merge
  `dc47ae4`), branch eliminato.
- **feat/progress-summary** (BM-12) = **INTEGRATO in main** (merge `21c956b`),
  branch eliminato.
- **feat/menu-redesign** (BM-11) = **INTEGRATO in main** (merge `2e61180`), branch
  eliminato.
- **feat/risk-badges** (BM-10) = **INTEGRATO in main** (merge `2dd1f7c`), branch
  eliminato.
- **chore/lint-mem-fw-v1.0.0** (riconciliazione memoria post-fw-v1.0.0) = **INTEGRATO
  in main** (merge `765bad4`), branch eliminato.
- **chore/framework-upgrade-v1.0.0** (upgrade v0.5.1 → v1.0.0, solo processo) =
  **INTEGRATO in main** (merge `126bc7d`, pushato; bump "nessun tag"), branch eliminato.
- **feat/tui-foundation** (BM-09) = **INTEGRATO in main** (merge `5867137`), branch
  eliminato.
- **chore/checkpoint-post-v1.3.0**, **docs/readme-v1.3.0**,
  **fix/exit-code-propagation**, **chore/release-v1.3.0**, **fix/agent-selection**,
  **feat/positional-dispatch**, **chore/framework-upgrade-v0.2-to-v0.5.1** =
  MERGIATI in main, branch eliminati.
- **origin/dev** = remoto dormiente, allineato a main al momento dell'innesto; non
  usare come integrazione (vedi [[2026-07-12-trunk-based-su-main]]).
