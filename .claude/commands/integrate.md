---
description: Generates the "READY FOR INTEGRATION" block — paste-ready commands for merge + tag, without running them
---
At the end of a deliverable, prepare the READY FOR INTEGRATION block for: $ARGUMENTS
(if empty: for the current branch).

Claude Code **does not push and does not merge** — that is a human action (see
@.claude/docs/04-git-workflow.md). Here it COLLECTS the state with read-only commands
and PRODUCES a block of exact commands, ready to paste. Run ONLY the read commands of
steps 1-2 and the CHANGELOG update of step 3 (local commit); everything else must be
PRINTED, not executed.

## 1. Collect the state (read-only)
- Current branch (feature): `git branch --show-current`.
- Integration branch `<integration>` and stable branch `<stable>`: they are the ROLES
  of docs/04 (example defaults `develop`/`main`; actual names
  [TO BE DEFINED AT SETUP]). Replace the placeholders with the project's real names.
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
- if there are only `refactor`/`perf`/`test`/`docs`/`build`/`ci`/`chore` or
  memory/doc-only commits → **no tag** (it is internal work, not a release: state it
  explicitly in the block and omit the tag commands);
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
  branch BEFORE printing the block: this way the changelog goes into the merge.

## 4. Print the READY FOR INTEGRATION block
A single copyable code block, with the placeholders already replaced by the real
computed values. Do NOT run it:
```
# 1. rebase the feature onto the updated integration branch (conflicts are resolved HERE)
git checkout <feature>
git fetch origin
git rebase origin/<integration>

# 2. bring the local integration branch level with the remote, then explicit non-fast-forward merge
git checkout <integration>
git merge --ff-only origin/<integration>
git merge --no-ff <feature> -m "<type>(<scope>): merge <feature> into <integration>"

# 3. annotated tag with the computed bump   (if "no tag": omit this step)
#    type the -m by hand, short and pure ASCII (no pasted em-dashes/accents)
git tag -a v<X.Y.Z> -m "v<X.Y.Z> - <deliverable summary>"

# 4. verify BEFORE the push: the tag exists and is sound, and you publish only the expected commits
git rev-parse v<X.Y.Z>
git log --oneline origin/<integration>..<integration>

# 5. explicit push of branch and tag (YOU run it: it is the human action)
git push origin <integration>
git push origin v<X.Y.Z>

# 6. delete the now-merged feature branch (safe: -d, never -D)
git branch -d <feature>
```

If (and ONLY if) `git rev-parse v<X.Y.Z>` fails — corrupted tag, typically from a
copy-paste — ALSO print this recovery block, SEPARATE from the one above
(docs/04, "Execution boundary and blocks for the user"): never `tag -d` on a sound tag.
```
# ONLY if 'git rev-parse v<X.Y.Z>' failed at step 4:
git tag -d v<X.Y.Z>
# then recreate the tag by typing it by hand (step 3) and re-verify (step 4)
```

## 5. Final verification (print it as a checklist)
- the merge commit header is within the commit-linter limit: **100 characters**
  (conventional default, not overridden in `commitlint.config.cjs`);
- the merge commit type is a valid type (`feat`/`fix`/...), NEVER `merge:`;
- the tag version is consistent with the computed bump and with `git describe`;
- the git arguments use **normal spaces** and ASCII hyphens: no non-breaking/unicode
  spaces nor "long" dashes copied from an editor — a `--no-ff` with a wrong character
  fails obscurely;
- the block contains the two PRE-push checks: `git rev-parse` of the tag and
  `git log origin/<integration>..<integration>` (what becomes public);
- every destructive command (e.g. `tag -d`) is in a SEPARATE block with its
  condition, never inline (docs/04, "Execution boundary and blocks for the user").

## Release variant (1.0.0 and post-1.0)
For the `<integration>`→`<stable>` promotion the sequence is the same but on the
stable branch, and the tag (`v1.0.0` or the MAJOR/MINOR/PATCH bump) goes on
`<stable>` after the release merge — see *Versioning* in docs/04.

Do NOT run push/merge/tag: the block is for the user. Once integration has happened,
the user can run `/checkpoint` to reconcile `STATE.md` and the active branches.
