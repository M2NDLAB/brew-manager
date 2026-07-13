---
type: learnings
updated: 2026-07-12
tags: [improvement]
---
# Learnings & proposte di miglioramento

> **Cos'è questo file.** Il backlog dell'auto-miglioramento di processo (vedi
> `.claude/docs/06-self-improvement.md`). Qui Claude Code registra le proposte di
> modifica a regole, doc, comandi e configurazione (IMP-nnn) — ma NON le applica
> da solo: le applica solo dopo approvazione dell'utente. Le correzioni puramente
> FATTUALI alla doc (Livello 1) non passano da qui, si applicano subito.
>
> La numerazione delle IMP di brew-manager parte da **001**. Le IMP del
> claude-code-framework (001–026 nel repo del framework) NON si ereditano: questo
> file è nato vuoto all'innesto (2026-07-12, framework v0.2.0). Le frizioni
> brownfield osservate durante l'innesto sono materiale per il FRAMEWORK, non per
> questo progetto: sono annotate in
> [[sessions/2026-07-11-innesto-note]].

## Proposte APERTE (in attesa di decisione utente)
_(nessuna proposta aperta)_

<!-- Formato di una proposta:
### IMP-001 — <titolo breve>
- Data: YYYY-MM-DD | Origine: <sessione/problema che l'ha generata>
- Problema osservato: <attrito ricorrente, errore ripetuto, gap, regola ambigua>
- Proposta: <cosa cambiare e dove: CLAUDE.md / docs/NN / comando / hook / processo>
- Beneficio atteso / rischio:
- Trigger di ripresa: <se non è applicabile subito: quale evento la fa tornare in gioco>
-->

## Applicate

### IMP-001 — Review-agent in background: solo comandi in allow-list + prassi diff-inline → applicata il 2026-07-13 (approvazione utente esplicita), commit dedicato su fix/dryrun-bk-restore
- Origine: security gate del micro-task parser (workflow di review in stallo:
  6 retry × 180s per agente; già accaduto nel gate BM-02, 19/31 agenti persi).
  Causa: gli agenti invocavano comandi git legittimi ma fuori allow-list
  (`git show`, `git -C <path> diff`) e in background il prompt permessi non è
  approvabile → stallo silenzioso.
- Applicato: (a) `Bash(git show:*)` aggiunto all'allow di `.claude/settings.json`
  (read-only; la deny resta prevalente); (b) PRASSI per i review-agent: diff
  INLINE nel prompt + soli strumenti Read/Grep/Glob, niente Bash (verificata
  efficace: seconda run del gate parser 2/2 senza stalli).

## Rimandate
_(nessuna)_

## Rifiutate
_(nessuna)_
