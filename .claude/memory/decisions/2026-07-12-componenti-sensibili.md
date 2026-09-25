---
type: decision
updated: 2026-09-25
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
- **Amendment (2026-09-25, IMP-022, approved by the user)**: `lib/selection.sh`
  joins the gate — SEVEN components, superseding the "six" above. The selection
  parsing (`_resolve_selection`, `_resolve_cli`, `_collect_module_tokens`,
  `_selection_is_valid`) and the per-id registries moved there out of
  `brew_manager.sh` (BM-08a/b, then BM-10–12): a defect there decides which
  modules run — it already produced two MEDIUM fail-opens in BM-08b, one of them
  the `\065`→mod_05 bypass — and a branch touching only it would otherwise skip the
  gate. The flag parsing stays in `brew_manager.sh`. The lists to keep in step:
  CLAUDE.md (rule 8 and the technical rules), docs/03, docs/00, this note and
  INDEX; `/new-component` step 6 names them.
