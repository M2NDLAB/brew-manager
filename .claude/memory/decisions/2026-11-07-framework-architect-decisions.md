---
type: decision
updated: 2026-11-07
tags: [decision, framework, lint, attribution, memory, process]
---
# The framework architect's decisions of 2026-11-07 (A–D) and the anchors' form (U23)

- **Context**: the first `/fw:checkpoint` after the framework upgrade to v4.1.0 (merge
  `0b127a9`, no tag) had four questions left open by the upgrade: the lint target (STATE
  #34), the `Claude-Session:` trailer of the upgrade's commits (STATE #36), the upgrade's
  working folder outside the repository, and the OPEN IMPs v4.1.0 covers upstream. The user
  sent IMP-033…049 and a new one — recorded here as IMP-050, the lesson U2 decided — to the
  framework's Architect on 2026-11-07 ("il 2026-11-07 ho mandato IMP-033…049 e questa nuova
  all'Architetto") and brought back four decisions, plus their own answer to U23 (the form of the anchors code and tests use for
  STATE entries, [[2026-10-19-framework-upgrade-v4.1.0]]). Applied on
  `chore/post-upgrade-checkpoint` ([[plans/post-upgrade-checkpoint]]).
- **Decision** — the user's words, verbatim:
  - **A, lint**: "Lint: il target lint del progetto diventa zsh -n. In STATE va dichiarato
    come «solo controllo di sintassi, shellcheck non supporta zsh». La regola generale va
    nel framework." Applied: `make lint` runs `make check`'s `zsh -n` on the same files,
    with no logic of its own; `Bash(shellcheck:*)` leaves `.claude/settings.json`'s allow.
    The general rule is the framework's to write: no rule of its own is added here.
  - **B, attribution**: "Attribuzione: da ora si tiene Co-Authored-By e si toglie il link di
    sessione con {"attribution": {"sessionUrl": false}} in .claude/settings.json. La
    sintassi l'ho verificata sulla documentazione: attribution.sessionUrl è booleana e sta
    in qualunque file di impostazioni; solo sessionUrl a false lascia intatto
    Co-Authored-By. Va registrata come regola tecnica. I commit già pubblicati non si
    riscrivono: va dichiarato in STATE." Applied: the key in `.claude/settings.json`, the
    technical rule **Commit attribution** in CLAUDE.md, the declaration in STATE.
  - **C, the working folder**: "La cartella _upgrade-scratch/brew-manager resta finché il
    framework non chiude il triage." Applied: a STATE entry with that trigger.
  - **D, duplicates**: "Le IMP duplicate a monte le segnala l'Architetto dopo la sua
    sessione di raccolta: in questo ramo nessuna IMP va chiusa come duplicata." Applied:
    no IMP closed; the OPEN IMPs v4.1.0 covers upstream wait for the Architect's report.
  - **U23, the anchors**: "le voci aperte tengono il loro numero come etichetta e nessun
    numero viene riusato, perché codice e test citano «Attenzione #N» / «STATE #N» (vedi
    IMP-043)." Applied: the condensed STATE keeps every open entry under its number, new
    entries take new numbers (38 on), and a closed entry leaves at most a one-line pointer;
    the comments in code and tests are not touched.
- **Discarded alternatives**: for A, the options STATE #34 listed — removing the target
  (and the allow rule) or keeping shellcheck with `--shell=bash` and directives — the
  second yields false positives on zsh-only constructs (SC1071 without `--shell`);
  for B, rewording the published commits (pushed history is never rewritten); for U23,
  renumbering the entries or citing a session note from code (20 comment lines in 8 code and
  test files and 10 lines of CLAUDE.md would go stale).
- **Consequences**: `make lint` is a syntax check only, as `make check` is; the session
  link is omitted only where Claude Code adds it — commits and pull requests from a cloud or
  Remote Control session (its settings reference, `attribution.sessionUrl`, read on
  2026-11-07) —, so a local session's commits prove nothing either way; the commits
  published before 2026-11-07 keep their `Claude-Session:` trailer. Supersedes
  [[2026-07-12-shellcheck-advisory]].
  Links: [[sessions/2026-11-07-post-upgrade-checkpoint]] · [[STATE]] · [[LEARNINGS]]
