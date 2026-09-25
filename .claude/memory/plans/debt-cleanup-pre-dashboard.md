---
type: plan
prompt: debt-cleanup-pre-dashboard
branch: one branch per task (listed below)
created: 2026-09-25
status: in-progress
tags: [plan, debt, security, dashboard]
---
# Plan: close the open debts before the Dashboard improvement

## Goal
Every (a) item of [[sessions/2026-09-24-debt-inventory-pre-dashboard]] closed,
integrated and released as v1.5.0; the (b) items handed to the improvement's first
task; the (c) items tracked in STATE with their triggers.

> A programme, not a single-prompt plan: each task is a BRANCH and a deliverable with
> its own end-of-deliverable cycle (gate where marked → /retro → /checkpoint → printed
> /integrate → stop until the user's go). Sixteen entries exceed docs/01's healthy range
> for one prompt precisely because each entry is a whole prompt; a heavy branch gets its
> own task plan. The decisions it rests on: [[decisions/2026-09-25-debt-cleanup-pre-dashboard]].
> Item ids (#15, N-HANG, …) refer to the inventory note.

## Tasks
- [x] 1. `chore/imp-022-sensitive-selection` — IMP-022 (`lib/selection.sh` into every
  sensitive list) + #7 (the one-off gitleaks scan of the whole history, recorded);
  persists the inventory, this plan and the decision; Level-1 memory corrections.
  Gate: no (author-verifies, grep DoD with counter-proof). — commit: `6b1e5f6`,
  `aa54a51`, `90cb34c`, `5fa7159`, checkpoint `2ef3c21`; merged in `73bc5ee`.
- [x] 2. `chore/apply-project-imps` — IMP-003, IMP-004, IMP-007, IMP-002, one commit
  each; IMP-002/004 marked `Destination: framework`; IMP-005 → Deferred. Gate: no.
  — commit: `a59d5eb`, `a7f309f`, `225cadd`, `53d4827`, review fixes `36aa1b2`,
  checkpoint `3d36cf4`; merged in `9e4f2b4`.
- [x] 3. `chore/gitignore-d10` — #20 (`.vault-token`, `vault-keys.json`, `*.iml`).
  Gate: no. — commit: `7ef025b` + the checkpoint; ready for integration.
- [ ] 4. `fix/startup-brew-env` — N1 + 4b-0: PATH bootstrap for launchd/GUI starts; the
  installer honours `--dry-run` and never starts without a terminal (`_ask`); a NEW exit
  code for the failed environment precondition, added to the docs/04 contract (MINOR);
  the README exit-status paragraph; the real-launchd check with the user (procedure
  below, to run before any code). Gate: yes.
  — commit: —
- [ ] 5. `refactor/module-fn-names` — #18: `_module_bk`/`_module_las`/`_module_mas`, a
  generic dispatch, the `las`/`mas` section headers, the wiring guard test; README
  "Adding a new module", CLAUDE.md, new-component.md. Gate: yes (a light adversarial
  lens on the dispatch). — commit: —
- [ ] 6. `fix/headless-prompts` — N-HANG + N-bk-NI: `_handle_log` and the bk/log menus
  through `_read_choice`; the watchdog e2e harness. Gate: yes (mod_bk). — commit: —
- [ ] 7. `fix/cli-flag-values` — #9 residual: exact values at the edge, an ONLY_SET
  marker, empty `--only=` → 1, empty `--skip=` stays valid, non-TTY without a selection
  → 1, the `_ask` display. Gate: yes. — commit: —
- [ ] 8. `fix/mod03-json` — N2: `printf '%s'`, one python pass, a reported parse
  failure. Gate: no. — commit: —
- [ ] 9. `fix/bk-dryrun-check` — #15 (static check in dry-run; in wet mode a
  confirmation naming the Brewfile execution) + N-bk-1 + the bk half of #14. Gate: yes.
  — commit: —
- [ ] 10. `fix/las-dryrun-clean` — #16 (+ `_ask_danger` on [c] in wet mode) + the las
  half of #14; closes #3 and #14. Gate: yes. — commit: —
- [ ] 11. `fix/bk-agent-trust` — #6b + the bk half of #13 + 3b-bk; introduces
  `lib/agents.sh` (label predicate + shared `schedule=` parser, sensitive, added to the
  lists). Gate: yes, adversarial. — commit: —
- [ ] 12. `fix/las-agent-trust` — #12 + the las half of #13 + N-las-recreate; migrates
  las to `lib/agents.sh`. Gate: yes, adversarial. — commit: —
- [ ] 13. `fix/per-run-paths` — #11 + 11-bis: a per-run tmp dir, LOG_FILE computed
  once. Gate: yes. — commit: —
- [ ] 14. `chore/memory-harvest-map` — (i) the brew→framework IMP map. ON HOLD until
  the framework numbers AND the format arrive from the other chat. Gate: no.
  — commit: —
- [ ] 15. `docs/readme-truth` — the README residue (R2, R2b, R3, R4, R5, R10, R11–R13,
  M3), SECURITY.md, the "managed with Claude Code" decision; a claim-by-claim final
  check. Gate: no. — commit: —
- [ ] 16. `chore/release-v1.5.0` — VERSION + CHANGELOG `[1.5.0]` with Known limitations
  (#4b until the improvement, #17 and #3b with their conditions, #6); the tag is the
  user's. — commit: —

## Task 4 — the real-launchd verification (proposed 2026-09-26, reviewed; awaiting the user's go)
Asked by the user before branch 4 starts: N1 + 4b-0 (STATE #23) is declared confirmed only
after a run under a REAL launchd job. Drafted, then reviewed adversarially (a safety lens
and a validity lens, both "sound with fixes"; the fixes are applied below).

**Hypothesis.** A job launchd starts runs `/bin/zsh <repo>/brew_manager.sh …` with the
default PATH `/usr/bin:/bin:/usr/sbin:/sbin`; a non-login, non-interactive zsh reads only
/etc/zshenv and ~/.zshenv (absent), never /etc/zprofile or ~/.zprofile, so
`command -v brew` fails, the tool prints "Homebrew is not installed on this system.", its
bare `read` gets EOF (launchd's stdin is /dev/null), and it exits **0** before the
`script(1)` re-exec. Read-only facts already predict it (brew only in /opt/homebrew/bin,
`launchctl getenv PATH` empty, an existing gui/501 agent shows the default PATH).

**The job.** The agent writes `/Users/seco/Projects/brew-manager/logs/com.m2ndlab.verify-n1.plist` (logs/ is git-ignored) only after the user's go. It
mirrors what `mod_las_scheduler.sh:214-238` writes (and the bk restore, same shape): the
same ProgramArguments form, no EnvironmentVariables. Deliberate differences: label
`com.m2ndlab.verify-n1` (not the `com.m2ndlab.brew-manager.` prefix, so the las integrity
scan never sees it); no StartCalendarInterval and RunAtLoad false (on demand only); loaded
from logs/, never from ~/Library/LaunchAgents (nothing persists at login); arguments
`1 --dry-run` (the user's choice). On the not-found path the arguments are irrelevant: the
brew check runs before they are validated, and the installer's bare `read` ignores
`--yes`/`--dry-run`, so the verdict carries over to real `<modules> --yes` agents.
ProgramArguments: `/bin/zsh`, `/Users/seco/Projects/brew-manager/brew_manager.sh`, `1`, `--dry-run`; StandardOutPath
`/Users/seco/Projects/brew-manager/logs/verify_n1.out`; StandardErrorPath `/Users/seco/Projects/brew-manager/logs/verify_n1.err`.

**Block A — preflight (read-only; the user pastes the whole output back).** Expected:
`278ce8f` and a clean status; brew only in /opt/homebrew/bin; both zshenv files missing;
an empty `getenv`; no brew_manager process (if one is listed, stop and wait); both
verify_n1 files missing; "Could not find service"; `plutil` OK.
```
git -C /Users/seco/Projects/brew-manager log -1 --format=%h -- brew_manager.sh
git -C /Users/seco/Projects/brew-manager status --short -- brew_manager.sh lib modules
sw_vers
uname -m
ls -l /opt/homebrew/bin/brew /usr/local/bin/brew
ls -l /etc/zshenv ~/.zshenv
launchctl getenv PATH
pgrep -fl brew_manager.sh
ls -l /Users/seco/Projects/brew-manager/logs/verify_n1.out /Users/seco/Projects/brew-manager/logs/verify_n1.err
launchctl print gui/501/com.m2ndlab.verify-n1 2>&1 | head -2
plutil -lint /Users/seco/Projects/brew-manager/logs/com.m2ndlab.verify-n1.plist
```

**Block B — the run (the user pastes the whole output back).** The loop waits up to 120 s
while the job runs; if `state = running` still shows afterwards, do NOT clean up: report.
```
launchctl bootstrap gui/501 /Users/seco/Projects/brew-manager/logs/com.m2ndlab.verify-n1.plist
launchctl kickstart -p gui/501/com.m2ndlab.verify-n1
for i in {1..120}; do launchctl print gui/501/com.m2ndlab.verify-n1 | grep -q 'state = running' || break; sleep 1; done
launchctl print gui/501/com.m2ndlab.verify-n1 | grep -E 'state =|runs =|pid =|last exit|last terminating signal'
launchctl print gui/501/com.m2ndlab.verify-n1 | grep -B3 'PATH =>'
cat /Users/seco/Projects/brew-manager/logs/verify_n1.out
cat /Users/seco/Projects/brew-manager/logs/verify_n1.err
find /Users/seco/Projects/brew-manager/logs -name 'brew_report_*' -newer /Users/seco/Projects/brew-manager/logs/com.m2ndlab.verify-n1.plist
```

**Reading the outcome.**
- CONFIRMED: verify_n1.out contains "Homebrew is not installed on this system." and
  "brew-manager cannot continue"; verify_n1.err is empty; `runs = 1` and
  `last exit code = 0`; the job's PATH is the default one; `find` prints nothing (no
  session log: the run stopped before `script(1)`).
- REFUTED: verify_n1.out shows "Running modules: 1" AND the job's PATH line contains a
  Homebrew prefix whose source (which environment block, which setting) is identified.
  Even then the PATH bootstrap is NOT dropped on the evidence of one Mac: the outcome is
  input to the user's decision.
- INCONCLUSIVE: anything else — the job never ran, still running after the poll, a
  terminating signal, brew found with no identifiable source. Reported as is. An optional
  control job of the same shape can then print zsh's effective PATH
  (`/bin/zsh -c 'print -r -- PATH=$PATH; whence -p brew || print brew-not-on-PATH'`).

**Block C — cleanup (only after the output of A and B is pasted back and recorded).**
Expected: "Could not find service" after the bootout, and no process listed.
```
launchctl bootout gui/501/com.m2ndlab.verify-n1
launchctl print gui/501/com.m2ndlab.verify-n1 2>&1 | head -2
ps -axo pid,ppid,pgid,command | grep -E 'brew_manager[.]sh|brew(\.rb)? doctor'
rm /Users/seco/Projects/brew-manager/logs/com.m2ndlab.verify-n1.plist /Users/seco/Projects/brew-manager/logs/verify_n1.out /Users/seco/Projects/brew-manager/logs/verify_n1.err
```
**Block D — only if the `ps` line of block C listed processes:** `kill` followed by the
PIDs read from that list (never `pkill -f`, which can match an editor or an agent whose
argv contains the path).

**Safety.** Brew not found (the expected case): banner, a bare `read` at EOF (the installer
runs only on `^[Yy]$`), `exit 0` — no curl, no `script(1)`, no /tmp file, no session log;
logs/ already exists. Brew found: the read-only health module under --dry-run
(`HOMEBREW_NO_AUTO_UPDATE=1`), `brew doctor` writes the fixed `/tmp/brew_doctor.log` (#11),
a session log `logs/brew_report_<ts>.log` stays (kept as evidence: `find` names it), and at
the end the child removes the fixed /tmp files — hence the "no other session" precondition
of block A. A hang: the poll bounds the wait; `bootout` stops the job; the recorded child
lives in `script(1)`'s own session, which launchd's group kill does not reach, hence the
`ps` check AFTER the bootout and block D (IMP-023).

**Recording.** Blocks A and B verbatim go into branch 4's session note, and STATE #23 is set
to confirmed/refuted/inconclusive, BEFORE any code of branch 4 is written.

## Handed to the improvement's first task (category b)
The improvement (the Dashboard) opens with the outcome contract and the JSON layer;
that first task receives, from the inventory and the user's decisions:
- 4b-1 + 4b-2 — the outcome contract of the 18 modules (with #4, the "unmeasured"
  counters, STATE #27), designed with the JSON schema; 4b-3 only if its trigger fires.
- **Extend IMP-002 to the output surfaces when the schema is defined** (user decision,
  2026-09-25: not before — today the checklist covers parity extractions and code built
  on the same contract, down to the exit code the user observes).
- The JSON layer into every sensitive list (docs/03: a surface that acts on behalf of a
  client), by the IMP-022 mechanism.
- The GUI invocation contract: a clean environment (the condition that keeps #17
  deferred), stdin `/dev/null`, an explicit selection, flags and never environment
  variables (STATE #28).
- Headless consent for default-n actions (BM-16), `--adopt` by a stable key instead of
  a position, per-action entry points for bk/las/log, agents carrying flags (a
  `modules=` extension, MINOR), the `_is_*` predicates for new code.
- The #3b condition: the JSON layer is built from structured data, never from the
  modules' screen output.

## Resumption notes
- Branch names of tasks 4–16 are provisional; each branch's checkpoint records the real
  one and the merge sha here.

## Links
[[STATE]] · [[sessions/2026-09-24-debt-inventory-pre-dashboard]] ·
[[decisions/2026-09-25-debt-cleanup-pre-dashboard]] · [[plans/roadmap-v2]]
