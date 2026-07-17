---
type: component
component: lib-common
updated: 2026-07-17
tags: [component]
---
# lib-common (lib/common.sh + lib/log.sh)

Infrastruttura condivisa: palette/simboli TUI, utility di output, guard-rail dei
prompt, gestione del log di fine sessione.

## Stato attuale
Stabile, piccola. Componente SENSIBILE (vedi docs/03): un difetto qui si propaga a
tutti i moduli. Dal BM-08c i guard-rail distinguono consenso da non-interattivo.

## Cosa espone / responsabilità
- Output: `_hline`, `_header_main`, `_section`, `_ok/_warn/_err/_info/_item`,
  `_stat_row`, `_spinner` (degrada a wait puro sotto recording).
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
- I colori sono hardcoded ANSI: qualunque output di modulo deve passare dalle
  utility, mai printf con escape propri (il post-processing sed del log li
  assume).

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
- [[sessions/2026-07-17-bm08c-agent-selection]] (guard-rail consenso vs non-interattivo)
