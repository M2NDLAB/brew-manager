---
type: session
date: 2026-07-13
status: completed
branch: fix/adopt-off-by-one
tags: [session, roadmap-v2, bm-04, security-gate]
---
# BM-04 — off-by-one adozione + canale di selezione (sensibile ALTO, gate)

## Fatto
- Commit 430f322 su mod_00 + lib/common.sh + brew_manager.sh (estensioni imposte
  dal gate, vedi sotto). Fix: indice 1-based diretto ([N] mostrato == indice
  array); eco del bersaglio + _ask default y prima di ogni `brew install --cask
  --adopt` (in --yes auto-conferma: flussi documentati invariati); dry-run
  prevale su tutto.
- **Scoperta maggiore**: su TUTTE le versioni rilasciate il canale di selezione
  dell'adozione era MORTO end-to-end, e mascherava l'off-by-one:
  (a) `_read_choice` scriveva l'informativo su stdout → il `$()` del chiamante
  catturava una stringa multilinea con ANSI → nessun `case` matchava mai;
  (b) il launcher esportava `BREW_MANAGER_ADOPT="${ANSWER:-n}"` sempre non-vuoto
  → il ramo override rispondeva sempre "n" → prompt interattivo irraggiungibile.
  Quindi `--adopt=all/1,2` e la selezione interattiva non hanno mai funzionato.
- Fix imposti dal gate (2 HIGH risolti, non negoziabili per docs/03):
  HIGH-1 launcher: export dei valori RAW (vuoto = nessun override; i consumatori
  hanno già i loro default `:-n`); HIGH-2 parsing: whitespace = separatore come
  la virgola ('1 2' non diventa più indice 12 = app sbagliata), dedup dei
  duplicati, warning per token non numerici, "No valid selection" se vuoto.
  LOW risolti: shape-check del token cask in _check_brew_available
  ('--version.app' non può diventare argomento/flag di brew); valori di
  _read_choice emessi con printf %s + `local _rc_response` (aggancio concordato
  del debito 3b: intervento che tocca la lib).

## Security gate (docs/03) — esito
2 lenti (refute+regressione), diff inline, Read-only, 2/2 senza stalli.
- 2 HIGH → RISOLTI nel branch (sopra) e riverificati con la batteria estesa.
- MEDIUM (YES_MODE perso nel re-exec script(1) ora interagisce col nuovo _ask:
  `--adopt=all` SENZA --yes in non-TTY salta le adozioni, fail-closed) → resta
  debito #8 agganciato a BM-08c COME DA DECISIONE UTENTE; interazione annotata.
- INFO pre-esistenti registrati: /tmp/brew_adopt_err.log path fisso (symlink,
  multi-utente) → nuovo punto in Attenzione; README riga ~101 "without asking"
  da riallineare in BM-19.

## Test (stub brew/mdfind, ~/Applications finta con 3 app + '--version.app')
RED su versione main: selezioni 1 e 2 → zero install (canale morto, bug
dimostrato). GREEN su branch: [1]→appone, [2]→appthree, [3]→apptwo (mappa
esatta tabella→install); '1,3' e 'all' corretti; '1 2' → app 1 E 2; '1,1' →
dedup; 'x,2' → warn + app 2; '1;3' → "No valid selection"; dry+all+yes → zero
install con preview "would adopt" ×3; interattivo senza flag: prompt visibile,
'2'+'y' → adozione giusta, 'n' → skip; '--version' mai adottabile né installato.

## Problemi → causa → soluzione
- Il mio primo harness aveva mascherato HIGH-1 settando ADOPT="" a mano (il
  launcher reale non lo faceva mai) → lezione: gli harness devono replicare
  l'ambiente del LAUNCHER, non quello ideale. Batteria corretta e ri-eseguita.

## Correzioni fattuali doc
- CHANGELOG aggiornato (fix + funzionalità --adopt di fatto mai funzionante).

## Proposte IMP
- Nessuna nuova.

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- Prossimo: BM-05a (fix/weekday-shift + migrazione plist legacy) dopo ok utente.
