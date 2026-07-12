---
type: index
updated: 2026-07-12
tags: [moc]
---
# INDEX — memoria persistente brew-manager (MOC)

> **Cos'è questo file.** La mappa dei contenuti (Map Of Content) della memoria.
> [[STATE]] è il punto d'ingresso operativo (iniettato dall'hook); da qui invece
> si naviga tutto il resto. La cartella `.claude/` è pensata per aprirsi anche
> come vault Obsidian: i wikilink `[[...]]` generano il graph view, ma funzionano
> comunque come semplici rimandi in qualsiasi editor.

## Stato
- [[STATE]] — stato corrente: avanzamento, decisioni, debito doc, problemi aperti
- [[TREE]] — struttura del repository (rigenerata, mai editata a mano)
- [[LEARNINGS]] — backlog dei miglioramenti di processo (IMP): vuoto alla nascita
  (le IMP del framework non si ereditano; qui si parte da 001)

## Per componente
- [[core-brew-manager]] — entry point TUI, dispatch, recording (sensibile)
- [[lib-common]] — utility TUI + guard-rail condivisi `_ask`/`_read_choice` (sensibile)
- [[mod-00-audit]] — audit/adozione app non gestite (sensibile; bug off-by-one noto)
- [[mod-05-cleanup]] — autoremove+cleanup (sensibile; senza conferma né dry-run)
- [[mod-bk-brewfile]] — backup/restore Brewfile+agenti (sensibile; bug weekday)
- [[mod-las-scheduler]] — LaunchAgent scheduler (sensibile; dipende dal bug CLI)
- Gli altri 12 moduli (read-only o a rischio basso/medio) non hanno ancora una
  nota: si crea alla prima modifica sostanziale (vedi components/README).

## Per fase (sessioni — append-only)
- [[sessions/2026-07-11-innesto-note]] — innesto del framework v0.2.0: assessment
  brownfield, frizioni per la futura IMP-027 del framework
- [[sessions/2026-07-12-bm01-dev-checks]] — BM-01: make lint advisory (check
  esisteva già); test RED/GREEN su check e stub shellcheck

## Decisioni
- [[2026-07-12-trunk-based-su-main]] — trunk-based su main; origin/dev dormiente
- [[2026-07-12-componenti-sensibili]] — criterio "raggio di impatto sul Mac" e
  elenco dei sei componenti nel gate
- [[2026-07-12-shellcheck-advisory]] — make lint advisory: shellcheck non ha
  dialetto zsh, il gate di sintassi resta zsh -n

## Piani
- [[plans/roadmap-v2]] — backlog atomizzato post-innesto (BM-01…BM-20: fix
  sicurezza M1, resolver di selezione M2, TUI M3, feature M4, doc M5). Status:
  in attesa — parte DOPO l'integrazione del branch di innesto (precondizione 1
  del piano stesso); un task per volta, ok utente tra un task e il successivo.
