---
description: Checkpoint completo - memoria + documentazione + commit Git
---
Esegui la procedura di checkpoint per il lavoro corrente: $ARGUMENTS

1. Leggi @.claude/docs/04-git-workflow.md per le regole di commit.
2. `git status` e `git diff --stat`: elenca cosa è cambiato e verifica che non ci
   siano file inattesi o sospetti (secret, file di ambiente, artefatti di build).
3. Aggiorna la memoria (.claude/memory/):
   - crea/aggiorna la nota di sessione di oggi con cosa è stato fatto e perché;
   - aggiorna le note components/ dei componenti toccati;
   - riscrivi STATE.md con lo stato corrente; DOPO la riscrittura verifica che le
     voci preesistenti di "Attenzione / problemi aperti" siano ancora presenti o
     consapevolmente chiuse (un debito critico non deve morire in una riscrittura)
     e che ogni voce abbia il suo TRIGGER esplicito, mai generica;
   - riconcilia lo stato dei branch in STATE con la realtà git (i merge nel branch
     di integrazione avvengono FUORI sessione, quindi STATE può essere stale):
     `git branch --merged main` e `git log --oneline -5 main`;
     aggiorna "Branch attivi" e l'avanzamento di conseguenza;
   - se la struttura del filesystem è cambiata (file/directory creati, spostati o
     rimossi): RIGENERA TREE.md con
     `tree -L 3 --dirsfirst -I 'logs|backups|agents|.DS_Store'`
     (fallback se manca `tree`: `git ls-files`) e riallinea la legenda;
   - aggiorna INDEX.md se ci sono nuove note da collegare.
4. Documentazione di progetto (regola "doc aggiornata" di CLAUDE.md):
   - se la doc di progetto ESISTE: verifica se le modifiche toccano funzionalità
     utente, procedure operative, API o deploy, e aggiorna le pagine pertinenti —
     sintetico ma reale, niente placeholder;
   - se la doc di progetto NON esiste ancora: aggiungi/aggiorna la sezione "Debito
     documentazione" in STATE.md con cosa andrà documentato.
5. `git add` ESPLICITO dei file rilevanti (mai `git add .`), incluse memoria e doc.
6. Commit con Conventional Commit: tipo e scope corretti, body con il PERCHÉ.
7. Mostra il commit creato. NON pushare: il push lo decide l'utente. A fine
   deliverable, per i comandi di merge + tag pronti da incollare usa `/integrate`.

Se il codice non compila o i test falliscono: commit con prefisso `wip:` SOLO se
siamo su feature branch, altrimenti FERMATI e segnala.
