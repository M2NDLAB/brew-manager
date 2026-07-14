---
type: session
date: 2026-07-14
status: completed
branch: refactor/version-deadcode
tags: [session, roadmap-v2, bm-07, m1-chiuso]
---
# BM-07 — versione a fonte unica + codice morto (ultimo task di M1)

## Fatto
- Commit 3a35309. **Chiude M1.**
- **Versione**: file `VERSION` autorevole + `git describe` come arricchimento +
  `make version-check` anti-drift. Scelta approvata dall'utente dopo aver
  verificato i fatti (tarball GitHub senza `.git`) →
  [[2026-07-14-versione-fonte-unica]].
- **`--version` / `-V` non esisteva affatto** (il piano lo dava per scontato nei
  criteri): implementato, risponde PRIMA di qualunque side effect (niente
  directory `logs/`, niente check Homebrew, niente TUI) e funziona anche senza
  git né brew installati. La versione ora compare anche nell'header della TUI,
  dove non era mai stata mostrata (la costante era definita ed esportata ma non
  visualizzata da nessuna parte).
- **Codice morto**: rimossa `_install_agent_multi` (108 righe, mai raggiungibile
  dal menu). Header interni: `mod_las_scheduler.sh` si dichiarava
  `mod_15_scheduler.sh` e `mod_mas_mas.sh` si dichiarava `mod_16_mas.sh` →
  corretti; verificato che TUTTI i 18 header ora coincidono col nome file.

## Test di non-regressione
- `--version` nel repo → `brew-manager 1.1.2 (v1.1.2-38-gcb234fd-dirty)`;
  da un tarball senza `.git` (working tree copiato) → `brew-manager 1.1.2`;
  senza brew nel PATH → funziona; senza file VERSION → `unknown`, nessun crash.
- `make version-check`: GREEN con VERSION=1.1.2 vs tag v1.1.2; RED (exit≠0) con
  VERSION=9.9.9.
- Flag: `--dryrun` → exit 2 (parser severo intatto); `--dry-run`, `0,4 --yes` →
  parser trasparente come prima.
- Menu: 18 voci, output **identico a main** a parte la riga di versione
  nell'header (diff riga per riga).
- `grep`: zero riferimenti a `mod_15_`/`mod_16_`/`_install_agent_multi`.

## Problemi → causa → soluzione
- Primo test del tarball fatto con `git archive HEAD`: esportava il codice
  COMMITTATO, non il working tree, quindi testavo la versione vecchia (falso
  FAIL). Rifatto copiando il working tree reale.
- `git describe` agganciava il tag helper `v1.1.2-baseline` (più vicino nel
  grafo) → versione fuorviante. Risolto filtrando i soli tag di release; il
  primo filtro (`--exclude '*-*-*'`) non funzionava perché richiedeva tre
  trattini: corretto in `--exclude '*-*'`.

## Follow-up
- **M1 CHIUSO.** Blocco /integrate stampato; merge deciso dall'utente.
- STOP concordato: punto con l'utente sul primo tag di release (v1.2.0 dopo M1
  vs aspettare il resolver M2) PRIMA di procedere. Non iniziare BM-08.
- Alla release: aggiornare `VERSION` e taggare nello stesso commit (il check lo
  impone), e spostare `[Unreleased]` del CHANGELOG sotto la nuova versione.
