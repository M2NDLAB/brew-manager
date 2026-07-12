# decisions/ — registro delle decisioni

Una nota per ogni **decisione che vale la pena tracciare**: cosa è stato deciso,
perché, quali alternative sono state scartate e con quale motivo. Serve a non
ri-discutere all'infinito le stesse scelte e a capire, mesi dopo, il razionale
dietro qualcosa che oggi sembra strano.

## Due livelli di decisione

- **Decisioni architetturali significative** (impattano la struttura, sono costose
  da invertire): brew-manager NON adotta ADR formali — tutte le decisioni si
  registrano qui per intero (il progetto è piccolo e a sviluppatore singolo).
- **Decisioni leggere** (una libreria minore, una convenzione di naming, una scelta
  di struttura): si registrano direttamente qui, per intero.

Se il progetto non adotta ADR formali, va benissimo tenere TUTTE le decisioni qui.

## Naming
`YYYY-MM-DD-<slug>.md`. Se sono rimandi ad ADR numerati:
`YYYY-MM-DD-adr-NNNN-<slug>.md`.

## Formato — decisione leggera
```markdown
---
type: decision
updated: YYYY-MM-DD
tags: [decision]
---
# <titolo della decisione>

- **Contesto**: <quale problema/forza ha richiesto una scelta>
- **Decisione**: <cosa è stato deciso>
- **Alternative scartate**: <e perché>
- **Conseguenze**: <impatto, trade-off accettati>
```

## Formato — rimando a un ADR formale
```markdown
---
type: decision
adr: NNNN
updated: YYYY-MM-DD
tags: [decision, adr-pointer]
---
# Rimando → ADR NNNN — <titolo>

Il testo autorevole è in <percorso dell'ADR>. Qui solo la sintesi e i collegamenti.
- **Sintesi**: <2-3 righe>
- **Impatto / collegamenti**: [[<altra-decisione>]], [[<componente>]]
```

> Questo README resta come guida; le note di decisione vivono accanto ad esso.
