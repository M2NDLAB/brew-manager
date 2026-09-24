# components/ — durable knowledge about the components

One note for each **significant component/module** of the project (a service, a
library, an app, a subsystem). It captures the knowledge that canNOT be inferred at
a glance from the code: what it exposes, the invariants, the gotchas, the
constraints for those who use it, the local decisions. It is the "living"
documentation that Claude Code loads at the start of a session **only for the
components touched by the task** (see the memory section of `CLAUDE.md`) — which is
why it must be kept dense and up to date.

Unlike the session notes (append-only), these notes are **updated**: they must
reflect the current state of the component, not its history (the history is in
`sessions/` and in git).

## When to write / update it
At the birth of the component and at every substantial change, inside `/checkpoint`.

## Naming
`<component>.md` — e.g. `auth.md`, `core-lib.md`, `web-app.md`.

## Format
```markdown
---
type: component
component: <name>
updated: YYYY-MM-DD
tags: [component]
---
# <name>

<one line: what it is and what it is for.>

## Current state
<created when, maturity level, tests, etc.>

## What it exposes / responsibilities
<public APIs, contracts, events, relevant configuration.>

## Constraints and gotchas (for those who use or modify it)
<gotchas, delicate initialisation orders, implicit assumptions,
 things that look modifiable but are not — with the WHY.>

## Sessions that touched it
- [[sessions/YYYY-MM-DD-<slug>]]
```

> This README stays as a guide; the component notes live alongside it.
