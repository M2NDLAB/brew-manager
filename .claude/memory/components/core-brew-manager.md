---
type: component
component: core-brew-manager
updated: 2026-07-18
tags: [component]
---
# core-brew-manager (brew_manager.sh)

Entry point TUI: parsing flag, caricamento lib+moduli, dispatch, recording della
sessione, summary finale.

## Stato attuale
Stabile, v1.2.0 rilasciata. Versione da file `VERSION` (BM-07, non più costante
hardcoded). Dal BM-08a la selezione moduli è delegata a `_resolve_selection`
([[lib-selection]]) — coperta da `tests/test_selection.zsh`. Dal fix exit-code
(2026-07-18) il PARENT propaga l'exit del figlio attraverso il wrapper
script(1) — contratto end-to-end coperto da `tests/test_exit_codes.zsh`
(sandbox a symlink farm + mock brew). Il resto del core resta senza test.

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
- **Consenso vs non-interattivo (BM-08c)**: `NON_INTERACTIVE` (da `! -t 0`, o
  dall'handoff `BREW_MANAGER_NONINTERACTIVE` nel figlio re-exec col pty) NON è
  consenso — solo `--yes` setta `YES_MODE`. Export di entrambi per i moduli.
  Vedi [[2026-07-17-consent-vs-noninteractive]], [[lib-common]].
- Recording: auto-rilancio dentro `script(1)` (guard `BREW_MANAGER_RECORDING`),
  post-processing sed che rimuove escape ANSI; `logs/` con fallback mktemp.
  **Contratto di exit (fix 2026-07-18)**: `_run_rc` catturato SUBITO dopo
  script(1) e propagato dopo la strip — selezione invalida → 2, selezione
  vuota → 1, figlio ucciso da segnale → numero grezzo del segnale (semantica
  script(1) macOS: Ctrl+C → 2), run ok → 0. Strip fallita: WARNING su stderr,
  log raw conservato, rc della run INVARIATO. Un fallimento DENTRO un modulo
  esce ancora 0 (metà residua di Attenzione #4b).
- Cleanup finale hardcoded dei temporanei `/tmp/brew_*.log`.

## Vincoli e insidie (per chi lo usa o lo modifica)
- **Argomenti CLI posizionali: IMPLEMENTATI (BM-08b)** — `./brew_manager.sh 0,4,5`
  esegue quei moduli non-interattivamente; `--only`/`--skip` filtrano. La cattura
  dei posizionali avviene nel loop dei flag (registry non ancora sourcato), la
  RISOLUZIONE dopo il source (dove c'era il menu). Gli agenti scheduler sono
  instradati per il resolver e il non-TTY è fail-closed senza `--yes` —
  entrambi CHIUSI in BM-08c (questa nota conteneva il residuo stale,
  riconciliato 2026-07-18).
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
- [[sessions/2026-07-17-bm08c-agent-selection]] (NON_INTERACTIVE vs YES_MODE)
- [[sessions/2026-07-18-exit-code-propagation]] (rc del figlio propagato dal parent)
