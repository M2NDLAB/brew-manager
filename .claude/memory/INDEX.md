---
type: index
updated: 2026-07-21
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
- [[LEARNINGS]] — backlog dei miglioramenti di processo (IMP): IMP-001 APPLICATA;
  7 proposte APERTE — IMP-002 (checklist test di estrazione), IMP-003 (mai echo su
  dati, rafforzata da BM-09), IMP-004 (chiudi la CLASSE: grep tutti i siti +
  verifica adversariale), IMP-005 (controllo terminale gata su TUI_TTY, non solo
  colore — BM-09), IMP-006 (review-workflow su un git-range: isola gli agenti o
  vietali dal checkout — BM-10, Destinazione: framework), IMP-007 (smoke moduli =
  selezione CLI, mai pipe sul prompt né head sull'output — BM-11/BM-12), IMP-008
  (lente di gate "affermazioni, non solo azioni" — BM-12, Destinazione: framework)

## Per componente
- [[core-brew-manager]] — entry point TUI, dispatch, recording (sensibile)
- [[lib-common]] — rendering TUI capability-aware + guard-rail condivisi
  `_ask`/`_read_choice` (sensibile; layer detection/palette/box dal BM-09)
- [[lib-selection]] — registry moduli + `_resolve_selection` (sensibile; dal BM-08a)
- [[mod-00-audit]] — audit/adozione app non gestite (sensibile; bug off-by-one noto)
- [[mod-05-cleanup]] — autoremove+cleanup (sensibile; dry-run e conferma
  `_ask_danger` presenti da BM-02/BM-10 — la vecchia nota "senza conferma" era stale)
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
- [[sessions/2026-07-17-bm08b-positional-dispatch]] — BM-08b: dispatch posizionale
  + `--only`/`--skip` (API stretta `_resolve_cli`), 74 test, gate con 2 MEDIUM
  fail-open del tokenizer fixati (escape/newline), IMP-003 registrata
- [[sessions/2026-07-17-bm08c-agent-selection]] — BM-08c (chiude M2): agenti via
  resolver + consenso fail-closed (NON_INTERACTIVE ≠ YES_MODE). Il 1° fix #8 fu un
  CRITICAL preso dal gate → rifatto; re-gate trovò il gemello bk. IMP-004
- [[sessions/2026-07-17-framework-upgrade-v0.2-to-v0.5.1]] — upgrade dell'innesto
  framework v0.2.0 → v0.5.1 (solo processo): 3 classi di file, invariante memoria = 2
  file, hooks-install 3-vie per-versione con verifica funzionale reale, pacchetto harvest
  (R3), docs/01 omesso (R4), rimandi orfani potati (R1)
- [[sessions/2026-07-18-readme-v1.3.0]] — README ↔ realtà di v1.3.0 (task 1
  pre-release): scheduler per-modulo e fail-closed documentati; 2 claim corretti
  dalla verifica dal vivo (exit del parent perso in script(1), default `y` del
  cleanup sotto `--yes`); IMP-002 rafforzata (exit end-to-end)
- [[sessions/2026-07-18-exit-code-propagation]] — micro-task pre-release: il
  parent propaga l'rc del figlio (chiusa la metà parent di #4b; scope solo-A
  deciso dall'utente); gate adversariale 0 C/H/M, 2 LOW applicati (warning
  strip, test in sandbox symlink-farm); 102 test
- [[sessions/2026-07-18-release-v1.3.0]] — release v1.3.0 (VERSION + CHANGELOG
  "scheduler release"); verificata da clone pulito con tag simulato;
  **RILASCIATA 2026-07-18**: merge c6c80c0, tag annotato v1.3.0 pushato
- [[sessions/2026-07-19-bm09-tui-foundation]] — BM-09 (M3, primo task): rendering
  capability-aware in lib/common.sh (detection colore/Unicode, handoff parent→child,
  palette semantica, degradazione ASCII puro, primitivi box/clear); 0 moduli
  toccati; gate adversariale passato (1 LOW LC_ALL fixato + hardening echo-on-data);
  30 test nuovi, 132 totali; IMP-005 registrata
- [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]] — upgrade dell'innesto
  framework v0.5.1 → v1.0.0 (solo processo, attraversa la 1.0): docs/04 (+criterio
  MAJOR e **contratto pubblico di brew**, moduli CONGELATI), lint-memory (+controllo
  11, caso-limite 7), CLAUDE.md (+test-scripts), scripts/README, retrofit del pin;
  invariante memoria VUOTA; bump "nessun tag"
- [[sessions/2026-07-20-bm10-risk-badges]] — BM-10 (M3, 2° task): risk badge
  `[RO]`/`[W]`/`[!]` + cornici di conferma distruttiva. `MODULE_RISK` (classificazione
  verificata adversarialmente) + `_risk_badge`/`_about_risk` + `_ask_danger` (box →
  `_ask` INTATTO). Badge nel menu/18 About; 9 cornici (las escluso). Presentazione
  pura. Gate PASSATO (5 lenti, 0 finding); 170 test. Incidente git-thrashing del
  gate → IMP-006. INTEGRATO in main (merge `2dd1f7c`)
- [[sessions/2026-07-20-bm11-menu-redesign]] — BM-11 (M3, 3° task): banner flat +
  menu a card allineate (mockup A/B → decisione utente: flat + footer 3 righe).
  `MODULE_NAME` + sottotitoli MODULE_DESC (chiavi congelate) + test_menu_registry
  (layout 80-col = invariante di dati); `_header_main` rimossa. Gate PASSATO
  (0 finding); 178 test. Lezione smoke-via-pipe → IMP-007. INTEGRATO in main
  (merge `2e61180`)
- [[sessions/2026-07-21-bm12-progress-summary]] — BM-12 (M3, 4° e ULTIMO task):
  spinner gated su TUI_TTY (era morto in pratica) + summary di sessione. Gate a 2
  lenti: comportamento pulito ma **4 difetti di verità** — attestava "preview,
  nothing changed" per moduli senza gate dry-run → `MODULE_DRYRUN` + `_run_status`
  + stato `⚠ ran anyway`; spinner che inondava il log → strip a semantica CR;
  secondi sotto-riportati; riga disco che poteva mentire. 247 test. → IMP-008.
  **M3 COMPLETA**; in attesa di integrazione, poi release v1.4.0

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
- [[2026-07-17-consent-vs-noninteractive]] — BM-08c: NON_INTERACTIVE (anti-blocco)
  separato da YES_MODE (solo --yes); "non c'è tty" ≠ consenso

## Piani
- [[plans/roadmap-v2]] — backlog atomizzato post-innesto (BM-01…BM-20: fix
  sicurezza M1, resolver di selezione M2, TUI M3, feature M4, doc M5). Status:
  **M1 CHIUSO** (v1.2.0 rilasciata); **M2 CHIUSO** e **v1.3.0 RILASCIATA**
  (2026-07-18). **M3 AVVIATO**: BM-09 (fondazione TUI) **INTEGRATO in main**
  (merge `5867137`); **BM-10** (badge di rischio) **COMPLETATO** su `feat/risk-badges`
  (gate passato, 170 test), in attesa di integrazione. Fuori roadmap: **upgrade
  framework v0.5.1 → v1.0.0** + riconciliazione memoria **INTEGRATI in main** (merge
  `765bad4`). Prossimo: STOP, decisione utente su BM-11/12 (giudizio estetico).
- [[plans/bm10-risk-badges]] — piano di BM-10 (5 task), status: completed.
