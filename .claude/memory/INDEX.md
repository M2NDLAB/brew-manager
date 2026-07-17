---
type: index
updated: 2026-07-17
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
- [[LEARNINGS]] — backlog dei miglioramenti di processo (IMP): IMP-001 APPLICATA
  (review-agent in allow-list); 1 proposta APERTA (IMP-002, checklist superficie
  del contratto per i test di estrazione/parità)

## Per componente
- [[core-brew-manager]] — entry point TUI, dispatch, recording (sensibile)
- [[lib-common]] — utility TUI + guard-rail condivisi `_ask`/`_read_choice` (sensibile)
- [[lib-selection]] — registry moduli + `_resolve_selection` (sensibile; dal BM-08a)
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
- [[sessions/2026-07-13-bm02-dryrun-cleanup]] — BM-02: gate dry-run+conferma in
  mod_05; security gate passato; scoperta script(1)/stdin; debiti core #8/#9
- [[sessions/2026-07-13-microtask-parser-flags]] — micro-task: parser rifiuta
  flag ignoti + lookalike Unicode; chiusa Attenzione #9; IMP-001 registrata
- [[sessions/2026-07-13-bm03-dryrun-bk-restore]] — BM-03: dry-run nel restore
  bk (preview statica, [3a] con conferma); IMP-001 applicata; disclosure falso
  PASS S7 di BM-02 → debito 3b
- [[sessions/2026-07-13-bm04-adopt-off-by-one]] — BM-04: off-by-one + canale di
  selezione morto su tutte le release (2 HIGH del gate risolti); RED→GREEN
  contro main; lezione harness-come-launcher
- [[sessions/2026-07-13-bm05a-weekday-migration]] — BM-05a: weekday mapping +
  migrazione plist legacy; gate in 2 round (4 HIGH: XML injection, collasso
  multi-intervallo, Modify che perdeva il conf, heredoc bk non validato)
- [[sessions/2026-07-13-bm05b-mod09-counter]] — BM-05b: contatore mod_09 (+1);
  ultimo off-by-one; lezione sul contare l'output di una TUI
- [[sessions/2026-07-14-bm06-greedy-scope]] — BM-06: scope per-cask del greedy,
  exit code, dry-run mai esistito; gate: --cask mancante in outdated, token
  flag-shaped, streaming perso e riguadagnato con pipestatus
- [[sessions/2026-07-14-bm07-version-deadcode]] — BM-07: VERSION + --version
  (non esisteva) + rimozione codice morto → **M1 CHIUSO**
- [[sessions/2026-07-14-bm19-readme-reality]] — BM-19 ristretto: README ↔ realtà
  di v1.2.0, over-claim rimossi (CLI posizionale, scheduling per-modulo)
- [[sessions/2026-07-14-release-v1.2.0]] — release v1.2.0: VERSION+CHANGELOG,
  version-check simulato col tag in un clone; tag e push all'utente (RILASCIATA
  2026-07-17: merge c5dc3a5, tag annotato v1.2.0)
- [[sessions/2026-07-17-bm08a-selection-resolver]] — BM-08a: estrazione
  `_resolve_selection` in lib/selection.sh, nascita dei test (43 check), gate
  adversariale passato (5 finding test-adequacy risolti), IMP-002 registrata

## Decisioni
- [[2026-07-12-trunk-based-su-main]] — trunk-based su main; origin/dev dormiente
- [[2026-07-12-componenti-sensibili]] — criterio "raggio di impatto sul Mac" e
  elenco dei sei componenti nel gate
- [[2026-07-12-shellcheck-advisory]] — make lint advisory: shellcheck non ha
  dialetto zsh, il gate di sintassi resta zsh -n
- [[2026-07-14-versione-fonte-unica]] — file VERSION autorevole + git describe
  come arricchimento + make version-check anti-drift
- [[2026-07-17-selection-resolver-contract]] — BM-08a: home lib/selection.sh,
  contratto ad array globale (non stdout), return 0/1, harness zsh (no bats)

## Piani
- [[plans/roadmap-v2]] — backlog atomizzato post-innesto (BM-01…BM-20: fix
  sicurezza M1, resolver di selezione M2, TUI M3, feature M4, doc M5). Status:
  **M1 CHIUSO** e v1.2.0 rilasciata; **M2 in corso** — BM-08a COMPLETO (in attesa
  di integrazione), prossimo BM-08b. Un task per volta, ok utente tra i task.
