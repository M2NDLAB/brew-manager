# 02 — Code quality: comments, error handling, Definition of Done

PERMANENT rules, valid in every session and for every language in the project. They
are stack-agnostic principles: the conventions specific to the chosen language go in
`CLAUDE.md` (*"Project-specific technical rules"*).

## Comments — the code explains the WHAT, the comments explain the WHY

- Every public unit (class, module, exported function): a documentation comment with
  its responsibility, why it exists, its invariants, and a usage example if the API
  is not obvious. *(The tool — the language's doc comment — is the project's answer
  **Doc comments**: `CLAUDE.md`, *The answers the method reads*.)*
- Every non-trivial public function: what it does, parameters with their constraints
  (range, null), what it throws/returns on error and when, side effects.
- Blocks of complex logic: a comment BEFORE the block explaining the intent and why
  this approach was chosen over the alternatives.
- Workarounds or forced choices: a `// NOTE:` comment with the reason and the link
  (issue, decision, external doc). Never a silent workaround.
- FORBIDDEN: comments that repeat the code (`i++ // increment i`); commented-out code
  left in the files (git is the history, not the comments); TODOs without a reference
  (`// TODO(#issue): ...` is the accepted format).
- Schema migrations / SQL: every index and every constraint with a comment on the why.

## Error handling — no unhandled error, ever

- No empty catches, and none that merely print the stacktrace. Every error handler
  either genuinely handles (retry, fallback, compensation), or enriches and rethrows
  as a domain error, or logs with context and a correlation id and propagates. Never
  swallow an error.
- Error hierarchy: domain errors extend common bases; the application edge translates
  them into a uniform response format. Expose a structured, stable error format to
  the client *(which one — the answer **Error format** in `CLAUDE.md`)*, never stacktraces/queries/
  internal paths/library versions: the detail goes to the log (with a correlation
  id), the client gets the concise message.
- Resources: always released safely (the language's idiomatic construct). I/O
  operations: timeout ALWAYS explicit (never infinite defaults); retries only on
  idempotent operations.
- Validation: input validated AT THE EDGE (on incoming DTOs/requests). Inside the
  domain, input is assumed valid — fail fast with a programming error if an invariant
  is violated (it signals a bug, not a user error).
- User interfaces: every call handled, an explicit error state, understandable
  messages + a visible correlation id for support.

## Best practices and patterns

- SOLID applied pragmatically: in particular dependency inversion (the domain NEVER
  imports the infrastructure) and single responsibility (a unit that grew too large
  is a refactor signal).
- Introduce a design pattern only when there is a concrete problem to solve: a
  pattern without a problem is free complexity.
- Immutability by default: immutable types/values where possible, mutable state only
  where it is genuinely needed.
- Null safety: make what can be absent explicit in the types/signatures; do not use
  ambiguous "empty" values where the language offers something better.
- Naming: the name states the intent. Functions = verbs, predicates = is/has/can. No
  abbreviations except the universal ones (id, url).
- Magic numbers/strings: ALWAYS named constants or externalised configuration.
- Concurrency: mutable shared state = last resort; prefer immutability + message
  passing.
- Every new dependency: justify in the commit why it is needed, check its licence and
  that it is actively maintained. Prefer what is already in the project.
- Formatting: applied automatically by the pre-commit hook (`make hooks-install`), so
  that drift does not accumulate and formatting-only commits are not needed. The tool
  (formatter/linter) is the answer **Formatter / linter** in `CLAUDE.md` — see
  `scripts/hooks-install.sh`.
  Never commit unformatted code.
- Testing configuration: do not build configuration objects by hand in tests with
  long lists of positional/`null` values — adding a field would break every call
  site, including the ones that do not use it. Use builders/fixtures or binding from
  a map, so that adding a property does not propagate to existing tests.
- Verify against REAL artifacts before deciding: never derive a decision or a fix
  from memory alone, or from a recorded debt, when the artifact (code, data, config)
  is on disk — a debt may have been recorded with the wrong CAUSE. Verifying it
  (grep/read) is cheap; carrying out a wrong diagnosis to the letter is expensive.

## Tests that demonstrate (not just green tests)

- A green test can pass for the WRONG reason. A fix is proven in a way that
  DEMONSTRATES the real chain: reproduce the defect (RED), apply the fix isolating
  the variable, show the transition to GREEN — not a generic "the tests pass", which
  they might do with the bug still in place.
- Where it really matters (security, compliance, domain invariants): tests written as
  INVARIANTS re-applied BY CONSTRUCTION, not as assertions about the state known
  today — e.g. a test that, through reflection/introspection, asserts a property over
  ALL entities, with an anti-vacuity check (it fails if the scanned set is empty).
  That way a future regression breaks the build by itself, instead of waiting for
  someone to remember to update the test.
- An invariant over a set that carries a KNOWN debt is a BIDIRECTIONAL allow-list, not an
  assertion that no member violates the property: (a) a member that violates it and is not
  listed fails, so the debt cannot grow in silence; (b) a listed member that no longer
  violates it fails, so an exemption cannot outlive its fix; each entry carries its reason.
  The list is no assertion about the state known today — (b) breaks it the day that state
  changes, as the anti-vacuity check guards the scanned set. And if declaring the truth
  breaks the build — a unit that says it lacks the property —, the test measures the
  declaration, not the behaviour: the test is what to fix.
- A test of what drives an external tool keeps its hermetic baseline, and adds cases under
  the configurations the users have — their git configuration, their attributes, their
  platform: emptying the configuration for hermeticity also removes the defects it causes.
  Each such case checks that its datum reaches the program under test — in the form the
  program receives it, the configuration taking hold, the byte arriving — before it counts.

## Definition of Done for every task

1. Code commented according to the rules above.
2. All errors handled, no path that swallows exceptions.
3. Green tests (unit + integration where applicable). For a component with real
   dependencies, include a **smoke test of the complete system**: a test that boots
   the whole wired component (not just isolated units with mocks) and checks that the
   parts really do wire together — the wiring gaps unit tests cannot see surface
   here. For a deployable UI the analogue is a smoke test of the app's full MOUNT
   (e.g. an end-to-end test, or one that renders the real app with the network
   mocked): component unit tests use test providers and do not see real wiring bugs.
4. API documentation updated if the API changed.
5. No new compiler/linter warnings.
6. A schema migration if the data schema changed.
7. Project documentation updated if the change touches user features, operational
   procedures, APIs or deployment *(where the documentation lives — the answer
   **Documentation** in `CLAUDE.md`)*; if the project documentation does not exist yet, the
   debt is recorded in `memory/STATE.md`.
8. Memory updated and the commit made per `04-git-workflow.md` (the `/fw:checkpoint`
   command covers points 7 and 8 together).
9. For a completed **deployable** component/app: the production artifact exists (e.g.
   a multi-stage container image, non-root runtime, or the equivalent for your
   platform — the answer **Production artifact** in `CLAUDE.md`). This does NOT emerge from tests run in a
   development environment: it must be verified explicitly.
10. The records claim no more than their data: a commit message, a changelog entry, the
    Verified part of an applied IMP is written after the last measurement it cites, and no
    wider than it — a list that declares itself complete is held against its source, or
    narrowed to what was measured.

> The security gate for sensitive components is an ADDITIONAL requirement on top of
> the Definition of Done: see `03-security-gate.md`.
