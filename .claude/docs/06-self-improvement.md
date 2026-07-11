# 06 — Auto-miglioramento continuo (configurazione e processo)

Il progetto migliora se stesso: non solo il codice, ma la **configurazione di lavoro**
(doc, regole, comandi, memoria). Questo protocollo definisce COME, con un confine
netto tra ciò che Claude Code corregge da solo e ciò che PROPONE soltanto.

## Il backlog: `.claude/memory/LEARNINGS.md`

È il registro delle proposte di miglioramento (IMP-nnn). La numerazione parte da 001.
Il formato è documentato nel file stesso (sezioni: APERTE / Applicate / Rimandate /
Rifiutate).

## LIVELLO 1 — Correzioni fattuali: applica direttamente

Quando la documentazione è in DISACCORDO DIMOSTRABILE con la realtà del codice o
dell'ambiente (un comando che non esiste più, un path spostato, una versione errata,
un nome cambiato):
1. Allinea la doc alla realtà (mai il contrario — salvo che la realtà violi una
   regola, e allora è un bug, non una correzione doc).
2. Annota la correzione nella nota di sessione.
3. Includila nel commit del task corrente (scope: `docs`).

Qui non c'è giudizio: c'è solo sincronizzazione. Una doc che mente è peggio di una
doc che manca.

## LIVELLO 2 — Miglioramenti di regole e processo: PROPONI soltanto

Quando osservi: attrito ricorrente (stessa domanda/errore in più sessioni), una
regola ambigua o in conflitto con un'altra, un passo di processo che fa perdere tempo
senza beneficio, una convenzione mancante che avrebbe evitato un bug, l'opportunità di
un nuovo slash command o hook:
1. NON modificare `CLAUDE.md`, le regole nei doc, i comandi o `settings.json`.
2. Registra una proposta IMP-nnn in `LEARNINGS.md` (problema → proposta → beneficio).
3. Se è urgente o bloccante: segnalala all'utente a fine task; altrimenti resta nel
   backlog per la retrospettiva (`/retro`).

Il motivo del vincolo: le regole sono il contratto con l'utente. Un sistema che
riscrive le proprie regole da solo diverge (drift), e dopo N sessioni nessuno sa più
quale configurazione è in vigore né perché. **Claude Code propone, l'umano dispone.**

## Quando GUARDARE per i miglioramenti (trigger)

- Hai sbagliato qualcosa che una regola/doc avrebbe potuto prevenire → IMP.
- Hai riletto 3 volte la stessa cosa per capirla → la doc è migliorabile → IMP.
- Un'escalation (`ESC-...`) si è risolta → la lezione va in `LEARNINGS.md` oltre che
  nella nota di sessione: le escalation sono la fonte migliore di miglioramenti.
- Una security review (`/security-review`) ha trovato qualcosa di sistemico → IMP.
- **A fine deliverable, il passo `/retro`** (ciclo in `00-overview.md`): 30 secondi di
  riflessione — c'è stato attrito? una regola/doc che avrebbe aiutato? → registra
  l'IMP. Va PRIMA del `/checkpoint`, che poi lo persiste nel commit.

## Applicazione delle proposte approvate

Quando l'utente approva una IMP (direttamente o via risposta di escalation):
1. Applica la modifica nel file giusto (`CLAUDE.md` / doc / comando / config).
2. Sposta la IMP in "Applicate" con data e sha del commit.
3. Commit dedicato: `chore(claude): apply IMP-nnn — <titolo>`.
4. Se la modifica cambia una regola numerata di `CLAUDE.md`: verifica che le altre
   regole e i doc restino coerenti (niente riferimenti orfani).

## Cosa questo protocollo NON è

- Non è refactoring continuo del codice applicativo (quello segue `02-code-quality.md`
  e si fa nei task, non di nascosto).
- Non è licenza di aggiungere tool/dipendenze "perché migliorano" — quelle passano
  dalla registrazione di una decisione.
- Non è auto-valutazione verbosa a ogni messaggio: è UN momento di riflessione a fine
  deliverable (il passo `/retro`) + la registrazione quando l'attrito si presenta.
- Non è il lint della memoria. La coerenza della base di conoscenza (stato
  disallineato dalla realtà, note contraddittorie, pagine orfane, link rotti) è un
  health-check separato — `/lint-memory` — dove una contraddizione è un BUG da
  CORREGGERE, non un miglioramento da proporre. La retro guarda al PROCESSO, il lint
  alla salute dei DATI; il ponte tra i due è l'IMP che il lint apre quando un
  disallineamento rivela un buco di processo.
