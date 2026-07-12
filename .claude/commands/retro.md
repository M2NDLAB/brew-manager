---
description: Retrospettiva - rivedi i learnings e proponi miglioramenti di processo
---
Esegui una retrospettiva di miglioramento secondo
@.claude/docs/06-self-improvement.md su: $ARGUMENTS
(se $ARGUMENTS è vuoto: sulle ultime sessioni registrate in memoria).

Due intensità d'uso (vedi il ciclo in @.claude/docs/00-overview.md):
- **A fine deliverable** (passo fisso del ciclo, PRIMA di `/checkpoint`): riflessione
  LEGGERA — esegui i passi 1-3 e REGISTRA gli eventuali IMP; senza attrito è un no-op
  di pochi secondi. Le decisioni (passi 4-6) si possono rimandare.
- **Periodica / on-demand**: review COMPLETA del backlog accumulato — tutti i passi,
  con le decisioni dell'utente sulle IMP aperte.

1. Leggi .claude/memory/LEARNINGS.md e le note di sessione recenti in
   .claude/memory/sessions/.
2. Cerca pattern: errori ripetuti, escalation risolte le cui lezioni non sono ancora
   diventate proposte, attriti di processo, doc rilette/fraintese, finding di
   security review sistemici.
3. Per ogni pattern trovato: crea o aggiorna una proposta IMP-nnn nel backlog
   (problema osservato → proposta concreta → beneficio/rischio).
4. Presenta all'utente le proposte APERTE in una tabella:
   ID | Problema | Proposta | Impatto stimato | Consigliata sì/no e perché.
5. ATTENDI la decisione dell'utente per ciascuna: approva / rifiuta / rimanda.
6. Applica le approvate (commit dedicato per ciascuna), sposta le rifiutate in
   "Rifiutate" col motivo e le rimandate in "Rimandate" col trigger di ripresa.

NON modificare regole o config senza approvazione esplicita — solo le correzioni
fattuali di Livello 1 sono auto-applicabili.
