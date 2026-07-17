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
  `--adopt=n|all|1,2`, `--upgrade=y|n`, `--version|-V` — esportati come env
  `BREW_MANAGER_*`. Flag ignoti/lookalike Unicode → errore + exit 2 (micro-task).
- **Selezione**: il registry (`MODULE_DESC`/`MODULE_IDS`) e il parser sono usciti
  in `lib/selection.sh` (BM-08a); il core li SOURCA e chiama `_resolve_selection
  "$module_choice"`, che popola `MODULES_TO_RUN`. La policy "vuoto = fatale"
  (`_err` + `exit 1`) resta nel core. Vedi [[lib-selection]].
- Dispatch: numerico → `_module_N` dinamica; speciali → case esplicito
  (log→`_module_log`, bk→`_module_14`, las→`_module_15`, mas→`_module_16`).
- Recording: auto-rilancio dentro `script(1)` (guard `BREW_MANAGER_RECORDING`),
  post-processing sed che rimuove escape ANSI; `logs/` con fallback mktemp.
- Cleanup finale hardcoded dei temporanei `/tmp/brew_*.log`.

## Vincoli e insidie (per chi lo usa o lo modifica)
- **Gli argomenti CLI posizionali NON sono ancora implementati** benché documentati
  nel README e usati dai plist dello scheduler (Attenzione #1 in STATE): la
  selezione avviene SOLO dal prompt interattivo; in non-TTY degrada a `go`. BM-08a
  ha estratto la FONDAZIONE (il resolver); il dispatch posizionale è BM-08b, che
  dovrà anticipare il source di `selection.sh` (oggi il parsing flag precede la
  definizione del registry).
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
