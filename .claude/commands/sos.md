---
description: Genera un Escalation Report per un interlocutore esperto esterno
---
Genera SUBITO un ESCALATION REPORT secondo il formato definito in
@.claude/docs/05-escalation-protocol.md riguardo a: $ARGUMENTS
(se $ARGUMENTS è vuoto: riguardo al problema corrente della sessione).

Checklist obbligatoria prima di stampare il report:
1. Raccogli: branch e ultimo commit (`git log -1 --oneline`), errore verbatim,
   estratti pertinenti dei file coinvolti, versioni ambiente rilevanti.
2. MASCHERA ogni valore sensibile (ambiente, token, password → `***`).
3. Compila TUTTE le sezioni del formato — un report con sezioni vuote è inutile per
   chi non vede questo ambiente.
4. Stampa il report in un unico blocco di codice facilmente copiabile.
5. Registra l'ID nella nota di sessione di memoria.
6. Poi FERMATI e attendi la ARCHITECT RESPONSE.
