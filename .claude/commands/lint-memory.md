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
10. **Marcatori `[DA DEFINIRE AL SETUP]` grep-visibili.** Nessuno *slot* da compilare
    è spezzato dal word-wrap su due righe fisiche: sfuggirebbe al `grep -rn "DA
    DEFINIRE AL SETUP" .` che li individua, restando non compilato in silenzio.
    Sentinella: `grep -rn "DA DEFINIRE AL$" .` — ogni hit è un candidato. Falsi
    positivi NOTI da ignorare (prosa che *discute* il marcatore, non uno slot): i
    record IMP di `LEARNINGS.md`. Un hit altrove, o che è davvero uno slot fillable,
    va ricompattato su una sola riga fisica.
11. **Inventari vs realtà.** Le liste-inventario ENUMERATE qui sotto corrispondono
    al filesystem? Confronto insiemistico nei DUE versi: voce che ESISTE ma manca
    dall'inventario; voce ELENCATA ma inesistente. Si controllano SOLO le liste
    enumerate — mai le menzioni in prosa altrove (è l'enumerazione a evitare i
    falsi positivi lista-vs-prosa):
    (a) file in `.claude/commands/` ↔ elenco "Comandi rapidi" di `CLAUDE.md` e,
        dove presente, la riga `commands/` della "Struttura" del `README.md`;
    (b) target di PROCESSO del `Makefile` ↔ gli stessi elenchi. Di processo = la
        ricetta invoca uno script di `scripts/` (ancoraggio STRUTTURALE, non
        posizionale: regge anche quando il setup compila o rimuove il banner
        `[DA DEFINIRE AL SETUP]`); `help` è escluso (meta-target che stampa la
        lista) e i target di PROGETTO (build/test/run dello stack) sono FUORI
        perimetro — mai segnalarli;
    (c) file in `scripts/` ↔ tabella di `scripts/README.md`.
    Una voce vale anche in forma equivalente (`make reset-task` ≡
    `./scripts/reset-task.sh`). Mismatch = BUG (semantica del lint): si allinea la
    doc alla realtà. Esclusi per dichiarazione, come nel controllo 10 (registrano
    stati PASSATI, non inventari dello stato corrente): i documenti append-only
    (`CHANGELOG.md`) e i record IMP di `LEARNINGS.md`. Nei progetti-cliente
    valgono i soli file copiati dal template (il `README.md` del framework non è
    tra questi).

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
