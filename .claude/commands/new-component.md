---
description: Scaffold a new brew-manager module according to the project's conventions
---
Create a new module named $ARGUMENTS following the project's conventions EXACTLY (a
"component" in brew-manager IS a module; see also the
"Project-specific technical rules" in CLAUDE.md).

1. Read the project's technical rules (CLAUDE.md) and the note of the most similar
   module in .claude/memory/components/ to replicate its structure and conventions.
2. Create `modules/mod_NN_slug.sh` (numeric, NN two-digit zero-padded, the next free
   number) or `modules/mod_<alias>_slug.sh` (a special module invoked by name). The
   file is loaded automatically by the `mod_*.sh` glob: no loading registration.
3. Define the `_module_NN` function (number WITHOUT zero-padding, e.g. `_module_5`)
   or `_module_<alias>` (today only `log` uses it: bk/las/mas are `_module_14`,
   `_module_15` and `_module_16`, so a new module 14 would be shadowed by bk — fix
   that collision first, see STATE.md). Standard internal structure:
   - opening with `_section "NN" "Title"`;
   - an "About this module" block in plain language BEFORE any action (what it does,
     what it checks, what it may modify), with `_about_risk "<id>"` (from
     `lib/selection.sh`) for its risk line;
   - output ONLY through the `lib/common.sh` utilities (`_ok`, `_warn`, `_err`,
     `_info`, `_item`); confirmations ONLY via `_ask`/`_read_choice`;
   - **every mutating action gated by `BREW_MANAGER_DRY_RUN` and compatible with
     `BREW_MANAGER_YES`** (safe default = do not act). A non-negotiable rule: it is
     the project's historical class of defects (see STATE.md);
   - any temporary files in `/tmp/brew_*.log` (the main script removes only the
     files listed in its final `rm -f`: add yours there; fixed /tmp paths are a
     known debt, see STATE.md), shared state for the summary in UPPERCASE global
     variables.
4. Register the module in the registries of `lib/selection.sh` (`brew_manager.sh`
   only consumes them):
   - an entry in `MODULE_DESC` (MANDATORY: without it the module cannot be selected)
     and, in the same commit, in `MODULE_NAME` (short menu name), `MODULE_RISK`
     (`ro`/`write`/`danger` badge) and `MODULE_DRYRUN` (1 only if a `--dry-run` run
     changes nothing; a 0 must also be listed in `_KNOWN_UNGATED` of
     `tests/test_run_summary.zsh`) — the tests keep all four in lockstep with
     `MODULE_DESC`;
   - if it must run in the `go` sequence: add the number to `MODULE_IDS`;
   - `tests/test_menu_registry.zsh` pins the `MODULE_DESC` key set (every module)
     and the `MODULE_IDS` count (numbered modules): update it too;
   - the rows of the numbered modules are rendered from the registries
     (`_menu_row` over `MODULE_IDS`): no dedicated printf;
   - the module lists written by hand: the "Valid modules" error of
     `brew_manager.sh`, the `0→13` hint of the menu section and the "module ids
     0-13" hint of `modules/mod_las_scheduler.sh`;
   - for the special modules only: in `lib/selection.sh` a whole-token arm in the
     `_resolve_selection` case AND the name in the lowercase-special checks of both
     `_resolve_selection` (comma lists) and `_collect_module_tokens`
     (`--only`/`--skip`); the name in the `for tid in log bk las mas` menu loop; a
     branch in the dispatch case of `brew_manager.sh` (alias → function).
5. Minimal verification:
   - `zsh -n` on every touched file;
   - `make test` (the registry tests fail if a registry entry of step 4 is missing;
     the special-module wiring — resolver checks, menu loop, dispatch — is not
     covered by tests: the CLI smoke below checks the resolver and the dispatch, the
     menu loop is checked by the user from a real terminal);
   - smoke run with the new module selected on the CLI, stdin from `/dev/null` and the
     output in a per-run file, filtered afterwards (the command and its caveats are in
     the Tests rule of CLAUDE.md; never input piped into the prompt, never `| head`):
     it must start, end, and NOT perform mutating actions; ask the user to confirm
     from a real terminal that its row shows up in the menu;
   - if the module is mutating: check that with the default answer to the prompts it
     changes nothing.
6. If the module falls under the sensitivity criteria (it removes files/packages,
   installs, creates launchd persistence — see docs/03): add it to EVERY list of
   sensitive components — CLAUDE.md (rule 8 and the technical rules), docs/03,
   docs/00 (the end-of-deliverable cycle) and the decision note
   `.claude/memory/decisions/2026-07-12-componenti-sensibili.md`; its first merge
   goes through the security gate.
7. Update the documentation: the module's card in the "Modules" section of README.md
   (rule 5).
8. Create the note in .claude/memory/components/<module>.md and update INDEX.md,
   STATE.md, TREE.md (via /checkpoint).
