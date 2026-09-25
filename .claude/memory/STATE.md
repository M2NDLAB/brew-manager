---
type: state
updated: 2026-09-26
branch: chore/gitignore-d10
tags: [state]
---
# STATE — brew-manager

> Updated: 2026-09-26 | Last: **debt cleanup before the Dashboard — branch 3 of 16** (`chore/gitignore-d10`): `.vault-token`, `vault-keys.json` and `*.iml` added to `.gitignore` (#20 closed; `*.log` stays out by decision D10); LEARNINGS re-verified after branch 2 (IMP-001…025, each once, statuses coherent); the IMP-002 widening to output surfaces handed to the improvement's first task (user decision); the **real-launchd verification plan** for branch 4 written, reviewed adversarially and persisted in [[plans/debt-cleanup-pre-dashboard]] (task 4 section). Branch 2 INTEGRATED (merge `9e4f2b4`). Ready for integration (no tag). Next: branch 4 (N1 + 4b-0) ONLY on the user's go, starting with the launchd verification. → [[sessions/2026-09-26-gitignore-and-launchd-plan]] | Index: [[INDEX]]

> **Previous**: framework upgrade v1.0.0 → v1.2.0 INTEGRATED (merge `0725ae6`, post-merge checkpoint merged in `8ed9f5c`, pushed; no tag): the method in English, interaction in Italian → [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]].

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
    attraverso `script(1)`); **suite 268**. **INTEGRATO in main** (merge
    `dc47ae4`, branch eliminato). → [[sessions/2026-07-21-dryrun-mod02-mas]].
  - [x] **Release v1.4.0 RILASCIATA** (2026-07-23): merge `ab45323` in main, tag
    **annotato** `v1.4.0` (oggetto `d4901b3` → commit `ab45323`) creato e pushato;
    `main == origin/main`; `make version-check` verde; branch
    `chore/release-v1.4.0` eliminato. Merge/tag/push eseguiti dall'utente. Bump
    **MINOR** (13 `feat` nel set `v1.3.0..main`): impacchetta tutta M3 (BM-09→12) +
    il micro-task dry-run. CHANGELOG `[1.4.0]` con **Known limitations** onesta per
    #15/#16 (**decisione utente: rilascia ORA col debito dichiarato**, scartate le
    opzioni "chiudi prima"). 268 test verdi. → [[sessions/2026-07-23-release-v1.4.0]].
- [x] **Upgrade framework v0.5.1 → v1.0.0** (2026-07-19, fuori roadmap, solo
  processo): procedura SETUP formale, attraversa la 1.0. 4 file riconciliati (docs/04,
  lint-memory, CLAUDE.md, scripts/README) + retrofit del pin; contratto pubblico di brew
  compilato in docs/04 (moduli CONGELATI, decisione utente); invariante memoria VUOTA;
  132 test verdi. **INTEGRATO in main** (merge `126bc7d`, pushato; bump "nessun tag").
  → [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]].
- [x] **Framework upgrade v1.0.0 → v1.2.0** (2026-09-24, out of roadmap, process only;
  the THIRD upgrade of the graft, a jump decided mid-way: a v1.1.0 assessment was
  superseded before any file was touched). FASE 1 read-only multi-agent assessment →
  user decisions D1–D14 → FASE 2 on `chore/framework-upgrade-v1.0.0-to-v1.2.0`:
  13 task commits, hooks reinstalled and proven (gitleaks blocks, commitlint rejects),
  translation fidelity reviewed adversarially. Stale claims corrected in a separate
  Level-1 commit; security gate not applicable (verdict in the note). 268 tests green.
  **INTEGRATED into main** (merge `0725ae6`, pushed; no tag). →
  [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] ·
  [[plans/framework-upgrade-v1.0.0-to-v1.2.0]].
- [ ] **Debt cleanup before the Dashboard** (from 2026-09-25; decided by the user after
  a read-only multi-agent inventory → [[sessions/2026-09-24-debt-inventory-pre-dashboard]]):
  16 branches in order ([[plans/debt-cleanup-pre-dashboard]]; decisions
  [[decisions/2026-09-25-debt-cleanup-pre-dashboard]]), one at a time, the security
  gate where marked, a printed /integrate after each; it ends with release **v1.5.0**.
  - [x] Branch 1 `chore/imp-022-sensitive-selection`: inventory persisted (`6b1e5f6`),
    plan and decisions (`aa54a51`), IMP-022 applied (`90cb34c`), #7 closed
    (`5fa7159`), Level-1 memory corrections at the checkpoint (`2ef3c21`).
    **INTEGRATED** (merge `73bc5ee`; no tag). →
    [[sessions/2026-09-25-imp-022-and-history-scan]].
  - [x] Branch 2 `chore/apply-project-imps`: IMP-003 (`a59d5eb`), IMP-004 (`a7f309f`),
    IMP-007 (`225cadd`), IMP-002 (`53d4827`), the adversarial review's fixes
    (`36aa1b2`), checkpoint `3d36cf4`; IMP-005 deferred. **INTEGRATED** (merge
    `9e4f2b4`; no tag). → [[sessions/2026-09-25-apply-project-imps]].
  - [x] Branch 3 `chore/gitignore-d10`: the three template patterns (`7ef025b`), the
    IMP-002 hand-over and the reviewed real-launchd verification plan for branch 4
    (memory), checkpoint. **Ready for integration** (no tag). →
    [[sessions/2026-09-26-gitignore-and-launchd-plan]].

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
  esporta `HOMEBREW_NO_AUTO_UPDATE=1` SOLO sotto `--dry-run` (riga 160): senza,
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
- The `.claude/` process framework (docs, commands, memory), CLAUDE.md, Makefile, git
  hooks (gitleaks + commitlint), CHANGELOG.md. **Method at framework v1.2.0** (from
  v1.0.0, 2026-09-24): the whole method in English (rule 9), interaction in Italian,
  the Italian memory headings frozen and mapped in the CLAUDE.md technical rules (D1);
  /checkpoint writes `model`/`turns` into session notes; IMP format
  `Origin: [[<session note>]] — <problem>`; `docs/04` keeps brew's public contract
  (flags, selection grammar, frozen module ids, exit codes 0/1/2, plist format); hooks
  carry the English marker (the Italian one is accepted as legacy). Provenance pin
  `.claude/framework-version` at 1.2.0 / `7d6a9f7`, outside memory/. History:
  [[sessions/2026-07-11-innesto-note]] (graft v0.2.0),
  [[sessions/2026-07-17-framework-upgrade-v0.2-to-v0.5.1]] (→v0.5.1),
  [[sessions/2026-07-19-framework-upgrade-v0.5.1-to-v1.0.0]] (→v1.0.0),
  [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] (→v1.2.0).
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
- Sensitive components (rule 8 / docs/03): mod_00, mod_05, mod_bk, mod_las +
  `brew_manager.sh` + `lib/common.sh` + `lib/selection.sh` (the last one since
  IMP-022, 2026-09-25) → [[2026-07-12-componenti-sensibili]].
- commitlint mantenuto benché il progetto non usi Node (npx risolve al volo, zero
  footprint nel repo); formattazione hook lasciata commentata (shfmt non installato).
- Language (since the framework v1.2.0 upgrade, 2026-09-24): artifacts in English
  (rule 9), interaction in Italian; the memory written in Italian before the upgrade is
  not translated (per-entry policy for the living files); STATE/LEARNINGS headings are
  frozen identifiers, mapped in CLAUDE.md →
  [[decisions/2026-09-24-language-rule-prospective]].
- `.gitignore`: the template's `*.log` pattern was omitted on purpose at the graft —
  brew's logs are already ignored through `logs/` and `brew_report_*.log` (user
  decision D10, 2026-09-24). It is not debt.
- README not modified at the graft: the "managed with Claude Code" note remained an
  open option (Contributing or footer); README :516 already cites the tooling, so it
  is partly superseded → decided (yes/no, or closed as superseded) in branch 15 of
  the debt cleanup ([[plans/debt-cleanup-pre-dashboard]]).
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
- **VERSION and the release tag move together** (formerly Caution #5b — a permanent,
  mechanised rule, not a debt): `VERSION` and the tag are updated in the SAME commit,
  `[Unreleased]` moves under the new version, and `make version-check` fails on drift
  → [[2026-07-14-versione-fonte-unica]]. Next application: the v1.5.0 release.
- **Debt cleanup before the Dashboard** (2026-09-25): the categories, the order, the
  new exit code for a failed environment precondition (MINOR → v1.5.0),
  `lib/agents.sh`, the bk [4] and las [c] wet-mode behaviour, and the conditions that
  keep #17 and #3b deferred → [[decisions/2026-09-25-debt-cleanup-pre-dashboard]].

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
- **README and SECURITY.md vs the code** (registered by the upgrade assessment,
  2026-09-24, D2; widened by the debt inventory the same day): besides "Adding a new
  module" (four registries, not three; the key-set pin; the hand-written id lists; the
  `_module_14` trap) and "Project structure" (`lib/selection.sh`, `tests/`), a full
  re-read against the code found R2b–R13 and M3 — the log is per run, the prompt text is
  stale, a CLI selection is not "non-interactive" on a tty, the summary example is
  impossible, las [c] deletes more than stated, the dry-run and exit-status claims are
  too wide, mod_03 is not a single call, the helpers do NOT implement DRY_RUN, las has
  no `[!]` confirmation, mod_02 updates without one — and SECURITY.md :18-25/:73
  under-states the footprint and the network traffic. Full list:
  [[sessions/2026-09-24-debt-inventory-pre-dashboard]] (section E). Every fix branch
  rewrites its own section (rule 5); the residue goes in branch 15
  (`docs/readme-truth`), last.

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
   in `brew_manager.sh:160`, verificato end-to-end attraverso il re-exec di
   `script(1)`. RESIDUI APERTI, entrambi dichiarati onestamente nel registry:
   vedi #15 (mod_bk `[4]`) e #16 (mod_las `[c]` + `mkdir`).
   Debt inventory 2026-09-24: a full sweep of the mutating commands confirms the
   residual is exactly #15 + #16; mod_01's fixed `/tmp/brew_doctor.log` write also runs
   under --dry-run → #11. Closed with branches 9 and 10.
3b. **Echo on data expands escapes** (LOW, BM-03 gate; scope measured by the debt
   inventory 2026-09-24): zsh's builtin `echo` expands `\e`/`\0NN`/`\x..` even
   without `-e`. The resolver instance was CLOSED in BM-08b (the MEDIUM `\065`→mod_05
   bypass; closed with parameter expansion, `${(@s:,:)}`/`${// /}`). The class is
   wide: 74 `echo "$var" |` sites in 14 module files (mostly
   grep/counting, but mod_00:53/70 validate a token on the expanded value), the five
   renderers `_ok/_warn/_err/_info/_item` are `echo -e "$msg"` (59 calls interpolate
   data), ~38 `echo -e` lines with data, mod_05 on both the dry-run and the real path,
   bk `_restore_agents` and [5] View, las [v]; mod_02:88 and mas:46 rely on the
   expansion (a palette inside `_item`); untrusted data also reaches the text of a
   consent question (mod_00:208 puts the app name into `_ask_danger`, rendered by
   `_ask` through `echo -e`); #26 (mod_03) is a live JSON corruption.
   Category (c) for the class, **deferrable ONLY if the JSON layer is built from
   structured data, never from the modules' screen output** (user condition,
   2026-09-25). Prevention = IMP-003, APPLIED in the CLAUDE.md Code conventions
   (2026-09-25, branch 2); the bk-restore half is fixed in
   branch 11, mod_03 in branch 8. → TRIGGER: the JSON layer reuses screen output, or
   new code copies the pattern.
4. ~~**mod_10 greedy**: scope globale + exit code non verificato~~ **RISOLTO** in
   BM-06. The "success printed anyway" pattern is wider than mod_02/mas (debt
   inventory 2026-09-24): mod_04, mod_05, mod_bk (dump, restore, `_restore_agents`,
   `_backup_agents`), mod_00, the las remove, mod_log → absorbed by #4b (4b-1),
   category (b).
4b. **Module outcomes are not reported** (LOW at BM-06; re-assessed by the debt
   inventory 2026-09-24). ~~The parent losing the child's exit in the ANSI strip~~
   CLOSED by the exit-code micro-task (2026-07-18: `99`→2, empty selection→1, a signal
   → its raw number, pinned by `tests/test_exit_codes.zsh`). OPEN, the modules' half,
   with a corrected cause: today's returns are not "noise" (the "mod_02 returns 1"
   sample is not reproducible) but UNIFORMLY 0 — 17 of 18 modules return 0 even with
   brew failing on every verb; only mod_10 returns 1, and the dispatcher never reads
   `$?` (`_run_status` is a pure function of the registries; `failed` is reserved,
   never assigned). The summary shows ✓ for failed, skipped and declined modules.
   Split: **4b-1** (truthful minimal outcomes) + **4b-2** (the full outcome contract:
   states, a `_mod_outcome` channel, "unmeasured" counters, an audit of the 18
   modules) → category **(b)**, the improvement's first task, designed with the JSON
   schema; **4b-3** (a non-zero process exit when a module fails: MINOR with a new
   code outside 1–31) → **(c)**, TRIGGER: the Dashboard must show launchd-run outcomes
   through LastExitStatus, or BM-17 is brought forward. Idiosyncrasy: Ctrl+C → exit 2
   (the raw signal number of macOS `script(1)`), indistinguishable from "unknown
   token". → [[sessions/2026-09-24-debt-inventory-pre-dashboard]] (section C).
5. ~~**Tag esistenti lightweight**~~ **CONVENZIONE IN VIGORE da v1.2.0**: `v1.2.0`
   è il primo tag di release **annotato** (i legacy v1.1.1/v1.1.2 restano
   lightweight, com'erano). Ogni release futura usa `git tag -a`. Nota:
   `v1.1.2-baseline` è annotato ed è un tag HELPER, escluso dal `git describe` del
   tool (vedi BM-07).
5b. ~~**VERSION and the tag must stay aligned**~~ → moved to "Decisioni prese" (a
   permanent, mechanised rule, not a debt — debt inventory 2026-09-24).
6. ~~`_install_agent_multi` codice morto~~ **RIMOSSA** in BM-07 (108 righe). Gli
   schedule multi-giorno NON fanno round-trip: vengono SALTATI con warning
   (restore bk, re-register, migrazione, recreate) invece di degradare a
   daily/singolo giorno. → TRIGGER: se si vuole davvero la feature multi-giorno,
   va riscritta da zero (serve un writer multi-intervallo anche nel restore).
   Debt inventory 2026-09-24: a feature, not a debt → category (c); re-evaluate in the
   Dashboard design (a multi-day picker would be an M4 feat, MINOR).
6b. **bk: the agents-restore preview does not mirror the restore, and the restore
   degrades silently** (INFO at BM-05a → LOW/MEDIUM, widened by the debt inventory
   2026-09-24): the preview mirrors the skip of an invalid `modules=` value, but it
   lists entries the restore skips (label shape, multi-day, and an empty label skipped
   SILENTLY); an unknown day or a missing schedule becomes a
   DAILY agent; an out-of-range time is clamped in the plist while the conf keeps the
   raw value; and on AUTHENTIC backups the minute clamp rejects the zero-padded
   "00"–"09" brew-manager itself writes (an agent at 9:05 is restored at 9:00,
   silently). README :390 and the code comment "the preview never lies" are false. →
   branch 11 (`fix/bk-agent-trust`: one verdict shared by preview and restore, in
   `lib/agents.sh`).
7. ~~The pre-existing git history was never scanned~~ **CLOSED** (2026-09-25, branch
   `chore/imp-022-sensitive-selection`): `gitleaks detect --redact --log-opts="--all
   -m"` with gitleaks 8.30.1 and the default rules (no `.gitleaks.toml`, no
   `.gitleaksignore`) scanned 155 commits = `git rev-list --all --count` (every commit
   of every ref, each of the 31 merges diffed against its parents) → **0 findings**.
   Every public ref (`git ls-remote origin`: main, dev, 6 tags) resolves to a local
   commit, so the published history is covered; nothing to rotate. The pre-commit
   hook keeps covering new commits. → [[sessions/2026-09-25-imp-022-and-history-scan]].
8. ~~**YES_MODE perso nel re-exec script(1)**~~ **CHIUSO (BM-08c)**, ma NON col fix
   "candidato" originale — che il gate ha bocciato come CRITICAL (avrebbe
   auto-confermato i default distruttivi senza --yes). Chiuso separando
   **NON_INTERACTIVE** (solo anti-blocco) da **YES_MODE** (solo --yes): una run
   non-TTY senza --yes ora NEGA ogni `_ask` (fail-closed, anche default `y`); un
   `BREW_MANAGER_YES` stale in env è sovrascritto. I LaunchAgent (--yes) eseguono
   la loro selezione. Decisione: [[2026-07-17-consent-vs-noninteractive]].
   INVARIANTE nuova: "non c'è tty" ≠ "consenso" — un modulo che muta SENZA passare
   per `_ask` NON è coperto (see #3: mod_02's `brew update` — the pointer said "#12",
   a wrong number since it was written in 98cdbff).
9. ~~Unknown CLI flags ignored silently~~ RESOLVED (0e48373). ~~A legacy plist with a
   corrupt `modules` → exit 2 on every run~~ CLOSED (BM-08c: the scheduler, the bk
   restore and its preview validate with `_selection_is_valid` and refuse or skip).
   RESIDUAL, OPEN and wider
   than recorded (debt inventory 2026-09-24): flag VALUES are not validated —
   `--upgrade=yes`/`Y`/`true` prints `[auto: yes]` and then declines (exit 0);
   `--upgrade=y` without --yes pre-answers nothing (README :166/:181 false); an EMPTY
   `--only=` counts as absent, so `go --only=` runs the WHOLE sequence, cleanup
   included, even on a tty (a destructive fail-open); a non-TTY run without a
   selection falls to the menu's default `go`. → branch 7 (`fix/cli-flag-values`),
   PATCH only with the recorded formulation: invalid values → 2, an empty `--only=` →
   1, an empty `--skip=` stays valid, `--adopt=` mirrors mod_00's grammar, no aliases,
   no consent from `--upgrade=y`.
10. ~~`_ask` shows "(y/N)" even with default y; "Runs only after confirmation" holds
   only interactively~~ **CLOSED** (debt inventory 2026-09-24): the interactive
   "(y/N)" is true by design (Enter = No, an explicit `y` is needed,
   common.sh:438-440), and the mod_05 wording was already fixed in 2fcb1f8 (BM-02). The
   only residue (`[auto: <raw default>]` for a default other than y/n) goes into #9.
   The real GUI gap — all-or-nothing consent, no flags for default-n actions — is a
   design topic (BM-16), category (b).
11. **Fixed, predictable /tmp paths** (`/tmp/brew_*.log`, INFO at BM-04 → LOW;
   re-assessed 2026-09-24): mod_00, mod_01 (also under --dry-run) and mod_02 write
   fixed paths; O_TRUNC follows a symlink planted by another local user; 2 of the 5
   paths in the final `rm` (brew_manager.sh:564-565) are dead; kills and hangs leak
   the files; concurrent sessions (a GUI plus agents) delete each other's files and
   report false states. → branch 13 (`fix/per-run-paths`, with #25): a per-run
   `mktemp -d`.
12. **Re-register/repair widen a scoped agent to `go --yes`** (PRE-EXISTING, found by
   the BM-08c gate as LOW → MEDIUM proposed; the recorded "the listing under-reports; it
   does not change execution"
   is FALSE, and so is the code comment mod_las:125-127 — debt inventory
   2026-09-24): the plist reader keeps only the first `<string>` (`35` for two strings
   on one line); an argv the current grammar accepts (`--only=1 --yes`) is flagged as
   legacy-corrupt; the re-register writes the placeholder `modules=go`; and a Repair —
   or a plain [4] Modify that keeps the shown value `go` — rewrites the plist as `go
   --yes`. Reachable today only through a plist not written by brew-manager; directly
   reachable once the Dashboard or the BM-15 presets write agents with
   `--only`/`--skip`. README :417 is false. → branch 12 (`fix/las-agent-trust`): read
   the whole
   argv, validate it with the real grammar, drop the `go` placeholder.
13. **Agent labels from untrusted data** (PRE-EXISTING, found by the BM-08c gate as
   LOW → LOW/MEDIUM, widened
   2026-09-24): no label validation on las's data paths (recreate, repair, Modify,
   Remove; the re-register only by shape) and no prefix enforcement in las or in the
   bk restore — a third-party LaunchAgent was overwritten on both paths in a sandbox,
   and a `../` label makes [5] Remove `rm` any writable `*.plist` outside
   ~/Library/LaunchAgents. → one predicate `^com\.m2ndlab\.brew-manager\.[A-Za-z0-9._-]+$`
   in the new sensitive `lib/agents.sh`: the bk half in branch 11, the las half in
   branch 12.
14. **`MODULE_DRYRUN` è la lista dei moduli che NON rispettano `--dry-run`**
   (BM-12). ~~`[2]=0` e `[mas]=0`~~ **CHIUSI** (micro-task 2026-07-21: entrambi
   ora `1`, gate dimostrato). Al loro posto `[bk]=0` e `[las]=0`, che erano `1`
   da sempre — **dichiarati, mai verificati**: il gate del micro-task ha
   confrontato l'INTERO registry col codice e li ha trovati falsi (#15, #16). Il
   summary li marca `⚠ ran anyway` — vero, e visibile a ogni dry-run.
   **Non flippare un valore a 1 senza fixare il modulo**: `test_run_summary.zsh`
   fallisce on the allow-list only — its grep half just proves the gate is MENTIONED
   (mod_bk mentions `BREW_MANAGER_DRY_RUN` 7 times, mod_las 6), so the behavioural
   proof is the tripwire tests (debt inventory 2026-09-24) — e si tornerebbe alla falsa
   attestazione "nothing changed". L'allow-list è bidirezionale: un `0` fuori
   lista fallisce, e una voce che non è più debito fallisce pure — quindi al fix
   di #15/#16 va aggiornata `_KNOWN_UNGATED` in `tests/test_run_summary.zsh`.
   → TRIGGER: fix di #15 o #16. Closed inside branches 9 and 10 of the debt cleanup
   (each flips its own entry).
15. **`mod_bk [4] Check` esegue il Brewfile come DSL Ruby in una preview**
   (MEDIUM, gate 2026-07-21, PRE-ESISTENTE — accettato come debito, non fixato
   qui perché `mod_bk` è componente sensibile e merita task+review propri):
   `brew bundle check` (`mod_bk_brewfile.sh:499`/`:503`) valuta il contenuto del
   Brewfile, mentre lo stesso file documenta a `:96-99` perché la preview del
   restore lo legge STATICAMENTE ("even a check would execute code from a hostile
   Brewfile"). Richiede un `backups/Brewfile` manomesso (attaccante locale).
   Dichiarato con `MODULE_DRYRUN[bk]=0`. → TRIGGER: task dedicato su mod_bk (o
   BM-14 viste report): gatare `[4]` o riusare la lettura statica.
   Debt inventory 2026-09-24: also reachable WITHOUT a tty (bk reads its menu with a
   bare `read`, so a non-TTY caller writing the answer after the prompt reaches [4]).
   → branch 9 (`fix/bk-dryrun-check`): a static check only in dry-run; in wet mode
   `brew bundle check` behind a confirmation that names the Brewfile execution, with
   `HOMEBREW_NO_AUTO_UPDATE=1` (user decision).
16. **`mod_las [c]` cancella i log di audit senza gate + `mkdir` ungated**
   (MEDIUM+LOW, gate 2026-07-21, PRE-ESISTENTE — stesso motivo di #15):
   il case `c|C` fa `rm -f` su `agents_activity.log` e su tutti i
   `logs/agent_*.log` (`mod_las_scheduler.sh:817-819`) senza gate `--dry-run`,
   mentre `mod_log` gata gli `rm` equivalenti; l'audit trail degli agent è
   irreversibile. In più `mkdir -p "$HOME/Library/LaunchAgents"` (`:15`) gira
   anche in dry-run e anche sul path che esce subito in non-interattivo
   (`mod_bk:18` creates the tool's own `backups/`; the `mod_log:15` case is a no-op,
   see below).
   Dichiarato con `MODULE_DRYRUN[las]=0`. → TRIGGER: task dedicato su mod_las
   (o hardening #12/#13, che toccano lo stesso modulo).
   Debt inventory 2026-09-24: the "mkdir in mod_log:15" part is a no-op
   (brew_manager.sh:67-70 always creates `logs/`); the only mkdir outside the tool is
   `~/Library/LaunchAgents`; [c] has no confirmation in wet mode either. → branch 10
   (`fix/las-dryrun-clean`), with `_ask_danger` before [c] in wet mode (user decision).
17. **`(( BREW_MANAGER_DRY_RUN ))` è aritmetica su una stringa d'ambiente**
   (INFO, gate 2026-07-21, PRE-ESISTENTE on every site — 27, see below): in zsh
   `y`/`yes`/`true` valgono "gate spento" e una stringa `NAME=value` in contesto
   aritmetico ESEGUE l'assegnazione. **Non raggiungibile oggi**: il core esporta
   `BREW_MANAGER_DRY_RUN` ∈ {0,1} da parsing dei flag (`brew_manager.sh:151`)
   prima di sorgere lib/ e modules/, e il figlio sotto `script(1)` ri-parsa gli
   stessi `"$@"`. Hardening a costo zero se si tocca la classe:
   `[[ "$BREW_MANAGER_DRY_RUN" == 1 ]]`. Nota collaterale: esportare a mano
   `BREW_MANAGER_DRY_RUN=1` SENZA passare `--dry-run` dà una run reale (l'export
   la sovrascrive). → TRIGGER: pass di hardening sui guard-rail, o prima
   segnalazione utente sul comportamento della variabile d'ambiente.
   Debt inventory 2026-09-24: 27 sites, not ~18 (22 on DRY_RUN — 4 of them negated,
   fail-open in the dangerous direction — plus 5 consent sites), 35 with the TUI_*
   sites; and with an existing array name a subscript EXECUTES a command substitution,
   not only an assignment. Category (c), **deferrable ONLY while the GUI invocation
   contract (b) imposes a clean environment — if the GUI passes environment variables,
   #17 returns to (a)** (user condition, 2026-09-25).
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
18. **`_module_14` collision** (latent; PRIORITY, a PREREQUISITE of M4 — decision D2):
   bk/las/mas are `_module_14`/`_module_15`/`_module_16` and the alphabetical glob
   (`brew_manager.sh:241`) sources `mod_bk_*` after `mod_14_*`, so bk's function
   replaces a future module 14 (likewise 15/16). Reproduced END-TO-END by the debt
   inventory (2026-09-24), with a corrected damage: under --yes without a tty bk does
   nothing, but the new module NEVER runs, the summary attests a state computed for the
   wrong module, the run HANGS without a tty (#21), and interactively bk's
   Restore/Delete menu appears. The visible headers `_section "15"`/`"16"` of las/mas
   belong to the same fix. README :565 ("any number is fine internally") is the trap.
   → branch 5 (`refactor/module-fn-names`, through the security gate — dispatch, bk,
   las): `_module_bk/las/mas`, a generic dispatch, a wiring guard test. Details:
   [[sessions/2026-09-24-debt-inventory-pre-dashboard]] (section B).
19. ~~**`lib/selection.sh` missing from the sensitive components**~~ **CLOSED**: IMP-022
   applied on 2026-09-25 (`90cb34c`) — it is in CLAUDE.md rule 8 and the technical
   rules, docs/03, docs/00, [[2026-07-12-componenti-sensibili]] and INDEX, and
   `/new-component` step 6 names every list.
20. ~~**`.gitignore` lacks three template patterns**~~ **CLOSED** (2026-09-26, `7ef025b`:
   `.vault-token` and `vault-keys.json` in the secrets block, `*.iml` with `.idea/`;
   `git check-ignore -v` now points at the repo's `.gitignore`) (LOW, out of the
   upgrade's scope,
   D10): `.vault-token` and `vault-keys.json` (the template's secrets block) and
   `*.iml` were never added at the graft; nothing of the kind is tracked
   (`git ls-files` empty). `*.log` is not debt (see Decisions). Done in branch 3 of the
   debt cleanup (`chore/gitignore-d10`).
21. **Non-TTY runs of bk/log hang forever** (HIGH for the GUI, MEDIUM today — found by
   the debt inventory 2026-09-24): `script(1)` forwards ONE EOF when stdin is closed;
   the bare `read`s of the bk/log menus consume it, then `_handle_log`'s own bare
   `read` (lib/log.sh:21, run at the end of EVERY session, ignoring YES and
   NONINTERACTIVE) waits forever — the LaunchAgent shape `bk --yes </dev/null` hangs,
   and the hung child survives its parent (reparented to PID 1). With stdin on an open
   pipe EVERY run waits at the log prompt; on a terminal `go --yes` stops there (README
   :162 false). [[lib-common]] recorded a false cause (fixed). → branch 6
   (`fix/headless-prompts`).
22. **mod_bk ignores NON_INTERACTIVE** (LOW-MEDIUM, 2026-09-24): its menu and the
   Delete selection read stdin directly and there is no guard like las:19, so a non-TTY
   run WITHOUT --yes, with piped answers, deleted the Brewfile and the agents bundle
   under a banner saying "every prompt is declined, nothing is modified". → branch 6,
   with #21.
23. **Startup without Homebrew on PATH; the built-in installer** (MEDIUM, 2026-09-24):
   no PATH bootstrap (`/opt/homebrew/bin`, `/usr/local/bin`) — under launchd or from a
   GUI launched by the Finder (PATH=/usr/bin:/bin:/usr/sbin:/sbin) the tool says
   "Homebrew is not installed" and exits **0**, so the installed LaunchAgents most
   likely never run brew and look successful (simulated with `env -i`, NOT yet observed
   under a real launchd job); the installer (brew_manager.sh:185-235) ignores
   --dry-run, uses a bare `read` and runs before the `script(1)` re-exec. → branch 4,
   the first code branch: PATH bootstrap, the installer honours --dry-run and never
   starts without a terminal, a NEW exit code for the failed environment precondition
   added to the docs/04 contract (MINOR → v1.5.0), confirmed under a real launchd job
   with the user before being declared. The reviewed procedure (preflight, run, reading,
   cleanup) is in [[plans/debt-cleanup-pre-dashboard]], section "Task 4 — the
   real-launchd verification".
24. **The las recreate fails on zero-padded minutes** (LOW, 2026-09-24): recreating a
   pending conf passes "00"–"09" to `_install_agent`, whose regex rejects them — the
   default agents at 09:00 included; an unknown day becomes a silent daily agent. →
   branch 12, with the parser shared through `lib/agents.sh`.
25. **The child recomputes LOG_FILE** (LOW, 2026-09-24): it is computed in the parent
   and again in the re-executed child, so across a second boundary (3 of 32 real logs)
   or in the mktemp fallback (always) the banner, the summary and "[3] Delete" point to
   a different file than the one written ("Log deleted" while the log stays); two runs
   started in the same second share one file. → branch 13, with #11.
26. **mod_03 corrupts brew's JSON through echo** (MEDIUM, 2026-09-24): `echo` turns
   `\n` inside JSON strings into control characters, `json.load` fails silently
   (`2>/dev/null`) and every formula falls back to its own `brew info` — reproduced on
   a real 384 KB payload; the proof that echo breaks JSON. → branch 8
   (`fix/mod03-json`), the first application of IMP-003.
27. **Agents on interactive-only modules do nothing and report done** (LOW,
   2026-09-24): the scheduler accepts, and even suggests, `bk`/`log`/`las`/`mas` as an
   agent selection; non-interactively their menus take the default n (las returns on
   purpose). Refuse them in `_install_agent` and the bk restore, or document it →
   TRIGGER: the improvement's first task (category (b)), with the outcome contract.
28. **Handoff variables trusted from the environment on a fresh start** (INFO/LOW,
   2026-09-24): an inherited `BREW_MANAGER_RECORDING=1` skips the `script(1)` re-exec
   (no session log, while `_handle_log` names one) and lets TUI_*/NONINTERACTIVE come
   from the environment; `BREW_MANAGER_SCRIPT_DIR` is always accepted and can load
   `lib/` and `modules/` from another checkout. Not a privilege boundary → TRIGGER:
   the improvement's first task (category (b)), in the GUI invocation contract (a
   clean environment); related to #17 and #25.
29. **bk wet previews trigger Homebrew's auto-update** (INFO, 2026-09-24): `bundle` is
   one of Homebrew's auto-update commands, so the read-only `brew bundle dump`/`check`
   of [2]/[2b]/[4] may rewrite the index despite "no disk writes". → branch 9 (user
   decision: `HOMEBREW_NO_AUTO_UPDATE=1` on those calls).
- [[LEARNINGS]] (retro of the upgrade, 2026-09-24; OPEN, propose-only): **IMP-012**
  hooks-install vs linked worktrees; **IMP-013** the edge-case-4 rollback needs
  `FORCE_OVERWRITE=1`; **IMP-014** docs/05 delimiters without the promised legacy
  reader; **IMP-015** new slots invisible to the Step 4 grep; **IMP-016** a translation
  release vs name-cited section titles; **IMP-017** a written gate verdict for upgrades
  touching the baseline; **IMP-018** read the framework only via its tag, with `-C`;
  **IMP-019** `wip:` rejected by commitlint; **IMP-020** content-based memory
  invariant checks; **IMP-021** delegation briefs quote the user's decisions
  verbatim — all `Destination: framework`; ~~**IMP-022**~~ APPLIED (2026-09-25,
  `90cb34c`). Retro of branch 1 of the debt cleanup (2026-09-25; OPEN): **IMP-023**
  delegated sandbox runs must not leave processes behind; **IMP-024** brief delegated
  agents in the artifact language when their output will be persisted — both
  `Destination: framework`. Branch 2 (2026-09-25): IMP-002, 003, 004, 007 APPLIED
  (IMP-002/004 also `Destination: framework`), IMP-005 DEFERRED (cut by the user: the
  code already complies); retro: **IMP-025** (applying an IMP: map the proposal, run
  what the rule prescribes; `Destination: framework`), OPEN. Branch 3 (2026-09-26):
  **IMP-026** (command blocks for the user: self-contained, literal, no inline comments;
  `Destination: framework`), OPEN.

## Branch attivi
- **chore/gitignore-d10** (branch 3 of the debt cleanup: `.gitignore`, and memory: the
  IMP-002 hand-over, the launchd verification plan) = **READY for the user's
  integration** (`/integrate` block, no tag).
- **main** = integration + stable (trunk-based); HEAD `9e4f2b4` (merge of branch 2 of
  the debt cleanup; below it `73bc5ee` (branch 1), `8ed9f5c`, the post-upgrade
  checkpoint, `0725ae6`, the framework upgrade, and the release merge `ab45323`),
  aligned with
  `origin/main`; tags **`v1.4.0`** (annotated, object `d4901b3` → `ab45323`) + `v1.3.0`
  + `v1.2.0` (annotated) + `v1.1.2-baseline` (helper). `CHANGELOG [Unreleased]`:
  empty. `make version-check` green.
- **chore/framework-upgrade-v1.0.0-to-v1.2.0** (framework upgrade, process only) =
  **INTEGRATED into main** (merge `0725ae6`, pushed; no tag), branch deleted. The git
  hooks installed from it (English marker) are the ones `main` now generates; the two
  `.bak` of the old Italian hooks have been removed by the user.
- **chore/apply-project-imps** (branch 2 of the debt cleanup) = **INTEGRATED into main**
  (merge `9e4f2b4`, pushed; no tag), branch deleted.
- **chore/imp-022-sensitive-selection** (branch 1 of the debt cleanup) = **INTEGRATED
  into main** (merge `73bc5ee`, pushed; no tag), branch deleted.
- **chore/checkpoint-post-fw-v1.2.0** (post-merge memory checkpoint) = **INTEGRATED into
  main** (merge `8ed9f5c`, pushed; no tag), branch deleted.
- **chore/checkpoint-post-v1.4.0** (post-release memory checkpoint) = **INTEGRATED into
  main** (merge `e7c3a56`), branch deleted.
- **chore/release-v1.4.0** (release) = **INTEGRATO in main** (merge `ab45323`,
  tag annotato `v1.4.0`), branch eliminato.
- **fix/dryrun-mod02-mas** (micro-task dry-run) = **INTEGRATO in main** (merge
  `dc47ae4`), branch eliminato.
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
