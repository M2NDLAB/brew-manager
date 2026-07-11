---
type: component
component: core-brew-manager
updated: 2026-07-12
tags: [component]
---
# core-brew-manager (brew_manager.sh)

Entry point TUI: parsing flag, caricamento lib+moduli, dispatch, recording della
sessione, summary finale.

## Stato attuale
Stabile, v1.1.2 (ma la costante `BREW_MANAGER_VERSION` dice ancora "1.1.0" —
debito in STATE). Nessun test.

## Cosa espone / responsabilità
- Flag CLI: `--dry-run`, `--yes|-y` (auto-attivo se stdin non è TTY),
  `--adopt=n|all|1,2`, `--upgrade=y|n` — esportati come env `BREW_MANAGER_*`.
- Mappa `MODULE_DESC` (chiavi 0–13 + log/bk/las/mas): la validazione dell'input
  controlla l'esistenza della chiave → un modulo senza voce NON è selezionabile.
- `MODULE_IDS=(0..13)` = sequenza `go`; gli speciali ne restano fuori.
- Dispatch: numerico → `_module_N` dinamica; speciali → case esplicito
  (log→`_module_log`, bk→`_module_14`, las→`_module_15`, mas→`_module_16`).
- Recording: auto-rilancio dentro `script(1)` (guard `BREW_MANAGER_RECORDING`),
  post-processing sed che rimuove escape ANSI; `logs/` con fallback mktemp.
- Cleanup finale hardcoded dei temporanei `/tmp/brew_*.log`.

## Vincoli e insidie (per chi lo usa o lo modifica)
- **Gli argomenti CLI posizionali NON sono implementati** benché documentati nel
  README e usati dai plist dello scheduler (Attenzione #1 in STATE): la selezione
  moduli avviene SOLO dal prompt interattivo; in non-TTY degrada a `go`.
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
