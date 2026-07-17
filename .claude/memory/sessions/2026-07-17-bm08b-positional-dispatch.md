---
type: session
date: 2026-07-17
branch: feat/positional-dispatch
tags: [session, m2, bm08b, dispatch, cli, security-gate]
---
# BM-08b — dispatch posizionale + --only/--skip

## Fatto (3 commit su feat/positional-dispatch, da main con BM-08a integrato)
- `1e7e735` feat(dispatch): API di risoluzione CLI stretta in `lib/selection.sh` —
  `_resolve_selection` con param `invalid_mode` (warn/collect) + globale
  `RESOLVE_INVALID`; `_collect_module_tokens` (valida i token di --only/--skip);
  `_resolve_cli <spec> <only> <skip>` (base + intersezione --only + sottrazione
  --skip, STRETTA: rc 2 token ignoto / 1 vuota / 0 ok). Tutto sopra il resolver
  di BM-08a. 43 → 64 test.
- `2e34c25` feat(cli): wiring in `brew_manager.sh` — il loop dei flag cattura i
  posizionali (uniti con virgole) e --only/--skip; se c'è selezione da CLI →
  `_resolve_cli` STRETTO (token ignoto → errore + exit 2), altrimenti menu
  interattivo INVARIATO. --dry-run/--yes onorati via env. README riallineato
  (rimosso "Not yet supported" + 2 correzioni fattuali: MODULE_DESC in
  lib/selection.sh, parse non più "solo dal prompt").
- `7096d8a` fix(dispatch): fix del gate (vedi sotto). 64 → 74 test.

## Contratto (esteso → addendum in [[2026-07-17-selection-resolver-contract]])
Il resolver ora espone anche il contratto STRETTO per la CLI (RESOLVE_INVALID +
collect mode + `_resolve_cli`); il path interattivo resta lenient (warn+skip).
BM-08c userà lo stesso `_resolve_cli` per gli agenti.

## Gate di sicurezza (adversariale, autore ≠ giudice — docs/03)
Due reviewer indipendenti in parallelo (Agent tool, non workflow: ultracode off),
lenti diverse: (1) injection/dispatch, (2) parità/guard-rail.
- **PULITI**: injection/RCE/glob/aritmetica; parità interattiva; nessun implicit
  YES; --dry-run gate. Il dispatch vede solo token validati.
- **2 MEDIUM fixati** (fail-open nel tokenizer, eseguivano un modulo DIVERSO):
  - R1: `echo|tr` espandeva i backslash-escape (`\065`→`5` → mod_05 cleanup).
    Era PRE-ESISTENTE (parity-move di BM-08a). Fix: `${_n// /}`. → [[LEARNINGS]] IMP-003.
  - R2: virgole vuote (`0,4,`) → token vuoto "invalido" → rc 2 con nome VUOTO,
    over-reject. Fix: `[[ -z ]] && continue` (empty ignorati, path coerenti).
- **1 LOW fixato**: newline nello spec troncava via `read -rA <<<`; fix: split
  con `${(@s:,:)}` → token col newline validato intero e rifiutato.
- **1 LOW fixato (doc/code)**: `--only`/`--skip` da soli → run `go` non-interattivo;
  allineata la nota README.
- **INFO registrato**: il posizionale espone un singolo modulo mutante a un caller
  non-TTY (eredita YES auto-detect, Attenzione #8/#1) — ampliamento di reach di un
  debito GIÀ tracciato, non un bypass nuovo.
Fix DIMOSTRATO end-to-end: `./brew_manager.sh '\065'` ora esce 2 senza eseguire
alcun modulo (prima: Running modules: 5).

## Verifica
`make check` verde; `make test` 74/74; smoke cablati: posizionale valido→esegue
senza menu; token invalido/escape→exit 2; --only filtra; virgola vuota tollerata;
nessun posizionale→menu interattivo intatto.

## Retro
IMP-003 registrata (convenzione: mai echo su dati — chiude la classe fail-open a
monte di #3b), IMP-002 rafforzata. Propose-only, decisioni differite.

## Prossimo
BM-08c: gli agenti las passano la selezione attraverso `_resolve_cli`; chiude
Attenzione #8 e la parte scheduler di #1. Nota: BM-08c è il posto dove indurire
l'input del plist (newline già gestito nel resolver; resta la sanificazione
dell'estrazione da plist, Attenzione #9).
