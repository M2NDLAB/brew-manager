---
description: Security review del codice modificato
---
Esegui una security review dei file modificati (`git diff`). Controlli minimi,
agnostici allo stack — adatta/estendi quelli specifici della tua tecnologia
(vedi @.claude/docs/03-security-gate.md):

1. **Secret** hardcodati o in config committati (anche codificati base64).
2. **Injection** (SQL/NoSQL/comando/template): query o comandi costruiti per
   concatenazione invece che parametrizzati.
3. **Authorization**: endpoint/handler/azioni privi del controllo di autorizzazione,
   o esclusi per errore dal filtro auth; broken access control / IDOR (accesso a
   risorse di altri tramite id manipolato).
4. **Dati sensibili / PII nei log** (es. log di oggetti di dominio interi).
5. **Input non validato** al bordo (validazione mancante sui DTO/richieste in
   ingresso).
6. **Idempotency** mancante su endpoint mutativi dove la doppia esecuzione fa danno
   (pagamenti, ordini, operazioni non reversibili) — se applicabile.
7. **CORS / CSRF** con configurazione troppo permissiva.
8. **Esposizione di dettagli** negli errori (stacktrace, path interni, query, versioni)
   verso il client.
9. **Superficie di management/diagnostica** (endpoint admin, actuator, debug) esposta
   senza autenticazione o su superficie pubblica.
10. **Dipendenze nuove**: verifica licenza e CVE note.

Report: tabella severity (CRITICAL/HIGH/MEDIUM/LOW) + fix proposto per ciascun
finding. Ricorda la meccanica del gate (docs/03): HIGH/CRITICAL risolti prima della
PR, MEDIUM risolti o accettati in STATE.md, LOW almeno registrati.
