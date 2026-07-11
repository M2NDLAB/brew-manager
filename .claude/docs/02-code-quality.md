# 02 — Code quality: commenti, error handling, Definition of Done

Regole PERMANENTI valide in ogni sessione e per ogni linguaggio del progetto. Sono
principi agnostici allo stack: le convenzioni specifiche del linguaggio scelto
vanno in `CLAUDE.md` (*"Regole tecniche specifiche del progetto"*).

## Commenti — il codice spiega il COSA, i commenti spiegano il PERCHÉ

- Ogni unità pubblica (classe, modulo, funzione esportata): un commento di
  documentazione con responsabilità, perché esiste, invarianti, esempio d'uso se
  l'API non è ovvia. *(Lo strumento in questo progetto: blocco di commenti `#`
  prima della funzione, come già in uso in `lib/common.sh` e nei moduli — zsh non
  ha doc comment nativi.)*
- Ogni funzione pubblica non banale: cosa fa, parametri con vincoli (range, null),
  cosa lancia/ritorna in errore e quando, side effect.
- Blocchi di logica complessa: un commento PRIMA del blocco che spiega l'intento e
  il motivo dell'approccio scelto rispetto alle alternative.
- Workaround o scelte forzate: commento `// NOTA:` con il motivo e il link (issue,
  decisione, doc esterna). Mai un workaround silenzioso.
- VIETATO: commenti che ripetono il codice (`i++ // incrementa i`); codice
  commentato lasciato nei file (git è la storia, non i commenti); TODO senza
  riferimento (`// TODO(#issue): ...` è il formato accettato).
- Migrazioni di schema / SQL: ogni indice e ogni vincolo con un commento sul perché.

## Error handling — nessun errore non gestito, mai

- Niente catch vuoti o che si limitano a stampare lo stacktrace. Ogni gestione di
  errore: o gestisce davvero (retry, fallback, compensazione), o arricchisce e
  rilancia come errore di dominio, o logga con contesto e correlation-id e propaga.
  Mai inghiottire un errore.
- Gerarchia degli errori: gli errori di dominio estendono basi comuni; il bordo
  dell'applicazione li traduce in un formato di risposta uniforme. Esporre al client
  un formato d'errore strutturato e stabile *(in questo progetto il "client" è il
  terminale: errori SOLO tramite `_err`/`_warn` di `lib/common.sh`, con messaggio
  azionabile; l'output grezzo dei comandi falliti va nel log di sessione, non a
  video)*, mai
  stacktrace/query/path interni/versioni librerie: il dettaglio va nel log (con
  correlation-id), al client va il messaggio sintetico.
- Risorse: sempre rilasciate in modo sicuro (costrutto idiomatico del linguaggio).
  Operazioni I/O: timeout SEMPRE esplicito (mai default infiniti); retry solo su
  operazioni idempotenti.
- Validazione: input validato AL BORDO (sui DTO/richieste in ingresso). Dentro il
  dominio si assume input valido — fail-fast con un errore di programmazione se
  un'invariante è violata (segnala un bug, non un errore utente).
- Interfacce utente: ogni chiamata gestita, stato d'errore esplicito, messaggi
  comprensibili + un correlation-id visibile per il supporto.

## Best practices e pattern

- SOLID applicato pragmaticamente: in particolare dependency inversion (il dominio
  non importa MAI l'infrastruttura) e single responsibility (un'unità troppo grande
  è un segnale di refactor).
- Introduci un design pattern solo quando c'è un problema concreto da risolvere: un
  pattern senza problema è complessità gratuita.
- Immutabilità di default: tipi/valori immutabili dove possibile, stato mutabile
  solo dove serve davvero.
- Null safety: rendi esplicito nei tipi/firme ciò che può mancare; non usare valori
  "vuoti" ambigui dove il linguaggio offre un'alternativa migliore.
- Naming: il nome dice l'intento. Funzioni = verbi, predicati = is/has/can. Niente
  abbreviazioni salvo quelle universali (id, url).
- Magic numbers/strings: SEMPRE costanti nominate o configurazione esternalizzata.
- Concorrenza: stato condiviso mutabile = ultima risorsa; preferire immutabilità +
  message passing.
- Ogni nuova dipendenza: motiva nel commit perché serve, verifica licenza e
  manutenzione attiva. Preferire ciò che già c'è nel progetto.
- Formattazione: applicata in automatico dall'hook pre-commit (`make hooks-install`),
  così non si accumula drift e non servono commit di sola formattazione. Lo
  strumento in questo progetto: NESSUNO attivo — il blocco resta commentato in
  `scripts/hooks-install.sh` con un esempio `shfmt` pronto (shfmt/shellcheck non
  sono installati; decisione registrata all'innesto). Verifica minima manuale:
  `zsh -n` sui file toccati.
- Test della configurazione: non costruire gli oggetti di configurazione a mano nei
  test con lunghe liste di valori posizionali/`null` — aggiungere un campo
  romperebbe tutti i call-site, anche quelli che non lo usano. Usa builder/fixture o
  binding da una mappa, così l'aggiunta di una property non si propaga ai test
  esistenti.
- Verifica su artefatti REALI prima di decidere: mai derivare una decisione o un
  fix dalla sola memoria o da un debito registrato quando l'artefatto (codice,
  dati, config) è su disco — un debito può essere stato registrato con la CAUSA
  sbagliata. Verificarla (grep/lettura) costa poco; eseguire alla lettera una
  diagnosi errata costa molto.

## Test che dimostrano (non solo test verdi)

- Un test verde può passare per la ragione SBAGLIATA. Un fix si prova in modo che
  DIMOSTRI la catena reale: riproduci il difetto (RED), applica il fix isolando la
  variabile, mostra il passaggio a GREEN — non un generico "i test passano", che
  potrebbero passare anche col bug.
- Dove conta davvero (sicurezza, compliance, invarianti di dominio): test scritti
  come INVARIANTI riapplicate per COSTRUZIONE, non come asserzioni sullo stato noto
  oggi — es. un test che via reflection/introspezione asserisce una proprietà su
  TUTTE le entità, con controllo anti-vacuità (fallisce se l'insieme scandito è
  vuoto). Così una regressione futura rompe il build da sola, invece di aspettare
  che qualcuno si ricordi di aggiornare il test.

## Definition of Done di ogni task

1. Codice commentato secondo le regole sopra.
2. Errori tutti gestiti, nessun path che inghiotte eccezioni.
3. Test verdi (unit + integrazione dove applicabile). Per un componente con
   dipendenze reali, includere uno **smoke del sistema completo**: un test che avvia
   l'intero componente cablato (non solo unità isolate con mock) e verifica che le
   parti si "wirino" davvero — i gap di wiring che gli unit non vedono emergono qui.
   Per una UI deployabile l'analogo è uno smoke del MOUNT completo dell'app (es. un
   test end-to-end, o che renda l'app reale con la rete mockata): gli unit di
   componente usano provider di test e non vedono i bug del wiring reale.
4. Documentazione dell'API aggiornata se l'API è cambiata.
5. Nessun warning nuovo del compilatore/linter.
6. Migrazione di schema se lo schema dati è cambiato.
7. Documentazione di progetto aggiornata se la modifica tocca funzionalità utente,
   procedure operative, API o deploy *(dove vive la doc — `README.md`)*;
   se la doc di progetto non esiste ancora, debito annotato in `memory/STATE.md`.
8. Memoria aggiornata e commit fatto secondo `04-git-workflow.md` (il comando
   `/checkpoint` copre i punti 7 e 8 insieme).
9. Per un componente/app **deployabile** completato: esiste l'artefatto di
   produzione (in questo progetto NON applicabile: gli script del repo SONO
   l'artefatto, distribuito via `git clone`; l'equivalente pratico è: il modulo
   funziona da una copia pulita del repo, senza dipendere da stato locale).
   Questo NON emerge dai test eseguiti in ambiente di sviluppo: va verificato
   esplicitamente.

> Il gate di sicurezza per i componenti sensibili è un requisito AGGIUNTIVO alla
> Definition of Done: vedi `03-security-gate.md`.
