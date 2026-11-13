---
description: Scaffold a new brew-manager module according to the project's conventions - run by the user only
disable-model-invocation: true
---
Create a new module named $ARGUMENTS following the project's conventions EXACTLY (a
"component" in brew-manager IS a module; see also the
"Project-specific technical rules" in CLAUDE.md).

1. Read the project's technical rules (CLAUDE.md) and the note of the most similar
   module in .claude/memory/components/ to replicate its structure and conventions.
2. Create `modules/mod_NN_slug.sh` (numeric, NN two-digit zero-padded, the next free
   number — never a retired id: `10`, `bk`, `las`, `log` and `mas` stay reserved for
   good, CLAUDE.md's answer **Public contract**; every module is numbered). The
   file is loaded automatically by the `mod_*.sh` glob: no loading registration. No
   production artefact: the module file ships with the repository, distributed via
   `git clone` (CLAUDE.md's answer **Production artifact**).
3. Define the `_module_N` function (number WITHOUT zero-padding, e.g. `_module_5`),
   at the start of a line in the module's file — the form the wiring test looks for.
   Standard internal structure:
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
     `MODULE_DESC`, both ways (an entry with no `MODULE_DESC` key fails too);
   - add the number to `MODULE_IDS`: it is the `go` sequence and the only list the
     menu draws, so every module is in it (`tests/test_menu_registry.zsh` fails on a
     registered id outside it, on a `MODULE_IDS` id nobody registered, on a registered
     id whose file has no `_module_N` function, and on a module file nobody
     registered);
   - `tests/test_menu_registry.zsh` pins the `MODULE_DESC` key set and the
     `MODULE_IDS` count: update both, on purpose — the ids are a public contract;
   - the menu rows, the range in the menu's header and the "Valid modules" error of
     `brew_manager.sh` are rendered from the registries: no module list to update by
     hand, no dedicated printf.
5. Minimal verification:
   - `zsh -n` on every touched file;
   - `make test` (the registry and wiring tests fail if an entry of step 4 is
     missing; the suite's menu check renders the menu at a pseudo-terminal, its text
     only);
   - smoke run with the new module selected on the CLI, stdin from `/dev/null` and the
     output in a per-run file, filtered afterwards (the command and its caveats are in
     the Tests rule of CLAUDE.md; never input piped into the prompt, never `| head`):
     it must start, end, and NOT perform mutating actions; ask the user to confirm
     from a real terminal that its row shows up in the menu;
   - if the module is mutating: check that with the default answer to the prompts it
     changes nothing.
6. If the module has a gated path (it deletes, installs, modifies Homebrew's
   configuration or decides what runs): add the path, with the file that holds it, to
   CLAUDE.md's answer **Sensitive components**, and amend the decision note
   `.claude/memory/decisions/2026-07-12-componenti-sensibili.md`; its first merge goes
   through the gate (`/fw:security-review`).
7. Update the documentation: the module's card in the "Modules" section of README.md
   (rule 5).
8. Create the note in .claude/memory/components/<module>.md and update INDEX.md,
   STATE.md, TREE.md (via /fw:checkpoint).
