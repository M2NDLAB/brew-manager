---
type: state
updated: 2026-07-21
branch: fix/dryrun-mod02-mas
tags: [state]
---
# STATE — brew-manager

> Aggiornato: 2026-07-21 | Ultimo: **micro-task `--dry-run` mod_02 + mas** (strada B, deciso dall'utente dopo l'integrazione di BM-12) su `fix/dryrun-mod02-mas`, 8 commit sopra main `21c956b`. I due gate richiesti sono fatti (`brew update` e `brew install mas` non girano più in dry-run; il gate precede sempre la conferma, quindi `--dry-run` batte `--yes`). **Il gate adversariale a 2 lenti ha però REFUTATO l'affermazione che il branch aveva aggiunto**: portando `MODULE_DRYRUN` tutto a 1 il branch ATTESTAVA come verificati 4 difetti pre-esistenti — auto-update implicito di Homebrew (HIGH, mod_04/10/bk), `brew bundle check` in `bk [4]` (MEDIUM), `rm -f` in `las [c]` (MEDIUM), `mkdir` ungated (LOW). **Decisione utente: via di mezzo** → `HOMEBREW_NO_AUTO_UPDATE=1` sotto dry-run (una riga, chiude l'HIGH per tutti i moduli) + `[bk]=0`/`[las]=0` dichiarati onestamente + allow-list al posto dell'invariante tautologica + README ristretto al vero. **268 test verdi**. **In attesa di integrazione** (bump PATCH). Prima: **M3 COMPLETA**, BM-12 integrato in main (merge `21c956b`); v1.4.0 non ancora rilasciata. | Indice: [[INDEX]]

> **Storico precedente**: BM-12 — spinner + summary di sessione (M3, 4° e ultimo task), 5 commit su `feat/progress-summary`: mockup PRIMA del codice → decisione utente **summary variante B completa + spinner sui soli siti già cablati**; `_spinner` gata su `TUI_TTY` (era morto-in-pratica su RECORDING) e propaga l'rc del figlio; renderer puri + summary con righe di esito per POSIZIONE, stat, delta disco, footer identità. **Gate adversariale (2 lenti): comportamento PULITO ma 4 difetti di VERITÀ trovati e FIXATI** — il summary attestava "preview, nothing changed" per moduli senza gate --dry-run (mod_02/mas) → nuovo registry `MODULE_DRYRUN` + `_run_status` puro + stato `⚠ ran anyway`; lo spinner inondava il log (strip ora a semantica CR + guardia di non-vuoto); secondi sotto-riportati; riga disco che poteva mentire → ri-misura al rendering. **248 test verdi**. **M3 COMPLETA** (BM-09→BM-12), INTEGRATA in main (merge `21c956b`); **release v1.4.0** non ancora fatta.

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
  - [x] BM-07 versione a fonte unica + codice morto — INTEGRATO in main
    (commit 3a35309 in main, verificato 2026-07-18; la voce era stale).
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
      salvo il gemello bk (fixato). INTEGRATO in main (merge `b929a23`,
      branch eliminato). → [[sessions/2026-07-17-bm08c-agent-selection]].
  - [x] Upgrade framework v0.2.0 → v0.5.1: INTEGRATO in main (merge `45bf4bc`,
    branch eliminato). → [[sessions/2026-07-17-framework-upgrade-v0.2-to-v0.5.1]].
  - [x] **README ↔ realtà di v1.3.0** (2026-07-18, task 1 pre-release): scheduler
    per-modulo e invariante fail-closed documentati, 2 claim corretti perché
    smentiti dalla verifica dal vivo (exit del parent, default `y` di mod_05 sotto
    `--yes`). INTEGRATO in main (merge `56cf64d`).
    → [[sessions/2026-07-18-readme-v1.3.0]].
  - [x] **Micro-task exit-code propagation** (2026-07-18, inserito dall'utente
    pre-release): il parent propaga l'rc del figlio attraverso script(1)
    (`_run_rc` prima della strip ANSI) — `99`→2, selezione vuota→1, segnale→
    numero grezzo; strip fallita = WARNING, rc invariato. Scope deciso
    dall'utente: SOLO metà parent di #4b (la metà moduli → BM-18). Gate
    adversariale passato (0 C/H/M; 2 LOW + 4 INFO applicati). Test end-to-end
    nuovi (102 totali). README: claim non-zero RIPRISTINATO (ora vero). Branch
    `fix/exit-code-propagation` (4cef18c+a6d1be9+a3a4ad1), in attesa di
    integrazione. → [[sessions/2026-07-18-exit-code-propagation]].
  - [x] Micro-task exit-code: INTEGRATO in main (merge `1fa521a`, branch
    eliminato).
  - [x] **Release v1.3.0 RILASCIATA** (2026-07-18): merge `c6c80c0` in main,
    tag **annotato** `v1.3.0` (→ c6c80c0) creato e pushato; `main ==
    origin/main`; branch `chore/release-v1.3.0` eliminato; `make
    version-check` verde. Bump MINOR (feat BM-08b nel set); verificata da
    clone pulito prima del rilascio (version-check + 102 test + `--version`).
    Merge/tag/push eseguiti dall'utente.
    → [[sessions/2026-07-18-release-v1.3.0]].
  - [x] **M3 — TUI bella + funzionale (BM-09…BM-12): COMPLETA e INTEGRATA in main**
    (BM-12 mergiato in `21c956b`); resta da fare la release v1.4.0, che
    impacchetterà i quattro task.
    - [x] **BM-09** fondazione TUI in `lib/common.sh` — branch
      `feat/tui-foundation` (feat `bab07d0` + fix `b2d7b62` + docs `910d551`).
      Rendering capability-aware (detection colore/Unicode, handoff parent→child
      come NON_INTERACTIVE, palette semantica, degradazione a ASCII puro alla
      fonte, primitivi `_box`/`_repeat`/`_pad`/`_clear`); 0 moduli modificati;
      escape grezzi → palette (NO_COLOR pulito ovunque). Guard-rail
      byte-identici. **Gate adversariale PASSATO** (6 lenti + verifica
      per-finding): 1 LOW fixato (precedenza `LC_ALL` in `_tui_unicode`) + 1
      hardening (echo-on-data in `_box`, IMP-003), 5 refutati; consent-invariance
      e correctness-regression puliti. `tests/test_capabilities.zsh` (30 check,
      e2e "pipato = zero ANSI"); suite 132 verde. **INTEGRATO in main** (merge
      `5867137`, branch `feat/tui-foundation` eliminato).
      → [[sessions/2026-07-19-bm09-tui-foundation]].
    - [x] **BM-10** badge di rischio `[RO]`/`[W]`/`[!]` + cornici di conferma
      distruttiva — branch `feat/risk-badges` (6 commit: `985ffd4` piano +
      `bb520a9`+`60a1969`+`03a4f33`+`5b52e02`+`baaf11b`). `MODULE_RISK` (single
      source of truth, classificazione verificata adversarialmente: raise=0) +
      `_risk_badge`/`_risk_caption`/`_about_risk` (renderer puri, palette BM-09) +
      `_ask_danger` (box `C_DANGER` → `_ask` INTATTO, consenso byte-identico). Badge
      nel menu (+legenda) e nei 18 About; 9 cornici distruttive (00/04/05/10/bk×3/
      mas×2); `las` escluso (nessun `_ask` — flusso a menu; sarebbe cambio di
      consenso). `mod_00`=`[!]` (adotta), non `[RO]` del mockup. Presentazione pura,
      contratto pubblico intatto. **Gate adversariale PASSATO** (5 lenti, 0 finding).
      33+5 test → 170 verdi. **INTEGRATO in main** (merge `2dd1f7c`, branch
      eliminato). → [[sessions/2026-07-20-bm10-risk-badges]].
    - [x] **BM-11** banner + redesign menu — branch `feat/menu-redesign` (3 commit:
      `597281e` registry `MODULE_NAME`+test, `27acf1e` banner+menu, `6b7df8b`
      README). Mockup a 2 varianti proposti PRIMA del codice (richiesta utente) →
      decisione: **flat + footer 3 righe**. Card `badge(4)·id(3)·nome(17)·
      desc(≤46)` ≤78 col, cap pinnati da `tests/test_menu_registry.zsh` (8 check);
      `_header_main` rimossa da common.sh (solo-rimozione). Presentazione pura,
      contratto intatto. **Gate PASSATO** (0 finding). **178 test verdi**.
      **In attesa di integrazione** (bump MINOR).
      → [[sessions/2026-07-20-bm11-menu-redesign]].
    - [x] **BM-12** spinner + summary di sessione — branch `feat/progress-summary`
      (5 commit: `5968904` spinner+renderer, `7adcc20` cablaggio summary,
      `d84b651`+`73f905c` README, `13dc359` fix del gate). Mockup prima del codice
      → decisione utente: **summary variante B (completa) + spinner sui soli 2
      siti già cablati** (mod_01/mod_02). `_spinner` gata su `TUI_TTY` — era
      **morto in pratica** su RECORDING (la TUI gira sempre sotto script(1)) —
      con frame Unicode/ASCII, secondi da `$SECONDS` e rc del figlio propagato;
      summary con righe di esito per POSIZIONE (ripetizioni ok), stat, riga disco
      e footer. **Gate adversariale a 2 lenti: comportamento pulito, ma 4 difetti
      di VERITÀ** (vedi Attenzione #14) tutti FIXATI in `13dc359`; test 42→70
      (**suite 248** — la vecchia voce «247» era imprecisa di 1, misurato su main
      il 2026-07-21). **INTEGRATO in main** (merge `21c956b`, branch eliminato).
      → [[sessions/2026-07-21-bm12-progress-summary]].
  - [x] **Micro-task `--dry-run` mod_02 + mas** (2026-07-21, fuori roadmap,
    strada B decisa dall'utente dopo l'integrazione di BM-12): branch
    `fix/dryrun-mod02-mas`, 8 commit. `brew update` (mod_02) e `brew install mas`
    ora gatati — il gate precede esecuzione E conferma, quindi `--dry-run` batte
    `--yes`; preview con tabella repository + età della cache API. **Gate
    adversariale a 2 lenti: 0 finding sul codice nuovo, ma l'AFFERMAZIONE globale
    del branch REFUTATA** (4 difetti pre-esistenti che il branch attestava come
    verificati → Attenzione #3, #14, #15, #16). Via di mezzo decisa dall'utente:
    `HOMEBREW_NO_AUTO_UPDATE=1` sotto dry-run (una riga, chiude l'HIGH ovunque) +
    `[bk]`/`[las]` dichiarati 0 + allow-list al posto dell'invariante tautologica
    + README ristretto al vero. Nuovo `tests/test_dryrun_gates.zsh` (18 check:
    tripwire su mock brew con controlli "denti" in wet, e2e dell'auto-update
    attraverso `script(1)`); **suite 268**. **In attesa di integrazione**
    (bump PATCH). → [[sessions/2026-07-21-dryrun-mod02-mas]].
- [x] **Upgrade framework v0.5.1 → v1.0.0** (2026-07-19, fuori roadmap, solo
  processo): procedura SETUP formale, attraversa la 1.0. 4 file riconciliati (docs/04,
  lint-memory, CLAUDE.md, scripts/README) + retrofit del pin; contratto pubblico di brew
  compilato in docs/04 (moduli CONGELATI, decisione utente); invariante memoria VUOTA;
  132 test verdi. **INTEGRATO in main** (merge `126bc7d`, pushato; bump "nessun tag").
  → [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]].

## Cosa esiste adesso
- Albero directory: vedi [[TREE]].
- `brew_manager.sh` — entry point TUI, stabile; dispatch, parsing flag, recording
  sessione via script(1). Selezione da CLI (posizionale + `--only`/`--skip`,
  BM-08b) o dal menu interattivo. Dal **BM-11** banner flat (brand line
  right-aligned, Unicode-gated) e menu a card allineate con helper LOCALI
  `_menu_row`/`_menu_section`; summary con `MODULE_NAME`; help del menu compresso
  in footer 3 righe. Dal **BM-12** il dispatch traccia stato+durata per POSIZIONE
  (`RUN_STATUS`/`RUN_SECS`) e il summary di fine sessione rende righe di esito,
  stat, delta disco e footer identità. Dal **micro-task dry-run** (2026-07-21)
  esporta `HOMEBREW_NO_AUTO_UPDATE=1` SOLO sotto `--dry-run` (riga 152): senza,
  brew rieseguiva `brew update` da sé prima di `outdated`/`upgrade`/`bundle` e
  una preview riscriveva comunque l'indice. Vedi [[core-brew-manager]].
- `lib/common.sh` + `lib/log.sh` — infrastruttura TUI e guard-rail condivisi
  (`_ask`, `_read_choice`, YES_MODE, DRY_RUN). Dal **BM-09** rendering
  capability-aware: detection colore/Unicode + handoff `TUI_{LEVEL,UNICODE,TTY}`,
  palette semantica (degrada a ASCII puro su pipe/NO_COLOR), primitivi
  `_box`/`_clear`. Dal **BM-10** i renderer di rischio `_risk_badge`/`_risk_caption`
  (puri) e `_ask_danger` (box `C_DANGER` → `_ask` INTATTO — presentazione, consenso
  invariato). Dal **BM-11** `_header_main` RIMOSSA (orfana dopo il banner flat del
  core — igiene codice morto). Dal **BM-12** `_spinner` gata su `TUI_TTY` (era
  morto-in-pratica su RECORDING) e ritorna l'rc del figlio, più i renderer del
  summary `_run_glyph`/`_fmt_secs`/`_fmt_kb`/`_fmt_kb_or_na`/`_du_kb` (puri;
  `_du_kb` valida al bordo e ritorna VUOTO, mai 0). Vedi [[lib-common]].
- `lib/selection.sh` (BM-08a/b) — registry `MODULE_DESC`/`MODULE_IDS` +
  `_resolve_selection` (lenient) + `_resolve_cli`/`_collect_module_tokens`
  (stretto, per la CLI); infrastruttura di dispatch condivisa (sensibile). Dal
  **BM-10** anche `MODULE_RISK` (id→ro/write/danger, single source of truth del
  badge, presentazione — NON alimenta il resolver) + `_about_risk`. Dal **BM-11**
  `MODULE_NAME` (nome breve da menu, presentation-only) e testi `MODULE_DESC` da
  sottotitolo (≤46 col ASCII; le CHIAVI restano il contratto congelato). Dal
  **BM-12** `MODULE_DRYRUN` (id→1 se una run `--dry-run` non cambia NULLA
  eseguendo il modulo): dal micro-task 2026-07-21 `[2]`/`[mas]` sono 1 (gate
  dimostrato) e `[bk]`/`[las]` 0 (dichiarati onestamente, #15/#16). Vedi
  [[lib-selection]].
- 14 moduli standard `mod_00`–`mod_13` (sequenza `go`) + 4 speciali `bk`/`las`/
  `log`/`mas` (per nome). 9 moduli read-only; mutanti: 00, 02, 04, 05, 10, bk,
  las, log, mas. Note dei sensibili: [[mod-00-audit]], [[mod-05-cleanup]],
  [[mod-bk-brewfile]], [[mod-las-scheduler]].
- Framework di processo `.claude/` (docs, commands, memoria), CLAUDE.md, Makefile,
  hook git (gitleaks + commitlint), CHANGELOG.md. **Metodo aggiornato a framework
  v1.0.0** (da v0.5.1): `docs/04` con il criterio del MAJOR + il **contratto pubblico
  di brew-manager** (flag/selezione/exit-code/plist + **moduli congelati**),
  `/lint-memory` +controllo 11 "inventari vs realtà", `make test-scripts` nei Comandi
  rapidi. Provenance pin `.claude/framework-version` (retrofit, FUORI da memory/, baseline
  certa dei prossimi upgrade). Storia: [[sessions/2026-07-11-innesto-note]] (innesto
  v0.2.0), [[sessions/2026-07-17-framework-upgrade-v0.2-to-v0.5.1]] (→v0.5.1),
  [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]] (→v1.0.0).
- Test: `tests/` (zsh puro, zero-dip, `make test`, **268 check** con anti-vacuità):
  `test_selection.zsh` (87) copre `_resolve_selection`/`_resolve_cli`/
  `_selection_is_valid`; `test_guardrails.zsh` (9) fissa l'invariante di consenso
  (`_ask`/`_read_choice` sotto NON_INTERACTIVE vs `--yes`);
  `test_exit_codes.zsh` (6) fissa l'exit end-to-end del binario reale (sandbox
  symlink-farm + mock brew con tripwire); `test_capabilities.zsh` (30, BM-09) fissa
  detection colore/Unicode, ladder di degradazione, purezza ASCII fallback e l'e2e
  "pipato = zero ANSI" via il vero re-exec `script(1)`; `test_risk_badges.zsh` (38,
  BM-10) fissa la completezza di `MODULE_RISK` vs `MODULE_DESC`, la classificazione,
  la degradazione L0/larghezza del badge e l'**invarianza del consenso** di
  `_ask_danger` (== `_ask` sotto --yes/non-interactive); `test_menu_registry.zsh`
  (8, BM-11) fissa il layout 80-col del menu come invariante di DATI (lockstep
  `MODULE_NAME`↔`MODULE_DESC`, cap 17/46 colonne, ASCII-only, chiavi congelate);
  `test_run_summary.zsh` (72, BM-12 + micro-task dry-run) fissa lo spinner gated su
  `TUI_TTY` (non-TTY: zero `\r`/ANSI + riga statica) con **rc del figlio
  preservato**, i formatter/glifi puri, l'**invariante di wiring**
  `DU_AFTER`↔twin KB sul sorgente di mod_05, e la coerenza di `MODULE_DRYRUN`
  (grep del gate nel sorgente + **allow-list bidirezionale** `_KNOWN_UNGATED`:
  un `0` fuori lista fallisce, una voce stantia pure — vedi IMP-009);
  `test_dryrun_gates.zsh` (18, micro-task 2026-07-21) esegue mod_02 e mas contro
  un **mock brew con tripwire** e prova che in dry-run i comandi mutanti non sono
  invocati, con i controlli "denti" in wet (per mas: stesso `y` su stdin,
  `--dry-run` unica variabile), più l'e2e che `HOMEBREW_NO_AUTO_UPDATE` raggiunge
  davvero brew **attraverso il re-exec di `script(1)`**.
  Resto del codice non coperto. Linter/formatter: ASSENTI (shellcheck/shfmt non installati; blocco
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
- **Contratto pubblico di brew-manager** (criterio del MAJOR, in `docs/04`, deciso
  all'upgrade framework v1.0.0): flag CLI, grammatica di selezione, exit-code `0/1/2`,
  formato plist/LaunchAgent, e **identificatori di modulo CONGELATI** (numeri `0–13`/`go`/
  nomi speciali `bk/las/log/mas` — rinumerare/riassegnare/rinominare = MAJOR, nuovi moduli
  solo in append). Motivo: i numeri sono persistiti nei plist LaunchAgent sui Mac utenti
  (#12). L'exit-code runtime dei moduli (#4b) è FUORI dal contratto, in ingresso additivo
  con BM-18. → [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]].

## Debito documentazione
- ~~README vs realtà di v1.2.0~~ **SALDATO** in BM-19 ristretto (7f7f90d): rimossi
  gli over-claim (CLI posizionale, scheduling per-modulo, esempi `./brew_manager.sh
  bk`), aggiornati i comportamenti (adozione, cleanup, restore, greedy, integrity),
  documentati `--version`/`-V` e SECURITY.md/VERSION/CHANGELOG.
- ~~Residuo BM-19: README da riaggiornare quando M2 avrebbe implementato CLI e
  scheduling per-modulo~~ **SALDATO** (2026-07-18, `docs/readme-v1.3.0` 9ceb69b):
  scheduling per-modulo documentato come reale (callout las riscritto), invariante
  fail-closed documentata, validazione restore agenti in bk. La CLI posizionale
  era già documentata da BM-19+BM-08b. → [[sessions/2026-07-18-readme-v1.3.0]].
- ~~README "Project structure": non cita SECURITY.md né i file del framework~~ e
  ~~"Adding a new module": promette CLI inesistente~~ — **voci STALE, già a posto**
  (verificato 2026-07-18 sul file reale: SECURITY.md e il tooling sono citati;
  la sezione moduli descrive il resolver reale). Chiuse.
- ~~`BREW_MANAGER_VERSION="1.1.0"` vs tag v1.1.2~~ **RISOLTO** in BM-07 (file
  VERSION + `make version-check`).

## Attenzione / problemi aperti
1. ~~**CLI posizionale + plist scheduler**~~ **CHIUSO (M2, BM-08b+BM-08c)**: il
   dispatch posizionale esiste (BM-08b) e gli agenti lo instradano davvero via
   `_resolve_cli` (BM-08c) — un agente esegue la selezione salvata, non più `go`.
   Un valore invalido è RIFIUTATO all'install (non più fallback-`go`). Il rischio
   "non-TTY punta un modulo mutante" è neutralizzato da #8 (consenso): senza
   `--yes` ogni `_ask` è negata. → residuo README SALDATO (2026-07-18,
   `docs/readme-v1.3.0`): anche lo scheduling per-modulo è ora documentato come
   reale, con l'invariante di consenso. Nessun residuo.
2. ~~**Off-by-one zsh (array 1-based)**~~ **CHIUSO**: adozione mod_00 (BM-04, col
   canale di selezione morto su tutte le release), weekday in las/bk + selezione
   Modify/Remove dello scheduler (BM-05a), contatore mod_09 (BM-05b). La regola
   by-convention resta in CLAUDE.md per il codice nuovo.
3. **DRY_RUN non uniforme**: ~~mod_05~~ (BM-02), ~~restore bk [3]/[3b]~~ (BM-03),
   ~~`brew install mas`~~ e ~~`brew update` incondizionato in mod_02~~ **CHIUSI**
   dal micro-task 2026-07-21 (`fix/dryrun-mod02-mas`): entrambi i comandi sono
   dietro il gate, che precede esecuzione E conferma (`--dry-run` batte `--yes`),
   dimostrato da `tests/test_dryrun_gates.zsh` con tripwire su mock brew.
   Chiuso anche l'**auto-update implicito di Homebrew** (era il difetto più
   diffuso, trovato dal gate: `brew` esegue `brew update --auto-update` da sé
   prima di `install|outdated|upgrade|bundle|release`, e il `--dry-run` DI BREW
   non lo ferma) → `HOMEBREW_NO_AUTO_UPDATE=1` esportato solo sotto `--dry-run`
   in `brew_manager.sh:152`, verificato end-to-end attraverso il re-exec di
   `script(1)`. RESIDUI APERTI, entrambi dichiarati onestamente nel registry:
   vedi #15 (mod_bk `[4]`) e #16 (mod_las `[c]` + `mkdir`).
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
4b. **Il `return` dei moduli è inerte** (LOW, gate BM-06) — ora SOLO metà aperta:
   ~~il PARENT perde l'exit del figlio nella strip ANSI (misurato 2026-07-18:
   `99` → exit 0)~~ **CHIUSA** dal micro-task exit-code (2026-07-18, scope
   deciso dall'utente): `_run_rc` catturato dopo `script(1)` e propagato —
   selezione invalida→2, vuota→1, segnale→numero grezzo, contratto fissato da
   `tests/test_exit_codes.zsh` e documentato nel README. RESTA APERTA la metà
   MODULI: il dispatcher ignora i return e il core esce 0 anche se un modulo
   fallisce a runtime; i return odierni sono RUMORE (mod_02 ritorna 1 su run
   sane, campionato 2026-07-18) → serve un contratto di return su TUTTI i 18
   moduli. → TRIGGER: decisione utente (candidato BM-18 doctor). Nota
   idiosincrasia documentata: Ctrl+C → exit 2 (numero segnale grezzo di
   script(1) macOS), indistinguibile da "unknown token" per un caller.
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
   BM-16 (conferme a tier; BM-10 e BM-11 chiusi SENZA toccare `_ask`, per scelta
   di scope: presentazione intorno al prompt, mai il prompt).
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
14. **`MODULE_DRYRUN` è la lista dei moduli che NON rispettano `--dry-run`**
   (BM-12). ~~`[2]=0` e `[mas]=0`~~ **CHIUSI** (micro-task 2026-07-21: entrambi
   ora `1`, gate dimostrato). Al loro posto `[bk]=0` e `[las]=0`, che erano `1`
   da sempre — **dichiarati, mai verificati**: il gate del micro-task ha
   confrontato l'INTERO registry col codice e li ha trovati falsi (#15, #16). Il
   summary li marca `⚠ ran anyway` — vero, e visibile a ogni dry-run.
   **Non flippare un valore a 1 senza fixare il modulo**: `test_run_summary.zsh`
   fallisce (grep del gate nel sorgente + allow-list) e si tornerebbe alla falsa
   attestazione "nothing changed". L'allow-list è bidirezionale: un `0` fuori
   lista fallisce, e una voce che non è più debito fallisce pure — quindi al fix
   di #15/#16 va aggiornata `_KNOWN_UNGATED` in `tests/test_run_summary.zsh`.
   → TRIGGER: fix di #15 o #16.
15. **`mod_bk [4] Check` esegue il Brewfile come DSL Ruby in una preview**
   (MEDIUM, gate 2026-07-21, PRE-ESISTENTE — accettato come debito, non fixato
   qui perché `mod_bk` è componente sensibile e merita task+review propri):
   `brew bundle check` (`mod_bk_brewfile.sh:499`/`:503`) valuta il contenuto del
   Brewfile, mentre lo stesso file documenta a `:96-99` perché la preview del
   restore lo legge STATICAMENTE ("even a check would execute code from a hostile
   Brewfile"). Richiede un `backups/Brewfile` manomesso (attaccante locale).
   Dichiarato con `MODULE_DRYRUN[bk]=0`. → TRIGGER: task dedicato su mod_bk (o
   BM-14 viste report): gatare `[4]` o riusare la lettura statica.
16. **`mod_las [c]` cancella i log di audit senza gate + `mkdir` ungated**
   (MEDIUM+LOW, gate 2026-07-21, PRE-ESISTENTE — stesso motivo di #15):
   il case `c|C` fa `rm -f` su `agents_activity.log` e su tutti i
   `logs/agent_*.log` (`mod_las_scheduler.sh:817-819`) senza gate `--dry-run`,
   mentre `mod_log` gata gli `rm` equivalenti; l'audit trail degli agent è
   irreversibile. In più `mkdir -p "$HOME/Library/LaunchAgents"` (`:15`) gira
   anche in dry-run e anche sul path che esce subito in non-interattivo (stesso
   pattern LOW in `mod_log:15` e `mod_bk:18`, ma lì sono directory del tool).
   Dichiarato con `MODULE_DRYRUN[las]=0`. → TRIGGER: task dedicato su mod_las
   (o hardening #12/#13, che toccano lo stesso modulo).
17. **`(( BREW_MANAGER_DRY_RUN ))` è aritmetica su una stringa d'ambiente**
   (INFO, gate 2026-07-21, PRE-ESISTENTE su tutti i ~18 siti): in zsh
   `y`/`yes`/`true` valgono "gate spento" e una stringa `NAME=value` in contesto
   aritmetico ESEGUE l'assegnazione. **Non raggiungibile oggi**: il core esporta
   `BREW_MANAGER_DRY_RUN` ∈ {0,1} da parsing dei flag (`brew_manager.sh:151`)
   prima di sorgere lib/ e modules/, e il figlio sotto `script(1)` ri-parsa gli
   stessi `"$@"`. Hardening a costo zero se si tocca la classe:
   `[[ "$BREW_MANAGER_DRY_RUN" == 1 ]]`. Nota collaterale: esportare a mano
   `BREW_MANAGER_DRY_RUN=1` SENZA passare `--dry-run` dà una run reale (l'export
   la sovrascrive). → TRIGGER: pass di hardening sui guard-rail, o prima
   segnalazione utente sul comportamento della variabile d'ambiente.
- [[LEARNINGS]]: IMP-001 APPLICATA; **IMP-002** (checklist superficie del
  contratto per i test), **IMP-003** (mai echo su dati — rafforzata dal gate BM-09),
  **IMP-004** (chiudi la CLASSE: grep tutti i siti + verifica adversariale + re-gate),
  **IMP-005** (output di controllo terminale gata su `TUI_TTY`, non solo sul
  colore — origine BM-09), **IMP-006** (review-workflow su un git-range: isola gli
  agenti o vietali dal `checkout` — origine gate BM-10, `Destinazione: framework`)
  **IMP-007** (smoke moduli = selezione CLI posizionale, mai pipe sul prompt né
  `head` sull'output — origine BM-11, estesa da BM-12) e **IMP-008** (lente di gate
  "affermazioni, non solo azioni": un summary/badge che ASSERISCE una proprietà di
  sicurezza va verificato contro il comportamento reale — origine gate BM-12,
  `Destinazione: framework`), **IMP-009** (un test che asserisce l'ASSENZA di
  debito inverte l'incentivo: allow-list bidirezionale, non insieme vuoto),
  **IMP-010** (promuovere un fix locale a CLAIM globale allarga l'insieme da
  verificare oltre il diff) e **IMP-011** (gatare un comando esterno non basta:
  verifica se lo STRUMENTO lo riesegue da sé — origine auto-update di Homebrew;
  le tre `Destinazione: framework`, origine gate del micro-task dry-run
  2026-07-21) APERTE, propose-only, in attesa di decisione (retro periodica o su
  richiesta).

## Branch attivi
- **main** = integrazione + stabile (trunk-based); HEAD `21c956b` (merge BM-12;
  sotto: merge BM-11 `2e61180`, merge BM-10 `2dd1f7c`), allineato a
  `origin/main`; tag **`v1.3.0`** (annotato, pushato) + `v1.2.0` (annotato) +
  `v1.1.2-baseline` (helper). `CHANGELOG [Unreleased]`: vuota (si compila alla
  release, prassi v1.3.0). **v1.4.0 non ancora rilasciata**: impacchetterà
  BM-09+BM-10+BM-11+BM-12 (tutta M3) **più il micro-task dry-run** se integrato
  prima della release.
- **fix/dryrun-mod02-mas** (micro-task dry-run) = gate `--dry-run` su mod_02 e
  mas + `HOMEBREW_NO_AUTO_UPDATE` sotto dry-run + registry onesto per bk/las,
  8 commit di lavoro + checkpoint sopra main, gate adversariale passato (2 lenti;
  la via di mezzo sui finding l'ha decisa l'utente), **268 test verdi**.
  **In attesa di integrazione dell'utente** (blocco `/integrate`, bump PATCH:
  solo `fix`/`docs`, nessun `feat`).
- **feat/progress-summary** (BM-12) = **INTEGRATO in main** (merge `21c956b`),
  branch eliminato.
- **feat/menu-redesign** (BM-11) = **INTEGRATO in main** (merge `2e61180`), branch
  eliminato.
- **feat/risk-badges** (BM-10) = **INTEGRATO in main** (merge `2dd1f7c`), branch
  eliminato.
- **chore/lint-mem-fw-v1.0.0** (riconciliazione memoria post-fw-v1.0.0) = **INTEGRATO
  in main** (merge `765bad4`), branch eliminato.
- **chore/framework-upgrade-v1.0.0** (upgrade v0.5.1 → v1.0.0, solo processo) =
  **INTEGRATO in main** (merge `126bc7d`, pushato; bump "nessun tag"), branch eliminato.
- **feat/tui-foundation** (BM-09) = **INTEGRATO in main** (merge `5867137`), branch
  eliminato.
- **chore/checkpoint-post-v1.3.0**, **docs/readme-v1.3.0**,
  **fix/exit-code-propagation**, **chore/release-v1.3.0**, **fix/agent-selection**,
  **feat/positional-dispatch**, **chore/framework-upgrade-v0.2-to-v0.5.1** =
  MERGIATI in main, branch eliminati.
- **origin/dev** = remoto dormiente, allineato a main al momento dell'innesto; non
  usare come integrazione (vedi [[2026-07-12-trunk-based-su-main]]).
