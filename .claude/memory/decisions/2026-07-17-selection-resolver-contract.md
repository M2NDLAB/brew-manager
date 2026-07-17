---
type: decision
updated: 2026-07-17
tags: [decision, m2, dispatch]
---
# Resolver di selezione: home, contratto di output, nascita dei test (BM-08a)

- **Contesto**: M2 (roadmap-v2) ruota attorno a un resolver di selezione moduli
  riusabile — la "chiave di volta" da cui dipendono il dispatch posizionale da
  CLI (BM-08b) e gli agenti schedulati (BM-08c). Prima di BM-08a la logica viveva
  inline nel `case` di PARSE SELECTION in `brew_manager.sh`: non riusabile e non
  testabile (sourcare lo script avvia l'intera TUI). Fatti verificati sugli
  artefatti reali: `_warn` (lib/common.sh) scrive su **stdout** (a differenza di
  `_read_choice`, che manda i prompt su stderr apposta per il capture); **nessun
  modulo** referenzia `MODULE_DESC`/`MODULE_IDS` (grep su `modules/` → zero);
  `tests/` non esisteva e non c'era `make test`.

- **Decisione** (approvata dall'utente 2026-07-17, due scelte foundational):
  1. **Home**: registry (`MODULE_DESC`/`MODULE_IDS`) + `_resolve_selection` in un
     **nuovo `lib/selection.sh`**, sourcato dopo `common.sh`, **senza side effect
     al source** → sourcabile in isolamento dai test contro il registry REALE
     (parità ad alta fedeltà: se qualcuno rinumera i moduli, il test lo cattura).
  2. **Contratto di output**: il resolver **popola il globale `MODULES_TO_RUN`**
     (reset a ogni chiamata) e **non stampa** la lista; ritorna `0` se non vuoto,
     `1` se vuoto. La policy "vuoto = fatale" resta nel chiamante (il path
     interattivo fa `_err` + `exit 1`, invariato).
  3. **Nascita dei test**: **harness zsh a mano, zero dipendenze** (niente bats),
     wired come `make test` sempre eseguibile e bloccante; `make check` linta anche
     `tests/*.zsh`.

- **Alternative scartate**:
  - *Contratto a stdout* (`_resolve_selection` stampa la lista, capture con `$(…)`):
    scartato perché `_warn` scrive su stdout → i warning si mescolerebbero al
    risultato; l'array globale preserva anche l'ordine dei warning nella TUI.
  - *Registry+resolver in `lib/common.sh`*: mescola i dati del registry moduli con
    "colori/simboli/TUI"; separazione di responsabilità più sporca.
  - *Registry fermo in `brew_manager.sh`, solo il resolver in lib*: il test userebbe
    un registry-fixture (rischio drift dal reale) invece del registry vero.
  - *bats*: framework de-facto, ma **non installato** (come shellcheck) → sarebbe una
    nuova dipendenza opzionale con `make test` advisory-se-presente, incoerente con
    la filosofia "nessun tool obbligatorio". Resta candidato futuro se la suite cresce.

- **Conseguenze**: **BM-08b e BM-08c PUNTANO a questa decisione** — il dispatch
  posizionale e gli agenti chiamano lo stesso `_resolve_selection`, non re-parsano.
  Attenzione: BM-08b esegue il parsing CLI PRIMA che `MODULE_DESC` sia definito nel
  flusso attuale → dovrà spostare il source di `selection.sh`/il punto di chiamata
  (è compito di BM-08b, non di BM-08a). BM-08a è **parità pura**: i quirk del parser
  originale sono preservati di proposito e documentati (mixed-case `Log` non matcha;
  `go` dentro una lista viene scartato; token speciale in lista è case-sensitive) —
  il loro fix è un task separato, così BM-08a resta provabilmente behavior-neutral.
  Vedi [[core-brew-manager]], [[lib-common]], [[plans/roadmap-v2]].
