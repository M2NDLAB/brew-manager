---
description: Raccoglie le IMP marcate "Destinazione: framework" e stampa un blocco copiabile da riproporre al repo del framework — solo legge e stampa, mai clone/copia/push/cross-repo
---
Raccogli le lezioni destinate al FRAMEWORK e preparane il blocco da riportare a monte,
per: $ARGUMENTS (se $ARGUMENTS è vuoto: sull'intero backlog di `LEARNINGS.md`).

Vedi il ponte in @.claude/docs/06-self-improvement.md (*"Il ponte verso il framework"*).
Complementare a `/retro`: `/retro` REGISTRA le IMP (e ci mette il marcatore
`Destinazione: framework` quando la lezione riguarda il metodo); `/harvest-framework` le
RACCOGLIE per farle risalire.

Questo comando **solo legge e stampa**: NON clona, NON copia file tra repo, NON esegue
git/push verso il framework (confine di esecuzione — `04-git-workflow.md` — e agnosticità:
il progetto non conosce, e non deve conoscere, dove vive il repo del framework). Il travaso
e la ri-registrazione
come IMP nel framework restano curatela UMANA.

## 1. Contesto (il comando è moot nel repo-framework)
Se stai girando NEL repo del framework stesso (regime ibrido: ogni IMP è già una lezione
sul framework), non c'è nulla da distinguere né rastrellare: dillo e fermati. Il comando
serve nei progetti-CLIENTE, dove `LEARNINGS.md` è il backlog del progetto e solo ALCUNE
IMP sono framework-bound.

## 2. Raccogli (read-only)
1. Trova le voci marcate: `grep -n "Destinazione: framework" .claude/memory/LEARNINGS.md`
   (il marcatore è per convenzione una riga fisica singola).
2. Definisci il perimetro:
   - default (`$ARGUMENTS` vuoto): TUTTE le IMP marcate, in qualunque sezione
     (APERTE / Applicate / Rimandate) — il backlog intero;
   - con `$ARGUMENTS`: restringi al criterio dato (una IMP specifica `IMP-nnn`, una
     data/sessione, una sezione). Interpreta `$ARGUMENTS` come filtro sulle voci trovate.
3. Per ciascuna voce nel perimetro, leggi il corpo dell'IMP in `LEARNINGS.md` e raccogli:
   numero e titolo, Origine, Problema osservato, Proposta, Beneficio/rischio.

## 3. Anti-vacuità (obbligatoria)
Se NESSUNA IMP è marcata `Destinazione: framework` nel perimetro scelto: NON stampare un
blocco vuoto. Dichiara esplicitamente che non c'è materiale framework-bound, ricorda come
si marca una lezione (la riga `- Destinazione: framework` nel corpo dell'IMP, vedi il
formato in `LEARNINGS.md`) e fermati. Un output vuoto silenzioso sembrerebbe "tutto
raccolto" quando non lo è.

## 4. Stampa il blocco RACCOLTA PER IL FRAMEWORK
Un unico blocco di codice copiabile. Per ogni lezione usa il formato di una proposta IMP
del framework (così è pronta da incollare nel suo `LEARNINGS.md`), MA con i riferimenti
locali ANONIMIZZATI: nessun nome di questo progetto/cliente/ambiente, nessun path
specifico del progetto, nessuno SHA locale (docs/04: la storia condivisa del framework è
agnostica). Riformula "Origine" in termini generici ("emerso lavorando su un progetto che
usa il framework"), mai con l'identità del progetto.

```
===== RACCOLTA PER IL FRAMEWORK =====
# Riproponi ciascuna voce come IMP nel repo del framework (il numero si riassegna là).
# PRIMA di incollare: verifica che NON restino nomi/paths/SHA di questo progetto.

### <titolo della lezione>            (era IMP-<nnn> in questo progetto)
- Origine: <contesto generico e anonimo>
- Problema osservato: <...>
- Proposta: <cosa cambiare NEL framework: CLAUDE.md / docs/NN / comando / hook / processo>
- Beneficio atteso / rischio: <...>

### <titolo della lezione successiva> (era IMP-<nnn> in questo progetto)
- ...
===== FINE RACCOLTA =====
```

## 5. Chiudi
- Ricorda che il passo successivo è UMANO: aprire il repo del framework e registrare le
  voci come proposte IMP, una per una, secondo le regole del framework, dopo aver
  riverificato l'anonimizzazione.
- NON marcare nulla come "già risalito" e NON modificare `LEARNINGS.md`: il comando non
  muta stato. La de-duplicazione tra harvest successivi è curatela umana — per non
  ri-rastrellare le lezioni già portate a monte, restringi con `$ARGUMENTS` (es. a una
  data) oppure annota tu a mano le voci già risalite.
- Poi FERMATI.
