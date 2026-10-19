#!/usr/bin/env bash
# ============================================================================
# reset-task: discard ONLY the uncommitted work of the last task
#
# Unlike a branch reset, this one is SURGICAL: it throws away only the changes
# not yet committed, staged or not (the half-done task interrupted by a stop/crash),
# and PRESERVES every commit of the previous tasks and the branch. It is the correct
# cleanup for the task planning protocol (.claude/docs/01-task-planning.md).
#
# Usage:  make reset-task          # the project's protected branches (Makefile); asks
#         make reset-task YES=1    # same, without asking: the user's, never an agent's
#         ./scripts/reset-task.sh  # direct: PROTECTED_BRANCHES from the environment,
#                                  # else main + develop, with a warning; asks
# Self-test: scripts/test-reset-task.sh.
# Its limits: a merge, rebase or cherry-pick in progress keeps its state through the
# restore, and on a detached HEAD the guard below has no branch to compare — settle
# those by hand first.
# ============================================================================
set -uo pipefail
# Two steps: in bash 3.2, `cd ""` succeeds and stays put, so outside a repository the
# one-line form went on as if inside one.
top="$(git rev-parse --show-toplevel)" || exit 1
cd "$top" || exit 1

AUTO="${1:-}"
BRANCH=$(git branch --show-current)

# Guard 1: never operate on shared/protected branches.
# The list is the PROJECT's answer and lives in the Makefile (PROTECTED_BRANCHES, the
# setup slot of the reset-task target), so this script stays method — identical in every
# project. Run directly without it, the script falls back to the example defaults and
# says so.
# Unattended (--yes), nobody would read that warning: refuse instead of guessing.
if [ -z "${PROTECTED_BRANCHES:-}" ]; then
  if [ "$AUTO" = "--yes" ]; then
    echo "❌ PROTECTED_BRANCHES is not set: refusing --yes with default protected branches."
    echo "   The project's list is in the Makefile: run 'make reset-task'."
    exit 1
  fi
  PROTECTED_BRANCHES="main develop"
  echo "⚠ PROTECTED_BRANCHES is not set: using the defaults 'main develop'. The project's list is in the Makefile: run 'make reset-task'."
fi
for b in $PROTECTED_BRANCHES; do
  if [ "$BRANCH" = "$b" ]; then
    echo "❌ You are on '$BRANCH' (protected branch). reset-task only operates on feature branches."
    echo "   If '$BRANCH' is dirty, inspect it by hand with 'git status'."
    exit 1
  fi
done

# Nothing to do?
if git diff --quiet && git diff --cached --quiet && [ -z "$(git clean -nd)" ]; then
  echo "✓ Working tree already clean on '$BRANCH'. No half-done task to discard."
  echo "  Last commit: $(git log --oneline -1)"
  exit 0
fi

echo "→ Branch: $BRANCH"
echo "→ The COMMITS of the completed tasks are safe and will NOT be touched."
echo "→ ONLY this uncommitted work would be discarded (the interrupted task):"
echo "---- modified/staged files ----"
git status -s
echo "---- untracked files that would be removed ----"
git clean -nd
echo "--------------------------------"
echo "Last commit (the one you will resume from): $(git log --oneline -1)"

if [ "$AUTO" != "--yes" ]; then
  printf "Proceed to discard ONLY the uncommitted work? [y/N] "
  read -r ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "Cancelled. Nothing touched."; exit 0; }
fi

head_before="$(git rev-parse -q --verify HEAD)"
# The index AND the working tree from HEAD, in one step: `git restore .` restores the working
# tree from the INDEX, so a change only staged survived it — as an unstaged one, once the
# index was reset after it. Each step's failure is reported, never swallowed.
if ! git restore --source=HEAD --staged --worktree -- .; then
  echo "❌ git restore failed: the half-done task is NOT discarded. See 'git status'."
  exit 1
fi
if ! git clean -fd -q; then
  echo "❌ git clean failed: untracked files may remain. See 'git status'."
  exit 1
fi
# "Discarded" only on a datum: the tree reads clean and HEAD has not moved.
if ! { git diff --quiet && git diff --cached --quiet && [ -z "$(git clean -nd)" ]; } \
  || [ "$(git rev-parse -q --verify HEAD)" != "$head_before" ]; then
  echo "❌ Work is still left after the discard:"
  git status -s
  exit 1
fi

echo "✅ Half-done task discarded. Branch '$BRANCH' intact up to the last commit."
echo "   git log: $(git log --oneline -1)"
echo "→ Resume by re-running the same prompt: the docs/01 protocol will restart"
echo "  from the first unticked task in the plan (.claude/memory/plans/)."
