---
type: learnings
updated: 2026-07-12
tags: [improvement]
---
# Learnings & proposte di miglioramento

> **Cos'è questo file.** Il backlog dell'auto-miglioramento di processo (vedi
> `.claude/docs/06-self-improvement.md`). Qui Claude Code registra le proposte di
> modifica a regole, doc, comandi e configurazione (IMP-nnn) — ma NON le applica
> da solo: le applica solo dopo approvazione dell'utente. Le correzioni puramente
> FATTUALI alla doc (Livello 1) non passano da qui, si applicano subito.
>
> La numerazione delle IMP di brew-manager parte da **001**. Le IMP del
> claude-code-framework (001–026 nel repo del framework) NON si ereditano: questo
> file è nato vuoto all'innesto (2026-07-12, framework v0.2.0). Le frizioni
> brownfield osservate durante l'innesto sono materiale per il FRAMEWORK, non per
> questo progetto: sono annotate in
> [[sessions/2026-07-11-innesto-note]].
>
> **Attributo `Destinazione: framework`.** In un progetto-CLIENTE una IMP può
> riguardare il FRAMEWORK invece che questo progetto: si marca con la riga
> `- Destinazione: framework` (riga fisica singola, così `/harvest-framework` la
> raccoglie via grep). Omessa = lezione-di-questo-progetto, che resta nel cliente.
> È un attributo di DESTINAZIONE, non un livello: la lezione resta di Livello 2 —
> vedi `docs/06-self-improvement.md`, *"Il ponte verso il framework"*. NEL REPO DEL
> FRAMEWORK l'attributo è moot (ogni IMP è già framework) e non si usa sulle voci.

## Proposte APERTE (in attesa di decisione utente)

### IMP-002 — Checklist "superficie del contratto" per i test di estrazione/parità
- Data: 2026-07-17 | Origine: gate di sicurezza BM-08a. Parità/injection/scope
  PULITI, ma 5 finding confermati TUTTI in test-adequacy: return-code mai
  asserito, whitespace di bordo, token vuoti in lista, molteplicità dei warning
  (N per N token invalidi), special maiuscoli BK/LAS/MAS.
- Problema osservato: la PRIMA suite di una funzione estratta per parità, pur con
  la guardia anti-vacuità già prescritta da docs/02, ha coperto le classi di
  input "felici" ma non l'intera superficie osservabile del contratto. Il gate
  adversariale l'ha scoperto — bene — ma a valle dell'implementazione; una
  checklist a monte avrebbe prodotto la copertura giusta al primo colpo (subito
  utile: BM-08b/c estenderanno lo stesso resolver).
- Proposta: aggiungere a `docs/02-code-quality.md` (sezione "Test che dimostrano")
  una checklist BREVE per i test di ESTRAZIONE/PARITÀ — enumerare la superficie
  del contratto: (a) valore di ritorno / exit code per OGNI esito; (b) ogni
  classe di input inclusi i BORDI (whitespace di bordo, token vuoti,
  case-variant); (c) molteplicità dei side-effect (N eventi per N cause, non solo
  "almeno uno"); (d) verifica per MUTAZIONE che la suite fallisca se il contratto
  viene invertito, prima di dichiarare done.
- Beneficio atteso / rischio: copertura completa al primo colpo, meno cicli
  gate→hardening. Rischio: una checklist può irrigidire — va tenuta come guida
  proporzionale (docs/00), non come rito per ogni micro-test.
- Trigger di ripresa: decisione utente (prossima retro periodica, oppure ora).
- **Rafforzata dal gate BM-08b** (2026-07-17): il gate ha trovato un gap di
  strictness sui token vuoti (`0,4,` → errore col nome vuoto) — esattamente un
  caso di "bordo/molteplicità" che la checklist IMP-002 avrebbe fatto scrivere
  a monte. Segnale a favore dell'adozione.
- **Rafforzata dalla verifica README v1.3.0** (2026-07-18): il claim "unknown
  module token → exit non-zero" era stato scritto asserendo l'exit del FIGLIO
  (rc=2 di `_resolve_cli`, unit-testato) ma mai quello END-TO-END del processo
  che l'utente invoca: il wrapper script(1) perde l'exit 2 del figlio nella
  strip ANSI e il parent esce 0. È il punto (a) della checklist — "exit code per
  OGNI esito" — misurato al bordo REALE del programma, non all'unità interna.

### IMP-003 — Convenzione: mai `echo` per normalizzare DATI (espande gli escape)
- Data: 2026-07-17 | Origine: gate di sicurezza BM-08b, finding MEDIUM R1.
- Problema osservato: `_n=$(echo "$_n" | tr -d ' ')` nel resolver espandeva i
  backslash-escape dell'input (`echo '\065'`→`5`), così un token fasullo veniva
  REMAPPATO su un id di modulo reale → `./brew_manager.sh '\065'` eseguiva mod_05
  (cleanup distruttivo) invece di fallire. È un pattern **fail-open**, ed era
  **pre-esistente**: il parity-move di BM-08a l'aveva trasportato verbatim (la
  parità è "behavior-neutral" ma preserva anche i bug latenti). Stessa radice di
  Attenzione #3b, che però traccia le ISTANZE, non previene la classe. Fixato in
  BM-08b con `${_n// /}` (param expansion).
- Proposta: aggiungere alle "Convenzioni di codice" di `CLAUDE.md` (regole tecniche)
  una riga by-convention (docs/03, "Prevenzione by-convention"): *"Per
  normalizzare/ripulire una stringa di DATI (specie input non fidato) usa la
  parameter expansion (`${v// /}`, `${v//$'\t'/}`) o `printf '%s'` — MAI `echo`,
  che espande `\e`/`\0NN`/`\x..` e può reinterpretare un token in un valore
  diverso. `echo -e` vale anche per i messaggi che interpolano dati (vedi il
  display di `_err`)."* Corollario: un parity-refactor che sposta codice di
  parsing di input non fidato deve SEGNALARE i pattern fail-open che preserva,
  invece di trattarli come neutri.
- Beneficio atteso / rischio: previene un'intera classe di bypass di validazione
  (chiude a monte #3b e casi simili). Rischio: quasi nullo — è una convenzione,
  non un cambio di codice; va applicata al codice nuovo, gli istanze vecchie
  restano tracciate in #3b.
- Trigger di ripresa: decisione utente (prossima retro periodica, oppure ora).
- **Rafforzata dal gate BM-09** (2026-07-19): il primitivo NUOVO `_box` rendeva
  il suo TITLE via `echo -e` — la stessa trappola echo-on-data — in un componente
  sensibile condiviso su cui BM-10/BM-11 costruiranno. Nessun impatto attuale (mai
  chiamato con dati non fidati), ma la convenzione l'avrebbe prevenuto a monte;
  fixato subito (border via `printf %s`) e pinnato da un test anti-echo-on-data.
  Segnale forte: la trappola riappare anche nel codice di PRESENTAZIONE nuovo, non
  solo nel parsing di input non fidato.

### IMP-004 — Chiudere una CLASSE di difetto = grep di TUTTI i siti + verifica adversariale
- Data: 2026-07-17 | Origine: gate BM-08c e il suo re-gate. Due lezioni: (1) ho
  fixato il fail-open-verso-`go` in `_install_agent` (scheduler) ma ho MANCATO il
  gemello `_restore_agents` in `mod_bk` — l'altro writer di plist con lo STESSO
  pattern; il re-gate l'ha trovato (MEDIUM, componente sensibile). (2) Il fix #8
  toccava una guard-rail di consenso: la mia verifica iniziale FUNZIONALE ("YES
  sopravvive al re-exec?") non bastava — serviva l'ADVERSARIALE ("cosa ora
  AUTORIZZA?"), che il gate ha fornito trovando un CRITICAL (auto-conferma di
  cleanup distruttivo senza --yes).
- Problema osservato: fixare solo l'istanza sotto mano lascia i gemelli aperti; e
  una verifica solo funzionale su una guard-rail di sicurezza non vede cosa il fix
  ora permette. Nessuna regola imponeva l'enumerazione dei siti né la ri-esecuzione
  del gate dopo un fix sensibile.
- Proposta: riga in `docs/03-security-gate.md` (o DoD di docs/02): *"Fix di una
  CLASSE di difetto (un pattern, non un one-off): PRIMA di dichiararla chiusa,
  `grep` del pattern su TUTTO il codice, enumera i siti, fixa o registra ciascuno.
  Per un fix a una guard-rail di consenso/sicurezza la verifica include 'cosa
  questo ora AUTORIZZA?' (adversariale), non solo 'funziona?'. Dopo un fix
  sostanziale a codice sensibile condiviso, RI-esegui il gate."*
- Beneficio atteso / rischio: difetti chiusi per classe, non a spizzichi; re-gate
  come prassi dopo fix sensibili (qui ha trovato il gemello bk). Rischio: minimo —
  è disciplina di verifica, non codice.
- Trigger di ripresa: decisione utente (prossima retro periodica, oppure ora).

### IMP-005 — Convenzione: l'output di CONTROLLO terminale gata sulla tty reale, non solo sul colore
- Data: 2026-07-19 | Origine: BM-09 (fondazione TUI). Implementando la
  degradazione "output pipato senza ANSI", il comando `clear` emetteva comunque
  una sequenza ANSI di controllo-schermo anche con output pipato/non-TTY — un
  leak scoperto SOLO dal test end-to-end "zero ESC quando pipato". Il colore era
  già gated (TUI_COLOR_LEVEL), il controllo-schermo no.
- Problema osservato: la degradazione era pensata per il COLORE; le sequenze di
  CONTROLLO terminale (clear, cursor-move, `\r`) sono un SECONDO canale che sfugge
  se si gata solo il colore. In un re-exec sotto script(1) il figlio ha una pty
  (`-t 1` vero), quindi il gate corretto è la tty-ness REALE handed-off dal parent
  (`TUI_TTY`), non `-t 1` locale né il livello colore (un NO_COLOR interattivo può
  ancora voler pulire lo schermo).
- Proposta: riga nelle "Convenzioni di codice" di `CLAUDE.md`: *"Ogni emissione di
  CONTROLLO terminale (clear, sequenze cursore, `\r`) passa per `_clear`/un gate su
  `TUI_TTY`, come il colore passa per la palette gated su `TUI_COLOR_LEVEL`: un run
  pipato/agente non emette né colore né controllo."* Corollario diretto per BM-12
  (spinner/progress): lo spinner e ogni uso di `\r`/cursore gatano su `TUI_TTY`
  (oggi lo spinner gata solo su `RECORDING`, che in pratica è sempre attivo).
- Beneficio atteso / rischio: chiude la classe "sequenza di controllo che sporca
  l'output pipato alla fonte"; guida pronta per BM-12. Rischio: minimo — è una
  convenzione, e il meccanismo (`TUI_TTY` + `_clear`) è già in codice da BM-09.
- Trigger di ripresa: decisione utente (retro periodica) o primo task BM-12.

<!-- Formato di una proposta:
### IMP-001 — <titolo breve>
- Data: YYYY-MM-DD | Origine: <sessione/problema che l'ha generata>
- Problema osservato: <attrito ricorrente, errore ripetuto, gap, regola ambigua>
- Proposta: <cosa cambiare e dove: CLAUDE.md / docs/NN / comando / hook / processo>
- Beneficio atteso / rischio:
- Trigger di ripresa: <se non è applicabile subito: quale evento la fa tornare in gioco>
- Destinazione: framework   (OPZIONALE — solo se la lezione va fatta risalire al
                             framework; riga fisica singola per il grep di /harvest-framework)
-->

## Applicate

### IMP-001 — Review-agent in background: solo comandi in allow-list + prassi diff-inline → applicata il 2026-07-13 (approvazione utente esplicita), commit dedicato su fix/dryrun-bk-restore
- Origine: security gate del micro-task parser (workflow di review in stallo:
  6 retry × 180s per agente; già accaduto nel gate BM-02, 19/31 agenti persi).
  Causa: gli agenti invocavano comandi git legittimi ma fuori allow-list
  (`git show`, `git -C <path> diff`) e in background il prompt permessi non è
  approvabile → stallo silenzioso.
- Applicato: (a) `Bash(git show:*)` aggiunto all'allow di `.claude/settings.json`
  (read-only; la deny resta prevalente); (b) PRASSI per i review-agent: diff
  INLINE nel prompt + soli strumenti Read/Grep/Glob, niente Bash (verificata
  efficace: seconda run del gate parser 2/2 senza stalli).

## Rimandate
_(nessuna)_

## Rifiutate
_(nessuna)_
