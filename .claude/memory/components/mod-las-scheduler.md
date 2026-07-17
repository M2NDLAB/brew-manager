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
- ~~I plist passano moduli che il core non parsea → ogni agente fa `go`~~
  **CHIUSO (M2)**: il posizionale esiste (BM-08b) e un agente esegue la selezione
  salvata (BM-08c). `_install_agent` è ora il **chokepoint del plist**: valida con
  `_selection_is_valid` e **RIFIUTA** un valore invalido (niente più fallback-`go`
  distruttivo). La migrazione [6][r] passa il valore raw (mangled → refuse a voce).
  La guard del modulo si auto-esclude anche in NON_INTERACTIVE (un agente non
  gestisce agenti). Vedi [[2026-07-17-consent-vs-noninteractive]].
- ~~BUG weekday (#2)~~ CHIUSO in BM-05a; ~~`_install_agent_multi` codice morto~~
  RIMOSSO in BM-07 (i multi-giorno vengono SALTATI, non round-trippano).
- In Modify il conf è cancellato PRIMA della reinstallazione: se il load fallisce
  il conf è perso.
- **Re-register: divergenza conf/plist** (Attenzione #12, LOW): l'estrazione legge
  solo il 1° `<string>` positionale → un plist a due arg è registrato monco.
- Install non chiede conferma y/n finale; il **label** sui path recreate/re-register
  non è validato (Attenzione #13, label injection).

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
- [[sessions/2026-07-17-bm08c-agent-selection]] (agenti via resolver, _install_agent rifiuta invalidi)
