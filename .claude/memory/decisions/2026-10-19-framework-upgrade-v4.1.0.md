---
type: decision
updated: 2026-10-19
tags: [decision, framework, upgrade, process, security-gate, language, release]
---
# Framework upgrade v1.2.0 → v4.1.0: the user's decisions U1–U24

- **Context**: the fourth upgrade of the graft, a single jump from framework v1.2.0 to v4.1.0,
  run by v4.1.0's SETUP.md, *Upgrading the framework on an already-grafted project*. FERMATA 1
  was a read-only assessment: ten readers, seven adversarial verifiers (one per file group)
  and a completeness critic. Restore point: `main` at
  `8a7e6a207039ab897f2338cbd70b1ed6b8982f17`. The full report is outside the repository, in
  the upgrade's working folder T, kept until the merge:
  `/Users/seco/Projects/_upgrade-scratch/brew-manager/fermata1/report.md`. Verbatim texts of
  every answer and customisation at the restore point are in `appendix.md`, same folder. The
  user reviewed the report with the framework's Architect and answered on 2026-10-19:
  "Risposte U1–U24: ok come raccomandato, con queste eccezioni e aggiunte."
- **Supersedes in part** [[2026-09-24-language-rule-prospective]]: its D1 (the Italian
  memory headings frozen as identifiers, an IT↔EN map in the technical rules) is superseded
  by the v4 core's rule 9 ("The memory's FORMAT — the titles and labels the commands read by
  name — is method: every upgrade brings it to the method's form, never a map from old to
  new"). The map leaves CLAUDE.md; the titles and field labels take the method's English
  form; the memory's CONTENT stays as written (nothing is translated). That note is marked
  superseded at a later checkpoint: the upgrade does not edit project memory.

## Decisions

- **U1 — the pin's `grafted`**: the real graft date, `2026-07-12`. The user: "grafted = la
  data vera dell'innesto, 2026-07-12, provata da git (data del commit dell'innesto, 77471fc).
  Riporta comando e output come prova nella nota di sessione." Verified before the branch:
  `git show -s --format='commit %H%nauthor-date %ad%ncommitter-date %cd%nsubject %s'
  --date=iso-strict 77471fc` printed author and committer date
  `2026-07-12T00:55:50+02:00`, subject "chore: graft claude-code-framework v0.2.0 process
  docs and commands"; the graft's merge `7893f87` is dated `2026-07-12T18:31:30+02:00`.
  (In UTC the commit instant is 2026-07-11T22:55:50Z; the date git records, in the commit's
  own offset, is 2026-07-12.)
- **U2 — IMP-030 under the v4 core** (as recommended). The v4 core's rule 8 gates "a
  deliverable that touches a sensitive component — … the project's own list, the answer
  **Sensitive components** in `CLAUDE.md` — or whose product asserts a security property; in
  doubt, under the gate", and `/fw:integrate` stops on "not applicable" when the diff touches
  a component of that answer. So:
  - the answer **Sensitive components** names the **code paths** that delete, install,
    modify Homebrew's configuration or decide what runs, each with the file that holds it;
    values identical to docs/03 and the technical-rules list at the restore point; no
    "PATH-BASED" label;
  - a technical-rules bullet **Security gate** holds only what ADDS to the core: one
    independent reviewer, delegated, never the author; "what does this now AUTHORISE?" in
    every gated review; a refuter where a change widens what a gated path authorises; IMP-004's
    class closing, verbatim. It replaces the technical-rules list of sensitive components;
  - "one review lens" becomes "one independent reviewer" (in v4 a *lens* is a perspective,
    and every review applies two);
  - **lost by this decision** (they narrow the core): "any other edit to these files is
    verified by the author" (and its docs/03 twin), "LOW at least recorded" (the core: LOW/INFO
    "closed or declared where its claim lives"), and the review scoped to the changed paths
    (the core: the branch diff and the set a widened claim names);
  - covered: "no multi-hour review workflows" (v4 docs/03, the review's size);
  - an IMP with `Destination: framework` at the retro: path-scoped sensitive components, and
    how `/fw:integrate`'s "not applicable" check reads them.
- **U3 — IMP-031** stays in the technical rules' Code conventions.
- **U4 — language**: "Interaction language: Italian" and the prospective-boundary sub-bullet
  stay in the technical rules, citing "the core's rule 9"; the IT↔EN map leaves (the user's
  brief). Whether a condensed STATE entry keeps its language is decided at the first
  `/fw:checkpoint` after the merge.
- **U5 — docs/04's answers**: Branches, Merge (with `/fw:integrate`) and Public contract go
  to their answer lines, values identical; the contract as an indented sub-list with no blank
  line. **Exception, the user**: "gli esempi MINOR vanno nelle regole tecniche, come prevede
  la procedura v4.1.0, non dentro Public contract. Il contratto resta con i valori identici."
- **U6 — `settings.json` allow**: keep `Bash(git show:*)` (IMP-001), `Bash(git tag)`,
  `Bash(git describe:*)`, `Bash(shellcheck:*)`, `Bash(brew list:*)`, `Bash(brew info:*)`;
  drop `Bash(zsh -n:*)` — measured: `zsh -n +n -c '…'` executes, a later `+n` cancelling
  `-n`; drop v1.2.0's four reading rules as v4.1.0 does (`git diff`, `git log`,
  `git branch`, `tree`: `/fw:checkpoint`'s `tree` then prompts in manual mode). docs/04's
  prose reasons go; IMP-001's record keeps the why of `git show`.
- **U7 — IMP-002** becomes a verbatim sub-bullet of the technical rules' Tests; IMP-003 and
  IMP-007 stay where they are; IMP-004 goes to the Security gate bullet (U2).
- **U8 — prunings**: v4.1.0's copies are taken (lint-memory check 10, harvest-framework,
  docs/01, docs/06, sessions/README, the LEARNINGS format comment, the SessionStart fallback).
  Residue: `scripts/state-inject.sh:50` still names "the framework setup guide" — inert here,
  METHOD, not re-pruned.
- **U9 — Formatter / linter**: the answer line carries docs/02's text verbatim; the technical
  rules' formatter sentence stays (a duplicate, accepted); the shfmt block of
  `scripts/hooks-install.sh` stays identical.
- **U10 — Makefile**: line 3 in the project's form; `PROTECTED_BRANCHES = main dev` with the
  trunk-based reason in place of the slot's marker line; the product section byte-identical.
- **U11 — `.gitignore`**: add only `.claude/worktrees/` with its comment; `*.log` stays out
  (D10 of the previous upgrade) and the template's marker block does not come back.
- **U12 — `fw/new-component.md`**: brew's procedure kept; the description names a brew-manager
  module, plus " - run by the user only" and `disable-model-invocation: true`; step 6 points at
  the answer **Sensitive components** and names `/fw:security-review`; the production-artefact
  slot answered in one line pointing at the answer **Production artifact**.
- **U13 — `fw/checkpoint.md`**: `main` and the tree pattern kept; the setup paragraph deleted.
- **U14 — `fw/integrate.md` and releases**: step 1's line answers `main` and `main`
  (trunk-based). A technical-rules line **Releases**, the user's wording: "deve dire
  esplicitamente che i merge di feature e chore usano i blocchi SENZA tag di /fw:integrate, e
  che un tag nasce solo da chore/release-vX.Y.Z. Alla fermata 3 conferma, citando il testo, che
  il blocco 1 non contiene git tag."
- **U15 — `rules/fw-code-quality.md`**: globs `brew_manager.sh`, `lib/*.sh`, `modules/*.sh`,
  `tests/*.zsh`.
- **U16 — LEARNINGS header**: the project's Italian paragraph and date kept (an `invariant`
  CHECK to confirm); the format comment becomes v4.1.0's.
- **U17 — anchors in CLAUDE.md**: "STATE Attenzione #N" becomes "STATE #N" in the rebuilt
  technical rules.
- **U18 — what leaves the method docs**: (a) the history-scan record of docs/03 stays only in
  STATE #7 and its session note; (b) docs/00's graft date stays in memory and the pin;
  (c) docs/02's "Never commit unformatted code." returns with v4.1.0's copy; (d) the **Error
  format** answer is carried verbatim although inaccurate (the raw output goes to fixed /tmp
  files or /dev/null, not the session log): a separate Level-1 correction after the merge.
  *(Recorded on 2026-11-07: (a)'s STATE #7 left STATE in its condensation, its text verbatim
  in appendix A of [[sessions/2026-11-07-post-upgrade-checkpoint]], beside its own session
  note; (d) was corrected as text, `32069dc`.)*
- **U19 — duplicates**: the technical-rules bullet "Where the project documentation lives"
  leaves (it is the answer **Documentation**); Stack, Run, Deployment and the formatter
  sentence stay.
- **U20 — first commits**: branch, hooks photograph, the pin's `v` (Step 0), preflight again,
  then this record with the plan.
- **U21 — `settings.json`**: its 3-way is done in T, resolved there, checked as JSON, then
  written into place at once — not merged in place, where conflict markers would leave a
  file Claude Code reloads at once invalid.
- **U22 — `/fw:` commands**: `fw/plan.md` is applied by hand from v4.1.0's text until task 1
  brings it; before the gate, if the `/fw:` commands do not resolve in the session, the user
  restarts Claude Code on the branch. Never a bare `/checkpoint` or `/security-review` after
  the rename.
- **U23 — anchors in code and tests**: out of the upgrade. **The user**: "la forma delle ancore
  nel codice la decido io prima del primo /fw:checkpoint dopo il merge."
- **U24 — `settings.local.json`**: never edited. **The user** removed `Bash(git *)`,
  `Bash(gh auth *)` and `Bash(./brew_manager.sh go *)` through `/permissions` and validated the
  JSON; read-only re-check at the branch's opening: none of the three present, valid JSON.
- **STATE.md, the user**: "niente condensazione dentro l'upgrade, perché toglierebbe senso a
  invariant. Nel piano la condensazione è il deliverable subito successivo al merge, nel primo
  /fw:checkpoint."

## Divergences from the loaded v1.2.0 method (v4.1.0 prevails)

1. D1's frozen Italian headings and map: superseded (see above).
2. Edge case 7 allows a customised METHOD file to be kept as a hybrid; the user's rule ("MAI
   MODIFICARE IL NUCLEO O UN FILE METHOD PER CONSERVARE UNA PERSONALIZZAZIONE") takes the
   procedure's other branch — customisations move to the technical rules or an answer.
3. Edge case 3 (b) updates code and tests citing old titles in the rename commit; the user
   keeps code and tests out (U23). Safe: every such citation is a comment no test reads.
4. The hooks' way back is Step 1's photograph (edge case 4), not `FORCE_OVERWRITE=1`.
5. Rule 3: "never push without the user's confirmation" becomes "never push"; a pre-push
   hook refuses pushes from the session.
6. Rule 7: only the user discards an interrupted task (`make reset-task`, from their own
   terminal); a direct `scripts/reset-task.sh --yes` without `PROTECTED_BRANCHES` is refused.
7. Nothing of the method is `@`-imported; STATE.md reaches the session through the hook, at
   most 8,000 characters with *Caution & open issues* first. Until the first checkpoint after
   the merge condenses it, a session sees mostly closed entries and a pointer to the whole file.
8. Rule 8: LOW/INFO closed or declared; the session note's gate line is mandatory and checked
   by `/fw:integrate`; a product asserting a security property is gated. Rules 1, 2 (a
   ten-point Definition of Done) and 6 change; rule 10 (method files edited with the file
   tools) arrives.
9. docs/04: `chore: wip …`; a blank line before the footer; tag hygiene; destructive commands
   never given in advance; no comment lines inside command blocks; delegated agents read-only
   on git; `ask` rules on the boundary's files.
10. The guard refuses more in the main session too (an amend while HEAD is held by its
    upstream, `git branch -D`, `--no-verify`, `add -f`, `--output`, a diff with a path outside
    the work tree), with a measured false positive: a literal path to a bare clone with two
    revisions.
11. Trunk-based tagging (U14), the pin's `grafted` (U1), the `.gitignore` union (U11), the
    out-of-place `settings.json` merge (U21), `/fw:plan` by hand (U22), the first commits'
    order (U20).

## IMPs for the retro (task 11), `Destination: framework`

The user requires at least: (1) a permission on an interpreter's check-only option runs code
(`zsh -n +n -c '…'`): a warning in docs/04; (2) `settings.json` merged out of place and
written at once: SETUP Step 3; (3) the inert pointer in `state-inject.sh:50`; (4) the guard's
false positive on a literal bare-clone path; (5) docs/00's step-2 slot missing from the
inventory's edge-case-8 list, evidence for the framework's IMP-139; (6) the release policy as
an answer `/fw:integrate` reads; (7) preflight asks `n/a` for `grafted` while SETUP Step 6
says not to touch it — complete both (`grafted` is touched only for its canonical form or for
the real date proven by git). The report's other candidates are added if they hold at the
retro.

## Links
[[plans/framework-upgrade-v1.2.0-to-v4.1.0]] · [[2026-09-24-language-rule-prospective]] ·
[[2026-07-12-componenti-sensibili]] · [[2026-07-12-trunk-based-su-main]] · [[STATE]]
