---
type: session
date: 2026-07-17
branch: refactor/selection-resolver
tags: [session, m2, bm08a, dispatch, tests]
---
# BM-08a — estrazione `_resolve_selection` + nascita dei test

## Contesto d'ingresso
Release v1.2.0 già RILASCIATA (merge c5dc3a5, tag annotato v1.2.0 pushato); lo
STATE era stale su questo. Riconciliata la memoria e — su via libera ESPLICITA
dell'utente al gate ⛔ pre-M2 — avviato M2/BM-08a.

## Fatto
- **`lib/selection.sh` (nuovo)**: registry `MODULE_DESC`/`MODULE_IDS` +
  `_resolve_selection` spostati VERBATIM da `brew_manager.sh`. Nessun modulo
  referenziava il registry (grep su `modules/` → zero): spostamento sicuro.
- **`brew_manager.sh`**: source di `selection.sh`, registry inline rimosso, `case`
  di PARSE SELECTION sostituito dalla chiamata al resolver (−51/+13).
- **`tests/test_selection.zsh` (nuovo)** + `make test`: PRIMO harness del progetto,
  zsh puro zero-dip, con anti-vacuità. `make check` linta anche `tests/*.zsh`.
- Commit refactor `3ff6cfc`; hardening test `4e1b6f1`.

## Decisioni (registrate → [[2026-07-17-selection-resolver-contract]])
Home `lib/selection.sh`; contratto ad **array globale** `MODULES_TO_RUN` (NON
stdout, perché `_warn` scrive su stdout → mescolerebbe warning e risultato);
ritorno 0/1; harness zsh a mano (no bats: dip non installata, incoerente con
"nessun tool obbligatorio"). Due scelte approvate dall'utente 2026-07-17.

## Gate di sicurezza (adversariale, autore ≠ giudice — docs/03)
Workflow multi-agente: 4 finder per dimensione (parità, injection/dispatch,
scope/init, test-adequacy) → ogni finding refutato da 2 verificatori con lente
diversa. **Parità, injection, scope PULITI** (finder vuoti) → codice
behavior-neutral. **5 finding confermati, TUTTI test-adequacy LOW/INFO** (nessun
HIGH/CRITICAL/MEDIUM → gate PASSA). **1 refutato** empiricamente (il reset di
`MODULES_TO_RUN` È coperto: rimuoverlo → 13/23 fail).
RISOLTI (non accettati come debito) con 20 asserzioni (23 → 43): return-code 0/1
(`assert_rc`), whitespace di bordo, token vuoti, molteplicità warning
(`assert_warn_count`), special maiuscoli BK/LAS/MAS. Chiusura **provata per
mutazione**: invertendo il return la suite ora fallisce 4/43 (prima restava verde).

## Verifica
`make check` verde (22 script + test); `make test` **43/43**; smoke cablato
dell'intero `brew_manager.sh` (via `BREW_MANAGER_RECORDING` per saltare il re-exec
`script(1)`): selezione invalida → exit 1 senza dispatch; valida → `Running
modules` → `SUMMARY`.

## Parità: quirk preservati di proposito (non fix)
`Log` mixed-case non matcha; `go` dentro una lista viene scartato; special in
lista è case-sensitive. Il loro fix è un task separato, così BM-08a resta
provabilmente behavior-neutral.

## Retro
IMP-002 registrata (checklist "superficie del contratto" per i test di
estrazione/parità), propose-only, decisione differita.

## Prossimo
BM-08b (dispatch posizionale + `--only`/`--skip`) PUNTA a
[[2026-07-17-selection-resolver-contract]]. Nota tecnica per BM-08b: dovrà
spostare il source di `selection.sh`/il punto di chiamata, perché il parsing CLI
avviene PRIMA che `MODULE_DESC` sia definito nel flusso attuale.
