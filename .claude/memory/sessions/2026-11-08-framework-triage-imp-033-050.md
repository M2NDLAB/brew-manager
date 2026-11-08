---
date: 2026-11-08
task: the framework's triage of IMP-033…050 filed as delivered, and the second harvest's corrections — memory only
branch: chore/framework-triage-imp-033-050
status: completed
model: 'claude-opus-5-5'
turns: 4
tags: [session, memory, learnings, framework, harvest]
---
# Session 2026-11-08 — the framework's triage of IMP-033…050

## Done
On `chore/framework-triage-imp-033-050`, from `main` at `71e2be9` (the post-upgrade
checkpoint's merge), memory only, one commit per logical change:
- `aea9ac6` — IMP-046, Level 1: `status` is read-only, only `path` is clobbered silently.
- `6ffe091` — IMP-033: `bash -n +n` runs code too.
- `3a340a8` — the first harvest's date, 2026-10-31, in IMP-053; a dated correction in
  [[sessions/2026-11-07-post-upgrade-checkpoint]] and in [[plans/post-upgrade-checkpoint]],
  their lines left as written.
- `4ba4fc5` — IMP-056's count of review rounds, Level 1.
- `184e579` — IMP-055: the upgrade gate's case, its source `gate/result.json:205` in the
  upgrade's working folder (STATE #40).
- `950aaa7` — IMP-033…050 under Deferred, delivered (the table below); INDEX's LEARNINGS line.
- `e0030da` — IMP-057, `Destination: framework`, on the user's request.
- This commit — the checkpoint: STATE (#41 closed; 7,911 → 6,997 characters), this note,
  INDEX.

Before them, read-only: the second `/fw:harvest-framework`, on IMP-050…056. The user sent
IMP-051…056 to the Architect on 2026-11-08, IMP-050 left out as it already is IMP-169. That
harvest found the two errors that `3a340a8` and `4ba4fc5` correct, and the evidence that
`184e579` adds.

## The user's decisions, verbatim (2026-11-08)
- «Forma: le IMP consegnate vanno sotto «Deferred», con la consegna nel titolo (numero a monte
  e data 2026-11-08). Trigger di ripresa: la release del framework che contiene la IMP a monte,
  da verificare al prossimo upgrade.» — the delivered IMPs go under Deferred with the delivery
  in the title; the resumption trigger is the framework release that contains the upstream
  IMP, checked at the next upgrade.
- «STATE #41: chiudila. Il rapporto dell'Architetto copre solo IMP-033…050, quindi le vecchie
  IMP aperte (006, 008, 009, 010, 011, 013, 014, 016, 019, 021; 026–028 in parte) restano OPEN,
  nessuna chiusa come duplicata (decisione D). Il filo resta nella riga di LEARNINGS in STATE,
  con il trigger «il rapporto dell'Architetto sulle IMP vecchie». La richiesta all'Architetto
  la mando io.» — #41 closed; the old OPEN IMPs stay open, none closed as a duplicate, and the
  thread lives in STATE's LEARNINGS line until the Architect reports on them; the user asks.
- «La #40 (cartella _upgrade-scratch) resta aperta: il triage del framework non è chiuso
  finché decide su IMP-112.» and «STATE deve scendere, non salire: obiettivo ≤ 7.000
  caratteri.»

## The correspondences, as the framework's Architect sent them (2026-11-08)
| Here | Lesson | Upstream | The triage's note |
|---|---|---|---|
| IMP-033 | A prefix permission on an interpreter's check-only option runs code | IMP-153 | — |
| IMP-034 | SETUP Step 3: merge `settings.json` out of place | IMP-154 | — |
| IMP-035 | `scripts/state-inject.sh` points a client project at a guide it lacks | IMP-155 | extends IMP-049, applied upstream |
| IMP-036 | The guard refuses a read on a literal path to a bare clone | IMP-156 | a false positive of the no-index refusal of IMP-123 |
| IMP-037 | The inventory's edge-case-8 list missed a docs/00 slot | — | evidence on IMP-139, no new entry |
| IMP-038 | The release policy as an answer `/fw:integrate` reads | IMP-157 | — |
| IMP-039 | `grafted`: preflight and Step 6 disagree | IMP-158 | — |
| IMP-040 | `reset-task.sh`'s fallback ignores the Makefile's list | IMP-159 | — |
| IMP-041 | The inventory's measures of the LEARNINGS header and format comment | IMP-160 | — |
| IMP-042 | A self-test copies a file the upgrade may not have brought yet | IMP-161 | — |
| IMP-043 | STATE's numbered entries as anchors through a condensing checkpoint | IMP-162 | — |
| IMP-044 | The upgrade's checkpoint: two rules for one STATE rewrite | IMP-163 | — |
| IMP-045 | Step 0's pin fix and `/fw:plan`'s first commit | IMP-164 | — |
| IMP-046 | zsh traps beyond word splitting | IMP-165, the `path` part | extends IMP-136; the `:s` and `=word` part duplicates IMP-112, which the framework had rejected: it recorded the recurrence, and its triage decides whether to reopen it |
| IMP-047 | The boundary's permission claims rest on a local settings file | IMP-166 | — |
| IMP-048 | Attribution trailers against "no external name in shared history" | IMP-167 | the project's `attribution.sessionUrl` key counts as evidence, not as proof |
| IMP-049 | The memory claims an upgrade makes stale | IMP-168 | — |
| IMP-050 | Sensitive components named by code path | IMP-169 | extends IMP-141 |

Outside this triage: IMP-051…056, sent on 2026-11-08, wait for the Architect's mapping; the
old OPEN IMPs v4.1.0 covers wait for its report on them.

## Security gate
- Not applicable: the branch's diff touches only `.claude/memory/` (`git diff --no-renames
  --name-only origin/main...HEAD`: `INDEX.md`, `LEARNINGS.md`, `STATE.md`,
  `plans/post-upgrade-checkpoint.md` and two session notes, this one among them) and no file
  the project ships, so the core exempts it from the gate and the retro (`/fw:integrate`'s
  check; docs/00, *Scope and session hygiene*). IMP-057 is the user's request, not a retro's.

## Problems encountered → cause → solution
1. No status for an IMP delivered upstream → docs/06 names four sections, and none fits a
   lesson the framework decides → asked before writing, as the user's brief required; Deferred
   with the delivery in the title, the user's choice → IMP-057.
2. #41's scope → the Follow-up of [[sessions/2026-11-07-post-upgrade-checkpoint]] ties it to
   the old OPEN IMPs v4.1.0 covers, while the Architect's report covered IMP-033…050 only →
   asked; the user closed it and moved the thread to STATE's LEARNINGS line.
3. STATE at 7,911 characters against the 7,000 target → wording, a done progress line and
   history the notes already hold → condensed to 6,997, every open entry kept under its
   number, #42 left as the user asked on 2026-11-08; each rewritten line's earlier text in the
   appendix below.

## Factual doc corrections (Level 1, docs/06)
- IMP-046 (`aea9ac6`): on zsh 5.9 (`zsh -f`), `for status in a` fails with "read-only
  variable: status", exit 1, and `for path in /nowhere` leaves `PATH=/nowhere`, exit 0 — as
  the framework's triage measured too.
- IMP-053, task 4's line in [[sessions/2026-11-07-post-upgrade-checkpoint]] and task 4 of
  [[plans/post-upgrade-checkpoint]] (`3a340a8`): the first harvest ran on 2026-10-31. Its
  session's transcript prints the block that day at 17:28 UTC, and that session's only later
  activity, on 2026-11-07, was the user's `/permissions`; the user sent the block upstream on
  2026-11-07. The note and the plan keep their lines and gain a dated correction;
  `d2f5211`'s message, published, keeps the wrong date.
- IMP-056 (`4ba4fc5`): the scoped rewrite `36b0cdd` lies in round 4's range,
  `e79f80d..4e8149d` (the two ranges' `git log`): three rounds found a site each, the fourth
  nothing more.
- Additions, measured: IMP-033 (`6ffe091`), `bash -n +n -c 'echo X'` prints X and exits 0 on
  bash 3.2.57; IMP-055 (`184e579`), the upgrade gate's reviewer's `/tmp/claude-501/gd.err`,
  from `gate/result.json:205`.

## Proposals
- IMP-057 (OPEN, `Destination: framework`): a status for a lesson the framework has
  recorded, and a harvest that leaves it out by default.

## Follow-up
- IMP-051…056, sent to the Architect on 2026-11-08 → its mapping (STATE, the LEARNINGS line).
- The old OPEN IMPs — 006, 008–011, 013, 014, 016, 019, 021 and 026–028 in part, which v4.1.0
  covers — → the Architect's report on them, which the user requests; none closed before it
  (decision D) (STATE, the LEARNINGS line).
- IMP-112 → the framework's triage decides whether to reopen it. Until then the triage stays
  open, and with it the upgrade's working folder (STATE #40) and IMP-046's `:s` and `=word`
  part.
- IMP-033…050 → the framework release that contains each, checked at the next upgrade (their
  resumption triggers; STATE, the LEARNINGS line).
- A harvest from now on: its default perimeter prints the 18 Deferred entries again, their
  `Destination: framework` kept; narrow it to the OPEN section (IMP-057).
- STATE #42: `git log --format=%B 269cc9c.. | grep -cE 'https://claude\.ai/code/session_[0-9A-Za-z]'`
  printed 0 on 2026-11-08, before this commit; the branch's other seven commits carry
  `Co-Authored-By` and no `Claude-Session:`.
- Task 3, which the user starts after this merge: the work recorded for it in
  [[sessions/2026-11-07-post-upgrade-checkpoint]] (*Work for task 3's branch*); STATE stays
  within 7,000 characters at every checkpoint.

## Appendix — STATE.md's lines this checkpoint rewrote, verbatim at `71e2be9`
Lines 9, 12, 17, 21–24, 28, 31, 33–34, 36, 57–60, 63–64 and 67–68 of
`git show 71e2be9:.claude/memory/STATE.md`, as they stood.

> Updated: 2026-11-08 | Last: **the post-upgrade checkpoint** (`chore/post-upgrade-checkpoint`): STATE condensed; `make lint` = `zsh -n`; gate 0 C/H/M at `4e8149d`. → [[sessions/2026-11-07-post-upgrade-checkpoint]] | Index: [[INDEX]]
- [x] v1.1.2 → v1.5.0 and four framework upgrades, the last to v4.1.0 (merge `0b127a9`, no tag): the notes in [[INDEX]].
- `make test` 333 checks (9 zsh suites); `make check` = `make lint` = `zsh -n`; no CI; gitleaks found 0 in the 155 commits of 2026-09-25 (#7; later ones: the pre-commit hook). Tags annotated from `v1.2.0` (`v1.1.2-baseline` a helper the tool's `git describe` skips).
- Trunk-based `main`; a tag only from `chore/release-vX.Y.Z`, with `VERSION` → CLAUDE.md (Releases); [[2026-07-12-trunk-based-su-main]].
- Gate and contract: CLAUDE.md's answers and rule **Security gate** (U2, U5 of [[decisions/2026-10-19-framework-upgrade-v4.1.0]]); module ids frozen (users' plists) → [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]].
- Personal terminal tool, no Dashboard → [[2026-10-07-v2-plan]]. No tty ≠ consent → [[2026-07-17-consent-vs-noninteractive]]. Artifacts English, a condensed entry too → CLAUDE.md.
- `make lint` = `zsh -n`, a syntax check only — shellcheck does not support zsh (SC1071). Co-Authored-By kept, `attribution.sessionUrl` false; commits published before 2026-11-07 keep their `Claude-Session:` trailer, never rewritten → [[decisions/2026-11-07-framework-architect-decisions]].
- README/SECURITY.md vs the code ([[sessions/2026-09-24-debt-inventory-pre-dashboard]], E): each 2.0.0 task fixes its section; the residue (R4, R9–R11, R13, M3, SECURITY.md, the upgrade gate's F5 at :36-41 and its docs/03 pointer) → task 8. bk/las/log/mas described until task 3.
> Numbers are labels — code and tests cite "STATE #N" or "STATE Attenzione #N" —, never reused. "→ task N" is the trigger ([[plans/v2-personal-tool]]); "task 3" entries close once a grep proves the code gone. Earlier text: appendix A of [[sessions/2026-11-07-post-upgrade-checkpoint]]; evidence: [[sessions/2026-10-07-replan-v2-assessment]] (C, file:line at `37b8db5`).
- **#3** `--dry-run` not uniform: #15/#16 (task 3); module 1's `/tmp/brew_doctor.log` and its plain `git status` in Homebrew's repo (may refresh the index) under `--dry-run` → task 4, with #11, #14.
- **#3b** zsh `echo` on data expands escapes (LOW, 74+ sites; #26 live) → after 2.0.0 (D10), module 0's three install-path sites → task 5. TRIGGER: v2.0.0, or new code copying it.
- **#4b** Module outcomes not reported: 17 of 18 modules return 0 when brew fails, `$?` unread, ✓ for failed/skipped/declined → task 7 (4b-1, reduced 4b-2, raw output into the log; 4b-3 closed). Ctrl+C exits 2 → 130 in task 4.
- **#38** The run summary shows unmeasured counters as measured: after module 1 alone, "Installed casks 0 / formulae 0 / Available updates 0" and the adopt rows (task 2's acceptance run) → task 7, with #4b.
- **#39** Module 1's restore box overflows: "From: …" and the local-changes line exceed the 74-column field of an 80-column terminal; `_box` never truncates → task 5 (module 1's texts).
- **#40** `/Users/seco/Projects/_upgrade-scratch/brew-manager`: keep until the framework's triage closes, then the user deletes it (decision C) → TRIGGER: the triage closes.
- **#41** Upstream duplicates among the OPEN IMPs: the Architect flags them after their harvest session; none closed as a duplicate before (decision D) → TRIGGER: the Architect's report.
- Closed, text in appendix A: #1, #2, #5, #5b, #7, #8, #10, #17 (reopen: a caller sets the variables), #19, #20, #23 (reopen: no Homebrew outside a login shell), #28, #30 (merge `8a7e6a2`), #34 and #36 (decisions A, B: *Decisions made*), #35 (the user's local rules narrowed, re-read 2026-11-07), #37 (closed by `chore/post-upgrade-checkpoint`), #43 (the lint ran 2026-11-08: the note's Follow-up).
- [[LEARNINGS]]: OPEN 006, 008–021, 023–029, 032–056 (033…050 sent to the Architect 2026-11-07) → TRIGGER: the periodic retro or the user's request; the ones v4.1.0 covers upstream after #41. Applied 001–004, 007, 022, 030, 031; Deferred 005 (its own trigger).
- **chore/post-upgrade-checkpoint**: done (plan completed), at `/fw:integrate`'s checks (no tag).
- **main** (integration = stable): `0b127a9` = `origin/main`, latest tag `v1.5.0` = VERSION; `origin/dev` dormant; every other branch merged and deleted.
