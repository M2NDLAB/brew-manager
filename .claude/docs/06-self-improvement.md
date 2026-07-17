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

> **Perimetro del LIVELLO 1.** Riguarda la doc del METODO e del progetto GESTITO
> con questo framework. Durante un INNESTO su un progetto esistente (brownfield),
> la doc preesistente dell'ospite in
> disaccordo con la realtà NON si corregge d'ufficio: si registra in `STATE.md`
> ("Debito documentazione") e si corregge solo come task deciso dall'utente —
> prevale l'igiene di scope di `00-overview.md` (un cambiamento alla volta).
> A innesto COMPLETATO la doc dell'ospite È la doc del progetto gestito e rientra
> nel LIVELLO 1; restano fuori solo i debiti già registrati in `STATE.md`
> durante l'innesto, che si smaltiscono come task decisi dall'utente.

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

## Il ponte verso il framework — lezioni "framework-bound"

Finora ogni IMP è trattata come una lezione su QUESTO progetto. Ma quando il progetto
USA il framework (non È il framework), una parte delle lezioni non riguarda il progetto:
riguarda il METODO — una regola ambigua, un comando che manca, un passo di processo che
fa attrito ovunque, non solo qui. Quelle lezioni hanno una seconda destinazione, il repo
del framework, così da migliorare ANCHE il prossimo progetto che lo usa: è il "loop" che
fa evolvere il framework a partire dai progetti su cui è innestato.

**Come si marca.** Una IMP che riguarda il framework porta, nel suo corpo in
`LEARNINGS.md`, la riga `- Destinazione: framework` (vedi il formato IMP nell'header di
`LEARNINGS.md`). È un attributo di DESTINAZIONE, non un terzo livello: la lezione resta di
Livello 2 (si PROPONE, non si applica in autonomia) e segue il suo normale ciclo NEL
progetto; il marcatore aggiunge solo "questa, oltre che qui, va fatta risalire". Criterio
per marcarla: è utile a QUALSIASI progetto che usi il framework, non solo a questo. Riga
fisica singola, così `/harvest-framework` la raccoglie via grep.

**Come risale — `/harvest-framework`.** Il comando raccoglie dal backlog le IMP marcate
`Destinazione: framework` e ne STAMPA un blocco copiabile (problema → proposta →
beneficio), pronto per essere riproposto come IMP nel repo del framework. Il comando
**solo legge e stampa**: non clona, non copia file tra repo, non esegue git/push verso il
framework. Il travaso è **curatela umana**: chi lo esegue incolla il blocco, lo
**anonimizza** (nessun nome di questo progetto/cliente/ambiente nella storia condivisa del
framework — `04-git-workflow.md`) e lo registra come nuova proposta nel framework, dove
sarà valutata come un qualsiasi contributo secondo le sue regole.

**Perché questo confine.** Un comando che scrivesse davvero nel repo del framework
violerebbe due regole insieme: il confine di esecuzione — la storia condivisa la muove
l'umano, non l'agente (`04-git-workflow.md`) — e l'agnosticità: il template non sa nulla,
e non deve sapere nulla, dell'istanza concreta che lo usa (non conosce dove vive il repo
del framework rispetto al progetto). Il blocco copiabile è deliberatamente l'unico output:
rende il travaso esplicito, revisionabile e sotto controllo umano.

> Nel REPO DEL FRAMEWORK stesso l'attributo è moot: qui ogni IMP è già una lezione sul
> framework (regime ibrido dichiarato), quindi non si marca nulla e `/harvest-framework`
> non ha materiale da rastrellare. Il comando serve nei progetti-cliente.

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
