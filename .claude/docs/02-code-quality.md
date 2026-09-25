# 02 — Code quality: comments, error handling, Definition of Done

PERMANENT rules, valid in every session and for every language in the project. They
are stack-agnostic principles: the conventions specific to the chosen language go in
`CLAUDE.md` (*"Project-specific technical rules"*).

## Comments — the code explains the WHAT, the comments explain the WHY

- Every public unit (class, module, exported function): a documentation comment with
  its responsibility, why it exists, its invariants, and a usage example if the API
  is not obvious. *(The tool in this project: a block of `#` comments before the
  function, as already used in `lib/common.sh` and in the modules — zsh has no
  native doc comments.)*
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
  the client *(in this project the "client" is the terminal: errors ONLY through
  `_err`/`_warn` of `lib/common.sh`, with an actionable message; the raw output of
  failed commands goes to the session log, not to the screen)*, never
  stacktraces/queries/internal paths/library versions: the detail goes to the log
  (with a correlation id), the client gets the concise message.
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
  in this project: NONE active — the block stays commented out in
  `scripts/hooks-install.sh` with a ready `shfmt` example (shfmt/shellcheck are not
  installed; decision recorded at the graft). Minimal manual check: `zsh -n` on the
  touched files; project-wide gates: `make check` (`zsh -n` on every script,
  blocking) and `make test`; `make lint` runs shellcheck as advisory only.
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
- When a suite pins a CONTRACT (a function extracted or moved for parity, an
  exit-code or output contract, a new public surface), enumerate the contract's
  surface BEFORE writing it — a proportional guide, not a ritual for every
  micro-test: (a) the return value or exit code of EVERY outcome, measured at the
  real edge the user invokes, not only at the inner unit; (b) every input class,
  EDGES included (surrounding whitespace, empty tokens, case variants); (c) the
  MULTIPLICITY of side effects (N events for N causes, not just "at least one");
  (d) a MUTATION check: invert the contract and watch the suite fail before
  declaring it done.

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
   procedures, APIs or deployment *(where the documentation lives — `README.md`)*;
   if the project documentation does not exist yet, the debt is recorded in
   `memory/STATE.md`.
8. Memory updated and the commit made per `04-git-workflow.md` (the `/checkpoint`
   command covers points 7 and 8 together).
9. For a completed **deployable** component/app: the production artifact exists (in
   this project NOT applicable: the repo's scripts ARE the artifact, distributed via
   `git clone`; the practical equivalent is: the module works from a clean copy of
   the repo, without depending on local state). This does NOT emerge from tests
   run in a development environment: it must be verified explicitly.

> The security gate for sensitive components is an ADDITIONAL requirement on top of
> the Definition of Done: see `03-security-gate.md`.
