---
type: component
component: mod-05-cleanup
updated: 2026-07-12
tags: [component]
---
# mod-05-cleanup (modules/mod_05_cleanup.sh)

Libera spazio: `brew autoremove` (dipendenze orfane) + `brew cleanup -s` (vecchie
versioni + cache). SENSIBILE: è il modulo più aggressivo della suite.

## Stato attuale
Funzionante; il meno protetto di tutti (sotto). Nessun test.

## Cosa espone / responsabilità
- Funzione `_module_5`; misura la cache prima/dopo e popola `DU_AFTER` per il
  summary.

## Vincoli e insidie (per chi lo usa o lo modifica)
- **NESSUNA conferma e NESSUN rispetto di `BREW_MANAGER_DRY_RUN`** (STATE
  Attenzione #3): autoremove+cleanup partono all'ingresso nel modulo. In
  combinazione con la degradazione a `go` degli agenti schedulati (STATE
  Attenzione #1), questo modulo gira automaticamente e in silenzio sui Mac con
  scheduler attivo. Qualunque intervento qui DEVE prima introdurre preview
  (--dry-run di autoremove/cleanup) e conferma.
- `brew autoremove` può rimuovere formule usate FUORI dal grafo brew (il commento
  "both operations are safe" nel codice è ottimista).
- Misura solo la cache, non lo spazio recuperato dai pacchetti rimossi: il numero
  del summary sottostima.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
