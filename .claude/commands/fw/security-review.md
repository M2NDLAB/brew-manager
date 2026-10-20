---
description: The method's security gate (docs/03) on the branch's diff - not Claude Code's built-in /security-review, which is not the gate. Use before integrating a deliverable under the gate
---
First Read `.claude/docs/03-security-gate.md` whole; if the context has been compacted
since, read it again before the next step. This command is the gate's review, the one the
session note's gate line names; Claude Code's built-in `/security-review` is another
command, and running it does not satisfy the gate.

Run a security review of the branch's changes, and of the set a widened claim names
(check 11). Minimum checks, stack-agnostic — adapt/extend those specific to your
technology (`docs/03`):

1. **Secrets** hardcoded or in committed config (including base64-encoded ones).
2. **Injection** (SQL/NoSQL/command/template): queries or commands built by
   concatenation instead of parameterised.
3. **Authorization**: endpoints/handlers/actions lacking the authorization check,
   or mistakenly excluded from the auth filter; broken access control / IDOR (access
   to other people's resources via a manipulated id).
4. **Sensitive data / PII in the logs** (e.g. logging whole domain objects).
5. **Unvalidated input** at the edge (missing validation on incoming DTOs/requests).
6. **Idempotency** missing on mutating endpoints where double execution does damage
   (payments, orders, non-reversible operations) — where applicable.
7. **CORS / CSRF** with an overly permissive configuration.
8. **Exposure of details** in errors (stacktraces, internal paths, queries, versions)
   towards the client.
9. **Management/diagnostics surface** (admin, actuator, debug endpoints) exposed
   without authentication or on a public surface.
10. **New dependencies**: check the licence and known CVEs.
11. **The lenses of the gate** — *Claims, not only actions* and *The real path*: apply both as
    `docs/03` (*The lenses of the gate*) words them.

Report: first the range reviewed, `Reviewed: <base>..<full sha of HEAD when the review
started>`; then the severity table (CRITICAL/HIGH/MEDIUM/LOW) + proposed fix for each
finding. The session note's gate line copies that sha — never a later HEAD: a fix committed
after it is a new tip, which the review has not seen. Remember how the gate works (docs/03):
HIGH/CRITICAL resolved before the PR, MEDIUM resolved or accepted in STATE.md, LOW closed by
a line of text or declared as a known limit where its claim lives.
