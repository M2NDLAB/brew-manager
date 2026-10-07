---
type: component
component: core-brew-manager
updated: 2026-09-27
tags: [component]
---
# core-brew-manager (brew_manager.sh)

Entry point TUI: parsing flag, caricamento lib+moduli, dispatch, recording della
sessione, summary finale.

## Stato attuale
Stabile, v1.3.0 rilasciata. Versione da file `VERSION` (BM-07, non più costante
hardcoded). Dal BM-08a la selezione moduli è delegata a `_resolve_selection`
([[lib-selection]]) — coperta da `tests/test_selection.zsh`. Dal fix exit-code
(2026-07-18) il PARENT propaga l'exit del figlio attraverso il wrapper
script(1) — contratto end-to-end coperto da `tests/test_exit_codes.zsh`
(sandbox a symlink farm + mock brew). Il resto del core resta senza test.

**Startup without Homebrew on PATH (branch `fix/startup-brew-env`, 2026-09-27; STATE
#23).** Before anything else runs, `_brew_bootstrap_path` looks for a brew EXECUTABLE on
PATH (`whence -p`: a function or alias named brew does not count) and, if there is none,
probes `BREW_BIN_CANDIDATES=(/opt/homebrew/bin/brew /usr/local/bin/brew)` in order and
prepends the first hit's `bin` and `sbin` to the exported PATH (no `eval "$(brew
shellenv)"`). It covers launchd's and a Finder-started app's PATH
(`/usr/bin:/bin:/usr/sbin:/sbin`) and any start outside a login shell. When Homebrew is
still missing the check exits **69** (`EXIT_ENV_UNAVAILABLE`, sysexits `EX_UNAVAILABLE`)
on every way out: `--dry-run` never offers the installer; no terminal (`NON_INTERACTIVE`,
stdout not a TTY, or the recorded child) gets no prompt at all; at a terminal `_ask`
with default `n` (so `--yes` never installs). The download-and-run is `_brew_install`
(download first with timeouts, a non-empty body, the installer's own exit status read,
then the probe; it only RETURNS, and only a full success re-execs). The exit order:
`--version` (0) → an unknown flag (2) → Homebrew (69) → the selection (2 or 1).
`tests/test_exit_codes.zsh` pins it (49 checks): the minimal environment through
`script(1)`, each guard clause alone, `_brew_install` extracted and run against a mock
curl — no test ever answers the installer prompt.

## Cosa espone / responsabilità
- Flag CLI: `--dry-run`, `--yes|-y` (auto-attivo se stdin non è TTY),
  `--adopt=n|all|1,2`, `--upgrade=y|n`, `--only=ids`, `--skip=ids`, `--version|-V`
  — esportati come env `BREW_MANAGER_*`. Flag ignoti/lookalike Unicode → errore +
  exit 2 (micro-task).
- **Selezione** (registry + parser in `lib/selection.sh`, [[lib-selection]]):
  - **Da CLI (BM-08b)**: il loop dei flag cattura i token posizionali (uniti con
    virgole) e `--only`/`--skip`; se presenti, `CLI_SELECTION=1` → il core chiama
    `_resolve_cli` STRETTO (token ignoto → errore + exit 2) e SALTA il menu.
  - **Interattiva**: nessuna selezione da CLI → menu + `read` + `_resolve_selection`
    (lenient: warn+skip). Policy "vuoto = fatale" (`_err` + `exit 1`) nel core.
- **Banner + menu (BM-11, flat variant)**: banner = brand line (glifo/middle-dot
  gated su `TUI_UNICODE`, contesto right-aligned a TERM_WIDTH — il glifo 🍺 conta
  1 char ma 2 colonne: pad corretto di −1) + rule + log path (`~` al posto di
  $HOME, display-only). Menu = card `badge(4)·id(3)·nome(17)·desc(≤46)` ≤78 col
  via helper LOCALI `_menu_row`/`_menu_section` (printf %s sui dati, IMP-003);
  rule tra sequenza numerata e TOOLS; footer 3 righe. I cap di colonna sono
  invarianti di dati ([[lib-selection]], `tests/test_menu_registry.zsh`). Il
  summary elenca i moduli con `MODULE_NAME`. Il `read` della Choice e la
  grammatica sono INTATTI (presentazione pura).
- **Summary di sessione (BM-12)**: il loop di dispatch registra per ogni
  POSIZIONE della run (non per id — la grammatica ammette `1,1,2`) lo stato in
  `RUN_STATUS` e la durata in `RUN_SECS`. Lo stato lo decide `_run_status`
  ([[lib-common]]) da DUE registri: `MODULE_RISK` (quanto il modulo può cambiare)
  e `MODULE_DRYRUN` (se `--dry-run` lo ferma davvero) — `done` se non è una dry
  run o il modulo è `ro`, `preview` se è un mutante gatato, **`ran`** se è un
  mutante NON gatato (oggi `bk` e `las`, STATE #15/#16). Derivarlo dal solo
  rischio è ciò che produsse la falsa attestazione trovata dal gate BM-12.
  **`failed` non è mai assegnato** (#4b). Il summary rende righe di esito
  + stat + riga "Disk" (solo se `DU_*_KB` sono stati misurati da mod_05) + footer
  identità. `_menu_section` è definita FUORI dal ramo interattivo perché la usa
  anche l'header del summary (una run CLI quel ramo non lo attraversa).
- Dispatch: numerico → `_module_N` dinamica; speciali → case esplicito
  (log→`_module_log`, bk→`_module_14`, las→`_module_15`, mas→`_module_16`).
- **Consenso vs non-interattivo (BM-08c)**: `NON_INTERACTIVE` (da `! -t 0`, o
  dall'handoff `BREW_MANAGER_NONINTERACTIVE` nel figlio re-exec col pty) NON è
  consenso — solo `--yes` setta `YES_MODE`. Export di entrambi per i moduli.
  Vedi [[2026-07-17-consent-vs-noninteractive]], [[lib-common]].
- Recording: auto-rilancio dentro `script(1)` (guard `BREW_MANAGER_RECORDING`),
  post-processing sed che rimuove escape ANSI; `logs/` con fallback mktemp.
  **Contratto di exit (fix 2026-07-18)**: `_run_rc` catturato SUBITO dopo
  script(1) e propagato dopo la strip — selezione invalida → 2, selezione
  vuota → 1, figlio ucciso da segnale → numero grezzo del segnale (semantica
  script(1) macOS: Ctrl+C → 2), run ok → 0. Strip fallita: WARNING su stderr,
  log raw conservato, rc della run INVARIATO. Un fallimento DENTRO un modulo
  esce ancora 0 (metà residua di Attenzione #4b).
- Cleanup finale hardcoded dei temporanei `/tmp/brew_*.log`.

## Vincoli e insidie (per chi lo usa o lo modifica)
- **Argomenti CLI posizionali: IMPLEMENTATI (BM-08b)** — `./brew_manager.sh 0,4,5`
  esegue quei moduli non-interattivamente; `--only`/`--skip` filtrano. La cattura
  dei posizionali avviene nel loop dei flag (registry non ancora sourcato), la
  RISOLUZIONE dopo il source (dove c'era il menu). Gli agenti scheduler sono
  instradati per il resolver e il non-TTY è fail-closed senza `--yes` —
  entrambi CHIUSI in BM-08c (questa nota conteneva il residuo stale,
  riconciliato 2026-07-18).
- I moduli sono funzioni SOURCATE nello stesso processo: condividono l'ambiente;
  una variabile "locale" non dichiarata `local` inquina lo stato globale.
- **`--dry-run` spegne anche l'auto-update di Homebrew** (line 160 since branch 4; riga 152 when written, micro-task
  2026-07-21): `(( DRY_RUN )) && export HOMEBREW_NO_AUTO_UPDATE=1`. Senza,
  `brew` eseguiva `brew update --auto-update` da sé prima di
  `install|outdated|upgrade|bundle|release`, quindi moduli che "si limitano a
  elencare" (4, 10, bk) riscrivevano comunque l'indice in una preview — e nemmeno
  il `--dry-run` DI BREW lo ferma (decide prima di leggere gli argomenti). Solo
  sotto dry-run: una run normale mantiene il comportamento abituale di brew.
  Verificato end-to-end perché la variabile deve sopravvivere al re-exec di
  `script(1)` (`tests/test_dryrun_gates.zsh`).
- Il re-exec sotto script(1) fa ripartire lo script dall'inizio: tutto ciò che
  precede il guard `BREW_MANAGER_RECORDING` viene eseguito DUE volte.
- The built-in Homebrew installer (`_brew_install`, then `exec zsh "$0" "$@"` at top
  level — inside a function `$0` would be the function's name): re-read the re-exec flow,
  the guards and the suite's extraction harness before touching it.
- Nessuna trap su Ctrl+C: il salvataggio del log è garantito dal processo esterno
  di script(1), non da handler interni.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
- [[sessions/2026-07-17-bm08a-selection-resolver]] (registry/parser usciti in lib/selection.sh)
- [[sessions/2026-07-17-bm08b-positional-dispatch]] (cattura posizionali + branch CLI)
- [[sessions/2026-07-17-bm08c-agent-selection]] (NON_INTERACTIVE vs YES_MODE)
- [[sessions/2026-07-18-exit-code-propagation]] (rc del figlio propagato dal parent)
- [[sessions/2026-07-20-bm11-menu-redesign]] (banner flat + menu a card allineate)
- [[sessions/2026-07-21-bm12-progress-summary]] (tracking per-posizione + summary di sessione)
- [[sessions/2026-07-21-dryrun-mod02-mas]] (HOMEBREW_NO_AUTO_UPDATE sotto --dry-run)
- [[sessions/2026-09-26-startup-brew-env]] (the Homebrew PATH bootstrap, exit 69, the
  installer only at a terminal)
