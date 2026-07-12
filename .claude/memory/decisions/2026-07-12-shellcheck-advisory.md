---
type: decision
updated: 2026-07-12
tags: [decision]
---
# make lint è advisory: shellcheck non può fare da gate su codice zsh

- **Contesto**: BM-01 chiede `make lint` che "esegue shellcheck solo se presente".
  Verificando lo strumento reale: shellcheck NON ha un dialetto zsh (supporta solo
  sh/bash/dash/ksh; su shebang zsh emette SC1071). Tutto il codice del progetto è
  zsh con costrutti zsh-only (`${(P)var}`, `read -rA`, `typeset -A`).
- **Decisione**: `make lint` esegue shellcheck con `--shell=bash --severity=warning`
  se installato, mostra i finding ma NON fallisce mai (advisory); skip pulito se
  assente. Il gate di sintassi resta `make check` (`zsh -n`, quello sì bloccante).
- **Alternative scartate**: (a) `--shell=bash` bloccante — scartata: falsi positivi
  garantiti sui costrutti zsh → lint permanentemente rosso appena qualcuno installa
  shellcheck; (b) omettere lint — scartata: su codice portabile/sh-like shellcheck
  dà comunque segnale utile come advisory.
- **Conseguenze**: la regola trasversale della roadmap "shellcheck pulito dove
  installato" NON è applicabile letteralmente su zsh: va letta come "finding
  advisory esaminati, non zero finding". Se il progetto mai migrasse a bash, il
  target può diventare bloccante rimuovendo il fallback `|| echo`.
