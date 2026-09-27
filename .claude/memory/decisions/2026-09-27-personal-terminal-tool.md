---
type: decision
updated: 2026-09-27
tags: [decision, scope, dashboard, release, contract]
---
# brew-manager becomes a personal terminal tool: no Dashboard; bk, las, log and mas go

- **Context**: the debt cleanup of [[plans/debt-cleanup-pre-dashboard]] was preparing a
  macOS Dashboard (a GUI client of brew-manager) and new Homebrew functions
  ([[2026-09-25-debt-cleanup-pre-dashboard]]). On 2026-09-27, during branch 4
  (`fix/startup-brew-env`: the Homebrew PATH bootstrap, exit 69, the installer only at a
  terminal), with the code, the tests and the security gate done and the real-launchd
  regression (task 6) about to be run, the user changed the scope.
- **Decision** (the user's, 2026-09-27):
  - brew-manager becomes a **personal terminal tool for the maintenance of the user's
    Mac**. **No Dashboard.**
  - The modules **bk** (Brewfile backup/restore), **las** (LaunchAgent scheduler), the
    **log** module (log manager) and **mas** (Mac App Store) will be **removed** — as
    **version 2.0.0**, in a later task.
  - For branch 4: **the PATH fix stays** — it is done, tested and through the gate, and
    it keeps the tool working when it is started outside a login shell. **The
    real-launchd regression (task 6) is dropped**: it verified the fix for scheduled
    agents, which will be removed. The user did not run blocks A and B.
  - **STATE #21** (bk/log runs hang without a terminal): the nature of the hang (an idle
    block or a CPU-consuming loop) is recorded in STATE #21 from the adversarial check of
    the same day; the debt will be resolved by the removal of bk and log. This supersedes
    the choice made earlier that day (accept it as debt and move branch 6,
    `fix/headless-prompts`, before #18).
- **Discarded alternatives**: keep the Dashboard plan (the user decided against it); run
  task 6 anyway (it would verify a surface that is being removed).
- **Consequences** — recorded here, NOT decided here (each is the user's call, in the
  2.0.0 task or before it):
  - Removing modules changes the frozen module identifiers of the public contract
    (docs/04: `bk`/`las`/`log`/`mas` are frozen names) → a MAJOR, hence 2.0.0. The
    LaunchAgents already installed on the Mac run `brew_manager.sh` with a selection;
    what happens to them when las goes (uninstall first, or an explicit error) is part
    of that task.
  - The pre-Dashboard programme needs a re-plan: many of its branches and STATE entries
    concern only the removed modules or the GUI (#6, #6b, #12, #13, #14's bk/las
    entries, #15, #16, #22, #24, #27, `lib/agents.sh`, the GUI invocation contract of
    #17/#28, the JSON-layer condition of #3b, the Dashboard trigger of #4b), while
    others stay (#9 flag values, #11/#25 per-run paths, #26 mod_03 JSON, #3b in the
    remaining modules). #18 (the `_module_14` collision) disappears with bk/las/mas.
  - Part of #21 survives the removal: `_handle_log` (lib/log.sh:21), the prompt at the
    end of EVERY session, is not the log module; it ignores `--yes`, so a terminal run
    with `--yes` stops there, and a run whose stdin is an open pipe waits there.
  - The release that ships branch 4: docs/04 and the CHANGELOG say exit 69 was "added in
    v1.5.0"; whether a v1.5.0 is cut before 2.0.0, or branch 4 ships inside 2.0.0, is
    open.
