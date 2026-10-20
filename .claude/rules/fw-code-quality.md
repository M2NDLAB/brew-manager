---
# The globs of the project's code files, one per list item, in place of the setup marker
# below (the framework's SETUP.md, step 2) — e.g. "src/**/*.ts". Until then the marker reads
# as a bracket expression, which matches at most a one-character name: the rule does not load
# on the project's files (measured on a Read, 2026-10-17), and the core (fw-core) alone sends
# Claude to docs/02 before the first edit of code.
paths:
  - "brew_manager.sh"
  - "lib/*.sh"
  - "modules/*.sh"
  - "tests/*.zsh"
---
# Code quality — Read `docs/02` before this change

You are working on the project's code. Before the first edit of code in this task — and
again after a compaction —, Read `.claude/docs/02-code-quality.md` whole, unless this
session already holds it: the core keeps the prohibitions of its rule 2 and the Definition
of Done, the doc holds the rest — the comments' rules, error handling, the patterns, the
tests that demonstrate, and the prohibitions among them.
