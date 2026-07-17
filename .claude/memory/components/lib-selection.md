---
type: component
component: lib-selection
updated: 2026-07-17
tags: [component]
---
# lib-selection (lib/selection.sh)

Registry dei moduli + resolver della selezione. Nato in BM-08a estraendo la logica
inline da `brew_manager.sh`, per renderla riusabile (dispatch posizionale BM-08b,
agenti BM-08c) e testabile in isolamento.

## Stato attuale
Nuovo (2026-07-17, BM-08a). **Sensibile**: infrastruttura di dispatch condivisa —
un difetto qui propaga a tutti i moduli. Coperto da `tests/test_selection.zsh`
(43 check). Gate adversariale di BM-08a passato (parità/injection/scope puliti).

## Cosa espone / responsabilità
- `MODULE_DESC` (assoc, `typeset -gA`; chiavi 0–13 + log/bk/las/mas): descrizioni
  E insieme di validità — una chiave assente = modulo non selezionabile.
- `MODULE_IDS=(0..13)` (`typeset -ga`): sequenza `go`; gli speciali ne restano fuori.
- `_resolve_selection <spec>`: popola il GLOBALE `MODULES_TO_RUN` (reset a ogni
  chiamata), ritorna `0` se non vuoto / `1` se vuoto. NON stampa la lista.

## Vincoli e insidie (per chi lo usa o lo modifica)
- **Contratto ad array globale, non stdout**: `_warn` (lib/common.sh) scrive su
  stdout, quindi stampare la lista la mescolerebbe ai warning. Chi riusa il resolver
  legge `MODULES_TO_RUN`, MAI `$(_resolve_selection …)`.
- **Dipendenze al CALL time**: usa `_warn` (common.sh) e legge `MODULE_DESC`/`IDS`.
  Va sourcato dopo common.sh. In `brew_manager.sh` è sourcato subito dopo common/log,
  così il registry è pronto per menu/dispatch/summary.
- **Sourcabile senza side effect**: definisce solo dati e una funzione → i test lo
  sourcano in isolamento (con common.sh per `_warn`) contro il registry REALE.
- **Parità con quirk preservati di proposito**: il `case` è uno spostamento verbatim
  del vecchio parser → `Log` mixed-case non matcha, `go` in lista scartato, special
  in lista case-sensitive. Fissati in [[2026-07-17-selection-resolver-contract]];
  il loro fix è un task separato.
- **Return-code NON load-bearing oggi**: il path interattivo (`brew_manager.sh`)
  legge la LUNGHEZZA di `MODULES_TO_RUN`, non `$?`. Lo diventa quando BM-08b/c
  cablano la rc nel dispatch CLI/schedulato — per questo il contratto 0/1 è già
  testato (`assert_rc`).
- **Contratto stabile per BM-08b/c**: entrambi PUNTANO al resolver, non re-parsano.
  BM-08b dovrà però anticipare il source/la chiamata (il parsing CLI precede la
  definizione di `MODULE_DESC` nel flusso attuale).

## Sessioni che l'hanno toccato
- [[sessions/2026-07-17-bm08a-selection-resolver]] (nascita)
