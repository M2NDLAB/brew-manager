---
type: session
date: 2026-07-17
branch: fix/agent-selection
tags: [session, m2, bm08c, scheduler, security-gate, consent]
---
# BM-08c — agenti attraverso il resolver + consenso fail-closed (chiude M2)

## Fatto (3 commit su fix/agent-selection, da main con BM-08b integrato)
- `7f4f218` fix(dispatch): **NON_INTERACTIVE ≠ consenso**. Separati: `NON_INTERACTIVE`
  (da `! -t 0` o dall'handoff interno `BREW_MANAGER_NONINTERACTIVE` nel figlio
  re-exec) ha il SOLO scopo di non bloccarsi sullo stdin morto; `YES_MODE` è
  settato ESCLUSIVAMENTE da `--yes`. `_ask` nega sotto NON_INTERACTIVE senza
  `--yes` (anche default `y`); `_read_choice` usa il default senza leggere stdin.
  Nuovo `tests/test_guardrails.zsh` (9 check).
- `cd110d4` fix(scheduler): `_install_agent` è il chokepoint del plist — valida
  con `_selection_is_valid` e RIFIUTA un valore invalido (niente fallback-`go`);
  migrazione passa il valore raw; guard estesa a NON_INTERACTIVE. Nuovo
  `_selection_is_valid` in lib/selection.sh (subshell, no side-effect).
- `d1a5e2b` fix(bk): il gemello `_restore_agents`/`_preview_restore_agents`
  allineato (valida + SKIP, non `go`).

## Il fix #8 — sbagliato una volta, corretto dal gate
Primo tentativo (poi RIFATTO): far sopravvivere YES_MODE al re-exec via
`BREW_MANAGER_YES` ereditato. Il gate l'ha bocciato come **CRITICAL**: convertiva
le run non-TTY senza `--yes` da fail-closed ad **auto-conferma dei default
distruttivi** (`5 </dev/null` → `brew autoremove`+`cleanup -s` senza consenso;
`0 --adopt=all` → adozione; env stale). Il branch è stato **resettato** per non
conservare il commit CRITICO. La radice: confondere "non-interattivo" con
"consenso". Fix corretto = quello del reviewer (separare i due).

## Gate di sicurezza (adversariale, autore ≠ giudice — docs/03)
- Round 1 (2 reviewer): trovati **CRITICAL** (mod_05 senza consenso), **HIGH**
  (adoption), **MEDIUM** (env stale, fail-open-`go`). Tutti fixati.
- Re-gate (sul fix corretto): consenso **CORRETTO e COMPLETO** (nessun path
  distruttivo senza `--yes`, nessun flusso legittimo rotto, buchi env/handoff
  fail-closed — provato con brew mockato). Trovato **1 MEDIUM** di completezza: il
  gemello bk non era stato allineato → fixato (`d1a5e2b`).
- Debiti PRE-ESISTENTI registrati (fuori scope): divergenza conf/plist in
  re-register (estrae solo il 1° argv positionale), label injection sul path
  recreate, `mod_02` `brew update` non gated da `--dry-run`. Vedi STATE.

## Verifica (brew/launchctl mockati, HOME sandbox, pty — nessun launchd reale)
- `5 </dev/null` → nessun cleanup; `5 --yes` → cleanup (agente). `0 --adopt=all
  </dev/null` → niente adozione. env `BREW_MANAGER_YES=1` stale → ignorato.
- Agente read-only `8,9` → plist `8,9 --yes` → gira solo 8,9. `99` → rifiutato.
- Restore bk: bundle valido `8,9` restaurato, invalido `--ye` skippato (no `go`).
- 96 test verdi (87 selection + 9 guardrails).

## Retro
IMP-004 registrata (chiudi la CLASSE: grep tutti i siti + verifica adversariale +
re-gate dopo fix sensibili). IMP-002/003 restano aperte.

## Esito
**M2 CHIUSO** (BM-08a/b/c). Chiuse Attenzione #1 (CLI + scheduler), #8, #9. La
guardia by-convention "ogni azione mutante rispetta DRY_RUN/YES" ora è rafforzata
da "NON_INTERACTIVE non è consenso". Prossimo: M3 (TUI) o release, decisione utente.
