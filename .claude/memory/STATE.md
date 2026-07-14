---
type: state
updated: 2026-07-12
branch: main
tags: [state]
---
# STATE — brew-manager

> Aggiornato: 2026-07-14 | Ultimo: **BM-19 ristretto completo — sequenza di release v1.2.0 in corso** | Indice: [[INDEX]]

## Stato avanzamento
- [x] Progetto maturo e rilasciato: v1.1.2 su `main` (TUI zsh per audit/cleanup di
  Homebrew, 14 moduli standard + 4 speciali, LaunchAgent scheduler, backup Brewfile).
- [x] Innesto del claude-code-framework v0.2.0 — branch `chore/innesto-framework`
  (questo checkpoint). Memoria inizializzata dall'assessment, non da template vuoto.
- [x] Integrazione del branch di innesto in `main` — merge 7893f87 eseguito
  dall'utente; tag baseline `v1.1.2-baseline` creato.
- [ ] Roadmap v2 ([[plans/roadmap-v2]]): BM-01…BM-20 in ordine di dipendenza —
  M1 copre la bonifica dei difetti in "Attenzione". Un task per volta, ok utente
  tra un task e il successivo.
  - [x] BM-01 `make check`/`make lint` — INTEGRATO in main (merge 3d3af76,
    pushato; branch eliminato). Nota: `check` esisteva già dall'innesto; lint è
    ADVISORY ([[2026-07-12-shellcheck-advisory]]).
  - [x] BM-02 fix --dry-run in mod_05_cleanup — INTEGRATO in main (merge 3ae5d41).
  - [x] Micro-task (fuori roadmap, richiesto dall'utente): parser rifiuta i flag
    ignoti, inclusi lookalike Unicode — branch `fix/parser-unknown-flags`,
    commit 0e48373, gate passato, in attesa di integrazione. Chiude Attenzione #9.
  - [x] Micro-task parser: INTEGRATO in main (merge fafa9da). IMP-001 applicata
    (commit ae6cfb6 su questo branch).
  - [x] BM-03: INTEGRATO in main (merge 12dada6).
  - [x] BM-04: INTEGRATO in main (merge 22e0c52).
  - [x] BM-05a: INTEGRATO in main (merge 5d51b14).
  - [x] BM-05b: INTEGRATO in main (merge d555f54).
  - [x] BM-06: INTEGRATO in main (merge cb234fd).
  - [x] BM-07 versione a fonte unica + codice morto — branch
    `refactor/version-deadcode`, commit 3a35309. In attesa di integrazione.
  - [x] **M1 CHIUSO** (BM-01…BM-07): tutti i difetti dell'assessment sanati.
  - [x] Decisione utente 2026-07-14: **si rilascia v1.2.0 ORA** (strada A), M2 dopo.
  - [x] BM-19 RISTRETTO (README ↔ realtà di v1.2.0) — branch `docs/readme-reality`,
    commit 7f7f90d. Regola di onestà: nessun over-claim su CLI posizionale e
    scheduling per-modulo (non esistono ancora).
  - [ ] Release v1.2.0 (branch `chore/release-v1.2.0`) ← PROSSIMO
  - [ ] ⛔ **STOP dopo il push di v1.2.0**: M2 (BM-08a) parte SOLO su via libera
    esplicita dell'utente.
  - [ ] M2 — resolver di selezione (BM-08a/b/c): la chiave di volta; chiude
    Attenzione #1 (CLI posizionali + plist scheduler) e #8 (YES_MODE).

## Cosa esiste adesso
- Albero directory: vedi [[TREE]].
- `brew_manager.sh` — entry point TUI, stabile; dispatch, parsing flag, recording
  sessione via script(1). Vedi [[core-brew-manager]].
- `lib/common.sh` + `lib/log.sh` — infrastruttura TUI e guard-rail condivisi
  (`_ask`, `_read_choice`, YES_MODE, DRY_RUN). Vedi [[lib-common]].
- 14 moduli standard `mod_00`–`mod_13` (sequenza `go`) + 4 speciali `bk`/`las`/
  `log`/`mas` (per nome). 9 moduli read-only; mutanti: 00, 02, 04, 05, 10, bk,
  las, log, mas. Note dei sensibili: [[mod-00-audit]], [[mod-05-cleanup]],
  [[mod-bk-brewfile]], [[mod-las-scheduler]].
- Framework di processo `.claude/` (docs, commands, memoria), CLAUDE.md, Makefile,
  hook git (gitleaks + commitlint), CHANGELOG.md. Vedi
  [[sessions/2026-07-11-innesto-note]].
- Test: ASSENTI. Linter/formatter: ASSENTI (shellcheck/shfmt non installati;
  blocco formattazione predisposto ma commentato nell'hook). CI: assente.

## Decisioni prese (non ovvie dal codice)
- Trunk-based su `main` (integrazione = stabile); `origin/dev` dormiente, non è
  l'integrazione → [[2026-07-12-trunk-based-su-main]].
- Componenti sensibili (regola 8 / docs/03): mod_00, mod_05, mod_bk, mod_las +
  `brew_manager.sh` + `lib/common.sh` → [[2026-07-12-componenti-sensibili]].
- commitlint mantenuto benché il progetto non usi Node (npx risolve al volo, zero
  footprint nel repo); formattazione hook lasciata commentata (shfmt non installato).
- Lingua: doc di progetto (README, SECURITY) in inglese; framework e memoria in
  italiano.
- README non modificato all'innesto: la nota "gestito con Claude Code" resta
  un'opzione aperta (proposta in Contributing o footer).
- SLA di risposta (72h/7gg) RIMOSSI da SECURITY.md dall'utente a mano (commit
  9b7e874): la policy ora promette solo "as soon as reasonably possible". Il
  subject di quel commit è rimasto un placeholder, per scelta dell'utente:
  storia pushata, NON riscrivere.

## Debito documentazione
- ~~README vs realtà di v1.2.0~~ **SALDATO** in BM-19 ristretto (7f7f90d): rimossi
  gli over-claim (CLI posizionale, scheduling per-modulo, esempi `./brew_manager.sh
  bk`), aggiornati i comportamenti (adozione, cleanup, restore, greedy, integrity),
  documentati `--version`/`-V` e SECURITY.md/VERSION/CHANGELOG.
- **Resta aperto**: quando M2 implementerà la selezione da CLI e lo scheduling
  per-modulo, il README va riaggiornato (le avvertenze "Not yet supported" vanno
  rimosse) → parte residua di BM-19.
- README "Project structure": non cita `SECURITY.md` né i file del framework
  (CLAUDE.md, Makefile, scripts/, .claude/) — da aggiornare al primo ritocco del README.
- README "Adding a new module": promette invocabilità da CLI inesistente (stessa
  radice del punto 1).
- ~~`BREW_MANAGER_VERSION="1.1.0"` vs tag v1.1.2~~ **RISOLTO** in BM-07 (file
  VERSION + `make version-check`).

## Attenzione / problemi aperti
1. **Argomenti CLI posizionali non implementati** — il parser gestisce solo i flag;
   la selezione moduli è solo interattiva. AGGRAVANTE: i plist generati da
   `mod_las_scheduler` passano i moduli come argomenti → gli agenti schedulati li
   ignorano e in non-TTY degradano a `go --yes`, che include mod_05
   (autoremove+cleanup SENZA conferma). → TRIGGER: bloccante per qualunque lavoro
   su scheduler/CLI; da risolvere PRIMA di pubblicizzare gli agenti schedulati.
2. ~~**Off-by-one zsh (array 1-based)**~~ **CHIUSO**: adozione mod_00 (BM-04, col
   canale di selezione morto su tutte le release), weekday in las/bk + selezione
   Modify/Remove dello scheduler (BM-05a), contatore mod_09 (BM-05b). La regola
   by-convention resta in CLAUDE.md per il codice nuovo.
3. **DRY_RUN non uniforme**: ~~mod_05~~ (risolto in BM-02), ~~restore bk
   [3]/[3b]~~ (risolto in BM-03); resta `brew install mas` non gated in
   mod_mas. → TRIGGER: qualunque modifica a mod_mas deve prima chiudere il gap.
3b. **Echo intermedio sui dati espande gli escape** (LOW, gate BM-03 +
   verifica empirica: l'echo builtin zsh converte `\e` in ESC): in mod_05
   (dry-run BM-02) e in `_restore_agents` i dati passano per echo prima del
   printf %s → garanzia di inertezza parziale. Il test S7 di BM-02 era un
   falso PASS (grep fragile su od). Fix da poche righe: `printf '%s\n'` al
   posto degli echo intermedi. → TRIGGER: primo intervento su mod_05 o mod_bk
   (o micro-fix dedicato se l'utente lo chiede).
4. ~~**mod_10 greedy**: scope globale + exit code non verificato~~ **RISOLTO** in
   BM-06. Resta lo stesso pattern "successo stampato comunque" in **mod_02** e
   **mod_mas**. → TRIGGER: primo intervento su quei moduli.
4b. **Il `return` dei moduli è inerte** (LOW, gate BM-06): il dispatcher di
   `brew_manager.sh` ignora i valori di ritorno e il core termina con `exit 0`
   incondizionato, quindi una run schedulata che fallisce riporta comunque
   successo a chi la monitora. Cambiare il contratto di exit tocca TUTTI i
   moduli. → TRIGGER: decisione utente (candidato a BM-08/BM-18 doctor).
5. **Tag esistenti lightweight** (v1.1.1, v1.1.2), il framework prevede tag
   annotati per /integrate e git describe. → TRIGGER: dal prossimo tag si usa
   `git tag -a` (i vecchi restano com'erano). Nota: `v1.1.2-baseline` è annotato
   ed è un tag HELPER, escluso dal `git describe` del tool (vedi BM-07).
5b. **VERSION e tag devono restare allineati**: `make version-check` fallisce se
   divergono. Alla release: aggiornare `VERSION` e taggare nello STESSO commit,
   e spostare `[Unreleased]` del CHANGELOG sotto la nuova versione.
   → TRIGGER: ogni release ([[2026-07-14-versione-fonte-unica]]).
6. ~~`_install_agent_multi` codice morto~~ **RIMOSSA** in BM-07 (108 righe). Gli
   schedule multi-giorno NON fanno round-trip: vengono SALTATI con warning
   (restore bk, re-register, migrazione, recreate) invece di degradare a
   daily/singolo giorno. → TRIGGER: se si vuole davvero la feature multi-giorno,
   va riscritta da zero (serve un writer multi-intervallo anche nel restore).
6b. La preview del restore agenti (bk) rispecchia lo skip dei modules invalidi ma
   NON quelli di label malformata e schedule multi-day (INFO, gate BM-05a): la
   preview elenca agenti che il restore reale salterebbe. → TRIGGER: prossimo
   intervento su mod_bk o BM-14 (viste report).
7. Secret scanning attivo solo sui commit nuovi (`gitleaks protect --staged`):
   la storia git preesistente non è mai stata scansionata. → TRIGGER: one-off
   `gitleaks detect` alla prima occasione utile (repo pubblico: basso rischio).
8. **YES_MODE auto-detect perso nel re-exec script(1)** (MEDIUM, security review
   BM-02, debito accettato): il processo esterno rileva stdin non-TTY e setta
   YES_MODE=1, ma il figlio sotto script(1) ri-parsa i flag con stdin=pty (→ TTY)
   e lo azzera. Run non-TTY SENZA --yes: le _ask leggono un pty a EOF → hang o
   skip silenzioso (fail-closed; con la conferma di BM-02 ora tocca anche mod_05).
   I LaunchAgent passano --yes espliciti: NON impattati. Fix candidato (1 riga in
   brew_manager.sh): `[[ ! -t 0 || "${BREW_MANAGER_YES:-0}" == 1 ]] && YES_MODE=1`.
   INTERAZIONE NUOVA (gate BM-04): con l'_ask per-app dell'adozione,
   `--adopt=all` SENZA --yes esplicito in non-TTY salta ogni adozione
   (fail-closed); il README (~riga 101, "without asking") va riallineato in
   BM-19. → TRIGGER: BM-08c (decisione utente confermata 2026-07-13).
9. ~~Flag CLI ignoti ignorati in silenzio~~ **RISOLTO** (micro-task 0e48373,
   2026-07-13): flag ignoti e lookalike Unicode → errore + exit 2. RESIDUI
   registrati dal gate (LOW, fail-safe): typo nei VALORI (`--upgrade=yes`
   degrada in silenzio a `n`) → validazione valori in BM-08b; plist legacy con
   `modules` corrotto (es. `--ye` dal mangling tr dell'integrity re-register,
   che storpia anche go→o) ora fallirebbe con exit 2 a ogni run schedulato →
   sanificare l'estrazione in mod_las (ambito BM-05a/integrity).
10. `_ask` mostra sempre "(y/N)" anche con default y, e "Runs only after
   confirmation" vale solo interattivamente (LOW, lib condivisa). → TRIGGER:
   UX conferme in BM-10/BM-16.
11. **Path /tmp fissi e prevedibili** (`/tmp/brew_*.log`, INFO gate BM-04):
   O_TRUNC segue i symlink — su Mac multi-utente un altro utente locale può
   pre-piazzare un symlink. Pre-esistente in più moduli. → TRIGGER: BM-07
   (refactor) o un pass di hardening dedicato: mktemp per-run.
- [[LEARNINGS]]: stato delle proposte IMP (aperte / applicate / rimandate) —
  vuoto alla nascita, le IMP del progetto partono da 001.

## Branch attivi
- **main** = integrazione + stabile (trunk-based); include innesto (7893f87) e
  BM-01 (3d3af76); tag `v1.1.2-baseline`.
- **docs/readme-reality** = BM-19 ristretto COMPLETO (7f7f90d), in attesa del
  merge via blocco /integrate (esegue l'utente).
- **origin/dev** = remoto dormiente, allineato a main al momento dell'innesto; non
  usare come integrazione (vedi [[2026-07-12-trunk-based-su-main]]).
