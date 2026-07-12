# plans/ — piani di task per i prompt onerosi

Un piano per ogni **prompt oneroso**, secondo il protocollo di task planning
(`.claude/docs/01-task-planning.md`). Un prompt grande non si esegue "tutto d'un
fiato": si spezza in **task atomici, ognuno con un commit**. Il piano è la
checklist che rende l'esecuzione **resiliente alle interruzioni** — se la sessione
muore al task N, i task 1..N-1 sono salvi su branch e si riprende dal task N, senza
ricostruire nulla a mano.

## Quando si crea
All'avvio di un prompt che Claude Code valuta oneroso (≈ più di 8-10 file, o ~400
righe, o che tocca più layer). Per i task piccoli NON serve un piano. Il piano si
crea e si **committa subito**, prima di iniziare i task, così sopravvive anche a un
crash immediato.

## Ciclo di vita
`status: in-progress` durante l'esecuzione → `status: completed` quando tutti i task
sono spuntati. All'inizio di ogni sessione, un piano `in-progress` segnala dove
riprendere.

## Naming
`<id-prompt>.md` — es. `01-scaffold.md`, `03-modulo-x.md`.

## Formato
```markdown
---
type: plan
prompt: <id-prompt>
branch: <feature branch dedicato>
created: YYYY-MM-DD
status: in-progress | completed
tags: [plan, <area>]
---
# Piano: <prompt>

## Obiettivo
<1-2 righe: cosa deve esistere a piano completato>

## Task
- [ ] 1. <task atomico, committabile da solo> — commit: —
- [ ] 2. <...> — commit: —
- [ ] 3. <...> — commit: —

## Note di ripresa
<vuoto all'inizio; qui si annotano stato e decisioni utili a una sessione futura>

## Collegamenti
[[<componente>]] · [[STATE]]
```

Regole sui task (sintesi — dettaglio in `docs/01`): ogni task atomico e
committabile, ordinati per dipendenza, 6-12 task è il range sano, un commit per
task con `[task N/T]` nel messaggio, si spunta il task col suo sha.

> Questo README resta come guida; i piani vivono accanto ad esso.
