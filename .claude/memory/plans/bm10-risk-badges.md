---
type: plan
prompt: BM-10 — badge di rischio + UX di conferma distruttiva
branch: feat/risk-badges
created: 2026-07-20
status: in-progress
tags: [plan, tui, bm10, m3, sensitive]
---
# Piano: BM-10 — risk badges [RO]/[W]/[!] e cornici di conferma distruttiva

## Obiettivo
A piano completato: ogni modulo mostra un badge di rischio `[RO]`/`[W]`/`[!]` nel
menu e nel blocco "About this module" (con una riga "cosa può fare"); i prompt
distruttivi hanno una **cornice di pericolo** rossa distinta da quelli informativi.
Costruito sui primitivi `_box`/palette di BM-09. **Presentazione pura**: nessun
cambiamento a flag/selezione/exit-code/plist/numerazione moduli (contratto pubblico
CONGELATO, docs/04). I 132 test restano verdi + nuovi test additivi.

## Classificazione di rischio (verificata adversarialmente, workflow wurvsecj5)
Un modulo prende il livello PIÙ ALTO raggiungibile da QUALSIASI suo path (mai
sottostimare — un badge basso è un bug di sicurezza). Gate della verifica: raise=0.
- **`[RO]`** (ro, 9): 1, 3, 6, 7, 8, 9, 11, 12, 13 — solo lettura/report.
- **`[W]`**  (write, 2): 2 (`brew update`, refresh metadati), log (rm/purge SOLO in `logs/`).
- **`[!]`**  (danger, 7): 0 (adopt), 4 (upgrade), 5 (autoremove+cleanup), 10 (greedy
  upgrade), bk (restore/install + plist + launchctl), las (LaunchAgent persist),
  mas (install mas + mas upgrade).
> `mod_00` = `[!]` (adotta) benché il mockup §4.7 lo dia `[RO]`: la **regola §4.5 +
> la non-regressione** ("i sensibili mostrano [!]") vincono sul mockup illustrativo.
> Verifiche bk/las/log tagliate dal limite di sessione ma inequivocabili dai
> mutating_ops enumerati e già al livello corretto (nessuna sottostima possibile).

## Siti `_ask` distruttivi (cornice di pericolo)
- 0: L207 `_ask "Adopt …"` · 4: L79 `_ask "Proceed with upgrade now?"` ·
  5: L64 `_ask "Proceed with autoremove and cleanup now?"` · 10: L118 `_ask "Force-upgrade …"`
- bk: L441 restore-all · L467 restore-brew · L485 restore-agents
- mas: L36 install mas · L114 mas upgrade
- las: mappare a mano all'edit (833 righe: install/modify/remove/re-register)

## Architettura
- `lib/common.sh`: `_risk_badge <level>` + `_risk_caption <level>` (render PURI,
  level-driven, usano `C_OK/C_WARN/C_DANGER` → vuoti a L0); `_ask_danger <q> <def>
  [box-line…]` = disegna `_box "$C_DANGER"` POI delega a `_ask` (consenso INTATTO).
- `lib/selection.sh`: `MODULE_RISK` (assoc, 1 voce per chiave `MODULE_DESC`) +
  `_about_risk <id>` (badge+caption per il blocco About).
- `brew_manager.sh`: badge nel menu (numerati + speciali), colonne allineate.
- 18 moduli: riga `_about_risk "<id>"` dopo l'header About.
- 7 moduli `[!]`: `_ask_danger` ai siti distruttivi sopra.

## Task
- [x] 1. Registry `MODULE_RISK` + `_about_risk` (selection.sh) + `_risk_badge`/
       `_risk_caption` (common.sh) + `tests/test_risk_badges.zsh` (completezza vs
       MODULE_DESC con anti-vacuità, livelli attesi, degradazione L0 = zero ANSI,
       larghezza badge fissa) — commit: bb520a9 (33 test, 165 totali)
- [x] 2. Badge nel menu di `brew_manager.sh` (numerati + log/bk/las/mas) + legenda,
       allineamento verificato (badge 4-col fissa) — commit: (questo)
- [ ] 3. Riga `_about_risk "<id>"` nel blocco About dei 18 moduli — commit: —
- [ ] 4. `_ask_danger` (common.sh) + cornice di pericolo ai siti distruttivi di
       0,4,5,10,bk,las,mas + test (cornice rossa; consenso identico a `_ask` sotto
       --yes/non-interactive: invariante byte-per-byte) — commit: —
- [ ] 5. README (badge nel menu/moduli) + `make test` (132+nuovi) e `make check` verdi — commit: —

## Dopo i task (ciclo di fine deliverable)
- Security gate ADVERSARIALE (docs/03, componente sensibile: lib/common.sh + moduli
  sensibili): _ask byte-identico? degradazione L0 pulita? badge non sottostima?
- `/checkpoint`, poi STAMPA `/integrate` e FERMATI. Merge/push = utente.
- NON incatenare BM-11/12: giudizio estetico dell'utente tra i task M3.

## Note di ripresa
Branch `feat/risk-badges` da main `765bad4` (post-merge riconciliazione memoria).
Classificazione in workflow wurvsecj5 (output: tool-results/be7rm3z7o.txt).

## Collegamenti
[[lib-common]] · [[lib-selection]] · [[sessions/2026-07-19-bm09-tui-foundation]] ·
[[plans/roadmap-v2]] · [[STATE]]
