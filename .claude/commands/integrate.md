---
description: Genera il blocco "PRONTO PER INTEGRAZIONE" — comandi pronti da incollare per merge + tag, senza eseguirli
---
A fine deliverable, prepara il blocco PRONTO PER INTEGRAZIONE per: $ARGUMENTS
(se vuoto: per il branch corrente).

Claude Code **non pusha e non mergia** — è azione umana (vedi
@.claude/docs/04-git-workflow.md). Qui RACCOGLIE lo stato con comandi di sola lettura
e PRODUCE un blocco di comandi esatti, pronti da incollare. Esegui SOLO i comandi di
lettura dei passi 1-2 e l'aggiornamento del CHANGELOG del passo 3 (commit locale);
tutto il resto va STAMPATO, non eseguito.

## 1. Raccogli lo stato (read-only)
- Branch corrente (feature): `git branch --show-current`.
- Branch di integrazione `<integrazione>` e branch stabile `<stabile>`: sono i RUOLI
  di docs/04 (default di esempio `develop`/`main`; nomi effettivi
  [DA DEFINIRE AL SETUP]). Sostituisci i segnaposto coi nomi reali del progetto.
- Commit del branch non ancora nell'integrazione: `git log --oneline origin/<integrazione>..HEAD`
  (fallback senza remote: `<integrazione>..HEAD`).
- Versione corrente e distanza: `git describe --tags --long` (se non esistono tag,
  parti da `v0.0.0`).
- Guardia sulla BASE: `git describe --tags` accetta anche tag leggeri e nomi
  non-SemVer (tipico di una storia ereditata da un innesto su repo esistente). Se
  il tag base non è nel formato `vX.Y.Z`, FERMATI e segnala: la base del
  versioning va decisa con l'utente (candidata tipica: il tag SemVer più alto,
  `git tag --list 'v*' --sort=-v:refname | head -1`).

## 2. Calcola il bump e la prossima versione
Applica le regole di *Versioning* di docs/04 al set di commit del branch:
- il bump è il PIÙ ALTO tra quelli dei commit: `feat`→MINOR, `fix`→PATCH,
  breaking (`tipo!`/`BREAKING CHANGE:`)→MAJOR;
- se ci sono solo `refactor`/`perf`/`test`/`docs`/`build`/`ci`/`chore` o commit di
  sola memoria/doc → **nessun tag** (è lavoro interno, non un rilascio: dichiaralo
  esplicitamente nel blocco e ometti i comandi di tag);
- rispetta il regime: **pre-1.0** (`0.y.z`) si tagga sul branch di integrazione
  (`<integrazione>`); **post-1.0** il merge feature→`<integrazione>` NON si tagga — il
  tag arriva alla release `<integrazione>`→`<stabile>` (vedi nota in fondo). Calcola la
  prossima versione dal `git describe` del passo 1.

## 3. Aggiorna il CHANGELOG (se il progetto ne tiene uno)

Se alla root esiste un `CHANGELOG.md` (formato Keep a Changelog):
- bump = "nessun tag" → NON toccarlo (il lavoro interno non è una release);
- altrimenti: sposta il contenuto di `## [Unreleased]` sotto una nuova voce
  `## [X.Y.Z] — YYYY-MM-DD` (versione calcolata al passo 2, data di oggi),
  integrandolo con ciò che emerge dai commit del branch, e COMMITTA sul feature
  branch PRIMA di stampare il blocco: così il changelog entra nel merge.

## 4. Stampa il blocco PRONTO PER INTEGRAZIONE
Un unico blocco di codice copiabile, con i segnaposto già sostituiti dai valori reali
calcolati. NON eseguirlo:
```
# 1. allinea la feature sull'integrazione aggiornata (i conflitti si risolvono QUI)
git checkout <feature>
git fetch origin
git rebase origin/<integrazione>

# 2. porta l'integrazione locale al pari del remoto, poi merge esplicito non-fast-forward
git checkout <integrazione>
git merge --ff-only origin/<integrazione>
git merge --no-ff <feature> -m "<tipo>(<scope>): merge <feature> in <integrazione>"

# 3. tag annotato col bump calcolato   (se "nessun tag": ometti questo passo)
#    digita il -m a mano, breve e ASCII puro (niente em-dash/accenti incollati)
git tag -a v<X.Y.Z> -m "v<X.Y.Z> - <sintesi del deliverable>"

# 4. verifica PRIMA del push: il tag esiste ed e' sano, e pubblichi solo i commit attesi
git rev-parse v<X.Y.Z>
git log --oneline origin/<integrazione>..<integrazione>

# 5. push esplicito di branch e tag (lo lanci TU: è l'azione umana)
git push origin <integrazione>
git push origin v<X.Y.Z>

# 6. elimina il feature branch ormai mergiato (safe: -d, mai -D)
git branch -d <feature>
```

Se (e SOLO se) `git rev-parse v<X.Y.Z>` fallisce — tag corrotto, tipicamente da un
copia-incolla — stampa ANCHE questo blocco di recupero, SEPARATO da quello sopra
(docs/04, "Confine di esecuzione"): mai `tag -d` su un tag sano.
```
# SOLO se 'git rev-parse v<X.Y.Z>' e' fallito al passo 4:
git tag -d v<X.Y.Z>
# poi ricrea il tag digitandolo a mano (passo 3) e riverifica (passo 4)
```

## 5. Verifica finale (stampala come checklist)
- l'header del merge commit è entro il limite del commit-linter: **100 caratteri**
  (default conventional, non sovrascritto in `commitlint.config.cjs`);
- il tipo del merge commit è un tipo valido (`feat`/`fix`/...), MAI `merge:`;
- la versione del tag è coerente col bump calcolato e con `git describe`;
- gli argomenti git usano **spazi normali** e trattini ASCII: niente spazi
  non-breaking/unicode né trattini "lunghi" copiati da un editor — un `--no-ff` con un
  carattere sbagliato fallisce in modo oscuro;
- il blocco contiene le due verifiche PRE-push: `git rev-parse` del tag e
  `git log origin/<integrazione>..<integrazione>` (cosa diventa pubblico);
- ogni comando distruttivo (es. `tag -d`) è in blocco SEPARATO con la sua
  condizione, mai inline (docs/04, "Confine di esecuzione").

## Variante release (1.0.0 e post-1.0)
Per la promozione `<integrazione>`→`<stabile>` la sequenza è la stessa ma sul branch
stabile, e il tag (`v1.0.0` o il bump MAJOR/MINOR/PATCH) va su `<stabile>` dopo il
merge di release — vedi *Versioning* in docs/04.

NON eseguire push/merge/tag: il blocco è per l'utente. A integrazione avvenuta,
l'utente può lanciare `/checkpoint` per riconciliare `STATE.md` e i branch attivi.
