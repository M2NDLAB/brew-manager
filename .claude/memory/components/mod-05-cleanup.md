---
type: component
component: mod-05-cleanup
updated: 2026-07-21
tags: [component]
---
# mod-05-cleanup (modules/mod_05_cleanup.sh)

Libera spazio: `brew autoremove` (dipendenze orfane) + `brew cleanup -s` (vecchie
versioni + cache). SENSIBILE: è il modulo più aggressivo della suite.

## Stato attuale
Funzionante e ora protetto: **BM-02** ha introdotto il ramo `--dry-run` (preview
via `brew autoremove --dry-run` / `cleanup -s -n`) e la conferma; **BM-10** l'ha
promossa a `_ask_danger` (cornice rossa che nomina i due comandi); **BM-12** ha
cambiato solo COME si misura la cache. Nessun test unitario proprio (il consenso
è coperto da `tests/test_guardrails.zsh` a livello di `_ask`).

## Cosa espone / responsabilità
- Funzione `_module_5`; misura la cache prima/dopo. Dal **BM-12** la misura è UNA
  passata `du -sk` (`_du_kb`) da cui derivano sia la stringa mostrata (`DU_AFTER`,
  via `_fmt_kb_or_na`) sia i twin numerici `DU_BEFORE_KB`/`DU_AFTER_KB` che il
  summary sottrae per la riga "Disk". **Invariante**: ogni sito che assegna
  `DU_AFTER` deve assegnare il twin KB — se lo si dimentica la riga del summary
  sparisce in silenzio (è successo davvero); pinnata da `tests/test_run_summary.zsh`.

## Vincoli e insidie (per chi lo usa o lo modifica)
- ~~NESSUNA conferma e NESSUN rispetto di `BREW_MANAGER_DRY_RUN`~~ — **voce STALE,
  corretta il 2026-07-21** (Livello 1, docs/06): il rispetto di DRY_RUN è stato
  aggiunto da BM-02 (merge 3ae5d41) e la conferma è oggi `_ask_danger`. Restano
  validi i due caveat sotto. I **3 rami di uscita** (dry-run, conferma negata,
  cleanup reale) misurano tutti la cache: toccandone uno, toccare anche gli altri.
- `brew autoremove` può rimuovere formule usate FUORI dal grafo brew (il commento
  "both operations are safe" nel codice è ottimista).
- Misura solo la cache, non lo spazio recuperato dai pacchetti rimossi: il numero
  del summary sottostima.

## Sessioni che l'hanno toccato
- [[sessions/2026-07-11-innesto-note]] (assessment, nessuna modifica al codice)
- [[sessions/2026-07-21-bm12-progress-summary]] (misura cache in KB per il delta disco;
  correzione della voce stale su conferma/dry-run)
