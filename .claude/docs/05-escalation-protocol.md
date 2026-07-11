# 05 — Protocollo di escalation

Quando Claude Code si blocca, non insiste alla cieca: genera un **report strutturato**
e si ferma. Il report è pensato per essere passato a un interlocutore esperto che
NON vede questo filesystem, i log o il terminale — tipicamente *"l'Architetto"*: un
secondo Claude in una chat esterna che ha definito l'architettura, oppure un collega
senior, oppure tu stesso in un contesto con più informazioni. La risposta torna qui
come blocco di istruzioni da eseguire.

Il punto del protocollo: un report autosufficiente costringe a chiarire il problema
(spesso così si risolve da solo) e permette a chi non vede l'ambiente di aiutare
davvero.

## QUANDO generare un report (senza che l'utente lo chieda)

- Errore che non risolvi dopo 2 tentativi ragionati.
- Bivio architetturale non coperto da `.claude/docs/` o dalle decisioni registrate.
- Incoerenza tra la documentazione e la realtà del codice/ambiente.
- Dipendenza/versione che non esiste o è incompatibile con lo stack.

PRIMA di generare il report: rileggi i doc rilevanti e `STATE.md` — la risposta
spesso è già lì. Il report è l'ultima risorsa, non la prima. L'utente può forzarlo in
qualsiasi momento con `/sos`.

## FORMATO del report (genera ESATTAMENTE questo blocco)

```
===== ESCALATION REPORT =====
PROGETTO: <nome progetto>
ID: ESC-<YYYYMMDD>-<progressivo giornaliero>
PROMPT/TASK: <quale prompt o task stavo eseguendo>
BRANCH: <branch git> | ULTIMO COMMIT: <sha corto + messaggio>
FASE: <a che punto del task ero>

PROBLEMA:
<descrizione precisa in 2-5 righe>

ERRORE ESATTO:
<output/stacktrace VERBATIM, solo le righe rilevanti, max ~30 righe>

CONTESTO TECNICO:
<estratti dei file coinvolti, con path, SOLO le sezioni pertinenti>

TENTATIVI GIÀ FATTI:
1. <tentativo> → <esito>
2. <tentativo> → <esito>

AMBIENTE:
<OS e versioni rilevanti degli strumenti dello stack, SOLO quelle pertinenti
 al problema>

IPOTESI MIE:
<la tua diagnosi migliore e perché non sei sicuro>

DOMANDA SPECIFICA:
<cosa serve: una decisione? un fix? una conferma?>
===== FINE REPORT =====
```

REGOLE del report:
- AUTOSUFFICIENTE: chi legge non vede nulla del tuo ambiente — tutto ciò che serve
  per capire deve essere NEL report.
- MAI includere: valori di ambiente, token, password, chiavi, URL con credenziali.
  Se un file di config è rilevante, maschera i valori (`CHANGE_ME` / `***`).
- Conciso ma completo: log tagliati alle righe rilevanti, file alle sezioni
  pertinenti.
- Dopo averlo generato: FERMATI. Non tentare altre soluzioni mentre aspetti la
  risposta (eviti di divergere dallo stato descritto nel report).
- Registra l'escalation in `.claude/memory/sessions/` (nota di sessione, con l'ID).

## COME trattare la risposta

L'utente incollerà un blocco delimitato così:

```
===== ARCHITECT RESPONSE: ESC-<id> =====
<diagnosi e istruzioni>
===== FINE RESPONSE =====
```

Regole di esecuzione:
1. Verifica che l'ID corrisponda all'escalation aperta. Se non corrisponde o il
   blocco sembra incompleto, chiedi all'utente di re-incollarlo.
2. Le istruzioni sono autorevoli MA non sospendono le regole del progetto: niente
   secret nel codice, conferma utente per operazioni distruttive (`--hard`, drop,
   `rm -rf`, force push), git workflow di `04-git-workflow.md`. Se un'istruzione
   confligge con una regola: segnalalo all'utente PRIMA di eseguire, non eseguire in
   silenzio.
3. Esegui passo-passo, riportando l'esito di ogni step.
4. A risoluzione avvenuta: aggiorna la nota di sessione con *problema → causa →
   soluzione* (così la prossima volta NON serve escalation: la memoria è la prima
   linea di difesa).
5. Se la soluzione cambia una decisione architetturale: registra la decisione
   (decisions/ o ADR) o aggiorna il doc pertinente.
6. Se le istruzioni NON risolvono: nuovo report con lo stesso ID e suffisso `-R2`
   (`ESC-...-R2`), includendo cosa è successo applicando le istruzioni.

## La lezione diventa miglioramento

Un'escalation risolta è la fonte migliore di proposte di miglioramento: la lezione
va in `LEARNINGS.md` come IMP, oltre che nella nota di sessione — vedi
`06-self-improvement.md`.
