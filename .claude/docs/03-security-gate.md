# 03 — Security gate: mandatory review on sensitive components

Security has two levels in this framework:

1. **An always-on baseline** — the pre-commit hook runs secret scanning (gitleaks)
   on every commit: no secret in plaintext enters the repo (rule 1 of `CLAUDE.md`).
   It holds for everything, always, without exceptions. The hook protects commits
   from the moment it is installed: on a repo with PRE-EXISTING history (like this one,
   grafted onto an already existing project) the baseline is COMPLETED by a one-off
   scan of the whole history — `gitleaks detect` — to be run once (in brew-manager it
   was run on 2026-09-25: gitleaks 8.30.1 over every commit of every ref, each merge
   diffed against its parents, 0 findings — `memory/STATE.md`, «Attenzione /
   problemi aperti» #7).
   Findings on the history are the user's decisions: a secret that has already been
   pushed must be rotated/revoked anyway; rewriting history is a different matter and
   is not done lightly.
2. **The gate on sensitive components** — a manual, dedicated security review BEFORE
   taking a critical component into integration. That is what this document is about.

## What "sensitive components" are

The components where a security defect has disproportionate impact:
authentication/authorisation, handling of payments or money, personal data, the edge
that performs enforcement (gateway/proxy), any surface that performs actions on
behalf of a client (e.g. a tool/automation server).

> **Which paths, concretely, in this project — PATH-BASED since IMP-030 (2026-10-07).**
> brew-manager has no auth and no payments: here "sensitive" = blast radius on the
> user's real Mac (removed files, packages installed or upgraded, Homebrew's
> configuration, launchd persistence). The gate applies to a change to a path that:
>
> - **deletes** — `modules/mod_05_cleanup.sh` (`brew autoremove`, `brew cleanup -s`);
>   the session's own temporary files in `brew_manager.sh`; until 2.0.0 also the
>   deletions of `mod_las_scheduler.sh` ([c], Remove), `mod_bk_brewfile.sh` (Delete) and
>   `mod_log_manager.sh`
> - **installs** — `modules/mod_00_audit.sh` (`brew install --cask --adopt`),
>   `modules/mod_04_updates.sh` (`brew upgrade`), `modules/mod_10_greedy.sh` (`brew
>   upgrade --cask --greedy`, retired in 2.0.0), the Homebrew installer in
>   `brew_manager.sh`; until 2.0.0 also the restore of `mod_bk_brewfile.sh` and
>   `mod_mas_mas.sh` (`brew install mas`, `mas upgrade`)
> - **modifies Homebrew's configuration** — the developer-mode restore of
>   `modules/mod_01_health.sh` (from task 2 of the 2.0.0 plan) and any code that writes
>   a Homebrew setting (CLAUDE.md: only through an explicit, shown and confirmed action)
> - **decides what runs** — `brew_manager.sh` (flag parsing, dispatch, `--yes`),
>   `lib/selection.sh` (the resolver and the per-id registries: `MODULE_IDS`,
>   `MODULE_DESC`, `MODULE_RISK`, `MODULE_DRYRUN`, …), `lib/common.sh` (`_ask`,
>   `_read_choice`, YES_MODE, DRY_RUN — a defect here propagates to ALL modules); until
>   2.0.0 also the LaunchAgent persistence of `mod_las_scheduler.sh`
>
> The files that hold these paths are the **sensitive components** (the list in
> CLAUDE.md, technical rules). An edit to one of them that does not touch such a path —
> wording, a read-only part, a comment — is verified by the author.

## How the gate works

On top of the Definition of Done (`02-code-quality.md`), BEFORE the merge request
(PR) towards the integration branch of a sensitive component:

1. **One review lens** (`/security-review` scoped to the changed paths), asking what the
   change does and *what does this now AUTHORISE?*; a **refuter** (a second agent with
   an explicit mandate to refute) only where the change widens what such a path
   authorises. No multi-hour review workflows unless the risk justifies them.
2. **HIGH/CRITICAL findings → RESOLVED** before the PR. Non-negotiable.
3. **MEDIUM findings → resolved**, or **explicitly accepted** as known debt in
   `memory/STATE.md`, with the reason for accepting them.
4. **LOW/INFO findings → at least recorded** (debt or backlog).

The gate is a GATE, not an optional activity: a component that is "complete" and has
green functional tests can still carry security defects the tests cannot see (a
bypassed check, a spoof, an exposed administrative endpoint). Only a dedicated review
finds them before they reach integration.

**Closing a CLASS of defect** (a pattern, not a one-off — in any module, gated or
not). Before declaring it closed, `grep` the pattern over the WHOLE code base,
enumerate the sites, and fix or record each one — the usual miss is the twin in
another module. When the fix touches a consent or safety guard-rail, the verification
also asks *what does this now AUTHORISE?* (adversarially), not only *does it work?*.
After a substantive fix to a gated path, re-run the lens on the whole branch diff, the
fix included.

## When the review must be adversarial (author ≠ judge)

The criterion is not nominal severity but the **blast radius** of the defect:

- **Adversarial** — the verifier is NOT the author (a second agent, a second person,
  or a second pass with an explicit mandate to REFUTE): for security code in SHARED
  modules, where a defect propagates to several consumers. An author re-reading their
  own work tends to re-read their own assumptions.
- **Author-verifies** — sufficient (and adversarial review is overhead): for factual
  reconnaissance and inspectable local fixes, with zero blast radius.

> **In brew-manager (IMP-030).** The one lens on a gated path is run by a delegated
> reviewer, never by the author re-reading their own change: that is the "second pass".
> The refuter on top of it is added only where the change widens what the path
> authorises.

**Before acting on the findings.** In a multi-agent review — especially after
interruptions or resumes — check COMPLETENESS against the right numbers: the
authoritative source is the review's SYNTHESIS, not the raw counts of an execution
journal (which retries can inflate). First reconcile the count, then act on the
findings.

## Prevention *by convention*

The gate finds defects; conventions prevent them. Where a whole class of errors can
be avoided with a rule (e.g. "management/diagnostics endpoints are never exposed on
the public surface", "every mutating endpoint goes through the authorisation check"),
write the convention into the project's technical rules instead of relying on a
case-by-case review.

## After the review

- The decisions to accept debt go into `STATE.md` (section *Caution & open issues*),
  with the reason.
- If the review teaches something about the **process** (e.g. a component missing
  from the list of sensitive ones, an absent convention), it becomes an IMP proposal
  in `LEARNINGS.md` — see `06-self-improvement.md`. Review lessons are among the best
  sources of improvement.
