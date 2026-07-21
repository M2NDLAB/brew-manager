---
type: tree
updated: 2026-07-21
generated-by: /checkpoint
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
│   ├── hooks-install.sh
│   ├── README.md
│   ├── reset-task.sh
│   └── test-hooks-install.sh
├── tests
│   ├── test_capabilities.zsh
│   ├── test_exit_codes.zsh
│   ├── test_guardrails.zsh
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

5 directories, 41 files
```

## Legenda directory chiave
| Path | Cosa contiene |
|---|---|
| .claude/docs/ | documentazione di processo (il "metodo") — caricare solo i file rilevanti |
| .claude/commands/ | slash command del metodo — l'elenco autorevole è in `CLAUDE.md`, "Comandi rapidi" |
| .claude/memory/ | questa memoria: [[STATE]], [[TREE]], [[INDEX]], sessions/, decisions/, components/, plans/ |
| lib/ | infrastruttura condivisa sourcata dal main: TUI + guard-rail ([[lib-common]]) + registry/resolver di selezione ([[lib-selection]]) |
| modules/ | i 18 moduli (funzioni sourcate): 14 numerici `mod_00`–`mod_13` (sequenza `go`) + 4 speciali per nome (`bk`, `las`, `log`, `mas`) |
| scripts/ | script di processo del framework (hooks-install, reset-task, test-hooks-install self-test) — NON script applicativi |
| tests/ | test del progetto (harness zsh, zero-dip, `make test`, **220 check**): `test_selection.zsh` (resolver, [[lib-selection]]), `test_guardrails.zsh` (consenso `_ask`/`_read_choice`), `test_exit_codes.zsh` (exit end-to-end via sandbox, [[core-brew-manager]]), `test_capabilities.zsh` (detection TUI + degradazione + e2e "pipato = zero ANSI", BM-09, [[lib-common]]), `test_risk_badges.zsh` (registry `MODULE_RISK` + badge/degradazione + invarianza consenso di `_ask_danger`, BM-10), `test_menu_registry.zsh` (lockstep `MODULE_NAME`↔`MODULE_DESC` + cap di colonna del menu 80-col, BM-11), `test_run_summary.zsh` (spinner gated su TUI_TTY + rc del figlio preservato, glifi/formatter puri, invariante di wiring `DU_AFTER`↔KB in mod_05, BM-12) |
| logs/ (ignorata) | log di sessione `brew_report_*.log` generati via script(1) |
| backups/ (ignorata) | Brewfile e bundle agenti prodotti dal modulo `bk` |
| agents/ (ignorata) | conf e activity log dei LaunchAgent del modulo `las` |

## Note
- `tree` non mostra i dotfile: esistono anche `.claude/`, `.gitignore`,
  `.claude/settings.local.json` (locale, non versionato) e
  `.claude/framework-version` (provenance pin dell'innesto framework, v1.0.0).
- `logs/`, `backups/`, `agents/` sono directory RUNTIME create dai moduli:
  git-ignorate, mai committate.
- Solo `brew_manager.sh` è eseguibile; `lib/` e `modules/` vengono sourcati.
