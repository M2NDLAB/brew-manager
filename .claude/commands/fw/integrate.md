---
description: Prints the READY FOR INTEGRATION blocks - merge, tag and checks, then the push - without running them (docs/04). Use at the end of a deliverable, after /fw:checkpoint
---
At the end of a deliverable, prepare the READY FOR INTEGRATION blocks for: $ARGUMENTS
(if empty: for the current branch).

First Read the sections *Merge*, *Versioning — SemVer on annotated tags* and *Execution
boundary and blocks for the user* of `.claude/docs/04-git-workflow.md` — `grep -n '^## '`
gives their lines, each read from its title to the next —; if the context has been
compacted since, read them again before printing the blocks.

**Then, before anything else, the security gate's line** (docs/03, *The check at
integration*). Find the note that closes this deliverable — a session note the branch ADDED,
`git diff --no-renames --diff-filter=A --name-only origin/<integration>...HEAD --
.claude/memory/sessions/` (without a remote, `<integration>...HEAD`), whose frontmatter
`branch:` is the current branch; of several, the latest by its `date:` — and read its
*Security gate* section. STOP, and say which of these holds, when:
- there is no such note, or its section is missing or says nothing: a forgotten gate
  (`sessions/README.md`, *The security gate's line*);
- it says "not applicable" while the branch's diff touches a sensitive component — a
  category of the core's rule 8, the method's own boundary among them — the core (rule 8,
  its table, *Boundary*) and `fw-boundary.md` name it: `.claude/settings.json`, `scripts/agent-git-guard.mjs`,
  `scripts/hooks-install.sh`, `scripts/state-inject.sh`, `.gitleaks*`, a hook manager's
  configuration, which sets `core.hooksPath` —, or a component of the answer **Sensitive components** in
  `CLAUDE.md` — or the deliverable asserts a security property (docs/03, *The lenses of the
  gate*) — in doubt, under the gate; a branch whose diff touches only `.claude/memory/`, and
  no file the project ships, is exempt, and its line says so (docs/00, *Scope and session
  hygiene*);
- it is neither "not applicable" with its reason nor `/fw:security-review` at a reviewed
  tip with its outcome: a review other than the method's — Claude Code's built-in
  `/security-review` is not the gate —, no reviewed tip, a "pending";
- the reviewed tip is not an ancestor of HEAD (`git merge-base --is-ancestor <tip> HEAD`),
  or a commit after it touches a file the project ships — any path outside `.claude/memory/`,
  and the memory's starting files where the project ships them (the framework's own
  repository: `LEARNINGS.md` by its diff, its header — its `updated:` date aside —, titles and format comment, not its
  entries) — other than step 3's own commit of `CHANGELOG.md`, if the project keeps one
  (`git diff --no-renames --name-only <tip>..HEAD`): the review did not see it — run it
  again on the new tip;
- a HIGH or CRITICAL finding is open, or a MEDIUM one is neither resolved nor accepted in
  `STATE.md` with its reason — where `STATE.md` stays a template, in the closing note's gate
  section with its IMP (the framework's `CONTRIBUTING.md`).

Under the gate the base too, here, before step 2 computes a version and step 3 commits it:
`git merge-base --is-ancestor origin/<integration> HEAD` (without a remote, `<integration>`)
must succeed. Otherwise the integration branch moved since the branch was based, and step 4's
rebase would replay the reviewed commits as new ones — STOP: rebase the branch, and review
its new tip. It reads `origin/<integration>` as the last fetch recorded it — the agent fetches
nothing —: a move after that fetch is block 1's to stop, its fetch and its test of the base
inside the chain.

Where the project merges by Pull Request (the answer **Merge** in `CLAUDE.md`), the same
check runs when the agent prepares the PR — its description, a push it prints —, and the
note's line goes in the PR's description; a PR the user pushes and opens without the agent
skips it. The check reads what the note records: it is the agent's discipline, not an
enforcement — a merge made outside this command skips it (docs/03).

Claude Code **does not push and does not merge** — that is a human action (docs/04,
*Execution boundary and blocks for the user*). Here it COLLECTS the state with read-only commands
and PRODUCES two blocks of exact commands, ready to paste. Run ONLY the read commands of
steps 1-2, the CHANGELOG update of step 3 if the project keeps one (a local commit) and
the read-only computations of step 4, its failure path included (*When the user reports a
failed check*); everything else must be PRINTED, not executed.

The branch placeholders `<integration>` and `<stable>` stand for the names step 1's line
records — the ROLES of docs/04 —, and the agent substitutes them in what it prints, as it
does every placeholder of the blocks: setup answers that line only, and a project that
replaced them throughout has nothing left to substitute. Where the two roles are one branch
(trunk-based, docs/04, *Branching model*), the tag goes on that branch in both regimes:
neither step 2's post-1.0 rule nor the release variant below applies.

## 1. Collect the state (read-only)
- Current branch (feature): `git branch --show-current`.
- Integration branch `<integration>` and stable branch `<stable>`: they are the ROLES
  of docs/04 (example defaults `develop`/`main`; actual names
  `main` and `main`: trunk-based, the two roles are one branch — CLAUDE.md, **Branches**). Replace the placeholders with the project's real names.
- Branch commits not yet in the integration branch: `git log --oneline origin/<integration>..HEAD`
  (fallback without a remote: `<integration>..HEAD`).
- Current version and distance: `git describe --tags --long` (if no tags exist,
  start from `v0.0.0`).
- Guard on the BASE: `git describe --tags` also accepts lightweight tags and
  non-SemVer names (typical of a history inherited from a graft onto an existing
  repo). If the base tag is not in the `vX.Y.Z` format, STOP and flag it: the
  versioning base must be decided with the user (typical candidate: the highest
  SemVer tag, `git tag --list 'v*' --sort=-v:refname | head -1`).

## 2. Compute the bump and the next version
Apply the *Versioning* rules of docs/04 to the branch's set of commits:
- the bump is the HIGHEST among those of the commits: `feat`→MINOR, `fix`→PATCH,
  breaking (`type!`/`BREAKING CHANGE:`)→MAJOR;
- then weigh the CONTENT, which decides where the types undersell it (docs/04, *Versioning*,
  "The type suggests; the content decides"): a new rule, check or command in the files the
  project ships is a MINOR even under a `docs` or `chore` type, a change that breaks the
  public contract a MAJOR whatever its type. State the bump above the blocks with its
  reasoning — the commits and the content that decide it; if the request that opened the
  deliverable named an expected bump, name it too, and where the two differ say so and wait
  for the user's confirmation before step 3's commit;
- if there are only `refactor`/`perf`/`test`/`docs`/`build`/`ci`/`chore` or
  memory/doc-only commits, and the content weighed above brings nothing more → **no tag**
  (it is internal work, not a release: state it explicitly above the blocks and omit the
  tag commands) — EXCEPT in a project whose
  documentation is the product (docs/04, *Versioning*, "When the documentation IS the
  product"): there a change to the files it ships is a release, at least a PATCH whatever
  the commit types — a MINOR or a MAJOR by its content, as the bullet above says —, and
  only a change confined to its own memory or to files
  it does not ship is no tag;
- respect the regime: **pre-1.0** (`0.y.z`) tags on the integration branch
  (`<integration>`); **post-1.0** the feature→`<integration>` merge is NOT tagged — the
  tag comes at the `<integration>`→`<stable>` release (see the note at the bottom).
  Compute the next version from step 1's `git describe`.

## 3. Update the CHANGELOG (if the project keeps one)

If a `CHANGELOG.md` exists at the root (Keep a Changelog format):
- bump = "no tag" → do NOT touch it (internal work is not a release);
- otherwise: move the content of `## [Unreleased]` under a new entry
  `## [X.Y.Z] — YYYY-MM-DD` (version computed at step 2, today's date),
  integrating it with what emerges from the branch commits, and COMMIT on the feature
  branch BEFORE printing the blocks: this way the changelog goes into the merge. Under the
  gate the entry's text is the one the review read: written in `[Unreleased]` before the
  review, moved here under its heading, and nothing added that the review has not seen.

## 4. Print the READY FOR INTEGRATION blocks — two, never one
Two copyable code blocks, with the placeholders replaced by the real computed values,
and between them ONE line of plain text. Do NOT run them. They are two because a pause
written as a comment inside a copyable block is not a pause: pasted whole, the push runs
before anyone has read the checks. Block 1 touches only LOCAL history and ends with the
checks; block 2 publishes (docs/04, "Execution boundary and blocks for the user").

How the blocks are written, because they are pasted whole:
- **No comment lines inside them.** In zsh with its default options a `#` at the prompt
  is a command, not a comment (`command not found: #`), and inside a chain it breaks the
  chain. Every explanation goes in the text around the blocks.
- **The constructive lines are ONE chain** (each line ends with `&&`, which continues the
  command in bash and zsh): after a failure — a rebase conflict, a refused checkout or
  merge, a tag that already exists — nothing else runs, and no tag lands on the wrong
  commit.
- **Every check prints a fixed line when it passes** (`tag on <integration>: OK`,
  `count: OK (<N>)`, `signature: OK`), whatever language git or gpg answer in; the
  user looks for those lines, not for a reading of the output.
- **A free text in single quotes.** The merge header and the tag's summary go in single
  quotes, with no `'` inside: in double quotes the user's shell would run a backticked word
  or a `$(…)` of the text. A branch name goes in unquoted: one outside `[A-Za-z0-9._/-]` is a
  STOP.
- **No tag the block does not name.** Every push carries `--no-follow-tags`: a
  `push.followTags` in the user's configuration would publish, besides, every local
  annotated tag on the commits it pushes.

First compute, read-only:
- `<tip>` = `git rev-parse <feature>`, the full sha the gate's check and these computations
  ran on, and `<base>` = `git rev-parse origin/<integration>`: block 1 refuses another tip,
  and a rebase onto another base. Under the gate, `git merge-base --is-ancestor <base> <tip>`
  must succeed: otherwise the integration branch moved since the branch was based, and the
  rebase would replay the reviewed commits as new ones — STOP: rebase the branch, and review
  its new tip;
- `N` = `git rev-list --count origin/<integration>..<feature>` + 1 (fallback without a
  remote: `<integration>..<feature>`): the branch's commits plus the merge commit — what
  `origin/<integration>..<integration>` holds after the merge;
- the tag is free: `git rev-parse -q --verify refs/tags/v<X.Y.Z>` prints nothing. If it
  prints a sha, the version is taken: if it is this deliverable's own tag, left by an
  earlier paste of block 1 (it points at the `--no-ff` merge of `<feature>` on
  `<integration>`), print only block 1's checks and block 2; otherwise STOP and report
  it;
- SIGNED = `git config --type=bool --get tag.gpgSign` prints `true` (the repository's
  config or the global one). Then `git tag -a` signs the tag by itself, and block 1
  verifies it. Otherwise leave out the signature line: signing stays optional, and a
  project that does not sign sees no check.

Block 1 — local only: the feature at `<tip>`, the rebase, the merge (`--no-ff`, with a
valid conventional type, never `merge:`), the annotated tag with the computed bump (its
`-m` short, pure ASCII, in single quotes), then the checks — the tag on the integration
tip, the signature (ONLY if SIGNED), the commits about to become public, their count:
```
git checkout <feature> &&
test "$(git rev-parse HEAD)" = <tip> &&
git fetch origin &&
test "$(git rev-parse origin/<integration>)" = <base> &&
git rebase origin/<integration> &&
git checkout <integration> &&
git merge --ff-only origin/<integration> &&
git merge --no-ff <feature> -m '<type>(<scope>): merge <feature> into <integration>' &&
git tag -a v<X.Y.Z> -m 'v<X.Y.Z> - <deliverable summary>' &&
echo "block 1: merged and tagged"
git rev-parse -q --verify 'v<X.Y.Z>^{commit}' >/dev/null && test "$(git rev-parse 'v<X.Y.Z>^{commit}')" = "$(git rev-parse <integration>)" && echo "tag on <integration>: OK"
git tag -v v<X.Y.Z> && echo "signature: OK"
git --no-pager log --oneline origin/<integration>..<integration>
test "$(git rev-list --count origin/<integration>..<integration>)" = <N> && echo "count: OK (<N>)"
```

Then the line, as plain text OUTSIDE any code block, with the real values:

> Copy block 2 only if block 1 printed `block 1: merged and tagged`, `tag on <integration>:
> OK`, `count: OK (<N>)` and `signature: OK` (the last only if SIGNED). If any is
> missing, do not publish: report which line is missing — the repair comes then, from the
> state it finds, and a destructive line only if that state needs one.

Block 2 — publication, YOU run it: the branch and the tag in ONE atomic push — the remote
takes both or neither, so a tag never goes public on a commit the remote branch lacks —
then, only after the push succeeded, the safe deletion (`-d`, never `-D`) of the merged
feature branch:
```
git push --atomic --no-follow-tags origin <integration> v<X.Y.Z> &&
git branch -d <feature>
```

With "no tag": block 1 without the `git tag -a` line, its marker `block 1: merged`, and
neither the tag nor the signature check; block 2 `git push --no-follow-tags origin
<integration> && git branch -d <feature>`; the line names the marker and the count.
### When the user reports a failed check
The blocks above hold no destructive line, not even in a block of its own under its
condition: a condition written above a copyable block is not a condition — pasted out of
inertia, the block runs (docs/04, "Execution boundary and blocks for the user"). A recovery
block is produced here only: after the user reports that block 1 did not print one of its
lines, and once read-only commands have shown the state it repairs — `git log --oneline -3`
on the integration branch, `git rev-parse -q --verify 'refs/tags/v<X.Y.Z>^{commit}'`, and
`git ls-remote --tags origin v<X.Y.Z>`, which tells whether the tag is published.

If (and ONLY if) the tag exists but `tag on <integration>: OK` did not appear — a tag
left by an earlier, failed paste — ALSO print this recovery block, SEPARATE from the ones
above — alone, never beside blocks 1 and 2, which come again once the repair is done —,
and only while that tag is local: `git ls-remote` printed nothing. A tag already
published is never deleted, whatever it points at; nor is a sound one.
```
git tag -d v<X.Y.Z>
```
Then repair what failed and run `/fw:integrate` again. If `signature: OK` does not appear,
the tag is not published either: find out why first — an SSH signature, for one,
verifies only with `gpg.ssh.allowedSignersFile` configured.

## 5. Final verification (print it as a checklist)
- the security gate's line of the note that closes the deliverable was read before the
  blocks, and holds: a verdict with its reason, under the gate `/fw:security-review` at a
  tip no later commit of a shipped file follows, step 3's own commit aside, and the base an
  ancestor of that tip, checked before step 2; block 1
  opens on `<tip>` and rebases onto `<base>` only;
- the `-m` texts in single quotes with no `'` inside, the branch names within
  `[A-Za-z0-9._/-]`, every push with `--no-follow-tags`;
- the merge commit header is within the commit-linter limit: **100 characters**
  (conventional default, not overridden in `commitlint.config.cjs`);
- the merge commit type is a valid type (`feat`/`fix`/...), NEVER `merge:`;
- the tag version is consistent with the computed bump and with `git describe`, and
  the tag is free; the bump's reasoning stands above the blocks, with the user's
  confirmation where it differs from the bump the request expected;
- the git arguments use **normal spaces** and ASCII hyphens: no non-breaking/unicode
  spaces nor "long" dashes copied from an editor — a `--no-ff` with a wrong character
  fails obscurely;
- no comment line inside the blocks; block 1's constructive lines form one `&&` chain
  ending with its marker;
- block 1 is local only and ends with the checks: the tag on the integration tip, the
  signature only when SIGNED, the log of `origin/<integration>..<integration>` (what
  becomes public) and its count against `N`, each printing its fixed line;
- block 2 holds only the atomic push and the branch deletion, and the line before it,
  outside the blocks, names every line block 1 must have printed;
- no destructive line in the printed blocks, not even in a block of its own: a recovery
  block comes only from step 4's failure path, after the user reports a failed check
  (docs/04, "Execution boundary and blocks for the user").

## Release variant (1.0.0 and post-1.0)
For the `<integration>`→`<stable>` promotion the two blocks are the same, on the stable
branch: block 1 checks out `<stable>`, fetches, merges `--ff-only origin/<stable>` and
then `--no-ff <integration>`, and tags (`v1.0.0` or the MAJOR/MINOR/PATCH bump) on
`<stable>` — see *Versioning* in docs/04; its checks look at `<stable>`, with `N` =
`git rev-list --count origin/<stable>..<integration>` + 1. Block 2 is
`git push --atomic --no-follow-tags origin <stable> v<X.Y.Z>` alone: the integration branch is never
deleted.

Do NOT run push/merge/tag: the blocks are for the user. The merge happens after the
checkpoint, outside the session: until the next deliverable the memory records the state
that awaits the blocks, never a merge not yet run. The next deliverable's first
`/fw:checkpoint` reconciles `STATE.md` and the active branches with what the user ran — not a
commit of its own after the merge, which would be one more to push.
