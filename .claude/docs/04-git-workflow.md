# 04 — Git workflow: commit, branch, merge, rollback

Regole PERMANENTI. Claude Code le applica in autonomia dove indicato e chiede
conferma dove indicato.

## Modello di branching

> **Convenzione di lettura — i nomi dei branch in QUESTO progetto.** In
> questo doc e nei comandi, **branch di integrazione** (dove confluiscono le feature) e
> **branch stabile** (le versioni rilasciate) sono RUOLI, non nomi imposti.
> **brew-manager è trunk-based su `main`: i due ruoli COINCIDONO** — "merge sul
> branch di integrazione" e "release sul branch stabile" si riferiscono entrambi a
> `main`. Esiste un `origin/dev` remoto, dormiente e allineato a `main` al momento
> dell'innesto: non è il branch di integrazione (decisione registrata in
> `.claude/memory/decisions/`). Dove qui sotto si legge `develop`, in questo
> progetto vale `main`.

Modello di DEFAULT (a due branch), come esempio concreto:
- `main` = branch stabile/produzione. Solo merge dal branch di integrazione via
  release, mai commit diretti.
- `develop` = branch di integrazione/staging. Solo merge di feature branch,
  eseguiti da un umano (vedi *Merge*: via PR o via blocco `/integrate`).
- `feat/<area>-<descrizione>` = una feature, vita breve (giorni, non settimane).
- `fix/<area>-<descrizione>` per bugfix; `hotfix/<descrizione>` dal branch stabile (e
  ri-merge nel branch di integrazione subito dopo).
- Claude Code crea SEMPRE un branch prima di iniziare una feature o una modifica
  significativa — mai lavorare direttamente sul branch di integrazione.

## QUANDO committare (i punti importanti)

Commit = checkpoint logico autoconsistente che compila e passa i test. Si committa:
1. PRIMA di ogni cambiamento rischioso o refactor ampio (checkpoint di sicurezza per
   il rollback).
2. Quando una unità funzionante è completa (una migrazione + il modello, un endpoint
   con i suoi test, un componente UI funzionante).
3. Alla fine di ogni task di un piano (vedi `01-task-planning.md`).
4. SEMPRE prima di chiudere una sessione, anche se il lavoro è parziale (commit con
   prefisso `wip:` SOLO su feature branch — mai `wip` su `develop`).

MAI committare: codice che non compila su `develop`/`main`; file di ambiente o
secret (gitleaks blocca, ma non contarci come unica difesa); artefatti di build e
dipendenze installate.

## Formato commit — Conventional Commits

`<tipo>(<scope>): <descrizione imperativa minuscola>`

Tipi: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`.
Scope = nome del componente o area. Body (obbligatorio se il cambiamento non è
ovvio): il PERCHÉ del cambiamento, non il cosa (il cosa è nel diff). Footer per i
riferimenti (`Refs: #issue`, o un rimando alla decisione/ADR registrata).

Esempio:
```
feat(<area>): aggiungi step di compensazione al flusso X

Il flusso lasciava una risorsa bloccata quando il passo Y andava in timeout.
Aggiunto uno step di compensazione idempotente.
Refs: #123
```

Il formato è verificato dall'hook `commit-msg` (commitlint) e definito in
`commitlint.config.cjs`.

**Storia condivisa = per sempre.** Nei messaggi destinati alla storia condivisa
(commit, merge, tag) nessun riferimento a istanze ESTERNE al progetto — nomi di
altri progetti, clienti, ambienti privati: la storia pushata non si riscrive, e in
un repo-template un nome concreto vi resta per sempre, violando l'agnosticità.

## Merge

- Feature → `develop`: il merge è SEMPRE un'azione umana, mai eseguita da Claude
  Code, in una di due forme — questo progetto adotta il **blocco `/integrate`**
  (sviluppatore singolo, trunk-based su `main`):
  - **via Pull Request** quando esiste un flusso di review remoto (team, forge con
    review obbligatoria);
  - **via blocco `/integrate`** (merge locale `--no-ff` che l'UTENTE incolla ed
    esegue) nel flusso a sviluppatore singolo, dove una PR verso se stessi non
    aggiunge controllo.
  In entrambe le forme, prima del merge: rebase su `develop`
  (`git fetch && git rebase origin/develop`) per risolvere i conflitti nel branch,
  non nel merge.
- Strategia: squash merge per feature piccole (storia pulita), merge commit per
  feature grandi dove la storia interna dei commit ha valore. Mai fast-forward su
  `develop` (si perde la traccia del branch).
- Messaggio del merge commit: `merge:` NON è un tipo valido per commitlint. Per un
  merge esplicito (`--no-ff`) usa un tipo valido con "merge" nella descrizione, es.
  `feat(<area>): merge <feature> in develop`. I merge auto-generati da git ("Merge
  branch …") commitlint li ignora di default, ma preferiamo il messaggio conventional
  esplicito.
- `develop` → `main`: solo come merge di release, nella stessa forma scelta sopra
  (PR di release, o variante release del blocco `/integrate`). Il tag di versione
  segue la sezione *Versioning* qui sotto (in 0.x si tagga su `develop`; da `1.0.0`
  in poi su `main`, dopo il merge di release).

Conflitti: Claude Code li risolve solo se banali (import, formattazione); se toccano
logica, si FERMA e chiede all'utente mostrando le due versioni.

## Versioning — SemVer su tag annotati

Le versioni sono **tag git annotati** (`git tag -a vX.Y.Z -m "..."`), mai tag
leggeri: un tag annotato porta autore, data e messaggio ed è ciò che `git describe`
usa per calcolare la versione corrente e la distanza da essa. Formato SemVer `vX.Y.Z`.

**Il tipo di conventional commit suggerisce il bump** (la decisione finale resta
dell'utente — vedi "Tag e release"):

| Commit                                                          | Bump        |
| --------------------------------------------------------------- | ----------- |
| `feat`                                                          | MINOR       |
| `fix` (incluse le correzioni di sicurezza)                      | PATCH       |
| breaking change (`tipo!` o footer `BREAKING CHANGE:`)           | MAJOR       |
| `refactor`/`perf`/`test`/`docs`/`build`/`ci`/`chore`, sola doc/memoria | **nessun tag** |

Per un deliverable che raccoglie più commit, il bump è il **più alto** tra quelli dei
commit inclusi (un solo `feat` tra tanti `chore` → MINOR; nessun `feat`/`fix` →
nessun tag, è lavoro interno, non un rilascio).

Esistono **due regimi**, e determinano su QUALE BRANCH vive il tag:

- **Pre-1.0 — si tagga sul branch di SVILUPPO.** Finché non c'è la prima release
  stabile la versione è `0.y.z` e i tag vivono su `develop`, non su `main`: feature →
  bump MINOR (`v0.1.0` → `v0.2.0`), fix/sicurezza → bump PATCH (`v0.2.0` → `v0.2.1`),
  refactor/doc/memoria → nessun tag. In 0.x non si promette stabilità dell'API: un
  breaking interno resta nel MINOR e non forza da solo l'1.0.0.
- **Rilascio della 1.0.0 — promozione al branch STABILE.** Quando lo sviluppo è
  completo e l'API è considerata stabile, si porta `develop` su `main` con un merge
  di release (nella forma scelta in *Merge*) e si applica il tag **`v1.0.0` su
  `main`**. Da qui `main` è la linea delle versioni rilasciate.
- **Post-1.0 — si tagga sul branch STABILE.** Da 1.0.0 i tag di rilascio vivono su
  `main`, dopo il merge di release `develop → main`: breaking → MAJOR
  (`v1.4.2` → `v2.0.0`), feature → MINOR (`v1.4.2` → `v1.5.0`), fix → PATCH
  (`v1.4.2` → `v1.4.3`). Un **hotfix** parte da `main`, è un PATCH taggato su `main`,
  e va ri-mergiato su `develop` subito dopo (vedi "Modello di branching") così la
  correzione non si perde alla release successiva.

> **Conflitto storico risolto qui.** La regola precedente — "tag solo dopo il merge su
> `main`" — descriveva solo il post-1.0 e ignorava la fase 0.x. È SOSTITUITA da questi
> due regimi: in 0.x si tagga su `develop`, da 1.0.0 su `main`. Non restano due
> istruzioni in conflitto.

> Modello di branching diverso (es. trunk-based, o nomi differenti — [DA DEFINIRE AL
> SETUP])? I nomi cambiano, i due regimi no: pre-1.0 si tagga sulla linea di lavoro,
> post-1.0 sulla linea rilasciata.

**Igiene dei tag e del push (per l'utente che esegue).**
- Il tag si DIGITA a mano, con un solo `-m` breve e ASCII puro: em-dash, accenti e
  spazi non-breaking copiati da un editor corrompono il comando in modi oscuri.
- Prima di pushare un tag: verificarlo SEMPRE con `git rev-parse <tag>`.
  `git tag -d` si usa SOLO se quella verifica fallisce — mai su un tag sano, e mai
  inline coi comandi costruttivi (vedi "Confine di esecuzione").
- Prima di ogni push su un branch condiviso: `git log origin/<branch>..<branch>`
  per vedere ESATTAMENTE cosa si sta per rendere pubblico — un push trascina TUTTI
  i commit locali, non solo l'ultimo.

## Rollback — scegliere lo strumento giusto

- Commit già pushato su branch condiviso (`develop`/`main`): `git revert <sha>` —
  crea un commit inverso, la storia resta intatta. È l'UNICA opzione sui branch
  condivisi. Mai reset/force-push su `develop` o `main`.
- Commit locale non pushato: `git reset --soft HEAD~1` (tiene le modifiche) o
  `--hard` (le distrugge — chiedere SEMPRE conferma all'utente prima di `--hard`).
- Esperimento da buttare: il branch si cancella, niente da annullare — è il motivo
  per cui si lavora SEMPRE su branch.
- Release rotta in produzione: rollback del **deploy** PRIMA (riportare l'ambiente
  alla versione precedente), revert del **codice** DOPO con calma. Non si debugga in
  produzione.
- `git push --force` è VIETATO ovunque tranne sul proprio feature branch non
  condiviso, e solo come `--force-with-lease`.

## Regole operative per Claude Code

- `git status` e `git diff` prima di ogni commit: verificare che entrino SOLO i file
  attesi. Mai `git add .` alla cieca — add esplicito per path.
- Push: solo su richiesta dell'utente o a fine task completato. La configurazione
  (`.claude/settings.json`) nega il push automatico — è intenzionale: il push lo
  conferma l'umano.
- Tag e release: solo l'utente decide quando; Claude Code prepara (changelog dai
  conventional commit, bump versione secondo *Versioning*, tag annotato già scritto)
  e chiede conferma.
- Blocco di integrazione: a fine deliverable, `/integrate` produce la sequenza di
  comandi di merge + tag pronta da incollare (prossima versione calcolata da
  `git describe` e dal bump di *Versioning*). Claude Code la STAMPA, non la esegue:
  push, merge e tag restano azioni umane.

## Confine di esecuzione e blocchi per l'utente

Il confine che decide CHI esegue un comando git è lo STATO che il comando tocca.
Dichiararlo esplicitamente evita gli incidenti che nascono dalla sua ambiguità:

- **Storia LOCALE → Claude Code.** Commit, amend, `rm --cached`, branch locali,
  rebase del proprio feature branch: li esegue Claude Code in autonomia, dentro le
  regole di questo doc.
- **Storia CONDIVISA → l'utente.** Push, merge sul branch di integrazione, tag:
  Claude Code li PREPARA (blocchi pronti da incollare, vedi `/integrate`), l'utente
  li esegue dal suo terminale.

Regole per ogni blocco di comandi destinato all'esecuzione manuale dell'utente:

1. **Valori REALI, mai placeholder nudi.** SHA, branch e versioni letti da
   `git log`/`git tag`/`git describe`, mai `<hash>`/`vX.Y.Z`/`<branch>` da risolvere
   a mano. Se un valore non è risolvibile a priori, marcarlo esplicitamente:
   "sostituisci X leggendolo da `<comando>`".
2. **Placeholder per l'esecutore ≠ comandi per l'utente.** I placeholder nei comandi
   che esegue Claude Code (l'esecutore li risolve da solo) non si passano MAI
   all'utente: l'utente non deve risolvere nulla.
3. **Comandi distruttivi mai inline.** `tag -d`, `branch -D`, `reset --hard`,
   `push --force`, `rm`: mai nello stesso blocco copia-incolla dei comandi
   costruttivi. Vanno in un blocco SEPARATO, preceduto dalla condizione ESATTA che
   li giustifica ("solo se `<comando>` fallisce") — mai eseguibili per inerzia
   scorrendo la sequenza.

## Configurazione dei permessi (`settings.json`)

I permessi versionati (`.claude/settings.json`) sono la rete di sicurezza che decide
cosa Claude Code può eseguire senza chiedere. Tienili **puliti e specifici**:

- **`allow`**: solo comandi **read-only** (ispezione: `status`, `diff`, `log`,
  `branch`, la mappa dell'albero) e i comandi **sicuri e reversibili** di
  staging/commit (`git add`, `git commit`). Nient'altro: si riducono i prompt per le
  operazioni innocue, non per quelle che toccano stato condiviso.
- **`deny`**: tutte le operazioni **distruttive o irreversibili** — push (incluso
  `--force`), `reset --hard`, cancellazioni (`clean`, `branch -D`, `rm -rf`), e la
  **lettura di segreti** (`.env`, `secrets/`, file di credenziali). La `deny` ha la
  precedenza sull'`allow`: un `git branch:*` permesso resta comunque bloccato sul `-D`.
- **File locale NON versionato.** I permessi personali stanno in `settings.local.json`
  (già in `.gitignore`) e si parte **vuoti**: ciò che è condiviso e ragionato sta nel
  file versionato; le concessioni estemporanee restano locali e non inquinano il
  template del progetto.
- **Niente auto-approvazioni vaghe.** Evita le concessioni "non chiedere più per
  comandi simili": un `allow` troppo largo è un buco che nessuno ricorda di aver
  aperto. Meglio un prompt in più che un permesso implicito e dimenticato.

> I comandi read-only specifici dello stack aggiunti all'`allow` di questo progetto:
> `zsh -n` (check di sintassi), `shellcheck` (se installato), `brew list`,
> `brew info`, `git tag` (elenco), `git describe`.
