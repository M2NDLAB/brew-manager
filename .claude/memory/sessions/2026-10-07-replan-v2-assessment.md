---
date: 2026-10-07
task: read-only assessment for the 2.0.0 re-plan (a personal terminal tool) — the removal of bk/las/log/mas, the session recording, every open STATE entry, Homebrew 6/7 compatibility; then the critic of the draft plan
branch: main (read-only at 37b8db5); then chore/replan-v2 (task 1 of the plan)
status: completed
model: 'claude-opus-5-5'
turns: 2
tags: [session, assessment, v2, homebrew, scope]
---
# Session 2026-10-07 — the 2.0.0 re-plan: read-only assessment

After the v1.5.0 release (merge `37b8db5`, annotated tag `v1.5.0` → object `deb8f61`,
pushed) the user asked for a READ-ONLY re-plan under the new scope
([[decisions/2026-09-27-personal-terminal-tool]]): the removal of bk, las, the log
module and mas; the session recording and `_handle_log`; every open STATE entry;
Homebrew 7.x compatibility; process proportionality; the branch order to 2.0.0. The
user approved the result with precisions on 2026-10-07 →
[[decisions/2026-10-07-v2-plan]] and [[plans/v2-personal-tool]]. This note is the full
evidence base, so later branches point at a finding instead of re-deriving it. The
line numbers are those of `main` at `37b8db5`.

## Method
- Four read-only analysts in parallel (removal impact; recording; STATE triage; Homebrew
  6/7), then one critic of the draft plan. Sandboxes and a shallow clone of Homebrew
  7.0.8 only under the session scratchpad; no repo write, no mutating brew command, no
  process left. The appendices below are their reports, verbatim.
- Facts checked by the main session: `brew --version` = `Homebrew 6.0.21-70-g2316567`
  (developer mode on: `homebrew.devcmdrun = true`); upstream latest 7.0.8 (7.0.0 and
  7.0.1 on 2026-09-13); no `com.m2ndlab.*` plist in `~/Library/LaunchAgents` and no such
  job loaded; mod_10's grep for `auto_updates: true` never matches (brew prints
  `(auto_updates)` in the title; all 5 recorded logs say "Casks with auto_updates flag
  0"); mod_01:32 runs `brew ruby --version`, a developer command.
- **The user's question on D3, verified on the installed brew (6.0.21)**: plain `brew
  upgrade` upgrades an `auto_updates` cask when the app bundle is OLDER than the tap
  version (`cask/cask.rb:445-448`, `auto_updates_bundle_outdated?`). The behaviour
  arrived in 5.1.6 as opt-in (default only with `HOMEBREW_DEVELOPER`) and became the
  default in **6.0.0** (`env_config.rb`: `default: true`; opt-out
  `HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS`). On this Mac plain `brew outdated --cask`
  lists 17 casks, 14 of them `auto_updates`. So the claim holds, with that precision:
  what `--greedy` still adds is re-syncing apps that already updated themselves, and
  `version :latest` casks.

## Outcome
The draft was corrected after the critic (F3 first as its own branch, #3/#14 close only
with the session-log branch, B1 closes only by decision, the rule/contract edits named
in the approval, a path-based gate, the session-log branch before the compatibility
branch, F10 out). The user approved B1–B8 and D1–D11 as recommended, with precisions
recorded in [[decisions/2026-10-07-v2-plan]].

## Task 1 of the plan — `chore/replan-v2` (after the approval)
- `7b29470` — the plan [[plans/v2-personal-tool]], the decision record
  [[decisions/2026-10-07-v2-plan]] and this note (the reports verbatim; the session's
  scratchpad paths replaced by `<session scratchpad>`).
- `dda0ccb` — item 0: v1.5.0 RELEASED in STATE, INDEX, the old plan's task 16 and the
  release note (merge `37b8db5`, tag `v1.5.0` → object `deb8f61`). The triage by decision
  only: #17 and #28 accepted, 4b-3 closed, roadmap-v2 and the pre-Dashboard plan closed
  as superseded, STATE-DEC-README closed as superseded; every other open entry names the
  task that closes it; entries tied to a removed module close in task 3 after a grep;
  new entries #30 (developer mode), #31 (Homebrew 6/7), #32 (the log prompt's Delete
  lies), #33 (a stale cause in comments). No sweep of stale line numbers (each branch
  fixes its own).
- `02cba14` — IMP-030, the path-based gate: CLAUDE.md rule 8 and the sensitive
  paragraph (mod_04 and mod_10 come in as install paths; mod_01 from task 2), docs/03
  (the path list, one lens, the re-gate, author ≠ judge), docs/00, `/new-component`,
  `/security-review`, the 2026-07-12 decision.
- `c820c8f` — IMP-031, the user's rule: Homebrew's configuration changes only through an
  explicit, shown and confirmed action, never under `--dry-run`; a developer command
  counts as such a change.
- Verification: memory and process files only; `make check` green; no code, test or
  user doc touched. Security gate: not applicable (no gated path changed).
- Retro: no new friction (the refused `rm -rf` is IMP-027 already; the critic of the draft
  did its job). No IMP.
- Next: task 2, `fix/homebrew-developer-mode`, on the user's go.

## Appendix A — Removal of bk, las, log and mas

### Removing bk, las, log and mas before v2.0.0: full impact (read-only analysis)

Nothing in the repo or on the system was changed. **[V]** marks what I checked (code read, command run, or a run in a scratch copy). **[I]** marks what I inferred.

#### 0. Starting point [V]

- `git status` is clean on `main`. HEAD is `37b8db5` ("chore(release): merge v1.5.0 into main") and `git describe --tags` gives `v1.5.0`.
- `decisions/2026-09-27-personal-terminal-tool.md` is read. It lists the consequences but decides none of them; they are the user's calls.
- `STATE.md` front matter still says `branch: chore/release-v1.5.0` and "release v1.5.0 **prepared**". That is the reconciliation the user wants in the first branch of the new plan.

#### 1. Every reference to the four modules

##### 1.1 Code

| File | What changes |
|---|---|
| `modules/mod_bk_brewfile.sh` (661 lines), `mod_las_scheduler.sh` (835), `mod_log_manager.sh` (196), `mod_mas_mas.sh` (152) | **Deleted**, 1,844 lines in total. Their functions are `_module_14` (bk:9), `_module_15` (las:9), `_module_log` (log:8) and `_module_16` (mas:8). The module files are loaded by the glob at `brew_manager.sh:322`, so no loader changes. Deleting them also removes the `_module_14` collision (STATE #18) [V]. |
| `brew_manager.sh` | :13 header comment ("bk, las, log, mas"). :155 comment ("modules 4, 10, bk"). :417 hand-written list `Valid modules: 0-13, log, bk, las, mas`. :451-461 the whole **TOOLS** menu section, including the `for tid in log bk las mas` loop at :458. :469-470 the footer example `bk`. :473 the prompt hint `[go / numbers / name …]`. :538-544 the four special branches of the dispatch `case`, which collapses to `"_module_${_mod}"`. The comments at :99, :195-200, :337 and :387 mention LaunchAgents or "the log manager"; rewording them is optional. The PATH bootstrap, `NON_INTERACTIVE`, exit 69 and the summary stay. [V] |
| `lib/selection.sh` | :34-37 comment. `MODULE_DESC` :60-63, `MODULE_NAME` :78-79, `MODULE_DRYRUN` :115 plus its rationale comment :88-102 (all entries become 1), `MODULE_RISK` :137 plus comments :126-128 and :131 (the "0,5,bk,las" list). Resolver: the whole-token arms :204-207, the special-name check in comma lists :227, the filter check :260, and the doc comments :162-169, :179-182 and :244. **`_selection_is_valid` (:323-335) becomes dead code**: its only callers are mod_las (:131, :186) and mod_bk (:140, :181). Remove it. [V] |
| `lib/log.sh` | Not the `log` module, so no change from this removal. It is the only remaining user of `open(1)` (:25, `_handle_log` option [2]); the decision on `_handle_log` is item 2 of the request. [V] |
| `lib/common.sh` | Nothing specific to these modules. The comment at :258 ("scheduled-agent run") can optionally be reworded. [V] |
| Standard modules `mod_00`–`mod_13` | No references, only wording: `mod_07:13` and `mod_05:69`. The latter is the reason behind the `y` default, see §5. [V] |
| `Makefile` | No change: `check` and `test` use globs. [V] |

##### 1.2 Tests

Three anti-vacuity guards would **fail** after the removal, because they require at least 18 modules and only 14 remain. All suites must change in the same commit as the code.

| File:line | What changes |
|---|---|
| `test_risk_badges.zsh:42`, `test_menu_registry.zsh:45`, `test_run_summary.zsh:149` | `>= 18` becomes `>= 14`. **These are the hidden blockers.** [V] |
| `test_menu_registry.zsh:70-74` | The frozen key set `(0…13 log bk las mas)` becomes `(0…13)`. The comment at :71 changes. The `MODULE_IDS == 14` check stays. |
| `test_risk_badges.zsh:61-62, :67, :151` | Drop `log` from the write list, `bk las mas` from the danger list, `bk las` from the sensitive list, and `mod_bk_brewfile` and `mod_mas_mas` from the wiring scan. Left in, the scan would **pass silently**: `grep` on a missing file returns 2, so the check is never made. [V] |
| `test_run_summary.zsh:174-175, :183` | Drop the `MODULE_DRYRUN[mas]` check. `_KNOWN_UNGATED=(bk las)` becomes `()`; the two-way allow-list checks still work with an empty list, and that is the honest state because no module is left without a gate. [V] |
| `test_dryrun_gates.zsh:7-9, :18-20, :30, :147-182` | Remove the whole mas half: the source line, `yes.txt` and 6 `_pass` checks. Section 3 (auto-update end to end) stays. [V] |
| `test_selection.zsh` | Positive checks to remove or flip to "invalid": :168-173, :223-225, :245, :261, :307-308. Remove the `assert_valid_sel` helper :137-152 and the BM-08c block :296-317 (13 checks). About 24 checks go. **Add** checks that each removed name is rejected in every position: lone, upper case, inside a list, in `--only`, in `--skip`, and in the lenient menu path. [V] |
| `test_exit_codes.zsh` | Nothing to remove; no removed names are used. **Add** an end-to-end check next to :132: `assert_exit 2 "removed module (bk)" bk`, plus the hint text if the §2.3 hint is adopted. |
| `test_guardrails.zsh`, `test_capabilities.zsh` | No references. [V] |

##### 1.3 User documentation, process docs, configuration, memory

| File | What changes |
|---|---|
| `README.md` | Delete §"Special modules" (:356-473). Rewrite these lines: :26 (automatic runs via LaunchAgents), :42-47 (PATH note: drop "a scheduled LaunchAgent"), :55 (optional `mas`), :102 (badge text "schedules a LaunchAgent"), :116 and :129-133 (summary example `bk` row and the "two modules still ⚠" list), :149 and :166 (named-module examples), :191 (`--yes`: "Mac App Store updates and restores stay off"), :192 (`--dry-run`: "Two modules still have ungated options"), :201 ("the LaunchAgents installed by the `las` module"), :502-505, :509-510, :512-521 and :529 (project tree, `backups/`, `agents/`), :547-550 ("type `log` at the Choice prompt"), :560, :574-584 (the named-module recipe, including the TOOLS loop at :584). Add an "Upgrading from 1.x" section (§3.3). [V] |
| `SECURITY.md` | :18 (`backups/`, `agents/`, LaunchAgents, `mas`), :22 (`mas upgrade`), :36-39 (gate list: backup/restore, scheduler), :77 (scope item "LaunchAgent abuse"), :80 (`mas` out of scope). [V] |
| `CHANGELOG.md` | Past entries are not edited. The `[1.5.0]` Deprecated section (≈:72-83) already announces the removal and tells users to remove agents "with `./brew_manager.sh las` while you are on 1.5.0". The new `[2.0.0]` section needs **Removed** (the four modules, the plist/LaunchAgent contract surface) and an upgrade procedure for anyone who skipped that step. [V] |
| `.claude/docs/04-git-workflow.md` | :131-136 module identifiers, :147-149 the plist/LaunchAgent item. See §2. [V] |
| `.claude/docs/03-security-gate.md` | :33-35 (mod_bk, mod_las), :43 ("the LaunchAgents alike"), :46 (`mod_mas_mas` as medium risk). [V] |
| `.claude/docs/00-overview.md` | :80, the sensitive list. [V] |
| `CLAUDE.md` | :60 (rule 8 list), :92-93 (runtime dependencies: drop `mas` and `launchctl`; `open(1)` depends on item 2), :105-106 (the `_module_14` note), :154-156 (bk/log hang caveat and "`las` returns at once"), :160-161 and :165 (sensitive list, "the LaunchAgents"). :147 and :152 (the final log prompt) stay while `_handle_log` stays. [V] |
| `.claude/commands/new-component.md` | :10-16 (the `_module_<alias>` form and the collision warning), :43-50 (the "module ids 0-13" hint in mod_las, the special-module wiring, the `for tid in log bk las mas` loop). Proposal: drop the special-module path entirely; no named modules remain, so re-adding one later is a new MINOR design. |
| `.gitignore` :9-13 | **Keep** `backups/` and `agents/`; change only the comment to "left by bk/las, removed in 2.0.0". If the entries go, leftover local data (a Brewfile with local paths, agent configs) shows up as untracked and one `git add -A` commits it. |
| `.claude/commands/checkpoint.md:31` | The tree exclusion `logs\|backups\|agents` stays; the leftover folders still exist on this Mac. |
| Memory | `components/mod-bk-brewfile.md` and `mod-las-scheduler.md` get marked retired in 2.0.0 (history is kept, not deleted). Update `lib-selection.md` (:21, :34-37), `core-brew-manager.md`, `TREE.md`, `INDEX.md`, `decisions/2026-07-12-componenti-sensibili.md`, and the STATE entries; re-evaluating the STATE entries is item 3. [V] |

**Process note.** The edits to `CLAUDE.md` rule 8, the technical rules, docs/03 and docs/00 are rule changes under rule 6. They follow directly from the user's decision, but the plan should list them explicitly so that approving the plan approves them too.

#### 2. The public contract (docs/04)

##### 2.1 What changes, and why it is a major version

1. **Module identifiers (:131-136).** Today the numbers `0`–`13`, `go` and the names `bk`/`las`/`log`/`mas` are frozen. After 2.0.0 the numbers and `go` stay frozen, and the four names are **removed and permanently reserved**: never given to another module. The reason docs/04 gives today still applies: old plists and scripts on users' Macs carry these names, and reusing one would silently change what an old agent runs. The justification sentence should become "numbers and names are what scripts, aliases and any leftover agents pass on the command line".
2. **The plist/LaunchAgent format item (:147-149)** is **deleted**. Nothing writes plists any more, and nothing restores the `modules=` bundle.
3. **Exit codes are unchanged** (0/1/2/69). What changes is the result for existing inputs: `bk`, `las`, `log`, `mas` used to run a module (`0`) and now exit `2`.
4. **Selection grammar.** The numeric and `go` forms are untouched. The special forms disappear: lone `BK`/`LAS`/`LOG`/`MAS`, lowercase names inside a list, and names in `--only`/`--skip`.

Why this is a major version under the docs/04 rule that any change forcing a consumer to adapt is breaking:
- any script, alias or agent that selects one of the four names, or names one in `--only`/`--skip`, now fails with `2` instead of running;
- `go --skip=mas` also fails now, because filter tokens are checked strictly;
- a whole contract surface (the plist format) is withdrawn.

docs/04 already says renaming a module is MAJOR; removing one is a stronger case. Commit form: `feat(core)!: …` with a `BREAKING CHANGE:` footer. `commitlint.config.cjs` extends `config-conventional` and allows `feat` and `refactor`. Whether the `!` passes the hook is **[I]**; it is checked at commit time.

##### 2.2 What the resolver does with a removed name

Checked in a scratch copy of `lib/common.sh` and `lib/selection.sh` with the case arms :204-207 and the two name checks :227 and :260 removed:

| Input | `_resolve_cli` | Result in `brew_manager.sh` |
|---|---|---|
| `bk`, `las`, `log`, `mas`, `BK` | rc 2, `RESOLVE_INVALID=[bk]` | :415-418 exits **2** before dispatch |
| `3,las`, `0,mas,4` | rc 2, `MODULES_TO_RUN=[3]` / `[0 4]` | exits **2**: the valid modules do **not** run (fail-closed) |
| `go --skip=bk`, `go --only=log` | rc 2 | exits **2** |
| `go` | rc 0, modules 0–13 | runs, unchanged |
| Menu `bk` | `_warn "Module 'bk' is invalid — skipped"`, rc 1 | :486-488 "No valid module selected", exits **1** |
| Menu `3,mas` | warning, `[3]` | runs module 3 only (the menu path skips unknown tokens rather than failing) |

No removed name maps onto a remaining module. The `${_spec:-go}` default only applies to an empty spec.

##### 2.3 Proposal: keep exit 2, add a specific message

Do not add a new exit code. That would be another contract change, and launchd and scripts already see a non-zero status.

Add a presentation-only list `RETIRED_MODULE_NAMES=(bk las log mas)` in `selection.sh`. It must never feed the resolver; tests pin that the resolver rejects these names. Next to :416-417, if any invalid token lower-cased (`${(L)…}`) is in that list, print a constant line: "bk, las, log and mas were removed in 2.0.0 — see CHANGELOG.md". Do the same after the menu warning. The text is a constant, so it does not run into the echo-on-data debt (#3b). It also lands in a leftover agent's stdout log, which is where a user would look to find why the agent fails. Pin it in `test_exit_codes.zsh` (rc 2 and the text present).

#### 3. LaunchAgents already installed

##### 3.1 This Mac [V]

- `ls ~/Library/LaunchAgents | grep m2ndlab`: no match. The folder holds only `com.epicgames.launcher.plist`.
- `launchctl list | grep m2ndlab`: no match. `launchctl print gui/501 | grep -ci m2ndlab`: 0.
- `agents/` contains only `agents_activity.log` (564 B): five INSTALLED lines for a test agent `com.m2ndlab.brew-manager.rotest` from 2026-07-17 (`modules=8,9` / `go`) and no REMOVED line. Its plist is gone and it is not loaded, so it was removed outside the tool.
- `backups/` is empty. There are no `logs/agent_*.log` files.

So no agent needs removing here; only the optional data clean-up in §3.4 applies.

##### 3.2 What a 1.x agent does after the update to 2.0.0

A plist written by las runs `/bin/zsh <repo>/brew_manager.sh <modules> --yes` (mod_las:217-237): the selection is one positional argument, with no `--only`/`--skip`, no stdin path and `RunAtLoad` false [V]. After `git pull` the same path runs the 2.0.0 code.

| Agent selection | Behaviour under 2.0.0 |
|---|---|
| Contains a removed name (`bk`, `las`, `log`, `mas`, `3,mas`) | Homebrew check, then the `script(1)` re-run, then **exit 2** at selection. Nothing runs, and `_handle_log` is never reached, so the bk/log hang (#21) disappears for these agents. Each scheduled run still leaves a `logs/brew_report_*.log` and the error in `logs/agent_stdout_<label>.log`; launchd records exit 2. A `las` agent used to return immediately with 0 (mod_las:19-23). [V] for the selection path; the log files are **[I]** from :79 and :335. |
| `go` (las's weekly and daily presets, mod_las:274-276) | **Keeps running modules 0–13 unattended**: `brew update` (mod_02:96, no confirmation) and `brew autoremove` plus `brew cleanup -s` (mod_05:71, default `y`, confirmed automatically under `--yes`). Adoption (mod_00:158, default `n`), upgrades (mod_04:80, `${BREW_MANAGER_UPGRADE:-n}`) and greedy upgrades (mod_10:119, `n`) do not act. **Since 1.5.0 these agents really reach brew** (PATH bootstrap), and from 2.0.0 there is no way inside the tool to list or remove them. [V] code; that `_handle_log` then sees EOF and the run ends is **[I]** from STATE #21. |
| Numeric (`3,5`, `8,9`) | Runs unchanged. |

##### 3.3 Removal procedure

**A. Documented procedure (required).** It goes into the CHANGELOG `[2.0.0]` and a README "Upgrading from 1.x" section. Blocks follow IMP-026 (literal commands, no inline comments) and the docs/04 rule that destructive commands are separate and conditional. `launchctl bootout` is the replacement the man page recommends; `unload` "will only return a non-zero exit code due to improper usage" (man launchctl, LEGACY SUBCOMMANDS) [V].

Inspect (read-only):
```
ls ~/Library/LaunchAgents | grep '^com\.m2ndlab\.brew-manager\.'
launchctl list | grep 'com\.m2ndlab\.brew-manager\.'
```
Remove. Run this only if the first command above listed something:
```
for p in ~/Library/LaunchAgents/com.m2ndlab.brew-manager.*.plist(N); do launchctl bootout gui/$(id -u) "$p"; rm -i -- "$p"; done
```
Only if the second command listed a label whose plist no longer exists:
```
launchctl list | awk '$3 ~ /^com\.m2ndlab\.brew-manager\./ {print $3}' | while read -r l; do launchctl bootout "gui/$(id -u)/$l"; done
```
`(N)` is zsh syntax, the default shell on macOS. Stop the agent (bootout) before deleting its plist; a deleted plist leaves the job loaded until logout **[I]**.

**B. Optional: a print-only notice at startup.** I recommend it if the tool runs, or may run, on other Macs or for other users. It is not needed for this Mac.
- In the recorded child, after the banner, look for `$HOME/Library/LaunchAgents/com.m2ndlab.brew-manager.*.plist(N)`. If any exist, print how many and the commands from A.
- It **never** calls `launchctl` or `rm`, never changes the exit code, and also runs under `--dry-run`, since it only reads.
- Cost: about 15 lines in `brew_manager.sh`, which is a sensitive file, plus one test: a sandbox `HOME` with a fake plist and mock `launchctl`/`rm` that record calls; check the notice appears, nothing was called, the plist still exists, and the exit code is unchanged.
- Gate lens specific to B: the printed text is something the user will paste into a shell, and file names are untrusted. Print commands only for names matching `^com\.m2ndlab\.brew-manager\.[A-Za-z0-9._-]+\.plist$` (the predicate from STATE #13), quoted with `${(q-)…}`. For any other match print only a count and "inspect manually". Never pass the name through `echo` or `_warn` (#3b).

**C. Rejected: refusing to run when launched by an agent** (for example by checking `XPC_SERVICE_NAME`). That launchd behaviour is **[I]**; in my terminal it is `0`. It would tie the tool to launchd just as launchd support goes, and it would override a schedule the user set up on purpose. The exit 2 for removed names already fails safe where it matters.

##### 3.4 Leftover data

| Path | Contents | Proposal |
|---|---|---|
| `agents/` | `agent_*.conf`, `agents_activity.log` | Nothing reads it after 2.0.0. The user may delete it by hand. On this Mac: 564 B, a test history only. |
| `backups/` | `Brewfile`, `Brewfile.lock.json`, `agents_bundle.conf` | The Brewfile may be worth keeping (it is a package snapshot that `brew bundle` reads); the documentation should say so. Never deleted by the tool. Empty on this Mac. |
| `logs/agent_stdout_*.log`, `logs/agent_stderr_*.log` | Output of the agents | Deleted by hand. None on this Mac. |
| `.gitignore` entries | | **Keep** (§1.3). |

The tool never deletes any of this: an automatic clean-up would be a new deletion path needing its own gate, for no benefit. Optional manual block for the README, to run only after checking the contents with `ls -la agents backups`:
```
rm -r agents backups
```

#### 4. Size, branch split and gate

- **Heavy** by docs/01: about 20 files across code, tests, user docs, contract, process and memory. It needs a plan.
- **One branch**, for example `feat/remove-special-modules`, not two. Rule 5 requires docs to ship with the change, so a code-only branch could not be integrated on its own. Both halves are MAJOR and only ship together in 2.0.0. Splitting by module (mas and log first, then bk and las) would edit the same 6–7 files and the contract twice for no gain.
- Suggested commits, each with `make test` green:
  1. Code and tests: delete the four files, update the registries, resolver, menu and dispatch, remove `_selection_is_valid`, lower the three `>= 18` guards, and add the rejection checks (selection tests and end-to-end exit 2). `feat(core)!` with `BREAKING CHANGE`.
  2. The removed-name message and its end-to-end check (could fold into 1).
  3. *(Optional)* B: the print-only notice and its test.
  4. README, SECURITY.md and `.gitignore` comments.
  5. Contract and process: docs/04, docs/03, docs/00, the CLAUDE.md rule 8 and technical rules (approved through the plan), new-component.md, the sensitive-components decision note.
  6. Memory: retire the component notes, update TREE, INDEX and STATE.
- **Risk class.** The branch adds no path that deletes or installs anything on the system. It removes four: bk's restore installs packages, writes plists and runs `launchctl load`; las writes and deletes plists and runs `rm`; log runs `rm`; mas installs. The exposure gets smaller. It does touch `lib/selection.sh` and `brew_manager.sh`, which decide what runs.
  - Proportionate gate: **one lens**, whether selection still fails safe. Every removed name, in every position and case, is rejected and never mapped to another module or widened to `go`; exit codes are unchanged; every remaining id still dispatches. The new tests largely prove this.
  - A **second lens** only if B is adopted: B never acts on the system, and the commands it prints are safe to paste.

#### 5. Related findings outside this task

- **[V] Homebrew version mismatch.** `HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew --version` gives `Homebrew 6.0.21-70-g2316567`, the only brew on this Mac. The request says 7.0.1. Item 4 should start by reconciling this.
- **[V] mod_05 cleanup defaults to `y`.** The reason given is that automated `--yes` and LaunchAgent runs should free space (mod_05:69, README :191/:281). Without the scheduler that reason is weaker. Flipping it changes what `--yes` means, which is MAJOR, so 2.0.0 would be the cheapest time if the user wants it. This is the user's call; I am only flagging it.
- **[V] No in-tool log pruning after `log` goes.** `logs/` holds 35 files today. This depends on the `_handle_log` decision (item 2).
- **[V] `open(1)` is used only by `lib/log.sh:25`.** It stays a runtime dependency only if `_handle_log` option [2] stays.

Scratch files from the resolver simulation are in `<session scratchpad>/sim/`. No processes were left running.

## Appendix B — Session recording and _handle_log

### Session recording (`script(1)`) and the end-of-session prompt (`_handle_log`): assessment for the v2.0.0 re-plan

Legend: **[V]** means I checked it in the code, in the real `logs/`, or with a sandbox run. **[I]** means I inferred it from the code or the man page and did not reproduce it.

Evidence base, all read-only:
- I read `brew_manager.sh`, `lib/log.sh`, `lib/common.sh`, the four test suites that run the real binary, the README, `.gitignore`, the CHANGELOG, STATE, the debt-inventory note and the debt-cleanup plan.
- I made two sandbox runs from a symlink farm with a mock `brew`, stdin `</dev/null`, under a watchdog: `8 --dry-run` and `99 --dry-run`. They live in `<session scratchpad>/rec.5jd0CV`. No process was left behind, and nothing in the repo or on the system changed.
- I measured the 35 real logs in `logs/`.

#### 1. What the `script(1)` re-exec does today

##### 1.1 Sequence

| Step | Where | Process |
|---|---|---|
| `SCRIPT_DIR`: taken from the `BREW_MANAGER_SCRIPT_DIR` environment variable if set, otherwise computed and exported | `brew_manager.sh:22-27` | parent, then child (child reads the env) |
| `VERSION` read from file | `:39-40` | both. The child overwrites the parent's `export BREW_MANAGER_VERSION` (`:334`), so that export is dead weight [V] |
| `--version` early exit | `:60-64` | both |
| `logs/` created, or a `mktemp -d` fallback; `LOG_FILE=…/brew_report_<YmdHMS>.log` | `:66-79` | **both, computed independently** (#25) |
| `NON_INTERACTIVE`: parent uses `! -t 0`; child trusts the `BREW_MANAGER_NONINTERACTIVE` handoff | `:112-117` | both |
| Flag parsing and exports (`DRY_RUN`, `YES`, `NONINTERACTIVE`, `ADOPT`, `UPGRADE`, `HOMEBREW_NO_AUTO_UPDATE` under `--dry-run`) | `:119-169` | both, on the same `"$@"` |
| Libraries sourced. `_detect_capabilities` probes the real stdout in the parent and exports `BREW_MANAGER_TUI_{LEVEL,UNICODE,TTY}`; the child uses that handoff | `:175-180`; `common.sh:60-81` | both |
| Homebrew bootstrap and check. The installer guard has a "recorded child" clause | `:265-316`; clause `:290` (`-n "$BREW_MANAGER_RECORDING"`) | both (the child finds brew through the exported PATH) |
| All `modules/mod_*.sh` sourced | `:322-324` | both. The parent never uses them [V] |
| **Guard**: `export BREW_MANAGER_RECORDING=1`; `script -q "$LOG_FILE" zsh brew_manager.sh "$@"` | `:332-335` | parent only |
| `_run_rc=$?` captured **before** the strip | `:339` | parent |
| ANSI and CR strip: `sed` into `mktemp`, then `mv`. An emptiness guard keeps the raw log and prints a WARNING if the strip fails | `:357-364` | parent |
| `exit $_run_rc` | `:365` | parent |
| Banner (prints the **child's** `LOG_FILE`), menu or CLI selection, dispatch, summary, `_handle_log`, fixed `/tmp` `rm` | `:368-648` | child only |

- **Exit propagation [V].** The man page says "command exit status is always the exit status of script". The sandbox confirmed it: `8 --dry-run` → 0 and `99 --dry-run` → 2. A child killed by a signal comes back as the raw signal number. That makes **Ctrl+C exit 2**, the same code as "unknown module token" (CHANGELOG 1.3.0, about line 165).
- **Where the selection is validated.** CLI selection is validated only in the child (`:408-423`). So a rejected selection still creates a session log: the `99` run left a 621-byte log [V].
- **What the log contains [V].** The stripped log is line-for-line identical to the stdout the parent printed. The only differences are the CRs and a leading `^D\b\b`. That marker is the pty's echo of the EOF that `script(1)` forwards: both sandbox logs and 25 of the 35 real logs start with it. **The log is a hard copy of the screen, nothing more.**
- **Log permissions [V].** Logs are `-rw-------`, because of the `mktemp`+`mv` in the strip. A raw log kept after a failed strip keeps `script(1)`'s own permissions, probably umask 0644 [I].

##### 1.2 What depends on the recording

- **The end-of-session summary does not depend on the log [V].**
  - It is rendered in the child from in-memory state: `RUN_STATUS`/`RUN_SECS` (`:535-547`), the module counters (`:511-522`) and a fresh `du` for the disk line (`:609-611`).
  - `RUN_STATUS` comes from `_run_status` (`common.sh:368-375`). That is a pure function of `DRY_RUN`, `MODULE_RISK` and `MODULE_DRYRUN`. **Module outcomes and `$?` are never read** (comment at `:533-534`, #4b).
  - The summary is in the log only because the child's stdout is the pty.
- **The two log-path lines print the child's own `LOG_FILE`:** the banner (`:388`) and the summary's "Log" line (`:632`).
- **`_handle_log "$LOG_FILE"`** runs in the child at `:639`. Its bare `read` is at `lib/log.sh:21`.
- **Handoffs that exist only because of the pty:**
  - `NON_INTERACTIVE` (`:106-117`) and `TUI_*` (`common.sh:52-81`);
  - the `TERM_WIDTH` sanitising (`common.sh:177-181`);
  - the spinner's CR rationale (`common.sh:288-293`).
- **Subprocesses see a TTY [I].** Brew calls that write straight to stdout get the pty. In the code that stays in 2.0.0, only `mod_00_audit.sh:215` (`brew install --cask --adopt`) does this. Every other mutating call is piped through `while read` (for example `mod_04_updates.sh:85`, `mod_05_cleanup.sh:93`, `mod_10_greedy.sh:135`).
- **Tests:**
  - `test_exit_codes.zsh:5-11, 117-141`: the exit codes are checked through the wrapper.
  - `test_exit_codes.zsh:359-363`: the inherited-`RECORDING` clause of the installer guard.
  - `test_exit_codes.zsh:305-316`: uses `/usr/bin/script` itself as a pty harness. This does not depend on the tool's recording.
  - `test_capabilities.zsh:173-213`: piped e2e "through the script(1) re-exec".
  - `test_dryrun_gates.zsh:185-235`: `HOMEBREW_NO_AUTO_UPDATE` "survives script(1)".
  - `test_run_summary.zsh:241-286`: the strip program, extracted from the core.
- **README claims:**
  - `:26` "captures every session to a log file";
  - `:110` the summary ends with the log path;
  - `:175-176` "Unattended full run: every question is auto-answered". **False**: `go --yes` at a terminal stops at the log prompt;
  - `:201` piping is unsupported because "the session recorder owns the script's standard input"; signal → signal number;
  - `:203` Ctrl+C still saves the log;
  - `:535-551` "Session logging" (Keep/Open/Delete, and "manage all logs" through the `log` module);
  - `:560`, `:616` (script(1) listed as a macOS dependency);
  - project structure `:485`, `:505`, `:507-508`.
- **Other files:**
  - `CLAUDE.md`: runtime dependency `script(1)`, and the smoke rule at about line 145 ("waits at the final log prompt", "CRLF line endings").
  - `.gitignore:5-7` (logs/), `:54-58` (`/tmp/...` patterns that are dead: anchored to the repo root, they never match `/tmp`), `:101`.
  - `docs/02:35`: "the raw output of failed commands goes to the session log, not to the screen". **Factually false [V]**: the log *is* the screen. Raw outputs go to fixed `/tmp` files that are deleted at the end (see 2.5).

#### 2. Costs

1. **Everything before the guard runs twice** (`:22-324`).
   - Runtime cost is negligible [V]: sourcing all libs and modules takes about 0.02 s per pass (3 runs). A whole mock run of `8 --dry-run` took 0.66 s.
   - The real cost is conceptual: two processes, three env handoffs, and the trust problem of #28.
   - In the `logs/` fallback case the child calls `mktemp -d` again: an orphan directory and the WARNING printed twice [I from `:69-77`].
2. **Who owns stdin.**
   - Piped stdin is forwarded into the pty as terminal input: it is echoed into the log, and EOF becomes `^D`.
   - In the code that stays in 2.0.0, the only stdin reads are `_ask` (`common.sh:439`) and `_read_choice` (`:476`), both guarded by YES/NON_INTERACTIVE; the menu (`brew_manager.sh:474`, only without a CLI selection); and **`_handle_log` (`lib/log.sh:21`), the one unguarded read on every run** [V by grep]. (`mod_00:169` and `mod_13:46/65` read from here-strings or pipes.)
3. **The one-EOF hang class (#21).**
   - Once `bk` and `log` are removed, only `_handle_log` is left. It ignores `--yes`, so a terminal `go --yes` stops at the prompt [V code].
   - A run whose stdin is an open pipe waits at it. The debt inventory measured this: `(sleep 6; printf '1\n') | … 8 --dry-run` ended only after 6 s. I did not re-run it: this task requires stdin `</dev/null`.
   - With `</dev/null` the forwarded EOF happens to satisfy that single read. That is the only reason today's smokes end.
4. **#25, which is "#11-bis".**
   - "11-bis" is the debt inventory's label (`sessions/2026-09-24-debt-inventory-pre-dashboard.md:604`; plan `debt-cleanup-pre-dashboard.md:73`, branch 13 "#11 + 11-bis") for **the child recomputing `LOG_FILE`**. STATE recorded it as **#25**.
   - Measured now [V]: in **3 of 35** real logs the printed path differs from the file name (`…225250` vs `…225251`, `…232932` vs `…232933`, `…131850` vs `…131851`).
   - In the fallback case it would mismatch 100% of the time [I]. Two runs started in the same second share one file [I].
5. **#11: fixed `/tmp` paths.**
   - The paths: `mod_00_audit.sh:215/218` (adopt stderr, of which only `tail -1` is shown), `mod_01_health.sh:96/100/105` (also under `--dry-run`), `mod_02_update.sh:96/100/112`. The full `brew update` output is **never shown**: only `New Formulae/Casks` lines.
   - The `rm` list moved to **`brew_manager.sh:645-646`**. STATE #11 still cites `:564-565`, which is stale after branch 4 (a Level-1 correction).
   - `brew_cleanup.log` and `brew_audit.log` are dead: nothing writes them [V grep].
   - The `rm` runs in the child after `_handle_log`, so kills and hangs leak the files.
   - The workaround at `test_dryrun_gates.zsh:36-62` exists only because of this.
6. **Latent defects in `_handle_log` itself [I, from code order; not reproducible under the stdin constraint].**
   - **[2] Open** runs in the child while `script(1)` is still writing and before the parent's strip. It opens a raw file with ANSI and CRLF, which may be partial: by the man page, `script` flushes every 30 s by default.
   - **[3] Delete** unlinks a file `script(1)` still holds open. The parent's `sed` then fails, and `:362` prints "log cleanup failed … raw log kept at …". That is false, because the log was deleted. Under #25 the opposite happens: "Log deleted" while the real log stays.
   - `lib/log.sh:12` and `:24-26` pass data through `echo -e` (#3b sites).
7. **Ctrl+C exits 2**, which collides with "unknown token" (the #4b idiosyncrasy). [I] One untested line in the child would map it to 130: `trap 'exit 130' INT`.
8. **Disk growth [V].** 35 logs, 812 KB in total, from 2026-06-02 to 2026-09-27. Mean is about 23 KB and the largest is 196 KB. Even a daily run would add only about 9 MB a year.
   - The 25 logs that start with `^D` came from runs with stdin `</dev/null`, mostly agent smokes, not the user's own sessions [I].
   - Once `mod_log_manager.sh` goes (purge at `:163-186`), **nothing cleans `logs/`**.

#### 3. Options

##### (a) Keep recording and fix `_handle_log`

- **Code:**
  - `lib/log.sh:20-21`: replace the bare `read` with `_read_choice "Choice [1/2/3, default: 1]" "1"`. That gives Keep without a prompt under `--yes` or NON_INTERACTIVE.
  - Compute `LOG_FILE`/`_LOGS_DIR` once in the parent and pass them to the child, as `BREW_MANAGER_LOG_FILE`, read only under RECORDING. Use a unique name such as `brew_report_<ts>_$$.log`.
  - For a per-run tmp dir (#11), see (b).
  - To fix Open and Delete for real, the prompt has to **move into the parent after the strip** (`:364`). The parent has already sourced the libraries (`:175-180`) and is attached to the real terminal.
  - Optional retention to replace the `log` module's purge, for example keep the newest N `brew_report_*.log` and skip under `--dry-run`. This is a **new deletion path** and needs a gate.
- **Risk:** low to medium. You keep a UI of marginal value and add code: the prompt moved to the parent, plus retention.
- **Closes:** the #21 residue, #25, #11. Retention would add a deletion surface.

##### (b) Simplify: always record, no end prompt, print the log path

- **Code:**
  - Delete `lib/log.sh` (37 lines) and `:176`. Drop `:635-639`.
  - The summary already prints the path (`:632`). The "Support" footer (`lib/log.sh:33-37`) can move into the summary footer or be dropped.
  - Parent: compute `LOG_FILE` once (unique name) and pass it on. Create `BREW_MANAGER_TMP=$(mktemp -d)` (per-user `$TMPDIR`, mode 0700), export it, and `rm -rf` it after `script` returns, inside `:332-365`. The parent survives Ctrl+C of the child, so cleanup runs even then.
  - `mod_00/01/02` write under `$BREW_MANAGER_TMP`. They need a fallback or a fail-fast when it is unset, because the tests source modules directly.
  - Drop `:645-646` and `.gitignore:54-58`.
  - No retention code; document a manual cleanup in the README.
  - **No `--no-log` flag**: it would bring back a second, direct execution mode. That doubles the handoff and test matrix and adds a public CLI flag (docs/04), to save an `rm`.
- **Tests:**
  - `test_exit_codes`:
    - RED-then-GREEN: an open-pipe run, for example `(sleep 30) | … 8 --dry-run`, must end within about 10 s.
    - `8 --yes </dev/null` must end with no "Choice" line.
    - The banner path must equal the created file.
    - Two parallel runs must produce two files.
    - A `/tmp` tripwire, plus checking that the per-run dir is gone at the end.
  - A grep invariant: no literal `/tmp/` in `modules/`.
  - Adapt `test_dryrun_gates.zsh:36-62`.
  - Unchanged: `test_run_summary.zsh:241-286` and the `test_capabilities` e2e.
- **Docs:** README `:175-176`, `:201`, `:535-551`, `:485`, `:507-508`; the CLAUDE.md smoke rule (the "final log prompt" text); `docs/02:35` (a Level-1 correction).
- **Risk:** low.
  - The only new deletion is `rm -rf` of a directory the parent itself created with `mktemp -d`.
  - It *removes* a deletion path ([3] Delete).
  - Loss: [2] Open goes away, but `open <path>` does the same job with the path printed on screen.
- **Closes:** the #21 residue, #25, #11. #28 is reduced (see §5).

##### (c) Remove `script(1)`: run directly, summary on screen only, optional `tee`

- **Code:**
  - Remove `:66-79`, `:326-366`, `:386-388`, `:632`, `:635-639` and `lib/log.sh`.
  - Simplify `:106-117` to `[[ ! -t 0 ]]`, `common.sh:60-81` (no RECORDING branch), and the installer guard `:290`.
  - Remove `test_run_summary.zsh:241-286` and `test_exit_codes.zsh:359-363`, and re-word the headers in four suites.
  - Still needs the #11 fix in the modules, with a `trap … EXIT` instead of a supervising parent.
  - About 150 lines fewer.
- **Behaviour changes:**
  - Ctrl+C exits 130 instead of 2, which fixes the collision. CHANGELOG 1.3.0 documented 2, so this is a 2.0.0 note.
  - Piped stdin reaches the menu directly (#9 territory).
- **Cost:** the audit trail is lost. Today the log is the only after-the-fact record of what `mod_04`/`mod_10` upgraded, what `mod_05` removed and what `mod_00` adopted. Homebrew keeps no upgrade history of its own [I]. While #4b-1 is open the summary prints ✓ even for a failed module, so the log is the only place where a failure stays visible after the terminal is closed.
- **The `tee` variant:** `_main "$@" 2>&1 | tee -i -a "$LOG_FILE"`, with the exit status from `${pipestatus[1]}`. It re-implements `script(1)`:
  - capabilities still have to be detected before the pipe;
  - `\r`/`clear` still need the strip;
  - Ctrl+C and flush ordering need care;
  - sudo prompts on `/dev/tty` would not be logged [I].

  Not recommended.
- **Closes:** #25, #28 (except the `BREW_MANAGER_SCRIPT_DIR` part at `:22-23`, which is independent), the #21 residue, the Ctrl+C collision. Leaves #11 open.

| | (a) keep and fix | **(b) simplify** | (c) remove |
|---|---|---|---|
| Summary verifiable after the session | yes | **yes** | no (or `tee`, with its complexity) |
| Hangs or waits at the end | fixed | **gone** | gone |
| New deletion paths | retention (gate) | **only the parent's own mktemp dir** | none |
| Size | M | **S–M** | M (many docs and tests) |
| Gate | light, 1–2 lenses | **light, 1 lens** | light, 1 lens |

#### 4. Recommendation: (b)

On the user's point: **the recording does not make the summary correct.** The summary is computed in memory and ignores outcomes, which is #4b. What the recording does is **preserve the evidence the summary can be checked against**: the full screen transcript, including every upgrade, cleanup and adoption line. For a tool that deletes and installs on the user's own Mac, that audit trail is worth about 20 ms and a 0600 file of roughly 23 KB per run.

The end prompt adds nothing a personal user cannot do with `open` or `rm`. It also carries two latent false-message defects (§2.6) and the last unguarded read on the CLI path.

So:
1. **Keep the recording.**
2. **Remove the prompt.**
3. **Compute `LOG_FILE` once, in the parent, with a unique name.**
4. **Add a per-run tmp dir that the parent creates and removes.**
5. **Add no `--no-log` flag and no automatic retention.**
   - Measured growth is about 2.5 MB a year at the current rate.
   - Document a manual one-liner in the README instead.
   - Trigger to revisit: `logs/` grows past a size the user cares about.

Two companions, the user's call:
- **Pair this with #4b-1** (truthful per-module outcomes), so the summary itself becomes truthful and the log becomes corroboration rather than the only evidence.
- **Evidence completeness.** Today the log cannot confirm `mod_02`'s "Database updated" (the raw `brew update` output is never shown and is then deleted) or a `mod_00` adopt failure beyond `tail -1`. Showing the full raw output on failure would put it into the log. This belongs with #4b-1.

**Optional:** the untested `trap 'exit 130' INT` in the child, to end the Ctrl+C = 2 collision while keeping `script(1)`.

**Gate (proportional):** `brew_manager.sh` and `mod_00` are sensitive, and the branch adds an `rm -rf`. One light lens is enough: "the per-run dir is the only target: non-empty, created by `mktemp -d`, removed only by the parent; no other deletion added".

**Branch shape:** one branch, for example `fix/session-log`, covering the #21 residue, #25 and #11, sized S–M. Place it **after** the bk/las/log/mas removal. Both touch the end of `brew_manager.sh` and `.gitignore`, and the open-pipe e2e is simpler once the bk/log menus are gone.

#### 5. STATE entries under (b)

| Entry | Verdict | Reason |
|---|---|---|
| #21 residue (`_handle_log`'s bare read) | **closed** | The prompt is gone. After the removals, no unguarded stdin read is left on the CLI path. The bk/log half closes with the module removal |
| #25 (= "#11-bis") | **closed** | `LOG_FILE` is computed once and passed to the child; a unique name prevents same-second collisions |
| #11 | **closed** | Per-run `mktemp -d` owned by the parent, which survives Ctrl+C of the child. The dead `rm` list and the `.gitignore:54-58` patterns go. Fix the stale `:564-565` reference |
| #28 | **reduced → close as accepted, or keep as INFO (user's call)** | Its trigger, the GUI invocation contract, no longer exists, and it is not a privilege boundary. Cheap hardening: the child trusts RECORDING only if the `LOG_FILE` handoff exists |
| #4b | **kept** | The log is the evidence until 4b-1. The Ctrl+C = 2 idiosyncrasy stays unless the INT trap is added |
| #3b | **slightly reduced** | The `echo -e` data sites at `lib/log.sh:12/24-26` disappear |
| #17 | unchanged by this choice | Its condition was the GUI contract; re-evaluate in the STATE review |

Level-1 factual corrections to queue:
- `docs/02:35` ("raw output … goes to the session log");
- STATE #11's line references;
- after the change, README `:175-176`, `:201`, `:535-551` and the CLAUDE.md smoke-rule text. CLAUDE.md is the rules file, so confirm with the user whether that edit counts as factual alignment.

#### 6. Open questions for the user

1. Retention: none (recommended), or keep the newest N with a light gate?
2. Add the INT→130 trap? It changes the Ctrl+C status documented in 1.3.0, which is acceptable in 2.0.0.
3. Raw output on failure in the log (evidence completeness): with #4b-1, or not at all?

## Appendix C — STATE triage

### Re-assessment of the open STATE entries for 2.0.0 (personal terminal tool, no Dashboard; bk/las/log/mas removed)

Evidence tags used below:
- **[V]** I verified it in this session: code read at the cited line, a read-only command, or a scratchpad reproduction.
- **[N]** It comes from the memory notes and I did not re-run it.
- **[I]** It is my inference from the code.

The **gate** column applies the user's rule: a light gate only on paths that delete or install, or that decide what runs.

#### 0. Baseline (verified)
- `main` = `origin/main` = `37b8db5`, the tree is clean, and `git describe --tags` = `v1.5.0`. The `v1.5.0` tag is annotated: tag object `deb8f61` points to commit `37b8db5`, and the tag is on origin. **[V]**
- STATE still says v1.5.0 is "ready", at STATE.md:9, :206-210 and :772-782. Fixing that belongs in the first branch (B1).
- **Homebrew on this Mac is `6.0.21-70-g2316567`** (`brew config`, last commit 2026-09-03), **not 7.0.1**. Checking 7.x behaviour first needs the user to run `brew update`, which mutates, so it is the user's call. This feeds item 4. **[V]**
- No `com.m2ndlab.brew-manager.*` agent is loaded (`launchctl list`) or installed (`~/Library/LaunchAgents`). The repo's `agents/` folder holds only `agents_activity.log`. **[V]**
- How I ran things: smokes ran only from a copy of the tool in the scratchpad, on module `8` with `--dry-run`. No repo writes, no mutating brew command, no process left behind.

#### 1. "Attenzione / problemi aperti"

| id | verdict | reason (file:line) | size | gate | branch |
|---|---|---|---|---|---|
| #1 | stays CLOSED | Positional dispatch is at brew_manager.sh:408-423 [V]. The agent half leaves with las. | — | — | B1 |
| #2 | stays CLOSED | mod_00:173-179 and mod_09:69-71 are correct [V]. The las/bk weekday sites are removed. | — | — | B1 |
| #3 | CLOSE at 2.0.0 | Sweep of the remaining modules [V]: every mutating command is gated (mod_00:215←:201, mod_02:96←:85, mod_04:85←:78, mod_05:82/:93←:33, mod_10:135←:98). The two leftovers, #15 and #16, leave with bk/las. mod_01:96 writes `/tmp` under `--dry-run`, which is handled by #11. | — | no | B2 (check), mod_01 → B5 |
| #3b | KEEP, LOW, optional | Details in §5a. Its condition about the JSON layer no longer applies, so the only risk left is terminal escape sequences reaching your own terminal. | M | no (presentation only; consent is unchanged and test_guardrails covers it). Rule 8 still applies because lib/common.sh is in its list. | B6 |
| #4 | MERGE → 4b-1 | The "success printed anyway" sites left are mod_02:97-107, mod_04:85-88, mod_05:82-96 and mod_00:215-218 [V]. | — | — | B7 |
| #4b | KEEP as 4b-1 + reduced 4b-2; 4b-3 CLOSE | The dispatcher never reads `$?` (brew_manager.sh:536-547) [V]. `_run_status` is pure (common.sh:368-375). `failed` is reserved and never assigned (common.sh:339-341, brew_manager.sh:584). The child always exits 0 (:648). Only mod_10 returns non-zero (:115, :161). A declined action shows ✓: mod_05:71-78, mod_04:80 (no else branch), mod_10:163-164. A brew failure shows "All packages are up to date" (mod_04:20-22, :64-65). The summary is the user's main readout, so this still matters. | M | yes-light (it reports on the 0/4/5/10 paths; consent must not move) | B7 |
| #5 | stays CLOSED | v1.5.0 is annotated [V]. | — | — | B1 |
| #6, #6b | CLOSE | Only las/bk schedules and the bk agent restore. | — | — | B2 |
| #7 | stays CLOSED | The hook still covers new commits. | — | — | — |
| #8 | stays CLOSED | Consent logic at common.sh:426-440 and :461-472 [V]. The invariant still has two holes in the remaining code: the bare reads at lib/log.sh:21 and brew_manager.sh:474. They go to N-HANG-r and #9. | — | — | — |
| **#9** | **KEEP, MEDIUM** | Verified by reading the code and by sourcing the pure resolver [V]. `go --only=` runs all 14 modules (CLI_SELECTION at :149; `_resolve_cli` :300 skips an empty filter). `--only=` alone opens the menu, and the menu read at :474 at EOF takes `go` (selection.sh:208). Any `--upgrade=` value is accepted (:124) and becomes the default at mod_04:80. Under `--yes`, `--upgrade=yes` prints `[auto: yes]` (common.sh:427), then declines (:428) silently. Without `--yes`, `--upgrade=y` pre-answers nothing (:438-440), so README :178-179 and :194 are false. Any `--adopt=` value is accepted (:123). The destructive half needs `--yes`, because mod_05 defaults to y. Inside a MAJOR the old "PATCH-only" wording no longer binds. | M | yes-light (it decides what runs, including mod_05 under `--yes`) | B4 |
| #10 | stays CLOSED | The `[auto: <raw default>]` leftover goes into #9. The headless consent gap (BM-16) concerned only the GUI: CLOSE. | — | — | B4 |
| **#11** | **KEEP, LOW** | Fixed paths [V]: mod_00:215/:218, mod_01:96/:100/:105 (also under `--dry-run`), mod_02:96/:100/:112. The final `rm` is at brew_manager.sh:645-646; two of its five paths are dead, and it runs after `_handle_log` (:639), so a kill or hang leaks the files. tests/test_dryrun_gates.zsh:37-60 works around the fixed path. On a personal Mac the gain is correctness (two terminals at once, stale files) and true README/SECURITY claims, more than security. | S | yes-light, 1 lens (mod_00:215 is the adopt/install line) | B5 (or B3) |
| #12, #13 | CLOSE | las/bk only; `lib/agents.sh` was never created. One lesson carries into item 1's uninstall procedure: match agents by the label prefix, never by data read from a conf file. | — | — | B2 |
| #14 | MERGE → B2 | The `[bk]=0`/`[las]=0` entries go (selection.sh:115). `_KNOWN_UNGATED=(bk las)` (test_run_summary.zsh:183) becomes `()`; keep the two-way checks at :186-197 (IMP-009). The summary's "ran anyway" state becomes unreachable (README :127-130). Optional: only mod_02 has a tripwire dry-run test (test_dryrun_gates.zsh:116/:136); mod_00/04/05/10 are only checked by grep (test_run_summary.zsh:156-166). | S | no | B2 (tripwires optional → B7) |
| #15, #16 | CLOSE | bk / las only. | — | — | B2 |
| #17 | CLOSE (accept, INFO) | 27 sites → 9 [V]: 5 on DRY_RUN (mod_00:201, 02:85, 04:78, 05:33, 10:98) + 4 consent sites (common.sh:426/434/461/469). All 4 negated fail-open sites were in las and go with it. All 9 are unreachable: both parent and child overwrite the values from argv (:151/:163/:164). The 8 `TUI_*` sites (common.sh:157/203/259/299/305/351, brew_manager.sh:375/381) can only be reached through an inherited RECORDING (#28). For a personal tool, whoever sets the environment already owns the shell. | (S if done) | no | — (the `_is_*` predicates could ride in B6) |
| #18 | CLOSE (moot) | See §5c. | S | no | B2 |
| #19, #20 | stay CLOSED | — | — | — | — |
| #21 | CLOSE with B2; the leftover → N-HANG-r | The bk/log menus go; lib/log.sh:21 stays (§3). | — | — | B2 / B3 |
| #22 | CLOSE | bk only. The same class (a bare read that ignores NON_INTERACTIVE) survives in `_handle_log` → N-HANG-r. | — | — | — |
| #23 | stays CLOSED (shipped in v1.5.0) | The PATH bootstrap (brew_manager.sh:208-218) is still useful from a non-login shell. Exit 69 stays in the contract. | — | — | B1 wording |
| #24, #27, #29 | CLOSE | las (#24, #27), bk (#29). | — | — | — |
| **#25 (= 11-bis)** | **KEEP if the recording stays; it disappears if the recording goes** | brew_manager.sh:79 has no RECORDING guard, so the child computes the log path again. The parent passes its path to script(1) at :335; the child shows its own at :388, :632 and :639 [V code]. Today's two smokes matched, as expected within the same second. Pairs with NEW-L1. | S | no (rule 8 applies to brew_manager.sh) | B3 |
| **#26 (= N2)** | **KEEP, MEDIUM** | Reproduced today [V]: the real 384,443-byte `brew info --json=v2 --installed` piped through zsh `echo` fails with `JSONDecodeError: Invalid control character at line 4958 col 46`; through `printf '%s'` it parses 69 formulae. The echo is at mod_03:82; the failure is swallowed (:90), then every formula falls back to its own `brew info` (:93-95). The module's About text (mod_03:17-18) and README :262 claim "one fast call". | S | no | B6 (first) |
| #28 (= M1) | CLOSE (accept); it disappears if the recording goes | brew_manager.sh:22-27, :113-117, :332-335; common.sh:61-67 [V code]. Not a privilege boundary, and no GUI caller remains. | — | no | B3 decision |

#### 2. "Debito documentazione", README and SECURITY

| id | verdict | reason | size | gate | branch |
|---|---|---|---|---|---|
| README/SECURITY vs code | KEEP the leftover | Rows below. Rule 5: each fix branch rewrites its own section. | M | no | B8 |
| R1 | KEEP (rewrite) | README :572-584 says "three entries", but MODULE_DRYRUN is a fourth registry. It doesn't mention the key-set pin (test_menu_registry.zsh:74). "Done…automatically" is false because of hand-written lists at brew_manager.sh:417, :445, :458, :469. The named-module recipe, including the "any number is fine internally" trap (:580), goes with the named modules. | S | no | B2 |
| R2 | KEEP | The structure at :474-528 lacks `lib/selection.sh` and `tests/`; the bk/las/mas/log rows go. | S | no | B2 |
| R2b | KEEP (depends on item 2) | :508 says "one per interactive session"; there is one per run (:79/:335). | S | no | B3 |
| R3, R5 | KEEP (rewrite) | The prompt text at :164-166 differs from the real prompt at :473. The summary example at :110-120 is impossible (a preview plus "freed ~1.7G") and shows a bk row. | S | no | B2 |
| R4 | KEEP | :143 and :185 call a CLI-selection run "non-interactive"/"unattended"; on a terminal it is not. | S | no | B8 |
| R6 | CLOSE | las `[c]` only. | — | — | — |
| R7 | KEEP | :192 "a dry run never modifies anything" is false because of the `/tmp` write at mod_01:96. | S | no | B5 |
| R8 | CLOSED by branch 4 | :201 now says "a module that fails while running does not change it yet" [V]. | — | — | B1 |
| R9 | KEEP | :262 "one fast call", false because of N2. | S | no | B6 |
| R10 | KEEP (wording) | :26 "nothing beyond what macOS has" (that line also mentions LaunchAgents); :39 "Python 3 pre-installed". | S | no | B8 |
| R11 + M3 | KEEP | :588 says the helpers implement both flags; they do not implement DRY_RUN. NONINTERACTIVE is omitted. "Never read input directly" is broken by lib/log.sh:21 and brew_manager.sh:474. | S | no | B8 (after B3/B4) |
| R12 | CLOSE (it becomes true) | Every remaining `[!]` module asks through `_ask_danger`: mod_00:208, mod_04:80, mod_05:71, mod_10:119 [V]. Only the "schedules a LaunchAgent" wording changes, at README :102 and in `_risk_caption` (common.sh:524). | — | — | B2 |
| R13 | KEEP | :213 promises "no persistent side effects beyond what you confirm". False: `brew update` runs unconfirmed (mod_02:96), and brew auto-updates during wet runs at mod_04:20/:73 and mod_10:49. | S | no | B8 |
| 4b-readme | KEEP | :124 "✓ The module ran to completion". | S | no | B7 |
| README :98-130 bk/las parts, :390, :403, :417, :432 | CLOSE | bk/las only. | — | — | B2 |
| SECURITY.md | KEEP the leftover | :18 footprint: fixed `/tmp` paths; the backups/ and agents/ folders go. :20-28 network list omits mod_00's adopt install, mod_10's greedy upgrade, brew's auto-update and Homebrew analytics. :28 "No data is sent" should say "by brew-manager itself". :36-39 and :77 (LaunchAgent/backup) go in B2. | S | no | B2 + B8 |
| STATE-DEC-README | KEEP (one-line decision) | README :531 already names the tooling; I propose closing it as superseded. | S | no | B8 |
| "Added in v1.5.0" | stays SETTLED | — | — | — | — |
| README/SECURITY describe bk/las/log/mas | MERGE → B2 | Rule 5: the docs change with the removal. | — | — | B2 |
| "Homebrew 4.x" wording | for item 4 | README :9/:38/:248; mod_01:79/:85/:87; mod_02:75. The phrase is not in CLAUDE.md. | S | no | item-4 branch |

#### 3. Old plan tasks 5–16 and the inventory ids

| id | verdict | reason | size | gate | branch |
|---|---|---|---|---|---|
| T5 module-fn-names | CLOSE | #18 is moot. | — | — | — |
| T6 headless-prompts | REDUCE → N-HANG-r | — | — | — | B3 |
| **N-HANG-r** (new id, the #21 leftover) | **KEEP** | lib/log.sh:21 is a bare read that ignores YES and NONINTERACTIVE [V code]. Measured on a scratchpad copy of the tool [V]: with an open stdin pipe, `8 --dry-run` waited 5 s at the log prompt under the banner "Non-interactive, no --yes — every prompt is declined, nothing is modified"; with `</dev/null` it ended with rc 0 in 1 s. Other cases: a terminal `go --yes` stops at the prompt (from the code); a piped `3` deletes the log under that banner (log.sh:26, [I]); a non-TTY run with no selection: the menu read (:474) eats the only EOF, then the log prompt hangs forever ([N]; the fix goes with #9). | S | no (lib/log.sh is not a rule-8 file) | B3 |
| T7 / T8 | KEEP | = #9 / = N2. | — | — | B4 / B6 |
| T9, T10, T11, T12; N-bk-NI, N-bk-1, N-las-recreate, 3b-bk | CLOSE | bk/las only (= #22, #29, #24). | — | — | — |
| T13 per-run-paths | KEEP | #11 + 11-bis. | — | — | B5 / B3 |
| T14 harvest map | KEEP, ON HOLD | Process only; the scope change does not affect it. | S | no | own chore branch |
| T15 readme-truth | KEEP | §2 leftover. | — | — | B8 |
| T16 release v1.5.0 | DONE | Merge `37b8db5`, tag `v1.5.0` (`deb8f61`) on origin [V]. | — | — | B1 records it |
| 4b-1 | KEEP | See #4b. | M | yes-light | B7 |
| 4b-2 | MERGE (reduced) → 4b-1 | Keep the declined/skipped/failed states and an "unmeasured" state for counters (mod_04:20-22). Drop the JSON schema, the `_mod_outcome` channel and the audit of all 18 modules (14 remain). | — | — | B7 |
| 4b-3 | CLOSE | Its triggers (Dashboard LastExitStatus, BM-17) are gone. It can be added any time as a MINOR. | — | — | — |
| N1 / 4b-0 | stays CLOSED | = #23. | — | — | — |
| M1 / M2 | = #28 (CLOSE) / = #27 (CLOSE) | — | — | — | — |
| The items handed to the Dashboard's first task | CLOSE all | Widening IMP-002 (no schema), the JSON layer in the sensitive lists, the GUI invocation contract, BM-16, `--adopt` by a stable key (a GUI timing problem), per-action entry points, agents with flags. The `_is_*` predicates are optional in B6. | — | — | — |
| GUI design topics 1–4 | CLOSE | GUI only. | — | — | — |

#### 4. New findings (not in STATE)
- **NEW-L1, verified by reproduction.** The log prompt's `[3] Delete` deletes the file while script(1) still holds it open (lib/log.sh:26). The parent's clean-up step then fails, and prints a false message (brew_manager.sh:357-364): `WARNING: log cleanup failed … raw log kept at <path>`. I reproduced it with the same shape in the scratchpad: `script -q` + `rm` + the identical `sed` guard. When the two log paths differ (#25), the opposite lie happens: "Log deleted" while the log stays. → B3.
- **NEW-a, verified.** mod_02:28-29 looks up a tap's last update in brew's own repository. Taps are separate repositories, so the result is always empty and the row says "updated". Checked on this Mac's `anomalyco/tap`. In a dry run this contradicts the "would be refreshed" table. S → B7.
- **NEW-b, verified.** Code comments give a stale cause and a wrong id. brew_manager.sh:533-534 and :584, and common.sh:339-341, say module returns are "noise" until "BM-18". The inventory corrected the cause: they are uniformly 0. And roadmap-v2.md:427 defines BM-18 as the `doctor` self-check, not the return contract; docs/04:145 repeats the wrong id. → B7, and docs/04 in B2.
- **NEW-d, verified.** After the removal, `_selection_is_valid` (selection.sh:323-335) is dead code: its only callers are mod_las:131/:186 and mod_bk:140/:181. Its tests are in test_selection.zsh:137-143 and :296+. → B2.
- **NEW-f, inferred.** With the log module gone, nothing prunes `logs/brew_report_*.log` except `[3]` for the current run. → item 2.

#### 5. Focus answers
**a. #3b in the remaining code [V]**
- **37 `echo "$var" |` sites** remain out of 74. The ones that leave: bk 14, las 11, mas 10, log 2. The 37 by module: 00:3, 02:1, 03:4, 04:6, 05:6, 07:4, 08:1, 09:2, 11:4, 12:6. Only two matter beyond grep/counting: mod_00:53/:70 normalise app names before the shape check at :57, and mod_03:82 is N2.
- **6 module `echo -e` lines with untrusted data**: mod_00:214, mod_01:106, mod_04:86, mod_05:94, mod_12:35, lib/log.sh:12.
- **The 5 output helpers** (common.sh:273-277) are reached by **16 calls carrying string data**: core :416, log.sh:24, mod_00 ×5, mod_02:114, mod_05:88, mod_10 ×7.
- `_ask` renders an app name into a consent question (mod_00:208 → common.sh:427/:435/:438).
- mod_02:88 depends on the expansion (a colour code inside `_item`).

**b. #17 / #28 without the GUI condition.** Both are INFO for a single-user tool.
- #17's remaining 9 sites cannot be reached (argv overwrites the values).
- Its `TUI_*` half, and all of #28, can only be reached through an inherited `BREW_MANAGER_RECORDING`, which no remaining caller sets. Both disappear if the recording goes.
- Verdict: CLOSE both as accepted.

**c. #18 [V]**
- **What remains:** `_module_0` … `_module_13` (mod_00:6, 01:6, 02:64, 03:6, 04:6, 05:6, 06:6, 07:6, 08:6, 09:6, 10:8, 11:8, 12:8, 13:7).
- **What goes:** `_module_14` (bk:9), `_module_15` (las:9), `_module_16` (mas:8) and `_module_log` (log:8), plus their test uses (test_dryrun_gates.zsh:165/:180).
- **Dispatch:** the four named arms (brew_manager.sh:539-542) collapse into the generic `"_module_${_mod}"` (:543).
- **Docs to update:** CLAUDE.md:105 and new-component.md:14-15 (a factual sync).

**d. The survivors the user expected, checked against the code:** #9, #4b, N2, the README leftover and #11-bis are all confirmed **[V]**. #11-bis survives only if the recording stays.

#### 6. Stale causes and line numbers to fix in B1 (Level 1)
- **STATE #11:** `brew_manager.sh:564-565` is now `:645-646`.
- **STATE #21:** README `:162` is now `:175`; the `_handle_log` call is now at `:639`.
- **STATE #18:** the glob is now at `:322`; the dispatch at `:538-544`; README `:565` is now `:580`.
- **#4b (inventory C):**

  | was | now |
  |---|---|
  | dispatcher `:456-465` | `:536-547` |
  | comment `:452-453` | `:533-534` |
  | child exit `:567` | `:648` |
  | `_run_rc` `:258` / `:284` | `:339` / `:365` |
  | summary `:517-521` | `:597` |

- **11-bis:**

  | was | now |
  |---|---|
  | script(1) `:254` | `:335` |
  | banner `:307` | `:388` |
  | summary `:551` | `:632` |
  | `_handle_log` `:558` | `:639` |
  | clean-up `:277-279` | `:357-364` |

- **M1 / #28:** `:251` is now `:332-335`.
- **#9:** selection.sh `:207` is now `:208`; the menu `:392/:393` is now `:473/:474`.
- **README R-items:** shifted by about 13–15 lines (the "now" lines in §2).
- **SECURITY.md:** `:18-25/:73` is now `:18-28/:76-77`.
- **STATE Decisions:** README `:516` is now `:531`.
- **Cause:** the "noise" wording (NEW-b).

#### 7. Suggested branches (the order is input to item 6)
- **B1 `chore/replan-v2` (memory only)**: v1.5.0 recorded as released; the CLOSE verdicts with their reasons; §6; the new plan. Gate: no.
- **B2 `feat!/remove-bk-las-log-mas`** (item 1 → 2.0.0): closes #3, #6, #6b, #12–#16, #18, #21, #22, #24, #27, #29, R1, R3, R5, R6, R12, SECURITY's bk/las lines, the "describes bk/las" debt; the #14 allow-list; NEW-d. Gate: yes-light, because the dispatch and selection decide what runs.
- **B3 `fix/session-log`** (after the user's item-2 decision): N-HANG-r, #25, NEW-L1, #28, R2b, part of M3. Gate: no.
- **B4 `fix/cli-flag-values`**: #9 + the #10 leftover; a non-TTY run with no selection exits 1; README :175/:178-179/:185/:193-194. Gate: yes-light.
- **B5 `fix/per-run-tmp`**: #11 + R7 + SECURITY :18. It can fold into B3, because the child would inherit the per-run directory. Gate: yes-light, 1 lens.
- **B6 `fix/echo-on-data`**: N2 first (S), then #3b's remaining sites, with a test that keeps them gone. Gate: no.
- **B7 `fix/module-outcomes`**: 4b-1 + reduced 4b-2 + #4 + NEW-a + NEW-b + README :124 (+ optional dry-run tripwires). Gate: yes-light.
- **B8 `docs/readme-truth`**: §2 leftover + SECURITY + STATE-DEC-README. Gate: no.
- **Then release v2.0.0.**

**Rule 8 versus the light gate.** Rule 8 still requires `/security-review` on any branch touching `brew_manager.sh`, `lib/common.sh`, `lib/selection.sh`, mod_00 or mod_05. That covers B2–B7. The user's lighter gate (item 5) is a rule change: it needs an IMP and the user's approval before it applies. Until then, my gate column states the user's criterion, not the rule.

#### 8. Input for item 2 (the recording)
- **If the recording stays**, these items stay alive: #25, NEW-L1, N-HANG-r and R2b. #28 is accepted. Ctrl+C keeps exiting 2, the same code as "unknown token", and the clean-up of spinner frames in the log stays.
- **If it goes**, #25, NEW-L1, #28 and the handoff of the TTY and non-interactive state disappear by construction. Tests that reference the recording would need rework: test_exit_codes (13 references), test_capabilities (3), test_dryrun_gates (2), test_run_summary (1).
- **On the "verifiable summary" rationale:** the log lets you check a ✓ against the module's own output, but it does not make the ✓ true; only 4b-1 does. If the recording is kept for that reason, do 4b-1 as well.

Scratchpad only (outside the repo): `<session scratchpad>/` holds `farm1/` (the tool copy and its two session logs), `smoke1.*`, `smoke2.*` and `installed.json`.

## Appendix D — Homebrew 6.0/7.0 compatibility

### Homebrew 7.x compatibility of the modules that remain (read-only assessment, 2026-10-07)

Scope: `brew_manager.sh`, `lib/*.sh`, `modules/mod_00`–`mod_13`. bk, las, log and mas are out of scope.
Tags used below: **[V]** = verified (source read, command run, or log read). **[I]** = inferred from source, not reproduced.

#### 0. Baseline facts and method

- **[V] This Mac runs `Homebrew 6.0.21-70-g2316567`.** That is a `main` commit 70 commits past 6.0.21, last commit 2026-09-03. `brew config` reports macOS 27.0-arm64 and Ruby 4.0.6.
- **[V] Upstream (`gh release list`):**
  - 7.0.0 and 7.0.1 were both released on 2026-09-13.
  - The latest release is **7.0.8** (2026-10-05). "7.0.1 today" is out of date: seven patch releases followed it.
  - 6.0.22 (2026-09-05) is the last 6.0.x.
- **[V] Developer mode is on for this Homebrew.** `/opt/homebrew/.git/config` has `homebrew.devcmdrun = true`. When that flag is set, `brew update` follows `main` instead of the latest stable tag (7.0.8 source: `Library/Homebrew/cmd/update.sh:547-555`). This explains the `-70-g…` suffix. See F3 for the likely cause.
- **[V] The user's environment does not set `HOMEBREW_NO_AUTO_UPDATE` or `HOMEBREW_DEVELOPER`.** Every wet `install`, `outdated` or `upgrade` therefore auto-updates Homebrew itself first.
- **Sources:**
  - Raw blog sources from `Homebrew/brew.sh`: `_posts/2026-06-11-homebrew-6.0.0.md`, `_posts/2026-09-13-homebrew-7.0.0.md`, `pages/7.0.0-migration-guide.md`.
  - GitHub release notes 7.0.1 to 7.0.8.
  - A shallow clone of tag 7.0.8 (commit `a57af19`) at `<session scratchpad>/brew-7.0.8`. Paths cited as `B/…` below are under its `Library/Homebrew/`.
  - The local 6.0.21 source and its tags, read with `git show <tag>:…` in `/opt/homebrew`.
- **Commands run (all read-only, all with `HOMEBREW_NO_AUTO_UPDATE=1`):**
  - Inside the allow-list: `--version`, `config`, `tap`, `info`, `info --json=v2 --installed`, `outdated --verbose`, `outdated --cask [--greedy] --verbose`, `list --versions`, `leaves`, `doctor`, `commands`.
  - **Outside the literal allow-list, all read-only:** `uses --installed`, `deps --installed`, `missing`, `list --pinned`, `tap-info --installed --json=v1`, and `brew trust --json=v1` with no arguments (it lists only; `~/.homebrew/trust.json` still has its mtime of 2 Jun 22:02).
- **Not run:** `brew_manager.sh`. Every run writes `logs/` in the repo, and mod_01 writes `/tmp/brew_doctor.log`, so a run would break the read-only constraint. I used the existing session logs in `logs/` instead.
- No background processes were started.

#### 1. Homebrew 6.0 / 7.0 changes that reach this code

| # | Change | Since | Evidence | Reaches |
|---|---|---|---|---|
| C1 | **Ask mode is the default** for `install`/`upgrade`/`reinstall`. brew prints a plan and asks `[y/n]` only when **stdin and stdout are both TTYs**, and only when the plan includes dependencies, dependants or other packages (with no named args, `upgrade` asks whenever anything would be upgraded). `n`, Esc, ^C or ^D → `exit 1`. Opt-out: `--no-ask`/`--yes`/`-y`, or `HOMEBREW_NO_ASK`. 7.0 **disables** `--ask` and `HOMEBREW_ASK`. | 6.0.0 (`default: true` in the 6.0.0 tag's env_config) | `B/ask.rb:13,28-29`; `B/cmd/install.rb:42-52,211`; `B/cmd/upgrade.rb:70-80,201`; `B/env_config.rb:96-105,536-539`; migration guide :39 | mod_00:215 (F2) |
| C2 | **Tap trust is on by default.** brew refuses to evaluate formulae, casks or commands from untrusted non-official taps ("Refusing to load …"). 7.0 deprecates `HOMEBREW_REQUIRE_TAP_TRUST` and `HOMEBREW_NO_REQUIRE_TAP_TRUST`. `brew doctor` gains `check_untrusted_taps`. `tap-info --json=v1` gains a `trusted` field. Trust store: `~/.homebrew/trust.json`. | 6.0.0 | `B/trust.rb:27-43,224-234,605-608`; `B/diagnostic.rb:844`; `B/tap.rb:1209`; migration guide :28-29 | mod_01, mod_04 (F7) |
| C3 | **`--eval-all` / `HOMEBREW_EVAL_ALL` are disabled** on `deps`, `desc`, `info`, `options`, `readall`, `search`, `uses` and `tap`. Trusted-tap evaluation is now the default. | 7.0.0 | migration guide :23; `B/cmd/uses.rb:38-43` | none (not used; `uses --installed` is unaffected, `B/cmd/uses.rb:34`) |
| C4 | **The internal JSON API is the default.** It is one download, cached at `api/internal/packages.<tag>.jws.json`. The top-level `*_names.txt` files are rewritten only when regenerated. | 6.0.0 | `B/api/internal.rb:66`; `B/api.rb:226-235`; local cache layout | mod_02 (F6) |
| C5 | **Plain `brew upgrade` and `brew outdated` now include `auto_updates` casks whose app bundle is older than the tap version.** `--greedy` adds only the self-updated ones (and `version :latest`). The opt-out is `HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS`; 7.0 disables the old opt-in variable. | 6.0.0 | `B/cask/cask.rb:433-450`; `B/env_config.rb:661-665,764-774`; migration guide :67 | mod_03, mod_04, mod_10, README (F1, F5) |
| C6 | **`brew upgrade` quits running cask apps and reopens them.** Opt-out: `--no-quit` / `HOMEBREW_NO_UPGRADE_QUIT_CASKS`. | 6.0.0 | `B/cmd/upgrade.rb:129-132`; `B/env_config.rb:666-669`; `B/cask/upgrade.rb:505` | mod_04:85, mod_10:135 (F8) |
| C7 | **`brew doctor` changes.** New checks: untrusted taps (6.0) and another `brew` shadowing PATH (7.0). `--json` exists (landed during 6.0.x; present at tag 6.0.21). "Your system is ready to brew." is unchanged. macOS 27 is Tier 1 in 7.0. | 6.0 / 7.0 | `B/cmd/doctor.rb:27,101`; 7.0 post :89, :119 | mod_01 |
| C8 | **Cask pinning:** `brew list --pinned` now lists pinned casks too. | 6.0.0 | `B/cmd/list.rb:40-42` | mod_12:65 label |
| C9 | **Auto-update list unchanged**: `install outdated upgrade bundle release` (+ `tap` with arguments). `HOMEBREW_NO_AUTO_UPDATE` is still honoured. | — | `B/utils/auto-update.sh:21,144-155` | `brew_manager.sh:152-160` is still correct |
| C10 | **Output wording changes in 7.0.x patch releases** ("Improve install, upgrade and reinstall output", #24138). | 7.0.x | release notes | Never parse `brew upgrade` output. mod_04/mod_10 only echo it, which is fine. |

**[V] Removed or disabled in 7.0, and not used by the remaining code** (grep over `brew_manager.sh lib modules tests README.md`):
- `--ask`, `HOMEBREW_ASK`, `--eval-all`
- `list --installed-as-dependency`, `info --fetch-manifest`, `update --merge`
- `HOMEBREW_USE_INTERNAL_API`, `HOMEBREW_CASK_OPTS_*`, `HOMEBREW_NO_SANDBOX_CASK`, `HOMEBREW_UPGRADE_AUTO_UPDATES_CASKS`, `HOMEBREW_BUNDLE_*`

Side note on a module being removed: mod_bk calls `brew bundle dump … --describe` (`modules/mod_bk_brewfile.sh:327,348,370,401`), and 7.0 disables that flag (`B/bundle/subcommand/dump.rb:64-70`). bk's backup would break on 7.0 anyway, so removing it and raising the Homebrew minimum belong in the same MAJOR.

#### 2. Every brew invocation in the remaining code

| Site | Invocation | Still valid on 7.0.8? | Change / finding | Evidence | Action |
|---|---|---|---|---|---|
| brew_manager.sh:160 | `export HOMEBREW_NO_AUTO_UPDATE=1` (dry-run only) | yes | none | `B/utils/auto-update.sh:21` | none |
| brew_manager.sh:192,233 | installer `install.sh` via curl | yes | upstream script still maintained (last commit 2026-09-30) | `gh api repos/Homebrew/install` | none |
| brew_manager.sh:610 / :631 | `brew --cache` / `brew --prefix` | yes | — | — | none |
| mod_00:28,89,105 | `brew list --cask` | yes | — | — | none |
| mod_00:61 | `brew info --cask "$normalized"` (existence probe) | yes | short names resolve to official taps | — | none |
| **mod_00:215** | `brew install --cask "$cask_name" --adopt` | yes (`--adopt`: `B/cmd/install.rb:151-154,172`) | **C1.** stdout and stdin are the script(1) pty, so a cask with dependencies triggers a second `[y/n]` after `_ask_danger`. Under `--yes` the run stops for a keypress; `n` makes brew exit 1, reported as "Failed". [I] With the parent stdin at EOF, script(1) forwards ^D → exit 1. | `B/ask.rb:13-29`; `B/install.rb:535` | **F2** |
| mod_01:27 | `brew --version \| head -1 \| awk '{print $2}'` | yes (`Homebrew X` line unchanged) | — | `B/cmd/--version.sh` | none |
| mod_01:28-29 | `brew --prefix`, `brew --repository` | yes | — | — | none |
| **mod_01:32** | `brew ruby --version` | the command exists, but the call is wrong | `ruby` is a **developer command**, and `--version` is not one of its options (`B/cli/parser.rb:182-183`). [V] Output is blank: log `logs/brew_report_20260903_230056.log:605` shows an empty "Ruby (internal)". [V source] Running any dev-cmd as a non-developer **turns developer mode on** (`B/brew.sh:557-577`), which moves `brew update` off stable tags (`B/cmd/update.sh:547-555`). This happens under `--dry-run` too. | as cited; the call has been there since `d3aee0b` (v1.1.0) | **F3** |
| mod_01:33 | `git log` of the brew repo, labelled "Last DB update" | n/a | measures Homebrew's code, not the package index (wrong since 4.0) | — | relabel, or reuse F6's index age |
| mod_01:34-35 | `brew list --cask/--formula` | yes | — | — | none |
| mod_01:83 | `brew tap` | yes (`B/cmd/tap.rb:51-52`) | C2: no trust state shown | — | F7 (optional) |
| mod_01:85,87 | text "brew 4.x+" | — | outdated | — | F5 |
| mod_01:96 | `brew doctor > /tmp/brew_doctor.log` | yes | C7. [V] On this Mac today: rc=1, "Tier 2 configuration", "You are using macOS 27. We do not provide support for this pre-release version." [I] 7.0 should clear this (macOS 27 is Tier 1). The `/tmp` path is STATE #11. | `B/cmd/doctor.rb:101` | none for compatibility |
| mod_02:25 | `brew tap` | yes | — | — | none |
| mod_02:28 | `git log … -- Library/Taps/$tap` inside the brew repo | n/a | [I] taps are separate git repos, so this always falls back to "updated" (not a 7.0 issue) | — | note only |
| **mod_02:45-50** | `brew --cache` + glob `api/*(.om[1]N)` | yes | **C4.** The glob is not recursive, so it misses `api/internal/`. [V] Newest top-level file is 3 Sep 23:14; newest `api/internal/packages.arm64_golden_gate.jws.json` is 24 Sep 22:19. [I] The dry-run would report about 34 days instead of 13. | `B/api/internal.rb:66`; `B/api.rb:226-235` | **F6** |
| mod_02:75 | text "Since Homebrew 4.x" | — | outdated | — | F5 |
| mod_02:96 | `brew update` | yes (`--merge` disabled but not used) | with developer mode on it lands on `main` | — | none |
| mod_03:21-22,68,78 | `brew list --cask/--formula` | yes | — | — | none |
| mod_03:45-55 | `brew info --cask "$app"`, title line parsed | yes (title `==> token (Name): ver (auto_updates)`, `B/cask/info.rb:63-73`) | [A] detection works. **[V] The description column shows the version**, e.g. "155.0 (auto_updates)" (log 20260903 :691, :710). Pre-existing. | as cited | F9 |
| mod_03:39 | text "[A] … brew upgrade skips it (use --greedy)" | — | **false since 6.0 (C5)** | `B/cask/cask.rb:443-450` | F5 |
| mod_03:76 | `brew info --json=v2 --installed` | yes (`B/cmd/info.rb:62-66`; `name`/`full_name`/`desc` at `B/formula.rb:3099-3105`) | `echo` corruption is STATE #26 | — | reuse it (F10) |
| mod_04:20 | `brew outdated --verbose 2>/dev/null` | yes (format `full_name (v) < new [pinned at x]`, `B/cmd/outdated.rb:146-154`; casks `token (v) != new` [V]) | **C5** adds stale `auto_updates` casks: [V] 9 of the 11 non-greedy outdated casks here are `auto_updates`. **C2** [I]: an untrusted-tap formula drops silently out of the list (`B/formula.rb:2777-2783` swallows per-rack errors; `B/formulary.rb:1086-1097` loads through the tap), and `2>/dev/null` hides the warning. | as cited | F5, F7 |
| mod_04:24,34,46,61 | `brew list --versions [--cask]`, `brew list --cask`, `brew leaves` | yes | [V] `leaves` prints `anomalyco/tap/opencode` while `list --versions` prints `opencode`, so the version shows n/a. Pre-existing. | — | note only |
| mod_04:73 | `brew upgrade --dry-run` | yes (ask is off under dry-run, `B/cmd/upgrade.rb:201`) | — | — | none |
| mod_04:85 | `brew upgrade 2>&1 \| while …` | yes | stdout is a pipe, so no ask prompt (`B/ask.rb:13`). **C6**: running cask apps are quit. | — | F2 (explicit no-ask), F8 |
| mod_05:27,63,75,98 | `brew --cache` | yes | — | — | none |
| mod_05:37 / :82 | `brew autoremove --dry-run` / `brew autoremove` | yes (`B/cmd/autoremove.rb:14`) | 6.0 picks candidates more safely; no ask prompt (`Ask.confirm?` is called only from install, untap and bundle cleanup) | grep `Ask.confirm` | none |
| mod_05:52 / :93 | `brew cleanup -s -n` / `brew cleanup -s` | yes (`B/cmd/cleanup.rb:21-23`) | unchanged; cleanup also autoremoves unless `HOMEBREW_NO_AUTOREMOVE` (`B/cleanup.rb:471`) | — | none |
| mod_06:29 | `brew list --formula \| xargs -I {} brew uses --installed {}` | yes (`B/cmd/uses.rb:34`) | output includes casks (6.0.21 does too); about 1 s per call × 69 formulae | — | optional performance work |
| mod_07:20 | `brew services list` | yes (`B/services/subcommand/list.rb`) | 7.0 labels services `sh.brew.<formula>` (not parsed here); `--json` is available (:20-21); `scheduled` is shown as a warning | `list.rb:88-96` | none required |
| mod_08:22,24 / mod_09:22-23 | `brew --prefix`, `brew list` | yes | — | — | none |
| **mod_10:38** | `brew info --cask -- "$cask" \| grep -q "auto_updates: true"` | the command is valid, but **the grep never matches** | The text output says `(auto_updates)` in the title (`B/cask/info.rb:73`; same in 6.0.21; the format dates back to at least 4.0.5, git `efdef5f26c`). [V] On this Mac the grep count is 0 for firefox. [V] All 5 recorded runs (2026-06-11 to 2026-09-03) print "Casks with auto_updates flag 0", while 21 of 27 installed casks have `auto_updates: true` in JSON. **The module's upgrade path has never run.** | as cited | **F1** |
| mod_10:41,76,131,139 | `brew list --cask`, `brew list --versions --cask -- …` | yes | — | — | none |
| mod_10:49 | `brew outdated --cask --greedy --verbose` | yes | C5 changes what "greedy-only" means: [V] here the greedy list has 17 casks; 6 of them (appcleaner, claude, discord, firefox, logi-options+, sourcetree) appear only with `--greedy` | — | F1 |
| mod_10:104 / :135 | `brew upgrade --cask --greedy [--dry-run] -- …` | yes | pipe, so no ask prompt; C6 quits apps | — | F2, F8 |
| mod_10:3-4,16-22 | texts: "skipped by brew upgrade" | — | false since 6.0 | — | F5 |
| mod_11:38,67,93 | `brew list` | yes | — | — | none |
| mod_11:62 | `brew info "$f" \| grep keg-only` | yes (`B/cmd/info.rb:438`) | reason extraction (`grep -A1 \| tail -1`) is fragile [I] | — | F10 (JSON `keg_only`) |
| mod_11:88 | `brew info --cask \| grep -E "deprecated\|disabled"` | partly | matches lowercase text anywhere, including descriptions [I]. The message starts "Deprecated because…" or "Disabled because…" (`B/deprecate_disable.rb:76-96`; `B/cask/info.rb:20-24` capitalises the first letter). | as cited | F4 |
| mod_12:27 | `brew missing` | yes | 6.0 includes casks | — | none |
| mod_12:45 | `brew info "$f" \| grep -m1 "^https\?://"` | yes | — | — | F10 (JSON `homepage`) |
| mod_12:65 | `brew list --pinned` | yes | C8: casks included; the label still says "formulae" | `B/cmd/list.rb:40-42` | F11 |
| **mod_12:80-81** | `brew info --cask \| grep -qE "^This cask (is deprecated\|has been disabled)"` | **never matches** | the line reads "Deprecated because it …!" / "Disabled because …!" in both 6.0.21 and 7.0.8. [V source; no deprecated cask is installed to reproduce live.] More relevant now that casks failing Gatekeeper were scheduled for disablement in September 2026 (6.0 post :56). | `B/deprecate_disable.rb:93-96` | **F4** |
| mod_13:27,42,62,74 | `brew --prefix`, `brew list`, `brew --cache` | yes | — | — | none |
| lib/*.sh | (no brew calls; only text in `lib/selection.sh:47-48`) | — | — | — | none |

**Unaffected modules: 5, 6, 7, 8, 9, 13.** Every flag they use exists unchanged in 7.0.8.

#### 3. Findings the plan must carry (ranked)

- **F1: mod_10 never finds a candidate, and its premise changed (HIGH; [V]).**
  - The detection grep at :38 has matched nothing on every recorded run.
  - Since 6.0, plain `brew upgrade` (mod_04) already upgrades `auto_updates` casks whose bundle is stale. `--greedy` now only adds apps that have already updated themselves (a re-download to sync Homebrew's record) and `version :latest` casks.
  - **Option a (lean):** detect through JSON `auto_updates` (`B/cask/cask.rb:585`) and reword the module as "self-updated apps whose Homebrew record is stale".
  - **Option b:** retire module 10 in 2.0.0 together with bk/las/log/mas. It is a MAJOR anyway; number 10 is never reused.
  - This is the user's decision. Note that option a **revives an install/upgrade path that has never executed** (mod_10:120-150), so it needs the light gate and one wet test.
- **F2: brew's ask mode against brew-manager's consent (MEDIUM; [V] source, [I] behaviour).**
  - Export `HOMEBREW_NO_ASK=1` once in `brew_manager.sh` near :160. brew-manager owns consent; the variable exists since 6.0.0 and older versions ignore it.
  - In mod_00, show the plan before `_ask_danger` with `brew install --cask --adopt --dry-run`, mirroring mod_04:71-75.
  - Touches a sensitive component (mod_00 / `brew_manager.sh`). Light gate lens: "what does it authorise now?" Answer: the same as before 6.0, when brew never prompted.
- **F3: mod_01:32 dev-cmd (MEDIUM; [V] source and log, [I] cause on this Mac).**
  - The value is always blank, and the call can switch developer mode on (also under `--dry-run`).
  - Replace it by reading the "Homebrew Ruby:" line of `brew config`, which is read-only.
  - **Must land before the user's 7.0.x test.** Otherwise a `brew developer off` is undone by the next run of module 1, and `brew update` goes back to `main`.
- **F4: deprecated/disabled detection (MEDIUM; [V] source).** mod_12 never matches and mod_11 matches loosely. Use JSON `deprecated`/`disabled` (`B/cask/cask.rb:586,592`; `B/formula.rb:3142,3148`).
- **F5: false texts about `auto_updates` and "Homebrew 4.x" (LOW; [V]).**
  - Modules: mod_03:39; mod_04:13-17; mod_10:3-4,16-22; mod_01:79,85,87; mod_02:75.
  - README: :9, :38, :248, :259, :270, :317-319.
- **F6: mod_02 index age reads the wrong files (LOW; [V] layout, [I] output).**
  - Use a recursive glob `api/**/*(.om[1]N)`.
  - Update the fixture in `tests/test_dryrun_gates.zsh:82-83`, which models the old layout.
- **F7: tap-trust visibility (LOW, optional; [I]).** Untrusted-tap packages drop silently out of the outdated and upgrade lists. In mod_01, show each extra tap as trusted / partly trusted / untrusted using `brew tap-info --installed --json=v1` (`trusted`, `B/tap.rb:1209`). This Mac's only extra tap is untrusted at tap level, but its one formula is trusted in `~/.homebrew/trust.json`, so nothing is hidden today.
- **F8: running apps get quit (LOW; [V] source, [I] impact).**
  - Name it in the mod_04 and mod_10 confirmation text.
  - [I] Risk: running brew-manager from a terminal that is itself an outdated cask (here `visual-studio-code` is outdated) could quit the host app mid-run, if that cask declares an uninstall `quit`.
  - Whether to pass `--no-quit` is the user's call.
- **F9: mod_03 description column shows the version (LOW; [V] log).** Fixed by F10.
- **F10: one JSON call instead of per-item loops (performance, and the vehicle for F1, F4, F9).**
  - [V] Timings here: `brew info --cask` takes 0.94 s and `brew info <formula>` 1.02 s per item. One `brew info --json=v2 --installed` takes 1.21 s.
  - The loops cost roughly 25 s (mod_03, mod_10) and roughly 95 s (mod_11, mod_12) per run.
  - Cache the JSON once per run and pipe it with `printf '%s'` (CLAUDE.md echo rule, STATE #26).
  - Keep the helper out of `lib/common.sh` so it stays outside the gate. It is shared code, so follow the cross-module refactor discipline in 01-task-planning.
- **F11: mod_12:65 label (LOW).** Change "Pinned formulae" to "Pinned packages". mod_12:5 also announces a "brew doctor warnings summary" that the module never runs.

#### 4. The version constraint

**Where it is stated [V]:**
- README.md:9 (badge `Homebrew-4.x+`), :38 (Requirements table "4.x or later"), :248 (prose).
- `modules/mod_01_health.sh:79,85,87`; `modules/mod_02_update.sh:75`.
- **It is not in CLAUDE.md.** The Stack line only says "Homebrew (built-in installer)". It is not in docs/04 or SECURITY.md either.
- **No code enforces a version.** mod_01:27 only displays it.

**Proposal: "Homebrew 6.0 or later; tested with 7.0.x".** Put it in the README table and badge, and add the same constraint to the CLAUDE.md technical-rules Stack line, as the user asked.

Reasons:
1. 6.0.0 is where every behaviour the remaining modules must handle appeared: C1, C2, C4, C5, C6. Every fix above is valid from 6.0.0: `HOMEBREW_NO_ASK`, `--no-quit` and the `trusted` field all exist at the 6.0.0 tag.
2. On 4.x and 5.x, `auto_updates` and trust behave differently. Supporting them would mean two sets of semantics in the README and in testing, which is not proportionate for a personal tool.
3. Not "7.0 or later": nothing proposed needs 7.0. `doctor --json` and `vulns` already exist in 6.0.x. The Mac is on 6.0.21 today.
4. No hard version gate (it would be a new exit path). At most a soft warning in mod_01 when the major version is below 6.
5. Ship it inside 2.0.0, so the raised minimum rides the MAJOR.
6. Also correct README:36 ("Intel supported"): Homebrew 7 puts Intel and Sonoma 14 in Tier 3, and Homebrew stops running on Intel on 2027-09-01.

**Testing against 7.x needs the user to update Homebrew first.** That is a mutating action and it is the user's.

To check the current state (read-only):
```
brew --version
brew developer state
git -C /opt/homebrew config --get homebrew.devcmdrun
```

To land on the stable 7.0.x tag, which is 7.0.8 today. Run this only after F3 is merged, or never run module 1 before the test:
```
brew developer off
brew update
brew --version
brew doctor
```

Without `brew developer off`, `brew update` lands on a `main` commit past 7.0.8, not on a release tag. Any wet `install`, `outdated` or `upgrade` would also trigger the same update implicitly.

#### 5. Proportionate compatibility testing

1. **Tier 0 (agent, no brew):** `make check` and `make test`. The mocks in `tests/` do not model brew output formats, so they cannot catch Homebrew drift; Tier 1 is the real check.
2. **Tier 1 (user, read-only smoke, after the update and after F3):**
   ```
   f=$(mktemp) && ./brew_manager.sh go --dry-run </dev/null >"$f" 2>&1; echo rc=$? file=$f
   ```
   What to check in the output:
   - mod_01: version 7.0.x, the Ruby row is not empty, the macOS 27 Tier-2 warning is gone.
   - mod_02: the index age matches the mtime of `api/internal`.
   - mod_03: 21 [A] flags, and the description column no longer shows versions.
   - mod_04: stale `auto_updates` casks are listed.
   - mod_05: no "preview failed".
   - mod_10: a count above 0 (option a).
   - mod_12: deprecated/disabled casks come from JSON.
3. **Tier 2 (user, interactive, only the paths that install or remove):**
   - one mod_04 upgrade: no brew `[y/n]` after brew-manager's own confirmation, and apps quit and reopen as expected;
   - one mod_10 upgrade of a single cask (if option a);
   - mod_00 adoption, only if a candidate exists;
   - one mod_05 cleanup.
4. **Light gate (one or two lenses), only on F2 and on F1 option a:**
   - consent: what does `HOMEBREW_NO_ASK` and the revived mod_10 path authorise?
   - dry-run truth: re-check `MODULE_DRYRUN[1]` once mod_01 no longer writes Homebrew's config.

   No multi-hour workflow is warranted.
5. **Where this fits in the plan:** one branch, e.g. `fix/homebrew-6-7-compat`, after the bk/las/log/mas removal and before the README truth pass and the v2.0.0 release. Suggested tasks: F3, then F10 with F1/F4/F9, then F2/F8, then F6, then F5/F11 with the constraint text, then the user's Tier 1 and 2 checks. Every task is a PATCH, apart from any module retirement the user chooses.

## Appendix E — The critic of the draft plan

1. **Branch order: F3 has to land first, and Homebrew has to be updated straight after it.** Today the draft puts F3 at the start of B3 and the user's `brew developer off` / `brew update` at the end of B3 (draft:48-54).
   - Evidence: `modules/mod_01_health.sh:32` runs `brew ruby`, which is a dev-cmd (`brew-7.0.8/Library/Homebrew/dev-cmd/ruby.rb`). Running a dev-cmd writes `homebrew.devcmdrun true` (`brew.sh:565-576`), and with that set, `update.sh:547-555` follows `main` instead of release tags.
   - Every run of module 1 from `main` re-enables developer mode, including `--dry-run` runs and B2's smokes. Until then, the user's everyday `brew upgrade` auto-updates onto unreleased `main` commits.
   - B3's work (F4/F6/F10/D7) would be built against 6.0.21 and only tested on 7.0.8 at the end.
   - **Correction:** add a tiny PATCH branch `fix/mod01-dev-cmd` right after B1. It reads `Homebrew Ruby:` from `brew config` (`system_config.rb:195`), needs no gate, and also fixes the mislabelled `mod_01:33` "Last DB update" (homebrew7 §2).
   - The user then runs `brew developer off; brew update; brew --version` (7.0.8). B2–B8 are then built and smoke-tested on 7.0.x, which also makes D9's "tested with 7.0.x" true.

2. **The #3 and #14 closures in B2 are wrong, and B2 would publish a false dry-run claim.**
   - Draft:47 has B2 close #3, and the triage list folds #14 into B2. Removal §1.2 says `_KNOWN_UNGATED=()` is "honest because no module is left without a gate".
   - But `MODULE_DRYRUN[1]=1` (`lib/selection.sh:112`) while module 1, under `--dry-run`, writes `/tmp/brew_doctor.log` (`mod_01:96`) and Homebrew's git config (point 1). Homebrew7 §5.4 flags exactly this; the draft drops it.
   - B2's README rewrite of :192 ("two modules still ungated") would turn this into a public false claim (IMP-008).
   - **Correction:** close #3 and #14 only once F3 and B4 (#11) have landed. If B2 still lands first, set `_KNOWN_UNGATED=(1)`, either with `[1]=0` (honest) or with an explicit "/tmp scratch" exception.

3. **B1 closes entries that are only true once B2 has merged.** Draft:37-38 applies "the triage (closures with reasons)" in B1. STATE.md:386-392 says moot entries are closed "when its module goes (and checks it really went)". Until B2 merges, `main` still ships bk/las with #6b/#12/#13/#15/#16/#22/#24.
   - **Correction:** in B1, close only what a decision closes: #17 and #28 accepted, 4b-3, T5, the Dashboard/GUI items. Record every module-bound entry as "closes in B2". B2 ticks them after a grep proves the code is gone.

4. **Rule/contract edits are missing from the approval list, and docs/04 changes are missing from B4, B5 and D3.**
   - Rule 6 and removal §1.3 ("Process note"): the plan should say that approving it approves these edits:
     - CLAUDE.md rule 8, the Stack line, `_module_14` (:105) and the smoke rule (:147-156);
     - docs/03, docs/00, the docs/04 contract and `new-component.md`.
   - Rule 5 / docs/04:136-145 need contract text in these places:
     - **D2** (Ctrl+C → 130, a new exit code; B4): docs/04, README :201, CHANGELOG, and a pinned test. The pty harness at `test_exit_codes.zsh:305-316` can send ^C.
     - **B5**: invalid flag value → 2, a non-TTY run with no selection → 1, the new `--upgrade` semantics, and the exit-order clause.
     - **D3=b**: "numbers 0–9, 11–13; 10 reserved".
     - **NEW-b**: the "additive extension with BM-18" clause at docs/04:143-145, in B2 or B6.

5. **B4 is missing the docs that rule 5 requires.** It must also carry:
   - README "Session logging" :535-551, :175-176 and :201;
   - SECURITY.md :18 (the `/tmp` footprint);
   - CLAUDE.md :91-93 (`open(1)` goes; `lib/log.sh:25` was its only user) and :147/:151-152 (the "final log prompt" text);
   - docs/02:35.
   
   B3 also needs README lines for D7 (no brew `[y/n]`), D8 (apps quit or not) and D9.

6. **Item 2 is only half answered.** The user's condition was "keep the recording if it makes the summary verifiable". The draft never states the report's key finding (recording §4, triage §8): the log keeps evidence, but it does not make the ✓ true. Only 4b-1 does that.
   - The draft also drops the "evidence completeness" companion and open question 3 (recording §4).
   - Once B4 deletes the per-run dir, raw outputs are lost: `mod_02`'s `brew update`, and the `mod_00` adopt stderr beyond `tail -1`.
   - **Correction:** state in D1: "kept for corroboration; truthful only together with B6". Add to B6: print the raw output on failure (so it lands in the log) before the parent deletes the dir.

7. **D11 is broader than what the user asked for, and some gates are not proportionate.**
   - The user said "only on paths that delete or install". D11 also triggers on "touches a sensitive component", and `brew_manager.sh` is touched by B2–B6, so almost every branch is gated.
   - **Correction:** make IMP-030 path-based:
     - the paths are: mod_00 adopt, mod_04 upgrade (it installs; today it is only "medium", docs/03:46), mod_05 autoremove/cleanup, mod_10 if kept, B4's `rm -rf`, and the selection/consent code that decides whether those paths run;
     - any other edit to a sensitive file is author-verified.
   - Further cuts:
     - B8: no gate (docs-only release);
     - B2: 1 lens, no refuter (it only shrinks exposure, and the new rejection tests are the proof);
     - B6: 1 lens, with `test_guardrails` as the consent-invariance proof.

8. **F10 conflicts with the branch order and is the heaviest part of B3.**
   - Its "cache once per run" (homebrew7 F10) needs B4's per-run dir, but B3 comes before B4. B3 would invent a new temp path, which is the #11 class again.
   - It is also a cross-module refactor (docs/01 special case) done mainly for speed.
   - **Correction:**
     - fix N2/#26 in place: `printf '%s' "$_formula_json" |` at `mod_03_packages.sh:82` (S);
     - do F4 with a per-item `brew info --json=v2 --cask` call;
     - move F10/F9 to a PATCH after 2.0.0.
   - Also swap B3 and B4: B4 before B3 means F2 edits the final `mod_00:215-218` block only once. Both branches touch `mod_00:215`, `mod_01:96-105` and `mod_02:96-112`.

9. **Item 4 is not fully answered.**
   - **F7 (tap trust) is dropped from B3** (draft:49-53). Yet the user asked about tap trust explicitly, and `mod_04:20 2>/dev/null` silently hides formulae from untrusted taps, so the tool can report "All packages up to date" while one is outdated.
     - **Correction:** at least stop discarding that stderr, or add F7 to mod_01.
   - Add one line each:
     - C3 ("commands loading all formulae"): no `--eval-all` left; `mod_06:29` makes about 69 `brew uses` calls, optional speed-up;
     - `brew doctor`: compatible; the macOS 27 Tier-2 warning goes away on 7.0;
     - the "4.x" constraint is not in CLAUDE.md today (it is in README :9/:38/:248 and `mod_01:79-87`, `mod_02:75`).

10. **Item 3 is not fully answered.**
    - The open STATE item "Roadmap v2" (STATE.md:20) leaves BM-13 to BM-18 unassessed.
      - **Correction:** in B1, close roadmap-v2 as superseded. BM-17 goes with las. List BM-15/16/18 as post-2.0.0 candidates for the user.
    - Also in B1:
      - one line on the IMP backlog (STATE.md:613-630 and :749-769): unaffected, left for `/retro`;
      - the STATE-DEC-README decision (STATE.md:320-323; triage §2 proposes closing it as superseded).
    - Give D4 a branch if the user chooses to flip it.

11. **Item 0 covers more than STATE.** The reconciliation also needs:
    - STATE front matter `branch:` and "Branch attivi": `main` 37b8db5, tag v1.5.0 (deb8f61), version-check 1.5.0, release branch deleted;
    - "Decisioni prese: whether a v1.5.0 is cut" (STATE.md:342-346);
    - INDEX.md:170 ("Ready for … merge and tag");
    - old plan task 16 (`debt-cleanup-pre-dashboard.md:81`) ticked as done, not "superseded";
    - the 2026-10-07 release session note.
    
    Verified: `git ls-remote` shows `deb8f61` → `37b8db5` on origin.

12. **Two test traps in B2.**
    - `test_risk_badges.zsh:151` scans `mod_bk_brewfile`/`mod_mas_mas` (and `mod_10_greedy` if D3=b). On a deleted file the scan passes silently (removal §1.2); the draft only mentions the `>=18` guards.
      - **Correction:** fail when a scanned file is missing.
    - With D3=b the counts change: the guards become `>=13`, not 14; `MODULE_IDS==13`; the frozen key set at `test_menu_registry.zsh:74` changes; so do `test_selection.zsh:153/165/253/293` and `test_risk_badges.zsh:62`.

13. **Decisions are presented with their downsides missing.**
    - D3(b): on this Mac 6 casks are greedy-only (appcleaner, claude, discord, firefox, logi-options+, sourcetree). Retiring module 10 leaves `brew upgrade --cask --greedy` by hand as the only path; homebrew7 F1 lists `version :latest` casks as greedy-only too.
    - D8 `--no-quit`: it upgrades the bundle of an app that is still running.
    - D7: the `install --dry-run` preview auto-updates Homebrew in a real (non-dry-run) run.

14. **Stale or under-scoped items.**
    - `mod_05:69` gives "LaunchAgents" as the reason for default `y`. Reword it in B2 whatever D4 decides.
    - #3b is deferred, but `mod_00:53/:70` (app names passed through `echo` before the shape check) and `mod_00:208` (the name in the consent prompt) sit on the install path. Fold them into whichever branch touches `mod_00` (about 3 lines).
    - "Upgrading from 1.x" should name the primary path first: remove agents with `las` while still on 1.5.0, as CHANGELOG [1.5.0] already says. The manual `launchctl bootout` block is the fallback.

15. **Weight that can go.**
    - Drop B1's sweep of stale line references (the triage's "Stale causes and line numbers" list). B2–B6 move every one of those lines again, so each branch should update its own entries.
    - Fold B7 into B8: both are docs-only, and it saves one retro/checkpoint/integrate cycle.
    - Have each branch add its own `[Unreleased]` CHANGELOG line instead of rebuilding them all in B8.

16. **Internal inconsistencies in the draft.**
    - NEW-d is in "Kept" (draft:72) but B2 closes it.
    - B6's gate names module 10 even when D3=b retires it.
    - B4 lists "#28 accepted" but drops the hardening recording §5 calls cheap: the child trusts `RECORDING` only when the `LOG_FILE` handoff exists, on lines B4 already rewrites.

## Links
[[STATE]] · [[plans/v2-personal-tool]] · [[decisions/2026-10-07-v2-plan]] · [[decisions/2026-09-27-personal-terminal-tool]] · [[sessions/2026-10-07-release-v1.5.0]]
