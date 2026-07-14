---
type: session
date: 2026-07-14
status: completed
branch: docs/readme-reality
tags: [session, roadmap-v2, bm-19, release-v1.2.0]
---
# BM-19 (ristretto a v1.2.0) — README riconciliato con la realtà

## Fatto
- Commit 7f7f90d. Perimetro: dire il vero su ciò che v1.2.0 fa DAVVERO, senza
  over-claim (regola di onestà vincolante dell'utente).
- **Over-claim rimossi** (feature che non esistono):
  - selezione moduli da CLI (`./brew_manager.sh 1,4,5`): gli argomenti posizionali
    sono IGNORATI → riscritta la sezione "Choosing what to run" (la scelta avviene
    al prompt della TUI) + avvertenza esplicita "Not yet supported";
  - **scoperta**: anche TUTTI gli esempi dei moduli speciali usavano la forma
    posizionale (`./brew_manager.sh bk`), che non funziona → corretti in
    `./brew_manager.sh` + "then type `bk` at the Choice prompt";
  - scheduling per-modulo: il plist salva la selezione ma il core la ignora →
    dichiarato che ogni agente esegue la sequenza completa `go`;
  - corretto anche il commento `Usage:` nel codice, che prometteva `[go|modules]`.
- **Comportamenti aggiornati**: adozione funzionante + conferma del bersaglio
  (BM-04); cleanup che chiede prima (BM-02); i tre restore di bk che chiedono
  conferma e fanno preview in dry-run (BM-03); greedy solo sui cask confermati
  (BM-06); integrity check con la terza categoria (agenti legacy/corrotti) e la
  protezione dei multi-day (BM-05a); `--dry-run` onorato ovunque.
- **Aggiunti**: `--version`/`-V` (nuovo, BM-07), l'errore sui flag ignoti,
  `VERSION`/`CHANGELOG.md`/`SECURITY.md` nella struttura, la regola per i nuovi
  moduli (ogni azione mutante onora DRY_RUN e YES via `_ask`/`_read_choice`).

## Verifica di coerenza (README ↔ help ↔ comportamento)
- Non esiste un `--help`: l'unico "help" reale è il messaggio del parser sui flag
  accettati. Confrontato con la tabella del README → allineati (ho aggiunto `-V`
  al messaggio del parser, che lo ometteva).
- Ogni flag documentato testato: tutti accettati; `--version`/`-V` → exit 0.
- Verificato che il disclaimer sia VERO: `./brew_manager.sh 1,4,5` esegue davvero
  la sequenza `go` (parte dal modulo 0). La run reale è andata in timeout perché
  ha eseguito i moduli: processi terminati, nessun residuo.

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- Prossimo: release v1.2.0 (VERSION → 1.2.0, CHANGELOG [Unreleased] → [1.2.0]).
- Il resto di BM-19 (le parti che dipendono da M2: documentare la CLI posizionale
  quando esisterà) resta aperto nel piano.
