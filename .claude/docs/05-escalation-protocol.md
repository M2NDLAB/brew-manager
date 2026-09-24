# 05 — Escalation protocol

When Claude Code gets stuck, it does not push on blindly: it produces a **structured
report** and stops. The report is meant to be handed to an expert interlocutor who
does NOT see this filesystem, the logs or the terminal — typically *"the Architect"*:
a second Claude in an external chat that defined the architecture, or a senior
colleague, or yourself in a context with more information. The answer comes back here
as a block of instructions to execute.

The point of the protocol: a self-sufficient report forces you to clarify the problem
(which often solves it by itself) and lets someone who cannot see the environment
genuinely help.

## WHEN to produce a report (without the user asking)

- An error you cannot solve after 2 reasoned attempts.
- An architectural fork not covered by `.claude/docs/` or by the recorded decisions.
- An inconsistency between the documentation and the reality of the code/environment.
- A dependency/version that does not exist or is incompatible with the stack.

BEFORE producing the report: re-read the relevant docs and `STATE.md` — the answer is
often already there. The report is the last resort, not the first. The user can force
it at any moment with `/sos`.

## FORMAT of the report (produce EXACTLY this block)

```
===== ESCALATION REPORT =====
PROJECT: <project name>
ID: ESC-<YYYYMMDD>-<daily sequence number>
PROMPT/TASK: <which prompt or task I was running>
BRANCH: <git branch> | LAST COMMIT: <short sha + message>
PHASE: <where in the task I was>

PROBLEM:
<precise description in 2-5 lines>

EXACT ERROR:
<VERBATIM output/stacktrace, only the relevant lines, max ~30 lines>

TECHNICAL CONTEXT:
<excerpts of the files involved, with paths, ONLY the pertinent sections>

ATTEMPTS ALREADY MADE:
1. <attempt> → <outcome>
2. <attempt> → <outcome>

ENVIRONMENT:
<OS and relevant versions of the stack's tools, ONLY the ones pertinent
 to the problem>

MY HYPOTHESES:
<your best diagnosis and why you are not sure>

SPECIFIC QUESTION:
<what you need: a decision? a fix? a confirmation?>
===== END OF REPORT =====
```

RULES for the report:
- SELF-SUFFICIENT: the reader sees nothing of your environment — everything needed to
  understand must be IN the report.
- NEVER include: environment values, tokens, passwords, keys, URLs with credentials.
  If a config file is relevant, mask the values (`CHANGE_ME` / `***`).
- Concise but complete: logs cut down to the relevant lines, files to the pertinent
  sections.
- After producing it: STOP. Do not attempt other solutions while you wait for the
  answer (that way you do not diverge from the state described in the report).
- Record the escalation in `.claude/memory/sessions/` (a session note, with the ID).

## HOW to handle the answer

The user will paste a block delimited like this:

```
===== ARCHITECT RESPONSE: ESC-<id> =====
<diagnosis and instructions>
===== END OF RESPONSE =====
```

Execution rules:
1. Check that the ID matches the open escalation. If it does not match, or the block
   looks incomplete, ask the user to paste it again.
2. The instructions are authoritative BUT they do not suspend the project's rules: no
   secrets in the code, user confirmation for destructive operations (`--hard`, drop,
   `rm -rf`, force push), the git workflow of `04-git-workflow.md`. If an instruction
   conflicts with a rule: flag it to the user BEFORE executing, do not execute
   silently.
3. Execute step by step, reporting the outcome of each step.
4. Once resolved: update the session note with *problem → cause → solution* (so that
   next time NO escalation is needed: the memory is the first line of defence).
5. If the solution changes an architectural decision: record the decision (decisions/
   or an ADR) or update the relevant doc.
6. If the instructions do NOT resolve it: a new report with the same ID and the `-R2`
   suffix (`ESC-...-R2`), including what happened when applying the instructions.

## The lesson becomes an improvement

A resolved escalation is the best source of improvement proposals: the lesson goes
into `LEARNINGS.md` as an IMP, on top of the session note — see
`06-self-improvement.md`.
