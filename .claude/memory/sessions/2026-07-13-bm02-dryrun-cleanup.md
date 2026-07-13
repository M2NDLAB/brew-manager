---
type: session
date: 2026-07-13
status: completed
branch: fix/dryrun-cleanup
tags: [session, roadmap-v2, bm-02, security-gate]
---
# BM-02 — mod_05_cleanup onora --dry-run (sensibile ALTO, security gate)

## Fatto
- Riallineamento post BM-01: merge 3d3af76 su main (utente); registrato il commit
  manuale 9b7e874 (SLA rimossi da SECURITY.md, subject placeholder da NON toccare).
- Branch `fix/dryrun-cleanup`; commit e1248d3 (riallineamento memoria) e 2fcb1f8
  (fix). Gate: `(( BREW_MANAGER_DRY_RUN ))` → preview con `brew autoremove
  --dry-run` + `brew cleanup -s -n` (exit code gestiti, output stampato inerte
  con printf %s); path reale dietro `_ask` default "y" (in --yes identico a oggi;
  interattivo richiede y esplicita). Dry-run PREVALE su --yes.
- Test: matrice stub-brew 6 path (dry/yes/y/Enter/n/dry+yes) — chiamate mutanti
  solo dove attese; caso brew-fallisce → warning onesti; caso escape-injection
  (`\e]0;PWNED\a` nei dati) → zero byte ESC emessi; E2E con brew reale in dry-run
  → cache byte-identica (4.832.692 KB), preview con stima ~758 MB.

## Security gate (docs/03) — esito
Review multi-agente adversariale (3 lenti + refuter). DEGRADATA: 19/31 agenti
falliti (stalli + limite sessione); le voci non verificate sono state rigiudicate
manualmente sul codice. Nessun HIGH/CRITICAL confermato.
- RISOLTI in-perimetro (codice nuovo): exit code brew ignorati nel preview (LOW);
  output brew interpretato da echo -e → printf %s inerte (LOW); wording About
  onesto sul path --yes (LOW).
- ACCETTATI come debito (core, fuori perimetro — vedi STATE Attenzione #8/#9):
  YES_MODE auto-detect perso nel re-exec script(1) (MEDIUM); flag ignoti/typo
  silenziosamente ignorati dal parser (MEDIUM, pre-esistente).
- REFUTATI dai verificatori o rigiudicati: valori non-numerici di DRY_RUN
  (irraggiungibile via launcher), sink aritmetico via env (richiede attacker
  locale), no-op in YES_MODE (by design), duplicato HIGH del MEDIUM #8.

## Problemi → causa → soluzione
- Prima run E2E via pipe in timeout → `script(1)` non inoltra lo stdin in pipe
  alla read della TUI → selezione moduli impossibile in non-TTY (conferma
  Attenzione #1); test (a) del piano ineseguibile come scritto → registrato,
  NON aggirato (perimetro): equivalente di sostanza a livello funzione.
- Il processo orfano della run bloccata è stato terminato (pkill mirato).

## Correzioni fattuali doc
- Nessuna.

## Proposte IMP
- Nessuna registrata (i due debiti core sono candidati micro-task, decisione utente).

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- Proposto all'utente il micro-fix core (1 riga: auto-detect non-TTY che
  sopravvive al re-exec) — sua decisione se task dedicato o dentro BM-08c.
- Prossimo task: BM-03 (fix/dryrun-bk-restore) dopo ok utente su BM-02.
