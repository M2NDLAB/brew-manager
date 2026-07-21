---
type: session
date: 2026-07-21
branch: fix/dryrun-mod02-mas
tags: [session, dry-run, security-gate, mod-02, mod-mas]
---
# Sessione 2026-07-21 — micro-task: `--dry-run` su mod_02 e mas (+ ciò che il gate ha trovato)

## Cosa è stato fatto
Micro-task deciso dall'utente dopo l'integrazione di BM-12 (strada B): chiudere le
ultime due violazioni del vincolo cardine «`--dry-run` deve disabilitare OGNI
scrittura», quelle che il summary di BM-12 rendeva visibili come `⚠ ran anyway`.
Branch `fix/dryrun-mod02-mas` da `main` `21c956b`, 8 commit.

**I due fix richiesti** (commit 1-2):
- `dfc615b` **mod_02**: `brew update` dietro il gate. Il gate precede sia
  l'esecuzione sia qualunque conferma → `--dry-run` prevale su `--yes`. La
  preview riusa la tabella dei repository (estratta in `_mod02_repo_table`, così
  il ramo reale resta byte-identico) con stato "would be refreshed", più l'età
  della cache API (`_mod02_index_age`, degrada a "unknown", mai un numero finto).
- `211f33e` **mas**: `brew install mas` dietro il gate, posto **prima** di
  `_ask_danger`. Il percorso che installava davvero in dry-run era
  l'INTERATTIVO (utente che risponde `y`): con `--yes` il default del prompt è
  `n`, quindi non si arrivava mai a installare.

**Ciò che il gate ha imposto in più** (commit 4-8): vedi sotto.

## Il gate ha REFUTATO l'affermazione che il branch aveva aggiunto
Gate adversariale a 2 lenti (bypass del gate · verità del registry), come BM-10/12.
Sul codice nuovo: **0 HIGH/CRITICAL**. Entrambe le lenti hanno verificato ed
escluso bypass, injection, perdita di consenso, rottura del contratto pubblico, e
hanno confermato che il ramo non-dry-run è byte-identico a `main` in tutte le
combinazioni palette×unicode (incluso un nome di tap ostile con `%s` e `\e[31m`).

Il problema era altrove: per chiudere due moduli il branch aveva portato
`MODULE_DRYRUN` **tutto a 1**, aggiunto un test di classe e riscritto il README da
«questi due moduli non rispettano `--dry-run`» a «ogni modulo si ferma
all'anteprima». Il diff toccava 2 moduli, l'affermazione ne copriva 18 — e quattro
erano false, per difetti **pre-esistenti** che il branch non aveva introdotto ma
stava ATTESTANDO come verificati:

1. **HIGH — auto-update implicito di Homebrew.** `brew` esegue
   `brew update --auto-update` da sé prima di `install|outdated|upgrade|bundle|
   release` (`brew.sh`, `AUTO_UPDATE_COMMANDS`; verificato sul sorgente
   installato). Nemmeno il `--dry-run` DI BREW lo ferma: la decisione è presa
   prima di leggere gli argomenti. Quindi mod_04, mod_10 e bk riscrivevano
   l'indice in una sessione di sola anteprima — la stessa mutazione appena
   vietata a mod_02.
2. **MEDIUM — `mod_bk [4] Check`** esegue `brew bundle check`, che valuta il
   Brewfile come DSL Ruby, mentre lo stesso file documenta a `:96-99` perché la
   preview del restore lo legge staticamente.
3. **MEDIUM — `mod_las [c]`** cancella `agents_activity.log` e i log per-agente
   con `rm -f`, senza gate (mod_log gata gli `rm` equivalenti).
4. **LOW — `mkdir -p`** ungated in las/log/bk: `~/Library/LaunchAgents` viene
   creata anche in dry-run, anche sul path che poi esce subito in non-interattivo.

**Decisione dell'utente: via di mezzo.** Chiudere (1) — che è una riga e vale per
tutti i moduli — e DICHIARARE onestamente (2) e (3) invece di fixarli qui: sono
componenti sensibili (docs/03) e meritano task e review propri.

## Scelte non ovvie
- **`HOMEBREW_NO_AUTO_UPDATE=1` solo sotto `--dry-run`** (`brew_manager.sh:152`):
  una run normale mantiene il comportamento abituale di Homebrew. È una
  concessione della preview, non un cambio di come il tool guida brew.
  Il test lo verifica **end-to-end sul binario reale** chiedendo a un mock brew
  che valore ha ereditato: la variabile deve sopravvivere al re-exec di
  `script(1)`, e un grep sul sorgente non lo avrebbe dimostrato.
- **`MODULE_DRYRUN[bk]=0` e `[las]=0`**: erano 1 da sempre — dichiarati, mai
  verificati. Il summary ora li marca `⚠ ran anyway`, che è vero, invece di
  attestare un'anteprima che non c'è stata. È lo stesso principio di BM-12
  (mai attestare una proprietà di sicurezza che la run non ha avuto), applicato
  al caso in cui la dichiarazione è ottimista.
- **L'invariante di classe è diventata una ALLOW-LIST** (finding del gate sul mio
  stesso test): asserire "nessun modulo è mai non-gatato" rendeva la
  dichiarazione onesta l'unica mossa che rompe la build — la via più rapida al
  verde sarebbe stata dichiarare 1 e citare `BREW_MANAGER_DRY_RUN` in un
  commento. Ora: un `0` fuori lista fallisce (il debito non cresce in silenzio) e
  una voce stantia fallisce (un modulo fixato non conserva l'esenzione).
  Verificate entrambe le direzioni prima di committare. → [[LEARNINGS]] IMP-009.
- **Il commento del gate mas descriveva la minaccia sbagliata** (finding LOW):
  diceva che `--dry-run --yes` avrebbe auto-confermato l'install. Falso, e in un
  guard-rail un modello di rischio errato invita a "semplificare" il gate e
  riaprire il buco. Corretto in `baecb53`.
- **Etichetta "Package index cache written"**, non "Local index last refreshed":
  il valore è l'mtime della cache API, una proxy (altri comandi ci scrivono; un
  setup a tap può avere indice fresco e cache vecchia). Non promettere più
  precisione di quanta ce n'è è il tema stesso di questo task.

## Insidie tecniche incontrate
- **`local status=` è READ-ONLY in zsh** (alias di `$?`): l'assegnazione abortiva
  `_mod02_repo_table` a metà rendering. Trovato dal nuovo test al primo giro, non
  da una rilettura. Rinominato in `state`.
- **`/tmp/brew_update.log` è un path fisso** (STATE #11): il test wet è il primo
  a rendere quel ramo raggiungibile da `make test`, e `>` tronca attraverso un
  symlink. Il test ora RIFIUTA di girare se quel path è un symlink.

## Verifiche
- `make check` pulito; **suite 268 check verdi** (baseline reale su `main`: 248 —
  la voce «247» in STATE era imprecisa di 1, corretta).
- Nuovo `tests/test_dryrun_gates.zsh` (18 check): tripwire su mock brew, con i
  controlli "denti" in wet per entrambi i moduli (per mas: stesso `y` su stdin,
  `--dry-run` unica variabile) e i 3 check end-to-end sull'auto-update.
- Smoke reali (IMP-007, selezione posizionale): `2 --dry-run` → `↷ preview`;
  `mas --dry-run` → `↷ preview`; `bk --dry-run` → `⚠ ran anyway` (onesto).
- DoD #9: eseguito da worktree pulito — stesso comportamento, 268 verdi.

## Collegamenti
[[lib-selection]] · [[core-brew-manager]] · [[mod-bk-brewfile]] · [[mod-las-scheduler]] ·
[[sessions/2026-07-21-bm12-progress-summary]] (origine di `MODULE_DRYRUN`) · [[STATE]] ·
[[LEARNINGS]] (IMP-009, IMP-010, IMP-011 registrate qui)
