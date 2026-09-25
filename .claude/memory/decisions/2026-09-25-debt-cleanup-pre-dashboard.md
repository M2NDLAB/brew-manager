---
type: decision
updated: 2026-09-25
tags: [decision, debt, dashboard, contract, release]
---
# The pre-Dashboard debt cleanup: scope, order and the choices it depends on

- **Context**: before the macOS Dashboard improvement (a GUI client of brew-manager plus
  new Homebrew functions) the user wanted every open debt closed. A read-only inventory
  ([[sessions/2026-09-24-debt-inventory-pre-dashboard]]) classified each item — (a)
  close now, (b) first task of the improvement, (c) defer — and proposed an order and a
  release. The user approved it on 2026-09-25 with the changes and decisions below.
- **Decision**:
  - **Execution**: the (a) items, ONE branch at a time, in the order of
    [[plans/debt-cleanup-pre-dashboard]]; the docs/03 security gate where marked; every
    branch ends with /checkpoint and a PRINTED /integrate, then stops. Merge, push and
    tags are the user's; the next branch starts only on the user's go.
  - **Category changes**: N-bk-1 → (a), inside the #15 branch
    (`HOMEBREW_NO_AUTO_UPDATE=1` for preview and check). N1 + 4b-0 becomes the FIRST
    code branch, right after the docs/config branches 1–3 and before #18. #11 + 11-bis
    stay (a) (the Dashboard will show the log path). IMP-005 is cut (→ (c)). The
    agent-data-trust branch is split in two — one for mod_bk, one for mod_las — each
    with its own adversarial gate. 4b-1 goes to (b) with 4b-2, as proposed in the
    report, so the same sensitive sites cross the adversarial gate once.
  - **(c) with conditions**, written into the STATE triggers: **#17** is deferrable ONLY
    while the GUI invocation contract (a (b) item) imposes a clean environment — if the
    GUI passes environment variables, #17 returns to (a). **#3b** (the echo-on-data
    class) is deferrable ONLY if the JSON layer is built from structured data, never
    from the modules' screen output.
  - **Branch-grouping deviations approved**: branch 1 (IMP-022 + #7, both on docs/03)
    and branch 2 (the approved IMPs, one commit per IMP).
  - **IMPs approved**: IMP-022, IMP-003, IMP-004, IMP-007, IMP-002. IMP-002 and IMP-004
    are also marked `Destination: framework`.
  - **Exit code for N1**: a NEW dedicated code for "environment precondition failed
    (Homebrew not found / installation declined)". The number is proposed in the N1
    branch, checked against collisions with the raw signal numbers `script(1)` reports
    (1–31), and added to the docs/04 contract there. It is MINOR, so the end-of-cleanup
    release is **v1.5.0**. In the same branch the Homebrew installer MUST honour
    `--dry-run` and never start without a terminal.
  - **Real-launchd check before declaring N1 confirmed**: the agent proposes a
    read-only agent (module 1, `--dry-run`); the user installs it and starts it with
    `launchctl kickstart`; the log is checked; then the agent is removed.
  - **Label check (#13)**: a new `lib/agents.sh`, a SENSITIVE component, used by bk and
    las together with the shared `schedule=` parser. If the extraction turns out too
    wide for the cleanup, the agent says so BEFORE starting and it falls back to
    `lib/common.sh`.
  - **bk [4] in wet mode**: keeps `brew bundle check`, behind a confirmation that says
    explicitly the Brewfile is executed, with `HOMEBREW_NO_AUTO_UPDATE=1`. In dry-run:
    static check only.
  - **las [c] in wet mode**: `_ask_danger` is added.
  - **Harvest map** (branch 14): waits for the framework numbers AND the format from
    the other chat; not run before.
  - **First action of branch 1**: persist the full inventory in a session note (done in
    `6b1e5f6`).
  - **Release**: at the end of the cleanup, v1.5.0 with updated Known limitations — #4b
    until the improvement, #17 and #3b with their conditions, #6.
- **Discarded alternatives**: a v1.4.1 PATCH reusing exit code 1 for "Homebrew missing"
  (1 is already overloaded: failed sources, a failed install; a dedicated code is
  cleaner, at the price of a MINOR); 4b-1 in (a) (it is L, and the same sensitive sites
  would cross the adversarial gate twice); one agent-trust branch for both modules (one
  gate per sensitive module instead); one branch per IMP (overhead without benefit);
  keeping IMP-005 (the code already complies); the label predicate in
  `lib/selection.sh` (it is not the selection grammar) or in `lib/common.sh` by default
  (a dedicated lib is the default, common.sh the fallback).
- **Consequences**: about fifteen branches, nine through the gate (two adversarial); the
  release is MINOR and the new exit code enters the public contract; `lib/agents.sh`
  must enter every sensitive list (CLAUDE.md rule 8 and technical rules, docs/03,
  docs/00, [[2026-07-12-componenti-sensibili]]) in the branch that creates it; the (b)
  items become the improvement's first task (the outcome contract 4b-1/4b-2 designed
  with the JSON schema, the invocation contract, headless consent, stable keys for
  `--adopt`, per-action entry points, the JSON layer into the sensitive lists).
