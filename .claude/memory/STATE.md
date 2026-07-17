---
type: state
updated: 2026-07-17
branch: main
tags: [state]
---
# STATE — brew-manager

> Aggiornato: 2026-07-17 | Ultimo: **BM-08b (M2, dispatch posizionale + `--only`/`--skip`) COMPLETO su `feat/positional-dispatch` — gate adversariale PASSATO (2 MEDIUM fail-open fixati), in attesa di integrazione** · BM-08a integrato (main `f1e1029`) · v1.2.0 RILASCIATA | Indice: [[INDEX]]

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
  - [x] BM-19 RISTRETTO: INTEGRATO in main (merge 3e7b462).
  - [x] Release v1.2.0 **RILASCIATA** (2026-07-17): merge `c5dc3a5` in main, tag
    **annotato** `v1.2.0` (→ c5dc3a5) creato e pushato; `origin/main == main`, tag
    su origin; branch `chore/release-v1.2.0` eliminato; `make version-check` verde.
    Merge/tag/push eseguiti dall'utente.
  - [x] Via libera esplicita dell'utente al gate ⛔ pre-M2 (2026-07-17): M2 avviato.
  - [ ] M2 — resolver di selezione (BM-08a/b/c): la chiave di volta; chiude
    Attenzione #1 (CLI posizionali + plist scheduler) e #8 (YES_MODE).
    - [x] **BM-08a** estrazione `_resolve_selection` (parità pura) — **INTEGRATO
      in main** (merge `f1e1029`). Registry+resolver in `lib/selection.sh`; nasce
      il testing (`tests/test_selection.zsh`, `make test`). Contratto:
      [[2026-07-17-selection-resolver-contract]]. Gate adversariale passato.
    - [x] **BM-08b** dispatch posizionale + `--only`/`--skip` — branch
      `feat/positional-dispatch`, commit `1e7e735` (API stretta) + `2e34c25`
      (wiring+README) + `7096d8a` (fix gate). `./brew_manager.sh 0,4,5` esegue
      non-interattivamente; token ignoto → exit 2; menu interattivo invariato.
      74 test. **Gate adversariale PASSATO**: injection/parità/guard-rail puliti;
      **2 MEDIUM fail-open del tokenizer** (escape `\065`→mod_05; virgole vuote →
      errore vuoto) **fixati** (`${(@s:,:)}`/`${// /}`/skip-empty), + 3 LOW
      (newline, doc/code, test) risolti. In attesa di integrazione. Chiude la
      parte CLI di Attenzione #1. → [[sessions/2026-07-17-bm08b-positional-dispatch]].
    - [ ] **BM-08c** agenti las attraverso `_resolve_cli` — chiude Attenzione #8
      e la parte scheduler di #1.

## Cosa esiste adesso
- Albero directory: vedi [[TREE]].
- `brew_manager.sh` — entry point TUI, stabile; dispatch, parsing flag, recording
  sessione via script(1). Selezione da CLI (posizionale + `--only`/`--skip`,
  BM-08b) o dal menu interattivo. Vedi [[core-brew-manager]].
- `lib/common.sh` + `lib/log.sh` — infrastruttura TUI e guard-rail condivisi
  (`_ask`, `_read_choice`, YES_MODE, DRY_RUN). Vedi [[lib-common]].
- `lib/selection.sh` (BM-08a/b) — registry `MODULE_DESC`/`MODULE_IDS` +
  `_resolve_selection` (lenient) + `_resolve_cli`/`_collect_module_tokens`
  (stretto, per la CLI); infrastruttura di dispatch condivisa (sensibile). Vedi
  [[lib-selection]].
- 14 moduli standard `mod_00`–`mod_13` (sequenza `go`) + 4 speciali `bk`/`las`/
  `log`/`mas` (per nome). 9 moduli read-only; mutanti: 00, 02, 04, 05, 10, bk,
  las, log, mas. Note dei sensibili: [[mod-00-audit]], [[mod-05-cleanup]],
  [[mod-bk-brewfile]], [[mod-las-scheduler]].
- Framework di processo `.claude/` (docs, commands, memoria), CLAUDE.md, Makefile,
  hook git (gitleaks + commitlint), CHANGELOG.md. Vedi
  [[sessions/2026-07-11-innesto-note]].
- Test: `tests/test_selection.zsh` (zsh puro, zero-dip, `make test`, **74 check**
  con anti-vacuità) copre `_resolve_selection` + `_resolve_cli` + l'hardening del
  gate. Resto del codice ancora non coperto. Linter/formatter: ASSENTI (shellcheck/shfmt
  non installati; blocco formattazione predisposto ma commentato nell'hook). CI: assente.

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
  rimosse) → parte residua di BM-19. Nota: **BM-08a NON tocca il README** — è un
  refactor a parità pura, comportamento utente invariato; il debito CLI si salda in
  **BM-08b** (quando il posizionale esisterà davvero).
- README "Project structure": non cita `SECURITY.md` né i file del framework
  (CLAUDE.md, Makefile, scripts/, .claude/) — da aggiornare al primo ritocco del README.
- README "Adding a new module": promette invocabilità da CLI inesistente (stessa
  radice del punto 1).
- ~~`BREW_MANAGER_VERSION="1.1.0"` vs tag v1.1.2~~ **RISOLTO** in BM-07 (file
  VERSION + `make version-check`).

## Attenzione / problemi aperti
1. **CLI posizionale: PARTE CLI CHIUSA (BM-08b), parte SCHEDULER aperta** — il
   dispatch posizionale ora esiste (`./brew_manager.sh 0,4,5`, `--only`/`--skip`,
   stretto). RESTA APERTO: i plist di `mod_las_scheduler` passano i moduli come
   argomenti ma NON sono ancora instradati per `_resolve_cli`; un agente in non-TTY
   degrada ancora a `go --yes` (include mod_05 autoremove+cleanup SENZA conferma).
   NUOVO (gate BM-08b, INFO): il posizionale permette anche a un caller non-TTY di
   puntare un singolo modulo mutante (es. `./brew_manager.sh 5`), che eredita
   `YES_MODE=1` auto (vedi #8) — reach ampliato di un debito già noto, non un
   bypass nuovo. → TRIGGER: **BM-08c** (instradare gli agenti + chiudere #8),
   PRIMA di pubblicizzare gli agenti schedulati.
2. ~~**Off-by-one zsh (array 1-based)**~~ **CHIUSO**: adozione mod_00 (BM-04, col
   canale di selezione morto su tutte le release), weekday in las/bk + selezione
   Modify/Remove dello scheduler (BM-05a), contatore mod_09 (BM-05b). La regola
   by-convention resta in CLAUDE.md per il codice nuovo.
3. **DRY_RUN non uniforme**: ~~mod_05~~ (risolto in BM-02), ~~restore bk
   [3]/[3b]~~ (risolto in BM-03); resta `brew install mas` non gated in
   mod_mas. → TRIGGER: qualunque modifica a mod_mas deve prima chiudere il gap.
3b. **Echo intermedio sui dati espande gli escape** (LOW, gate BM-03): l'echo
   builtin zsh converte `\e`/`\0NN`/`\x..`. Istanza nel resolver **CHIUSA in
   BM-08b** (era un bypass MEDIUM: `\065`→mod_05; ora `${(@s:,:)}`/`${// /}`).
   RESTANO: mod_05 (dry-run BM-02) e `_restore_agents` passano i dati per echo
   prima del printf %s. La regola generale è proposta in [[LEARNINGS]] IMP-003
   (mai echo su dati). → TRIGGER: primo intervento su mod_05 o mod_bk (o micro-fix
   dedicato). NB: anche il display di `_err` usa `echo -e` (rende gli escape nei
   messaggi che interpolano dati — cosmetico, path già sicuro).
4. ~~**mod_10 greedy**: scope globale + exit code non verificato~~ **RISOLTO** in
   BM-06. Resta lo stesso pattern "successo stampato comunque" in **mod_02** e
   **mod_mas**. → TRIGGER: primo intervento su quei moduli.
4b. **Il `return` dei moduli è inerte** (LOW, gate BM-06): il dispatcher di
   `brew_manager.sh` ignora i valori di ritorno e il core termina con `exit 0`
   incondizionato, quindi una run schedulata che fallisce riporta comunque
   successo a chi la monitora. Cambiare il contratto di exit tocca TUTTI i
   moduli. → TRIGGER: decisione utente (candidato a BM-08/BM-18 doctor).
5. ~~**Tag esistenti lightweight**~~ **CONVENZIONE IN VIGORE da v1.2.0**: `v1.2.0`
   è il primo tag di release **annotato** (i legacy v1.1.1/v1.1.2 restano
   lightweight, com'erano). Ogni release futura usa `git tag -a`. Nota:
   `v1.1.2-baseline` è annotato ed è un tag HELPER, escluso dal `git describe` del
   tool (vedi BM-07).
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
   BM-19. AMPLIAMENTO (gate BM-08b, INFO): il posizionale ora permette a un
   caller non-TTY di puntare un SINGOLO modulo mutante (`./brew_manager.sh 5`),
   che eredita lo stesso YES auto — reach più ampio, stesso fix. → TRIGGER:
   BM-08c (decisione utente confermata 2026-07-13).
9. ~~Flag CLI ignoti ignorati in silenzio~~ **RISOLTO** (micro-task 0e48373,
   2026-07-13): flag ignoti e lookalike Unicode → errore + exit 2. RESIDUI
   ANCORA APERTI (LOW, fail-safe): typo nei VALORI (`--upgrade=yes` degrada in
   silenzio a `n`) — BM-08b NON l'ha toccato (scope: selezione, non valori dei
   flag), resta candidato a un task dedicato; plist legacy con `modules` corrotto
   (es. `--ye` dal mangling tr dell'integrity re-register, che storpia anche
   go→o) ora fallirebbe con exit 2 a ogni run schedulato → sanificare l'estrazione
   in mod_las (ambito BM-08c / integrity). NB: i token della SELEZIONE sono ora
   induriti (escape/newline, BM-08b), ma la sanificazione dell'estrazione da
   plist resta a monte, in mod_las.
10. `_ask` mostra sempre "(y/N)" anche con default y, e "Runs only after
   confirmation" vale solo interattivamente (LOW, lib condivisa). → TRIGGER:
   UX conferme in BM-10/BM-16.
11. **Path /tmp fissi e prevedibili** (`/tmp/brew_*.log`, INFO gate BM-04):
   O_TRUNC segue i symlink — su Mac multi-utente un altro utente locale può
   pre-piazzare un symlink. Pre-esistente in più moduli. → TRIGGER: BM-07
   (refactor) o un pass di hardening dedicato: mktemp per-run.
- [[LEARNINGS]]: IMP-001 APPLICATA; **IMP-002** (checklist superficie del
  contratto per i test) e **IMP-003** (convenzione: mai echo su dati) APERTE,
  propose-only, in attesa di decisione (retro periodica o su richiesta).

## Branch attivi
- **main** = integrazione + stabile (trunk-based); HEAD `f1e1029` (BM-08a
  integrato), allineato a `origin/main`; tag `v1.2.0` (annotato) + `v1.1.2-baseline`.
- **feat/positional-dispatch** = BM-08b COMPLETO (commit `1e7e735` + `2e34c25` +
  `7096d8a` fix gate + il commit di checkpoint), gate passato. In attesa di merge
  dell'utente (blocco `/integrate`).
- **refactor/selection-resolver** = BM-08a, MERGIATO in main (`f1e1029`); il branch
  andava eliminato al merge (`git branch -d`).
- **chore/memory-reconcile-v1.2.0** = superato dal checkpoint di BM-08a, da
  scartare se ancora presente (`git branch -D`).
- **origin/dev** = remoto dormiente, allineato a main al momento dell'innesto; non
  usare come integrazione (vedi [[2026-07-12-trunk-based-su-main]]).
