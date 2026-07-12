---
type: component
component: mod-las-scheduler
updated: 2026-07-12
tags: [component]
---
# mod-las-scheduler (modules/mod_las_scheduler.sh)

Installa e gestisce LaunchAgent macOS (launchd, utente corrente, no sudo) che
eseguono brew_manager.sh a orari programmati. SENSIBILE: crea PERSISTENZA.

## Stato attuale
Funzionante con riserve importanti (sotto). Nessun test.

## Cosa espone / responsabilità
- Funzione `_module_15` (alias di menu `las`).
- Install: plist `com.m2ndlab.brew-manager.<suffisso>` in `~/Library/LaunchAgents`
  (ProgramArguments: `/bin/zsh brew_manager.sh <moduli> --yes`, log su
  `logs/agent_*.log`), `launchctl unload+load`, conf in `agents/agent_*.conf`,
  activity log append-only.
- Modify/Remove/Integrity check [6] (riconcilia plist orfani ↔ conf pendenti),
  [c] clear logs (solo a zero agenti).
- In modalità --yes il modulo si AUTO-ESCLUDE (niente gestione agenti da agenti).

## Vincoli e insidie (per chi lo usa o lo modifica)
- **I plist passano i moduli come argomenti CLI che il core NON parsea** (STATE
  Attenzione #1): ogni agente schedulato esegue di fatto `go --yes` — inclusi i
  moduli che in --yes non sono sicuri (mod_05). È IL difetto prioritario del
  progetto; coinvolge core + questo modulo + bk.
- **BUG weekday (Attenzione #2)**: `_days`/`_days_names` 1-based indicizzati con
  weekday 0–6 → schedule salvato nel conf shiftato di un giorno (weekday 0 = nome
  vuoto); il plist launchd resta corretto → conf e plist DIVERGONO.
- `_install_agent_multi` è codice morto (mai richiamata dal menu).
- In Modify il conf è cancellato PRIMA della reinstallazione: se il load fallisce
  il conf è perso.
- Parsing dei plist orfani in [6] via grep+`tr -cd '0-9'`: si rompe con plist
  multi-intervallo (concatena le cifre).
- Install non chiede conferma y/n finale (parte dopo l'input dei parametri);
  input weekday/ora/minuto non validati.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
