---
type: decision
updated: 2026-07-12
tags: [decision]
---
# Componenti sensibili: criterio = raggio di impatto sul Mac dell'utente

- **Contesto**: la regola 8 (security gate, docs/03) richiede l'elenco concreto dei
  componenti sensibili. brew-manager non ha auth/pagamenti/dati personali: la
  sensibilità va tradotta nel dominio del tool — cosa può danneggiare il sistema
  reale dell'utente (file rimossi, pacchetti installati/disinstallati, persistenza
  launchd).
- **Decisione**: nel gate ricadono `mod_00_audit` (adozione app), `mod_05_cleanup`
  (autoremove/cleanup senza conferma), `mod_bk_brewfile` (restore: installa
  pacchetti, scrive plist, launchctl), `mod_las_scheduler` (persistenza
  LaunchAgent), più `brew_manager.sh` (dispatch/parsing/--yes) e `lib/common.sh`
  (guard-rail condivisi `_ask`/`_read_choice`/YES_MODE: un difetto lì si propaga a
  tutti i moduli — criterio del raggio di propagazione, IMP-016 del framework).
- **Alternative scartate**: includere anche i moduli a rischio medio (mod_04,
  mod_10, mod_mas — upgrade globali/install) — scartata per non diluire il gate:
  restano segnalati in docs/03 come "attenzione senza gate", con preview+conferma
  obbligatorie.
- **Conseguenze**: ogni branch che tocca uno dei sei componenti passa da
  /security-review PRIMA del merge; l'elenco vive in CLAUDE.md (regola 8) e in
  docs/03 e va aggiornato se un nuovo modulo diventa mutante.
