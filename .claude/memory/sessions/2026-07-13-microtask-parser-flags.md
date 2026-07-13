---
type: session
date: 2026-07-13
status: completed
branch: fix/parser-unknown-flags
tags: [session, security, micro-task, parser]
---
# Micro-task — parser rifiuta i flag ignoti (STATE Attenzione #9)

## Fatto
- Branch `fix/parser-unknown-flags` da main (BM-02 già integrato, 3ae5d41).
- `brew_manager.sh`: ramo `-*|–*|—*|−*)` nel case del parser → errore su stderr
  + exit 2 per ogni flag non riconosciuto, INCLUSI i lookalike Unicode
  (en/em dash, minus da smart-dash copia-incolla — trovati dalla review
  adversariale come bypass del guard ASCII-only). Posizionali ancora ignorati
  DI PROPOSITO: i plist LaunchAgent li passano come liste moduli (BM-08b).
- Test: 4 typo ASCII → exit 2, zero side-effect (nessun log, header TUI non
  stampato); 4 lookalike Unicode → exit 2; 7 invocazioni valide/posizionali
  (incluso stile plist `0,4 --yes`) → parser trasparente, comportamento
  invariato; exit 2 non collide con gli altri exit code (censiti).

## Security gate (docs/03, core = sensibile)
Review adversariale 2 lenti (refute + regressione), entrambe gate_holds=true.
- MEDIUM (bypass Unicode) → RISOLTO nello stesso branch.
- LOW residui REGISTRATI, non risolti (fuori perimetro): typo nei VALORI
  (`--upgrade=yes` degrada in silenzio a n — fail-safe, omissione non azione)
  → validazione valori in BM-08b; plist legacy con `modules=--ye` (dal
  mangling tr dell'integrity re-register in mod_las, che storpia anche
  go→o) ora fallirebbe con exit 2 a ogni run → sanificazione estrazione in
  ambito las (vicino a BM-05a/integrity).
- INFO accettati: `--`/`-`/flag nudi (--adopt senza =) ora rifiutati (nessuna
  invocazione legittima li usa); mkdir logs/ avviene prima del parser
  (innocuo, riordino opzionale).

## Problemi → causa → soluzione
- Primo workflow di review in stallo (6 retry × 180s per agente) → gli agenti
  invocavano comandi git fuori allow-list (`git -C`, `git show`) e in
  background il prompt permessi non è approvabile → fermato (TaskStop) e
  rilanciato con SOLO Read/Grep e diff inline: 2/2 puliti. → IMP-001 proposta
  in [[LEARNINGS]].
- Falso allarme nei test lookalike (exit=0): il MIO harness espandeva una
  command substitution prima di `$?` clobberandolo → misura corretta → tutti
  exit 2. Lezione: mai `$?` dopo una substitution nella stessa riga.

## Correzioni fattuali doc
- Nessuna.

## Proposte IMP
- IMP-001 registrata (review-agent in background e allow-list) — APERTA.

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- Prossimo: BM-03 (fix/dryrun-bk-restore) dopo ok utente.
