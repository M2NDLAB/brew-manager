#!/usr/bin/env bash
# ============================================================================
# reset-task: discard ONLY the uncommitted work of the last task
#
# Unlike a branch reset, this one is SURGICAL: it throws away only the changes
# not yet committed (the half-done task interrupted by a stop/crash) and
# PRESERVES every commit of the previous tasks and the branch. It is the correct
# cleanup for the task planning protocol (.claude/docs/01-task-planning.md).
#
# Usage:  ./scripts/reset-task.sh          # show what it would discard and ask
#         ./scripts/reset-task.sh --yes    # discard without asking (automation)
# ============================================================================
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

AUTO="${1:-}"
BRANCH=$(git branch --show-current)

# Guard 1: never operate on shared/protected branches.
# brew-manager is trunk-based on main; "dev" stays protected because it exists as a
# historical remote branch. Override via env, e.g.
#   PROTECTED_BRANCHES="main trunk" ./scripts/reset-task.sh
PROTECTED_BRANCHES="${PROTECTED_BRANCHES:-main dev}"
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

git restore . 2>/dev/null || true
git restore --staged . 2>/dev/null || true
git clean -fd -q

echo "✅ Half-done task discarded. Branch '$BRANCH' intact up to the last commit."
echo "   git log: $(git log --oneline -1)"
echo "→ Resume by re-running the same prompt: the docs/01 protocol will restart"
echo "  from the first unticked task in the plan (.claude/memory/plans/)."
