---
type: state
updated: 2026-11-13
branch: feat/remove-special-modules
tags: [state]
---
# STATE — brew-manager

> Updated: 2026-11-13 | Last: **2.0.0 task 3, bk/las/log/mas and module 10 removed** → [[sessions/2026-11-13-remove-special-modules]] | Index: [[INDEX]]

## Progress
- [ ] **2.0.0** ([[plans/v2-personal-tool]]): tasks 1–2 INTEGRATED, task 3 done ([[plans/remove-special-modules]]) → **task 4** after its merge → … → 8 the release.

## What exists now
- `brew_manager.sh`, `lib/`, modules 0–9 and 11–13 (`go`); bk/las/log/mas and 10 removed, their ids reserved: [[TREE]], [[INDEX]].
- `make test` 446 checks (9 zsh suites); `make check` = `zsh -n`; no CI; gitleaks in the pre-commit hook, the history to 2026-09-25 clean (#7); tags annotated from `v1.2.0`.
- Method: framework v4.1.0 (pin `.claude/framework-version`).

## Decisions made (not obvious from the code)
- In CLAUDE.md: trunk-based `main` ([[2026-07-12-trunk-based-su-main]]), tags only from `chore/release-vX.Y.Z`; the rule **Security gate** and the contract (U2, U5 of [[decisions/2026-10-19-framework-upgrade-v4.1.0]]), its ids frozen, the removed ones reserved.
- Personal terminal tool, no Dashboard → [[2026-10-07-v2-plan]]; no tty ≠ consent → [[2026-07-17-consent-vs-noninteractive]].
- [[decisions/2026-11-07-framework-architect-decisions]]: `make lint` = `zsh -n` (no shellcheck for zsh, SC1071); Co-Authored-By kept, `attribution.sessionUrl` false, the `Claude-Session:` trailers published before 2026-11-07 never rewritten.
- By choice: commitlint via `npx`; no `*.log` in `.gitignore` (D10, 2026-09-24); SECURITY.md's SLA removed by the user (`9b7e874`, never rewritten).

## Documentation debt
- README/SECURITY.md vs the code ([[sessions/2026-09-24-debt-inventory-pre-dashboard]], E): each 2.0.0 task fixes its section, task 8 the residue (R4, R9–R11, R13, M3, SECURITY.md:36-41 (upgrade gate F5) and its docs/03 pointer, SECURITY.md:22-29's network list: module 0's adoption download, brew's auto-update, analytics — task 3's gate, F5; from its round 3, README:108's `brew bundle install --help` pointer, which names no removing setting (name `HOMEBREW_BUNDLE_FORCE_INSTALL_CLEANUP`, or narrow it), and README:268's twins: the restore after `brew developer on` too, a launchd run's environment).

## Caution & open issues
> Numbers are labels, never reused (code and tests cite "STATE #N", "STATE Attenzione #N"). "→ task N" is the trigger ([[plans/v2-personal-tool]]); a "task 3" entry closes once a grep proves its code gone. Earlier text: appendix A of [[sessions/2026-11-07-post-upgrade-checkpoint]], then later notes' appendices ([[INDEX]]); evidence: [[sessions/2026-10-07-replan-v2-assessment]] (C, file:line at `37b8db5`).

- **#3** `--dry-run` not uniform: module 1's `/tmp/brew_doctor.log` and plain `git status` (may refresh Homebrew's index) → task 4, with #11, #14.
- **#3b** zsh `echo` on data expands escapes (LOW; 37 module sites since task 3, and the helpers; #26 live): module 0's three install-path sites → task 5, the rest → TRIGGER: v2.0.0 (D10), or new code copying it.
- **#4** "Success" printed after a failure (modules 0, 2, 4, 5) → task 7, with 4b-1.
- **#4b** Module outcomes not reported: every module returns 0 when brew fails, `$?` unread, ✓ for failed/skipped/declined → task 7 (4b-1, reduced 4b-2, raw output into the log). Ctrl+C exits 2 → 130 in task 4.
- **#9** Flag values not validated (`--upgrade=yes` declines; `--upgrade=y` alone answers nothing; `go --only=` runs all; non-TTY, no selection: `go`), #10's `[auto: …]` residue → task 6.
- **#11** Fixed `/tmp/brew_*.log` paths, modules 0, 1 (`--dry-run` too), 2 (LOW: symlink, leaks, concurrent runs; 2 dead in the final `rm`) → task 4, a per-run dir.
- **#14** `MODULE_DRYRUN` = the modules ignoring `--dry-run`: `[1]=0`, `_KNOWN_UNGATED=(1)` since task 3, both ways → closes in task 4 with #3.
- **#21** `_handle_log`'s bare `read` (deaf to `--yes`; an open stdin waits) → task 4 (D1); the bk/log hang left with the modules.
- **#25** The child recomputes `LOG_FILE` (LOW: a log path that differs) → task 4.
- **#26** Module 3 corrupts brew's JSON via `echo` (MEDIUM) → task 5: `printf '%s'`, `mod_03:82`.
- **#31** Homebrew 6.0/7.0 compatibility (appendix D's F2, F4–F9, F11, NEW-a; F5 also README's "Why this exists" and module 3's `[A]` line) → task 5. F1 closed with module 10.
- **#32** The log prompt's `[3] Delete` lies (LOW) → task 4 (D1).
- **#33** "noise until BM-18": `brew_manager.sh:530-531`/`:579`, `lib/common.sh:339-341`, CLAUDE.md's **Public contract** (the returns are uniformly 0) → task 7.
- **#38** The run summary shows unmeasured counters as measured (module 1 alone: "Installed casks 0 / formulae 0 / Available updates 0", the adopt rows) → task 7, with #4b.
- **#39** Module 1's restore box overflows an 80-column terminal ("From: …", the local-changes line; `_box` never truncates) → task 5 (module 1's texts, with `mod_01:86`'s "set in your environment" for a variable from `brew.env`).
- **#40** `/Users/seco/Projects/_upgrade-scratch/brew-manager` (decision C): the user deletes it when the framework's triage closes → TRIGGER: its decision on IMP-112 (and IMP-046's `:s` part).
- **#42** `attribution.sessionUrl` unproven (it needs the project's settings loaded; CLAUDE.md's rule names both limits since task 3) → TRIGGER: each checkpoint, the link count of [[sessions/2026-11-07-post-upgrade-checkpoint]] (Follow-up); closes at a commit the user confirms came from Remote Control or the cloud.
- **#44** The run header's "no changes" (`--dry-run`, `brew_manager.sh:493`) and "built-in defaults" (`--yes`, `:497`) are false while #3, #14, #21 hold (LOW), and so is README's `--yes` row "Skips all interactive prompts" (the menu and log prompts are bare reads) → task 4.
- **#45** For the user, from task 3: the menu checked from a real terminal; LICENSE:32 still names LaunchAgents (their legal text) → TRIGGER: task 3's integration ([[sessions/2026-11-13-remove-special-modules]], Follow-up).
- Closed: #1, #2, #5, #5b, #6, #6b, #7, #8, #10, #12, #13, #15, #16, #17 (reopen: a caller sets the variables), #18, #19, #20, #22, #23 (reopen: no Homebrew outside a login shell), #24, #27–#30, #34–#37, #41, #43.
- [[LEARNINGS]]: OPEN 006, 008–021, 023–029, 032, 051–059 → TRIGGER: the periodic retro or the user's request; the Architect's report on 051–056 (sent 2026-11-08) and on the old IMPs 006, 008–011, 013, 014, 016, 019, 021, 026–028 in part (v4.1.0 covers them; decision D: none closed before). Deferred 033–050, delivered 2026-11-08 → the framework release holding each, at the next upgrade (harvest: OPEN only); 005, its own trigger.

## Active branches
- **feat/remove-special-modules**: done (plan completed), at `/fw:integrate`'s checks (no tag: a MAJOR, released by task 8).
- **main** (integration = stable): `d91b0dd` = `origin/main`, tag `v1.5.0` = VERSION; `origin/dev` dormant; the others merged and deleted.
