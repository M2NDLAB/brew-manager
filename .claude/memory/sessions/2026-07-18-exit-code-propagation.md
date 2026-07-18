---
type: session
date: 2026-07-18
branch: fix/exit-code-propagation
tags: [session, exit-code, security-gate, core, release-v1.3.0]
---
# Micro-task: propagazione dell'exit code attraverso script(1)

## Contesto e scope (deciso dall'utente)
Inserito dall'utente tra il task README e la release v1.3.0: per una release che
completa lo scheduler, launchd deve poter vedere un avvio fallito. PRIMA di
implementare, analisi richiesta: il caso "parent perde l'exit del figlio" e il
caso "dispatcher ignora i return dei moduli" (BM-06, #4b) sono **due difetti
distinti** — il primo in `brew_manager.sh:245-250` (strip ANSI tra `script(1)` e
`exit $?`), il secondo nel dispatch (375-383) + `exit 0` incondizionato (437).
Campionati i return reali: SOLO mod_10 è affidabile; mod_02 ritorna 1 su run
sane. Chiudere il secondo = contratto di return su TUTTI i 18 moduli (BM-18).
**Decisione utente: scope = solo caso A** (parent); la metà moduli resta in #4b.

## Fatto (3 commit su fix/exit-code-propagation, da main 56cf64d)
- `4cef18c` fix(core): `_run_rc=$?` catturato SUBITO dopo `script -q`, exit
  finale `exit $_run_rc`. Premessa verificata empiricamente: script(1) macOS
  PROPAGA l'exit del figlio (documentato nel man). Nuovo
  `tests/test_exit_codes.zsh` end-to-end: **RED 2/4 prima del fix**
  (99→rc 0, selezione vuota→rc 0), **GREEN dopo** — la variabile isolata è il
  fix. Voce CHANGELOG sotto [Unreleased].
- `a6d1be9` fix(core): applicati i finding LOW/INFO del gate (sotto).
- `a3a4ad1` docs(readme): RIPRISTINATO il claim "non-zero exit" sul token
  ignoto (tolto per onestà nel task README, ora vero end-to-end) + contratto
  exit documentato per i caller unattended.

## Gate di sicurezza (adversariale, autore ≠ giudice — docs/03)
Verdetto: **il fix regge**. CRITICAL/HIGH/MEDIUM: nessuno. Il reviewer ha
refutato empiricamente le ipotesi d'attacco (nulla altera `$?` tra script e
cattura; guard-rail DRY_RUN/YES/NON_INTERACTIVE intoccati; mock non
scavalcabile; test incapace di mutare il sistema). Finding applicati:
- LOW: strip fallita era silenziosa nell'rc → ora WARNING su stderr + temp
  rimosso, rc della run INVARIATO (verificato il ramo in isolamento).
- LOW: il cleanup del test operava su `logs/` REALE del repo (race con una
  sessione utente concorrente) → test riscritto su **symlink farm** in
  mktemp -d: SCRIPT_DIR resta nella sandbox, log inclusi; repo intatto
  (23 file prima/dopo).
- INFO: tripwire sul mock brew (fail se le run toccano il brew vero), assert
  di isolamento, trap INT/TERM che ESCE (prima continuava senza sandbox),
  commenti di copertura, riga CHANGELOG sui segnali.
- INFO (solo doc): figlio ucciso da segnale → script(1) riporta il numero
  GREZZO (Ctrl+C → 2, indistinguibile da "unknown token" per un caller); non
  è regressione (prima: 0) e non si mappa in codice.

## Verifica
`make test` 102/102 (87+9+6). Dal vivo (brew reale): `99`→2, `8 --dry-run`→0,
`--dryrun`→2. Suite nuova: 6 check (2 through-the-wrapper, 1 parent-side,
1 non-regressione happy path, tripwire, isolamento).

## Esito
Metà PARENT di Attenzione #4b **CHIUSA**; metà moduli (return contract, BM-18)
resta aperta col suo trigger. In attesa di integrazione; poi task 2 (release
v1.3.0).

## Collegamenti
[[STATE]] · [[core-brew-manager]] · [[sessions/2026-07-18-readme-v1.3.0]] ·
[[LEARNINGS]] (IMP-002: il caso che ha originato questo fix)
