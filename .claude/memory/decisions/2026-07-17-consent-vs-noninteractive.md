---
type: decision
updated: 2026-07-17
tags: [decision, m2, security, guard-rail]
---
# Consenso ≠ non-interattivo: `NON_INTERACTIVE` separato da `YES_MODE` (BM-08c)

- **Contesto**: chiudere Attenzione #8 (YES_MODE perso nel re-exec `script(1)`).
  Un primo fix faceva sopravvivere YES_MODE al re-exec onorando `BREW_MANAGER_YES`
  ereditato. Il gate adversariale l'ha bocciato come **CRITICAL**: convertiva ogni
  run non-TTY SENZA `--yes` (`./brew_manager.sh 5 </dev/null`, `go`, cron, `ssh
  host cmd`) da fail-closed ad **auto-conferma dei default distruttivi** — mod_05
  eseguiva `brew autoremove`+`cleanup -s` senza consenso; `0 --adopt=all` adottava;
  un `BREW_MANAGER_YES=1` stale in env auto-confermava anche una TTY interattiva.

- **Decisione** (fix corretto, root-cause dal reviewer): due concetti ORTOGONALI.
  - `NON_INTERACTIVE` — stdin non usabile (agent, pipe, cron, ssh senza `-t`). SOLO
    scopo: non bloccarsi su un read. Rilevato da `! -t 0` alla PRIMA invocazione e,
    nel figlio re-exec sotto `script(1)` (pty → TTY), dall'handoff INTERNO
    `BREW_MANAGER_NONINTERACTIVE` (letto solo nel figlio via il guard
    `BREW_MANAGER_RECORDING` → un valore stale non zittisce i prompt su una run
    fresca). NON è consenso.
  - `YES_MODE` — consenso esplicito. Settato ESCLUSIVAMENTE da `--yes`. L'export di
    `BREW_MANAGER_YES` SOVRASCRIVE ogni valore ereditato (niente kill-switch stale).
  - `_ask` (lib/common.sh): `--yes` → default; NON_INTERACTIVE senza `--yes` →
    **nega** (return 1), anche con default `y`; altrimenti prompt.
  - `_read_choice`: NON_INTERACTIVE/`--yes` → default (senza leggere lo stdin).

- **Invariante** (rafforza la regola by-convention di CLAUDE.md "ogni azione
  mutante rispetta DRY_RUN/YES"): **"non c'è tty" NON implica "sì, procedi".**
  Solo `--yes` esplicito autorizza a prendere un default. I LaunchAgent passano
  `--yes` → eseguono la loro selezione con i default (manutenzione voluta); una run
  non-TTY senza `--yes` non modifica nulla (fail-closed).

- **Alternative scartate**: (a) far sopravvivere l'auto-yes da non-TTY (il primo
  tentativo) — CRITICAL, auto-conferma distruttiva; (b) lasciare #8 com'era su main
  (fail-closed via read su pty morto) — sicuro ma fragile (dipende dal
  comportamento di `read` a EOF) e non chiudeva #8 esplicitamente.

- **Conseguenze**: ogni nuovo `_ask`/`_read_choice` eredita il comportamento
  corretto. Un modulo che muta SENZA passare per `_ask` NON è coperto (va sempre
  gated da un prompt o da DRY_RUN — vedi `mod_02` `brew update`, registrato come
  debito). Verifica di sicurezza di un fix a questa guard-rail: "cosa AUTORIZZA?"
  (adversariale), non solo "funziona?" → [[LEARNINGS]] IMP-004.
  Vedi [[lib-common]], [[core-brew-manager]], [[mod-las-scheduler]], [[mod-bk-brewfile]].
