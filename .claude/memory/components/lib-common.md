---
type: component
component: lib-common
updated: 2026-07-20
tags: [component]
---
# lib-common (lib/common.sh + lib/log.sh)

Infrastruttura condivisa: rendering TUI **capability-aware** (palette/simboli),
utility di output, guard-rail dei prompt, gestione del log di fine sessione.

## Stato attuale
Stabile, componente SENSIBILE (vedi docs/03): un difetto qui si propaga a tutti i
moduli. Dal BM-08c i guard-rail distinguono consenso da non-interattivo. Dal
**BM-09** il layer di rendering degrada per capacità del terminale (vedi
[[sessions/2026-07-19-bm09-tui-foundation]]).

## Capability detection & degradazione (BM-09)
- `_tui_color_level <is_tty> <ncolors>` → 0/1/2/3 (no-ANSI / 16 / 256 / truecolor):
  legge `NO_COLOR` e `COLORTERM`; funzione PURA (tty+ncolors come arg → testabile).
- `_tui_unicode` → 1 se UTF-8, con **precedenza POSIX** `LC_ALL > LC_CTYPE > LANG`
  (NON unione: `LC_ALL=C` forza l'ASCII anche con LANG UTF-8 — fix del gate BM-09).
- `_detect_capabilities` popola `TUI_COLOR_LEVEL`/`TUI_UNICODE`/`TUI_TTY`. **Handoff
  parent→child** via `BREW_MANAGER_TUI_{LEVEL,UNICODE,TTY}` (come NON_INTERACTIVE):
  sotto `script(1)` il figlio ha una pty (`-t 1`/`tput` mentono) → detect UNA volta
  nel parent, il figlio (RECORDING) si fida dell'handoff; run fresh ri-detecta e
  ri-esporta sempre (nessun leak di valore stale). Default safe = no-color/ASCII.
- `_init_palette`: **L0 → ogni costante colore VUOTA** (ANSI soppresso alla fonte
  per pipe/NO_COLOR); L1 = palette storica invariata; 256/truecolor = tinte
  semantiche. Alias `C_OK/C_WARN/C_DANGER/C_INFO/C_HEADING/C_BRAND/C_ACCENT`; i nomi
  legacy `C_*` mappati sulla semantica (strutturali cyan/blue/purple intatti).
- `_init_symbols`: `SYM_*` e `BOX_*` UTF-8 vs ASCII per `TUI_UNICODE`.
- Primitivi: `_box` (blocco bordato — title/righe come DATI via `printf %s`, MAI
  `echo -e`: chiusa la trappola echo-on-data IMP-003), `_repeat`, `_pad`,
  `TUI_INDENT`, `_clear` (pulisce solo se `TUI_TTY`). `_hline` mappa i glifi
  heavy/light in ASCII in locale non-UTF-8.

## Risk badges (BM-10) — presentazione del rischio
- `_risk_badge <level>` / `_risk_caption <level>`: renderer PURI (level-driven) per
  il badge `[RO]`/`[W]`/`[!]` e la sua caption. Colore dalla palette semantica
  (`C_OK/C_WARN/C_DANGER`) → **vuoti a L0** (badge in ASCII puro se pipato/NO_COLOR).
  Badge a **larghezza visibile fissa (4 col)** → colonne del menu allineate. Il
  livello per-modulo vive in `MODULE_RISK` ([[lib-selection]]), non qui (renderer
  registry-agnostici). Un badge che SOTTOSTIMA il rischio è un bug (docs/03).
- `_ask_danger <title> <question> <default> [detail…]`: conferma di un'azione
  DISTRUTTIVA. Disegna un `_box "$C_DANGER"` che nomina l'azione + i dettagli, POI
  **delega a `_ask` INVARIATO** e ne ritorna lo status. Il box è SOLO presentazione:
  il consenso resta in `_ask` (invariante byte-per-byte sotto --yes/non-interactive;
  guard-rail BM-08c/BM-09 preservato). Va chiamato solo sul path REALE (il dry-run
  per-modulo ha la sua preview e non conferma). Dettagli in ASCII puro (no em-dash
  multibyte: sballerebbe il border-math di `_box` in locale C). Pinnato da
  `tests/test_risk_badges.zsh` (consenso == `_ask`; nessun bare `_ask` residuo nei 6
  moduli cablati).

## Cosa espone / responsabilità
- Output: `_hline`, `_section`, `_ok/_warn/_err/_info/_item`, `_stat_row`,
  `_spinner` (degrada a wait puro sotto recording — morto-in-pratica,
  RECORDING sempre attivo; BM-12 lo riscrive gatando `\r`/cursore su `TUI_TTY`).
  `_header_main` RIMOSSA in BM-11 (orfana: l'unico call-site era il banner del
  core, ora una brand line flat inline — igiene codice morto come BM-07).
- Guard-rail dei prompt (BM-08c) — due variabili ORTOGONALI
  ([[2026-07-17-consent-vs-noninteractive]]):
  - `BREW_MANAGER_YES` (solo `--yes`) = CONSENSO. `_ask` → prende il default;
    `_read_choice` → default.
  - `BREW_MANAGER_NONINTERACTIVE` (stdin non usabile) = solo anti-blocco, NON
    consenso. `_ask` senza `--yes` → **nega (return 1)**, anche con default `y`;
    `_read_choice` → default (senza leggere lo stdin morto).
  - interattivo (entrambe 0) → prompt reale.
  `_read_choice` ha in più l'override da env passata PER NOME (`${(P)varname}`).
- `TERM_WIDTH` via tput con sanificazione (tput può restituire garbage sotto
  script(1)), fallback 80, clamp 60–100.
- `log.sh`: `_handle_log` a fine run (keep/open/delete; scelta invalida = keep).

## Vincoli e insidie (per chi lo usa o lo modifica)
- **"Non c'è tty" ≠ "consenso"** (BM-08c, invariante): solo `--yes` esplicito
  autorizza a prendere un default. Una run non-TTY senza `--yes` non modifica
  nulla (`_ask` nega). Un fix a questa guard-rail va verificato ADVERSARIALMENTE
  ("cosa AUTORIZZA?") — il 1° tentativo di BM-08c auto-confermava i default
  distruttivi ed è stato bocciato dal gate come CRITICAL ([[LEARNINGS]] IMP-004).
- I default di `_ask`/`_read_choice` SONO la sicurezza degli agenti schedulati
  (--yes): cambiare un default da `n` a `y` trasforma un modulo interattivo in
  un'azione automatica su tutti i Mac che schedulano il tool. Mai farlo senza
  passare dal security gate.
- Un modulo che muta SENZA passare per `_ask` NON è coperto dalla guard-rail
  (deve gate da `--dry-run` o da un prompt) — vedi `mod_02` `brew update`
  (Attenzione #3 in STATE).
- `_read_choice` usa l'espansione indirendo `${(P)...}`: zsh-only, non portabile
  a bash.
- `_handle_log` legge SEMPRE da stdin (nessun bypass YES_MODE): in non-TTY la
  read fallisce e si applica il default keep — comportamento voluto ma implicito.
- I colori NON sono più hardcoded fissi (BM-09): si risolvono per capacità
  (`TUI_COLOR_LEVEL`). Ogni output DEVE passare per le costanti `${C_*}`/`${SYM_*}`
  e le utility — mai `\033` propri (l'invariante è: zero `\033` grezzi fuori da
  `lib/common.sh`; il post-processing sed del log resta come rete).
- **Controllo terminale (clear/cursore/`\r`) gata su `TUI_TTY`, NON sul colore**
  (BM-09, [[LEARNINGS]] IMP-005): un run pipato/agente non deve emettere né colore
  né sequenze di controllo. Usa `_clear`; per lo spinner/progress di BM-12 gata
  `\r`/cursore su `TUI_TTY` (oggi `_spinner` gata solo su RECORDING).
- **`_box` e ogni futuro primitivo: DATI via `printf %s`, MAI `echo -e`** ([[LEARNINGS]]
  IMP-003): un title/riga fornito dal chiamante (nome modulo, path) espanderebbe gli
  escape se passato per echo. Il gate BM-09 ha ritrovato la trappola nel `_box`
  nuovo → fixata; vale per BM-10/BM-11 che ci costruiranno sopra.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
- [[sessions/2026-07-17-bm08c-agent-selection]] (guard-rail consenso vs non-interattivo)
- [[sessions/2026-07-19-bm09-tui-foundation]] (rendering capability-aware: detection,
  handoff, palette semantica, primitivi box/clear; gate passato)
- [[sessions/2026-07-20-bm11-menu-redesign]] (rimozione `_header_main`, solo-rimozione)
