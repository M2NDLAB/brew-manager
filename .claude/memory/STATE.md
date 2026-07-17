---
type: state
updated: 2026-07-17
branch: main
tags: [state]
---
# STATE — brew-manager

> Aggiornato: 2026-07-17 | Ultimo: **BM-08c (M2, agenti attraverso il resolver + consenso fail-closed) COMPLETO su `fix/agent-selection` — gate adversariale + RE-gate PASSATI (CRITICAL introdotto e corretto; gemello bk chiuso), in attesa di integrazione. M2 CHIUSO** · BM-08b integrato (main `3ac3f63`) · v1.2.0 RILASCIATA | Indice: [[INDEX]]

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
  - [x] **M2 — resolver di selezione (BM-08a/b/c): CHIUSO.** Chiude Attenzione #1
    (CLI posizionali + plist scheduler), #8 (consenso) e #9 (grammatica agenti).
    - [x] **BM-08a** estrazione `_resolve_selection` (parità pura) — INTEGRATO in
      main (merge `f1e1029`). [[2026-07-17-selection-resolver-contract]].
    - [x] **BM-08b** dispatch posizionale + `--only`/`--skip` — INTEGRATO in main
      (merge `3ac3f63`). 2 MEDIUM fail-open del tokenizer fixati.
      → [[sessions/2026-07-17-bm08b-positional-dispatch]].
    - [x] **BM-08c** agenti attraverso il resolver + consenso fail-closed — branch
      `fix/agent-selection`, commit `7f4f218` (NON_INTERACTIVE≠consenso) +
      `cd110d4` (scheduler refuse) + `d1a5e2b` (bk refuse). 96 test (87 selection +
      9 guardrails). **Gate + RE-gate PASSATI**: il 1° fix #8 introdusse un
      **CRITICAL** (auto-conferma di cleanup distruttivo senza --yes) → branch
      resettato e rifatto col fix corretto (separare NON_INTERACTIVE da YES_MODE,
      [[2026-07-17-consent-vs-noninteractive]]); re-gate confermò corretto+completo
      salvo il gemello bk (fixato). In attesa di integrazione.
      → [[sessions/2026-07-17-bm08c-agent-selection]].

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
- Test: `tests/` (zsh puro, zero-dip, `make test`, **96 check** con anti-vacuità):
  `test_selection.zsh` (87) copre `_resolve_selection`/`_resolve_cli`/
  `_selection_is_valid`; `test_guardrails.zsh` (9) fissa l'invariante di consenso
  (`_ask`/`_read_choice` sotto NON_INTERACTIVE vs `--yes`). Resto del codice non
  coperto. Linter/formatter: ASSENTI (shellcheck/shfmt non installati; blocco
  formattazione predisposto ma commentato nell'hook). CI: assente.

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
1. ~~**CLI posizionale + plist scheduler**~~ **CHIUSO (M2, BM-08b+BM-08c)**: il
   dispatch posizionale esiste (BM-08b) e gli agenti lo instradano davvero via
   `_resolve_cli` (BM-08c) — un agente esegue la selezione salvata, non più `go`.
   Un valore invalido è RIFIUTATO all'install (non più fallback-`go`). Il rischio
   "non-TTY punta un modulo mutante" è neutralizzato da #8 (consenso): senza
   `--yes` ogni `_ask` è negata. → residuo: il README documenta la CLI posizionale
   (BM-08b) ma NON lo scheduling per-modulo come feature pubblicizzata — ok così.
2. ~~**Off-by-one zsh (array 1-based)**~~ **CHIUSO**: adozione mod_00 (BM-04, col
   canale di selezione morto su tutte le release), weekday in las/bk + selezione
   Modify/Remove dello scheduler (BM-05a), contatore mod_09 (BM-05b). La regola
   by-convention resta in CLAUDE.md per il codice nuovo.
3. **DRY_RUN non uniforme**: ~~mod_05~~ (risolto in BM-02), ~~restore bk
   [3]/[3b]~~ (risolto in BM-03); resta `brew install mas` non gated in
   mod_mas; e (gate BM-08c) `mod_02` esegue `brew update` INCONDIZIONATAMENTE — no
   `_ask`, non gated da `--dry-run`: gira anche con `2 --dry-run` e in non-TTY. È
   refresh di metadati (nessun install/rimozione/file utente), ma è comunque una
   mutazione fuori dal contratto DRY_RUN/consenso. → TRIGGER: primo intervento su
   mod_02 o mod_mas.
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
8. ~~**YES_MODE perso nel re-exec script(1)**~~ **CHIUSO (BM-08c)**, ma NON col fix
   "candidato" originale — che il gate ha bocciato come CRITICAL (avrebbe
   auto-confermato i default distruttivi senza --yes). Chiuso separando
   **NON_INTERACTIVE** (solo anti-blocco) da **YES_MODE** (solo --yes): una run
   non-TTY senza --yes ora NEGA ogni `_ask` (fail-closed, anche default `y`); un
   `BREW_MANAGER_YES` stale in env è sovrascritto. I LaunchAgent (--yes) eseguono
   la loro selezione. Decisione: [[2026-07-17-consent-vs-noninteractive]].
   INVARIANTE nuova: "non c'è tty" ≠ "consenso" — un modulo che muta SENZA passare
   per `_ask` NON è coperto (vedi #12 mod_02).
9. ~~Flag CLI ignoti ignorati in silenzio~~ **RISOLTO** (micro-task 0e48373).
   ~~plist legacy con `modules` corrotto → exit 2 a ogni run~~ **CHIUSO (BM-08c)**:
   `_install_agent` (scheduler) e `_restore_agents`/preview (bk) validano con
   `_selection_is_valid` e RIFIUTANO/SKIPPANO un valore invalido invece di
   installare (niente più `go`-fallback distruttivo né exit-2 inerte). RESIDUO
   ANCORA APERTO (LOW): typo nei VALORI dei flag (`--upgrade=yes` degrada in
   silenzio a `n`) — mai toccato (scope selezione, non valori), candidato a un
   task dedicato.
10. `_ask` mostra sempre "(y/N)" anche con default y, e "Runs only after
   confirmation" vale solo interattivamente (LOW, lib condivisa). → TRIGGER:
   UX conferme in BM-10/BM-16.
11. **Path /tmp fissi e prevedibili** (`/tmp/brew_*.log`, INFO gate BM-04):
   O_TRUNC segue i symlink — su Mac multi-utente un altro utente locale può
   pre-piazzare un symlink. Pre-esistente in più moduli. → TRIGGER: BM-07
   (refactor) o un pass di hardening dedicato: mktemp per-run.
12. **Re-register: divergenza conf/plist** (LOW, PRE-ESISTENTE, gate BM-08c): la
   re-register (mod_las) estrae i moduli con `grep -A1 brew_manager.sh | tail -1`
   → legge SOLO il primo `<string>` positionale. Un plist artefatto con due arg
   posizionali (`<string>3</string><string>5</string>`) è registrato nel conf come
   `modules=3` mentre l'agente esegue `3,5` (5=cleanup). Richiede un plist
   manipolato a mano (brew-manager ne genera sempre UNO). Il listato under-reporta;
   non cambia l'esecuzione. → TRIGGER: hardening re-register / BM-14 (viste report):
   estrarre TUTTI i `<string>` fino al primo `--flag`.
13. **Label injection sul path recreate** (LOW, PRE-ESISTENTE, gate BM-08c): il
   heredoc del plist interpola `${label}` RAW; sui path recreate/re-register il
   label viene da un filename/conf non fidato (solo il suffisso INTERATTIVO è
   validato `^[A-Za-z0-9._-]+$`). Un plist/conf manipolato con metacaratteri XML
   nel label potrebbe iniettare struttura. → TRIGGER: hardening mod_las — validare
   il label anche sui path non-interattivi (stessa forma del suffisso).
- [[LEARNINGS]]: IMP-001 APPLICATA; **IMP-002** (checklist superficie del
  contratto per i test), **IMP-003** (mai echo su dati) e **IMP-004** (chiudi la
  CLASSE: grep tutti i siti + verifica adversariale + re-gate) APERTE,
  propose-only, in attesa di decisione (retro periodica o su richiesta).

## Branch attivi
- **main** = integrazione + stabile (trunk-based); HEAD `3ac3f63` (BM-08a + BM-08b
  integrati), allineato a `origin/main`; tag `v1.2.0` (annotato) + `v1.1.2-baseline`.
  In `CHANGELOG [Unreleased]`: la CLI posizionale (BM-08b), da promuovere a v1.3.0
  alla prossima release.
- **fix/agent-selection** = BM-08c COMPLETO (commit `7f4f218` consenso + `cd110d4`
  scheduler + `d1a5e2b` bk + il commit di checkpoint), gate + re-gate passati. In
  attesa di merge dell'utente (blocco `/integrate`). **Chiude M2.**
- **feat/positional-dispatch** = BM-08b, MERGIATO in main (`3ac3f63`); il branch
  andava eliminato al merge (`git branch -d`).
- **origin/dev** = remoto dormiente, allineato a main al momento dell'innesto; non
  usare come integrazione (vedi [[2026-07-12-trunk-based-su-main]]).
