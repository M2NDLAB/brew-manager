---
type: session
date: 2026-07-19
branch: chore/framework-upgrade-v1.0.0
tags: [session, framework, upgrade, process, versioning, breaking-change]
---
# Upgrade dell'innesto claude-code-framework v0.5.1 → v1.0.0

Secondo upgrade reale dell'innesto, con la procedura formale *"Aggiornare il framework su un
progetto già innestato"* (SETUP.md del framework). Attraversa la **prima release stabile del
framework** (caso-limite 5). Baseline di partenza **v0.5.1** — accertata per contenuto
(innesto e primo upgrade pre-pin) e poi FISSATA dal retrofit del pin in chiusura. Solo layer
di PROCESSO toccato; memoria di progetto preservata. Assessment read-only pre-approvato
dall'utente (FASE 1). SHA pre-upgrade `5867137`.

## Superficie (4 classi di file)
- **METODO** (porta a v1.0.0): `scripts/README.md` — identico alla baseline → overwrite
  pulito (+riga `test-hooks-install.sh` + uso `make test-scripts`, allineamento doc v0.6.1;
  sana un drift d'inventario preesistente di brew).
- **IBRIDO** (riconciliati a 3 vie, base=v0.5.1):
  - `docs/04` — importato il blocco "breaking change / criterio del MAJOR" e riformulato il
    riquadro 1.0.0 (IMP-039), preservate le 3 personalizzazioni di brew (preambolo
    trunk-based, scelta `/integrate`, allow-list zsh).
  - `commands/lint-memory` — RECONCILE, non overwrite: +controllo 11 "Inventari vs realtà"
    (IMP-038) PRESERVANDO la potatura brew dei rimandi orfani a `SETUP.md` nel controllo 10.
    È il **caso-limite 7** (file METODO personalizzato inline): colto dal baseline-diff
    contro v0.5.1, che ha impedito un overwrite cieco.
  - `CLAUDE.md` — +riga `make test-scripts` nei Comandi rapidi (+1 upstream).
- **QUARTA — stato dell'innesto**: creato il provenance pin `.claude/framework-version`
  (`version 1.0.0` · `commit e3f1f51` · `grafted n/d (retrofit 2026-07-19)`), FUORI da
  `memory/` per costruzione (retrofit: innesto pre-IMP-036).
- **MEMORIA-DI-PROGETTO** (intatta): tutta `.claude/memory/`. `LEARNINGS.md` **byte-identico**
  — formato/header invariati upstream, quindi nessun sync (a differenza dell'upgrade
  v0.2→v0.5.1, dove l'header cambiò).
- **Invariata** (delta upstream ZERO, nessuna azione): `docs/00·01·02·03·05·06`, gli altri
  comandi, `settings.json`, `hooks-install.sh`, `Makefile`, `.gitignore`,
  `commitlint.config.cjs`. Doc di prodotto di brew (`README`/`SECURITY`/`CHANGELOG`) NON
  toccate (nota di chiusura della procedura: non sovrascriverle col template del framework).

## Fatto (4 commit su chore/framework-upgrade-v1.0.0)
- `41808f7` riconciliazione dei 4 file metodo/ibridi (marcatore di docs/04 lasciato RAW).
- `c9b8284` compilazione del contratto pubblico in docs/04 (su decisione utente).
- `2668a75` retrofit del provenance pin a v1.0.0.
- (checkpoint) questo commit.

## Decisione dell'utente: il contratto pubblico di brew-manager (criterio del MAJOR)
Il marcatore `[DA DEFINIRE AL SETUP]` del blocco breaking-change è stato compilato con la
superficie che brew-manager promette di NON rompere senza un MAJOR (progetto di codice):
- **Flag CLI** (nomi + semantica), **grammatica di selezione** (posizionale + `--only`/
  `--skip`), **formato plist/LaunchAgent**.
- **Identificatori di modulo CONGELATI** — numeri `0–13`, keyword `go`, nomi speciali
  `bk/las/log/mas`: rinumerare/riassegnare/rinominare = MAJOR; nuovi moduli solo in APPEND.
  Motivo concreto: i numeri sono persistiti nei plist LaunchAgent sui Mac degli utenti
  (`modules=3,5`, rischio #12), riassegnarli cambierebbe in silenzio ciò che un agente già
  installato esegue.
- **Exit-code**: congelati solo i codici garantiti oggi (`0/1/2` dai test e2e); la
  propagazione del fallimento runtime dei moduli (#4b) NON è ancora contratto → entrerà
  come estensione additiva con **BM-18**. Testo specializzato al caso "progetto di codice",
  rimosso l'esempio "metodo/tooling (com'è questo framework)", non pertinente a un cliente.

## Verifiche non negoziabili (esiti)
- **Invariante memoria (Passo 5)**: `git diff 5867137 HEAD -- .claude/memory/` = **VUOTO** a
  zero eccezioni (nessun rename di doc → nessun rimando penzolante; formato LEARNINGS
  invariato → nessun sync header). Il pin vive fuori da `memory/`.
- **Audit marcatori (Passo 4)**: 1 solo slot fillable nuovo (il contratto in docs/04) →
  compilato; gli altri hit sono prosa/falsi-positivi (nota branching pre-esistente in
  docs/04:178, sentinella del controllo 10, prosa del controllo 11, `integrate.md`).
- **Hook (caso-limite 4)**: `make hooks-install` re-run eseguito e dichiarato
  (`hooks-install.sh` ha delta upstream zero → hook funzionalmente identici). `.git/hooks`
  non è tracciato: se il branch viene scartato dopo il re-run, ri-eseguire hooks-install da
  main.
- `make check` rc=0 · `make version-check` OK (VERSION 1.3.0 == v1.3.0) · `make test` rc=0
  (**132 check**: 30+6+9+87).
- **Verifica adversariale indipendente** (FASE 1) dei due claim portanti — accounting
  completo dei file e invariante di memoria a zero — confermati.

## Confine / hand-off
- Nessun merge/push/tag eseguiti (confine di docs/04). Bump prodotto: **nessun tag**
  (upgrade solo-processo = `chore`, non una release di brew). Blocco `/integrate` stampato
  per l'utente. Merge/push = utente.
- **Promemoria**: riportare la sorgente del framework su main
  (`git -C ~/Projects/claude-code-framework checkout main`) — era detached su `v1.0.0`.
- **Impatto su M3 → release**: brew è post-1.0; la prossima release (M3) è additiva → MINOR
  = **v1.4.0** (la TUI non tocca il contratto). Il nuovo criterio MAJOR ora la governa: a
  ogni release verificare i cambiamenti contro il contratto (presentazione ⇒ MINOR).

## Collegamenti
[[STATE]] · [[LEARNINGS]] · [[TREE]] · [[INDEX]] ·
[[sessions/2026-07-17-framework-upgrade-v0.2-to-v0.5.1]] (il primo upgrade) ·
[[sessions/2026-07-11-innesto-note]] (l'innesto originale v0.2.0)
