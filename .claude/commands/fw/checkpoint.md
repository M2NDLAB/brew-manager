---
description: Checkpoint - memory, documentation and a commit, in one go (docs/04). Use at the end of a task or a deliverable (the cycle's fourth step), and before a session ends
---
Run the checkpoint procedure for the current work: $ARGUMENTS

1. Read the commit rules: the sections *WHEN to commit*, *Commit format — Conventional
   Commits* and *Operating rules for Claude Code* of `.claude/docs/04-git-workflow.md` —
   `grep -n '^## '` gives their lines, each read from its title to the next. If the
   context has been compacted since, read them again before the next step.
2. `git status` and `git diff --stat`: list what has changed and check that there
   are no unexpected or suspicious files (secrets, environment files, build artefacts).
3. Update the memory (.claude/memory/), with the file tools (rule 10 of the core,
   `.claude/rules/fw-core.md`):
   - create/update today's session note with what was done and why. Its frontmatter
     follows `sessions/README.md`, plus the two fields written by the main session:
     `model: '<model id as the runtime exposes it>'` (verbatim, ALWAYS single-quoted,
     a `'` inside is doubled; several models → ONE string, distinct ids in order of
     first use, `, `-separated; omit only if the runtime does not expose it) and
     `turns: <n>` (a bare integer: the user's messages whose work THIS note records —
     per note, an approximate proxy, a lower bound after a compaction or a
     resumption; on a later write: the value before this session's first write + all
     of this session's messages, never counting a message twice). Never backfill
     notes that predate these fields;
   - at a deliverable's last checkpoint, the note's security-gate line
     (`sessions/README.md`, *The security gate's line*): the outcome and the tip the
     review's report names — never the HEAD at hand —, or "not applicable" with its reason;
   - update the components/ notes of the components touched;
   - rewrite STATE.md with the current state, within its budget: the SessionStart hook
     shows 8,000 characters of it, *Caution & open issues* first
     (`scripts/state-inject.sh`), so STATE is a dashboard — the history (progress long
     done, decisions with their story, the detail of an issue) moves to the session note
     this checkpoint writes, or stays in the notes that already hold it, and STATE keeps one
     line with a pointer; each *Caution & open issues* entry is one line with its trigger
     and a pointer to the note that holds the detail. Measure it after the rewrite, from
     the repository's root whatever the shell's directory: `r="$(git rev-parse
     --show-toplevel)" && bash "$r/scripts/state-inject.sh" "$r/.claude/memory/STATE.md"`
     — its first line must be the banner `=== PROJECT MEMORY (STATE.md) ===`, its second
     `## Caution & open issues` or the line saying the file has none, and no other line may
     open with `===` — the cut's line, or a fallback's line to Read the file —; any other
     output is a measurement that failed, never a pass. One exception: the checkpoint that
     closes an upgrade of the framework (the framework's `SETUP.md`, Step 6) updates STATE
     without condensing it — the first checkpoint after the upgrade's merge does. AFTER the rewrite check also that the
     pre-existing entries of "Caution & open issues" are still present or
     knowingly closed (a critical debt must not die in a rewrite)
     and that every entry has its explicit TRIGGER, never a generic one;
     and that every open thread of the notes this checkpoint writes — a question that
     awaits the user, a measurement still to take — has its entry there, with its
     trigger (e.g. "ask the user at the next session's start"): the note keeps the
     detail, STATE the pointer, and the entry is closed once answered;
   - reconcile the branch state in STATE with the git reality (merges into the
     integration branch happen OUTSIDE the session, so STATE can be stale):
     `git branch --merged main` and `git log --oneline -5 main`;
     update "Active branches" and the progress accordingly;
   - if the filesystem structure has changed (files/directories created, moved or
     removed): REGENERATE TREE.md with
     `tree -L 3 --dirsfirst -I 'logs|backups|agents|.DS_Store'`
     (fallback if `tree` is missing: `git ls-files`) and realign the legend;
   - update INDEX.md if there are new notes to link.
4. Project documentation (rule 5 of the core, "documentation with the change"):
   - if the project doc EXISTS: check whether the changes touch user-facing
     features, operating procedures, APIs or deploy, and update the relevant pages —
     concise but real, no placeholders;
   - if the project doc does NOT exist yet: add/update the "Documentation debt"
     section in STATE.md with what will have to be documented.
5. EXPLICIT `git add` of the relevant files (never `git add .`), memory and doc included.
6. Commit with a Conventional Commit: correct type and scope, body with the WHY.
7. Show the commit created. Do NOT push: the push is the user's decision. At the end
   of a deliverable, for the merge + tag commands ready to paste use `/fw:integrate`. The
   merge it prints happens outside the session: the next deliverable's first checkpoint
   reconciles it, at step 3 — never a commit of its own after the merge.

If the code does not compile or the tests fail: commit as `chore: wip …` ONLY if we are
on a feature branch (`wip` is not a commit type: the commit-msg hook rejects a `wip:`
prefix), otherwise STOP and report.
