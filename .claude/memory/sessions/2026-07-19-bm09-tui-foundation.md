---
type: session
date: 2026-07-19
prompt: BM-09 — fondazione TUI capability-aware
branch: feat/tui-foundation
tags: [session, tui, bm09, sensitive]
---
# BM-09 — Fondazione TUI in lib/common.sh (M3, primo task)

## Cosa è stato fatto
Layer di rendering **capability-aware** in `lib/common.sh` (componente sensibile,
docs/03): l'intera app degrada SENZA rompersi, pilotata da un solo file. Nessun
modulo modificato — i 18 moduli usano le costanti `${C_*}`/`${SYM_*}` (censite: 782
`${NC}`, 358 `${C_GRAY}`…), che ora si risolvono per capacità. Branch
`feat/tui-foundation`, 3 commit (feat `bab07d0` + fix `b2d7b62` + docs `910d551`).

### Detection (funzioni pure, testabili senza tty)
- `_tui_color_level <is_tty> <ncolors>` → 0/1/2/3 (no-ANSI / 16 / 256 / truecolor);
  legge `NO_COLOR` e `COLORTERM` (truecolor|24bit vince). is_tty+ncolors come ARG.
- `_tui_unicode` → 1 se locale UTF-8. **Precedenza POSIX** `LC_ALL > LC_CTYPE >
  LANG` (primo non-vuoto vince), NON unione — vedi finding del gate sotto.
- `_detect_capabilities` popola `TUI_COLOR_LEVEL`/`TUI_UNICODE`/`TUI_TTY`.

### Handoff parent→child (come NON_INTERACTIVE)
Il tool si ri-esegue sotto `script(1)`; il figlio ha una **pty** → `-t 1` è vero e
`tput` mente. Quindi: **detect UNA volta nel parent** (stdout reale) → export
`BREW_MANAGER_TUI_{LEVEL,UNICODE,TTY}` → il figlio (RECORDING) si FIDA dell'handoff.
Un run fresh (non-recording) ri-detecta e ri-esporta SEMPRE → un valore stale in env
non può mai mis-renderizzare una sessione interattiva. Default in mancanza di
handoff = SAFE (no colore / ASCII). Stesso pattern collaudato del consenso.

### Palette semantica + degradazione
- **Livello 0** (pipe/non-tty/NO_COLOR): OGNI costante colore = stringa VUOTA →
  ANSI soppresso **alla fonte** (non solo strippato dal log). È il criterio di
  accettazione più forte.
- **Livello 1** (16 col): palette storica INVARIATA byte-per-byte.
- **256/truecolor**: tinte semantiche (§4.3 roadmap). Alias `C_OK/C_WARN/C_DANGER/
  C_INFO/C_HEADING/C_BRAND/C_ACCENT`; i nomi legacy `C_*` MAPPATI sulla semantica
  (un solo verde ovunque). Strutturali cyan/blue/purple lasciati com'erano (scelta
  da BM-11 se collassarli).
- Simboli/box UTF-8 vs ASCII (`✓⚠✗→─╭╮│` ↔ `+ ! x -> - + + |`), via `TUI_UNICODE`.

### Primitivi nuovi
`_box` (blocco bordato rounded/ASCII, title nel bordo, allineato), `_repeat`,
`_pad`, `TUI_INDENT`, `_clear` (pulisce solo se `TUI_TTY`). `_hline` mappa i glifi
heavy/light in ASCII in locale non-UTF-8.

### Guard-rail INTATTI
`_ask`/`_read_choice`/YES_MODE/NON_INTERACTIVE **byte-identici a main** — cambiano
solo le costanti che interpolano. Le due lenti più a rischio del gate
(consent-invariance, correctness-regression) non hanno trovato NULLA.

### Escape grezzi → palette
Convertiti gli `\033` hardcoded nel brew-missing screen (`brew_manager.sh`) e in
`lib/log.sh` → `NO_COLOR` pulito ovunque. Invariante: **0** `\033` grezzi fuori da
`lib/common.sh` (le definizioni palette). README: nuova sezione "Terminal rendering".

## Security gate (adversariale, docs/03 — autore ≠ giudice)
Workflow: 6 lenti indipendenti + verifica per-finding (mandato di REFUTARE). Esito:
**1 CONFIRMED (LOW), 0 UNCERTAIN, 5 REFUTED**. Nessun HIGH/CRITICAL/MEDIUM →
**gate PASSATO**.
- **CONFIRMED LOW — `_tui_unicode` ignorava la precedenza `LC_ALL`**: unione
  `LANG+LC_ALL+LC_CTYPE` → `LC_ALL=C LANG=…UTF-8` (combo comune CI/cron/`env -i`)
  sceglieva glifi UTF-8 in locale C → `_box` conta i byte di `─` (3) e disallinea i
  bordi (misurato: 76 vs 78 char), mojibake. **Fixato**: precedenza POSIX. Solo
  presentazione (nessun impatto su consenso/dry-run/selezione — confermato).
- **REFUTATO ma HARDENED — `_box` title via `echo -e`** (echo-on-data, IMP-003):
  nessun call site oggi, ma primitivo condiviso per BM-10/BM-11. Chiuso ORA (border
  via `printf %s`), pinnato da un test anti-echo-on-data. → IMP-003 rafforzata.
- Altri refutati (downgrade a INFO/NONE): e2e "vacuo" (ho il controllo positivo),
  C_ORANGE/C_WHITE non pinnati a L1 (aggiunti), duplicati dei due sopra.

## Test — `tests/test_capabilities.zsh` (30 check)
Matrice detection, ladder di degradazione, purezza ASCII fallback, e **end-to-end
"run pipato = zero ESC"** attraverso il vero re-exec `script(1)` (farm symlink +
mock brew, come test_exit_codes). Controllo positivo (colore emesso quando il tier
ce l'ha) → l'e2e non è vacuo. Suite totale **132 verde** (30+6+9+87), `make check`
pulito.

## Scoperta chiave (→ IMP-005)
Il comando `clear` emetteva ANSI di controllo-schermo ANCHE pipato — leak trovato
SOLO dal test e2e. Il colore era gated, il controllo no. Fix: `_clear` gata su
`TUI_TTY` (tty reale), non sul colore (un NO_COLOR interattivo può ancora pulire).
Registrata **IMP-005** (convenzione: ogni sequenza di controllo terminale gata su
`TUI_TTY`; corollario diretto per lo spinner di BM-12).

## Note per i prossimi task M3
- `_box` è pronto per le conferme di pericolo (BM-10) e le card del menu (BM-11).
- La palette semantica RICOLORA i moduli su terminali 256/truecolor (verde/giallo/
  rosso/gray/white/orange). Coerente e voluto; strutturali cyan/blue/purple intatti.
- `_spinner` è morto-in-pratica (RECORDING sempre attivo → path `wait`); BM-12 lo
  riscrive e deve gatare `\r`/cursore su `TUI_TTY` (IMP-005), non solo su RECORDING.
- Il design §4.2 della roadmap usava l'unione `$LANG$LC_ALL` (il bug): l'impl
  corregge la precedenza. Il design resta "proposta, adatta ai gusti".

## Stato
Branch `feat/tui-foundation` (HEAD `910d551`), 3 commit, gate passato, 132 test
verdi. In attesa di integrazione dell'utente (blocco `/integrate`). Poi STOP: la
decisione su BM-10/11/12 è dell'utente.

## Collegamenti
[[lib-common]] · [[core-brew-manager]] · [[plans/roadmap-v2]] · [[LEARNINGS]]
(IMP-003, IMP-005) · [[STATE]]
