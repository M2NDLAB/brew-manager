---
paths:
  - ".claude/settings.json"
  - "scripts/agent-git-guard.mjs"
  - "scripts/hooks-install.sh"
  - "scripts/state-inject.sh"
---
# The execution boundary — read before changing this file

This file is the method's execution boundary or its wiring. Before you edit it, Read the
sections *Enforcement of the execution boundary* and *Permission configuration* of
`.claude/docs/04-git-workflow.md` — a grep of its `## ` titles gives their lines —, and keep
what they list: the `env` marker, the guard's PreToolUse wiring and its fail-closed form, the
SessionStart hook, the `deny` and `ask` rules, the generated `pre-push`. An edit to
`.claude/settings.json`, the guard or `scripts/state-inject.sh` asks the human; every edit is
made with the file tools, never `sed -i` or a script (rule 10 of the core).
