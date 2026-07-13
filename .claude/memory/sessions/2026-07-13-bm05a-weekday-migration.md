---
type: session
date: 2026-07-13
status: completed
branch: fix/weekday-shift
tags: [session, roadmap-v2, bm-05a, security-gate]
---
# BM-05a — weekday mapping + migrazione plist legacy (sensibile ALTO, gate)

## Fatto
- Commit c5c4539 su mod_las_scheduler.sh + mod_bk_brewfile.sh.
- **Fix mapping**: `_weekday_name(weekday+1)` (array zsh 1-based) in install,
  multi-install, re-register orfani, recreate dangling e restore agenti di bk
  (loop `{1..7}` con wd=i-1). Su main: weekly scriveva nome giorno VUOTO, Sun→Mon
  al restore, Sat degradava a daily.
- **Migrazione legacy** (in scope per direttiva utente): l'integrity check [6] ha
  una terza sezione che rileva coppie conf+plist TRACCIATE con dati legacy o
  corrotti (modules storpiati dal vecchio `tr -d` — '--ye', 'go'→'o' — che col
  parser severo fanno uscire l'agente con exit 2 a ogni run; e nome giorno del
  conf divergente dal Weekday del plist) e offre la riparazione [r]: rigenera
  conf+plist dal plist (source of truth) con valori sanificati.
- **Estrazione riscritta**: `_plist_int` legge il primo `<integer>` dopo una chiave
  ANCORATA (`<key>X</key>`); prima `grep -A1 | tr -cd 0-9` concatenava interi
  adiacenti ('2'+'9'→'29') ed era la radice dei dati storpiati.
- Fix collaterali: Modify [4] non cancella più il conf prima dell'install (con
  input invalido si perdeva il tracking); log MODIFIED gated su dry-run; validazione
  weekday/ora/minuto; suffisso custom con shape-check; `_install_agent` ritorna 1
  su rifiuto e su load fallito; MIGRATED loggato solo dopo successo.

## Security gate (docs/03) — esito: 2 round
Round 1 (2 lenti): **gate_holds=false** — 3 problemi seri:
- HIGH: `_sanitize_agent_modules` bloccava solo i valori flag-shaped → metacaratteri
  XML da un bundle non fidato finivano RAW nell'heredoc del plist (injection
  strutturale: es. `RunAtLoad true`). → RISOLTO con grammatica whitelist
  (`^[0-9A-Za-z]+(,[0-9A-Za-z]+)*$`) + shape-check di label e suffisso.
- HIGH: migrazione/restore distruttivi sui plist MULTI-INTERVALLO (`_plist_int`
  head -1 collassava Mon+Wed+Fri a un solo giorno, o a daily = 7 run/settimana).
  → RISOLTO: `_plist_weekday_count` e guard `*+*`; i multi-day vengono SALTATI con
  warning in re-register, legacy-detect, dangling-recreate e restore bk.
- HIGH (regressione mia): Modify [4] cancellava il conf PRIMA della nuova
  validazione → input invalido = agente orfano silenzioso. → RISOLTO.
Round 2 (verificatore finale): HIGH-3 confermato risolto, ma **HIGH residuo**
trovato: `_restore_agents` di bk ha un heredoc PROPRIO e non validava ora/minuto
→ stesso vettore di injection via campo orario del bundle. → RISOLTO (clamp ai
default). Chiusi anche il MEDIUM (dangling-recreate multi-day → daily) e il LOW
(la grammatica troppo stretta degradava a 'go' i moduli named/maiuscoli come
'LAS', trasformando un agente mirato in un `go` completo).

## Test
Harness con `launchctl` stub, HOME e SCRIPT_DIR finti (zero LaunchAgent reali —
su questo Mac non ce ne sono: verificato). RED→GREEN contro main per Sun/Mon/Sat;
migrazione di plist legacy SIMULATI (orfano senza modules; coppia corrotta
'--ye' + giorno divergente); dry-run [6] → rilevazione senza alcuna scrittura;
payload di injection (XML in modules, in label, nel campo orario) → neutralizzati
byte-per-byte; multi-interval → mai riscritto; regressione finale 9/9 verde su
install weekly/daily/custom, modify, remove all, integrity, restore bk.

## Problemi → causa → soluzione
- Il primo giro di hardening ha introdotto una regressione (Modify che perde il
  conf): lezione — validare PRIMA di distruggere; il gate l'ha intercettata.
- Il verificatore finale ha trovato un HIGH che le due lenti del round 1 avevano
  mancato (heredoc duplicato in bk): conferma il valore del round di verifica
  separato su un diff già "corretto".

## Correzioni fattuali doc
- CHANGELOG aggiornato.

## Proposte IMP
- Nessuna nuova.

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- Debito residuo (INFO, registrato in STATE): la preview del restore agenti non
  rispecchia gli skip di label invalida e multi-day (solo quelli dei modules).
- Prossimo: BM-05b (fix/mod09-counter) dopo ok utente.
