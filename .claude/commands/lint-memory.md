---
description: Health-check di coerenza della memoria/wiki — trova contraddizioni e disallineamenti e propone la correzione
---
Esegui un LINT della memoria persistente (`.claude/memory/`) e dei rimandi di
processo: un health-check della COERENZA della base di conoscenza, su: $ARGUMENTS
(se vuoto: su tutta la memoria).

Questo NON è una retrospettiva di processo (`/retro`, vedi @.claude/docs/06-self-improvement.md):
la retro propone COSA MIGLIORARE nel workflow; il lint verifica la SALUTE dei DATI.
**Quando si esegue** (vedi il ciclo in @.claude/docs/00-overview.md): NON a ogni
deliverable — periodicamente, di norma insieme alla retrospettiva periodica sul
backlog IMP, e dopo eventi che toccano molte note in una volta (merge grossi,
ristrutturazioni della memoria, riscritture ampie di `STATE.md`).
**Criterio di risoluzione**: questo è un framework per software — una contraddizione
è un BUG, non una tensione da preservare. Il lint SEGNALA e PROPONE la correzione,
allineando sempre lo stato alla realtà (mai il contrario — salvo che la realtà violi
una regola: allora è un bug di processo, non di memoria, e va in escalation/IMP).

## Controlli
1. **Stato vs realtà.** `STATE.md` (avanzamento, "Branch attivi", "Cosa esiste")
   allineato con git? Verifica con `git branch`, `git branch --merged <integrazione>`,
   `git log --oneline -10`: branch dati per esistenti ma già mergiati/eliminati,
   feature "in corso" che risultano già committate, "ultimo" stantio.
2. **Contraddizioni tra note.** Decisioni (`decisions/`), note di componente
   (`components/`) e di sessione (`sessions/`) che si contraddicono tra loro o con
   `STATE.md`.
3. **Claim stantii.** Affermazioni rese obsolete da fatti più recenti (una decisione
   superata da una successiva senza che la prima sia marcata come tale).
4. **Pagine orfane.** Note senza alcun riferimento entrante (non citate da `INDEX.md`
   né da `[[wikilink]]` di altre note): o sono da collegare, o sono morte.
5. **Concetti senza pagina.** Concetti/componenti citati ripetutamente nelle note ma
   privi di una pagina propria — candidati a una nota dedicata.
6. **Cross-reference mancanti.** Note chiaramente correlate non collegate da
   `[[wikilink]]`; `INDEX.md` che non elenca note realmente esistenti.
7. **Link rotti.** `[[wikilink]]` che puntano a note inesistenti.
8. **Coerenza di `TREE.md`.** Allineato alla struttura reale del filesystem
   (rigenerabile come da `/checkpoint`).
9. **Coerenza `LEARNINGS` ↔ `STATE`.** Gli item registrati sono allineati tra i
   file: una IMP rimandata il cui trigger è vicino o bloccante compare anche tra i
   problemi aperti di `STATE.md` (e viceversa); il debito accettato dal security
   gate (docs/03) vive in `STATE.md` col motivo; ogni voce di debito ha il suo
   TRIGGER esplicito, non è generica.

## Output e risoluzione
Una tabella: **Area | Problema rilevato | Tipo** (disallineamento / contraddizione /
orfano / link rotto / claim stantio) **| Correzione proposta**.

- **Correzioni meccaniche e a basso rischio** (rigenerare `TREE.md`, riconciliare
  "Branch attivi" con git, aggiungere un `[[wikilink]]` mancante, fixare un link
  rotto): APPLICALE e dichiaralo.
- **Casi che richiedono giudizio** (quale di due note contraddittorie è quella
  giusta, quale claim è quello vero): PROPONI e chiedi conferma, non indovinare.

Se un disallineamento rivela un buco di PROCESSO (non solo di dati), registralo come
IMP in `LEARNINGS.md` (docs/06): è l'unico ponte tra il lint e la retrospettiva.
