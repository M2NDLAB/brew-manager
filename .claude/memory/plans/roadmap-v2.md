# brew-manager — Piano di lavoro atomizzato (roadmap v2)

Documento di lavoro. Vive in `.claude/memory/plans/roadmap-v2.md`.
Fonte dello stato del codice: assessment Claude Code (verificato a disco, non dal README).
Distinzione usata nel testo: **[fatto]** = verificato dall'assessment · **[op]** = opinione tecnica ·
**[interp]** = interpretazione mia · **[?]** = incertezza / da confermare sul codice reale.

---

## 0. Come Claude Code esegue questo documento

### Confine di esecuzione (dal tuo framework, invariato)
Claude Code implementa; **tu** integri. Per ogni task: apre branch, scrive codice, esegue i
test di non-regressione, committa (Conventional Commits, `git add` esplicito), aggiorna la
memoria, fa `/checkpoint`, poi **stampa** il blocco `/integrate` e **si ferma**. Merge, tag e
push li fai tu. Nessun merge/tag/push autonomo. **[fatto]**

### Protocollo operativo (prompt driver da incollare a Claude Code)
```
Lavora il backlog in .claude/memory/plans/roadmap-v2.md seguendo l'ordine della sezione 3.
Un task per volta, mai in blocco. Per ciascun task:
1. Apri il branch indicato (mai su main).
2. Implementa lo scope. Se il task è marcato "sensibile", tratta il componente secondo docs/03:
   massima cautela, ogni azione con side-effect gated da BREW_MANAGER_DRY_RUN e conferma.
3. Esegui i test di non-regressione elencati nel task. Se non passano, NON committare: fermati
   e spiegami cosa è divergente.
4. Commit con il messaggio Conventional Commits indicato (adatta lo scope se necessario).
5. Registra in LEARNINGS.md le decisioni non ovvie emerse; aggiorna STATE.md se lo stato cambia.
6. /checkpoint, poi STAMPA il blocco /integrate e FERMATI per la mia approvazione.
Non iniziare il task successivo finché non ti do l'ok sull'integrazione del precedente.
Dove il piano dice [?], leggi il codice reale prima di decidere e segnalami la scelta.
```

### Regola trasversale a ogni task (vale sempre)
- `--dry-run` disabilita OGNI scrittura. `--yes/-y` (o stdin non-TTY) salta le conferme.
  Ogni nuovo path con side-effect onora entrambi. **[fatto: è il vincolo cardine del progetto]**
- Quoting rigoroso, `zsh -n` pulito, shellcheck pulito dove installato.
- Idempotenza: rieseguire un task non deve peggiorare lo stato.
- Un modulo per file, prefisso `_` per le funzioni interne, costanti MAIUSCOLE. **[fatto: convenzione esistente]**

---

## 1. Precondizioni (prima del primo task)

1. **Framework innestato.** Decisioni A–H chiuse, FASE 3 applicata, branch `chore/innesto-framework`
   integrato. Il backlog sotto presuppone `.claude/`, `CLAUDE.md`, `Makefile` presenti.
2. **Baseline congelata** (la fai tu, è un'operazione git, non un task Claude Code):
   ```
   git checkout main
   git tag -a v1.1.2-baseline -m "baseline funzionante pre-roadmap-v2"
   git push origin v1.1.2-baseline
   ```
   Motivo: **[fatto]** l'assessment segnala che i tag esistenti sono lightweight; un tag annotato
   dà un punto di ritorno certo e fa funzionare `git describe`/`/integrate`.

---

## 2. Backlog atomico

Legenda campi di ogni task:
`Tipo · branch` — `Sensibile` — `Dipende da` — `Perché` — `Fatto quando` (criteri di accettazione) —
`Non-regressione` (cosa provare a mano) — `Commit`.

---

### M0 — Rete di sicurezza (prima di toccare la logica)

#### BM-01 · chore: target di verifica shell nel Makefile
- Tipo · branch: chore · `chore/dev-checks`
- Sensibile: no
- Dipende da: —
- Perché: **[op]** prima di rifattorizzare codice safety-critical serve una rete a costo zero.
  L'assessment dice **[fatto]** che non esistono test, linter né CI; `gitleaks` e `npx` ci sono,
  `shellcheck`/`shfmt` no.
- Fatto quando: `make check` esegue `zsh -n` su `brew_manager.sh`, `lib/*.sh`, `modules/*.sh` e
  fallisce su errore di sintassi; `make lint` esegue shellcheck **solo se presente** (skip pulito
  altrimenti, nessun errore se manca); target documentati nel Makefile.
- Non-regressione: `make check` verde sullo stato attuale; `make lint` non rompe se shellcheck assente.
- Commit: `chore(build): add zsh -n and optional shellcheck targets`

---

### M1 — Sicurezza e correttezza (blocca tutto il resto)

#### BM-02 · fix: onora --dry-run in mod_05_cleanup
- Tipo · branch: fix · `fix/dryrun-cleanup`
- Sensibile: **sì (alto — rimuove file/cache)**
- Dipende da: BM-01
- Perché: **[fatto]** l'assessment segnala che `mod_05` ignora `BREW_MANAGER_DRY_RUN` → `--dry-run`
  esegue davvero `autoremove` e `cleanup`. Viola il vincolo cardine.
- Fatto quando: con `--dry-run` nessun `brew autoremove`/`brew cleanup -s` eseguito, si stampa il
  piano ("rimuoverei: …") e la stima spazio; il disco resta invariato. Senza `--dry-run`,
  comportamento identico a oggi.
- Non-regressione: (a) `./brew_manager.sh 5 --dry-run` → cache invariata (misura `brew cleanup -s -n`
  prima/dopo); (b) `./brew_manager.sh 5` interattivo → cleanup ok con conferma; (c) run non-TTY.
- Commit: `fix(cleanup): honor --dry-run, skip autoremove/cleanup in read-only mode`

#### BM-03 · fix: onora --dry-run nel restore di mod_bk
- Tipo · branch: fix · `fix/dryrun-bk-restore`
- Sensibile: **sì (alto — installa pacchetti, carica plist)**
- Dipende da: BM-01
- Perché: **[fatto]** restore `[3]/[3b]/[3a]` ignora dry-run → installa pacchetti e carica
  LaunchAgent anche in modalità read-only.
- Fatto quando: con `--dry-run` il restore stampa cosa installerebbe/caricherebbe senza eseguire
  `brew bundle`/`launchctl load`; senza dry-run invariato.
- Non-regressione: `./brew_manager.sh bk` opzione 3 con `--dry-run` → nessun `brew install`,
  nessun plist caricato (verifica `launchctl list | grep brew-manager`); restore reale ancora ok.
- Commit: `fix(backup): honor --dry-run in restore paths (packages + agents)`

#### BM-04 · fix: off-by-one nella selezione di adozione (mod_00)
- Tipo · branch: fix · `fix/adopt-off-by-one`
- Sensibile: **sì (alto — `brew install --cask --adopt` sull'app sbagliata)**
- Dipende da: BM-01
- Perché: **[fatto]** array 1-based zsh: selezionare "1" dà elemento vuoto, "2" adotta la prima app.
  Adozione dell'app errata = danno reale.
- Fatto quando: l'indice N selezionato adotta la N-esima app mostrata; **in più**, prima di eseguire
  si stampa un'eco esplicita ("Adotto: <Nome.app> → <cask>. Confermi?") gated da `_ask`/`--yes`.
- Non-regressione: lista di ≥3 app adottabili, selezionare 1/2/3 e verificare che l'eco corrisponda;
  con `--dry-run` nessuna adozione; con `--adopt=1,3` selezione multipla corretta.
- Commit: `fix(audit): correct 1-based index in adoption selection + confirm target`

#### BM-05a · fix: weekday shiftato in las/bk
- Tipo · branch: fix · `fix/weekday-shift`
- Sensibile: **sì (alto — schedula l'agente nel giorno sbagliato)**
- Dipende da: BM-01
- Perché: **[fatto]** weekday shiftato di +1 (Sun→…) nella generazione plist / backup agenti.
- Fatto quando: scegliere "domenica" produce `Weekday` corretto nel plist launchd (Sun=0 per launchd);
  round-trip backup→restore preserva il giorno.
- Non-regressione: creare agente custom con giorno noto, ispezionare il `.plist` generato, confrontare
  col mapping launchd; backup e restore mantengono il giorno.
- Commit: `fix(scheduler): correct weekday mapping in plist generation`

#### BM-05b · fix: contatore off-by-one in mod_09
- Tipo · branch: fix · `fix/mod09-counter`
- Sensibile: no (read-only)
- Dipende da: BM-01
- Perché: **[fatto]** contatore sbagliato nel report dei binari tracciati.
- Fatto quando: il conteggio mostrato coincide col numero di righe effettive.
- Non-regressione: confronto conteggio vs `wc -l` sull'elenco reale.
- Commit: `fix(tracked): correct off-by-one in binary counter`

#### BM-06 · fix: mod_10 greedy — gate sul conteggio e check exit code
- Tipo · branch: fix · `fix/greedy-scope`
- Sensibile: **sì (medio — upgrade forzato più ampio di quanto confermato)**
- Dipende da: BM-01
- Perché: **[fatto]** conferma "N cask" ma lancia `brew upgrade --greedy` globale, senza controllare
  l'exit code.
- Fatto quando: l'upgrade agisce solo sui cask realmente confermati (o si dichiara chiaramente che è
  globale e la conferma lo riflette); exit code controllato e riportato nel summary.
- Non-regressione: caso con 1 cask greedy outdated → conferma e upgrade coerenti; `--dry-run` → solo
  anteprima; simulare fallimento e verificare che venga segnalato.
- Commit: `fix(greedy): scope upgrade to confirmed casks, check exit status`

#### BM-07 · refactor: versione a fonte unica + rimozione codice morto
- Tipo · branch: refactor · `refactor/version-deadcode`
- Sensibile: no
- Dipende da: BM-01
- Perché: **[fatto]** drift versione (script dice 1.1.0, HEAD è v1.1.2); `_install_agent_multi` è
  codice morto; header interni citano nomi file vecchi (`mod_15_*`, `mod_16_*`).
- Fatto quando: la versione ha una sola fonte (file `VERSION` letto a runtime, **oppure**
  `git describe` con fallback — **[?]** scegli in base a come lo script è distribuito); funzione morta
  rimossa; header corretti.
- Non-regressione: `./brew_manager.sh --version` coerente col tag; grep conferma zero riferimenti ai
  nomi vecchi; menu invariato.
- Commit: `refactor(core): single source of truth for version, drop dead code`

---

### M2 — Resolver di selezione (la chiave di volta)

#### BM-08a · refactor: estrai `_resolve_selection()` (parità di comportamento)
- Tipo · branch: refactor · `refactor/selection-resolver`
- Sensibile: **sì (core — dispatch condiviso)**
- Dipende da: M1 completo
- Perché: **[interp]** oggi la selezione moduli vive solo nel prompt; centralizzarla è il
  prerequisito di preset, scheduling corretto e gating uniforme. Questo sotto-task NON cambia
  comportamento: estrae la logica in una funzione unica usata dal path interattivo.
- Fatto quando: `_resolve_selection <spec>` restituisce la lista canonica validata contro
  `MODULE_DESC`; il menu interattivo la usa; output identico a prima (token invalidi scartati con
  warning, come oggi).
- Non-regressione: batteria di input (`go`, `0,4,5`, `log`, token invalido, misto) → stessa lista
  di prima del refactor. **[op]** aggiungi qui i primi smoke-test in `tests/`.
- Commit: `refactor(dispatch): extract _resolve_selection, no behavior change`

#### BM-08b · feat: dispatch posizionale + `--only`/`--skip`
- Tipo · branch: feat · `feat/positional-dispatch`
- Sensibile: **sì (core)**
- Dipende da: BM-08a
- Perché: **[fatto]** gli argomenti posizionali (`./brew_manager.sh 1,4,5`) sono documentati ma non
  implementati; il parser gestisce solo flag.
- Fatto quando: `./brew_manager.sh 0,4,5` esegue quei moduli non-interattivamente; `--only`/`--skip`
  filtrano la selezione; tutto passa dal resolver di BM-08a; `--dry-run`/`--yes` rispettati.
- Non-regressione: le combinazioni CLI producono la selezione attesa; il default interattivo resta `go`.
- Commit: `feat(cli): implement positional module selection and --only/--skip`

#### BM-08c · fix: gli agenti las passano la selezione attraverso il resolver
- Tipo · branch: fix · `fix/agent-selection`
- Sensibile: **sì (alto — chiude il buco "agente esegue cleanup non confermato")**
- Dipende da: BM-08b
- Perché: **[fatto]** gli agenti generati passano i moduli come argomento, ma essendo il posizionale
  non implementato degradavano a `go --yes` (incluso `mod_05`). Con BM-08b il posizionale esiste:
  qui si verifica che il plist generato usi la sintassi giusta e che un agente "solo audit" esegua
  davvero solo l'audit.
- Fatto quando: un agente configurato per moduli read-only NON esegue cleanup; il plist invoca
  `brew_manager.sh <selezione> --yes`.
- Non-regressione: installare agente con selezione read-only, forzarne l'esecuzione
  (`launchctl start`), leggere `agent_stdout_*` e confermare che `mod_05` non è girato.
- Commit: `fix(scheduler): route agent runs through selection resolver`

---

### M3 — TUI bella + funzionale

Design completo nella sezione 4. Qui l'atomizzazione.

#### BM-09 · feat: fondazione TUI in lib/common.sh
- Tipo · branch: feat · `feat/tui-foundation`
- Sensibile: **sì (infrastruttura condivisa)**
- Dipende da: BM-08a (per non collidere col refactor dispatch)
- Perché: **[op]** una TUI "bella" ha bisogno di un sistema visivo coerente e di degradazione
  robusta, non di ritocchi sparsi. Base per tutto M3.
- Fatto quando: `common.sh` espone rilevamento capacità (truecolor via `$COLORTERM`, 256 via
  `tput colors`, `NO_COLOR`, non-TTY), palette semantica, helper box/regole/padding (sezione 4).
  Degradazione: non-TTY o `NO_COLOR` → ASCII puro senza ANSI; terminale povero → 16 colori.
- Non-regressione: rendering ok su Terminal.app e con `NO_COLOR=1`; output pipato senza sequenze
  ANSI (coerente con lo stripping ANSI dei log); moduli esistenti ancora leggibili.
- Commit: `feat(tui): capability detection, semantic palette, box/layout primitives`

#### BM-10 · feat: badge di rischio e UX di conferma
- Tipo · branch: feat · `feat/risk-badges`
- Sensibile: **sì (lega sicurezza e presentazione)**
- Dipende da: BM-09, M1
- Perché: **[op]** il salto di qualità più alto della TUI è rendere il rischio *visibile*. Ogni
  prompt distruttivo mostra un badge; read-only vs scrittura color-coded; "About this module"
  guadagna una riga "questo modulo può: {scrive/rimuove/installa}".
- Fatto quando: badge `[RO]`/`[W]`/`[!]` (sezione 4) presenti nel menu e nei blocchi About; i prompt
  distruttivi hanno cornice/colore di pericolo distinti da quelli informativi.
- Non-regressione: i moduli read-only mostrano `[RO]`; i sensibili mostrano `[!]`; nessun prompt
  distruttivo senza badge.
- Commit: `feat(tui): risk badges and danger-styled confirmations`

#### BM-11 · feat: banner + redesign menu
- Tipo · branch: feat · `feat/menu-redesign`
- Sensibile: no
- Dipende da: BM-09
- Perché: **[op]** gerarchia visiva e allineamento colonne rendono il menu leggibile a colpo d'occhio.
- Fatto quando: header/banner coerente; moduli come card allineate (numero, badge, nome, una riga di
  descrizione); separatore netto tra numerati e speciali; larghezza colonne fissa.
- Non-regressione: tutti i 18 moduli elencati; selezione invariata; layout stabile a 80 colonne.
- Commit: `feat(tui): redesigned banner and aligned module menu`

#### BM-12 · feat: progresso operazioni lunghe + summary finale
- Tipo · branch: feat · `feat/progress-summary`
- Sensibile: no
- Dipende da: BM-09, BM-08a
- Perché: **[op]** feedback durante operazioni lunghe (topgrade mostra timing per step **[fatto: dai
  suoi doc]**) e una summary screen finale chiudono l'esperienza.
- Fatto quando: spinner puro-shell per le operazioni lunghe (con fallback ASCII, sezione 4); summary
  finale con stato per modulo (✓/↷/✗), delta disco, tempo trascorso.
- Non-regressione: spinner usa `\r` e non sporca i log (lo stripping CR/ANSI già lo gestisce); summary
  coerente con la selezione risolta; non-TTY → nessuno spinner, solo righe di stato.
- Commit: `feat(tui): spinner for long ops and final run summary`

---

### M4 — Feature

#### BM-13 · feat: layer di output machine-readable
- Tipo · branch: feat · `feat/output-layer`
- Sensibile: no
- Dipende da: BM-08b, BM-12
- Perché: **[op]** report robusti si costruiscono su un substrato JSON, non su scraping del terminale.
  MacOS-Maid espone `--output=json` **[fatto: dal suo README]**.
- Fatto quando: `--output=terminal|json|markdown`; il JSON è il substrato canonico (stato per modulo,
  conteggi, delta disco, timestamp); terminale e markdown ne sono rendering.
- Non-regressione: `--output=json` produce JSON valido (`python3 -m json.tool`); default `terminal`
  invariato.
- Commit: `feat(report): machine-readable output layer (json substrate)`

#### BM-14 · feat: viste report (markdown/terminale)
- Tipo · branch: feat · `feat/report-views`
- Sensibile: no
- Dipende da: BM-13
- Perché: **[op]** report archiviabili/condivisibili; disco prima/dopo generalizzato oltre `mod_05`.
- Fatto quando: `--output=markdown` genera un report leggibile con sezioni per modulo e riepilogo
  disco; opzione per salvarlo in `logs/` accanto al log di sessione.
- Non-regressione: report riflette la run reale; nessun path di scrittura fuori da `logs/`.
- Commit: `feat(report): terminal and markdown report views`

#### BM-15 · feat: preset di combinazioni
- Tipo · branch: feat · `feat/presets`
- Sensibile: **sì (medio — un preset può includere moduli di scrittura)**
- Dipende da: BM-08b
- Perché: la feature che hai chiesto. Design nella sezione 5. **[op]** validata da topgrade
  (`only`/`disable` in config) e MacOS-Maid (`--modules=`, categorie) **[fatto: dai loro doc]**.
- Fatto quando: `./brew_manager.sh preset <nome>` espande via resolver; config in
  `~/.config/brew-manager/presets.conf` (XDG); repo spedisce preset d'esempio; attributo `safe-only`
  che rifiuta l'inclusione di moduli di scrittura; un preset può incorporare `--dry-run` di default.
- Non-regressione: preset read-only non scrive nulla per costruzione; preset con moduli sensibili
  rispetta comunque conferma salvo `--yes`; nome inesistente → errore chiaro, non crash.
- Commit: `feat(presets): named module combinations from XDG config`

#### BM-16 · feat: `--yes-safe` + conferma digitata per rischio massimo
- Tipo · branch: feat · `feat/tiered-confirmation`
- Sensibile: **sì (alto)**
- Dipende da: M1, BM-10
- Perché: **[op]** pattern ggasp/cleanup **[fatto]**: distinguere "auto-conferma il sicuro"
  (`--yes-safe`) da "auto-conferma tutto" (`--yes`); per le azioni a raggio massimo (adopt, restore,
  install LaunchAgent) richiedere di digitare una parola invece del solo `y`.
- Fatto quando: `--yes-safe` salta solo le conferme non distruttive; le azioni ad alto rischio
  chiedono conferma digitata (bypassata solo da `--yes` pieno o non-TTY).
- Non-regressione: `--yes-safe` non esegue azioni distruttive senza conferma; `--yes` mantiene il
  comportamento non interattivo pieno per gli agenti.
- Commit: `feat(safety): --yes-safe tier and typed confirmation for high-risk actions`

#### BM-17 · feat: notifica di fallimento agenti (osascript)
- Tipo · branch: feat · `feat/agent-notify`
- Sensibile: no
- Dipende da: BM-08c
- Perché: **[op]** un agente che fallisce lo fa in un log che nessuno legge. `osascript -e 'display
  notification …'` è macOS-nativo, zero dipendenze, dentro i vincoli.
- Fatto quando: run schedulata fallita → notifica macOS con modulo e codice; opzione per disattivarla
  in config.
- Non-regressione: run ok → nessuna notifica; run fallita simulata → notifica presente; non impatta le
  run interattive.
- Commit: `feat(scheduler): macOS notification on agent-run failure`

#### BM-18 · feat: `doctor` self-check + smoke test minimi
- Tipo · branch: feat · `feat/doctor`
- Sensibile: no
- Dipende da: BM-01, BM-08a
- Perché: **[op]** su un tool safety-critical serve verificare le proprie invarianti. `doctor`
  controlla che ogni modulo sensibile onori `--dry-run`.
- Fatto quando: `./brew_manager.sh doctor` verifica invarianti (moduli sensibili gated, versione
  coerente, permessi prefix); `tests/` copre il resolver e i path dry-run principali via `zsh -n` e
  smoke test. **[?]** `bats-core` sarebbe lo standard ma è una dipendenza di sviluppo: decidi se
  introdurla o restare a smoke-test zero-dep.
- Non-regressione: `doctor` verde sullo stato post-M1/M2; fallisce di proposito se si rimuove un gate.
- Commit: `feat(doctor): self-check of safety invariants + smoke tests`

---

### M5 — Documentazione e drift (per ultimo, così descrive la realtà)

#### BM-19 · docs: riconcilia README con la realtà
- Tipo · branch: docs · `docs/readme-reality`
- Sensibile: no
- Dipende da: M2, M4
- Perché: **[fatto]** l'assessment elenca 3 divergenze: (a) CLI posizionale documentata ma assente
  — ora esiste (BM-08b), aggiornare è coerente; (b) SECURITY.md non citato nella struttura;
  (c) "Adding a new module" promette invocabilità CLI ora reale.
- Fatto quando: README riflette il comportamento reale post-roadmap; SECURITY.md citato; sezione
  preset/report aggiunta.
- Non-regressione: nessuna (solo doc); coerenza README ↔ `--help`.
- Commit: `docs(readme): reconcile with implemented CLI, presets, reports`

#### BM-20 · chore: CHANGELOG + allineamento versione
- Tipo · branch: chore · `chore/changelog`
- Sensibile: no
- Dipende da: tutto il resto integrato
- Perché: **[interp]** se in fase A–H hai scelto `CHANGELOG.md` (decisione D), qui lo popoli e sani
  il drift di versione in modo tracciato, così `/integrate` è completo.
- Fatto quando: CHANGELOG (Keep a Changelog) con le release passate e la nuova; bump SemVer coerente
  (le feature di M2–M4 sono minor; eventuali breaking nei flag → major).
- Non-regressione: `git describe` coerente; CHANGELOG ↔ tag.
- Commit: `chore(release): changelog and version alignment`

---

## 3. Ordine di esecuzione (rispetta le dipendenze)

Sequenza lineare consigliata. **[op]** i task M1 sono indipendenti tra loro: puoi variarne l'ordine
interno, ma integrali tutti prima di M2.

```
Precondizioni → baseline tag
BM-01
BM-02 · BM-03 · BM-04 · BM-05a · BM-05b · BM-06 · BM-07        (M1, sicurezza)
BM-08a → BM-08b → BM-08c                                        (M2, resolver)
BM-09 → BM-10 · BM-11 · BM-12                                   (M3, TUI)
BM-13 → BM-14                                                   (report)
BM-15                                                           (preset)
BM-16 · BM-17 · BM-18                                           (safety/feature)
BM-19 → BM-20                                                   (docs, per ultimo)
```

Perché quest'ordine e non l'ordine di "appeal": **[interp]** i preset (BM-15, quelli che vuoi di più)
dipendono dal resolver (BM-08b), che dipende dai fix di sicurezza (M1) per non ereditare i difetti nel
codice di dispatch. Costruire la TUI o i preset prima significherebbe rifarli dopo i fix. La roadmap è
un grafo di dipendenze, non una lista di desideri.

---

## 4. Design della TUI (bella + funzionale)

Vincolo: zsh puro + `tput`/ANSI, **nessuna dipendenza** (niente `gum`/`charm`: violerebbero il vincolo
di progetto). "Bella" qui = sistema visivo coerente, palette semantica, degradazione pulita — non
effetti che nascondono il rischio.

### 4.1 Principi
1. Il colore ha **significato**, non decorazione: una tinta = uno stato.
2. Il rischio è **sempre visibile** prima dell'azione (badge + cornice).
3. **Degrada senza rompersi**: non-TTY/`NO_COLOR`/terminale povero → resta leggibile in ASCII puro.
4. Coerenza spaziale: stesse regole di padding e larghezza ovunque.

### 4.2 Rilevamento capacità (in common.sh)
```
- truecolor : [[ "$COLORTERM" == (truecolor|24bit) ]]
- 256 col   : (( $(tput colors 2>/dev/null || echo 0) >= 256 ))
- 16 col    : fallback
- no ANSI   : [[ -n "$NO_COLOR" ]] || [[ ! -t 1 ]]   # non-TTY o preferenza utente
- Unicode   : [[ "$LANG$LC_ALL" == *UTF-8* ]]  → box tondi; altrimenti ASCII +-|
```
**[op]** il check `-t 1` è quello che tiene puliti i log (già strippi ANSI/CR a fine sessione): in
pipe/agente non emetti sequenze, così il report resta pulito alla fonte.

### 4.3 Palette semantica (proposta — [op], adatta ai tuoi gusti)
Ruolo → truecolor (hex) → 256 → 16, con fallback automatico:
```
brand/accent (🍺)  #D78700  214  yellow
ok / read-only     #5FAF5F  71   green
attention/warning  #D7AF00  178  yellow
danger/distruttivo #D75F5F  167  red (bold)
info secondario    #8A8A8A  245  dim
heading            #FFFFFF  231  bold white
```
Regola: **una** tinta accento, il resto sono stati. Niente arcobaleno.

### 4.4 Box e spaziatura
```
Card modulo (Unicode):        Fallback ASCII:
╭───────────────────────╮     +-----------------------+
│  [!] 5  Cleanup        │     | [!] 5  Cleanup        |
│      libera spazio…    │     |     libera spazio...  |
╰───────────────────────╯     +-----------------------+
```
- Padding interno: 2 spazi a sinistra.
- Riga vuota tra sezioni. Larghezza colonne fissa (numero / badge / nome).
- Regole orizzontali `────` per separare header/menu/footer.

### 4.5 Badge di rischio (il pezzo che lega sicurezza e grafica)
```
[RO]  read-only        (verde/dim)   — solo lettura, nessuna scrittura
[W]   scrive           (giallo)      — modifica cache/metadati/file in logs|backups|agents
[!]   distruttivo      (rosso bold)  — rimuove, adotta, installa, carica LaunchAgent
```
Posizione: a sinistra del numero nel menu, e nella riga "About this module: può {…}".
**[interp]** questo è ciò che rende il menu auto-documentante sul rischio: prima ancora di entrare
in un modulo sai se tocca il sistema.

### 4.6 Progresso (spinner puro-shell)
```
frames Unicode: ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏     fallback ASCII: | / - \
```
Implementazione: processo in background che stampa il frame + `\r`; `trap` per fermarlo e pulire la
riga; **mai** in non-TTY. Lo `\r` è già gestito dallo stripping dei log.

### 4.7 Mockup — menu (dopo)
```
  🍺  brew-manager v1.2.0                         macOS · zsh · Homebrew 4.x
  ────────────────────────────────────────────────────────────────────────
   AUDIT & MAINTENANCE                    (go = esegui 0→13)

   [RO]  0  Audit app non gestite     confronta /Applications con i cask
   [RO]  1  Salute sistema            brew doctor, permessi, spazio
   [W]   2  Update database           brew update (solo metadati)
   [RO]  3  Report pacchetti          casks + formule installate
   [!]   4  Aggiornamenti             upgrade cask/formule (chiede conferma)
   [!]   5  Cleanup                   autoremove + cleanup cache
   …
  ────────────────────────────────────────────────────────────────────────
   STRUMENTI       log · bk (backup) · las (scheduler) · mas · doctor · preset
  ────────────────────────────────────────────────────────────────────────
   preset:  audit-safe · weekly · disk-check              (--dry-run sempre disponibile)

   › _
```

### 4.8 Mockup — conferma distruttiva (dopo)
```
  ╭─ [!] AZIONE DISTRUTTIVA ──────────────────────────────────╮
  │  mod_05 · Cleanup                                         │
  │  Rimuoverò:  orfani (brew autoremove)                     │
  │             cache e versioni vecchie (brew cleanup -s)    │
  │  Spazio stimato liberato:  1.8 GB                         │
  │                                                           │
  │  Digita  cleanup  per confermare (o invio per annullare): │
  ╰───────────────────────────────────────────────────────────╯
  › _
```
(La conferma digitata scatta solo per il tier "alto" — BM-16. Sotto `--dry-run` questo box mostra
"ANTEPRIMA — nessuna modifica" e non chiede nulla.)

### 4.9 Mockup — summary finale (dopo)
```
  ────────────────────────────────────────────────────────────────────────
   Riepilogo sessione                                        durata  1m 12s
  ────────────────────────────────────────────────────────────────────────
   ✓  0  Audit app          3 adottabili, 12 gestite
   ✓  1  Salute sistema     ok
   ✓  4  Aggiornamenti      7 aggiornati
   ↷  5  Cleanup            saltato (--dry-run)
   ✗  10 Greedy             1 fallito (exit 1) — vedi log
  ────────────────────────────────────────────────────────────────────────
   Disco:  liberati 0 B (dry-run)     Log:  logs/brew_report_20260712_…log
```
Glifi con fallback ASCII: `✓`→`[OK]`, `↷`→`[--]`, `✗`→`[!!]`.

---

## 5. Design dei preset

### 5.1 Perché questo formato
**[op]** niente TOML/YAML: richiederebbe un parser e tu usi `python3` **solo** per JSON (vincolo di
progetto). Un formato plain-text parsabile in zsh puro è coerente col resto e a zero dipendenze.
**[interp]** config **utente**, fuori dal repo (come topgrade/MacOS-Maid): è personale, non si
committa, sopravvive agli aggiornamenti del repo. Il repo spedisce esempi.

### 5.2 Posizione e formato
```
~/.config/brew-manager/presets.conf     # XDG; il repo include presets.example.conf

# formato:  nome: moduli [| flag-di-default]
# 'safe-only' come flag rende il preset incapace di includere moduli di scrittura
audit-safe:  0,1,3,4,6,8,11,12,13 | --dry-run safe-only
weekly:      0,1,2,4,5,10 | --yes
disk-check:  5,13
adopt:       0 | --adopt=all
```

### 5.3 Semantica
- `./brew_manager.sh preset weekly` → il resolver (BM-08b) espande in `0,1,2,4,5,10` e applica `--yes`.
- Un preset può **incorporare** `--dry-run`: `audit-safe` è read-only per costruzione.
- `safe-only`: se il preset elenca un modulo di scrittura, errore in fase di caricamento (fail-fast),
  non a metà run. **[op]** è ciò che lega i preset al modello di rischio invece di renderli una mera
  scorciatoia: un preset marchiato sicuro non *può* diventare pericoloso per una svista.
- Nome inesistente → messaggio chiaro con lista dei preset disponibili, exit code ≠ 0.

### 5.4 Integrazione TUI
Voce `preset` nel menu (sotto il separatore, come i moduli speciali) che elenca i preset disponibili
con il loro badge di rischio aggregato: `audit-safe [RO]`, `weekly [!]`.

---

## 6. Assunzioni e rischi

- **[?]** Nomi esatti di funzioni/variabili in `common.sh` (`_ask`, `_read_choice`, `YES_MODE`,
  `BREW_MANAGER_DRY_RUN`) presi dall'assessment: Claude Code li verifica sul codice reale prima di
  toccarli.
- **[interp]** La palette e i mockup sono una proposta di partenza: sono gusti, non vincoli. Cambiali
  liberamente; ciò che conta è il *sistema* (una tinta = uno stato, rischio visibile, degradazione).
- **[op]** `bats-core` (BM-18) è l'unica dipendenza di sviluppo potenzialmente nuova. È opt-in e non
  runtime; se preferisci zero footprint, restano gli smoke-test `zsh -n`.
- **[fatto]** I dati sui progetti esterni (topgrade, MacOS-Maid, ggasp/cleanup) sono di questo mese;
  il comportamento di `brew`/macOS può cambiare — i task che dipendono da flag `brew` vanno verificati
  a runtime, non assunti.
- Ogni task resta reversibile: baseline taggata, un branch per unità, merge solo dopo tua approvazione.
