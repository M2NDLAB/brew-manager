---
description: Security review of the modified code
---
Run a security review of the modified files (`git diff`). Minimum checks,
stack-agnostic — adapt/extend those specific to your technology
(see @.claude/docs/03-security-gate.md):

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

Report: severity table (CRITICAL/HIGH/MEDIUM/LOW) + proposed fix for each
finding. Remember how the gate works (docs/03): HIGH/CRITICAL resolved before the
PR, MEDIUM resolved or accepted in STATE.md, LOW at least recorded.
