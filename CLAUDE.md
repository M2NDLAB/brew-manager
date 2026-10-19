# brew-manager — Claude Code Index

Stack: zsh (macOS-only, no build) | Repo: github.com/M2NDLAB/brew-manager

> This file is the PROJECT's: the answers the method reads and the project's technical
> rules. The method itself — the rules that hold in every session — is
> `.claude/rules/fw-core.md`, which Claude Code loads at every launch; its docs in
> `.claude/docs/` are read when a task needs them, its procedures are the commands under
> `.claude/commands/fw/`, and the memory's `STATE.md` reaches the session through the
> SessionStart hook. Nothing here imports them.

## The answers the method reads

> One line per answer the method's rules and docs read; setup fills each in place of its
> setup marker (the framework's `SETUP.md`, step 2), and an answer may run on to the lines
> below its own.

- **Documentation** — where the project documentation lives (the core's rule 5; `docs/02`, DoD point 7): `README.md`
- **Sensitive components** — the components under the security gate (the core's rule 8; `docs/03`): brew-manager has no auth and no payments: here "sensitive" = blast radius on the
  user's real Mac (removed files, packages installed or upgraded, Homebrew's
  configuration, launchd persistence). The components are the code paths that:
  - **delete** — `brew autoremove` and `brew cleanup -s` in `modules/mod_05_cleanup.sh`;
    the removal of the session's own temporary files in `brew_manager.sh`; until 2.0.0
    also the deletions of `mod_las_scheduler.sh` ([c], Remove), `mod_bk_brewfile.sh`
    (Delete) and `mod_log_manager.sh`
  - **install** — `brew install --cask --adopt` in `modules/mod_00_audit.sh`,
    `brew upgrade` in `modules/mod_04_updates.sh`, `brew upgrade --cask --greedy` in
    `modules/mod_10_greedy.sh` (retired in 2.0.0), the Homebrew installer in
    `brew_manager.sh`; until 2.0.0 also the restore of `mod_bk_brewfile.sh` and
    `mod_mas_mas.sh` (`brew install mas`, `mas upgrade`)
  - **modify Homebrew's configuration** — the developer-mode restore of
    `modules/mod_01_health.sh` and any code that writes a Homebrew setting (only through
    an explicit, shown and confirmed action: the technical rules, Code conventions)
  - **decide what runs** — flag parsing, dispatch and `--yes` in `brew_manager.sh`; the
    resolver and the per-id registries of `lib/selection.sh` (`MODULE_IDS`,
    `MODULE_DESC`, `MODULE_RISK`, `MODULE_DRYRUN`, …: a defect there decides WHICH
    modules run); `_ask`, `_read_choice`, YES_MODE and DRY_RUN in `lib/common.sh` (a
    defect there propagates to ALL modules); until 2.0.0 also the LaunchAgent
    persistence (plists, launchctl) of `mod_las_scheduler.sh` and of the agents'
    restore in `mod_bk_brewfile.sh`
- **Branches** — the integration and the stable branch, and the branching model if it is not the default (`docs/04`, *Branching model*): trunk-based on `main` — the integration branch and the stable branch are both `main` (the two roles COINCIDE): "merge onto the integration branch" and "release on the stable branch" both refer to `main`. Wherever `docs/04` and the commands say `develop`, in this project read `main`. A remote `origin/dev` exists, dormant and aligned with `main` at the time of the graft: it is not the integration branch (decision recorded in `.claude/memory/decisions/`).
- **Merge** — via Pull Request or via the `/fw:integrate` block (`docs/04`, *Merge*): the **`/fw:integrate` block** (single developer, trunk-based on `main`).
- **Public contract** — what the project promises its consumers, whose breaking is a MAJOR (`docs/04`, *Versioning*): any change that forces a consumer to adapt in order to adopt the new version is breaking. brew-manager is a **code** project: its public contract — what a release promises NOT to break without a MAJOR — is the set of these surfaces:
  - **CLI flags** — names and semantics of `--dry-run`, `--yes|-y`, `--adopt=n|all|1,2`,
    `--upgrade=y|n`, `--only=`, `--skip=`, `--version|-V`: removing one, renaming it or
    changing its meaning is MAJOR;
  - **Selection grammar** — the positional `[modules]` (a list of ids, or `go`) plus
    `--only`/`--skip`: changing its format incompatibly is MAJOR;
  - **Module identifiers** — the NUMBERS (`0`–`13`), the `go` keyword and the special
    NAMES (`bk`/`las`/`log`/`mas`) are FROZEN: renumbering, reassigning a number to a
    different module or renaming is MAJOR; new modules are APPENDED (new numbers/names),
    never by reorganising the existing ones. Concrete reason: the numbers are persisted
    in the LaunchAgent plists on users' Macs (`modules=3,5`), and reassigning them would
    silently change what an already-installed agent runs;
  - **Exit-code contract** — the codes pinned by the end-to-end tests
    (`tests/test_exit_codes.zsh`): `0` successful run, `1` a selection that resolves to
    empty, `2` an unknown module token or flag, `69` Homebrew unavailable — not on PATH
    nor at a standard prefix, and the installer not offered (`--dry-run`, no terminal),
    declined or failed (sysexits `EX_UNAVAILABLE`; added in v1.5.0, a MINOR) — changing
    them is MAJOR. Order: `--version` answers first (`0`, even next to an unknown flag),
    then an unknown flag (`2`), then the Homebrew precondition, then the module selection
    (`2` or `1`). *(Outside the contract for now, coming in as an additive extension with
    BM-18: the propagation of a module's runtime failure, which today still exits `0` —
    #4b.)*;
  - **plist/LaunchAgent format** — the schema written by the scheduler into
    `~/Library/LaunchAgents` and the `modules=` field read by the restore: an
    incompatible change breaks the agents already installed, so it is MAJOR.
- **Doc comments** — the language's documentation-comment tool (`docs/02`, *Comments*): a block of `#` comments before the function, as already used in `lib/common.sh` and in the modules — zsh has no native doc comments.
- **Error format** — the structured, stable error format exposed to clients (`docs/02`, *Error handling*): in this project the "client" is the terminal: errors ONLY through `_err`/`_warn` of `lib/common.sh`, with an actionable message; the raw output of failed commands goes to the session log, not to the screen.
- **Formatter / linter** — what the pre-commit hook runs (`docs/02`; `scripts/hooks-install.sh`): NONE active — the block stays commented out in `scripts/hooks-install.sh` with a ready `shfmt` example (shfmt/shellcheck are not installed; decision recorded at the graft). Minimal manual check: `zsh -n` on the touched files; project-wide gates: `make check` (`zsh -n` on every script, blocking) and `make test`; `make lint` runs shellcheck as advisory only.
- **Production artifact** — its format for a deployable component (`docs/02`, DoD point 9): NOT applicable — the repo's scripts ARE the artifact, distributed via `git clone`; the practical equivalent is: the module works from a clean copy of the repo, without depending on local state.

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
- **Releases**: merges of feature, fix and chore branches into `main` use the
  `/fw:integrate` blocks WITHOUT a tag; a tag is born only from a `chore/release-vX.Y.Z`
  branch, whose release merge carries `VERSION` and the annotated tag (the Version rule
  above). The bump reads the answer **Public contract**: breaking it is a MAJOR;
  backward-compatible additions (one more module, appended; a new flag; an optional
  field) are MINOR; fixes that do not touch the contract are PATCH.
- **Standard structure of a component** (= module, for /fw:new-component): see
  `.claude/commands/fw/new-component.md`. In short: a `modules/mod_NN_slug.sh` file
  (loaded automatically by the `mod_*.sh` glob), a `_module_NN` function (number
  without zero-padding; `_module_14`/`_module_15`/`_module_16` are currently taken by
  bk/las/mas — see STATE.md), and an entry in each per-id registry of
  `lib/selection.sh`: `MODULE_DESC` (mandatory: without it the module cannot be
  selected), `MODULE_NAME`, `MODULE_RISK` and `MODULE_DRYRUN` (kept in lockstep by
  the tests); only if it must run in the `go` sequence, also in `MODULE_IDS`. The
  rows of the numbered modules are rendered from the registries (`_menu_row` over
  `MODULE_IDS`); the special modules are also named by hand in `lib/selection.sh`,
  in the menu loop and in the dispatch case of `brew_manager.sh` — full list in
  fw/new-component.md.
- **Code conventions**: internal functions prefixed with `_`; constants and shared
  state in UPPERCASE; TUI output only through the `lib/common.sh` utilities
  (`_section`, `_ok`, `_warn`, `_err`, `_info`, `_item`, `_stat_row`), plus
  `_about_risk` from `lib/selection.sh` for the About block; prompts ONLY
  through `_ask`/`_read_choice` (never a bare `read` for confirmations). Beware of zsh
  arrays: they are 1-based (a source of off-by-one errors this code has already had;
  the known ones are closed, STATE #2). **Every mutating action MUST honour `BREW_MANAGER_DRY_RUN` and
  `BREW_MANAGER_YES`** — it is the by-convention rule that prevents the most
  widespread class of defects that emerged from the assessment (see STATE.md).
  **Homebrew's configuration belongs to the user** (IMP-031): brew-manager never
  changes a Homebrew setting — developer mode, the configuration of Homebrew's own
  repository, the tap-trust store, any persisted setting (`brew analytics`, `brew
  developer`, …) — except through an explicit action that is shown first and confirmed
  (at its prompt, or by an explicit `--yes`), and never under `--dry-run`. Running a
  Homebrew DEVELOPER command counts as such a change (it turns developer mode on), so
  the code never calls one (STATE #30; pinned by a test from task 2 of the 2.0.0 plan).
  **Never pass DATA through `echo`** (new and rewritten code; the existing sites are
  the recorded class STATE #3b, fixed in their planned branches): zsh's
  builtin `echo` expands every backslash escape even without `-e` (`\n`, `\t`, `\\`,
  `\e`, `\0NNN`, `\xNN`, `\uNNNN`, and `\c`, which drops the rest), so a token can
  turn into a different value (BM-08b: `\065` ran mod_05) and JSON gets corrupted
  (STATE #26). To normalise or clean a data string — above all untrusted
  input: CLI tokens, file and app names, brew output, JSON — use parameter expansion
  (`${v// /}`); to hand it on, `printf '%s\n' "$v"` (or `print -r -- "$v"`) for a
  line-oriented consumer (grep, awk, `while read`) and `printf '%s'` where the exact
  bytes matter (`$(...)`, JSON piped to python3). The same expansion hits messages that
  interpolate data: `_ok`/`_warn`/`_err`/`_info`/`_item` and the `_section` title still
  render through `echo -e` (the open debt STATE #3b, to be fixed in the
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
  makes every run wait at the final log prompt, STATE #21) and the output
  in a per-run file, filtered afterwards:
  `f=$(mktemp) && ./brew_manager.sh <id> --dry-run </dev/null >"$f" 2>&1; echo rc=$?`
  (never a fixed /tmp path, STATE #11; the file has CRLF line endings).
  Never pipe input into the prompt (under `script(1)` the menu reads EOF and falls back
  to its default `go`: a full run, which then waits forever at the final log prompt)
  and never truncate the output with `| head` (SIGPIPE kills the run and leaves a
  0-byte session log). A run that does not end is a defect, not a smoke artefact: until
  STATE #21 is fixed, `bk` and `log` never end without a terminal, and `las`
  returns at once without one (its headless smoke only proves the dispatch reaches
  it) — the user smokes those from a real terminal. The menu is checked by the user
  from a real terminal too: a CLI run never renders it.
  - When a suite pins a CONTRACT — a function extracted or moved for parity, or code
    built on the same contract, down to the exit code the user observes — enumerate the
    contract's surface BEFORE writing the suite, as a proportional guide, not a ritual
    for every micro-test: (a) the return value or exit code of EVERY outcome the
    contract promises — where an outcome reaches the user, asserted at the real edge the
    user invokes too, not only at the inner unit; (b) every input class, EDGES included
    (surrounding whitespace, empty tokens, case variants); (c) the MULTIPLICITY of side
    effects (N events for N causes, not just "at least one"); (d) a MUTATION check:
    temporarily break the implementation against the contract (e.g. invert a return),
    watch the suite fail, then restore it — before declaring the suite done.
- **Security gate** (IMP-030, IMP-004 — what brew adds to the core's rule 8; the
  components are the answer **Sensitive components**): every review under the gate is
  run by one independent reviewer, delegated, never the author re-reading their own
  change; it asks what the change does and *what does this now AUTHORISE?*; a
  **refuter** (a second agent with an explicit mandate to refute) is added where the
  change widens what a gated path authorises.
  **Closing a CLASS of defect** (a pattern, not a one-off — in any module, gated or
  not). Before declaring it closed, `grep` the pattern over the WHOLE code base,
  enumerate the sites, and fix or record each one — the usual miss is the twin in
  another module. When the fix touches a consent or safety guard-rail, the verification
  also asks *what does this now AUTHORISE?* (adversarially), not only *does it work?*.
- **Interaction language** (the core's rule 9): Italian.
  - Project boundary of the core's rule 9 for the existing memory: the memory written in Italian
    before the upgrade to framework v1.2.0 (session notes, decisions, components,
    plans, the IMP entries of `LEARNINGS.md`, the existing entries of `STATE.md`,
    `INDEX.md` and `TREE.md`) is NOT translated — translating it is a task the user
    decides, like any other. Everything written from that upgrade on is English; in
    the living files (STATE, INDEX, TREE, LEARNINGS) new or rewritten text is
    English, while entries carried over as they are stay Italian. Mixed
    Italian/English memory is the applied rule, not drift.
- **Deployment**: none — distribution via `git clone` of the repo.
- **Project licence**: MIT, copyright M2NDLAB (the repo's `LICENSE` file; it predates
  the graft and is independent of the framework's MIT).
