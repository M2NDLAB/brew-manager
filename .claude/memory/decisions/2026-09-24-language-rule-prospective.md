---
type: decision
updated: 2026-09-24
tags: [decision, language, framework, memory]
---
# Language: English artifacts from the v1.2.0 upgrade on, existing Italian memory kept

- **Context**: framework v1.1.0 translated the whole method to English and added rule 9
  to CLAUDE.md (ARTIFACTS always English, INTERACTION configurable). brew had declared
  the opposite at the graft ("framework and memory in Italian"), and its memory —
  about 30 notes, STATE, INDEX, TREE, the IMP backlog — is in Italian. Rule 9 has no
  clause for pre-existing non-English memory (SETUP's "Language of the host project"
  covers the host's docs at graft time, and SETUP.md is not in brew). The translation
  also renamed the STATE/LEARNINGS section titles the method files cite by name.
- **Decision** (user, FASE 2 approval of the v1.0.0 → v1.2.0 upgrade):
  - Rule 9 adopted verbatim. Interaction language: Italian (CLAUDE.md, technical
    rules). Commit messages in English from the first upgrade commit.
  - Prospective boundary, recorded in the same slot: memory written in Italian before
    the upgrade is NOT translated; everything written from the upgrade on is English.
    Living files (STATE, INDEX, TREE, LEARNINGS) follow a per-entry policy: new or
    rewritten text in English, entries carried over as they are stay Italian. Mixed
    memory is the applied rule, not drift.
  - Section titles: STATE.md and LEARNINGS.md keep their Italian headings, frozen as
    identifiers (code comments and tests cite "STATE Attenzione #N"); a map in the
    CLAUDE.md technical rules resolves the English titles cited by the method.
    Translating or renaming them needs a dedicated task decided by the user.
  - Files rebuilt by the upgrade are new writing: brew's customisations re-applied in
    English, by language level (1 prose translated, 2 values identical, 3 strings read
    by code byte-identical).
- **Discarded alternatives**: translating the whole memory now (out of scope, one
  change at a time; possible later as its own task); renaming the STATE headings
  (breaks 39 "Attenzione #N" anchors in 24 files, including code of sensitive
  components); citing the Italian titles inside six method files (six more hybrids to
  re-apply at every upgrade); keeping the method in Italian as a declared deviation
  (against rule 9 and every future upgrade).
- **Consequences**: a bilingual memory for a long time; the title map must be kept in
  step with any future rename of a cited title (IMP-043 check). The graft-time
  language record in [[sessions/2026-07-11-innesto-note]] stays as history.
  Links: [[sessions/2026-09-24-framework-upgrade-v1.0.0-to-v1.2.0]] ·
  [[plans/framework-upgrade-v1.0.0-to-v1.2.0]] · [[STATE]]
