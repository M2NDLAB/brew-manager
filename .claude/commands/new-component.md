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
   or `_module_<alias>`. Standard internal structure:
   - opening with `_section "NN" "Title"`;
   - an "About this module" block in plain language BEFORE any action (what it does,
     what it checks, what it may modify);
   - output ONLY through the `lib/common.sh` utilities (`_ok`, `_warn`, `_err`,
     `_info`, `_item`); confirmations ONLY via `_ask`/`_read_choice`;
   - **every mutating action gated by `BREW_MANAGER_DRY_RUN` and compatible with
     `BREW_MANAGER_YES`** (safe default = do not act). A non-negotiable rule: it is
     the project's historical class of defects (see STATE.md);
   - any temporary files in `/tmp/brew_*.log` (they are cleaned up by the main
     script), shared state for the summary in UPPERCASE global variables.
4. Register the module in `brew_manager.sh`:
   - an entry in `MODULE_DESC` (MANDATORY: without it the module cannot be selected);
   - if it must run in the `go` sequence: add the number to `MODULE_IDS`;
   - a print line in the menu (for the special ones: a dedicated printf after
     `_hline`);
   - for the special modules only: an alias in the input-parsing case and a branch in
     the dispatch case (alias → function).
5. Minimal verification (there is no test suite):
   - `zsh -n` on every touched file;
   - smoke run `./brew_manager.sh --dry-run` selecting the new module: it must show
     up in the menu, start, and NOT perform mutating actions;
   - if the module is mutating: check that with the default answer to the prompts it
     changes nothing.
6. If the module falls under the sensitivity criteria (it removes files/packages,
   installs, creates launchd persistence — see docs/03): add it to the list of
   sensitive components in CLAUDE.md (rule 8) and in docs/03; its first merge goes
   through the security gate.
7. Update the documentation: the module's card in the "Modules" section of README.md
   (rule 5).
8. Create the note in .claude/memory/components/<module>.md and update INDEX.md,
   STATE.md, TREE.md (via /checkpoint).
