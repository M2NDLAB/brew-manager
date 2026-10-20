#!/usr/bin/env bash
# repo-snapshot.sh — a fingerprint of a repository's shared state, compared BEFORE and
# AFTER delegating work to agents (docs/04, "Delegated agents and the shared working
# tree").
#
# It prints HEAD, the checked-out branch, every ref, the stash, the worktrees and the
# untracked files. HEAD and branch alone are not enough: an agent that created or moved
# another branch, stashed, left a worktree behind or wrote a file into the tree
# (2026-09-24: an archive left in the repo root) leaves HEAD where it was.
# Not covered, by design: edits to TRACKED files (look at `git diff` for those) and a
# branch moved and moved back (only its reflog would show it).
#
# Read-only by construction: every git call runs with --no-optional-locks, so taking the
# snapshot never rewrites .git/index (a plain `git status` would).
#
# Usage, from the repository root (or pass the repository's path as $1):
#   before="$(mktemp)"; scripts/repo-snapshot.sh > "${before}"
#   ... the delegated agents run ...
#   scripts/repo-snapshot.sh | diff "${before}" - && echo "repository unchanged"
# A non-empty diff means STOP: report it to the user; do not repair it on your own.
# Self-test: scripts/test-repo-snapshot.sh.
set -euo pipefail

repo="${1:-.}"
g() { git -C "${repo}" --no-optional-locks "$@"; }

g rev-parse --git-dir >/dev/null # outside a repository: fail loudly, print nothing

echo "HEAD $(g rev-parse --verify --quiet HEAD || echo '(no commit yet)')"
echo "branch $(g symbolic-ref --quiet --short HEAD || echo '(detached)')"
echo "--- refs"
g for-each-ref --format='%(objectname) %(refname)'
echo "--- stash"
g stash list
echo "--- worktrees"
g worktree list --porcelain
echo "--- untracked"
g ls-files --others --exclude-standard
