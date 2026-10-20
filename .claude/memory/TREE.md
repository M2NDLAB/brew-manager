---
type: tree
updated: 2026-10-19
generated-by: /fw:checkpoint
tags: [structure]
---
# Struttura del progetto

> Mappa del repository, da consultare PRIMA di esplorare il filesystem a mano.
> Si RIGENERA meccanicamente, **non si edita a mano**:
>
> ```
> tree -L 3 --dirsfirst -I 'logs|backups|agents|.DS_Store'
> ```
>
> Fallback se `tree` non è installato: `git ls-files`.

## Albero (generato)
```
.
├── lib
│   ├── common.sh
│   ├── log.sh
│   └── selection.sh
├── modules
│   ├── mod_00_audit.sh
│   ├── mod_01_health.sh
│   ├── mod_02_update.sh
│   ├── mod_03_packages.sh
│   ├── mod_04_updates.sh
│   ├── mod_05_cleanup.sh
│   ├── mod_06_deps.sh
│   ├── mod_07_services.sh
│   ├── mod_08_untracked.sh
│   ├── mod_09_tracked.sh
│   ├── mod_10_greedy.sh
│   ├── mod_11_conflicts.sh
│   ├── mod_12_security.sh
│   ├── mod_13_disk.sh
│   ├── mod_bk_brewfile.sh
│   ├── mod_las_scheduler.sh
│   ├── mod_log_manager.sh
│   └── mod_mas_mas.sh
├── scripts
│   ├── agent-git-guard.mjs
│   ├── check-prerequisites.sh
│   ├── hooks-install.sh
│   ├── README.md
│   ├── repo-snapshot.sh
│   ├── reset-task.sh
│   ├── state-inject.sh
│   ├── test-agent-git-guard.sh
│   ├── test-check-prerequisites.sh
│   ├── test-hooks-install.sh
│   ├── test-repo-snapshot.sh
│   ├── test-reset-task.sh
│   └── test-state-inject.sh
├── tests
│   ├── test_capabilities.zsh
│   ├── test_dryrun_gates.zsh
│   ├── test_exit_codes.zsh
│   ├── test_guardrails.zsh
│   ├── test_homebrew_developer.zsh
│   ├── test_menu_registry.zsh
│   ├── test_risk_badges.zsh
│   ├── test_run_summary.zsh
│   └── test_selection.zsh
├── brew_manager.sh
├── CHANGELOG.md
├── CLAUDE.md
├── commitlint.config.cjs
├── LICENSE
├── Makefile
├── README.md
├── SECURITY.md
└── VERSION

5 directories, 52 files
```

## Legenda directory chiave
| Path | Cosa contiene |
|---|---|
| .claude/rules/ | the method's core, `fw-core.md` (loaded at every launch), and its path-scoped rules: `fw-boundary.md` (the boundary's files), `fw-code-quality.md` (brew's code files) |
| .claude/docs/ | documentazione di processo (il "metodo") — read when the core's table names them, never `@`-imported |
| .claude/commands/fw/ | the method's slash commands, run as `/fw:<name>` — the authoritative list is the core's *Quick commands* (`.claude/rules/fw-core.md`) |
| .claude/memory/ | questa memoria: [[STATE]], [[TREE]], [[INDEX]], sessions/, decisions/, components/, plans/ |
| lib/ | infrastruttura condivisa sourcata dal main: TUI + guard-rail ([[lib-common]]) + registry/resolver di selezione ([[lib-selection]]) |
| modules/ | i 18 moduli (funzioni sourcate): 14 numerici `mod_00`–`mod_13` (sequenza `go`) + 4 speciali per nome (`bk`, `las`, `log`, `mas`) |
| scripts/ | the framework's process scripts and their self-tests (`make test-scripts`): `hooks-install.sh` (the git hooks), `agent-git-guard.mjs` (the PreToolUse guard), `state-inject.sh` (the SessionStart injection of STATE), `reset-task.sh`, `repo-snapshot.sh`, `check-prerequisites.sh` — NON script applicativi |
| tests/ | test del progetto (harness zsh, zero-dip, `make test`, **333 check**): `test_selection.zsh` (resolver, [[lib-selection]]), `test_guardrails.zsh` (consenso `_ask`/`_read_choice`), `test_exit_codes.zsh` (exit end-to-end via sandbox, [[core-brew-manager]]), `test_capabilities.zsh` (detection TUI + degradazione + e2e "pipato = zero ANSI", BM-09, [[lib-common]]), `test_risk_badges.zsh` (registry `MODULE_RISK` + badge/degradazione + invarianza consenso di `_ask_danger`, BM-10), `test_menu_registry.zsh` (lockstep `MODULE_NAME`↔`MODULE_DESC` + cap di colonna del menu 80-col, BM-11), `test_run_summary.zsh` (spinner gated su TUI_TTY + rc del figlio preservato, glifi/formatter puri, invariante di wiring `DU_AFTER`↔KB in mod_05, BM-12; coerenza di `MODULE_DRYRUN` + allow-list `_KNOWN_UNGATED`), `test_dryrun_gates.zsh` (mod_02/mas non invocano i comandi mutanti in dry-run — tripwire su mock brew, con controlli "denti" in wet; e2e che `HOMEBREW_NO_AUTO_UPDATE` raggiunge brew attraverso `script(1)`), `test_homebrew_developer.zsh` (no Homebrew developer command in the code; module 1's developer-mode detection and restore, [[mod-01-health]]) |
| logs/ (ignorata) | log di sessione `brew_report_*.log` generati via script(1) |
| backups/ (ignorata) | Brewfile e bundle agenti prodotti dal modulo `bk` |
| agents/ (ignorata) | conf e activity log dei LaunchAgent del modulo `las` |

## Note
- `tree` does not show dotfiles: there are also `.claude/` (`rules/`, `docs/`,
  `commands/fw/`, `memory/`, `settings.json`), `.gitignore`, `.gitattributes` (LF for the
  framework's files), `.claude/settings.local.json` (local, not versioned) and
  `.claude/framework-version` (provenance pin of the framework graft, v4.1.0).
- `logs/`, `backups/`, `agents/` sono directory RUNTIME create dai moduli:
  git-ignorate, mai committate.
- Solo `brew_manager.sh` è eseguibile tra i file del prodotto (gli script di `scripts/`
  sono del framework); `lib/` e `modules/` vengono sourcati.
