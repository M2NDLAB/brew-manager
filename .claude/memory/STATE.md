---
type: state
updated: 2026-07-12
branch: main
tags: [state]
---
# STATE — brew-manager

> Aggiornato: 2026-07-12 | Ultimo: **innesto del claude-code-framework v0.2.0 (brownfield)** | Indice: [[INDEX]]

## Stato avanzamento
- [x] Progetto maturo e rilasciato: v1.1.2 su `main` (TUI zsh per audit/cleanup di
  Homebrew, 14 moduli standard + 4 speciali, LaunchAgent scheduler, backup Brewfile).
- [x] Innesto del claude-code-framework v0.2.0 — branch `chore/innesto-framework`
  (questo checkpoint). Memoria inizializzata dall'assessment, non da template vuoto.
- [ ] Integrazione del branch di innesto in `main` (blocco /integrate: esegue l'utente) ← PROSSIMO
- [ ] Bonifica dei difetti noti emersi dall'assessment (vedi "Attenzione") — da
  pianificare come deliverable separati, ciascuno col suo branch.

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
2. **Off-by-one zsh (array 1-based)** in: adozione mod_00 (selezione "1" → elemento
   vuoto, "2" → prima app), weekday in las/bk (giorno shiftato di +1 al restore,
   sabato degrada a daily), contatore mod_09. → TRIGGER: primo intervento su uno
   di questi moduli; regola by-convention in CLAUDE.md per il codice nuovo.
3. **DRY_RUN non uniforme**: mod_05 lo ignora del tutto; restore bk [3]/[3b] e
   `brew install mas` non sono gated. → TRIGGER: qualunque modifica a un modulo
   mutante deve prima chiudere il gap del modulo toccato.
4. **mod_10 greedy**: conferma "N cask(s)" ma esegue `brew upgrade --greedy`
   globale; exit code non verificato (successo stampato comunque; stesso pattern in
   mod_02 e mas). → TRIGGER: primo intervento su mod_10.
5. **Tag esistenti lightweight** (v1.1.1, v1.1.2), il framework prevede tag
   annotati per /integrate e git describe. → TRIGGER: dal prossimo tag si usa
   `git tag -a` (i vecchi restano com'erano).
6. `_install_agent_multi` in mod_las è codice morto (mai richiamata dal menu);
   gli schedule multi-giorno non fanno round-trip nel restore bk. → TRIGGER:
   se si decide di cablare la feature multi-giorno.
7. Secret scanning attivo solo sui commit nuovi (`gitleaks protect --staged`):
   la storia git preesistente non è mai stata scansionata. → TRIGGER: one-off
   `gitleaks detect` alla prima occasione utile (repo pubblico: basso rischio).
- [[LEARNINGS]]: stato delle proposte IMP (aperte / applicate / rimandate) —
  vuoto alla nascita, le IMP del progetto partono da 001.

## Branch attivi
- **main** = integrazione + stabile (trunk-based).
- **chore/innesto-framework** = innesto del framework v0.2.0 — COMPLETO, in attesa
  del merge via blocco /integrate (esegue l'utente).
- **origin/dev** = remoto dormiente, allineato a main al momento dell'innesto; non
  usare come integrazione (vedi [[2026-07-12-trunk-based-su-main]]).
