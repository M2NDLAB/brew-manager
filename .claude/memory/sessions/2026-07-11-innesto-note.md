---
type: session
date: 2026-07-11
status: completed
branch: chore/innesto-framework
tags: [session, innesto, brownfield]
---
# Innesto del claude-code-framework v0.2.0 (brownfield)

> Sessione a cavallo della mezzanotte 11→12 luglio 2026; il nome file segue la
> data di avvio richiesta dall'utente.

## Fatto
- FASE 0 (accertamento read-only): root e stato git confermati; framework sorgente
  `~/Projects/claude-code-framework` a v0.2.0; `.claude/` conteneva solo il
  `settings.local.json` auto-generato dall'harness → CASO A (innesto pulito);
  `.gitignore` esistente e già corretto (logs/backups/agents ignorati, 0 log
  tracciati).
- FASE 1 (assessment): letti core, lib e tutti i 18 moduli; ricostruiti modello
  mentale, stack (zsh/macOS, no build, no test, no linter, no CI), convenzioni,
  pattern di estensione; classificati i moduli per raggio di impatto; trovati i
  difetti reali registrati in [[STATE]] "Attenzione" (CLI posizionali mancanti +
  plist scheduler, off-by-one zsh, DRY_RUN non uniforme, greedy più ampio del
  dichiarato, tag lightweight).
- FASE 2: piano a tabella presentato e approvato dall'utente ("vai con le tue
  raccomandazioni").
- FASE 3 (questo branch): copiati docs/commands/settings/memoria-template,
  CLAUDE.md/Makefile/commitlint/scripts; compilati TUTTI i [DA DEFINIRE AL SETUP]
  coi valori reali; memoria popolata dall'assessment (regime "ibrido dichiarato":
  LEARNINGS vuoto, IMP da 001); .gitignore fuso; SECURITY.md integrato con la sola
  sezione prevenzione; CHANGELOG.md creato; hook installati e verificati
  (commit non-conventional rifiutato, secret finto bloccato).

## Decisioni (rimandi)
- [[2026-07-12-trunk-based-su-main]] — trunk-based su main; origin/dev dormiente.
- [[2026-07-12-componenti-sensibili]] — gate su mod_00/05/bk/las + core + lib.
- commitlint mantenuto (npx al volo, zero footprint); formattazione hook commentata
  (shfmt non installato); allow-list estesa con zsh -n / shellcheck / brew
  list|info / git tag|describe; README NON toccato (nota Claude Code = opzione
  aperta).

## Frizioni brownfield osservate (materiale per il FRAMEWORK — candidata IMP-027 "onboarding brownfield", da NON applicare qui)
1. **SETUP.md è greenfield**: non copre le collisioni con file esistenti (README,
   SECURITY, LICENSE, .gitignore, eventuale Makefile). Servirebbe una sezione
   "riconciliazione": preserva il file del progetto, integra solo il necessario,
   segnala ogni collisione all'utente.
2. **Il "primo comando" presume stato vuoto**: in brownfield la memoria va
   POPOLATA da un assessment del codice esistente (STATE con difetti/maturità
   reali, note components/ dei componenti già esistenti, decisioni retroattive).
   Il pattern IMP-011 (fase di assessment read-only → proposta → decisione utente)
   copre metà del bisogno: andrebbe promosso a passo esplicito del setup brownfield.
3. **Versioning ereditato**: adozione del regime post-1.0 su storia di tag
   preesistente — tag esistenti lightweight (il framework assume annotati per
   `git describe`/i blocchi /integrate), costante di versione nello script in
   drift coi tag. Serve una checklist "igiene dei tag ereditati".
4. **Topologia branch ereditata**: il repo ospite aveva `origin/dev` remoto
   dormiente; SETUP non guida la scelta dichiarata trunk-based vs ripristino del
   branch di integrazione (qui risolta con decisione registrata).
5. **Storia git mai scansionata**: `gitleaks protect --staged` copre solo i commit
   nuovi; per il brownfield servirebbe un `gitleaks detect` one-off sull'intera
   storia come passo di setup.
6. **`.claude/` può preesistere per artefatti dell'harness** (settings.local.json
   creato dalle approvazioni permessi) senza essere un vero innesto precedente:
   il criterio "esiste .claude/?" da solo non distingue CASO A da CASO B.
7. **Lingua**: framework in italiano, doc del progetto ospite in inglese — la
   convivenza va dichiarata (qui: memoria/processo in italiano, README/SECURITY
   in inglese, commit in inglese come la storia esistente).
8. **hooks-install.sh sovrascrive `.git/hooks`**: qui innocuo (nessun hook), ma
   in un brownfield con husky/pre-commit esistenti serve un passo di merge.
9. **Divergenze doc-vs-realtà del progetto ospite** (README che documenta feature
   inesistenti): l'assessment le fa emergere; il setup brownfield dovrebbe
   prevedere dove registrarle (qui: "Debito documentazione" in STATE) senza
   correggerle d'ufficio durante l'innesto.

## Correzioni fattuali doc
- Nessuna applicata al README in questa sessione (le divergenze sono registrate
  come debito in [[STATE]], la correzione è un deliverable separato).

## Follow-up
- Merge del branch via blocco /integrate (utente).
- Primo deliverable candidato: fix Attenzione #1 (CLI posizionali + plist
  scheduler) — passa dal security gate (tocca core + las + bk).
- `gitleaks detect` one-off sulla storia (frizione 5).
- Valutare nota "gestito con Claude Code" nel README (opzione aperta).
