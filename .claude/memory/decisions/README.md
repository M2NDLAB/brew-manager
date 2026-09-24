# decisions/ — decision log

One note for every **decision worth tracking**: what was decided, why, which
alternatives were discarded and for what reason. It serves to avoid re-discussing
the same choices endlessly and to understand, months later, the rationale behind
something that today looks strange.

## Two levels of decision

- **Significant architectural decisions** (they affect the structure, they are
  costly to reverse): brew-manager does NOT adopt formal ADRs — all the decisions
  are recorded here in full (the project is small and single-developer).
- **Lightweight decisions** (a minor library, a naming convention, a structural
  choice): they are recorded directly here, in full.

If the project does not adopt formal ADRs, keeping ALL the decisions here is
perfectly fine.

## Naming
`YYYY-MM-DD-<slug>.md`. If they are pointers to numbered ADRs:
`YYYY-MM-DD-adr-NNNN-<slug>.md`.

## Format — lightweight decision
```markdown
---
type: decision
updated: YYYY-MM-DD
tags: [decision]
---
# <title of the decision>

- **Context**: <which problem/force required a choice>
- **Decision**: <what was decided>
- **Discarded alternatives**: <and why>
- **Consequences**: <impact, accepted trade-offs>
```

## Format — pointer to a formal ADR
```markdown
---
type: decision
adr: NNNN
updated: YYYY-MM-DD
tags: [decision, adr-pointer]
---
# Pointer → ADR NNNN — <title>

The authoritative text is in <path of the ADR>. Here only the summary and the links.
- **Summary**: <2-3 lines>
- **Impact / links**: [[<other-decision>]], [[<component>]]
```

> This README stays as a guide; the decision notes live next to it.
