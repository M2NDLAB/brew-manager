---
date: 2026-10-19
task: upgrade the grafted claude-code-framework from v1.2.0 to v4.1.0 (process only)
branch: chore/framework-upgrade-v1.2.0-to-v4.1.0
status: completed
model: 'claude-opus-5-5'
turns: 4
tags: [session, framework, upgrade, process, security-gate]
---
# Session 2026-10-19 — framework upgrade v1.2.0 → v4.1.0

The fourth upgrade of the graft, one jump from v1.2.0 to v4.1.0, run by v4.1.0's SETUP.md
(*Upgrading the framework on an already-grafted project*), with three stops for the user:
FERMATA 1 (read-only assessment), FERMATA 2 (after Step 5), FERMATA 3 (`/fw:integrate`'s
block 0). Process only: no product file changed, no tag.

- **Restore point**: `main` at `8a7e6a207039ab897f2338cbd70b1ed6b8982f17` (= `origin/main`).
- **Working folder T** (kept until the merge; the hooks photograph is there):
  `/Users/seco/Projects/_upgrade-scratch/brew-manager` — FERMATA 1 report
  `fermata1/report.md` (+ `appendix.md`), FERMATA 2 table `fermata2/table-fermata2.md`,
  the memory lint `fermata2/lint-memory.md`, the gate `gate/result.json`, the hooks before
  the upgrade `hooks-before/`.
- **The user's decisions** U1–U24 and the divergences from the loaded v1.2.0 method:
  [[decisions/2026-10-19-framework-upgrade-v4.1.0]]. Plan: [[plans/framework-upgrade-v1.2.0-to-v4.1.0]].

## Done
- Precondition "FW OK"; the v4.1.0 tag's signature valid; preflight 5 OK / 1 FAIL (the pin's
  missing `v`) / 1 CHECK (`grafted`); prerequisites 0 FAIL 0 WARN; inventory 0 FAIL, 67 CHECK,
  all explained in the FERMATA 1 report (10 readers, 7 adversarial verifiers, a critic).
- Step 1: branch, hooks photographed into T. Step 0: `09b7250` (the pin's `v`). Plan and
  decision record: `93c7b90`.
- Tasks: 1 commands to `fw/` `2231311` · 2 core rules + CLAUDE.md rebuilt `dbbff76` · 3 docs
  00–06 `679a33b` · 4 titles and labels renamed `116adcb` · 5 memory templates `2129ec9` ·
  6 boundary (settings, guard, state-inject) `5c0cd1b` · 7 Makefile and scripts (+
  `.gitattributes`) `f4af521` · 8 hooks-install + self-test `c9701eb` · 9 `.gitignore`
  `d9e86ef` · 10 the pin `56d3b1a` (the reviewed tip).
- Step 4: `make hooks-install` from the main worktree — `pre-commit.bak` and
  `commit-msg.bak` byte-identical to the photograph (the user removes them after the push),
  a new `pre-push`; every hook carries the generator's marker; no hook manager; a fake
  `ghp_` token blocked by gitleaks (`github-pat`); a non-conventional message rejected by
  commitlint; `make test-scripts` 13 PASS; the marker grep finds only
  `plans/framework-upgrade-v0.2-to-v0.5.1.md:30` (history, not a slot).
- Step 5: `invariant` 0 FAIL / 12 CHECK (all confirmed by hand: the restore point's pin,
  the LEARNINGS header's own paragraph, nine answers not word for word, the allow in
  `settings.json`); `post` 0 FAIL (6 CHECK after the pin: answered slots, the decisions
  README); `make check` 31 files; `make test` 333 checks; prerequisites 0 FAIL.
- The titles' functional check: `state-inject.sh` on the real STATE prints
  `## Caution & open issues` on line 2; 37 numbered entries + 2 bullets, as at the restore
  point; in a throwaway clone with entry #30 removed, `invariant` FAILs on it and the
  entry-by-entry comparison finds it, while the hook's 8,000 characters do not show it;
  `/fw:lint-memory` (report only) does not report the section missing.
- FERMATA 2 table: 131 answers and customisations verified against `d9e86ef` by 7
  independent verifiers and a critic — 40 identical, 6 moved identical, 26 reworded with
  identical values, 47 replaced by the method, 12 removed by the user's decisions, 0 lost.
- **The graft date (U1)**, the proof from git, run before the branch:

  ```
  $ git show -s --format='commit %H%nauthor-date %ad%ncommitter-date %cd%nsubject %s' --date=iso-strict 77471fc
  commit 77471fc044e6bad0aca6964e7831db175e867fad
  author-date 2026-07-12T00:55:50+02:00
  committer-date 2026-07-12T00:55:50+02:00
  subject chore: graft claude-code-framework v0.2.0 process docs and commands
  $ git show -s --format='commit %H%nauthor-date %ad%ncommitter-date %cd%nsubject %s%nparents %P' --date=iso-strict 7893f87
  commit 7893f87dbe4e06f5c4dca95b5cd6f7d85dd82a94
  author-date 2026-07-12T18:31:30+02:00
  committer-date 2026-07-12T18:31:30+02:00
  subject chore: merge chore/innesto-framework in main
  parents c0f456feaa22fb6d9b55ab995d0dd85b1e6b0d02 3dfd87ff8a9d4291623c99f30d70114af946d558
  ```

  In UTC the graft commit's instant is 2026-07-11T22:55:50Z; the date git records, in the
  commit's own offset, is 2026-07-12 — the pin's `grafted: 2026-07-12`.

## Security gate
- `/fw:security-review`, **Reviewed: `8a7e6a207039ab897f2338cbd70b1ed6b8982f17..56d3b1a5e25e80f0e9a03efd53bd7a117b7f015d`**
  (reviewed tip `56d3b1a`) — under the gate: the upgrade changes the enforcement edge (the
  guard, `settings.json`, the hooks, `state-inject.sh`). One independent, delegated,
  read-only reviewer (the two lenses, the eleven checks, "what does this now AUTHORISE?"),
  then one refuter per finding; the shared repository's snapshot identical before and after.
  **Outcome: 0 CRITICAL, 0 HIGH, 0 MEDIUM** (the two MEDIUMs raised were lowered by their
  refuters), LOW 2, INFO 7, refuted to none 5 — every finding closed or declared:
  - F1 (MEDIUM → INFO): this session and its agents ran on the v1.2.0 instructions loaded at
    launch — **closed**: the method's restart after the merge (SETUP Step 6); task 11 read
    `fw-core.md` before acting.
  - F2 (MEDIUM → LOW, pre-existing): the user's local allow rules (`git checkout *`, `git tag
    *`, `gh repo *`, `git ls-remote *`) approve discards, tags and forge writes with no
    prompt; docs/04's claims at :268-269 and :537 do not hold here — **declared**: STATE #35,
    the user's decision on their own file (U24).
  - F3 (LOW → INFO): `make check reset-task YES=1` reaches a discard through the local
    `make check *` / `make test *` rules — **declared** with F2 (#35).
  - F4 (LOW → INFO): memory claims the upgrade made stale, not on any list — **closed**: the
    list of #37 and IMP-049.
  - F5 (LOW, pre-existing): SECURITY.md:36-41 claims wider than v4.1.0's docs/03 declares —
    **declared**: STATE's Documentation debt, task 8 of the 2.0.0 plan.
  - F6 (LOW → INFO): every commit of the branch carries a `Claude-Session:` URL trailer, the
    first in the public history — **declared**: STATE #36, the user's decision before the
    push; IMP-048.
  - F7 (refuted): `make lint` cannot run, `Bash(shellcheck:*)` dormant — **closed**: STATE
    #34, the rule decided with the target.
  - F8 (refuted): the Error format answer's inaccuracy — **closed**: U18 (d), task 7.
  - F9 (INFO): RESET-02's fallback — **closed**: accepted by the user at FERMATA 2; IMP-040.
  - F10 (refuted): `state-inject.sh:50`'s pointer — **closed**: U8; IMP-035.
  - F11 (INFO): the guard's bare-clone false positive — **closed**: IMP-036.
  - F12 (INFO): commitlint pinned at the top level only, `npx --yes` — **closed**: declared
    by the method (`scripts/hooks-install.sh:69-70`).
  - F13 (refuted): `/fw:integrate` does not read the Releases rule — **closed**: IMP-038 and
    the FERMATA 3 check.
  - F14 (refuted): local absolute paths in memory — **closed**: existing practice, and T's
    path is recorded here on the user's request.
  - Not covered by the review: no project code run (make targets, hooks, the pre-push on the
    real repository); commitlint's transitive dependencies not checked for CVEs; `gh`'s
    token scopes not read; the user-level plugins not inspected.

## Problems encountered → cause → solution
1. `test-check-prerequisites.sh` failed with "cp: …/.gitattributes: No such file or
   directory" → the self-test copies the project's `.gitattributes`, planned for task 9 →
   `.gitattributes` moved into task 7 (it renormalises nothing); IMP-042.
2. commitlint warned "footer must have leading blank line" on task 3's commit → a body line
   opening with `Plan:` is read as a footer (docs/04 says so) → the local commit's message
   amended before anything else.
3. `echo =====` failed in zsh (`==== not found`) → `=word` expansion → quoted; IMP-046.
4. `make lint` skips: shellcheck absent at the restore point too (the recipe is unchanged),
   and it does not support zsh → the user does not install it; STATE #34.
5. The gate's reviewer noted the session ran on the loaded v1.2.0 rules (F1) → the
   procedure's restart is after the merge; `fw-core.md` read explicitly before task 11.
6. The `/fw:` commands appeared mid-session once task 1 brought them (U22: no restart
   needed before the gate).

## Factual doc corrections (Level 1, docs/06)
- None. (The Security gate rule names `/fw:security-review`: FERMATA 2, the user's item 1.)

## Proposals
- IMP-033…IMP-049 in LEARNINGS.md, all `Destination: framework`, OPEN (the decisions go to
  the periodic retrospective after the merge): the user's eight — IMP-033 (U6), 034 (U21),
  035 (U8), 036 (the guard's bare-clone false positive), 037 (docs/00's slot, IMP-139), 038
  (U14), 039 (`grafted`), 040 (RESET-02) — and IMP-041…046 from the FERMATA 1 report,
  IMP-047…049 from the gate. OPEN IMPs now covered upstream by v4.1.0 (006, 008, 009, 010,
  011, 013, 014, 016, 019, 021; 026–028 in part) go to the same review.

## Follow-up
- **The first `/fw:checkpoint` after the merge** — the next deliverable (the user): condense
  STATE (71.6K characters) and record: (a) task 2's acceptance run on the user's Mac on
  2026-10-10 — the preview changed nothing, the restore was confirmed, Homebrew went from
  7.0.8 to 7.0.9 stable, and a second run did not turn developer mode back on; (b) two
  defects — the summary prints "Installed casks 0 / formulae 0 / Available updates 0" when
  only module 1 runs (unmeasured data shown as true → task 7), and the restore's
  confirmation box overflows (the "From: ..." line past the frame → task 4 or 5);
  (c) STATE's frontmatter; (d) #30 closed by merge `8a7e6a2`; (e) the memory claims the
  upgrade made stale: STATE's decisions on the gate ("one lens", "the paths in docs/03") and
  on language ("headings frozen, mapped in CLAUDE.md"), the public contract "in docs/04",
  #19 and #33's pointers, `decisions/2026-07-12-componenti-sensibili` (an amendment: the list
  is CLAUDE.md's answer Sensitive components), `decisions/2026-07-12-trunk-based-su-main:20`
  (the protected list is the Makefile's), [[2026-09-24-language-rule-prospective]] marked
  superseded, the 2.0.0 plan's tasks 3/4/6/7 naming docs/0N and `new-component.md` as
  targets (now CLAUDE.md's answers and `/fw:new-component`) and its "gate: one lens", INDEX:197;
  (f) the OPEN IMPs covered upstream; (g) task 8's gate status (a product asserting a
  security property is gated); (h) the language of condensed entries (U4). → STATE #37.
- **Before that checkpoint** the user decides the anchors' form in code and tests (U23: 21
  comment lines in 9 files cite "STATE Attenzione #N"/"STATE #N"). → STATE #37.
- `make lint` (the user's three options) → STATE #34.
- The user's local permissions (F2, F3) → STATE #35. The commit trailers (F6) → STATE #36.
- Restart Claude Code at the repository's root after the merge, before the next deliverable.
- The hooks' `.bak` files: the user removes them after the push.
