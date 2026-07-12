---
type: session
date: 2026-07-12
status: completed
branch: chore/dev-checks
tags: [session, roadmap-v2, bm-01]
---
# BM-01 — target di verifica shell nel Makefile

## Fatto
- Precondizioni roadmap verificate: innesto integrato in main (7893f87) dall'utente,
  tag annotato `v1.1.2-baseline` presente, working tree pulito.
- Branch `chore/dev-checks`; commit f1a5063
  `chore(build): add zsh -n and optional shellcheck targets`.
- Scope reale RIDOTTO rispetto al piano: `make check` esisteva già dall'innesto
  (commit 3a463ac) — implementato solo `make lint` advisory + documentazione.
- Test eseguiti (tutti PASS): check verde sullo stato attuale; check FALLISCE
  (exit 2) su modulo con errore di sintassi iniettato e rimosso; lint skip pulito
  senza shellcheck (exit 0); lint con stub-shellcheck che trova finding → nota
  advisory, exit 0; lint con stub pulito → exit 0; riesecuzione idempotente.

## Problemi → causa → soluzione
- "shellcheck pulito dove installato" (regola trasversale roadmap) impossibile
  alla lettera → shellcheck non ha dialetto zsh → lint advisory, gate = zsh -n.
  Decisione: [[2026-07-12-shellcheck-advisory]].

## Correzioni fattuali doc
- Nessuna (Makefile documentato contestualmente).

## Proposte IMP
- Nessuna registrata. Segnalato all'utente il disallineamento driver ("decisioni
  in LEARNINGS.md") vs framework (decisioni in decisions/, LEARNINGS = solo IMP):
  in attesa di sua indicazione.

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- Prossimo task da roadmap: BM-02 (fix --dry-run in mod_05_cleanup) — SOLO dopo
  ok utente sull'integrazione di BM-01.
