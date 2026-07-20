---
type: session
date: 2026-07-20
prompt: BM-10 — badge di rischio + UX di conferma distruttiva (M3, secondo task)
branch: feat/risk-badges
tags: [session, tui, bm10, m3, sensitive]
---
# BM-10 — Risk badges [RO]/[W]/[!] + cornici di conferma distruttiva

## Contesto d'apertura (debito di memoria chiuso prima)
Ripresa dopo un limite di sessione. Prima di BM-10, riconciliata la memoria stale:
STATE/INDEX davano il framework upgrade v1.0.0 "in attesa di integrazione" mentre
era già in main (`126bc7d`). Allineato su branch `chore/lint-mem-fw-v1.0.0` (commit
`c752c4b`), **poi integrato in main dall'utente** (merge `765bad4`). Da lì
`feat/risk-badges` fresco. → [[STATE]], [[INDEX]].

## Cosa è stato fatto (piano [[plans/bm10-risk-badges]], 5 task, un commit/task)
Sistema di **risk badge** — PRESENTAZIONE PURA (contratto pubblico congelato
intatto: flag/selezione/exit-code/plist/numeri moduli non toccati). 6 commit su
`feat/risk-badges` sopra `main`, **170 test verdi**, `make check` pulito.

1. **Registry + renderer** (`bb520a9`): `MODULE_RISK` (assoc, 1 voce/modulo) in
   `lib/selection.sh` = single source of truth del rischio; `_risk_badge`/
   `_risk_caption` (renderer PURI, level-driven) in `lib/common.sh` sulla palette
   semantica BM-09 (`C_OK/C_WARN/C_DANGER` → vuoti a L0); `_about_risk <id>` compone
   la riga About. `tests/test_risk_badges.zsh` (33 check). Badge a larghezza fissa
   4 col → colonne allineate.
2. **Menu** (`60a1969`): badge a sinistra di ogni riga (numerati + log/bk/las/mas)
   + legenda; allineamento verificato L0/L2.
3. **Blocchi About** (`03a4f33`): riga `_about_risk "<id>"` nei 18 moduli. (Bug e
   fix: il primo loop `while read` droppava l'ultima riga dei file SENZA newline
   finale → reverto + `|| [[ -n "$line" ]]`; normalizzato +newline EOF su 17 file.)
4. **Cornici di pericolo** (`5b52e02`): `_ask_danger <title> <q> <default>
   [detail…]` disegna un `_box "$C_DANGER"` e POI delega a `_ask` INTATTO — il box è
   presentazione, il consenso resta in `_ask` (invariante byte-per-byte). Cablato ai
   **9 siti `_ask` distruttivi**: mod_00 adopt, 04 upgrade, 05 cleanup, 10 greedy,
   bk restore ×3, mas install/upgrade. +5 test (consenso == `_ask`; nessun bare
   `_ask` residuo).
5. **README + verifica** (`baaf11b`): legenda badge + cornici documentate nella
   sezione Interactive TUI.

## Decisioni non ovvie
- **Classificazione di rischio** verificata adversarialmente (workflow: classify +
  refute per modulo, raise=0): **[RO]** 1,3,6,7,8,9,11,12,13 · **[W]** 2 (`brew
  update`), log (rm/purge solo in `logs/`) · **[!]** 0,4,5,10,bk,las,mas. Un badge
  che SOTTOSTIMA è un bug di sicurezza → il livello è il MASSIMO di ogni path.
- **`mod_00` = `[!]`** (adotta via `brew install --cask --adopt`), NON `[RO]` come
  il mockup illustrativo §4.7: la regola §4.5 + la non-regressione ("i sensibili
  mostrano [!]") vincono sul mockup.
- **`las` escluso dalle cornici**: non ha `_ask` di consenso (flusso a menu via
  `read -r`); incorniciarlo richiederebbe AGGIUNGERE una conferma = cambio di
  consenso, fuori dallo scope presentazione di BM-10 (semmai BM-16). Badge `[!]` nel
  menu/About copre la sua visibilità di rischio.
- **Stringhe nuove ASCII** (`-`/`:`, no em-dash): un em-dash multibyte in un dettaglio
  `_box` sballa il conteggio-colonne del bordo in locale C — la classe che il gate
  BM-09 aveva sanato. La prosa preesistente con em-dash NON è stata toccata (scope).

## Security gate (docs/03, sensibile) — PASSATO PULITO
Workflow adversariale a **5 lenti indipendenti** (consent-invariance, risk-
understatement, injection, control-flow, degradation-leak) sul diff `765bad4..baaf11b`,
con refutazione per-finding: **0 finding sollevati, 0 confermati** (~490K token di
lavoro reale, non vacui). Consenso invariato, nessuna sottostima, nessuna injection,
degradazione pulita.

## Incidente operativo → [[LEARNINGS]] IMP-006
Gli agenti del gate (NON isolati, working dir condivisa) hanno eseguito `git
checkout` per ispezionare il diff → thrashing `main↔baaf11b`, HEAD lasciato su
`main` a fine run. **Nessun lavoro perso** (branch `feat/risk-badges` intatto a
`baaf11b`); ripristinato con `git checkout feat/risk-badges`. La harness aveva
segnalato i file come "modified by user — intentional" (fuorviante). Lezione: un
review-workflow su un git-range o usa `isolation:'worktree'`, o vieta esplicitamente
`checkout/switch/reset`, e comunque si RIVERIFICA HEAD/branch dopo. Estende IMP-001.

## Stato
`feat/risk-badges` (HEAD `baaf11b`), 6 commit, gate passato, 170 test verdi. **In
attesa di integrazione** (blocco `/integrate`; bump MINOR — set con `feat`).
Merge/tag/push = utente. Poi STOP: decisione utente su BM-11/BM-12 (giudizio estetico).

## Collegamenti
[[lib-common]] · [[lib-selection]] · [[plans/bm10-risk-badges]] ·
[[sessions/2026-07-19-bm09-tui-foundation]] · [[plans/roadmap-v2]] · [[LEARNINGS]]
(IMP-006) · [[STATE]]
