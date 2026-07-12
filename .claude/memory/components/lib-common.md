---
type: component
component: lib-common
updated: 2026-07-12
tags: [component]
---
# lib-common (lib/common.sh + lib/log.sh)

Infrastruttura condivisa: palette/simboli TUI, utility di output, guard-rail dei
prompt, gestione del log di fine sessione.

## Stato attuale
Stabile, piccola (143 + 38 righe). Componente SENSIBILE (vedi docs/03): un difetto
qui si propaga a tutti i moduli.

## Cosa espone / responsabilità
- Output: `_hline`, `_header_main`, `_section`, `_ok/_warn/_err/_info/_item`,
  `_stat_row`, `_spinner` (degrada a wait puro sotto recording).
- Guard-rail: `_ask` (y/N con default; in YES_MODE risponde col default SENZA
  prompt) e `_read_choice` (precedenza: override da env passata PER NOME con
  espansione zsh `${(P)varname}` → default in YES_MODE → prompt interattivo).
- `TERM_WIDTH` via tput con sanificazione (tput può restituire garbage sotto
  script(1)), fallback 80, clamp 60–100.
- `log.sh`: `_handle_log` a fine run (keep/open/delete; scelta invalida = keep).

## Vincoli e insidie (per chi lo usa o lo modifica)
- I default di `_ask`/`_read_choice` SONO la sicurezza degli agenti schedulati
  (--yes): cambiare un default da `n` a `y` trasforma un modulo interattivo in
  un'azione automatica su tutti i Mac che schedulano il tool. Mai farlo senza
  passare dal security gate.
- `_read_choice` usa l'espansione indirendo `${(P)...}`: zsh-only, non portabile
  a bash.
- `_handle_log` legge SEMPRE da stdin (nessun bypass YES_MODE): in non-TTY la
  read fallisce e si applica il default keep — comportamento voluto ma implicito.
- I colori sono hardcoded ANSI: qualunque output di modulo deve passare dalle
  utility, mai printf con escape propri (il post-processing sed del log li
  assume).

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
