---
type: state
updated: 2026-07-12
branch: main
tags: [state]
---
# STATE — brew-manager

> Aggiornato: 2026-07-13 | Ultimo: **BM-05a completo su fix/weekday-shift (gate in 2 round, 4 HIGH risolti)** | Indice: [[INDEX]]

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
  - [x] BM-05a fix weekday + migrazione plist legacy — branch `fix/weekday-shift`,
    commit c5c4539, gate PASSATO in 2 ROUND con 4 HIGH risolti (XML injection nei
    plist da bundle non fidato; collasso dei plist multi-intervallo; Modify che
    perdeva il conf; heredoc duplicato non validato in bk). In attesa di integrazione.
  - [ ] BM-05b fix contatore mod_09 ← PROSSIMO (dopo ok utente su BM-05a)

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
- README "Running from the command line": documenta argomenti CLI posizionali NON
  implementati (vedi Attenzione #1) — da riallineare quando si decide se
  implementare la feature o correggere la doc.
- README "Project structure": non cita `SECURITY.md` né i file del framework
  (CLAUDE.md, Makefile, scripts/, .claude/) — da aggiornare al primo ritocco del README.
- README "Adding a new module": promette invocabilità da CLI inesistente (stessa
  radice del punto 1).
- `BREW_MANAGER_VERSION="1.1.0"` nello script vs tag v1.1.2 — allineare la
  costante al prossimo release.

## Attenzione / problemi aperti
1. **Argomenti CLI posizionali non implementati** — il parser gestisce solo i flag;
   la selezione moduli è solo interattiva. AGGRAVANTE: i plist generati da
   `mod_las_scheduler` passano i moduli come argomenti → gli agenti schedulati li
   ignorano e in non-TTY degradano a `go --yes`, che include mod_05
   (autoremove+cleanup SENZA conferma). → TRIGGER: bloccante per qualunque lavoro
   su scheduler/CLI; da risolvere PRIMA di pubblicizzare gli agenti schedulati.
2. **Off-by-one zsh (array 1-based)**: ~~adozione mod_00~~ (BM-04, insieme al
   canale di selezione morto su tutte le release), ~~weekday in las/bk~~ +
   ~~selezione Modify/Remove nello scheduler~~ (BM-05a). Resta il contatore
   mod_09 (→ BM-05b). → TRIGGER: BM-05b; regola by-convention in CLAUDE.md.
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
4. **mod_10 greedy**: conferma "N cask(s)" ma esegue `brew upgrade --greedy`
   globale; exit code non verificato (successo stampato comunque; stesso pattern in
   mod_02 e mas). → TRIGGER: primo intervento su mod_10.
5. **Tag esistenti lightweight** (v1.1.1, v1.1.2), il framework prevede tag
   annotati per /integrate e git describe. → TRIGGER: dal prossimo tag si usa
   `git tag -a` (i vecchi restano com'erano).
6. `_install_agent_multi` in mod_las resta codice morto (mai richiamata dal menu),
   ma dopo BM-05a è allineata ai guard-rail. Gli schedule multi-giorno NON fanno
   round-trip: ora vengono SALTATI con warning (restore bk, re-register,
   migrazione, recreate) invece di degradare a daily/singolo giorno. → TRIGGER:
   se si decide di cablare davvero la feature multi-giorno (serve un writer
   multi-intervallo anche nel restore).
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
- **fix/weekday-shift** = BM-05a COMPLETO (c5c4539), gate passato in 2 round
  (4 HIGH risolti), in attesa del merge via blocco /integrate (esegue l'utente).
- **origin/dev** = remoto dormiente, allineato a main al momento dell'innesto; non
  usare come integrazione (vedi [[2026-07-12-trunk-based-su-main]]).
