---
type: component
component: lib-selection
updated: 2026-11-13
tags: [component]
---
# lib-selection (lib/selection.sh)

Registry dei moduli + resolver della selezione. Nato in BM-08a estraendo la logica
inline da `brew_manager.sh`; esteso in BM-08b con la risoluzione CLI stretta
(usata dal dispatch posizionale, e da BM-08c per gli agenti).

## Stato attuale
BM-08a + BM-08b (2026-07-17). **Sensibile**: infrastruttura di dispatch condivisa —
un difetto qui propaga a tutti i moduli (in the security gate's lists since IMP-022,
2026-09-25). Coperto da `tests/test_selection.zsh` (~~87 check~~ 189 checks since 2.0.0's
task 3; the old "74" was stale, corrected 2026-09-25). Due gate adversariali passati (BM-08a;
BM-08b con 2 MEDIUM fail-open del tokenizer trovati e fixati).

**2.0.0, task 3 (2026-11-13, [[sessions/2026-11-13-remove-special-modules]])**: the names bk,
las, log and mas and the number 10 left the registries, the resolver and `go`; they are
reserved (`RETIRED_MODULE_IDS=(10 bk las log mas)`, presentation only: `_retired_in` and the
constant `RETIRED_HINT` print a pointer next to a refused selection, never feed the
resolver). The resolver lost its whole-token arms and its lower-case name checks, so a
removed id is an unknown token in any case and position (CLI exit 2; the menu warns and
skips). `_selection_is_valid` went with its only callers (NEW-d). `MODULE_DRYRUN[1]=0`
(module 1 still writes under `--dry-run`, STATE #14). `tests/test_menu_registry.zsh` adds
the wiring invariant (every registered id has its file and `_module_N`, every `go` id is
registered, every module file is registered) and `tests/test_run_summary.zsh` the
`MODULE_DRYRUN` phantom check. The gate: three rounds, none CRITICAL, HIGH or MEDIUM.

## Cosa espone / responsabilità
- `MODULE_DESC` (assoc, `typeset -gA`; chiavi ~~0–13 + log/bk/las/mas~~ 0–9 and 11–13 since
  2.0.0's task 3): descrizioni
  E insieme di validità — una chiave assente = modulo non selezionabile. Dal
  **BM-11** i TESTI sono sottotitoli one-line del menu (≤46 col, ASCII-only,
  riscrivibili liberamente); le CHIAVI restano il contratto congelato.
- `MODULE_NAME` (assoc, BM-11): id → nome breve da menu/summary (≤17 col,
  ASCII-only). **Presentazione pura** come MODULE_RISK: il resolver non lo legge
  mai. Lockstep + cap di colonna pinnati da `tests/test_menu_registry.zsh`
  (~~8 check~~ 13 checks since task 3, the wiring invariant included): il layout 80-col
  del menu è un'invariante di DATI.
- `MODULE_IDS=(~~0..13~~ 0..9 11..13)` (`typeset -ga`): sequenza `go`; ~~gli speciali ne
  restano fuori~~ since task 3 every module is in it, the only list the menu draws.
- `MODULE_DRYRUN` (assoc, BM-12): id → 1 se una sessione `--dry-run` non cambia
  NULLA eseguendo quel modulo, 0 se può agire comunque. **Non è un livello di
  rischio** (quello è `MODULE_RISK`): è un fatto sul CODICE, e il summary lo usa
  per decidere se può attestare "previewed, nothing changed". Dal **micro-task
  dry-run** (2026-07-21) `[2]`/`[mas]` valgono 1 (gate dimostrato con tripwire su
  mock brew) e `[bk]`/`[las]` valgono **0**: erano 1 da sempre — dichiarati, mai
  verificati — e il gate ha trovato `brew bundle check` in `bk [4]` e `rm -f` in
  `las [c]` senza gate (STATE #15/#16). Regola: **sopravvalutare qui è un bug di
  sicurezza** (il log di sessione attesterebbe una proprietà che la run non ha
  avuto); sottovalutare è onesto. Since 2.0.0's task 3: bk, las and mas left with their
  modules, and `[1]=0` — module 1 writes `/tmp/brew_doctor.log` and may run a plain `git
  status` under `--dry-run` (STATE #3, #14; task 4 flips it back).
- `MODULE_RISK` (assoc, BM-10): id → `ro|write|danger`, 1 voce per chiave di
  `MODULE_DESC` = single source of truth del **badge di rischio**. **Presentazione
  pura**: NON alimenta il resolver (nessun impatto sul contratto di selezione).
  Livelli da audit adversariale (mai sottostimare, docs/03): `ro` 3,6,7,8,9,11,12,13
  · `write` 1,2~~,log~~ · `danger` 0,4,5~~,10,bk,las,mas~~ (since task 3; module 1 `write` since 2026-10-10: its
  developer-mode restore changes Homebrew's own setting and code). `_about_risk <id>` compone
  badge+caption (renderer puri in [[lib-common]]) per il blocco About dei moduli.
  Pinnato da `tests/test_risk_badges.zsh` (completezza vs MODULE_DESC, sensibili=danger).
- `_resolve_selection <spec> [invalid_mode]`: popola il GLOBALE `MODULES_TO_RUN`
  (reset) + `RESOLVE_INVALID` (i token ignoti); ritorna 0 non-vuoto / 1 vuoto.
  `invalid_mode`: `warn` (default, interattivo — stampa `_warn`) | `collect`
  (silenzioso, per la CLI stretta). NON stampa la lista.
- `_resolve_cli <spec> <only> <skip>`: risoluzione NON interattiva e STRETTA —
  base + intersezione `--only` + sottrazione `--skip`. Ritorna **2** se un token
  è ignoto (in `RESOLVE_INVALID`), **1** se vuota, **0** altrimenti. Ordine e
  duplicati della base preservati; i filtri sono liste di moduli concreti (no `go`).
- `_collect_module_tokens <csv>`: valida i token di un filtro → `FILTER_TOKENS`
  (validi) + append a `RESOLVE_INVALID` (ignoti).
- ~~`_selection_is_valid <spec>` (BM-08c): predicato SENZA side effect (delega a
  `_resolve_cli` in subshell) — 0 sse lo spec è una selezione valida non vuota.
  UNA sorgente di verità per la grammatica degli agenti (mod_las/mod_bk lo usano
  per accettare/rifiutare un valore salvato: ciò che valida = ciò che gira).~~ — removed
  in 2.0.0's task 3 with its only callers, las and bk (NEW-d).
- `RETIRED_MODULE_IDS`, `RETIRED_HINT`, `_retired_in [token...]` (task 3, decision D5):
  the five reserved ids and the constant pointer; `_retired_in` is true when a token,
  lower-cased, is one of them. Read only by `brew_manager.sh` after the resolver, in its
  error and warning branches; never by the resolver.

## Vincoli e insidie (per chi lo usa o lo modifica)
- **Contratto ad array globale, non stdout**: `_warn` (lib/common.sh) scrive su
  stdout, quindi stampare la lista la mescolerebbe ai warning. Chi riusa il resolver
  legge `MODULES_TO_RUN`, MAI `$(_resolve_selection …)`.
- **Dipendenze al CALL time**: usa `_warn` (common.sh) e legge `MODULE_DESC`/`IDS`.
  Va sourcato dopo common.sh. In `brew_manager.sh` è sourcato subito dopo common/log,
  così il registry è pronto per menu/dispatch/summary.
- **Sourcabile senza side effect**: definisce solo dati e ~~una funzione~~ functions (five
  today; corrected on 2026-11-08) → i test lo sourcano in isolamento (con common.sh per
  `_warn`) contro il registry REALE.
- **Parità con quirk preservati di proposito**: ~~`Log` mixed-case non matcha,~~ `go`
  in lista scartato~~, special in lista case-sensitive~~. Fissati in
  [[2026-07-17-selection-resolver-contract]]. Since 2.0.0's task 3 only the `go` quirk is
  left: the name quirks went with the names.
- **Tokenizer indurito (BM-08b, gate)**: split e strip degli spazi con param
  expansion (`${(@s:,:)}`, `${v// /}`), MAI `echo`/`read -rA <<<`. Motivo: `echo`
  espande i backslash-escape (`\065`→`5`), remappando un token fasullo su un
  modulo reale (fail-open, eseguiva mod_05); `read -rA` tronca al primo newline.
  Regola generale → [[LEARNINGS]] IMP-003. I token VUOTI (virgole adiacenti/finali)
  sono ignorati, non "invalidi": `0,4,` risolve a {0,4} su entrambi i path.
- ~~**Return-code NON load-bearing oggi**: il path interattivo (`brew_manager.sh`)
  legge la LUNGHEZZA di `MODULES_TO_RUN`, non `$?`. Lo diventa quando BM-08b/c
  cablano la rc nel dispatch CLI/schedulato — per questo il contratto 0/1 è già
  testato (`assert_rc`).~~ — **stale since BM-08b/c** (corrected on 2026-11-08): the CLI
  path reads `_resolve_cli`'s 2 (exit 2), and `_selection_is_valid` returns its status
  for the agents (0 = valid); on both of `brew_manager.sh`'s paths an empty selection is
  still read from the length of `MODULES_TO_RUN` (exit 1), not from the 1.
- **Contratto stabile per BM-08b/c**: entrambi PUNTANO al resolver, non re-parsano.
  ~~BM-08b dovrà però anticipare il source/la chiamata (il parsing CLI precede la
  definizione di `MODULE_DESC` nel flusso attuale).~~ — done the other way in BM-08b
  (corrected on 2026-11-08): the flag loop only captures the tokens, and the resolution
  runs after the source ([[core-brew-manager]]).
- **Il registro si tiene onesto con una ALLOW-LIST, non con "zero debito"**
  (micro-task dry-run, IMP-009): `tests/test_run_summary.zsh` pinna
  `_KNOWN_UNGATED=(~~bk las~~ 1)` (since task 3) in DUE direzioni — un modulo dichiarato 0 fuori lista
  fallisce (il debito non cresce in silenzio) e una voce che non è più debito
  fallisce (l'esenzione non sopravvive al fix). Un test che facesse fallire ogni
  `0` renderebbe la dichiarazione onesta l'unica mossa che rompe la build, e la
  via più rapida al verde sarebbe mentire nel registro. ~~**Al fix di #15/#16 va
  aggiornata anche `_KNOWN_UNGATED`.**~~ — done in task 3, #15/#16 closed with bk/las; at
  task 4's fix of module 1 (#14) the entry `1` leaves the list.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-17-bm08a-selection-resolver]] (nascita)
- [[sessions/2026-07-17-bm08b-positional-dispatch]] (API CLI stretta + hardening gate)
- [[sessions/2026-07-17-bm08c-agent-selection]] (`_selection_is_valid` per gli agenti)
- [[sessions/2026-07-20-bm10-risk-badges]] (`MODULE_RISK` + `_about_risk`, presentazione)
- [[sessions/2026-07-20-bm11-menu-redesign]] (`MODULE_NAME` + testi MODULE_DESC da menu)
- [[sessions/2026-07-21-bm12-progress-summary]] (`MODULE_DRYRUN` born)
- [[sessions/2026-07-21-dryrun-mod02-mas]] (`MODULE_DRYRUN` onesto: bk/las a 0, allow-list)
- [[sessions/2026-10-10-homebrew-developer-mode]] (module 1 `write`: the level covers
  Homebrew's own settings)
- [[sessions/2026-11-13-remove-special-modules]] (2.0.0: names and 10 removed and reserved,
  the hint, `[1]=0`, the wiring and phantom checks)
