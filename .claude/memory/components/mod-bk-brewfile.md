---
type: component
component: mod-bk-brewfile
updated: 2026-09-25
tags: [component]
---
# mod-bk-brewfile (modules/mod_bk_brewfile.sh)

Backup/restore portabili del setup: Brewfile (`brew bundle`) + bundle degli agenti
LaunchAgent, con preview/check/view/delete. SENSIBILE (restore installa pacchetti e
carica plist).

## Stato attuale
Funzionante; menu ricco (1/1a/1b, 2/2a/2b, 3/3a/3b, 4, 5, 6). Nessun test.

## Cosa espone / responsabilità
- Funzione `_module_14` (alias di menu `bk`).
- Backup: `brew bundle dump --force` → `backups/Brewfile`; agenti →
  `backups/agents_bundle.conf` (label|schedule|moduli).
- Restore: `brew bundle install` (tap+formule+cask+MAS) e `_restore_agents`
  (scrive `~/Library/LaunchAgents/<label>.plist`, `launchctl unload+load`,
  riscrive `agents/agent_*.conf`).
- Delete [6]: `rm -f` selettivo dei file di backup.

## Vincoli e insidie (per chi lo usa o lo modifica)
- ~~**BUG weekday (STATE Attenzione #2)**~~ CLOSED in BM-05a (checked 2026-09-24:
  mod_bk:203-209 maps the 1-based `_days_map` with `i - 1`).
- ~~**Restore [3]/[3b] NON rispetta `BREW_MANAGER_DRY_RUN`**~~ risolto in BM-03;
  ~~[3a] restore agenti non chiede NESSUNA conferma~~ — false (checked 2026-09-24):
  [3a] asks through `_ask_danger` (:486-489).
- **Found by the debt inventory (2026-09-24)**: the menu ignores NONINTERACTIVE (bare
  `read`s → STATE #21/#22); the agents-restore preview and restore diverge and the
  restore degrades silently, zero-padded minutes included (#6b); no label prefix
  enforcement (#13); wet previews trigger Homebrew's auto-update (#29); "success
  printed anyway" (#4b) → branches 6, 9 and 11 of [[plans/debt-cleanup-pre-dashboard]].
- **`[4] Check` esegue il Brewfile come DSL Ruby anche in `--dry-run`**
  (Attenzione #15, MEDIUM, trovato dal gate del micro-task dry-run 2026-07-21):
  `brew bundle check` (`:499`/`:503`) valuta il contenuto del file, mentre
  `_preview_restore_brew` lo legge STATICAMENTE proprio per non eseguire codice
  da un Brewfile ostile (il perché è scritto a `:96-99`). Per questo
  `MODULE_DRYRUN[bk]=0`: in dry-run il summary marca il modulo `⚠ ran anyway`,
  che è vero. Chi fixa `[4]` deve anche togliere `bk` da `_KNOWN_UNGATED` in
  `tests/test_run_summary.zsh` e riportare il registry a 1.
- Generazione plist DUPLICATA rispetto a mod_las: una modifica al formato va
  fatta in ENTRAMBI i punti (candidata a estrazione in lib). NB (BM-08c): la
  VALIDAZIONE della selezione è ora unificata — `_restore_agents` e la preview
  usano `_selection_is_valid` e **SKIPPANO** un agente con modules invalidi
  (niente più fallback-`go` distruttivo), come `_install_agent` di mod_las.
- Gli schedule multi-giorno (`Mon+Wed+Fri`) non fanno round-trip nel parsing del
  restore (la feature multi-giorno è comunque scollegata, vedi mod-las).

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
- [[sessions/2026-07-17-bm08c-agent-selection]] (restore agenti valida + skip invalidi)
- [[sessions/2026-07-21-dryrun-mod02-mas]] (gate: `[4] Check` non gatato → `MODULE_DRYRUN[bk]=0`)
