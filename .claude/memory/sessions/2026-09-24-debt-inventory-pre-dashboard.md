---
date: 2026-09-24
task: read-only inventory of every open debt before the macOS Dashboard improvement (items, classification, order, release)
branch: main (read-only at 8ed9f5c; persisted on chore/imp-022-sensitive-selection)
status: completed
model: 'claude-opus-5-5'
turns: 1
tags: [session, inventory, debt, security, dashboard]
---
# Session 2026-09-24 — debt inventory before the Dashboard (read-only)

The user asked for a read-only inventory of every open item before a major improvement
(a macOS Dashboard as a client of brew-manager, plus new Homebrew functions): the STATE
"Attenzione" entries, the project-destination OPEN IMPs, the stale product README, the
brew→framework harvest map and the decisions left open by the framework upgrade — each
with what/files/risk/estimate/sensitive/contract, a category (a) close now / (b) first
task of the improvement / (c) defer, a serial order and a release assessment. No
branch, no commit during the inventory. The user approved it on 2026-09-25 with changes:
[[decisions/2026-09-25-debt-cleanup-pre-dashboard]] (the decisions) and
[[plans/debt-cleanup-pre-dashboard]] (the ordered branches). This note is the full
record, so later branches can point at an item instead of re-deriving it.

## Method
- 10 delegated agents on the same model as the main session: 5 area analysts (dry-run
  and the bk/las paths; the `_module_14` collision; the return contract; guard-rail
  hardening; process/docs/memory) and 5 adversarial verifiers with a mandate to refute.
  All read-only on `main` 8ed9f5c; reproductions in sandboxes (a symlink farm of the
  repo, a fake HOME, `BREW_MANAGER_SCRIPT_DIR` redirected, mock `brew`/`launchctl` on
  PATH, menus driven by stdin, perl watchdogs). Baseline `make test` 268/268
  (30+18+6+9+8+38+72+87); the repo was clean before and after.
- Each item below merges the analysis with its verifier's corrections ("Verifier:").
  The sandbox evidence paths were session-local and are gone: every claim carries its
  code reference so it can be re-verified.
- Housekeeping: 8 orphaned processes (4 hung runs and their `script(1)` parents,
  reparented to PID 1, alive ~75 minutes) left by the sandboxes were killed by the main
  session — live evidence of item N-HANG.
- Coverage limits: README module cards 1, 6, 7, 11, 12 checked by sampling only; the
  launchd behaviour was SIMULATED with `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin`,
  never under a real launchd job (the user asked for a real-launchd check in the N1
  branch); the dynamic return-code sampling ran with `NONINTERACTIVE=1` everywhere, so
  the bk/las/log/mod_10 return conclusions are static.

Legend: estimate S/M/L; "sensitive" = touches a rule-8 component (security gate);
"contract" = the docs/04 public contract; the category shown is the FINAL one after the
user's decisions (the proposal is noted where the user changed it).

## A. Dry-run truth and the bk/las agent paths

### #15 — bk [4] Check evaluates the Brewfile as Ruby, also under --dry-run
- Status: open. Case `4)` (`mod_bk_brewfile.sh:494-509`) has no dry-run gate;
  `brew bundle check` runs at :499 and again at :503 (`--verbose`). Homebrew 6.0.21
  evaluates the Brewfile with `instance_eval(@input, @path.to_s)`
  (`Library/Homebrew/bundle/dsl.rb:67`), against the file's own comment at :95-99 (the
  reason the restore preview reads the Brewfile statically). Reproduced: DRY_RUN=1 and
  input `4` → the mock recorded two `brew bundle check --file=…/backups/Brewfile`
  calls. The registry declares it (`MODULE_DRYRUN[bk]=0`, `lib/selection.sh:115`), so
  every bk dry-run reports `⚠ ran anyway`.
- Verifier: reachable WITHOUT a tty today. mod_bk has no NON_INTERACTIVE guard (unlike
  las:19) and reads its menu with a bare `read -r bf_choice` (:318); `script(1)`
  forwards the parent's stdin to the child's pty, so a non-TTY caller that writes the
  answer after the prompt (a GUI using Process + Pipe) reaches [4]. Only a closed
  stdin/EOF makes it Skip. Timing-dependent but real.
- Risk MEDIUM: arbitrary code from a tampered `backups/Brewfile` (a folder the README
  invites copying between Macs) during a "preview". For the GUI the per-module state is
  falsely pessimistic (`ran`), and a preview "Check" would run Ruby.
- Estimate M · sensitive yes (mod_bk) · contract none (PATCH) · (a) → branch 9.
- Fix: under --dry-run never call `brew bundle`: print an info line and reuse the static
  read (`_preview_restore_brew`, :100-120) or a static compare of the `brew/cask/tap
  "x"` lines against `brew list --formula -1`, `brew list --cask -1` and `brew tap`,
  listing the lines that cannot be read statically. Then `MODULE_DRYRUN[bk]=1`, bk out
  of `_KNOWN_UNGATED`, the registry comment updated. User decision: in wet mode keep
  `brew bundle check`, behind a confirmation that says explicitly the Brewfile is
  executed, with `HOMEBREW_NO_AUTO_UPDATE=1`.
- Tests: `test_dryrun_gates.zsh` — the mock must record `$1 $2` (today only `$1`, which
  cannot tell `bundle check` from `bundle dump`); a sandbox `BREW_MANAGER_SCRIPT_DIR`
  with `backups/Brewfile`; dry + stdin `4`: no `bundle check`, notice printed, static
  list present (anti-vacuity); wet with the same stdin: `bundle check` recorded
  (teeth). `test_run_summary.zsh`: assert `[bk]==1` like mod_02/mas (:172-175). The
  grep check at :156-166 alone does not protect: mod_bk already mentions
  `BREW_MANAGER_DRY_RUN` 7 times, so a flip without a fix would pass it.
- Files: mod_bk:494-509 (:18 `mkdir -p backups/` optional); selection.sh:82-115;
  test_run_summary.zsh:183 and :172-175; test_dryrun_gates.zsh; README.md:98-121;
  CHANGELOG; STATE #3/#14/#15; components/mod-bk-brewfile.md.

### #16 — las [c] deletes the agents' audit logs without a gate; `mkdir ~/Library/LaunchAgents` outside the gate
- Status: open, both halves. `rm -f` at `mod_las_scheduler.sh:817`/:819 with no dry-run
  gate and, in wet mode, no confirmation (the only guard is "no agent installed");
  `mkdir -p "$agents_dir" "$plist_dir"` at :15 runs BEFORE the non-interactive return at
  :19-23. Reproduced: dry-run + `c` deleted `agents_activity.log` and
  `logs/agent_std{out,err}_*.log` ("3 log file(s) deleted") and created
  `~/Library/LaunchAgents`; a non-interactive dry-run also created it. Correction to the
  recorded entry: the "mkdir in mod_log:15" part is a no-op (`brew_manager.sh:67-70`
  creates `logs/` unconditionally); bk:18 (`backups/`) and las:15 (`agents/`) are the
  tool's own directories; the only mkdir outside the tool is `~/Library/LaunchAgents`.
- Verifier: today no non-interactive client reaches [c] or any las path (las returns at
  :19-23 under YES or NONINTERACTIVE); a GUI "clear agent logs" button would need a new
  entry point (a feat) that must be born gated. The (a) rests on the truth of the `ran`
  state and on the irreversible audit loss in interactive dry-runs.
- Risk MEDIUM ([c]) + LOW (mkdir) · estimate M · sensitive yes (mod_las) · contract
  none (PATCH) · (a) → branch 10.
- Fix: under --dry-run, before any `rm`, an info line "would delete N log file(s)" plus
  one `_item` per file, and nothing deleted. Create `agents/` only in wet mode and after
  the non-interactive return; move `mkdir -p "$plist_dir"` into `_install_agent`, after
  the gate at :192 and before `cat >` at :214. Then `MODULE_DRYRUN[las]=1` and
  `_KNOWN_UNGATED=()` (keep the mechanism for future modules, with a comment —
  IMP-009). User decision: `_ask_danger` before [c] in wet mode.
- Tests: a sandbox HOME without `Library`; `agents/agents_activity.log` and
  `logs/agent_stdout_x.log`; YES=0, NI=0, stdin `c`: dry → files survive, "would
  delete" printed, no LaunchAgents dir; wet → files deleted (teeth); non-interactive dry
  → no LaunchAgents dir. `test_run_summary.zsh`: `_KNOWN_UNGATED=()`, `[las]==1`.
- Files: mod_las:15, :803-827, :192-214; selection.sh:82-115;
  test_run_summary.zsh:183-197; test_dryrun_gates.zsh; README.md:117-121; CHANGELOG;
  STATE #3/#14/#16; components/mod-las-scheduler.md.

### #14 — `MODULE_DRYRUN` and the bidirectional allow-list `_KNOWN_UNGATED`
- A sound mechanism, not a defect: `[bk]=0 [las]=0` (selection.sh:111-116),
  `_KNOWN_UNGATED=(bk las)` (test_run_summary.zsh:183, bidirectional checks :186-197).
  Limit: the grep check (:156-166) only proves the gate is MENTIONED (bk 7 hits, las 6);
  only the behavioural tripwires prove it.
- Risk LOW in itself; an IMP-008-class bug if flipped without the fix · S · (a), closed
  inside branches 9 and 10 (each flips its own entry and updates the registry comment
  and README:98-121).

### #3 (residual) — non-uniform DRY_RUN
- An umbrella entry. A sweep of every mutating command in `modules/*.sh` (brew
  install/upgrade/update/cleanup/autoremove/bundle, mas, rm, mkdir, launchctl
  load/unload, file redirects) finds every path gated (mod_00:201, 02:85, 04:78, 05:33,
  10:98, mas:44/127, bk ×7, las ×6, log ×2) except bk:499/:503 (#15) and las:817/:819
  and :15 (#16).
- Verifier: the sweep missed `mod_01_health.sh:96` — `brew doctor >
  /tmp/brew_doctor.log` writes a fixed /tmp path on EVERY run, --dry-run included
  (mod_01 is in `go`). `MODULE_DRYRUN` is unaffected (mod_01 is `ro`), but the #11
  symlink/O_TRUNC risk is reachable in a preview session and README.md:121 ("nothing
  is … overwritten") is imprecise → handled with #11.
- (a): closed in STATE when #15 and #16 are fixed.

### #6b — bk: the agents-restore preview does not mirror the real restore, and the restore degrades silently
- Status: open and wider than recorded (INFO). A sandbox with an 8-entry bundle: the
  dry-run [3a] lists all 8 as "would write … and load"; the wet restore wrote 5,
  skipped 2 with a warning (invalid label shape :169-172; multi-day :189-192) and 1
  SILENTLY (empty label :165), and DEGRADED 3 without a warning: (1) `Funday 10:00` —
  an unknown day leaves `_weekday` empty (:199-209), the plist has no Weekday → a DAILY
  agent that fires 7 times a week (the very risk the multi-day skip avoids); (2) a
  missing schedule → daily 9:00 with an empty `schedule=` in the conf; (3) `daily
  25:99` → the plist is clamped to 9:00 (:215-216) while the conf keeps
  `schedule=daily 25:99` (:272): conf and plist diverge and the listing lies. The
  comment at :138-139 ("so the preview never lies") is false, and so is README.md:390.
- Verifier: it also hits AUTHENTIC backups. brew-manager writes minutes zero-padded
  (`printf '%02d'`, mod_las:245/:247, copied into the bundle by `_backup_agents`,
  mod_bk:88); the restore clamp `[[ "$_minute" =~ ^([0-9]|[1-5][0-9])$ ]] ||
  _minute=0` (mod_bk:216) rejects "00"–"09": an agent at 9:05 is restored at 9:00 with
  no warning, while the preview, the message and the conf say 9:05.
- Risk LOW (to be re-graded LOW→MEDIUM at the gate) · estimate M · sensitive yes
  (mod_bk) · contract none (PATCH: the restore becomes stricter on malformed entries;
  the bundle and plist formats are unchanged) · (a) → branch 11.
- Fix: one verdict function (e.g. `_bundle_agent_plan <line>`) returning `SKIP|reason`
  or the normalised fields (label, weekday, hour, minute, modules, canonical schedule),
  used by BOTH `_preview_restore_agents` and `_restore_agents`; an unknown day, a
  missing schedule or an out-of-range time → SKIP with a reason, never a silent
  default; the conf written with the canonical schedule; the minute parser accepts
  `0[0-9]`. Parsing through printf/parameter expansion also closes the #3b sites in
  `_restore_agents` (:161-163) and in [5] View (:583-585). User decision: the shared
  parser and the label predicate live in a new sensitive `lib/agents.sh`.
- Tests: an invariant by construction on a bundle fixture — for EVERY entry the preview
  verdict equals the restore outcome (restored, or skipped with a reason); anti-vacuity
  (≥1 restored, ≥1 skipped); sandbox HOME + `BREW_MANAGER_SCRIPT_DIR` + mock launchctl;
  never the real `~/Library/LaunchAgents`.

### #12 — las re-register/repair widen a scoped agent to `go --yes`
- Status: open. The recorded claim "the listing under-reports; it does not change
  execution" (STATE #12, and the code comment mod_las:125-127 "it never affects what an
  agent EXECUTES") is FALSE. The extraction `grep -A1 brew_manager.sh | tail -1 | sed`
  (:517, :595, :753) gives `3` for a plist with `3` and `5` on two lines, and `35` when
  both `<string>`s sit on one line; `35` is invalid and `_sanitize_agent_modules`
  (:129-136) turns it into the placeholder `go` in the conf. Chain reproduced: an
  orphan plist with argv `--only=1 --yes` (health only, read-only; a VALID argv for the
  parser) → [6]→[r] re-register writes `modules=go` (:596) → the next [6] flags it as
  legacy, because any flag-shaped first argument is treated as corrupt (:517-519), with
  the false message "invalid (agent exits 2 every run)" → [r] Repair takes `go` from the
  conf (:754-755) and `_install_agent` rewrites the plist as `go --yes` (activity log:
  REGISTERED, INSTALLED, MIGRATED), against its own comment at :757-761.
- Verifier: a simpler path exists, with no misleading message — after the re-register a
  plain [4] Modify (change only the hour, Enter on "New modules [Enter to keep: go]",
  :393-394) rewrites the plist as `go --yes`; the prompt shows `go` as the current
  value, so the user cannot notice.
- Risk MEDIUM proposed (the gate classifies): an unattended agent goes from a read-only
  module to the whole sequence (adoption, upgrades, cleanup under --yes). Precondition
  today: a plist not written by brew-manager; forward: if the Dashboard or the BM-15
  presets write agents with `--only`/`--skip`, it becomes directly reachable.
- Estimate M · sensitive yes (mod_las) · contract none if minimal (PATCH); extending
  `modules=` for agents carrying flags would be MINOR (an improvement decision); the bk
  restore validates `modules=` with `_selection_is_valid`, which rejects flags
  (`--only=1` → INVALID) · (a) → branch 12.
- Fix: (1) read ALL the ProgramArguments `<string>`s after `brew_manager.sh` (e.g.
  `plutil -extract ProgramArguments json`, part of macOS, or a strict parser) and
  validate the full argv with the real grammar (`_resolve_cli` + the known flags); (2)
  the legacy detector flags only argv the real parser would REJECT (e.g. `--ye`), not
  every `-*`; (3) drop the `go` placeholder — an argv not representable in the conf →
  a skip with a warning ("re-register it manually"), as for multi-interval agents; the
  migration never reads from the conf a value that is not a validated selection written
  by `_install_agent`.
- Tests: a las harness in a sandbox; the orphan `--only=1` is not flagged and never
  rewritten; positional `3`,`5` on two lines → the conf says `3,5` or the re-register
  refuses; the true legacy `--ye` is still flagged (teeth).

### #13 — agent labels from untrusted data: no validation, no prefix
- Status: open and wider than recorded. A label coming from data is NOT validated in
  las on: re-register (:471, the file basename), the recreate of pending confs (:485,
  :663 → `_install_agent` :691), the legacy repair (:499, :740 → :764), [4] Modify
  (:380), [5] Remove (:441-444). `_install_agent` (:163-190) validates weekday, hour,
  minute and modules, never the label. The bk `_restore_agents` checks the shape (:169)
  but NOT the prefix. Reproduced: (1) bk — a bundle entry `label=com.other.vendor.agent`
  unloaded, overwrote with a brew-manager plist and reloaded an existing third-party
  plist in `~/Library/LaunchAgents`, and the preview listed it with no warning; (2)
  las — a planted conf with that label is flagged by [6] as "plist modules '' invalid"
  and [r] Repair overwrote the third-party plist. Structural XML injection is not
  practical (closing tags need `/`, which also lands in the file path, so `cat >`
  fails); the residue is a malformed plist launchctl rejects.
- Verifier: wider than third-party LaunchAgents — a label read from a conf can contain
  `../`, and [5] Remove runs `launchctl unload` + `rm -f "$plist_dir/${_label}.plist"`
  on ANY writable `*.plist` outside `~/Library/LaunchAgents` (path traversal;
  reproduced with `label=../../Documents/victim`: the file was removed and the mock
  launchctl was called on `…/LaunchAgents/../../Documents/victim.plist`); `cat >` on
  [4] Modify and on the recreate writes there too. In the bk restore traversal is
  impossible (the :169 regex excludes `/`); the re-register label (:471) already has
  the prefix enforced by its glob (:467), so only its shape matters there.
- Risk LOW recorded → between LOW and MEDIUM at the gate · estimate M · sensitive yes
  (las, bk) · contract none (PATCH: brew-manager always writes the
  `com.m2ndlab.brew-manager.` prefix, constant since d3aee0b / v1.1.0, so only
  hand-edited or third-party data is refused — noted in the CHANGELOG) · (a) → the bk
  half in branch 11, the las half in branch 12.
- Fix: one predicate `_agent_label_is_valid` =
  `^com\.m2ndlab\.brew-manager\.[A-Za-z0-9._-]+$` (it also closes the traversal),
  applied inside `_install_agent` as the last line of defence and at every data entry
  point; bk restore/preview: skip with a reason (inside the #6b verdict); las
  integrity/modify/remove: skip with a warning, plist untouched. User decision: the
  predicate lives in the new sensitive `lib/agents.sh`.
- Tests: a fixture with a third-party label and a pre-existing third-party plist in the
  sandbox HOME, plus a `../` fixture: after the bk restore, the las repair and the las
  remove the third-party file is intact and launchctl never touched it (mock log);
  teeth: a valid brew-manager label is still restored.

### N-bk-NI — mod_bk ignores NON_INTERACTIVE (found by the verifier)
- Status: new. The module menu (`read -r bf_choice`, mod_bk:318) and the Delete
  selection (`read -r del_choice`, :628) read stdin directly instead of
  `_read_choice`/`_ask`, and there is no guard like las:19. In a non-TTY run WITHOUT
  --yes, with the answers `6`, `all`, `n` piped in, [6] deleted the Brewfile and the
  agents bundle, while the banner ("Non-interactive, no --yes — every prompt is
  declined, nothing is modified") and README.md:188 ("fail-closed … can inspect and
  report but never modify anything") promise the opposite; the summary showed `✓ bk`.
  The #8 invariant does not cover menus with bare reads. It is also the path by which
  #15 is reachable without a tty. The same class exists in mod_log (`read -r
  log_choice`, :89).
- Risk LOW-MEDIUM · estimate S + an e2e test · sensitive yes (mod_bk) · contract none
  (PATCH; the README says piping the prompt is unsupported) · (a) → branch 6 with
  N-HANG (same fix: `_read_choice "Choice" "n"` = Skip under NI and --yes, identical to
  today's behaviour under launchd).

### N-las-recreate — the las recreate fails on every zero-padded minute (found by the verifier)
- Status: new. Recreating pending confs ([6]→[r], mod_las:663-691) fails for ANY conf
  brew-manager wrote with minutes 00–09, the default agents [1]/[2] at 09:00 included:
  the parser passes "00" to `_install_agent` and the regex at :177 rejects it ("Invalid
  minute '00' (0-59) — agent not installed"). In the same parser an unknown day leaves
  `_dc_wd` empty → a silent DAILY agent (:681-686): the #6b class on the las side. The
  README (Integrity check: "re-register … bring everything back in sync") is false for
  standard agents.
- Risk LOW (it fails visibly) · estimate S-M (the #6b parser fix, shared through
  `lib/agents.sh`) · sensitive yes (las) · contract none · (a) → branch 12.

### #6 — multi-day schedules are skipped everywhere
- A functional gap, not a defect: no writer produces multi-day agents (`_install_agent`
  takes one weekday, :169/:198-203; custom [3] asks for one day, :351;
  `_install_agent_multi` was removed in BM-07); legacy multi-day agents are correctly
  skipped with a warning (bk :189-192, re-register :578, legacy scan :506, recreate
  :677); README.md:438 is truthful.
- Risk none (the status quo is safe) · estimate L · sensitive if implemented · contract
  MINOR if implemented (StartCalendarInterval as an array; `schedule=Mon+Wed+Fri HH:MM`
  is the legacy format) · (c): re-evaluate in the Dashboard design (a multi-day picker
  is natural in a GUI → an M4 feat with its gate).

### N-bk-1 — bk wet previews trigger Homebrew's auto-update despite "no disk writes"
- `bundle` is in Homebrew's AUTO_UPDATE_COMMANDS
  (`Library/Homebrew/utils/auto-update.sh:143-149`), so in a non-dry run `brew bundle
  dump --file=/dev/stdout` (mod_bk:370, :401) and `brew bundle check` (:499) may first
  run `brew update --auto-update` and rewrite the index, while the About/menu promise
  "See what would be saved — no disk writes" (:33) and "(no save)" (:297). Under
  --dry-run it is already covered (`brew_manager.sh:160`). The IMP-011 class in wet
  mode.
- Risk INFO · estimate S · sensitive yes (bk) · contract none · proposed (c); **user
  decision: (a)** inside branch 9 (one line: `HOMEBREW_NO_AUTO_UPDATE=1` on the
  read-only `brew bundle` calls).

## B. Dispatch wiring and headless runs

### #18 — the `_module_14/15/16` collision
- Status: open and intact; reproduced END-TO-END (STATE said "plausible, not run").
  bk/las/mas define `_module_14()` (mod_bk:9), `_module_15()` (mod_las:9),
  `_module_16()` (mod_mas:8); log already uses `_module_log()` (mod_log:8), the right
  precedent. The core sources `modules/mod_*.sh` with an alphabetical glob
  (`brew_manager.sh:241-243`) and dispatches `bk) _module_14 / las) _module_15 / mas)
  _module_16 / *) "_module_${_mod}"` (:457-463). Digits sort before letters, so
  `mod_14_*` is sourced before `mod_bk_*` and bk's redefinition silently replaces
  `_module_14` (verified with LC_ALL=C, en_US.UTF-8 and it_IT.UTF-8, zsh 5.9:
  `functions_source[_module_14]` = mod_bk_brewfile.sh). Every dispatch path goes
  through the generic arm: `14` from the CLI, `go` (once 14 is in MODULE_IDS), the menu,
  a LaunchAgent with `modules=14`. Not reachable today: `14` is unregistered → exit 2
  (selection.sh:224; MODULE_IDS 0..13 at :118).
- Corrected cause (STATE said "would run bk (danger)"): under --yes without a tty
  bk/las/mas default to doing nothing. The measured damage: (1) the new module NEVER
  runs, silently; (2) the summary attests something false — RUN_STATUS is computed from
  `MODULE_RISK`/`MODULE_DRYRUN[$_mod]` by id (`brew_manager.sh:465`) while bk's code ran
  (with a stub `MODULE_RISK[14]=ro` the summary says `✓ 14 … completed`); (3) the run
  HANGS without a tty (N-HANG); (4) interactively, choosing 14 shows bk's menu with
  Restore and Delete; (5) bk's ungated `mkdir -p backups` (:18) runs. `go --only=14
  --dry-run` reproduces it too. README :565 ("a function (any number is fine
  internally)") is the trap that created it and would recreate it for any future named
  module.
- Verifier: three more sites — the visible headers `_section "15" "LaunchAgent
  Scheduler"` (mod_las:10) and `_section "16" "Mac App Store (MAS) Integration"`
  (mod_mas:9) show the internal number on screen and in the session log (bk already
  uses `_section "bk"`); CLAUDE.md's "named by hand … in the dispatch case of
  `brew_manager.sh`" becomes false if the dispatch goes generic; a new test file →
  TREE regenerated and the test count updated (the Makefile is untouched: `make test`
  globs `tests/*.zsh`).
- Risk latent today, HIGH as soon as a module 14/15/16 is added (it never runs, it hangs
  agents and GUI runs, the per-module state is false — the IMP-008 class) · estimate M ·
  sensitive yes (the `brew_manager.sh` dispatch, mod_bk, mod_las; mod_mas medium risk),
  with a light adversarial lens on the dispatch (shared infrastructure) · contract none
  (docs/04 freezes the IDENTIFIERS, not function names; plists/confs/bundle hold ids
  only — mod_las:104/:226, mod_bk:89/:248/:273); fixing the `15.`/`16.` headers is
  visible in the TUI and the log → PATCH · (a) → branch 5.
- Fix: rename to `_module_bk`/`_module_las`/`_module_mas` (the `_module_log` model);
  collapse the dispatch to the generic arm `"_module_${_mod}"` (the resolver lets only
  validated tokens through — MODULE_DESC keys or the 4 names, selection.sh:204-207,
  :224-227, :257-261; verified: no injection opens); headers → `las`/`mas`; update the
  README (:559-568: four registries, `_module_<alias>`, the key-set pin of
  test_menu_registry.zsh:75-82, the hand-written lists at brew_manager.sh:336/:363 and
  mod_las:188), CLAUDE.md (the `_module_14/15/16` warning, and the dispatch-case
  sentence), new-component.md (:13-16, :50, the step 5 note), the CHANGELOG and the
  memory (core-brew-manager.md:52-53, mod-bk-brewfile.md:17, mod-las-scheduler.md:16,
  STATE #18, INDEX). NOT touched: lib/selection.sh, test_run_summary.zsh:159 (an
  id→file map), brew_manager.sh:377 (ids).
- Tests: a NEW guard test by construction with anti-vacuity: (1) every `_module_X()` in
  `modules/*.sh` defined in ONE file (≥18 found); (2) bidirectional: {X} == the
  MODULE_DESC keys — already RED on main without any stub (orphan functions 14 15 16,
  keys without a function bk las mas) and GREEN after the rename: the docs/02 RED→GREEN;
  (3) file↔id (`${(l:2::0:)k}` only for numeric keys: it truncates `log`→`og`); (4)
  dynamic: source every module in the glob order of :241 in a subshell and check
  `functions_source[_module_<k>]` per key (this is what sees the shadowing); (5) teeth:
  a mktemp copy of `modules/` with a `mod_14_stub.sh` and a duplicate `_module_bk` must
  be flagged; (6) with a generic dispatch, grep that no hand-written `_module_[0-9]` arm
  is left. Plus `zsh -n` and the smokes `./brew_manager.sh bk|las|mas|log --dry-run`
  (CLI selection, IMP-007). test_dryrun_gates.zsh:165/180 call `_module_16` → update.

### N-HANG — non-TTY runs of bk/log hang forever; every run blocks on the log prompt when stdin stays open
It merges three findings: NEW-NONTTY-HANG (module14 area), 10-bis (guard-rails area)
and N3 (process area).
- Status: new, not in STATE; the component note lib-common.md:104-105 records it with a
  FALSE cause ("in non-TTY the read fails and the keep default applies — intended but
  implicit").
- Mechanism: with the parent's stdin on /dev/null, `script(1)` forwards ONE EOF (^D) to
  the pty. Direct `read`s consume it: the bk menu (mod_bk:318; also :628), the log menu
  (mod_log:89; also :100, :121, :164), the main menu without a CLI selection
  (`brew_manager.sh:393`). At the end of EVERY session the core calls `_handle_log`
  (`brew_manager.sh:558`), which does a direct `read -r log_choice` (`lib/log.sh:20-21`)
  ignoring YES and NON_INTERACTIVE → it waits forever: no exit, no exit code, the
  session log never cleaned. Modules without direct reads (8) or that return early
  non-interactively (las :19-23) end normally; `_ask`/`_read_choice` never read under
  NON_INTERACTIVE (common.sh:434, :469), so they do not consume the EOF.
- Measured (watchdogs): `bk --dry-run`, `bk --yes` (the LaunchAgent shape), `log
  --dry-run`, `bk,log --yes`, `bk,bk --yes` with stdin </dev/null → HUNG (rc 142/143
  from the alarm); `8 --dry-run`, `las --yes`, `mas --dry-run` → rc 0. `--only=` or
  `--yes` without a selection run the whole `go` sequence and then hang. With stdin on
  an open pipe carrying no data even the minimal run waits for stdin to close: `(sleep
  6; printf '1\n') | zsh ./brew_manager.sh 8 --dry-run` → rc 0 after 6 s, stuck on
  "Choice [1/2/3, default: 1]" under the "Non-interactive, no --yes" banner. On a
  terminal, `go --yes` stops at "What do you want to do with the log?" → README :162
  ("Unattended full run: every question is auto-answered") is false and :526 ("each
  interactive session") imprecise. It also violates the CLAUDE.md convention "prompts
  ONLY through `_ask`/`_read_choice`".
- Verifier: the hung child (`script(1)` + zsh) SURVIVES the parent's death, reparented
  to PID 1 — a GUI with timeouts would leak orphans on every run (8 were killed at the
  end of this inventory). The scheduler explicitly accepts named modules in an agent
  (mod_las:186-188), so the case is reachable from the UI today. Unverified inference:
  launchd does not start a new instance of a still-running job, so a `bk`/`log` agent
  would stop after its first run.
- Risk HIGH for the GUI, MEDIUM today (agents on bk/log) · estimate M (verifier: the
  `_handle_log` fix alone is not enough — after the first direct read consumes the EOF
  any second direct read hangs, so the bk/log menu guards are mandatory; plus a watchdog
  e2e harness, which does not exist: test_exit_codes.zsh has no timeout and macOS has
  no `timeout`) · sensitive yes (mod_bk; `brew_manager.sh` too if `exec </dev/null` is
  used in the child — that alternative must come with #9's refusal of non-TTY runs
  without a selection, or `echo 5 | ./brew_manager.sh --yes` would turn into `go`) ·
  contract none (PATCH) · (a) → branch 6.
- Fix: `_handle_log` through `_read_choice "Choice" "1"` (keep); the bk and log menus
  through `_read_choice` (fail-closed default) or an early return under NON_INTERACTIVE
  like las:19.
- Tests: e2e cases in test_exit_codes.zsh with stdin </dev/null for every module with a
  menu (bk, log) expecting rc 0 within a watchdog, plus the open-pipe case;
  anti-vacuity.

## C. Outcome truth (#4 / #4b) and the startup path

### 4b-1 — minimal truthful outcomes
- Status: open, with a different cause than recorded. STATE says today's returns are
  NOISE ("mod_02 returns 1 on healthy runs", sampled 2026-07-18): not reproducible on the
  current code. Returns are UNIFORMLY 0 and carry no information: 17 of 18 modules
  sampled in 5 scenarios (dry-run; wet without --yes; wet with --yes; wet with --yes and
  brew failing on every verb; dry-run with brew failing) → rc always 0. The only
  informative return is mod_10 (`return 1` on a failed preview/upgrade,
  mod_10_greedy.sh:112-115, :158-162), and the dispatcher discards it:
  `brew_manager.sh:456-465` never reads `$?` (the comment at :452-453 says so),
  `_run_status` (lib/common.sh:368-373) is a pure function of dry/risk/dryrun, and the
  `failed` glyph is RESERVED and never assigned (:339-341).
- The "success printed anyway" pattern (STATE #4) is wider than recorded (mod_02, mas):
  mod_02:96-106 (`_spinner` rc discarded → "Database updated"), mod_04:85-88 (`brew
  upgrade | while` → "Update completed"), mod_05:82-90 (the autoremove rc is never read
  → "Dependencies removed"), :93-96 ("Cleanup completed") and :66 (`return 0` after a
  failed preview), mas:51-58 (a failed install → `_err`, then `return` with rc 0) and
  :130-136, mod_bk:327-333 and :348-354 (dump in a pipe: with --force a STALE Brewfile
  stays and is announced "Brewfile saved"), :447-451 and :473-477 ("Homebrew restore
  completed"), mod_00:215-218 (a failed adoption → only `_warn`, rc 0). Reproduced:
  mod_05 prints "Dependencies removed", "Error: mock failure (autoremove)", "Cleanup
  completed", rc 0, summary ✓.
- Verifier: (1) the slice is L, not M (~12 files, 5 of them sensitive, an adversarial
  gate); (2) `return 1` is wrong for mod_bk, a `while true` menu (:286): options 1, 1b,
  3a, 3b do not `break`, and the module rc is the `break`'s 0 → an accumulator is needed
  (e.g. `_bk_rc=1`, `return $_bk_rc` after the loop); (3) missing sites:
  `_restore_agents` writes the plist (:236-261), `launchctl load … 2>/dev/null` is
  unchecked (:263-264), then `_ok "Restored agent"` (:277) and the count (:278);
  `_backup_agents` (:77-92, "Agents bundle saved"); the las remove (`launchctl
  unload`/`rm -f` unchecked, `_ok "Removed"`, :443-446); `_install_agent` returns 1
  honestly (:261-263) but the menu discards it (`break`); mod_log `_ok
  "Deleted"`/`"Purged"` after an unchecked `rm -f` (:150-151, :177-178); (4) the
  post-increment idiom from 0 — `(( x++ ))` with x=0 returns 1 — lives in helpers
  (mod_bk:278 `(( _restored++ ))`, mod_las:447, :817-819): harmless today, a source of
  false ✗ once helper rcs are propagated → the convention `(( ++x ))`/`(( x += 1 ))` and
  an explicit `return 0`; (5) the sampler ran with NONINTERACTIVE=1 everywhere and a
  mock without `auto_updates: true`, so the bk/las/log/mod_10 conclusions are static
  (still true).
- Proposed (a); **user decision: (b)**, the first task of the improvement together with
  4b-2, so the same sensitive sites go through the adversarial gate once.

### 4b-2 — the full outcome contract for the 18 modules
- Status: open. Three verified holes: (i) read-only modules that confuse "brew failed"
  with "nothing to report", because errors go to `2>/dev/null`: mod_04:18-20 → :65 "All
  packages are up to date" (shown), mod_10:41/:48 → "No auto_updates casks found"
  (shown); the same shape in mod_11:88-93, mod_12, mod_03:78-98, mod_06:29,
  mod_07:20-22, mod_13:62-74; the false count also reaches the summary stats
  (`OUTDATED_COUNT` 0 → "Available updates 0", `brew_manager.sh:517-521`) — the counters
  need an "unmeasured" state distinct from 0, like `_du_kb`; (ii) SKIPPED modules shown
  as ✓ (the las non-interactive return; the bk/log menus taking "n"); (iii) DECLINED
  consent shown as ✓ (mod_05:69-78 "Cleanup skipped" + `return 0`; mod_04, mod_10, mas,
  mod_00 in fail-closed).
- Needed: per-module states richer than ok/failed — ok, findings, preview, ran (gone
  after #15/#16), skipped, declined, partial, failed — plus a reason and the items
  involved; an explicit channel (e.g. `_mod_outcome <status> [reason]` writing
  MOD_OUTCOME/MOD_REASON, reset by the dispatcher before each module; precedence
  explicit > rc≠0 → failed > registry-derived), then an audit of all 18 modules.
- Risk: without it the GUI shows "clean"/"up to date" when brew does not answer, and
  "completed" for skipped or declined actions · estimate L · sensitive yes (every rule-8
  component; adversarial gate) · contract: the summary is presentation; the JSON layer
  will be a NEW public surface (MINOR) and must be ADDED to the docs/04 contract list in
  the same decision · (b), designed together with the JSON schema (a decision in
  decisions/ first).
- Tests: an invariant over ALL `_module_*` with anti-vacuity (with a failing mock brew no
  module reports `ok`), a truth table of the outcome helper, an e2e of the summary with
  skipped/declined in fail-closed.

### 4b-3 — an exit code when a module fails at runtime
- Status: open. The child always ends with `exit 0` (`brew_manager.sh:567`); the parent
  propagates it through `script(1)` (`_run_rc=$?` :258, `exit $_run_rc` :284). docs/04
  keeps it OUTSIDE the contract ("additive extension with BM-18").
- Contract: MINOR with a NEW distinct code, 0/1/2 unchanged and
  declined/skipped/preview/ran staying 0; MAJOR if 1 or 2 were reused or a fail-closed
  refusal became non-zero. `script(1)` on macOS reports the raw signal number (HUP 1,
  INT 2, QUIT 3, TERM 15): pick a value outside 1–31 (e.g. the sysexits band 64–78).
  Verifier: code 1 is ALREADY overloaded — the failed source of lib/common.sh, log.sh,
  selection.sh (`brew_manager.sh:175-180`), the failed source of a module (:242), a
  failed Homebrew install (:226) — so "1 = empty selection" is not exclusive; the
  decision must also say what happens to those infrastructure exits and to "Homebrew not
  found".
- Consumers of the rc: in the repo only test_exit_codes.zsh (its happy path stays 0);
  the plists have no KeepAlive/SuccessfulExit and the tool never reads LastExitStatus
  (mod_las:81 only checks presence) · estimate S (code) + a contract decision ·
  sensitive yes (`brew_manager.sh`) · (c): a Dashboard reading a JSON per-module state
  does not need it. Trigger → (b): the Dashboard must show the outcome of
  launchd-scheduled runs through LastExitStatus, or BM-17 (agent failure notification)
  is brought forward. Do it after 4b-1/4b-2.

### N1 + 4b-0 — startup without Homebrew on PATH; the built-in installer
- N1 (process area): `brew_manager.sh:186-235` runs BEFORE the `script(1)` re-exec
  (:245-285) and never checks DRY_RUN: with --dry-run on a Mac without brew it asks
  "Install Homebrew now?" with a bare `read -r _brew_install_choice` (:199, against the
  `_ask` convention; lib/common.sh is already sourced at :175), and a `y` runs `curl …
  install.sh | bash`; declining exits 0 ("cannot continue", :233).
- 4b-0 (return-contract verifier): the same path fires on a HEALTHY Mac when the run
  starts from launchd or a GUI. There is no PATH bootstrap (`/opt/homebrew/bin`,
  `/usr/local/bin`; `brew shellenv` only after an interactive install, :208-213);
  launchd gives jobs PATH=/usr/bin:/bin:/usr/sbin:/sbin, the plists set no
  EnvironmentVariables (mod_las:214-238, mod_bk:236-260), `launchctl getenv PATH` is
  empty, there is no /etc/zshenv or ~/.zshenv. Simulated: `env -i HOME=…
  PATH=/usr/bin:/bin:/usr/sbin:/sbin /bin/zsh farm/brew_manager.sh 8 --yes </dev/null`
  → rc 0, "Homebrew is not installed… cannot continue". Consequences: (1) the
  LaunchAgents installed by las/bk most likely NEVER run brew, and look successful; (2)
  README:188 ("the exit status reflects how the run ended … so launchd, scripts and CI
  can detect a failed start") is false for the most likely failed start; (3) a Dashboard
  launched from the Finder inherits the same minimal PATH → exit 0 with "not installed",
  and if it keeps stdin open it hangs on the `read` at :199. No brew-manager agent is
  installed on this Mac, so it was never observed live; memory, README and CHANGELOG
  never mention launchd's PATH.
- Risk MEDIUM · estimate S-M · sensitive yes (`brew_manager.sh`) · contract: the PATH
  bootstrap and the dry-run gate are PATCH; a non-zero exit on "cannot continue"
  corrects a violation of "0 = successful run". Verifier (process area): the declined
  installer path is not pinned by test_exit_codes.zsh (it pins 99→2, `8 --skip=8`→1,
  `--dryrun`→2, happy→0), so a non-zero exit is a conformity fix; a NEW dedicated code
  is additive (MINOR); reusing 1 is not MAJOR by the letter but semantically ambiguous.
  **User decision (2026-09-25): a NEW dedicated code for "environment precondition
  failed (Homebrew not found / installation declined)", added to the docs/04 contract →
  MINOR, the cleanup release becomes v1.5.0; the installer honours --dry-run and never
  starts without a terminal; the finding is confirmed under a REAL launchd job before
  being declared (a read-only agent `1 --dry-run`, installed and kickstarted by the
  user, its log checked, then removed).** (a) → branch 4, the first code branch.
- Tests: e2e in test_exit_codes.zsh with `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin`
  and the mock brew outside that PATH but in a probed prefix, plus a tripwire on curl:
  in dry-run the installer is never invoked; the exit is the new code.

## D. Guard-rail hardening

### #9 (residual) — flag values are not validated; `--only=` empty runs everything
- Status: open and wider than recorded ("--upgrade=yes silently degrades to n"): (i)
  `brew_manager.sh:124` accepts any `--upgrade=` value, which becomes `_ask`'s DEFAULT
  (mod_04:80); under --yes `_ask` returns 0 only for the default `y` (common.sh:428) →
  with `yes`, `Y` or `true` it prints `[auto: yes]` and then DECLINES (rc 1), and mod_04
  has no else branch: no message, exit 0 — the output says the opposite of what happens;
  (ii) `--upgrade=y` WITHOUT --yes pre-answers nothing (the interactive `_ask` ignores the
  default, common.sh:438-440; non-TTY declines) → README :181 ("Pass y to upgrade
  without interaction") and :166 are false without --yes; (iii) `--adopt=` accepts
  anything (:123); mod_00:182-189 warns at runtime ("'yes' is not a number — skipped"):
  safe and visible, exit 0; (iv) fail-open: an empty `--only=`/`--skip=` counts as
  absent (:149).
- Verifier: the most realistic case is positional + empty only — `go --only=` runs the
  WHOLE `go` sequence even on a TTY (the parser cannot tell `--only=` from an absent
  flag; `_resolve_cli go "" ""` → 0…13); a GUI building `go --only=$ids --yes` with
  empty ids runs everything, mod_05's cleanup included → an ONLY_SET marker is needed.
  Without a selection the menu opens; non-TTY → EOF → the default `go` (selection.sh:207);
  `--yes` without a selection = mod_05's cleanup (default y under --yes) followed by the
  N-HANG block.
- Risk MEDIUM (a destructive fail-open) · estimate M · sensitive yes (the
  `brew_manager.sh` parser, `lib/common.sh` `_ask`) · (a) → branch 7.
- Contract — PATCH only with this formulation (verifier-corrected): invalid
  `--upgrade=`/`--adopt=` values → exit 2 (the class of an unknown flag, already in the
  contract); an EMPTY `--only=` → exit 1 ("a selection that resolves to empty",
  consistent with the documented "keeps only the listed modules"), NOT 2; an EMPTY
  `--skip=` stays VALID ("remove nothing": rejecting it would break callers building
  `--skip=$LIST`, not a PATCH); the `--adopt=` validator mirrors mod_00's grammar exactly
  (numbers separated by commas AND spaces, duplicates allowed, an empty value; `--adopt="1
  2"` is announced in CHANGELOG 1.2.0; out-of-range indices stay a runtime warn+skip); a
  non-TTY run without a selection → exit 1 is a defensible PATCH only because the README
  declares piping the prompt unsupported (it is NOT true that no caller can depend on it:
  `print "" | ./brew_manager.sh --dry-run` runs `go` and exits 0) → note it in the
  CHANGELOG. NOT to do: accepting `yes`/`Y`/`true` as aliases (MINOR, in the mutating
  direction); letting `--upgrade=y` grant consent without --yes (it conflicts with the
  recorded consent decision [[2026-07-17-consent-vs-noninteractive]]) → align the README
  to the code instead. Writing "invalid value = unknown flag" into docs/04 is a rule
  change (Level 2) → ask.
- Fix: exact `case`s at the edge (exit 2 listing the accepted values); the ONLY_SET
  marker; non-TTY without a selection → `_err` + exit 1; `_ask` prints the actual
  decision and treats a default other than y/n as a programming error; README
  :166/:172/:181 rewritten (`--adopt`/`--upgrade` choose WHAT, consent comes only from
  --yes).
- Tests: test_exit_codes.zsh: `--upgrade=yes`→2, `--adopt=yes`→2, `go --only=`→1, `4
  --upgrade=y --dry-run`→0, `--yes` without a selection non-TTY → 1 within a watchdog;
  test_guardrails.zsh: `_ask` never prints "auto: yes" when it declines. Depends on
  N-HANG (the same non-interactive path).

### #11 — fixed, predictable /tmp paths
- Sites: mod_00:215/218 (`2>/tmp/brew_adopt_err.log`, then `tail -1` shown through
  `_warn`, i.e. echo -e), mod_01:96/100/105 (`brew doctor > /tmp/brew_doctor.log`, also
  under --dry-run), mod_02:96/100/112 (`brew update > /tmp/brew_update.log`). The cleanup
  at `brew_manager.sh:564-565` removes 5 paths, 2 of them DEAD (`brew_cleanup.log`,
  `brew_audit.log`: nobody writes them). The rm runs only in the child at a normal end:
  kills and every N-HANG block leak the files (the rm at :564 comes after `_handle_log`
  at :558). mktemp is used only for the log fallback (:71/:76) and the ANSI strip (:276).
- Risk: (1) security LOW on multi-user Macs (/private/tmp is drwxrwxrwt and macOS has no
  protected_symlinks: O_TRUNC follows a planted symlink; a pre-created 666 file lets
  another user read or inject output later shown through echo -e); (2) correctness with
  concurrent jobs (GUI + agents): one session's rm deletes another's
  `/tmp/brew_update.log` mid-mod_02 → "Database updated" instead of "already up to date",
  the "New Formulae" lost — a false state for the JSON layer.
- Estimate M · sensitive yes (`brew_manager.sh`, mod_00) · contract none (PATCH) · (a) →
  branch 13 (kept by the user: the Dashboard will show the log path).
- Fix: in the parent `BREW_MANAGER_TMP="$(mktemp -d)"` (macOS per-user $TMPDIR, 0700),
  exported to the child; the three modules write under it; the parent removes it after
  `script(1)`, also on an abnormal exit; the fixed rm list goes. Verifier:
  tests/test_dryrun_gates.zsh:29, :36-60 hold a workaround for the fixed path (it refuses
  symlinks, saves and restores `/tmp/brew_update.log`) to adapt or remove; since the test
  sources mod_02 directly, the modules need a fallback or a fail-fast when
  BREW_MANAGER_TMP is unset.
- Tests: e2e with TMPDIR in the sandbox: no `/tmp/brew_*.log` created or deleted
  (tripwire), the per-run dir removed at the end; a grep invariant: no literal `/tmp/`
  in `modules/`.

### 11-bis — the child recomputes LOG_FILE
- Status: new. `brew_manager.sh:79` computes `LOG_FILE=…/brew_report_$(date
  +%Y%m%d_%H%M%S).log` twice: in the parent (passed to `script -q` at :254, cleaned at
  :277-279) and again in the re-executed child (it is not exported, and :79 does not
  depend on RECORDING). Across a second boundary the child shows a different path in the
  banner (:307), the summary (:551) and `_handle_log`: "[3] Delete" removes a
  non-existent path and prints "Log deleted" while the real log stays (a false claim with
  a privacy impact); "[2] Open" opens a missing file. Real logs: 3 of 32 differ (e.g.
  file …225250.log, banner …225251.log).
- Verifier: in the fallback case (`logs/` missing or not writable) the mismatch is 100% —
  the child re-runs :67-79 and calls `mktemp -d` AGAIN (an empty orphan dir per run, the
  WARNING printed twice); two runs started in the same second produce ONE file (the first
  run's log is lost).
- Risk LOW (truth and privacy of the log; for the GUI a wrong log path ~1 in 10, and
  parallel jobs collide) · estimate S · sensitive yes (`brew_manager.sh`) · contract none
  (the `brew_report_*.log` pattern — mod_log:57, README :359/:493 — stays) · (a) → branch
  13 with #11.
- Fix: compute LOG_FILE and `_LOGS_DIR` only in the parent and hand them to the child
  through internal variables, validated against the passed value (not against the
  child's own `_LOGS_DIR`, which differs in the fallback); a unique name
  `brew_report_<ts>_$$.log`. The handoff relies on BREW_MANAGER_RECORDING, itself trusted
  from the environment (M1).
- Tests: e2e: the banner path equals the created file; two parallel runs → two files.

### M1 — handoff variables trusted from the environment on a fresh start
- With an inherited `BREW_MANAGER_RECORDING=1` the script skips the `script(1)` re-exec:
  no session log is written, but `_handle_log` says "Log kept at: <non-existent file>";
  `TUI_*` and NONINTERACTIVE are read from the environment. `BREW_MANAGER_SCRIPT_DIR` is
  accepted ALWAYS, even without RECORDING, and makes `lib/` and `modules/` load from
  another checkout (`brew_manager.sh:22-23`, :113-117, :251; lib/common.sh:61-67). Not a
  privilege boundary (whoever controls the environment owns ~/.zshenv and PATH).
- Risk INFO/LOW · (b): part of the GUI invocation contract (launch with a clean
  environment); related to #17 and 11-bis.

### #17 — `(( VAR ))` arithmetic on environment strings
- Status: open; the count is 27, not ~18: 22 on BREW_MANAGER_DRY_RUN in 9 files (18 `((
  … ))` + 4 negated `(( ! … ))` at mod_las:400/560/650/728; bk 7, las 6, log 2, mas 2,
  mod_00/02/04/05/10 one each) + 5 consent sites (`(( BREW_MANAGER_YES ))`/`((
  BREW_MANAGER_NONINTERACTIVE ))`, common.sh:426/434/461/469, mod_las:19) = 27 in 10
  files. `yes`/`true` turn the gate off; `Z=5` turns it on AND assigns Z; the negated
  sites are fail-open in the dangerous direction (a string is 0, `!0` runs the real
  action).
- Verifier: command substitution in a subscript IS executed when the name is an
  existing array (`BREW_MANAGER_DRY_RUN='path[$(print y > F)]'` creates F; `path` always
  exists, and the script has its own arrays) — the class reaches command execution, not
  only assignment (STATE #17's text must say so); 8 more sites on TUI_TTY/TUI_UNICODE
  (e.g. `brew_manager.sh:294`/:300, common.sh:157/203/259), taken raw from
  `BREW_MANAGER_TUI_*` in the child → a class of 35, reachable only with a stale
  RECORDING (M1). Not reachable today: the core overwrites DRY_RUN/YES/NONINTERACTIVE
  from the flags (`brew_manager.sh:151/163/164`) before sourcing `lib/` and `modules/`.
- Risk INFO today. For the GUI the environment variables are NOT an API:
  `BREW_MANAGER_DRY_RUN=1` without `--dry-run` gives a REAL run (README :573 calls them
  "the two safety flags"). Estimate S-M (a gate on 5 sensitive components) · contract
  none (a refactor, no bump; accepting the variable as an input would be MINOR — not
  advised) · proposed (a) last, verifier (c); **user decision: (c), deferrable ONLY while
  the GUI invocation contract (b) imposes a clean environment — if the GUI passes
  environment variables, #17 returns to (a).** A lighter option for (b): add
  `_is_dry_run`/`_is_yes`/`_is_noninteractive` and make them mandatory for new code (the
  new-component template), without converting the 27 sites.
- Fix when done: predicates in lib/common.sh (`[[ "$BREW_MANAGER_DRY_RUN" == 1 ]]`), the
  27 (35) sites converted, README :573 (the variables are set only through the flags); a
  grep invariant "no `(( BREW_MANAGER_` in lib/ and modules/" with anti-vacuity.

### #3b — echo on data (the class)
- Status: wider than recorded (mod_05 dry-run + `_restore_agents`): mod_05 in the dry-run
  branch (:41, :45, :48, :55) AND on the real path (:83, :87-88 → `_item`, :93-94 `echo
  -e`); the five renderers `_ok/_warn/_err/_info/_item` are `echo -e "$msg"`
  (lib/common.sh:273-277), with 59 calls interpolating data; 37–39 `echo -e` lines with
  non-palette variables (mod_01:106, mod_04:86, mod_bk:329/350/449/475/505,
  mod_las:786-794, mas:55/134, `_ask`/`_read_choice` :427-470 including the --adopt
  override); 74 `echo "$var" |` sites in 14 files, all in `modules/` (00 3, 02 1, 03 4,
  04 6, 05 6, 07 4, 08 1, 09 2, 11 4, 12 6, bk 14, las 11, log 2, mas 10), mostly for
  grep/counting — but mod_00:53/70 validate the cask token on the ALREADY-expanded value;
  unlisted sites bk [5] View (:583-585) and las [v] (:785-794); mod_02:88 and mas:46
  DEPEND on the expansion (a palette inside `_item`); cosmetic: mod_12:32 prints
  `\'brew install\'` literally. zsh's builtin echo expands escapes even without -e (`echo
  'a\x41\065b\ec'` → `aA5b<ESC>c`).
- Risk LOW (terminal control sequences injected from brew output or file/app names; the
  adoption prompt mod_00:208 interpolates app_name through echo -e, but `_box` uses
  printf %s, so the shown command stays truthful). For the GUI no direct risk IF the JSON
  layer does not reuse these helpers · estimate L · sensitive yes (common.sh, mod_05,
  mod_00, bk, las) · contract none · (c) for the class; **user condition: deferrable ONLY
  if the JSON layer is built from structured data, never from the modules' screen
  output**; prevention = IMP-003 (branch 2); the bk-restore half (3b-bk) is (a) in branch
  11; N2 is (a).
- Fix when done: helpers `printf '  %b%s%b  %s\n' "$C" "$SYM" "$NC" "$msg"`;
  mod_02:88/mas:46 adapted (the colour outside the message, or an `_item_cmd` helper);
  `echo "$x" |` → `printf '%s\n' "$x" |`; an anti-echo-on-data invariant with a
  bidirectional allow-list (IMP-009).

### 3b-bk — echo on data in `_restore_agents`
- The real restore passes bundle data through `echo` (mod_bk:161-163 `echo "$_data" | tr
  …`, :189, :196-202 `echo "$_schedule"`) BEFORE validation; the preview (:135-137) uses
  `printf '%s\n'`. With the label `my\x2eagent` the preview shows `my\x2eagent` and the
  restore creates `my.agent`; `\x7c` fabricates a `|` and extra fields; the conf is
  written with the expanded schedule (:272). Verifier: a literal `\n` becomes a real
  newline → extra lines/fields (`schedule=`/`modules=`), and a multi-line `_schedule` in
  the conf written at :268-276 can inject keys; contained today (las derives the plist
  path from the label, not from `plist=` — mod_las:74, :308, :383 — and the modules are
  revalidated).
- Risk LOW · estimate S · sensitive yes (bk) · (a) inside branch 11 (one parser for the
  preview and the restore).
- Tests: a helper unit test — a line with `\x2e`/`\x7c`/`\e`/`\n` yields identical fields
  in the preview and the restore, bytes kept literal.

### #10 — `_ask` "(y/N)" and "Runs only after confirmation"
- Not a debt. (a) The interactive "(y/N)" is TRUE: `_ask` ignores the default and needs
  an explicit `y`, Enter = No (common.sh:438-440), by choice (commented in mod_05:69-70,
  "Enter aborts"); `[auto: y]` under --yes and `[non-interactive: no]` are true. (b) "Runs
  only after confirmation" was already fixed in 2fcb1f8 (BM-02): mod_05:20 says
  "(auto-confirmed in --yes runs)" and README :268 agrees. The only real residue
  (`[auto: <raw default>]` for a default other than y/n) goes into #9. The real GUI gap is
  different: consent is all-or-nothing (--yes) and there are no flags for default-n
  actions (bk restore :441/469/488, mod_10 greedy :119, mas :50/129), so they cannot be
  triggered headless — a design topic (BM-16) → (b). Closed in memory at branch 1.

### #5b — VERSION and tag aligned
- A permanent rule, already mechanised (`make version-check` green: VERSION 1.4.0 = tag
  v1.4.0). Notes: `make check` does not include version-check (Makefile:26-29) and
  integrate.md mentions neither VERSION nor version-check. Moved from Caution to
  Decisions at branch 1; applied at the v1.5.0 release. A possible IMP (Level 2): the
  release variant of /integrate runs `make version-check` after the bump.

## E. Process, documentation, memory

### #7 — the one-off gitleaks scan of the pre-existing history
- Done read-only during the inventory: gitleaks 8.30.1, default rules (no
  `.gitleaks.toml`/`.gitleaksignore`): `--log-opts="--all"` 121 commits (every non-merge
  commit on every ref), `--all --first-parent -m` 33, `--all -m` 152 = `git rev-list
  --all --count` (every merge diffed against every parent) → 0 findings; `gitleaks dir
  .` → 0; `git ls-remote origin` lists exactly the local refs (main, dev, 6 tags).
  Re-run and recorded at branch 1, plus a Level-1 fix of docs/03.
- Estimate S · sensitive no · (a) → branch 1.

### #19 / IMP-022 — `lib/selection.sh` missing from the sensitive lists
- The selection parsing (`_resolve_selection`, `_resolve_cli`, `_collect_module_tokens`,
  `_selection_is_valid`) and the registries (MODULE_IDS/DESC/NAME/RISK/DRYRUN) live
  there; docs/03 still attributes "input parsing" to `brew_manager.sh` (verifier: the
  FLAG parsing does stay in `brew_manager.sh`, :119-141, exit 2 at :135 → reword:
  `brew_manager.sh` = dispatch, flag parsing, --yes; `lib/selection.sh` = the selection
  resolver + the registries). Sites: CLAUDE.md rule 8 and the technical rules; docs/03;
  docs/00:80; the 2026-07-12 decision; STATE decisions; INDEX.md:148-149 ("six
  components"); new-component.md step 6 (it lists only CLAUDE.md rule 8 and docs/03).
  SECURITY.md:31-36 already covers it ("plus the shared dispatch/guard-rail code");
  tests/test_risk_badges.zsh needs no change (selection.sh is not a module).
- Risk MEDIUM (process: the resolver already produced 2 MEDIUM fail-opens in BM-08b,
  one of them the `\065`→mod_05 bypass; #15/#16 flip `MODULE_DRYRUN` there) · estimate S · sensitive: it
  changes the list itself (author-verifies with a grep DoD and a counter-proof) · (a),
  approved 2026-09-25 → branch 1, FIRST.
- Forward note (b): the Dashboard's machine-readable layer (JSON or a client-facing CLI)
  will fall under docs/03's "any surface that performs actions on behalf of a client":
  the improvement's first task adds it to the lists by the same mechanism.

### #20 / D10 — the .gitignore template patterns
- `.vault-token`, `vault-keys.json` (the secrets block) and `*.iml` are missing; nothing
  of the kind is tracked (`git ls-files` empty); `.vault-token`/`vault-keys.json` are
  ignored by nothing; `*.iml`/`*.log` are ignored on this Mac only by the user's GLOBAL
  gitignore. `*.log` stays out (decision D10). Out of scope but noted: the
  `/tmp/brew_*.log` patterns (.gitignore:53-59) have no effect (paths outside the repo),
  and the "Do NOT ignore" comment does not mention selection.sh/VERSION/tests.
- Estimate S · (a) → branch 3. DoD: `git check-ignore -v` of the three names points to
  the repo's `.gitignore`.

### README (product) — the registered drift plus a full re-read against the code
- R1 "Adding a new module" (:556-569): (a) "three entries" — `MODULE_DRYRUN` is a 4th
  mandatory registry (and a `0` also needs `_KNOWN_UNGATED`); (b) the key-set/count pin of
  test_menu_registry.zsh:75-82 is not mentioned; (c) `_module_NN()` without "no
  zero-padding" and without the 14-shadowing warning; (d) "Done — … pick it up
  automatically" (:561) is false: hand-written lists at `brew_manager.sh:336` ("Valid
  modules: 0-13"), :363 (the 0→13 hint) and mod_las:188 (new-component.md:43-45 lists
  them, the README does not); (e) "(any number is fine internally)" (:565) is the #18
  trap; (f) `MODULE_DRYRUN` and `_collect_module_tokens` are missing.
- R2 "Project structure" (:462-512): `lib/selection.sh` and `tests/` missing. R2b:
  `brew_report_*.log ← one per interactive session` (:493) is false (one per run,
  `brew_manager.sh:79/253`; it contradicts :359). R3: the documented prompt text
  (:151-153) is stale vs the real "Choice [go / numbers / name, default: go]"
  (`brew_manager.sh:392`). R4: "The run is then non-interactive" (:130) and "--skip=5 …
  unattended" (:172) are false on a terminal — a CLI selection skips only the MENU,
  `_ask` still reads the tty; only no tty (fail-closed) or --yes make a run unattended
  (fix the DOC: making the CLI selection non-interactive in code would change the
  selection/flag semantics — a MAJOR risk). R5: the summary example (:99-107) shows
  module 5 "preview (--dry-run)" with "freed ~1.7G" — impossible (the dry-run measures
  but does not clean, mod_05:27; the summary re-measures, `brew_manager.sh:524-538` →
  "(unchanged)"). R6: las [c] (:120) "deletes the agent activity log" — also every
  `logs/agent_*.log`. R7: "a dry run never modifies anything" (:179, :122) — false for
  the installer (N1) and, imprecisely, for mod_01's /tmp write. R8: "The exit status
  reflects how the run ended" (:188) holds only for startup (#4b, 4b-0). R9: mod_03
  "single fast call — no per-package queries" (:249) is false (N2). R10 (verifier: form
  only): "Python 3 … pre-installed" (:39) — the Command Line Tools required by Homebrew
  provide it; but :26 "requires nothing beyond what macOS already has" contradicts the
  Requirements table.
- R11 (:573): "`_ask`/`_read_choice` … implement both flags for you" — FALSE for DRY_RUN
  (the helpers handle only YES and NONINTERACTIVE; every module must gate itself) — it
  would lead M4 authors to skip the gate. R12 (:91): "Before a `[!]` action actually
  runs, … a framed danger box … then asks you to confirm" — false for las (`[las]=danger`,
  no `_ask`/`_ask_danger`, [c] deletes without confirmation). R13 (:200): the standard
  modules have "no persistent side effects beyond what you explicitly confirm" — false
  for mod_02's `brew update` (no confirmation) and for brew's auto-update on `outdated`
  outside dry-run. M3 (:573): only DRY_RUN and YES are listed as "the two safety flags",
  NONINTERACTIVE (the BM-08c fail-closed, the las:19 early-exit pattern) is omitted, and
  "never read input directly" is violated by the code itself (log.sh:21, mod_bk:318,
  mod_log:89). 4b-readme: :111 "✓ The module ran to completion" (also for failed,
  skipped or declined modules). Also :390 and :417 are false (#6b, #12), and :98-121
  becomes false with #15/#16.
- Verified TRUE and to keep: the flag table vs the parser (:119-141); 99→exit 2; the
  badge table vs MODULE_RISK (selection.sh:133-138); the bk options (mod_bk:290-316) and
  the las options (mod_las:274-296); go=0..13; the ASCII degradation; the --yes defaults
  (mod_05 y; mod_10/mas/bk n); the lenient/strict resolver. Module cards 1, 6, 7, 11, 12
  were only sampled.
- Risk MEDIUM for the Dashboard (designed on this description of the contract), HIGH for
  the M4 modules (R1 leads straight into #18) · estimate M · sensitive no · contract none
  (it describes the contract; R8 adds the limit without redefining the codes pinned by
  test_exit_codes.zsh) · (a) → branch 15, LAST: every fix branch updates its own section
  (rule 5), this branch fixes the residue (R2, R2b, R3, R4, R5, R10, R11–R13, M3) and does
  a claim-by-claim final check.

### SECURITY.md — footprint and network under-stated
- :18 "It reads and writes only within its own directory (logs/, backups/, agents/)" is
  false (plists in `~/Library/LaunchAgents`, fixed /tmp paths); :20-23 "The only network
  activity…" omits `brew install mas` (mas:50), `brew bundle` on restore, `brew install
  --cask --adopt` (mod_00), `brew upgrade --cask --greedy` (mod_10) and brew's implicit
  auto-update outside dry-run. Verifier: :25 "No data is sent to M2NDLAB or any third
  party" — Homebrew's analytics are on by default (no HOMEBREW_NO_ANALYTICS) on the
  installs/bundle/upgrades the tool runs, and mas talks to Apple → limit it to
  "brew-manager itself"; :73 ("writes … outside the script's directory") contradicts the
  legitimate use of LaunchAgents.
- Risk LOW-MEDIUM · S · (a) → branch 15.

### STATE-DEC-README — the "managed with Claude Code" note
- Open since the graft (STATE decisions: "README not modified at the graft: the note
  remains an open option"). README :516 already cites the tooling (CLAUDE.md, `.claude/`,
  Makefile, `scripts/`), so it is partly superseded. Decide yes/no, or close it as
  superseded, in branch 15.

### N2 — mod_03 corrupts brew's JSON through echo
- mod_03_packages.sh:82 runs `echo "$_formula_json" | python3 …json.load`: zsh's echo
  turns `\n` inside JSON strings (e.g. caveats) into real control characters → json.load
  fails, the error goes to `2>/dev/null`, and EVERY formula falls back to `brew info
  <f>` (:93-95); the 384 KB payload is also re-parsed once per formula. Reproduced on
  this Mac: `brew info --json=v2 --installed` (384439 bytes, valid) through `echo` →
  "JSONDecodeError: Invalid control character at: line 4958 column 46"; through `printf
  '%s'` → valid.
- Risk MEDIUM (a silent slowdown and a swallowed error, docs/02; and the proof that echo
  breaks JSON — any JSON layer built with echo would be corrupt or injectable) ·
  estimate S · sensitive no · contract none (PATCH) · (a) → branch 8, the first
  application of IMP-003.
- Fix: `printf '%s'`, one python invocation emitting name→desc for every formula, then a
  lookup; a parse failure is reported (`_warn`, detail in the log), not swallowed. Test:
  a mock brew and a JSON fixture with `\n` in a string — the description comes from the
  JSON path with no fallback (a tripwire on the mock's `brew info <f>`).

### Project IMPs (OPEN in LEARNINGS)
- IMP-002 (a checklist of the contract surface for extraction/parity tests: rc/exit for
  EVERY outcome, input classes with their edges, side-effect multiplicity, a mutation
  check) — docs/02 has nothing of the kind; targets: docs/02 "Tests that demonstrate"
  (hybrid) or the CLAUDE.md Tests rule (project section, cheaper at upgrades). S.
  Approved, also `Destination: framework` → branch 2.
- IMP-003 (never echo on DATA) — not in CLAUDE.md; N2 is a live instance; the #3b scope
  is 74 sites. S. Approved → branch 2 (the class clean-up stays (c), with the user's
  condition).
- IMP-004 (closing a CLASS: grep every site and enumerate them; "what does it now
  AUTHORISE?" for guard-rail fixes; a re-gate after a substantive fix on shared
  sensitive code) — docs/03 speaks only of by-convention prevention. S. Approved, also
  `Destination: framework` → branch 2 (before the class fixes).
- IMP-005 (terminal control output gated on TUI_TTY) — the code already complies
  (`_clear` common.sh:259; the spinner on TUI_TTY since BM-12; no raw
  clear/tput/`\r` in the modules); only the convention line is missing. S. **Cut by the
  user** → (c).
- IMP-007 (module smoke = positional CLI selection + output redirected to a file; never a
  pipe on the prompt, never `head`) — left out on purpose by the upgrade; CLAUDE.md:130
  and new-component.md:56 stay ambiguous. S. Approved → branch 2.
- The 15 framework-destination IMPs (006, 008–021) are outside this cleanup; IMP-008
  (verify claims, not only actions) and IMP-010 (the breadth of a claim) are the most
  relevant to "the JSON layer cannot report false states" — applying them locally before
  the JSON layer is the user's call.

### (i) The harvest map (brew IMP → framework IMP)
- The 2026-09-24 `/harvest-framework` printed 15 entries (IMP-006, 008–021, "was IMP-nnn
  in this project"); the event is recorded nowhere in memory, and nothing marks them as
  carried upstream: the command's default perimeter covers every marked entry in every
  section (harvest-framework.md:31-32), so the next harvest would pick them again unless
  run with a filter. The marker grep returns 18 lines = 15 entries + 3 header/format
  lines; the DoD pattern `^- (Destination|Destinazione): framework$` counts 15.
- Proposed format: in each entry, right after the Destination line, one physical line
  `- Harvested: framework IMP-0nn (2026-09-24)` (English; it does not contain
  "Destination: framework", so the marker count stays 15); a sentence in brew's own
  LEARNINGS header paragraph (not the template lines) saying entries with `Harvested:`
  are already upstream and the next harvest runs with the filter "only entries without a
  Harvested line"; a session note with the brew→framework table and a STATE line (the
  audit trail). Discarded: a table in the header (it touches template lines and does not
  travel with the entry). The local command is not changed (a behaviour change is Level
  2; the verifier corrected the rationale — in brew harvest-framework.md is a CUSTOMISED
  hybrid command, carried forward at upgrades, not overwritten); a new framework IMP
  could make /harvest-framework skip `Harvested:` entries by default. Lifecycle: the 15
  stay OPEN (a harvest is not a decision); at the next /retro the pure-framework ones
  (IMP-012…021) can move to Deferred with the trigger "a framework upgrade that applies
  IMP-nnn". DoD grep with a counter-proof (15 Destination, 15 Harvested, exactly one per
  id).
- **User decision: branch 14 ON HOLD until the framework numbers AND the format arrive
  from the other chat.**

### (ii) Decisions left open by the upgrade
- D10 = #20 (branch 3). D2, "stale content deferred to a dedicated branch" = the README
  drift (branch 15). The two `.bak` hooks STATE mentions were already removed by the
  user (memory drift). The IMP-007 smoke sentence and the mktemp prescription (#11) were
  excluded on purpose and are tracked in their items.

### Memory drift (Level 1, fixed at branch 1's checkpoint)
- STATE: the frontmatter and "Active branches" still showed
  `chore/checkpoint-post-fw-v1.2.0` as ready, though merged in 8ed9f5c and pushed; the
  `.bak` hooks no longer exist; #3 cites `brew_manager.sh:152` (now :160); the #3b
  scope; the #4/#4b cause; #10 closure; the #12 claim; the #6b/#13/#16/#17/#18
  corrections; #5b to Decisions.
- components/lib-selection.md says 74 checks (now 87); mod-las-scheduler.md "in Modify
  the conf is deleted BEFORE reinstalling" is false (mod_las:396-398 does not delete;
  `_save_agent_config` overwrites only on success); mod-bk-brewfile.md presents the
  weekday bug #2 as open (closed in BM-05a, mod_bk:203-209) and says "[3a] asks NO
  confirmation" (false: `_ask_danger`, :486-489); lib-common.md gives N-HANG a false
  cause.

## Classification after the user's decisions (2026-09-25)
- (a) close now: #15, #16, #14, #3, #6b, #12, #13, N-bk-NI, N-las-recreate, N-bk-1 (moved
  by the user), #18, N-HANG, N1+4b-0, #9, #11, 11-bis, 3b-bk, #7, #19/IMP-022, #20, the
  README (R1–R13, M3), SECURITY.md, STATE-DEC-README, N2, IMP-002/003/004/007, the
  harvest map (on hold), the memory drift, #10 and #5b (memory only).
- (b) first task of the improvement: 4b-1 + 4b-2 (with #4, the "unmeasured" counters,
  M2 below), 4b-3 only if its trigger fires, M1 (the invocation contract), the JSON layer
  into the sensitive lists, headless consent for default-n actions (BM-16), `--adopt` by
  a stable key instead of a position, per-action entry points for bk/las/log, agents with
  flags (a `modules=` extension, MINOR), the `_is_*` predicates for new code.
- (c) defer: 4b-3, #17 (conditioned), the #3b class (conditioned), #6, IMP-005.
- M2 (found by the guard-rails verifier): even after the N-HANG fix, an agent scheduled
  on `bk` or `log` does NOTHING (the non-interactive menu takes the default n) and
  reports done; the scheduler accepts bk/log/las/mas as an agent selection and even
  suggests them in its error message (mod_las:186-188); `las` is an intended no-op (:19).
  To decide: refuse interactive-only modules in `_install_agent` and in the bk restore,
  or document it (touches mod_las/mod_bk → gate) → (b) with 4b-2.
- Order and grouping → [[plans/debt-cleanup-pre-dashboard]]; decisions →
  [[decisions/2026-09-25-debt-cleanup-pre-dashboard]].

## Release assessment
The fixes are PATCH; #18 is a refactor (plus a visible header fix); chore/docs carry no
tag; nothing touches the frozen ids, the flag names or the plist format → no MAJOR. The
one MINOR is the NEW exit code for the environment precondition (N1) → the cleanup
release is **v1.5.0**, with Known limitations: #4b until the improvement, #17 and #3b
with their conditions, #6. Watch-points: the #9 formulation above; the #13 refusal noted
in the CHANGELOG; 4b-3 (deferred) MINOR with a new code outside 1–31; the JSON layer (the
improvement) a new public surface → MINOR and an entry in the docs/04 contract list.

## GUI design topics surfaced (for the improvement, not debts)
1. Consent is all-or-nothing in non-interactive runs; default-n actions (bk restore,
   mod_10 greedy, mas upgrade) cannot be triggered headless (BM-16).
2. `--adopt=1,2` is positional in the scan of the moment: indices can shift between the
   GUI listing and the run (TOCTOU — under --yes the wrong app would be adopted) →
   address items by a stable key (cask or bundle id).
3. Until N-HANG and #9 are closed the invocation contract must be: stdin always
   /dev/null, an explicit selection, flags and never environment variables.
4. The bk/las/log menus use bare reads and cannot be driven non-interactively →
   per-action entry points (a feat, MINOR).

## Proposals
- None registered in this read-only phase; candidate IMPs are noted in the items (e.g.
  /integrate's release variant running `make version-check`; /harvest-framework skipping
  `Harvested:` entries).

## Links
[[STATE]] · [[LEARNINGS]] · [[decisions/2026-09-25-debt-cleanup-pre-dashboard]] ·
[[plans/debt-cleanup-pre-dashboard]] ·
[[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] · [[mod-bk-brewfile]] ·
[[mod-las-scheduler]] · [[lib-common]] · [[lib-selection]] · [[core-brew-manager]]
