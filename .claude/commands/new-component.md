---
description: Scaffold di un nuovo modulo brew-manager secondo le convenzioni del progetto
---
Crea un nuovo modulo chiamato $ARGUMENTS seguendo ESATTAMENTE le convenzioni del
progetto (un "componente" in brew-manager È un modulo; vedi anche "Regole tecniche
specifiche del progetto" in CLAUDE.md).

1. Leggi le regole tecniche del progetto (CLAUDE.md) e la nota del modulo più
   simile in .claude/memory/components/ per replicarne struttura e convenzioni.
2. Crea `modules/mod_NN_slug.sh` (numerico, NN a due cifre zero-padded, prossimo
   numero libero) oppure `modules/mod_<alias>_slug.sh` (modulo speciale invocato
   per nome). Il file viene caricato automaticamente dal glob `mod_*.sh`: nessuna
   registrazione di caricamento.
3. Definisci la funzione `_module_NN` (numero SENZA zero-padding, es. `_module_5`)
   o `_module_<alias>`. Struttura interna standard:
   - apertura con `_section "NN" "Titolo"`;
   - blocco "About this module" in linguaggio piano PRIMA di qualunque azione
     (cosa fa, cosa controlla, cosa può modificare);
   - output SOLO tramite le utility di `lib/common.sh` (`_ok`, `_warn`, `_err`,
     `_info`, `_item`); conferme SOLO via `_ask`/`_read_choice`;
   - **ogni azione mutante gated da `BREW_MANAGER_DRY_RUN` e compatibile con
     `BREW_MANAGER_YES`** (default sicuro = non agire). Regola non negoziabile:
     è la classe di difetti storica del progetto (vedi STATE.md);
   - eventuali file temporanei in `/tmp/brew_*.log` (vengono ripuliti dal main),
     stato condiviso per il summary nelle variabili globali MAIUSCOLE.
4. Registra il modulo in `brew_manager.sh`:
   - voce in `MODULE_DESC` (OBBLIGATORIA: senza, il modulo non è selezionabile);
   - se deve girare nella sequenza `go`: aggiungi il numero a `MODULE_IDS`;
   - riga di stampa nel menu (per gli speciali: printf dedicata dopo `_hline`);
   - solo per i moduli speciali: alias nel case di parsing dell'input e ramo nel
     case di dispatch (alias → funzione).
5. Verifica minima (non esiste una test suite):
   - `zsh -n` su tutti i file toccati;
   - smoke run `./brew_manager.sh --dry-run` selezionando il nuovo modulo:
     deve comparire nel menu, partire, e NON eseguire azioni mutanti;
   - se il modulo è mutante: verifica che con risposta di default ai prompt non
     modifichi nulla.
6. Se il modulo ricade nei criteri di sensibilità (rimuove file/pacchetti,
   installa, crea persistenza launchd — vedi docs/03): aggiungilo all'elenco dei
   componenti sensibili in CLAUDE.md (regola 8) e in docs/03; il primo merge passa
   dal security gate.
7. Aggiorna la documentazione: scheda del modulo nella sezione "Modules" del
   README.md (regola 5).
8. Crea la nota in .claude/memory/components/<modulo>.md e aggiorna INDEX.md,
   STATE.md, TREE.md (via /checkpoint).
