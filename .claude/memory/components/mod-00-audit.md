---
type: component
component: mod-00-audit
updated: 2026-07-12
tags: [component]
---
# mod-00-audit (modules/mod_00_audit.sh)

Audit delle app in /Applications e ~/Applications non gestite da Homebrew, con
adozione opzionale via `brew install --cask --adopt`. SENSIBILE (installa e adotta).

## Stato attuale
Funzionante ma con difetti noti (sotto). Nessun test.

## Cosa espone / responsabilità
- Funzione `_module_0`; popola gli array globali `UNMANAGED_WITH_CASK`,
  `UNMANAGED_NO_CASK`, `UNMANAGED_APPLE` letti dal summary.
- Prompt di adozione via `_read_choice` con override `BREW_MANAGER_ADOPT`
  (default `n`: in --yes NON adotta nulla).
- App Apple rilevate con `mdfind` batch su kMDItemCFBundleIdentifier (il check
  codesign è volutamente disabilitato: troppo lento, resta solo in commento).
- Log errori adozione su `/tmp/brew_adopt_err.log` (fisso, sovrascritto).

## Vincoli e insidie (per chi lo usa o lo modifica)
- **BUG noto (STATE Attenzione #2)**: selezione per indice con `real_idx=num-1`
  su array zsh 1-based — "1" dà elemento vuoto, "2" adotta la PRIMA app. Da
  fixare al primo intervento sul modulo (con security gate).
- **NON rispetta `BREW_MANAGER_DRY_RUN`** (STATE Attenzione #3): l'adozione
  confermata parte anche in dry-run.
- Matching nome-app→cask euristico (tr/sed): falsi positivi/negativi possibili;
  un `brew info --cask` per app → lento su /Applications grandi.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
