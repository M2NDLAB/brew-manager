---
type: state
updated: 2026-11-08
branch: main
tags: [state]
---
# STATE — brew-manager

> Updated: 2026-11-08 | Last: **the post-upgrade checkpoint** (`chore/post-upgrade-checkpoint`): STATE condensed; `make lint` = `zsh -n`; gate 0 C/H/M at `4e8149d`. → [[sessions/2026-11-07-post-upgrade-checkpoint]] | Index: [[INDEX]]

## Progress
- [x] v1.1.2 → v1.5.0 and four framework upgrades, the last to v4.1.0 (merge `0b127a9`, no tag): the notes in [[INDEX]].
- [ ] **2.0.0** ([[plans/v2-personal-tool]]): tasks 1–2 INTEGRATED (`f232f12`, `8a7e6a2`) → **task 3** (MAJOR) → … → 8 the release.

## What exists now
- `brew_manager.sh`, `lib/`, modules 0–13 (`go`), bk/las/log/mas → [[TREE]] and the component notes ([[INDEX]]).
- `make test` 333 checks (9 zsh suites); `make check` = `make lint` = `zsh -n`; no CI; gitleaks found 0 in the 155 commits of 2026-09-25 (#7; later ones: the pre-commit hook). Tags annotated from `v1.2.0` (`v1.1.2-baseline` a helper the tool's `git describe` skips).
- Method: framework v4.1.0 (pin `.claude/framework-version`).

## Decisions made (not obvious from the code)
- Trunk-based `main`; a tag only from `chore/release-vX.Y.Z`, with `VERSION` → CLAUDE.md (Releases); [[2026-07-12-trunk-based-su-main]].
- Gate and contract: CLAUDE.md's answers and rule **Security gate** (U2, U5 of [[decisions/2026-10-19-framework-upgrade-v4.1.0]]); module ids frozen (users' plists) → [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]].
- Personal terminal tool, no Dashboard → [[2026-10-07-v2-plan]]. No tty ≠ consent → [[2026-07-17-consent-vs-noninteractive]]. Artifacts English, a condensed entry too → CLAUDE.md.
- `make lint` = `zsh -n`, a syntax check only — shellcheck does not support zsh (SC1071). Co-Authored-By kept, `attribution.sessionUrl` false; commits published before 2026-11-07 keep their `Claude-Session:` trailer, never rewritten → [[decisions/2026-11-07-framework-architect-decisions]].
- By choice: commitlint via `npx`; no `*.log` in `.gitignore` (D10 of 2026-09-24); SECURITY.md's SLA removed by the user (`9b7e874`, never rewritten).

## Documentation debt
- README/SECURITY.md vs the code ([[sessions/2026-09-24-debt-inventory-pre-dashboard]], E): each 2.0.0 task fixes its section; the residue (R4, R9–R11, R13, M3, SECURITY.md, the upgrade gate's F5 at :36-41 and its docs/03 pointer) → task 8. bk/las/log/mas described until task 3.

## Caution & open issues
> Numbers are labels — code and tests cite "STATE #N" or "STATE Attenzione #N" —, never reused. "→ task N" is the trigger ([[plans/v2-personal-tool]]); "task 3" entries close once a grep proves the code gone. Earlier text: appendix A of [[sessions/2026-11-07-post-upgrade-checkpoint]]; evidence: [[sessions/2026-10-07-replan-v2-assessment]] (C, file:line at `37b8db5`).

- **#3** `--dry-run` not uniform: #15/#16 (task 3); module 1's `/tmp/brew_doctor.log` and its plain `git status` in Homebrew's repo (may refresh the index) under `--dry-run` → task 4, with #11, #14.
- **#3b** zsh `echo` on data expands escapes (LOW, 74+ sites; #26 live) → after 2.0.0 (D10), module 0's three install-path sites → task 5. TRIGGER: v2.0.0, or new code copying it.
- **#4** "Success" printed after a failure (modules 0, 2, 4, 5; bk, mas, las remove, log until task 3) → task 7, with 4b-1.
- **#4b** Module outcomes not reported: 17 of 18 modules return 0 when brew fails, `$?` unread, ✓ for failed/skipped/declined → task 7 (4b-1, reduced 4b-2, raw output into the log; 4b-3 closed). Ctrl+C exits 2 → 130 in task 4.
- **#6** Multi-day schedules skipped, not round-tripped (bk, las) → task 3.
- **#6b** bk's agents-restore preview does not mirror the restore (LOW/MEDIUM) → task 3.
- **#9** Flag values not validated (`--upgrade=yes` declines; `--upgrade=y` alone answers nothing; `go --only=` runs all; non-TTY without a selection runs `go`), #10's `[auto: …]` residue → task 6.
- **#11** Fixed `/tmp/brew_*.log` paths, modules 0, 1 (`--dry-run` too), 2 (LOW: symlink, leaks, concurrent runs; 2 dead in the final `rm`) → task 4, a per-run dir.
- **#12** las re-register/repair widen a scoped agent to `go --yes` (LOW → MEDIUM proposed) → task 3.
- **#13** Agent labels from untrusted data (LOW/MEDIUM) → task 3.
- **#14** `MODULE_DRYRUN` = the modules ignoring `--dry-run` (`[bk]`/`[las]`=0; never flip a 0 without the fix; `_KNOWN_UNGATED` bidirectional) → task 3 (`[1]=0`, `_KNOWN_UNGATED=(1)` if module 1 still writes; today `[1]=1`), closes in task 4 with #3.
- **#15** bk `[4] Check` evaluates the Brewfile in a preview (MEDIUM, accepted until bk goes) → task 3.
- **#16** las `[c]` deletes the agents' audit logs, ungated; `mkdir` ungated (MEDIUM+LOW, accepted until las goes) → task 3.
- **#18** `_module_14` collision (bk/las/mas = `_module_14/15/16`) → task 3, which checks none is left.
- **#21** Non-TTY bk/log runs hang (idle, MEDIUM) → task 3; `_handle_log`'s bare `read` (deaf to `--yes`; an open stdin waits) → task 4 (D1).
- **#22** bk ignores NON_INTERACTIVE (LOW-MEDIUM) → task 3.
- **#24** las recreate rejects zero-padded minutes (LOW) → task 3.
- **#25** The child recomputes `LOG_FILE` (LOW: a log path that differs) → task 4.
- **#26** Module 3 corrupts brew's JSON via `echo` (MEDIUM) → task 5: `printf '%s'`, `mod_03:82`.
- **#27** Agents on interactive-only modules report done (LOW) → task 3.
- **#29** bk wet previews trigger Homebrew's auto-update (INFO) → task 3.
- **#31** Homebrew 6.0/7.0 compatibility (appendix D's F2, F4–F9, F11, NEW-a; F1 → task 3) → task 5.
- **#32** The log prompt's `[3] Delete` lies (LOW) → task 4 (D1).
- **#33** "noise until BM-18": `brew_manager.sh:533-534`/`:584`, `lib/common.sh:339-341`, CLAUDE.md's **Public contract** (the returns are uniformly 0) → task 7.
- **#38** The run summary shows unmeasured counters as measured: after module 1 alone, "Installed casks 0 / formulae 0 / Available updates 0" and the adopt rows (task 2's acceptance run) → task 7, with #4b.
- **#39** Module 1's restore box overflows: "From: …" and the local-changes line exceed the 74-column field of an 80-column terminal; `_box` never truncates → task 5 (module 1's texts).
- **#40** `/Users/seco/Projects/_upgrade-scratch/brew-manager`: keep until the framework's triage closes, then the user deletes it (decision C) → TRIGGER: the triage closes.
- **#41** Upstream duplicates among the OPEN IMPs: the Architect flags them after their harvest session; none closed as a duplicate before (decision D) → TRIGGER: the Architect's report.
- **#42** `attribution.sessionUrl` unproven (it needs the project's settings loaded) → TRIGGER: each checkpoint, the link count of [[sessions/2026-11-07-post-upgrade-checkpoint]] (Follow-up); closes at a commit the user confirms came from Remote Control or the cloud. The user decides if CLAUDE.md's rule names the limit.
- **#44** The run header's "no changes" (`--dry-run`, `brew_manager.sh:496`) and "built-in defaults" (`--yes`, `:500`) are false while #3, #14–#16, #21–#22 hold (LOW) → tasks 3–4.
- Closed, text in appendix A: #1, #2, #5, #5b, #7, #8, #10, #17 (reopen: a caller sets the variables), #19, #20, #23 (reopen: no Homebrew outside a login shell), #28, #30 (merge `8a7e6a2`), #34 and #36 (decisions A, B: *Decisions made*), #35 (the user's local rules narrowed, re-read 2026-11-07), #37 (closed by `chore/post-upgrade-checkpoint`), #43 (the lint ran 2026-11-08: the note's Follow-up).
- [[LEARNINGS]]: OPEN 006, 008–021, 023–029, 032–056 (033…050 sent to the Architect 2026-11-07) → TRIGGER: the periodic retro or the user's request; the ones v4.1.0 covers upstream after #41. Applied 001–004, 007, 022, 030, 031; Deferred 005 (its own trigger).

## Active branches
- **chore/post-upgrade-checkpoint**: done (plan completed), at `/fw:integrate`'s checks (no tag).
- **main** (integration = stable): `0b127a9` = `origin/main`, latest tag `v1.5.0` = VERSION; `origin/dev` dormant; every other branch merged and deleted.
