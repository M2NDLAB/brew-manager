---
type: learnings
updated: 2026-09-25
tags: [improvement]
---
# Learnings & improvement proposals

> **What this file is.** The backlog of process self-improvement (see
> `.claude/docs/06-self-improvement.md`). Here Claude Code records the proposed
> changes to rules, docs, commands and configuration (IMP-nnn) — but it does NOT
> apply them on its own: it applies them only after the user approves. Purely
> FACTUAL corrections to the docs (Level 1) do not go through here, they are
> applied immediately.
>
> La numerazione delle IMP di brew-manager parte da **001**. Le IMP del
> claude-code-framework (001–026 nel repo del framework) NON si ereditano: questo
> file è nato vuoto all'innesto (2026-07-12, framework v0.2.0). Le frizioni
> brownfield osservate durante l'innesto sono materiale per il FRAMEWORK, non per
> questo progetto: sono annotate in
> [[sessions/2026-07-11-innesto-note]].
>
> **The `Destination: framework` attribute.** In a CLIENT project an IMP may concern
> the FRAMEWORK rather than this project: it is marked with the line
> `- Destination: framework` (a single physical line, so `/harvest-framework` picks
> it up via grep). Omitted = a lesson about this project, which stays in the client.
> It is a DESTINATION attribute, not a level: the lesson stays a Level 2 one — see
> `docs/06-self-improvement.md`, *"The bridge to the framework"*. IN THE FRAMEWORK
> REPO the attribute is moot (every IMP is already about the framework) and is not
> used on the entries.

## Proposte APERTE (in attesa di decisione utente)

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

### IMP-012 — `hooks-install.sh` cannot run from a linked worktree, while the method recommends worktrees
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — `HOOKS_DIR="${REPO_ROOT}/.git/hooks"` is hard-coded
- Observed problem: in a linked worktree `.git` is a file (`gitdir:`), so the script
  fails with `mkdir: …/.git: Not a directory` (every version from v0.2.0 to v1.2.0).
  Worse, running Step 4 from the main worktree while the upgrade branch lives in a
  linked one executes the OLD script and exits 0 with the old hooks: a false green.
  docs/00 ("separate branch (or worktree)") and brew's IMP-006 both recommend
  worktrees.
- Proposal: resolve the hooks directory with `git -C "$REPO_ROOT" rev-parse
  --git-path hooks` (it returns the common hooks dir from a linked worktree —
  verified); until then, state in the upgrade procedure that Step 4 runs from the
  main worktree.
- Expected benefit / risk: removes a silent false green from Step 4. Risk: low, one
  line plus a self-test case.
- Resumption trigger: next framework release touching `hooks-install.sh`.
- Destination: framework

### IMP-013 — The edge-case-4 rollback does not work across a hook-marker change
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — the vX script treats the vY hooks as foreign
- Observed problem: SETUP (edge case 4) says to re-run `make hooks-install` from vX if
  the upgrade is abandoned after Step 4. For any upgrade from ≤v1.0.0 to ≥v1.1.0 that
  fails with rc=1 ("a hook not installed by this script already exists"): the old
  script only knows the Italian marker. It needs `FORCE_OVERWRITE=1`, which in turn
  overwrites the `.bak` saved by Step 4 (harmless: the originals are regenerable).
  brew's own session notes of the two previous upgrades prescribe the failing command.
- Proposal: document the rollback with `FORCE_OVERWRITE=1` (or "restore the `.bak`
  first, then a plain run") in edge case 4, and mention that the first vY run
  produces the expected WARNING + `.bak` pair.
- Expected benefit / risk: a rollback that works as written. Risk: none.
- Resumption trigger: next revision of the SETUP upgrade section.
- Destination: framework

### IMP-014 — docs/05 escalation delimiters changed without the legacy reader the CHANGELOG promises
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — `FINE RESPONSE` → `END OF RESPONSE`
- Observed problem: CHANGELOG [1.1.0] lists the escalation delimiters among the strings
  switched "with backward compatibility", but no reader accepts the Italian closing
  delimiters: docs/05 shows only `END OF REPORT/RESPONSE`, and its rule 1 asks to
  re-paste a block that "looks incomplete". An external Architect still using the old
  format would be bounced. Low impact for brew (no escalation ever opened).
- Proposal: either add one line to docs/05 ("the legacy `FINE REPORT/RESPONSE`
  delimiters are accepted") or correct the CHANGELOG claim.
- Expected benefit / risk: the documented compatibility becomes true. Risk: none.
- Resumption trigger: next framework release.
- Destination: framework

### IMP-015 — A new slot that lives only in an example blockquote does not resurface in the Step 4 grep
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — "Interaction language" has no marker of its own
- Observed problem: v1.1.0 adds the "Interaction language" slot as a bullet of the
  CLAUDE.md example blockquote, covered only by the marker on the section heading.
  A project that replaced the whole blockquote at setup gets no marker back from the
  3-way, so Step 4's grep never shows the new slot; only a checklist catches it.
  Related: the check-10 sentinel (`TO BE DEFINED AT$|DA DEFINIRE AL$`) catches only a
  wrap before "SETUP", not `[TO BE DEFINED⏎AT`, `[TO⏎BE`, or a trailing space.
- Proposal: every release that adds a slot lists it in its CHANGELOG entry under
  "New slots to fill on upgrade", and Step 4 reads that list besides the grep; widen
  the sentinel to every internal break of the marker.
- Expected benefit / risk: new slots cannot be skipped silently. Risk: none.
- Resumption trigger: next release that adds a slot.
- Destination: framework

### IMP-016 — A translation release breaks name-cited section titles between method and non-English memory
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — 13 method citations vs Italian headings
- Observed problem: v1.1.0 translated the STATE/LEARNINGS template headings and the
  method files that cite them by name ("Caution & open issues", "Active branches",
  "Applied", …), without listing them among the behaviour-bearing strings and while
  stating "upgrading needs no migration". A project whose memory stays in its
  language (as rule 9 itself allows for existing content) ends up with 13 citations
  that match no heading, including the /checkpoint "critical debt" check; the reverse
  direction (memory → renamed method titles) dangles too, and edge case 3 covers only
  renamed FILES. On such a release the Step-3 3-way also degenerates into "take vY and
  re-apply" (conflicts on 80-100% of each file), which the procedure does not say.
  brew solved it with a title map in the technical rules (D1). Evidence for the
  framework's IMP-043/046/048, not a duplicate of them.
- Proposal: in the upgrade procedure, a "translation release" note: (1) run the
  IMP-043 old/new grep in BOTH directions, memory included; (2) offer the title-map
  pattern as the standard answer when the memory keeps another language; (3) state
  that the 3-way degenerates into a rebuild and must be declared as such.
- Expected benefit / risk: the next language change does not break name-cited
  contracts silently. Risk: none.
- Resumption trigger: the retro deciding IMP-043/048 in the framework.
- Destination: framework

### IMP-017 — An upgrade touching the security baseline needs a written gate verdict
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — the gate was silently skipped in two previous upgrades
- Observed problem: upgrades rewrite `hooks-install.sh` (the gitleaks baseline),
  `settings.json` (permissions) and `reset-task.sh` (a destructive guard). None of
  them is a sensitive component, and the SETUP procedure never mentions
  /security-review, so the question was never asked (0 verdicts in the notes of the
  two previous upgrades). Also, `reset-task.sh` is classified METHOD although it
  carries a slot a project fills (`PROTECTED_BRANCHES`): an overwrite would have
  dropped brew's `dev` protection.
- Proposal: Step 5 of the upgrade asks for (1) the diff of the EXECUTABLE lines of the
  baseline scripts and (2) a written gate verdict with its reason; reclassify
  `reset-task.sh` as HYBRID.
- Expected benefit / risk: the baseline cannot weaken unnoticed across an upgrade.
  Risk: a few minutes per upgrade.
- Resumption trigger: next revision of the SETUP upgrade section.
- Destination: framework

### IMP-018 — Read the framework ONLY through its tag, and always with `-C`
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — tag shadowing and a moving HEAD
- Observed problem: two traps met in this upgrade. (1) brew has its own `v1.2.0` tag:
  `git show v1.2.0:<path>` run inside the project silently returns the PROJECT's file
  (a different blob), with no error. (2) The framework's HEAD moved during the
  assessment (a parallel commit): anything read from its working tree was no longer
  v1.2.0.
- Proposal: the SETUP procedure prescribes reading vX/vY exclusively as
  `git -C <framework> show "vY:<path>"`, never from the working tree or HEAD, plus a
  sanity check (`git -C <framework> rev-parse vY:<file>` against a known blob).
- Expected benefit / risk: removes two silent wrong-source reads. Risk: none.
- Resumption trigger: next revision of the SETUP upgrade section.
- Destination: framework

### IMP-019 — The `wip:` prefix prescribed by the method is rejected by commitlint
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — found by a FASE 1 verifier
- Observed problem: docs/04 ("WHEN to commit", point 4) and /checkpoint prescribe a
  `wip:` commit before closing a session with partial work, but `wip` is not in the
  commitlint type enum: the commit-msg hook rejects it (`type must be one of …`).
- Proposal: either add `wip` to the enum (feature branches only) or prescribe
  `chore: wip …`.
- Expected benefit / risk: an instruction of the method becomes executable. Risk: none.
- Resumption trigger: next framework release.
- Destination: framework

### IMP-020 — Make the Step-5 memory invariant content-based and ship its checks
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — "empty diff on memory/" cannot hold on a format release
- Observed problem: with Exception A active (IMP-046) the invariant becomes "only these
  files, only these lines", which a plain `git diff` cannot prove. brew needed a
  script: allowed-path diff, a body normaliser for LEARNINGS (from the first `## ` to
  the end, minus the format comment — 289 lines), CONTENT comparison of the guide
  READMEs with their expected files (not hunk headers: Apple diff and git diff print
  them differently), no-backfill and checkpoint-scope checks. It was run on a clone
  with one positive and eight negative branches: all caught.
- Proposal: contribute these checks to the framework as the verification half of
  IMP-046 (a `scripts/verify-memory-invariant.sh` or a Step-5 recipe).
- Expected benefit / risk: the memory guarantee stays mechanical on every upgrade.
  Risk: the script must stay generic (paths of the template only).
- Resumption trigger: the framework's decision on IMP-046.
- Destination: framework

### IMP-021 — A delegation brief must carry the user's decisions verbatim
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — FASE 1 agents flagged a "blocking" non-issue
- Observed problem: the FASE 1 assessment brief given to the review agents paraphrased
  only one of the user's language decisions (the level rule) and left out the
  already-decided rule-9 block. Several agents and verifiers then reported rule 9 as
  "undecided, blocking", and the finding had to be retracted in the report. The same
  run lost 2 of 27 agents to stalls: declaring the uncovered items explicitly, and
  re-checking them by hand, kept the report honest.
- Proposal: in the method (docs/00, effort/delegation hygiene): a brief for delegated
  agents quotes the user's decisions and constraints VERBATIM, never summarised; a
  multi-agent report states its coverage gaps (stalled or skipped agents) explicitly.
- Expected benefit / risk: fewer false findings and no silent coverage holes. Risk:
  longer briefs.
- Resumption trigger: next multi-agent assessment.
- Destination: framework

### IMP-023 — Delegated sandbox runs must not leave processes behind
- Date: 2026-09-25 | Origin: [[sessions/2026-09-24-debt-inventory-pre-dashboard]] — 8 orphaned processes alive ~75 min after the inventory agents finished
- Observed problem: the inventory agents reproduced a hang by running the real CLI
  under `script(1)` in a sandbox, with a watchdog on the direct child. The watchdog
  killed that process, but the grandchild (`script` + the shell) was reparented to PID 1
  and survived. One verifier noticed the other agents' orphans and killed only its own;
  8 processes stayed alive until the main session killed them at the end. Nothing in the
  method says a delegated run must leave the process table as it found it, or who checks.
- Proposal: in the guidance for delegated/adversarial verification (docs/03, the
  multi-agent review paragraph), add: a run of the real program in a sandbox kills the
  whole process group (or session) on timeout, not only its direct child; each agent
  reports the PIDs it could not reap; the orchestrator checks `ps` for processes under
  the scratch directory before declaring the workflow done.
- Expected benefit / risk: no leaked processes (which can keep writing into sandboxes
  or /tmp, and skew later measurements); a few lines of guidance. Risk: none.
- Destination: framework

### IMP-024 — Brief delegated agents in the ARTIFACT language when their output will be persisted
- Date: 2026-09-25 | Origin: [[sessions/2026-09-24-debt-inventory-pre-dashboard]] — the inventory came back in Italian and had to be rewritten in English to enter the memory
- Observed problem: the inventory agents were briefed in the interaction language
  (Italian) and returned ~220 KB of Italian findings. The user then asked to persist the
  full inventory in a session note, which rule 9 requires in English: the main session
  had to rewrite every item by hand — a second pass, with a risk of drift between the
  persisted text and the verified original.
- Proposal: in rule 9 (or in the delegation guidance), state that when a delegated
  agent's output may be persisted (memory, docs, IMP entries), the brief asks for the
  ARTIFACT language even if the user interacts in another one; the main session
  translates only what it shows the user.
- Expected benefit / risk: expensive work is persistable as it is (docs/00: persist
  expensive work immediately), with no translation drift. Risk: the user-facing summary
  needs a translation step — cheaper, and never persisted.
- Destination: framework

### IMP-025 — Applying an approved IMP: map every element of the proposal, and run the command a rule prescribes
- Date: 2026-09-25 | Origin: [[sessions/2026-09-25-apply-project-imps]] — an adversarial review of four IMP applications upheld two high findings
- Observed problem: two of four applied rules were defective although each IMP was
  approved and short. IMP-003 was applied with a sentence that inverted part of the
  approved proposal ("acceptable on screen"); IMP-007 prescribed a smoke command that,
  run as written, would never end for two modules. docs/06 "Applying approved
  proposals" says only "apply the change in the right file": nothing makes the author
  check the applied text against the approved one, or execute what a rule prescribes.
- Proposal: add to docs/06 "Applying approved proposals": before the dedicated commit,
  (1) map every element of the approved proposal to the applied text and state any
  deviation in the commit body and the Applied entry; (2) if the rule prescribes a
  command, run it once as written (in a safe mode) and record the outcome; (3) for a
  rule in a shared method file, an adversarial pass (docs/03) proportional to its
  reach.
- Expected benefit / risk: applied rules say what was approved and work as written;
  the review becomes a check rather than the first line of defence. Risk: a few
  minutes per IMP.
- Destination: framework

<!-- Format of a proposal:
### IMP-001 — <short title>
- Date: YYYY-MM-DD | Origin: [[<session note>]] — <problem>
- Observed problem: <recurring friction, repeated error, gap, ambiguous rule>
- Proposal: <what to change and where: CLAUDE.md / docs/NN / command / hook / process>
- Expected benefit / risk:
- Resumption trigger: <if it is not applicable now: which event brings it back into play>
- Destination: framework   (OPTIONAL — only if the lesson must be sent upstream to the
                            framework; a single physical line, for the grep of /harvest-framework)
-->

## Applicate

### IMP-003 — Convenzione: mai `echo` per normalizzare DATI (espande gli escape) → applied on 2026-09-25 (explicit user approval), commit `a59d5eb` + review fix `36aa1b2` on chore/apply-project-imps
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
- Applied: a "Never pass DATA through `echo`" rule in the CLAUDE.md Code conventions
  (new and rewritten code; the existing sites stay in STATE Attenzione #3b). The
  adversarial review corrected the first draft, which called the expansion in the
  output helpers "acceptable on screen" — the opposite of this proposal and of its
  BM-09 reinforcement: the text now says new code never adds an `echo` of its own on
  data and nothing a helper prints is a source of data; it lists every escape (the
  JSON case is `\n`, `\c` truncates) and gives `printf '%s\n'`/`print -r --` for
  line consumers (bare `printf '%s'` drops the last line of a `while read`).

### IMP-004 — Chiudere una CLASSE di difetto = grep di TUTTI i siti + verifica adversariale → applied on 2026-09-25 (explicit user approval), commit `a7f309f` + review fix `36aa1b2` on chore/apply-project-imps
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
- Applied: a "Closing a CLASS of defect" paragraph in docs/03 "How the gate works"
  (in any module; the re-gate covers the whole branch diff, the fix included). docs/03
  is a framework file: a brew customisation to re-apply at framework upgrades until
  the framework adopts the lesson.
- Destination: framework

### IMP-007 — Smoke del menu interattivo: selezione via CLI, mai pipe sul prompt Choice → applied on 2026-09-25 (explicit user approval), commit `225cadd` + review fix `36aa1b2` on chore/apply-project-imps
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
- Applied: the CLAUDE.md Tests rule and `/new-component` step 5 prescribe the smoke
  `f=$(mktemp) && ./brew_manager.sh <id> --dry-run </dev/null >"$f" 2>&1`. Beyond the
  letter of the proposal, for safety (review finding, upheld): stdin from /dev/null
  (an open stdin waits at the final log prompt, STATE #21), a `mktemp` file (no fixed
  /tmp path, #11), the caveat that `bk`/`log` never end without a terminal until #21
  is fixed. Dropped on purpose: checking the menu "by accepting that the pipe runs
  `go` and interrupting at once" — a piped run falls into `go` and then hangs, and an
  agent cannot interrupt it; the user checks the menu from a real terminal. The
  prescribed command was run on module 8: rc 0, it ends, no leftover process.

### IMP-002 — Checklist "superficie del contratto" per i test di estrazione/parità → applied on 2026-09-25 (explicit user approval), commit `53d4827` + review fix `36aa1b2` on chore/apply-project-imps
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
- Applied: a contract-surface checklist in docs/02 "Tests that demonstrate" (a
  framework file: a brew customisation to re-apply at upgrades). The first draft
  widened the trigger to "an output contract, a new public surface"; the review found
  it beyond the approved scope, so it was narrowed back to parity extractions and
  code built on the same contract, down to the exit code the user observes. Covering
  the Dashboard's JSON schema by the letter would need the user's go.
- Destination: framework

### IMP-022 — Add `lib/selection.sh` to the sensitive components → applied on 2026-09-25 (explicit user approval), commit `90cb34c` on chore/imp-022-sensitive-selection
- Date: 2026-09-24 | Origin: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] — STATE calls it sensitive, rule 8 does not list it
- Observed problem: STATE ("What exists", `lib/selection.sh`) and the component note
  call it the shared dispatch infrastructure, "sensitive", and the input parsing that
  docs/03 attributes to `brew_manager.sh` moved there (`_resolve_selection`,
  `_resolve_cli`). But it is in none of the sensitive lists (CLAUDE.md rule 8 and
  technical rules, docs/03, docs/00, the 2026-07-12 decision), so a branch touching
  only it would skip the gate.
- Proposal: add it to the four lists and to the decision note (Level 2: a rule
  change, after approval).
- Expected benefit / risk: the selection resolver — whose defects already produced
  MEDIUM fail-open findings in BM-08b — stays under the gate. Risk: none.
- Resumption trigger: user decision; at the latest before the next change to
  `lib/selection.sh`.
- Applied: `lib/selection.sh` added to CLAUDE.md rule 8 and the technical rules,
  docs/03 (with "flag parsing" left to `brew_manager.sh`), docs/00, the 2026-07-12
  decision (an English amendment: seven components), INDEX and STATE; `/new-component`
  step 6 now names every list (a factual correction). DoD: a grep over the 8 sites,
  green on the branch and all 8 missing on the parent commit (counter-proof).

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

### IMP-005 — Convenzione: l'output di CONTROLLO terminale gata sulla tty reale, non solo sul colore → deferred on 2026-09-25 (user decision)
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
- Deferred: cut from the pre-Dashboard cleanup by the user — the code already
  complies (`_clear` gated on `TUI_TTY` since BM-09, the spinner since BM-12, no
  raw clear/tput/`\r` in the modules); only the convention line is missing.
- Resumption trigger: new code that emits terminal control output (clear, cursor
  moves, `\r`) outside `_clear`/`_spinner`, or the first M4 module that draws
  progress; also any review that finds such an emission ungated.

## Rifiutate
_(nessuna)_
