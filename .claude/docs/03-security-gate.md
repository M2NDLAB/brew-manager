# 03 — Security gate: mandatory review on sensitive components

Security has two levels in this framework:

1. **An always-on baseline** — the pre-commit hook runs secret scanning (gitleaks)
   on every commit: no secret in plaintext enters the repo (rule 1 of `CLAUDE.md`).
   It holds for everything, always, without exceptions. The hook protects commits
   from the moment it is installed: on a repo with PRE-EXISTING history (like this one,
   grafted onto an already existing project) the baseline is COMPLETED by a one-off
   scan of the whole history — `gitleaks detect` — to be run once (in brew-manager it
   is recorded as debt in `memory/STATE.md`, section «Attenzione / problemi aperti»).
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

> **Which ones, concretely, in this project.** brew-manager has no auth and no
> payments: here "sensitive" = blast radius on the user's real Mac (removed files,
> packages installed/uninstalled, launchd persistence). These fall under the gate:
>
> - `modules/mod_00_audit.sh` — app adoption with `brew install --cask --adopt`
> - `modules/mod_05_cleanup.sh` — `brew autoremove` + `brew cleanup -s` (removals)
> - `modules/mod_bk_brewfile.sh` — restore (installs packages, writes plists,
>   `launchctl load`)
> - `modules/mod_las_scheduler.sh` — LaunchAgent persistence in `~/Library/LaunchAgents`
> - `brew_manager.sh` — dispatch, flag parsing, execution with `--yes`
> - `lib/common.sh` — shared guard-rail infrastructure (`_ask`, `_read_choice`,
>   YES_MODE, DRY_RUN): a defect here propagates to ALL modules
> - `lib/selection.sh` — the selection resolver (`_resolve_selection`,
>   `_resolve_cli`, `_collect_module_tokens`, `_selection_is_valid`) and the per-id
>   registries (`MODULE_IDS`, `MODULE_DESC`, `MODULE_RISK`, `MODULE_DRYRUN`, …): a
>   defect here decides WHICH modules run — for the CLI, the menu and the
>   LaunchAgents alike — and what the session summary attests about them
>
> Medium risk, outside the gate but to be handled with care (preview + confirmations):
> `mod_04_updates`, `mod_10_greedy`, `mod_mas_mas` (global upgrades / mas install).

## How the gate works

On top of the Definition of Done (`02-code-quality.md`), BEFORE the merge request
(PR) towards the integration branch of a sensitive component:

1. **`/security-review`** run on the branch diff.
2. **HIGH/CRITICAL findings → RESOLVED** before the PR. Non-negotiable.
3. **MEDIUM findings → resolved**, or **explicitly accepted** as known debt in
   `memory/STATE.md`, with the reason for accepting them.
4. **LOW/INFO findings → at least recorded** (debt or backlog).

The gate is a GATE, not an optional activity: a component that is "complete" and has
green functional tests can still carry security defects the tests cannot see (a
bypassed check, a spoof, an exposed administrative endpoint). Only a dedicated review
finds them before they reach integration.

## When the review must be adversarial (author ≠ judge)

The criterion is not nominal severity but the **blast radius** of the defect:

- **Adversarial** — the verifier is NOT the author (a second agent, a second person,
  or a second pass with an explicit mandate to REFUTE): for security code in SHARED
  modules, where a defect propagates to several consumers. An author re-reading their
  own work tends to re-read their own assumptions.
- **Author-verifies** — sufficient (and adversarial review is overhead): for factual
  reconnaissance and inspectable local fixes, with zero blast radius.

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
