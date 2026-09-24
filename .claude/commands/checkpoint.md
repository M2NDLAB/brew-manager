---
description: Full checkpoint - memory + documentation + Git commit
---
Run the checkpoint procedure for the current work: $ARGUMENTS

1. Read @.claude/docs/04-git-workflow.md for the commit rules.
2. `git status` and `git diff --stat`: list what has changed and check that there
   are no unexpected or suspicious files (secrets, environment files, build artefacts).
3. Update the memory (.claude/memory/):
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
   - update the components/ notes of the components touched;
   - rewrite STATE.md with the current state; AFTER the rewrite check that the
     pre-existing entries of "Caution & open issues" are still present or
     knowingly closed (a critical debt must not die in a rewrite)
     and that every entry has its explicit TRIGGER, never a generic one;
   - reconcile the branch state in STATE with the git reality (merges into the
     integration branch happen OUTSIDE the session, so STATE can be stale):
     `git branch --merged main` and `git log --oneline -5 main`;
     update "Active branches" and the progress accordingly;
   - if the filesystem structure has changed (files/directories created, moved or
     removed): REGENERATE TREE.md with
     `tree -L 3 --dirsfirst -I 'logs|backups|agents|.DS_Store'`
     (fallback if `tree` is missing: `git ls-files`) and realign the legend;
   - update INDEX.md if there are new notes to link.
4. Project documentation ("documentation updated" rule of CLAUDE.md):
   - if the project doc EXISTS: check whether the changes touch user-facing
     features, operating procedures, APIs or deploy, and update the relevant pages —
     concise but real, no placeholders;
   - if the project doc does NOT exist yet: add/update the "Documentation debt"
     section in STATE.md with what will have to be documented.
5. EXPLICIT `git add` of the relevant files (never `git add .`), memory and doc included.
6. Commit with a Conventional Commit: correct type and scope, body with the WHY.
7. Show the commit created. Do NOT push: the push is the user's decision. At the end
   of a deliverable, for the merge + tag commands ready to paste use `/integrate`.

If the code does not compile or the tests fail: commit with the `wip:` prefix ONLY if
we are on a feature branch, otherwise STOP and report.
