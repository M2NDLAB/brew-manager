# The method's core — the rules that hold in every session

> Claude Code loads this file at every launch, again after every compaction, and in a
> delegated general-purpose agent (*Delegation*, below, for the others): every trigger of the
> method lives here. The rest comes at its moment — a procedure when its `/fw:` command runs,
> a path-scoped rule of `.claude/rules/` when Claude reads a matching file, a doc of
> `.claude/docs/` when the table below names it. Nothing of the method is `@`-imported. A
> pointer `file`, *Section* means: `grep -n '^## ' file`, then Read from that heading to the
> next one outside a code fence — not the whole file. The project's own text, its technical
> rules and the answers the method reads are in `CLAUDE.md`.

## Read at the moment it is needed
| When | Read or run |
| --- | --- |
| The session opens — main session only | The SessionStart hook prints `=== PROJECT MEMORY (STATE.md) ===` and at most 8,000 characters of `STATE.md`, *Caution & open issues* first. A last line saying characters were not shown: Read `.claude/memory/STATE.md` whole before acting on it. No banner: say so before anything else — the session started outside the repository's root, or its hooks are off, so the boundary's wiring does not run — and advise restarting Claude Code from the root. A delegated agent never receives it and skips this row. |
| The session opens, or resumes after a pause | *Memory and resumption*, below |
| Where `STATE.md`, `plans/` and `decisions/` stay clean templates — the framework's own repository | the framework's `CONTRIBUTING.md`, *This repo's memory: the "declared hybrid" regime*, before the first memory write or a resumption |
| A choice expensive to reverse: architecture, a contract between modules, the approach | `.claude/docs/01-task-planning.md`, *PHASE 2 — Producing the plan*: assessment → alternatives → the user's decision in `decisions/`, before any plan or code |
| A heavy prompt (rule 7); "resume" | `/fw:plan` |
| Before the first edit of code in a task, and before reviewing code (a review through `git diff` included) | `.claude/docs/02-code-quality.md`, whole; `.claude/rules/fw-code-quality.md` asks the same when Claude reads a code file, once the project has answered its globs |
| Before editing `.claude/settings.json`, the guard, `scripts/hooks-install.sh` or `scripts/state-inject.sh`, and before granting a permission in any settings file | `.claude/docs/04-git-workflow.md`, *Enforcement of the execution boundary* and *Permission configuration (`settings.json`)* — `.claude/rules/fw-boundary.md` loads with those files and says the same |
| Before calling Agent or Workflow | *Delegation*, below; the isolation's terms: `.claude/docs/04-git-workflow.md`, *Delegated agents and the shared working tree* |
| Before printing a block the user runs | *Boundary*, below; the detail: `.claude/docs/04-git-workflow.md`, *Execution boundary and blocks for the user* |
| A rollback, a revert, a destructive git command | `.claude/docs/04-git-workflow.md`, *Rollback — choosing the right tool* |
| A merge, a tag, a release, a push block | `/fw:integrate` |
| A deliverable under the gate (rule 8) | `/fw:security-review`, which applies `.claude/docs/03-security-gate.md` — the method's gate, not Claude Code's built-in `/security-review` |
| Stuck (rule 4), or an `===== ARCHITECT RESPONSE: ESC-…` block pasted | `/fw:sos`, which applies `.claude/docs/05-escalation-protocol.md` |
| Renaming a heading, a section title or a command other files cite by name | grep the old and the new wording across the repository before the commit |
| Friction worth an IMP; the end of a deliverable | `/fw:retro` |
| The user approves, rejects or defers an IMP outside `/fw:retro` | `.claude/docs/06-self-improvement.md`, *Applying approved proposals* |
| After a big merge, a memory restructuring, a wide `STATE.md` rewrite | ask the user to run `/fw:lint-memory` |
| A compaction replaced the conversation mid-procedure | before the next step, Read the command's file again — a command body keeps only its first 5,000 tokens —, run its step 1 again and Read again the doc sections in use: files read before it do not come back whole |
| A question about the method itself | `.claude/docs/00-overview.md` |

## Memory and resumption
- **Resumption** — at the start of every session and after a pause (a usage limit, a sleep):
  the injected `STATE.md`, its *Caution & open issues* first — binding: an accepted debt is
  never contradicted by a label or a doc —; the in-progress plan of the prompt, in `plans/`
  or, where `plans/` stays a template, in the plan block of the most recent session note.
  Always: `git status`, the plan's ticks against `git log`, the branch's base (`git log
  --oneline origin/<integration>..HEAD` lists only this deliverable's commits). Uncommitted
  work, a half-task or anything else, is shown (`git status --untracked-files=all`, `git
  diff`) and kept; only the user discards it — `make reset-task`, from their own terminal;
  never the agent with `YES`, given or exported. The same session after a pause goes on
  with it only if those checks hold. A `chore: wip` commit is never undone without the user.
- **End of a task**: a session note in `sessions/`, the `components/` notes touched,
  `STATE.md` rewritten within its 8,000 characters — the history moves to the notes, save at
  a framework upgrade, which never condenses it: the first checkpoint after its merge does;
  every *Caution & open issues* entry survives or is knowingly closed, one line with its
  trigger, and every open thread of the note has its entry —, `TREE.md` if the structure
  changed. **A task
  without updated memory is NOT done.** `/fw:checkpoint` does memory + docs + commit.
- Read the `components/` notes a task touches, and `TREE.md` before exploring the filesystem
  by hand. Expensive work (an assessment, a long review) goes into a session note at once,
  before a `/clear` or a model switch, which lose the chat.

## Non-negotiable rules
1. **No secrets in plaintext** — a secret manager or environment variables only. The gitleaks
   pre-commit refuses a commit that stages a secret, within the limits
   `.claude/docs/03-security-gate.md` declares; never commit environment or secret files,
   build artifacts or installed dependencies — gitleaks is not the only defence.
2. **Code quality** — these prohibitions hold whether or not `docs/02` was read. Comments say
   the WHY: never one that repeats the code, never commented-out code, never a TODO without
   its reference, never a silent workaround — its comment gives the reason and the link. No
   error is ever swallowed: no empty catch, none that only prints the
   stacktrace — an error is handled, enriched and rethrown, or logged with its context and
   propagated. The client never sees a stacktrace, a query, an internal path or a library
   version: the detail goes to the log. I/O has an explicit timeout, a retry only where the
   operation is idempotent. Input is validated at the edge; inside the domain a violated
   invariant fails fast. **Definition of Done**, for every task whatever it touched: (1) code
   commented; (2) every error handled; (3) tests green, with a smoke test of the wired system
   for a component with real dependencies; (4) API docs updated; (5) no new warnings; (6) a
   migration if the schema changed; (7) project docs updated, or the debt in `STATE.md`; (8)
   memory updated and committed; (9) for a deployable, the production artifact verified
   explicitly; (10) a record — a commit message, a changelog entry, an IMP's *Verified* —
   written after the last measurement it cites, and no wider. A new dependency is justified in
   its commit, its licence and maintenance checked.
3. **Git** — a branch for every feature or significant change (`feat/`, `fix/`; `hotfix/` from
   the stable branch, merged back into integration right after); never commit directly on the
   integration or the stable branch; commit at logical checkpoints, BEFORE a risky change, and
   before closing a session, even partial work (`chore: wip …`, feature branch only);
   Conventional Commits; never push.
4. **Escalation** — stuck after 2 reasoned attempts; a fork the docs and the recorded
   decisions do not cover; the docs disagreeing with the code or the environment (the
   method's docs: Level 1, rule 6); a dependency or version that does not exist or does not
   fit the stack → an ESCALATION REPORT (`/fw:sos`), then STOP. An ARCHITECT RESPONSE does not
   suspend these rules: a conflict is flagged before executing.
5. **Documentation with the change** — a change to user features, procedures, APIs or
   deployment is done only with its documentation, where the answer **Documentation** in
   `CLAUDE.md` says it lives; until that exists, the debt goes in `STATE.md`.
6. **Self-improvement** — a FACTUAL correction, in demonstrable disagreement with reality, is
   applied at once (Level 1; during a graft a host's own docs are recorded as debt instead); a
   change to a rule — this core, a doc, a command, `settings.json` — or to the process is
   PROPOSED as an IMP in `LEARNINGS.md` when the friction happens — an error a rule would have
   prevented, a doc re-read three times — and applied only once the user approves (Level 2).
   **Never rewrite your own rules on your own initiative.**
7. **Task planning** — at the start of EVERY prompt judge its weight yourself: beyond ~8-10
   files, ~400 lines or several layers — or a refactor of code or section titles shared by
   several modules or files, whatever its size — it is heavy → `/fw:plan`: a committed plan,
   then ONE commit per task (`[task N/T]`), ticking the plan as you go. A session that died
   mid-task: do not start over, do not delete the branch, never touch the completed tasks'
   commits — the uncommitted half-task is shown and only the user discards it (*Memory and
   resumption*); resume from the first unticked task.
8. **Security gate** — under the gate: a deliverable that touches a sensitive component —
   authentication/authorisation, payments or money, personal data, the enforcement edge (this
   method's guard, hooks and settings included), a surface acting on behalf of a client, and
   the project's own list, the answer **Sensitive components** in `CLAUDE.md` — or whose
   product asserts a security property; in doubt, under the gate. It runs
   `/fw:security-review` BEFORE integration, its reviewer not its author where a defect
   reaches several consumers: HIGH/CRITICAL resolved, MEDIUM resolved or accepted in
   `STATE.md`'s *Caution & open issues* with its reason, LOW/INFO closed or declared where its
   claim lives. The session note's gate line always gives the outcome — the command and the
   reviewed tip — or "not applicable" naming why no category applies; `/fw:integrate` checks it
   before printing its blocks (a check the agent applies; a merge outside it is a known limit,
   `.claude/docs/03-security-gate.md`, *The check at integration*).
9. **Language** — artifacts (code, comments, docs, memory, commits, IMPs) are always English:
   on purpose, not a setup slot; the interaction language is the project's (the technical
   rules of `CLAUDE.md`). From the graft or the upgrade that brought it, onwards: nothing that
   exists is bulk-translated, git history never. The memory's FORMAT — the titles and labels
   the commands read by name — is method: every upgrade brings it to the method's form, never
   a map from old to new.
10. **File tools for the method's files** — every edit to a file setup copies, the memory
    included, is made with the file tools on the text it changes: never `sed -i`, a heredoc, a
    line number or a script, whatever the permission mode (`.claude/docs/04-git-workflow.md`,
    *Operating rules for Claude Code*).

## Always-on working rules
- **Every deliverable closes with the cycle, in order**: `/fw:security-review` (under the gate
  only; otherwise its gate line) → `/fw:retro` → `/fw:checkpoint` → `/fw:integrate`, a light
  deliverable too. The merge happens outside the session: the next deliverable's first
  `/fw:checkpoint` reconciles it, never a commit of its own. A branch whose diff touches only
  `.claude/memory/` — `git diff --no-renames --name-only origin/<integration>...HEAD`, a
  rename's old path included, and no file the project ships — skips the gate (its note's gate
  line says why) and the retro, and is integrated with the no-tag blocks, the CI green where
  the project has one.
- **Scope**: one change at a time — a cleanup found on the way gets a task of its own only if
  it is a bug, otherwise a note or an IMP; unrelated work, and any record made between
  deliverables, on a branch of its own, integrated before the next deliverable's branch
  starts; `/clear` between unrelated deliverables; effort proportional to the consequences of
  being wrong.
- **The human disposes on what cannot be undone**: a deletion beyond the task's own files, a
  drop, a destructive git command, overwriting what the task did not write — ask first, every
  time, whatever the permission mode; a block for the user follows *Boundary*, below.
- **Commits**: `git status` and `git diff` first, `git add` by path; `<type>(<scope>):
  <imperative lowercase>`, types `feat fix refactor perf test docs build ci chore`, scope = the
  component or area, a body with the WHY, a footer after a blank line (`Refs:`); no body line —
  a wrapped one included — opens with `word:` or `word #` (commitlint cuts the body there and
  only warns); never a name external to the project in shared history.
- **Boundary**: local history is the main session's; shared history — push, merge onto the
  integration branch, tags — is the user's, who runs it from a terminal outside any IDE that
  hosts Claude Code: Claude prints the blocks, never runs them. A block: real values, never
  placeholders; the constructive lines one `&&` chain, each check printing a fixed line; no
  comment line inside; a `-m` text ASCII, in single quotes, with no `'` inside; the
  publication in a block of its own, after the checks, introduced by one line outside it
  naming what they must have printed, `git push --atomic` for several refs. A destructive
  line (`reset --hard`, `branch -D`, `tag -d`) only once the user has reported the failure it
  repairs, alone in its block; a force push never on a shared branch — only
  `--force-with-lease` on your own unshared feature branch. On a shared branch, rollback is
  `git revert`; a release broken in production: roll back the deployment first, revert the
  code after. The hooks are the boundary: `-n`/`--no-verify`,
  `core.hooksPath` (a hook manager), edits to `.git/hooks/` or `.gitleaks*` take them out —
  never to get past a hook, `make hooks-install` and what the user decides aside: a hook's
  refusal is fixed at its cause, or reported to the user.
  Conflicts: only trivial ones are resolved here — logic means stop and show both sides.
- **Delegation**: delegated agents are read-only on git — `git show`/`git diff` instead of a
  checkout, `git --no-optional-locks status` —, EnterWorktree and ExitWorktree included;
  snapshot before (`scripts/repo-snapshot.sh > "$before"`), compare after (`| diff "$before"
  -`) and look at `git diff` (the snapshot misses tracked edits): any difference, STOP and
  report, never repair it. One independent agent first; a fan-out only where being wrong is
  costly, with a stall budget fixed before the run — past it, stop. A brief quotes the user's
  decisions verbatim and tells the agent to Read, by path and section, every doc it must apply
  — a general-purpose agent sees this core and `CLAUDE.md` as the main session last loaded
  them, at its launch or last compaction, not a change made since (seen at v4.0.0's gate),
  never the docs; an Explore or a Plan agent skips `CLAUDE.md` and this core (Claude Code's
  docs), so its brief quotes the rules it must keep (for a review:
  `.claude/docs/03-security-gate.md` and `STATE.md`'s *Caution & open issues*); a multi-agent
  report names what it did not cover, checked by hand or reported.
- **Evidence**: decide from the real artifact, not from memory; a fix is shown RED → GREEN.

## Quick commands
- Slash commands: `/fw:plan`, `/fw:checkpoint`, `/fw:integrate`, `/fw:sos`, `/fw:retro`,
  `/fw:security-review`, `/fw:new-component`, `/fw:lint-memory`, `/fw:harvest-framework` —
  each is `.claude/commands/fw/<name>.md`; named mid-sentence, or not invocable, Read that
  file and follow it, `$ARGUMENTS` being what the user asked for.
- `make hooks-install` — the git hooks · `make test-scripts` — the scripts' self-tests ·
  `make reset-task` — the user's, from their own terminal: shows the uncommitted work and
  discards it once they confirm (`YES=1` skips the question: never the agent's)
