# brew-manager — Claude Code Index

Stack: zsh (macOS-only, nessuna build) | Repo: github.com/M2NDLAB/brew-manager

> Questo file è l'**indice** che Claude Code legge per orientarsi: rimanda ai doc di
> processo, alla memoria persistente e fissa le regole non negoziabili. Le regole
> qui sotto sono di PROCESSO (agnostiche allo stack); le regole tecniche del
> progetto vanno nell'ultima sezione.

## Documentazione di processo — carica SOLO i file rilevanti per il task
- @.claude/docs/00-overview.md            — il metodo, il ciclo di fine deliverable, caricamento doc
- @.claude/docs/01-task-planning.md       — piano a task per prompt onerosi, ripresa resiliente
- @.claude/docs/02-code-quality.md        — commenti, error handling, Definition of Done
- @.claude/docs/03-security-gate.md       — review obbligatoria sui componenti sensibili
- @.claude/docs/04-git-workflow.md        — quando committare, branch, merge, rollback
- @.claude/docs/05-escalation-protocol.md — report strutturato quando ti blocchi
- @.claude/docs/06-self-improvement.md    — correzioni doc, backlog IMP, retrospettiva

## Memoria persistente — OBBLIGATORIA in ogni sessione
- A INIZIO sessione: leggi @.claude/memory/STATE.md (iniettato dall'hook SessionStart)
  e le note .claude/memory/components/ dei soli componenti toccati dal task; TREE.md
  prima di esplorare il filesystem a mano. Controlla se esiste un piano in-progress in
  .claude/memory/plans/ per il prompt richiesto (vedi regola 7).
- A FINE task: nota di sessione in memory/sessions/, aggiorna components/ toccati,
  riscrivi STATE.md, rigenera TREE.md se la struttura è cambiata.
  **Un task senza memoria aggiornata NON è finito.**
- Usa lo slash command /checkpoint per memoria + doc + commit insieme.

## Regole globali NON negoziabili (processo)
1. **Nessun secret in chiaro** nel codice o nei config committati — solo secret
   manager o variabili d'ambiente. L'hook gitleaks blocca i commit che violano questa
   regola (è la baseline; vedi anche il gate di sicurezza, regola 8).
2. **Code quality** secondo 02-code-quality.md: il PERCHÉ nei commenti, nessuna
   eccezione inghiottita, validazione al bordo, Definition of Done rispettata.
3. **Git** secondo 04-git-workflow.md: branch per ogni feature, commit ai checkpoint
   logici e PRIMA di cambi rischiosi, Conventional Commits, mai push senza conferma
   dell'utente.
4. **Escalation** secondo 05-escalation-protocol.md: bloccato dopo 2 tentativi
   ragionati, o davanti a un bivio non coperto dai doc/decisioni? NON insistere alla
   cieca: genera un ESCALATION REPORT e fermati. La risposta torna come blocco
   ARCHITECT RESPONSE — eseguila secondo il protocollo.
5. **Documentazione aggiornata** INSIEME alle modifiche: una modifica che tocca
   funzionalità utente, procedure, API o deploy non è finita finché la doc non è
   allineata (dove vive la doc di progetto: `README.md`). Stessa logica
   della memoria. Finché la doc di progetto non esiste, annota il debito in STATE.md.
6. **Auto-miglioramento** secondo 06-self-improvement.md: le correzioni FATTUALI alla
   doc (in disaccordo dimostrabile con la realtà) le applichi subito; i cambi di
   REGOLE e processo li PROPONI in memory/LEARNINGS.md (IMP-nnn) e li applichi solo
   dopo approvazione dell'utente. **Mai riscrivere le proprie regole in autonomia.**
7. **Task planning** secondo 01-task-planning.md: all'avvio di OGNI prompt valuta da
   solo l'onerosità; se oneroso, genera un PIANO a task atomici in .claude/memory/plans/,
   committalo, poi esegui UN COMMIT PER TASK (`[task N/T]` nel messaggio) spuntando il
   piano. Se una sessione si interrompe: NON ricominci da zero e NON elimini il branch
   — scarti solo il mezzo-task non committato (scripts/reset-task.sh) e riprendi dal
   primo task non spuntato. I commit dei task completati non si toccano mai.
8. **Security gate** secondo 03-security-gate.md: sui componenti sensibili
   (`mod_00_audit`, `mod_05_cleanup`, `mod_bk_brewfile`, `mod_las_scheduler`,
   `brew_manager.sh`, `lib/common.sh` — elenco motivato in 03-security-gate.md)
   esegui /security-review PRIMA della PR; finding
   HIGH/CRITICAL risolti, MEDIUM risolti o accettati come debito in STATE.md (col
   motivo), LOW almeno registrati.

## Comandi rapidi
- Slash command: `/checkpoint`, `/integrate`, `/sos`, `/retro`, `/security-review`,
  `/new-component`, `/lint-memory`
- `make hooks-install` — installa gli hook git (gitleaks + commitlint)
- `./scripts/reset-task.sh` — scarta il mezzo-task interrotto (preserva i commit)

---

## Regole tecniche specifiche del progetto

- **Stack**: zsh puro, macOS-only. Nessuna compilazione, nessuna build: gli script
  sono l'artefatto. Dipendenze runtime: Homebrew (installer integrato), `script(1)`,
  `python3` (parsing JSON in mod_03), `mas` (opzionale, modulo mas), `launchctl`,
  `mdfind`, `tput`, `open(1)`.
- **Run**: `./brew_manager.sh` (TUI interattiva). Flag: `--dry-run`, `--yes|-y`,
  `--adopt=n|all|1,2`, `--upgrade=y|n`. Solo `brew_manager.sh` è eseguibile:
  `lib/` e `modules/` vengono sourcati.
- **Struttura standard di un componente** (= modulo, per /new-component): vedi
  `.claude/commands/new-component.md`. In sintesi: file `modules/mod_NN_slug.sh`
  (caricato automaticamente dal glob `mod_*.sh`), funzione `_module_NN` (numero
  senza zero-padding), voce in `MODULE_DESC` (obbligatoria: senza, il modulo non è
  selezionabile), eventuale aggiunta a `MODULE_IDS` per la sequenza `go`, riga di
  menu; per i moduli speciali anche alias nel case di parsing e di dispatch.
- **Convenzioni di codice**: funzioni interne con prefisso `_`; costanti e stato
  condiviso in MAIUSCOLO; output TUI solo tramite le utility di `lib/common.sh`
  (`_section`, `_ok`, `_warn`, `_err`, `_info`, `_item`, `_stat_row`); prompt SOLO
  via `_ask`/`_read_choice` (mai `read` diretto per conferme). Attenzione agli
  array zsh: sono 1-based (fonte di off-by-one già presenti nel codice).
  **Ogni azione mutante DEVE rispettare `BREW_MANAGER_DRY_RUN` e
  `BREW_MANAGER_YES`** — è la regola by-convention che previene la classe di
  difetti più diffusa emersa dall'assessment (vedi STATE.md). Formatter/linter:
  nessuno attivo (candidati: `shfmt`/`shellcheck`, non installati; blocco
  predisposto ma commentato in `scripts/hooks-install.sh`). Check di sintassi a
  costo zero: `zsh -n <file>`.
- **Test**: assenti. Nessun framework di test; il debito è annotato in STATE.md
  (candidato futuro: bats). Verifica minima per ogni modifica: `zsh -n` sui file
  toccati + smoke run `./brew_manager.sh --dry-run` del modulo interessato.
- **Componenti sensibili** (regola 8): `mod_00_audit` (adozione app),
  `mod_05_cleanup` (autoremove/cleanup), `mod_bk_brewfile` (restore, plist),
  `mod_las_scheduler` (persistenza LaunchAgent), più `brew_manager.sh` e
  `lib/common.sh` come infrastruttura condivisa dei guard-rail (un difetto in
  `_ask`/YES_MODE o nel dispatch si propaga a tutti i moduli).
- **Dove vive la documentazione di progetto** (regola 5): `README.md` (in inglese;
  la memoria e i doc di processo del framework restano in italiano).
- **Deploy**: nessuno — distribuzione via `git clone` del repo.
- **Licenza del progetto**: MIT, copyright M2NDLAB (file `LICENSE` del repo;
  preesistente all'innesto del framework e indipendente dalla MIT del framework).
