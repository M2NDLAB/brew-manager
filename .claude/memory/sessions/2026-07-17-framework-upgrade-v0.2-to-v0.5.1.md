---
type: session
date: 2026-07-17
branch: chore/framework-upgrade-v0.2-to-v0.5.1
tags: [session, framework, upgrade, process, harvest, hooks-install]
---
# Upgrade dell'innesto claude-code-framework v0.2.0 → v0.5.1

Primo upgrade reale dell'innesto, eseguito con la procedura formale *"Aggiornare il
framework su un progetto già innestato"* (SETUP.md del framework, introdotta in v0.5.0).
Baseline di partenza accertata **v0.2.0** per contenuto (nessun provenance-pin: innesto
pre-IMP-036). Solo layer di PROCESSO toccato; memoria di progetto preservata.
Piano: [[plans/framework-upgrade-v0.2-to-v0.5.1]]. SHA pre-upgrade `b929a23`.

## Metodo (3 classi di file)
- **METODO** (porta a v0.5.1): docs/01·06, commands/integrate·lint-memory, scripts/README.
- **IBRIDO** (merge a 3 vie, base=v0.2.0): CLAUDE.md, Makefile, scripts/hooks-install.sh,
  docs/03·04. Preservati i blocchi project-inline e le personalizzazioni.
- **MEMORIA-DI-PROGETTO** (intatta): tutta `.claude/memory/` tranne l'header di LEARNINGS
  (eccezione R3) e il file di piano (artefatto del deliverable).
- **Invariata** (già = v0.5.1 o fw-invariata, nessuna azione): docs/00·02·05, commands/
  checkpoint·new-component·retro·security-review·sos, settings.json, .gitignore,
  reset-task.sh, commitlint.config.cjs.

## Fatto (7 commit su chore/framework-upgrade-v0.2-to-v0.5.1)
- `6c10e89` [task 0] piano + branch.
- `1bf77eb` [task 1] doc/comandi v0.3.0: integrate.md base-guard (SemVer), docs/03 scan-
  storia gitleaks (3-vie), docs/04 razionale tag annotati (3-vie), lint-memory controllo
  10. **R5**: i 2 marcatori `[DA DEFINIRE AL SETUP]` spezzati (docs/04, integrate.md)
  ricompattati su una riga — sono generici/runtime, non si compilano.
- `0652ab7` [task 2] hooks-install.sh 3-vie **per-versione** (v0.3.0 guardie hook-estranei/
  core.hooksPath/.bak + v0.5.1 fix symlink dangling) + scripts/README + test-hooks-
  install.sh (nuovo) + Makefile `test-scripts`. VERIFICA FUNZIONALE REALE dimostrata su
  repo ermetico: secret finto → **bloccato** (gitleaks rc=1); commit non-conventional →
  **rifiutato** (commitlint rc=1); commento shfmt-zsh di brew **propagato** nell'hook
  generato; re-run **idempotente** (nessun .bak); `make test-scripts` PASS (dangling
  RED→GREEN).
- `30eb9f5` [task 3] pacchetto harvest (R3): docs/06 (perimetro LIVELLO 1 + ponte),
  harvest-framework.md (nuovo), CLAUDE.md +/harvest-framework.
- `c0376c4` [task 4] LEARNINGS header: attributo `Destinazione: framework` + riga nel
  commento-formato. Diff puramente additivo, **nessuna voce IMP-001…004 toccata**.
- `176ecd1` [task 5] audit + invariante + lint + build (esiti sotto).
- `(task 6)` questo checkpoint.

## Decisioni dell'utente applicate
- **R1 — rimandi orfani potati a mano.** I doc-metodo aggiornati rimandavano a file che
  brew non ha (`SETUP.md`, `CONTRIBUTING.md`, "README Filosofia", numeri IMP del
  framework): riformulati/rimossi file per file. In docs/03 il rimando a SETUP.md è
  diventato il debito reale tracciato in `STATE.md` («Attenzione») — un ref valido, non
  penzolante.
- **R3 — pacchetto harvest adottato COMPLETO** (comando + ponte docs/06 + attributo nel
  formato di LEARNINGS). Cautela: mai toccate le voci IMP di brew.
- **R4 — docs/01 OMESSO per intero.** Entrambi gli hunk della modifica v0.5.1 (IMP-034,
  regime ibrido) sono framework-repo-specifici; il secondo (patch allo step RIPRESA)
  rimanda al primo, quindi non c'è una patch generale da salvare. docs/01 resta a v0.2.0.
- **R5** — vedi task 1: marcatori ricompattati, non compilati (generici/runtime).

## Verifiche non negoziabili (esiti)
- **Task 2 (hooks-install)**: tutte le prove funzionali DIMOSTRATE (vedi sopra), non
  asserite. Il 3-vie è stato validato per-versione: il risultato differisce da template@
  v0.5.1 SOLO per il commento shfmt-zsh di brew → corpo-framework di entrambe le versioni
  integro, personalizzazione intatta.
- **Task 5 (invariante memoria)**: `git diff b929a23 -- .claude/memory/` = **esattamente
  2 file** (piano + LEARNINGS header-only). Nessun altro file di memory/ nel diff.
- Audit marcatori: sentinella `"DA DEFINIRE AL$"` VUOTA; residui solo generici/runtime
  (una riga) o falsi positivi in prosa. `make check` rc=0, `make test` rc=0.

## Confine / hand-off
- Nessun merge/push/tag eseguiti (confine di docs/04). Bump prodotto: **nessun tag**
  (upgrade solo-processo = `chore`, non una release di brew). Il blocco `/integrate` è
  stato stampato per l'utente. Merge/push = utente.
- Nota hook (caso-limite 4): `make hooks-install` re-run è OBBLIGATORIO e idempotente
  (hook di brew portano il marcatore, contenuto generato invariato). `.git/hooks` non è
  tracciato: se il branch viene scartato dopo il re-run, ri-eseguire hooks-install da main.

## Collegamenti
[[plans/framework-upgrade-v0.2-to-v0.5.1]] · [[STATE]] · [[LEARNINGS]] · [[TREE]] ·
[[sessions/2026-07-11-innesto-note]] (l'innesto originale da v0.2.0)
