---
type: component
component: core-brew-manager
updated: 2026-07-17
tags: [component]
---
# core-brew-manager (brew_manager.sh)

Entry point TUI: parsing flag, caricamento lib+moduli, dispatch, recording della
sessione, summary finale.

## Stato attuale
Stabile, v1.2.0 rilasciata. Versione da file `VERSION` (BM-07, non più costante
hardcoded). Dal BM-08a la selezione moduli è delegata a `_resolve_selection`
([[lib-selection]]) — la selezione ora è coperta da `tests/test_selection.zsh`;
il resto del core resta senza test.

## Cosa espone / responsabilità
- Flag CLI: `--dry-run`, `--yes|-y` (auto-attivo se stdin non è TTY),
  `--adopt=n|all|1,2`, `--upgrade=y|n`, `--only=ids`, `--skip=ids`, `--version|-V`
  — esportati come env `BREW_MANAGER_*`. Flag ignoti/lookalike Unicode → errore +
  exit 2 (micro-task).
- **Selezione** (registry + parser in `lib/selection.sh`, [[lib-selection]]):
  - **Da CLI (BM-08b)**: il loop dei flag cattura i token posizionali (uniti con
    virgole) e `--only`/`--skip`; se presenti, `CLI_SELECTION=1` → il core chiama
    `_resolve_cli` STRETTO (token ignoto → errore + exit 2) e SALTA il menu.
  - **Interattiva**: nessuna selezione da CLI → menu + `read` + `_resolve_selection`
    (lenient: warn+skip). Policy "vuoto = fatale" (`_err` + `exit 1`) nel core.
- Dispatch: numerico → `_module_N` dinamica; speciali → case esplicito
  (log→`_module_log`, bk→`_module_14`, las→`_module_15`, mas→`_module_16`).
- Recording: auto-rilancio dentro `script(1)` (guard `BREW_MANAGER_RECORDING`),
  post-processing sed che rimuove escape ANSI; `logs/` con fallback mktemp.
- Cleanup finale hardcoded dei temporanei `/tmp/brew_*.log`.

## Vincoli e insidie (per chi lo usa o lo modifica)
- **Argomenti CLI posizionali: IMPLEMENTATI (BM-08b)** — `./brew_manager.sh 0,4,5`
  esegue quei moduli non-interattivamente; `--only`/`--skip` filtrano. La cattura
  dei posizionali avviene nel loop dei flag (registry non ancora sourcato), la
  RISOLUZIONE dopo il source (dove c'era il menu). Resta aperto: gli agenti dello
  scheduler passano i moduli come argomento ma NON sono ancora instradati per il
  resolver → **BM-08c** (chiude la parte scheduler di Attenzione #1 e #8).
  ATTENZIONE non-TTY: un posizionale su un singolo modulo mutante eredita
  `YES_MODE=1` auto (Attenzione #8) — reach ampliato di un debito già noto.
- I moduli sono funzioni SOURCATE nello stesso processo: condividono l'ambiente;
  una variabile "locale" non dichiarata `local` inquina lo stato globale.
- Il re-exec sotto script(1) fa ripartire lo script dall'inizio: tutto ciò che
  precede il guard `BREW_MANAGER_RECORDING` viene eseguito DUE volte.
- Installer Homebrew integrato (curl + exec zsh): non toccare senza rileggere il
  flusso di re-exec.
- Nessuna trap su Ctrl+C: il salvataggio del log è garantito dal processo esterno
  di script(1), non da handler interni.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
- [[sessions/2026-07-17-bm08a-selection-resolver]] (registry/parser usciti in lib/selection.sh)
- [[sessions/2026-07-17-bm08b-positional-dispatch]] (cattura posizionali + branch CLI)
