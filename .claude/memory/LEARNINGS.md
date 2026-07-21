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

### IMP-006 — Workflow di review su un git-range: isola gli agenti (worktree) o vietali dal checkout
- Data: 2026-07-20 | Origine: security gate BM-10 (workflow a 5 lenti sul diff
  `765bad4..baaf11b`). Il gate è PASSATO pulito (0 finding), ma il MODO in cui l'ho
  eseguito ha lasciato il repo in uno stato inatteso.
- Problema osservato: ho istruito gli agenti a ispezionare il diff con
  `git -C <root> diff/show <sha>` (Bash), NON isolati → condividevano la working
  dir principale. Almeno un agente ha eseguito `git checkout` per leggere i file, e
  il thrashing `main↔baaf11b` ha lasciato a fine run HEAD su `main`: il branch
  `feat/risk-badges` è rimasto intatto (nessun lavoro perso) ma non checked-out, e
  la harness ha segnalato i file come "modified by user — intentional", generando
  confusione (sembrava che l'utente avesse scartato BM-10). IMP-001 (già
  APPLICATA) prescriveva per i review-agent "diff INLINE + solo Read/Grep/Glob,
  niente Bash" — ma quella prassi non scala su un diff grande (~20 file) dove gli
  agenti traggono valore dal leggere i file interi, e NON l'ho seguita.
- Proposta: estendere la prassi review-workflow (docs/03 / IMP-001): un workflow
  di review su un git-range con più file (a) usa `isolation: 'worktree'` — ogni
  agente ispeziona una copia isolata, i suoi comandi git non toccano la working dir
  principale; OPPURE (b) se non isolato, il prompt VIETA esplicitamente
  `git checkout/switch/reset/restore` (solo `git show <sha>:<path>` e
  `git diff <sha> <sha>`, che non muovono HEAD); e comunque (c) dopo un workflow che
  ha eseguito git in una working dir condivisa, RIVERIFICA `git rev-parse HEAD` e il
  branch PRIMA di proseguire (checkpoint/integrate).
- Beneficio atteso / rischio: i review-workflow non lasciano il repo in uno stato
  inatteso; scala su diff grandi senza un inline gigante. Rischio: `worktree` costa
  un po' (setup per agente); (b)/(c) sono a costo zero.
- Trigger di ripresa: decisione utente (retro periodica) o prossimo workflow di review.
- Destinazione: framework

### IMP-007 — Smoke del menu interattivo: selezione via CLI, mai pipe sul prompt Choice
- Data: 2026-07-20 | Origine: BM-11 (redesign menu) — smoke di verifica del layout.
- Problema osservato: per lo smoke ho pipato la selezione al prompt
  (`printf '13\n' | ./brew_manager.sh --dry-run`): sotto script(1) il recorder
  possiede lo stdin, il `read` del menu riceve EOF e scatta il default `go` — la
  run "veloce da un modulo" è diventata una run completa di 14 moduli, andata in
  timeout e uccisa a mano. Il README lo dichiara già ("Piping input to drive the
  interactive prompt is not supported"), ma la regola operativa di CLAUDE.md
  ("smoke run `./brew_manager.sh --dry-run` del modulo interessato") non dice COME
  selezionare il modulo in uno smoke non-interattivo.
- Proposta: precisare la riga "Verifica minima" di CLAUDE.md (Regole tecniche →
  Test): lo smoke di un modulo si esegue con la selezione CLI posizionale
  (`./brew_manager.sh <id> --dry-run`), mai pipando input al prompt interattivo;
  il rendering del menu si verifica accettando che la pipe produca il default
  `go` (e interrompendo subito), o da un terminale reale.
- Beneficio atteso / rischio: niente run complete accidentali negli smoke, meno
  tempo perso nei task TUI a venire (BM-12 è il prossimo). Rischio: nessuno, è
  una precisazione di una riga.
- Trigger di ripresa: decisione utente (retro periodica, o all'avvio di BM-12).
- **Estesa dal BM-12** (2026-07-21): oltre a non pipare l'INPUT, non troncare
  l'OUTPUT. `./brew_manager.sh … | head -20` uccide la run con SIGPIPE a metà e
  lascia un log di sessione a **0 byte**: sembra una regressione del prodotto (ci
  ho perso due diagnosi) e invece è l'artefatto dello smoke. Regola completa:
  smoke = selezione CLI posizionale + output REDIRETTO SU FILE, poi si filtra il
  file. Vale per qualsiasi TUI che salvi un artefatto a fine run.

### IMP-008 — Un gate che verifica solo "cosa esegue" non vede le affermazioni FALSE
- Data: 2026-07-21 | Origine: security gate BM-12 (2 lenti adversariali).
- Problema osservato: il diff era, per comportamento, davvero "presentazione
  pura" — entrambe le lenti hanno verificato e confermato che consenso, rami
  dry-run, dispatch ed exit-code erano intatti. Eppure conteneva **4 difetti di
  verità**: il summary ATTESTAVA nel log di sessione che moduli senza gate
  `--dry-run` avevano "previewed, changed nothing" (falso per mod_02 e mas), e la
  riga del disco poteva dichiarare spazio liberato su una cache cresciuta. Il mio
  ragionamento da autore era "l'etichetta deriva dal contratto, il bug è altrove
  (Attenzione #3)" — ma il contratto non era rispettato dalla realtà, e la doc
  utente appena scritta trasformava l'etichetta in una promessa.
- Proposta: aggiungere a `docs/03-security-gate.md` una lente esplicita
  **"affermazioni, non solo azioni"**: quando un deliverable di presentazione
  produce ASSERZIONI su proprietà di sicurezza (badge, stati, riepiloghi,
  messaggi "nothing was changed") — specie se finiscono in un artefatto
  persistente (log, report, export) — ogni asserzione va verificata contro il
  comportamento REALE del codice che descrive, non contro il contratto che
  quel codice dovrebbe rispettare. Criterio operativo: se una stringa afferma
  che qualcosa NON è successo, deve esistere un dato che lo dimostra (qui:
  `MODULE_DRYRUN`, separato dal rischio), non un'inferenza.
- Beneficio atteso / rischio: impedisce che un debito noto e accettato (#3)
  diventi silenziosamente una promessa scritta all'utente. Rischio: nessuno —
  è una lente in più, applicabile solo dove ci sono asserzioni.
- Trigger di ripresa: decisione utente (retro periodica) o prossimo deliverable
  che produce report/summary/badge.
- Destinazione: framework

### IMP-009 — Un test che asserisce l'ASSENZA di debito inverte l'incentivo: pinna l'INSIEME, non il vuoto
- Data: 2026-07-21 | Origine: gate del micro-task dry-run (mod_02/mas), finding LOW.
- Problema osservato: dopo aver gatato gli ultimi due moduli avevo aggiunto un
  "invariante di classe" che scandiva il registry e FALLIVA se un modulo era
  dichiarato non-gatato (`MODULE_DRYRUN=0`). Sembrava il rafforzamento naturale
  di IMP-004 (chiudi la classe), ma rendeva la dichiarazione onesta l'unica
  mossa che rompe la build: per un modulo nuovo che scrive senza gate, la via
  più rapida al verde non è fixarlo — è dichiarare `1` e citare
  `BREW_MANAGER_DRY_RUN` in un commento (l'altro check è un grep sul file).
  Il test spingeva verso la bugia esattamente dove il progetto ha bisogno di
  verità (il summary attesta "nothing changed" su quel dato).
- Proposta: aggiungere a `docs/02-code-quality.md` (sezione "Test che dimostrano")
  la regola: **un invariante su un debito noto si scrive come ALLOW-LIST
  bidirezionale, non come asserzione di insieme vuoto**. Due check: (a) un
  elemento fuori lista fallisce → il debito non cresce in silenzio; (b) una voce
  della lista che non è più debito fallisce → l'esenzione non sopravvive al fix.
  Regola generale: se dichiarare la verità rompe la build, il test è progettato
  male — misura la dichiarazione, non il comportamento.
- Beneficio atteso / rischio: toglie l'incentivo a mentire nei registri su cui
  poggiano le asserzioni di sicurezza. Rischio: una allow-list può diventare un
  parcheggio comodo — mitigato dal check (b) e dal fatto che ogni voce va
  motivata in `STATE.md`.
- Trigger di ripresa: decisione utente (retro periodica) o prossimo invariante
  scritto su un registro di capability.
- Destinazione: framework

### IMP-010 — Promuovere un fix locale a CLAIM globale allarga l'insieme da verificare oltre il diff
- Data: 2026-07-21 | Origine: gate del micro-task dry-run, finding HIGH/MEDIUM.
- Problema osservato: il task chiudeva due violazioni note (`mod_02`, `mas`), ma
  per farlo ha portato a 1 un registro di 18 voci, aggiunto un test di classe e
  riscritto il README da "questi due moduli non rispettano `--dry-run`" a "ogni
  modulo si ferma all'anteprima". Il diff toccava 2 moduli; l'AFFERMAZIONE ne
  copriva 18 — e quattro erano false, per difetti che il branch non aveva
  introdotto (auto-update implicito di Homebrew in mod_04/10/bk, `rm` non gatato
  in `las [c]`, `brew bundle check` in `bk [4]`). Il branch non ha rotto nulla:
  ha ATTESTATO come verificato ciò che era solo dichiarato. Una review limitata
  ai file modificati — la prassi normale — non l'avrebbe mai visto.
- Proposta: aggiungere a `docs/03-security-gate.md`, accanto alla lente di
  IMP-008, il criterio di **ampiezza**: quando un deliverable generalizza
  un'affermazione (da "questi N" a "tutti"), l'insieme da verificare nel gate è
  quello dell'AFFERMAZIONE, non quello del diff. Segnali che fanno scattare la
  regola: un valore di registro/config che passa da eccezione a uniformità, un
  test che sostituisce casi puntuali con un ciclo su tutto l'insieme, una frase
  di doc che perde le sue eccezioni ("tranne…" che sparisce).
- Beneficio atteso / rischio: intercetta la classe di difetto in cui il codice è
  corretto e la promessa è falsa. Rischio: allarga il gate — va applicata solo
  quando il claim si allarga davvero, non a ogni fix.
- Trigger di ripresa: decisione utente, o prossimo deliverable che uniforma un
  registro/una capability.
- Destinazione: framework

### IMP-011 — Gatare un comando esterno non basta: verifica se lo STRUMENTO lo riesegue da sé
- Data: 2026-07-21 | Origine: gate del micro-task dry-run, finding HIGH (F1).
- Problema osservato: mettere `brew update` dietro il gate `--dry-run` sembrava
  chiudere la questione. Ma Homebrew esegue `brew update --auto-update` da solo
  prima di `install|outdated|upgrade|bundle|release` (brew.sh,
  `AUTO_UPDATE_COMMANDS`), e nemmeno il `--dry-run` DI BREW lo ferma: la
  decisione è presa prima di leggere gli argomenti. Risultato: una sessione di
  sola anteprima continuava a riscrivere l'indice tramite i moduli 4/10/bk, che
  "si limitano a elencare". La porta d'ingresso era chiusa e quella di servizio
  aperta — invisibile a qualsiasi test con mock, perché il mock non riproduce il
  comportamento implicito dello strumento vero.
- Proposta: aggiungere a `docs/02-code-quality.md` (o alle regole tecniche di
  progetto) la regola: **quando si gata l'invocazione di uno strumento esterno,
  verificare sul suo sorgente/doc se esistono percorsi che lo rieseguono
  implicitamente**, e cercare l'interruttore ufficiale (qui
  `HOMEBREW_NO_AUTO_UPDATE`). Vale per ogni strumento con comportamenti
  automatici: package manager, git (hook, auto-gc), runner di CI, formatter con
  watch.
- Beneficio atteso / rischio: evita gate che sembrano chiusi e non lo sono.
  Rischio: nessuno — è una verifica una tantum per strumento, di solito un grep
  nella doc.
- Trigger di ripresa: decisione utente, o prossimo gate su un comando esterno.
- Destinazione: framework

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
