---
type: plan
prompt: framework-upgrade-v0.2-to-v0.5.1
branch: chore/framework-upgrade-v0.2-to-v0.5.1
created: 2026-07-17
status: in-progress
tags: [plan, framework, upgrade, process]
---
# Piano: upgrade dell'innesto claude-code-framework v0.2.0 → v0.5.1

## Obiettivo
Portare il layer di PROCESSO di brew-manager (docs/, commands/, scripts/, Makefile,
CLAUDE.md) dal framework v0.2.0 a v0.5.1, **preservando intatta la memoria di
progetto**. Rimandi orfani potati a mano (R1), pacchetto harvest adottato completo
(R3), blocco meta-framework di docs/01 omesso (R4). SHA pre-upgrade: `b929a23`.
Bump prodotto: **nessun tag** (upgrade solo-processo = `chore`). Merge/push/tag =
utente. Assessment FASE 1: [[sessions/... TBD]] · procedura: SETUP.md §upgrade del
framework v0.5.0.

## Decisioni dell'utente (dentro il piano)
- **R1**: dove un doc-metodo aggiornato rimanda a file che brew NON ha (SETUP.md,
  CONTRIBUTING.md, README "Filosofia", numeri IMP del framework), si POTA/RIFORMULA
  a mano, file per file — niente wikilink penzolanti.
- **R3**: pacchetto harvest COMPLETO — `harvest-framework.md` + sezione "ponte" in
  docs/06 + attributo `Destinazione: framework` nell'HEADER/formato di LEARNINGS.
  **Mai** toccare le voci IMP-001…004 di brew.
- **R4**: blocco IMP-034 (regime ibrido) di docs/01 OMESSO per intero — entrambi
  gli hunk sono framework-repo-specifici, nessuna patch generale da salvare.
  Omissione annotata nella nota di sessione.
- **R5**: i due marcatori `[DA DEFINIRE AL SETUP]` spezzati (docs/04:142,
  integrate.md:16) si ricompattano da soli applicando l'upgrade v0.3.0 di quei
  file; sono generici/runtime, NON si compilano con un valore.

## Task (un commit ciascuno)
- [x] 0. Isolamento (worktree/branch) + questo piano — commit: 6c10e89
- [x] 1. Riconciliazione doc/comandi v0.3.0 + fix marcatori R5 (integrate.md base-guard,
      docs/03 3-vie + poda SETUP, docs/04 3-vie, lint-memory.md controllo 10 + poda) — commit: 1bf77eb
- [x] 2. Bundle hooks-install (3-vie per-versione v0.3.0+v0.5.1) + scripts/README +
      test-hooks-install.sh + Makefile test-scripts + VERIFICA FUNZIONALE REALE — commit: (questo)
- [ ] 3. Pacchetto harvest lato metodo (docs/06 + poda R1, harvest-framework.md + poda,
      CLAUDE.md +/harvest-framework) — commit: —
- [ ] 4. LEARNINGS header: attributo Destinazione:framework (eccezione memoria isolata,
      MAI le voci IMP) — commit: —
- [ ] 5. Passo 4/5: audit marcatori + INVARIANTE memoria (git diff mostrato) + /lint-memory
      + make check/test — commit: —
- [ ] 6. Passo 6: /checkpoint (STATE→v0.5.1, nota sessione, TREE) + blocco /integrate (no tag) — commit: —

## Verifiche non negoziabili (condizioni dell'utente)
- **Task 2**: DIMOSTRARE post-upgrade — secret finto → bloccato; commit
  non-conventional → rifiutato; commento shfmt-zsh sopravvissuto; hook idempotenti.
  Se non dimostrabile → fermarsi e segnalare.
- **Task 5**: `git diff b929a23 -- .claude/memory/` MOSTRATO all'utente. Deve essere
  ESATTAMENTE due file: `plans/framework-upgrade-v0.2-to-v0.5.1.md` (nuovo, task 0) +
  `LEARNINGS.md` (solo header/commento, task 4). Qualsiasi altro file memory/ nel
  diff = bug dell'upgrade → fermarsi, NON chiudere.

## Cosa NON si tocca (e perché)
- docs/01 → omesso (R4). settings.json, .gitignore, reset-task.sh, checkpoint.md,
  new-component.md, docs/00, docs/02 → ibridi/personalizzati ma fw-invariati:
  nessuna azione, mai sincronizzati col template. docs/05, retro/security-review/sos,
  commitlint.config.cjs → già identici a v0.5.1.
- Tutta .claude/memory/ tranne le due eccezioni enumerate (Task 5).

## Note di ripresa
- Framework a v0.2.0 e v0.5.1 disponibile in un clone temporaneo (fuori dal repo).
  Il "cosa è cambiato" si deriva LÌ (CHANGELOG come indice + `git diff v0.2.0 v0.5.1`
  scoped ai path di METODO), mai nel progetto.
- hooks-install: riconciliare guardando v0.3.0 e v0.5.1 SEPARATAMENTE (caso-limite 6),
  il fix v0.5.1 è innestato dentro il ramo FORCE_OVERWRITE introdotto in v0.3.0.
- Confine: agente prepara e committa in locale; merge/push/tag = utente.

## Collegamenti
[[STATE]] · [[LEARNINGS]] · [[lib-common]]
