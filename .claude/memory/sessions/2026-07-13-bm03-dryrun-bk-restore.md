---
type: session
date: 2026-07-13
status: completed
branch: fix/dryrun-bk-restore
tags: [session, roadmap-v2, bm-03, security-gate]
---
# BM-03 — restore di mod_bk onora --dry-run (sensibile ALTO, security gate)

## Fatto
- IMP-001 applicata in apertura con commit dedicato ae6cfb6 (git show in allow,
  prassi diff-inline) come da approvazione utente.
- Censimento reale LaunchAgent: ZERO installati su questo Mac (né plist, né
  agents/, né launchctl) — la migrazione plist legacy richiesta per BM-05a
  riguarda le installazioni degli utenti, non questa macchina.
- Commit 084bdb2: [3]/[3b]/[3a] con preview in dry-run; [3a] guadagna _ask
  (default n, coerente con [3]/[3b]); path reali invariati.
- Due decisioni di design emerse dal gate:
  1. **Preview pacchetti STATICA** (lettura riga-per-riga del Brewfile, brew MAI
     invocato): `brew bundle check` valuta il Brewfile come DSL Ruby → un
     Brewfile ostile eseguirebbe codice durante una preview che promette di non
     eseguire nulla. Aderisce anche alla lettera del piano ("senza eseguire
     brew bundle"). Il dettaglio "cosa manca" resta all'opzione [4] Check.
  2. **printf %s end-to-end**: l'echo builtin di zsh espande gli escape
     backslash (verificato empiricamente) — gli echo intermedi sui dati sono
     stati sostituiti con printf nei nuovi helper.
- Test (stub brew+launchctl, SCRIPT_DIR e HOME finti): 7 path — dry-run [3]/[3b]
  → ZERO chiamate esterne; dry [3a] → zero; reale confermato → install +
  launchctl + plist/conf scritti; rifiutato/yes-mode → nulla. Payload ostile
  (`\e]0;PWNED\a` in Brewfile e bundle) → mostrato come testo, zero byte ESC
  residui dopo lo strip dei colori legittimi (assertion a livello byte).

## Security gate (docs/03) — esito
Review 2 lenti (refute+regressione), diff inline, Read-only: 2/2 senza stalli,
gate_holds=true per entrambe.
- MEDIUM (Brewfile=Ruby DSL in preview) → RISOLTO (preview statica).
- MEDIUM (regressione [3a] in YES_MODE: prima eseguiva, ora salta col default n)
  → INTENZIONALE e documentato nel CHANGELOG; impatto pratico ~nullo (bk fuori
  da `go`, menu irraggiungibile non interattivamente); override tipo
  BREW_MANAGER_RESTORE rimandato a BM-16 (tier di conferma).
- LOW (echo intermedio espande escape) → RISOLTO nei nuovi helper; il residuo
  di classe in mod_05/_restore_agents è REGISTRATO in STATE (fuori perimetro).
- INFO (rc≠0 mostrato come lista mancanti) → decaduto con la preview statica.

## Problemi → causa → soluzione
- **Disclosure onestà BM-02**: il test S7 di BM-02 era un FALSO PASS (grep su
  `od -c` con spaziatura sbagliata). La garanzia di inertezza di mod_05 è
  parziale: l'echo intermedio su dati può produrre ESC. Registrato come debito
  in STATE (fix da 2 righe, fuori perimetro BM-03).
- Primo tentativo di harness bloccato dalla deny-list (`rm -rf` nel comando di
  setup): riscritto senza cancellazioni — la deny del framework funziona.

## Correzioni fattuali doc
- Nessuna (CHANGELOG aggiornato contestualmente).

## Proposte IMP
- Nessuna nuova (IMP-001 applicata, vedi sopra).

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- Debito nuovo in STATE: echo intermedio in mod_05/_restore_agents (2 righe).
- Prossimo: BM-04 (fix/adopt-off-by-one) dopo ok utente.
