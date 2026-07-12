# components/ — conoscenza durevole sui componenti

Una nota per ogni **componente/modulo significativo** del progetto (un servizio,
una libreria, un'app, un sottosistema). Cattura la conoscenza che NON si deduce a
colpo d'occhio dal codice: cosa espone, le invarianti, le insidie (gotcha), i
vincoli per chi lo usa, le decisioni locali. È la documentazione "viva" che Claude
Code carica all'inizio di una sessione **solo per i componenti toccati dal task**
(vedi la sezione memoria di `CLAUDE.md`) — per questo va tenuta densa e aggiornata.

A differenza delle sessioni (append-only), queste note si **aggiornano**: devono
riflettere lo stato attuale del componente, non la sua storia (la storia è in
`sessions/` e in git).

## Quando si scrive / aggiorna
Alla nascita del componente e a ogni modifica sostanziale, dentro `/checkpoint`.

## Naming
`<componente>.md` — es. `auth.md`, `core-lib.md`, `web-app.md`.

## Formato
```markdown
---
type: component
component: <nome>
updated: YYYY-MM-DD
tags: [component]
---
# <nome>

<una riga: cos'è e a cosa serve.>

## Stato attuale
<creato quando, livello di maturità, test, ecc.>

## Cosa espone / responsabilità
<API pubbliche, contratti, eventi, configurazione rilevante.>

## Vincoli e insidie (per chi lo usa o lo modifica)
<gotcha, ordini di inizializzazione delicati, assunzioni implicite,
 cose che sembrano modificabili ma non lo sono — col PERCHÉ.>

## Sessioni che l'hanno toccato
- [[sessions/YYYY-MM-DD-<slug>]]
```

> Questo README resta come guida; le note di componente vivono accanto ad esso.
