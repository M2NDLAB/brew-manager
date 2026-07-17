---
type: component
component: lib-selection
updated: 2026-07-17
tags: [component]
---
# lib-selection (lib/selection.sh)

Registry dei moduli + resolver della selezione. Nato in BM-08a estraendo la logica
inline da `brew_manager.sh`; esteso in BM-08b con la risoluzione CLI stretta
(usata dal dispatch posizionale, e da BM-08c per gli agenti).

## Stato attuale
BM-08a + BM-08b (2026-07-17). **Sensibile**: infrastruttura di dispatch condivisa —
un difetto qui propaga a tutti i moduli. Coperto da `tests/test_selection.zsh`
(74 check). Due gate adversariali passati (BM-08a; BM-08b con 2 MEDIUM fail-open
del tokenizer trovati e fixati).

## Cosa espone / responsabilità
- `MODULE_DESC` (assoc, `typeset -gA`; chiavi 0–13 + log/bk/las/mas): descrizioni
  E insieme di validità — una chiave assente = modulo non selezionabile.
- `MODULE_IDS=(0..13)` (`typeset -ga`): sequenza `go`; gli speciali ne restano fuori.
- `_resolve_selection <spec> [invalid_mode]`: popola il GLOBALE `MODULES_TO_RUN`
  (reset) + `RESOLVE_INVALID` (i token ignoti); ritorna 0 non-vuoto / 1 vuoto.
  `invalid_mode`: `warn` (default, interattivo — stampa `_warn`) | `collect`
  (silenzioso, per la CLI stretta). NON stampa la lista.
- `_resolve_cli <spec> <only> <skip>`: risoluzione NON interattiva e STRETTA —
  base + intersezione `--only` + sottrazione `--skip`. Ritorna **2** se un token
  è ignoto (in `RESOLVE_INVALID`), **1** se vuota, **0** altrimenti. Ordine e
  duplicati della base preservati; i filtri sono liste di moduli concreti (no `go`).
- `_collect_module_tokens <csv>`: valida i token di un filtro → `FILTER_TOKENS`
  (validi) + append a `RESOLVE_INVALID` (ignoti).

## Vincoli e insidie (per chi lo usa o lo modifica)
- **Contratto ad array globale, non stdout**: `_warn` (lib/common.sh) scrive su
  stdout, quindi stampare la lista la mescolerebbe ai warning. Chi riusa il resolver
  legge `MODULES_TO_RUN`, MAI `$(_resolve_selection …)`.
- **Dipendenze al CALL time**: usa `_warn` (common.sh) e legge `MODULE_DESC`/`IDS`.
  Va sourcato dopo common.sh. In `brew_manager.sh` è sourcato subito dopo common/log,
  così il registry è pronto per menu/dispatch/summary.
- **Sourcabile senza side effect**: definisce solo dati e una funzione → i test lo
  sourcano in isolamento (con common.sh per `_warn`) contro il registry REALE.
- **Parità con quirk preservati di proposito**: `Log` mixed-case non matcha, `go`
  in lista scartato, special in lista case-sensitive. Fissati in
  [[2026-07-17-selection-resolver-contract]].
- **Tokenizer indurito (BM-08b, gate)**: split e strip degli spazi con param
  expansion (`${(@s:,:)}`, `${v// /}`), MAI `echo`/`read -rA <<<`. Motivo: `echo`
  espande i backslash-escape (`\065`→`5`), remappando un token fasullo su un
  modulo reale (fail-open, eseguiva mod_05); `read -rA` tronca al primo newline.
  Regola generale → [[LEARNINGS]] IMP-003. I token VUOTI (virgole adiacenti/finali)
  sono ignorati, non "invalidi": `0,4,` risolve a {0,4} su entrambi i path.
- **Return-code NON load-bearing oggi**: il path interattivo (`brew_manager.sh`)
  legge la LUNGHEZZA di `MODULES_TO_RUN`, non `$?`. Lo diventa quando BM-08b/c
  cablano la rc nel dispatch CLI/schedulato — per questo il contratto 0/1 è già
  testato (`assert_rc`).
- **Contratto stabile per BM-08b/c**: entrambi PUNTANO al resolver, non re-parsano.
  BM-08b dovrà però anticipare il source/la chiamata (il parsing CLI precede la
  definizione di `MODULE_DESC` nel flusso attuale).

## Sessioni che l'hanno toccato
- [[sessions/2026-07-17-bm08a-selection-resolver]] (nascita)
- [[sessions/2026-07-17-bm08b-positional-dispatch]] (API CLI stretta + hardening gate)
