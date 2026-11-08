---
type: component
component: mod-00-audit
updated: 2026-11-08
tags: [component]
---
# mod-00-audit (modules/mod_00_audit.sh)

Audit delle app in /Applications e ~/Applications non gestite da Homebrew, con
adozione opzionale via `brew install --cask --adopt`. SENSIBILE (installa e adotta).

## Stato attuale
~~Funzionante ma con difetti noti (sotto). Nessun test.~~ — **stale, corrected on
2026-11-08** (Level 1, `/fw:lint-memory`): the two known defects below were fixed in BM-04
(`430f322`, 2026-07-13). No suite of its own: `tests/test_risk_badges.zsh` checks that its
confirmations are `_ask_danger`, and `tests/test_guardrails.zsh` pins the consent at
`_ask`'s level.

## Cosa espone / responsabilità
- Funzione `_module_0`; popola gli array globali `UNMANAGED_WITH_CASK`,
  `UNMANAGED_NO_CASK`, `UNMANAGED_APPLE` letti dal summary.
- Prompt di adozione via `_read_choice` con override `BREW_MANAGER_ADOPT`
  (default `n`: in --yes NON adotta nulla).
- App Apple rilevate con `mdfind` batch su kMDItemCFBundleIdentifier (il check
  codesign è volutamente disabilitato: troppo lento, resta solo in commento).
- Log errori adozione su `/tmp/brew_adopt_err.log` (fisso, sovrascritto) — STATE #11,
  task 4.

## Vincoli e insidie (per chi lo usa o lo modifica)
- ~~**BUG noto (STATE Attenzione #2)**: selezione per indice con `real_idx=num-1`
  su array zsh 1-based — "1" dà elemento vuoto, "2" adotta la PRIMA app. Da
  fixare al primo intervento sul modulo (con security gate).~~ — **fixed in BM-04**
  (`430f322`, through the gate; STATE #2 closed): the choice indexes the 1-based array
  directly, a repeated index counted once.
- ~~**NON rispetta `BREW_MANAGER_DRY_RUN`** (STATE Attenzione #3): l'adozione
  confermata parte anche in dry-run.~~ — **fixed in BM-04** (`430f322`): under `--dry-run`
  each adoption is a preview line, before any confirmation and even with `--yes`
  (`MODULE_DRYRUN[0]=1`).
- Only a valid cask-token shape reaches brew (BM-04): a flag-shaped or control-character
  `.app` name never becomes a brew argument (`--version.app`).
- Matching nome-app→cask euristico (tr/sed): falsi positivi/negativi possibili;
  un `brew info --cask` per app → lento su /Applications grandi. Its install-path `echo`
  sites on data are STATE #3b's three for task 5.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
- [[sessions/2026-07-13-bm04-adopt-off-by-one]] (the 1-based index, the target confirmed, the
  `--dry-run` preview, the cask-token check)
- [[sessions/2026-07-20-bm10-risk-badges]] (the `_ask_danger` frame on each adoption)
