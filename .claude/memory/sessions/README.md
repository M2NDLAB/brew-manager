# sessions/ — diario di lavoro (append-only)

Una nota per ogni **sessione di lavoro** significativa. È la memoria narrativa del
progetto: *cosa è stato fatto, cosa è andato storto e come si è risolto, cosa è
stato deciso al volo*. A differenza di `STATE.md` (che si riscrive ed è un
cruscotto del presente), le note di sessione sono **append-only**: non si
modificano a posteriori, si accumulano. Sono la prima linea di difesa contro il
"perché diavolo l'avevamo fatto così?" — e la fonte migliore di proposte di
miglioramento (vedi `docs/06-self-improvement.md`).

## Quando si scrive
A fine task/sessione, tipicamente dentro `/checkpoint`. Anche un'escalation
(`docs/05`) va registrata qui con il suo ID. E SEMPRE prima di un `/clear` o di un
cambio di modello, se in chat c'è lavoro costoso non ancora persistito (un
assessment, una review, decisioni prese al volo): il contesto di chat si perde, la
nota no — e il prompt successivo potrà PUNTARE alla nota invece di ricostruire.

## Naming
`YYYY-MM-DD-<slug-breve>.md` — es. `2026-06-14-setup-iniziale.md`,
`2026-06-15-modulo-pagamenti.md`. La data davanti tiene l'ordine cronologico.

## Formato
```markdown
---
date: YYYY-MM-DD
task: <cosa si stava facendo>
branch: <branch git>
status: completed | in-progress | blocked
tags: [session, <area>]
---
# Session YYYY-MM-DD — <titolo>

## Fatto
- <elenco puntuale di ciò che è stato prodotto, con i commit/sha rilevanti>

## Problemi incontrati → causa → soluzione
1. <sintomo> → <causa radice> → <fix>

## Correzioni fattuali doc (Livello 1, docs/06)
- <doc allineata alla realtà, se è successo>

## Proposte
- IMP-nnn (in LEARNINGS.md): <eventuale proposta di miglioramento emersa>

## Follow-up
- <eventuali code aperte riprese in una data successiva>
```

> Questo README resta come guida; le note di sessione vivono accanto ad esso.
