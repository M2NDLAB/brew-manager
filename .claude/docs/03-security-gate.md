# 03 — Security gate: review obbligatoria sui componenti sensibili

La sicurezza ha due livelli in questo framework:

1. **Baseline sempre attiva** — l'hook pre-commit esegue il secret scanning
   (gitleaks) su ogni commit: nessun secret in chiaro entra nel repo (regola 1 di
   `CLAUDE.md`). Vale per tutto, sempre, senza eccezioni.
2. **Gate sui componenti sensibili** — una review di sicurezza manuale, dedicata,
   PRIMA di portare in integrazione un componente critico. È l'oggetto di questo
   documento.

## Cosa sono i "componenti sensibili"

I componenti dove un difetto di sicurezza ha impatto sproporzionato: autenticazione/
autorizzazione, gestione di pagamenti o denaro, dati personali, l'edge che fa
enforcement (gateway/proxy), qualunque superficie che esegue azioni per conto di un
client (es. un server di tool/automazione).

> **Quali, in concreto, in questo progetto.** brew-manager non ha auth né pagamenti:
> qui "sensibile" = raggio di impatto sul Mac reale dell'utente (file rimossi,
> pacchetti installati/disinstallati, persistenza launchd). Ricadono nel gate:
>
> - `modules/mod_00_audit.sh` — adozione app con `brew install --cask --adopt`
> - `modules/mod_05_cleanup.sh` — `brew autoremove` + `brew cleanup -s` (rimozioni)
> - `modules/mod_bk_brewfile.sh` — restore (installa pacchetti, scrive plist,
>   `launchctl load`)
> - `modules/mod_las_scheduler.sh` — persistenza LaunchAgent in `~/Library/LaunchAgents`
> - `brew_manager.sh` — dispatch, parsing input, esecuzione con `--yes`
> - `lib/common.sh` — infrastruttura condivisa dei guard-rail (`_ask`, `_read_choice`,
>   YES_MODE, DRY_RUN): un difetto qui si propaga a TUTTI i moduli
>
> A rischio medio, fuori dal gate ma da trattare con attenzione (preview + conferme):
> `mod_04_updates`, `mod_10_greedy`, `mod_mas_mas` (upgrade globali / install mas).

## La meccanica del gate

Oltre alla Definition of Done (`02-code-quality.md`), PRIMA della richiesta di merge
(PR) verso il branch di integrazione di un componente sensibile:

1. **`/security-review`** eseguita sul diff del branch.
2. Finding **HIGH/CRITICAL → RISOLTI** prima della PR. Non negoziabile.
3. Finding **MEDIUM → risolti**, oppure **accettati esplicitamente** come debito noto
   in `memory/STATE.md`, con il motivo dell'accettazione.
4. Finding **LOW/INFO → almeno registrati** (debito o backlog).

Il gate è un GATE, non un'attività opzionale: un componente "completato" e con i test
funzionali verdi può comunque avere difetti di sicurezza invisibili ai test (un
bypass di un controllo, uno spoofing, un endpoint amministrativo esposto). Solo una
review dedicata li trova prima che finiscano in integrazione.

## Quando la review deve essere adversariale (autore ≠ giudice)

Il criterio non è la severità nominale ma il **raggio di propagazione** del difetto:

- **Adversariale** — chi verifica NON è chi ha scritto (un secondo agente, una
  seconda persona, o un secondo passaggio con mandato esplicito di REFUTARE): per il
  codice di sicurezza in moduli CONDIVISI, dove un difetto si propaga a più
  consumer. L'autore che rilegge il proprio lavoro tende a rileggere le proprie
  assunzioni.
- **Autore-che-verifica** — sufficiente (e l'adversariale è overhead): per
  ricognizioni fattuali e fix locali ispezionabili, con raggio di propagazione
  nullo.

**Prima di agire sui finding.** In una review multi-agente — specie dopo
interruzioni o resume — verifica la COMPLETEZZA dai numeri giusti: la fonte
autoritativa è la SINTESI della review, non i conteggi grezzi di un journal di
esecuzione (che i retry possono gonfiare). Prima si riconcilia il conteggio, poi si
agisce sui finding.

## Prevenzione *by-convention*

Il gate trova i difetti; le convenzioni li prevengono. Dove un'intera classe di
errori è evitabile con una regola (es. "gli endpoint di management/diagnostica non si
espongono mai sulla superficie pubblica", "ogni endpoint mutativo passa per il
controllo di autorizzazione"), scrivi la convenzione nelle regole tecniche del
progetto invece di affidarti alla review caso per caso.

## Dopo la review

- Le decisioni di accettazione del debito vanno in `STATE.md` (sezione *Attenzione /
  problemi aperti*), col motivo.
- Se la review insegna qualcosa sul **processo** (es. un componente che mancava
  dall'elenco dei sensibili, una convenzione assente), diventa una proposta IMP in
  `LEARNINGS.md` — vedi `06-self-improvement.md`. Le lezioni delle review sono tra le
  fonti migliori di miglioramento.
