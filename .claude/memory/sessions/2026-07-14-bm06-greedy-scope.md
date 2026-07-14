---
type: session
date: 2026-07-14
status: completed
branch: fix/greedy-scope
tags: [session, roadmap-v2, bm-06, security-gate]
---
# BM-06 — scope del greedy upgrade + exit code (sensibile MEDIO, gate)

## Fatto
- Commit 7785825 su mod_10_greedy.sh. La conferma diceva "update N cask(s)" ma
  eseguiva `brew upgrade --greedy` GLOBALE (formule + cask mai confermati) e non
  controllava l'exit code ("Greedy upgrade completed" anche in caso di errore).
- Ora: conferma che ELENCA i cask e dichiara che non si tocca altro; upgrade un
  cask alla volta (`brew upgrade --cask --greedy -- <cask>`), exit code per cask
  via `${pipestatus[1]}` (mantenendo lo streaming live dell'output), summary
  upgraded / already-current / failed e `return 1` se qualcuno fallisce.
- Il modulo NON aveva alcun gate dry-run: `go --dry-run` + `y` eseguiva un upgrade
  REALE, contraddicendo il README. Ora dry-run fa preview e prevale su --yes.
- Percorso automatizzato invariato: `_ask` con default "n" → gli agenti schedulati
  non forzano mai il greedy (verificato contro main).

## Security gate (docs/03) — gate_holds=true su entrambe le lenti
Fix applicati dai finding (tutti in perimetro):
- MEDIUM: `brew outdated --greedy` senza `--cask` includeva le FORMULE (verificato
  sul sistema reale: la lista conteneva `anomalyco/tap/opencode`). Una formula che
  condivide il token con un cask (`docker` è il caso canonico) faceva risultare il
  cask obsoleto → upgrade forzato per nulla. Aggiunto `--cask`.
- MEDIUM: token cask passati come operandi nudi. Un token flag-shaped verrebbe
  mangiato dal parser di brew, lasciando ZERO operandi → `brew upgrade --cask
  --greedy` senza argomenti aggiorna TUTTI i greedy cask, riaprendo il buco che
  questo task chiude. Aggiunti `--` e shape-check del token.
- MEDIUM (regressione introdotta da me): la command substitution per catturare
  `$?` aveva ucciso lo streaming → un download da 1.5 GB lasciava la TUI muta per
  minuti (letto come hang). Risolto con `${pipestatus[1]}`: streaming + exit code.
- LOW: il ramo dry-run non catturava l'exit code → falso "success" su preview
  fallita. Risolto.
- LOW: "Casks upgraded" contava anche i no-op (brew esce 0 anche quando non fa
  nulla, e questi cask si auto-aggiornano tra la scansione e la conferma). Ora si
  confronta la versione prima/dopo: "no change" separato dagli upgrade reali.
- INFO: `(( x++ ))` ritorna 1 al primo incremento in zsh → pre-increment.
Fuori perimetro, REGISTRATI in STATE: il `return 1` del modulo è inerte (il
dispatcher ignora i return e il core fa `exit 0` incondizionato) — cambiare il
contratto di exit riguarda tutti i moduli.

## Bug cosmetico scoperto dai test
`_stat_row "..." N "${#outdated_greedy[@]:+$C_YELLOW}"`: in zsh il `#` prende la
LUNGHEZZA dell'espansione `:+`, quindi veniva passato un NUMERO come colore e
stampato accanto al valore ("00"). Corretto con colore condizionale esplicito.

## Test (stub brew con stato su file)
Upgrade riuscito (versione 0.0.340→0.0.398, solo il cask confermato, con `--`);
no-op (exit 0 ma versione invariata → "no change", non "upgraded"); fallimento
(exit 1 → Failed + return 1); dry-run fallito (exit 2 → nessun falso successo);
token ostile `--force` da tap → scartato, mai passato a brew; regressione:
dry/dry+yes → solo preview, rifiuto/Enter/--yes → zero comandi di upgrade, zero
outdated → nessuna conferma. RED contro main: `brew upgrade --greedy` globale.

## Follow-up
- Blocco /integrate stampato; merge deciso dall'utente.
- README §10 da riallineare (scope per-cask + dry-run reale) → BM-19.
- Prossimo: BM-07 (versione a fonte unica + codice morto) → CHIUDE M1, poi punto
  con l'utente sul primo tag di release.
