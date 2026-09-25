# brew-manager — Claude Code Index

Stack: zsh (macOS-only, no build) | Repo: github.com/M2NDLAB/brew-manager

> This file is the **index** Claude Code reads to get its bearings: it points to the
> process documentation and to the persistent memory, and it fixes the
> non-negotiable rules. The rules below are about PROCESS (stack-agnostic); the
> project's technical rules go in the last section.

## Process documentation — load ONLY the files relevant to the task
- @.claude/docs/00-overview.md            — the method, the end-of-deliverable cycle, selective loading
- @.claude/docs/01-task-planning.md       — task plan for heavy prompts, resilient resumption
- @.claude/docs/02-code-quality.md        — comments, error handling, Definition of Done
- @.claude/docs/03-security-gate.md       — mandatory review on sensitive components
- @.claude/docs/04-git-workflow.md        — when to commit, branch, merge, rollback
- @.claude/docs/05-escalation-protocol.md — structured report when you get stuck
- @.claude/docs/06-self-improvement.md    — doc corrections, IMP backlog, retrospective

## Persistent memory — MANDATORY in every session
- AT THE START of a session: read @.claude/memory/STATE.md (injected by the
  SessionStart hook) and the .claude/memory/components/ notes of the components the
  task actually touches; read TREE.md before exploring the filesystem by hand. Check
  whether an in-progress plan exists in .claude/memory/plans/ for the requested
  prompt (see rule 7).
- AT THE END of a task: session note in memory/sessions/, update the components/
  notes you touched, rewrite STATE.md, regenerate TREE.md if the structure changed.
  **A task without updated memory is NOT done.**
- Use the /checkpoint slash command to do memory + docs + commit in one go.

## Non-negotiable global rules (process)
1. **No secrets in plaintext** in the code or in committed config — only a secret
   manager or environment variables. The gitleaks hook blocks commits that violate
   this rule (it is the baseline; see also the security gate, rule 8).
2. **Code quality** per 02-code-quality.md: the WHY in comments, no swallowed
   exceptions, validation at the edge, Definition of Done respected.
3. **Git** per 04-git-workflow.md: a branch for every feature, commits at logical
   checkpoints and BEFORE risky changes, Conventional Commits, never push without
   the user's confirmation.
4. **Escalation** per 05-escalation-protocol.md: stuck after 2 reasoned attempts, or
   facing a fork the docs and recorded decisions do not cover? Do NOT push on
   blindly: produce an ESCALATION REPORT and stop. The answer comes back as an
   ARCHITECT RESPONSE block — carry it out per the protocol.
5. **Documentation updated** TOGETHER with the change: a change that touches user
   features, procedures, APIs or deployment is not done until the documentation is
   aligned (where the project documentation lives: `README.md`). Same
   logic as the memory. Until the project documentation exists, record the debt in
   STATE.md.
6. **Self-improvement** per 06-self-improvement.md: FACTUAL corrections to the docs
   (in demonstrable disagreement with reality) you apply immediately; changes to
   RULES and process you PROPOSE in memory/LEARNINGS.md (IMP-nnn) and apply only
   after the user approves. **Never rewrite your own rules on your own initiative.**
7. **Task planning** per 01-task-planning.md: at the start of EVERY prompt judge its
   heaviness yourself; if it is heavy, produce a PLAN of atomic tasks in
   .claude/memory/plans/, commit it, then run ONE COMMIT PER TASK (`[task N/T]` in
   the message) ticking the plan as you go. If a session is interrupted: do NOT
   start over and do NOT delete the branch — discard only the uncommitted half-done
   task (scripts/reset-task.sh) and resume from the first unticked task. The commits
   of completed tasks are never touched.
8. **Security gate** per 03-security-gate.md: on sensitive components
   (`mod_00_audit`, `mod_05_cleanup`, `mod_bk_brewfile`, `mod_las_scheduler`,
   `brew_manager.sh`, `lib/common.sh`, `lib/selection.sh` — list with its rationale
   in 03-security-gate.md) run /security-review BEFORE the PR; HIGH/CRITICAL
   findings resolved, MEDIUM resolved or accepted as debt in STATE.md (with the
   reason), LOW at least recorded.
9. **Language** — two axes, and only one of them is yours to choose:
   - **ARTIFACTS: always English.** Everything that lands in the repo — code,
     comments, documentation, memory, future commit messages, IMP entries, session
     notes — is written in English. This is deliberately NOT a
     [TO BE DEFINED AT SETUP] slot. The framework is opinionated here on purpose:
     English artifacts are the universal practice of open source, and they keep a
     project readable, greppable and portable beyond the people who started it. The
     trade-off is stated openly rather than hidden — on this one axis the framework
     imposes instead of staying agnostic, and it accepts the cost.
   - **INTERACTION: yours.** The language the agent speaks with you in session is a
     [TO BE DEFINED AT SETUP] slot in the technical rules below. Talking to you in
     your own language costs the repo nothing, so nothing is imposed.
   Past git history is never translated: it is immutable (see 04-git-workflow.md).

## Quick commands
- Slash commands: `/checkpoint`, `/integrate`, `/sos`, `/retro`, `/security-review`,
  `/new-component`, `/lint-memory`, `/harvest-framework`
- `make hooks-install` — install the git hooks (gitleaks + commitlint)
- `make test-scripts` — self-test of the framework scripts (hooks-install)
- `./scripts/reset-task.sh` — discard the interrupted half-done task (keeps commits)

---

## Project-specific technical rules

- **Stack**: pure zsh, macOS-only. No compilation, no build: the scripts are the
  artifact. Runtime dependencies: Homebrew (built-in installer), `script(1)`,
  `python3` (JSON parsing in mod_03), `mas` (optional, mas module), `launchctl`,
  `mdfind`, `tput`, `open(1)`.
- **Run**: `./brew_manager.sh` (interactive TUI; `make run`). CLI selection: the
  positional `[modules]` (a list of ids, or `go`) plus `--only=`/`--skip=`. Flags:
  `--dry-run`, `--yes|-y`, `--adopt=n|all|1,2`, `--upgrade=y|n`, `--version|-V`.
  Only `brew_manager.sh` is executable: `lib/` and `modules/` are sourced.
- **Version**: the `VERSION` file at the root is the authoritative source;
  `git describe` only enriches it when there is a work tree. At release time
  `VERSION` and the tag are updated in the SAME commit — `make version-check` fails
  if they diverge.
- **Standard structure of a component** (= module, for /new-component): see
  `.claude/commands/new-component.md`. In short: a `modules/mod_NN_slug.sh` file
  (loaded automatically by the `mod_*.sh` glob), a `_module_NN` function (number
  without zero-padding; `_module_14`/`_module_15`/`_module_16` are currently taken by
  bk/las/mas — see STATE.md), and an entry in each per-id registry of
  `lib/selection.sh`: `MODULE_DESC` (mandatory: without it the module cannot be
  selected), `MODULE_NAME`, `MODULE_RISK` and `MODULE_DRYRUN` (kept in lockstep by
  the tests); only if it must run in the `go` sequence, also in `MODULE_IDS`. The
  rows of the numbered modules are rendered from the registries (`_menu_row` over
  `MODULE_IDS`); the special modules are also named by hand in `lib/selection.sh`,
  in the menu loop and in the dispatch case of `brew_manager.sh` — full list in
  new-component.md.
- **Code conventions**: internal functions prefixed with `_`; constants and shared
  state in UPPERCASE; TUI output only through the `lib/common.sh` utilities
  (`_section`, `_ok`, `_warn`, `_err`, `_info`, `_item`, `_stat_row`), plus
  `_about_risk` from `lib/selection.sh` for the About block; prompts ONLY
  through `_ask`/`_read_choice` (never a bare `read` for confirmations). Beware of zsh
  arrays: they are 1-based (a source of off-by-one errors this code has already had;
  the known ones are closed, STATE.md item 2). **Every mutating action MUST honour `BREW_MANAGER_DRY_RUN` and
  `BREW_MANAGER_YES`** — it is the by-convention rule that prevents the most
  widespread class of defects that emerged from the assessment (see STATE.md).
  **Never pass DATA through `echo`** (new and rewritten code; the existing sites are
  the recorded class STATE Attenzione #3b, fixed in their planned branches): zsh's
  builtin `echo` expands every backslash escape even without `-e` (`\n`, `\t`, `\\`,
  `\e`, `\0NNN`, `\xNN`, `\uNNNN`, and `\c`, which drops the rest), so a token can
  turn into a different value (BM-08b: `\065` ran mod_05) and JSON gets corrupted
  (STATE Attenzione #26). To normalise or clean a data string — above all untrusted
  input: CLI tokens, file and app names, brew output, JSON — use parameter expansion
  (`${v// /}`); to hand it on, `printf '%s\n' "$v"` (or `print -r -- "$v"`) for a
  line-oriented consumer (grep, awk, `while read`) and `printf '%s'` where the exact
  bytes matter (`$(...)`, JSON piped to python3). The same expansion hits messages that
  interpolate data: `_ok`/`_warn`/`_err`/`_info`/`_item` and the `_section` title still
  render through `echo -e` (the open debt STATE Attenzione #3b, to be fixed in the
  helpers), so new code never adds an `echo` of its own on data, and nothing a helper
  prints is ever a source of data. A parity refactor that moves the parsing of
  untrusted input must report the fail-open patterns it carries along instead of
  treating them as neutral.
  Formatter/linter: none active in the hook (candidates: `shfmt`/`shellcheck`, not
  installed; block prepared but commented out in `scripts/hooks-install.sh`);
  `make lint` runs shellcheck as ADVISORY when installed. Syntax gate: `make check`
  (`zsh -n` on every script); zero-cost check on a single file: `zsh -n <file>`.
- **Tests**: a hand-rolled zsh harness in `tests/`, zero dependencies, run by
  `make test` (a blocking gate); bats remains a future candidate. Minimal
  verification for every change: `zsh -n` on the touched files + a smoke run of the
  module concerned, selected on the CLI, with stdin from `/dev/null` (an open stdin
  makes every run wait at the final log prompt, STATE Attenzione #21) and the output
  in a per-run file, filtered afterwards:
  `f=$(mktemp) && ./brew_manager.sh <id> --dry-run </dev/null >"$f" 2>&1; echo rc=$?`
  (never a fixed /tmp path, STATE Attenzione #11; the file has CRLF line endings).
  Never pipe input into the prompt (under `script(1)` the menu reads EOF and falls back
  to its default `go`: a full run, which then waits forever at the final log prompt)
  and never truncate the output with `| head` (SIGPIPE kills the run and leaves a
  0-byte session log). A run that does not end is a defect, not a smoke artefact: until
  STATE Attenzione #21 is fixed, `bk` and `log` never end without a terminal, and `las`
  returns at once without one (its headless smoke only proves the dispatch reaches
  it) — the user smokes those from a real terminal. The menu is checked by the user
  from a real terminal too: a CLI run never renders it.
- **Sensitive components** (rule 8): `mod_00_audit` (app adoption),
  `mod_05_cleanup` (autoremove/cleanup), `mod_bk_brewfile` (restore, plist),
  `mod_las_scheduler` (LaunchAgent persistence), plus `brew_manager.sh` and
  `lib/common.sh` as the shared infrastructure of the guard-rails (a defect in
  `_ask`/YES_MODE or in the dispatch propagates to every module), and
  `lib/selection.sh`, the selection resolver and the per-id registries (a defect
  there decides WHICH modules run, for the CLI, the menu and the LaunchAgents).
- **Where the project documentation lives** (rule 5): `README.md`.
- **Interaction language** (rule 9): Italian.
  - Project boundary of rule 9 for the existing memory: the memory written in Italian
    before the upgrade to framework v1.2.0 (session notes, decisions, components,
    plans, the IMP entries of `LEARNINGS.md`, the existing entries of `STATE.md`,
    `INDEX.md` and `TREE.md`) is NOT translated — translating it is a task the user
    decides, like any other. Everything written from that upgrade on is English; in
    the living files (STATE, INDEX, TREE, LEARNINGS) new or rewritten text is
    English, while entries carried over as they are stay Italian. Mixed
    Italian/English memory is the applied rule, not drift.
- **Memory section titles**: the method files cite memory sections by their English
  name, while this project's memory keeps its Italian headings. The headings are
  identifiers (code comments and tests cite "STATE Attenzione #N"): never translate
  or rename them outside a dedicated task decided by the user. Map, one per line —
  English name cited by the method → heading in this project:
  - STATE.md "Progress" → `## Stato avanzamento`
  - STATE.md "What exists" / "What exists now" → `## Cosa esiste adesso`
  - STATE.md "Decisions made" → `## Decisioni prese (non ovvie dal codice)`
  - STATE.md "Documentation debt" → `## Debito documentazione`
  - STATE.md "Caution & open issues" → `## Attenzione / problemi aperti`
  - STATE.md "Active branches" → `## Branch attivi`
  - LEARNINGS.md "OPEN proposals" → `## Proposte APERTE (in attesa di decisione utente)`
  - LEARNINGS.md "Applied" → `## Applicate`
  - LEARNINGS.md "Deferred" → `## Rimandate`
  - LEARNINGS.md "Rejected" → `## Rifiutate`
  - LEARNINGS.md IMP fields: "Origin" → `Origine`, "Observed problem" → `Problema osservato`, "Proposal" → `Proposta`, "Expected benefit / risk" → `Beneficio atteso / rischio`, "Resumption trigger" → `Trigger di ripresa`, "Destination" → `Destinazione` (the legacy marker, still collected by /harvest-framework)
- **Deployment**: none — distribution via `git clone` of the repo.
- **Project licence**: MIT, copyright M2NDLAB (the repo's `LICENSE` file; it predates
  the graft and is independent of the framework's MIT).
