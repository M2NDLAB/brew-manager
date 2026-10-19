# 03 — Security gate: mandatory review on sensitive components

Security has two levels in this framework:

1. **An automatic baseline** — the pre-commit hook runs secret scanning (gitleaks)
   on the changes staged for a `git commit`, and refuses the commit when it finds a
   secret (rule 1 of the core, `.claude/rules/fw-core.md`), from the moment it is installed and while git reads
   it. Its limits include the commits git creates itself — a rebase's `--continue`,
   `git am`, a cherry-pick or a revert that applies cleanly —, which do not run it, a
   commit made with `-n` (`--no-verify`) where the guard does not see it — from the user's
   own terminal, a script, a session whose guard cannot run or that runs none of the
   project's hooks (`04-git-workflow.md`, *Enforcement of the execution boundary*) —, and a
   hook manager that sets
   `core.hooksPath` after the install, which takes it out
   (`04-git-workflow.md`, *Enforcement of the execution boundary*); the scan's own limits
   are listed in the framework's `SETUP.md`, *What the pre-commit's scan reads*. On a repo with
   PRE-EXISTING history (grafting the framework onto an existing project) the baseline
   is COMPLETED by a one-off scan of the whole history — `gitleaks detect` — as a setup
   step (step 3 of the framework's `SETUP.md`).
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

> **Which ones, concretely, in this project:** the answer **Sensitive components** in
> `CLAUDE.md`, *The answers the method reads* — the list step 2 of the end-of-deliverable
> cycle points to.

## How the gate works

On top of the Definition of Done (`02-code-quality.md`), BEFORE the merge request
(PR) towards the integration branch of a sensitive component:

1. **`/fw:security-review`** run on the branch diff — and on the set a widened claim names
   (*The lenses of the gate*).
2. **HIGH/CRITICAL findings → RESOLVED** before the PR. Non-negotiable.
3. **MEDIUM findings → resolved**, or **explicitly accepted** as known debt in
   `memory/STATE.md`, with the reason for accepting them.
4. **LOW/INFO findings → closed, or declared.** One that a line of text closes — a claim
   narrowed to what the code does — is closed in the release. One that it does not close
   becomes a known limit, declared where the claim it concerns lives — the document, the
   comment or the message that states what the code does —, not a proposal in the
   backlog; a lesson about the process still becomes one (*After the review*).

The gate is a GATE, not an optional activity: a component that is "complete" and has
green functional tests can still carry security defects the tests cannot see (a
bypassed check, a spoof, an exposed administrative endpoint). Only a dedicated review
finds them before they reach integration.

## The check at integration

The gate is never activated by a file's path: it holds in every session, from the method's
core (`.claude/rules/fw-core.md`, rule 8), loaded at every launch, on the categories above —
in doubt, under the gate. And the
session note that closes a deliverable records its verdict, the review's outcome and the tip
it reviewed (`.claude/memory/sessions/README.md`, *The security gate's line*), which
`/fw:integrate` reads before it prints its blocks — in the Pull Request form, when the agent
prepares the PR. It stops on a missing note or line; on "not applicable" for a deliverable
that touches a sensitive component — the method's own boundary among them — or asserts a
security property; on a review other than `/fw:security-review`, or no reviewed tip; on a
commit after the reviewed tip that touches a file the project ships, the commit of its own
step 3 aside; on a HIGH or CRITICAL finding still open, and on a MEDIUM neither
resolved nor accepted; and on an integration branch that moved since the branch was based,
before its step 3 commits a changelog entry under a version computed on the old base — as
the last fetch recorded it: a move after that fetch is stopped by block 1, whose own fetch
and test of the base run inside its chain.

Its known limits, declared here where the claim lives: it is a check the agent applies, not
an enforcement. A merge made outside `/fw:integrate` — a Pull Request merged on the forge, a
merge typed by hand, a PR the user opens without the agent — never passes through it; and
it reads what the note records, so a line that claims a review which did not run, or a
verdict wider than the review's, passes it. Its step 3 writes the changelog after the review,
if the project keeps one: under the gate the entry's text goes in `[Unreleased]` before the
review, and step 3 only moves it. A forge's required review or status check is the enforcement, where the project
has one.

## The lenses of the gate

A review that reads only what the code DOES can miss what the product SAYS, and the path a
tool takes to its effect. Every review of the gate applies the two lenses below, and a
deliverable whose product asserts a security property is under the gate for that alone.

- **Claims, not only actions.** Every assertion the product makes about a security property
  — a status, a badge, a summary, an "OK", "nothing changed", "no leaks found" — is checked
  against what the code really does, not against the contract it is meant to honour. An
  assertion that something did NOT happen needs a datum that shows it — what was read, and
  how much —, kept apart from the classification it would otherwise be inferred from. A
  debt accepted below (*After the review*) turns into a broken promise the moment a label
  or a freshly written document asserts the contrary. The perimeter is the claim's, not the
  diff's: when a change widens a claim — from these N to all, a list of exceptions that
  disappears, a range of versions —, the review covers the set the claim names, beyond the
  files the change touched.
- **The real path.** A gate on an external tool covers what the tool does by itself on the
  way to its effect: what its configuration — the user's included — makes it do, and what it
  updates, writes or fetches unasked, read at its source or in its documentation; and where
  and when it reads the configuration the gate relies on — the files, the directory it starts
  from, the moment it reads them (a delegated agent gets the instructions its session last
  loaded, not the files on disk), the flags and settings that skip them. Each such path is
  closed by the tool's own off-switch, compensated, or declared as a known limit; a path left
  unread is a gap of the gate. A statement about an external tool rests on its source's own
  text, the passage quoted in the record — never on a summary of it, a model's answer about
  a page included.

## When the review must be adversarial (author ≠ judge)

The criterion is not nominal severity but the **blast radius** of the defect:

- **Adversarial** — the verifier is NOT the author (a second agent, a second person,
  or a second pass with an explicit mandate to REFUTE): for security code in SHARED
  modules, where a defect propagates to several consumers. An author re-reading their
  own work tends to re-read their own assumptions.
- **Author-verifies** — sufficient (and adversarial review is overhead): for factual
  reconnaissance and inspectable local fixes, with zero blast radius.

One independent reviewer comes first; a fan-out of reviewers, then verifiers, only where
the blast radius warrants it, with a stall budget fixed before the run — and its report
names what it did not cover (`00-overview.md`, *Scope and session hygiene*).

**Before acting on the findings.** In a multi-agent review — especially after
interruptions or resumes — check COMPLETENESS against the right numbers: the
authoritative source is the review's SYNTHESIS, not the raw counts of an execution
journal (which retries can inflate). First reconcile the count, then act on the
findings.

**Review agents read, they never write.** The agents of a review are delegated agents:
read-only on git, reading the range with `git show`/`git diff` rather than checking it
out, with the shared repository's snapshot compared before and after the run —
`docs/04`, *Delegated agents and the shared working tree*. What a reviewer must RUN, the
main session prepares before the launch: every repository the review needs — the
projects an upgrade is rehearsed on, a clone carrying the release's temporary tag, a
repository for each measurement the brief asks for —, named in the brief, since the guard
refuses an agent's `git init`, `clone` or `tag` and a reviewer stopped there reviews nothing
it had to run. A reviewer stopped by the guard or by a permission prompt stops and reports
it, never gets around it; a fixture it finds missing is asked for, not built.

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
