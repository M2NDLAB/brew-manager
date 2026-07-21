---
type: component
component: mod-bk-brewfile
updated: 2026-07-21
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
- **BUG weekday (STATE Attenzione #2)**: `_days_map` 1-based indicizzata con
  weekday {0..6} → giorni shiftati di +1 al restore (Sun→Mon), sabato degrada a
  "daily". Il plist generato al momento dell'install è invece corretto.
- ~~**Restore [3]/[3b] NON rispetta `BREW_MANAGER_DRY_RUN`**~~ risolto in BM-03;
  [3a] restore agenti non chiede NESSUNA conferma y/n (solo gate dry-run).
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
