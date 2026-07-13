---
type: session
date: 2026-07-13
status: completed
branch: fix/mod09-counter
tags: [session, roadmap-v2, bm-05b]
---
# BM-05b — off-by-one nel contatore di mod_09 (read-only, no gate)

## Fatto
- Commit 6162d62. `Total tracked binaries` era stampato da `_idx`, contatore di
  loop inizializzato a 1 e incrementato a ogni riga → totale sempre +1. Ora conta
  l'array (`${#tracked_bins[@]}`).
- `_idx` era per il resto codice morto: l'header prometteva una colonna "No." che
  le righe non stampano mai (la prima colonna contiene il simbolo di stato).
  Header corretto di conseguenza.
- Nessun security gate: modulo read-only, nessuna azione mutante (docs/03 non si
  applica).

## Test
- RED/GREEN sul sistema REALE (il modulo è read-only, eseguibile senza rischi):
  main dichiarava **12** su **11** binari elencati; il fix dichiara **11**.
  Controprova indipendente con `wc -l` sull'elenco reale: 11.
- Il resto dell'output è identico (diff main-vs-fix: solo header e totale).
- Ramo "zero binari tracciati" non toccato dal diff (verificato: compare solo
  come contesto).

## Problemi → causa → soluzione
- Il mio primo conteggio di verifica dava 13 righe (invece di 11) perché il grep
  `^  ✓` catturava anche le due righe della LEGENDA "About this module", che usano
  lo stesso simbolo. Corretto restringendo il conteggio alle righe dopo il
  separatore di tabella. Lezione: quando si conta l'output di una TUI, ancorare
  il conteggio alla struttura (tabella), non a un simbolo che ricorre altrove.

## Correzioni fattuali doc
- CHANGELOG aggiornato.

## Proposte IMP
- Nessuna.

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- Restano in M1: BM-06 (greedy scope) e BM-07 (version drift + dead code).
- Dopo M1: punto con l'utente sul primo tag di release, PRIMA di M2 (resolver).
