#!/usr/bin/env bash
# Self-test of scripts/reset-task.sh (docs/01, "Cleanup of an interrupted task"). Four cases:
#   1. on a feature branch, unattended, every kind of work not yet committed is discarded — a
#      change only staged, a staged change edited again, a change in the working tree, an
#      untracked file —, the commits and the branch untouched, and the run says so;
#   2. a restore git refuses (another process holds the index's lock): a failure, and no
#      word of a discard;
#   3. outside a repository: a failure, and no word of a discard;
#   4. under core.autocrlf true, a configuration the users have (Git for Windows sets it):
#      the same discard, the tree clean as git reads it — once the setting has taken hold.
#
# HERMETIC: throwaway repositories under mktemp. reset-task.sh discards work in the repository
# it runs in, so every run first proves its directory is a throwaway one, by its root commit.
set -euo pipefail

# Hermetic against the user's own git configuration and the caller's git environment, as the
# other self-tests are: run from a git hook, GIT_DIR or GIT_INDEX_FILE would point the
# throwaway commands at the REAL repository.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
unset $(git rev-parse --local-env-vars) GIT_TEMPLATE_DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESET="${SCRIPT_DIR}/reset-task.sh"
DONE_LINE="Half-done task discarded"
MARKER="chore: the throwaway repository of test-reset-task"

fail() {
  echo "FAIL (reset-task): $*" >&2
  exit 1
}

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT
# git never climbs above the throwaway directory looking for a repository.
export GIT_CEILING_DIRECTORIES="${workdir}"

# make_repo <dir>: a throwaway repository whose root commit carries MARKER, on a feature
# branch with one completed task.
make_repo() {
  local r="$1" f
  git init -q "${r}"
  git -C "${r}" config user.name self-test
  git -C "${r}" config user.email self-test@example.invalid
  for f in staged edited both; do printf 'A\n' > "${r}/${f}.txt"; done
  git -C "${r}" add .
  git -C "${r}" commit -q -m "${MARKER}"
  git -C "${r}" branch -M main
  git -C "${r}" switch -q -c feat/task
  printf 'T\n' > "${r}/task.txt"
  git -C "${r}" add task.txt
  git -C "${r}" commit -q -m "feat: a completed task"
}

# dirty <dir>: the interrupted task — every kind of work not yet committed.
dirty() {
  local r="$1"
  printf 'B\n' > "${r}/staged.txt" && git -C "${r}" add staged.txt
  printf 'B\n' > "${r}/edited.txt"
  printf 'B\n' > "${r}/both.txt" && git -C "${r}" add both.txt && printf 'C\n' > "${r}/both.txt"
  printf 'x\n' > "${r}/untracked.txt"
}

# run <dir>: reset-task.sh unattended inside <dir>, once <dir> proves to be a throwaway
# repository; its output and exit status land in OUT and RC.
run() {
  local r="$1" root
  root="$(git -C "${r}" rev-list --max-parents=0 HEAD)" || fail "not a repository: ${r}"
  [[ "$(git -C "${r}" log -1 --format=%s "${root}")" == "${MARKER}" ]] \
    || fail "refusing to run reset-task.sh outside a throwaway repository: ${r}"
  set +e
  OUT="$(cd "${r}" && PROTECTED_BRANCHES="main" bash "${RESET}" --yes 2>&1)"
  RC=$?
  set -e
}

# discarded <dir> <label>: the tree clean as git reads it, the commits and the branch where
# they were, and the run saying so.
discarded() {
  local r="$1" label="$2" left
  [[ ${RC} -eq 0 ]] || fail "${label}: the run exited ${RC}: ${OUT}"
  left="$(git -C "${r}" status --porcelain)"
  [[ -z "${left}" ]] || fail "${label}: work left after the discard: $(tr '\n' ' ' <<<"${left}")"
  [[ ! -e "${r}/untracked.txt" ]] || fail "${label}: the untracked file survived the discard"
  [[ "$(git -C "${r}" log -1 --format=%s)" == "feat: a completed task" \
    && "$(git -C "${r}" branch --show-current)" == "feat/task" ]] \
    || fail "${label}: a commit or the branch moved"
  grep -q "${DONE_LINE}" <<<"${OUT}" || fail "${label}: the run did not say the task is discarded: ${OUT}"
}

# --- Case 1 — every kind of uncommitted work is discarded -------------------------------------
repo="${workdir}/repo"
make_repo "${repo}"
dirty "${repo}"
run "${repo}"
discarded "${repo}" "case 1"
for f in staged edited both; do
  [[ "$(cat "${repo}/${f}.txt")" == "A" ]] \
    || fail "case 1: ${f}.txt holds '$(cat "${repo}/${f}.txt")' after the discard, not the committed A"
done

# --- Case 2 — a restore git refuses is a failure, never a discard ------------------------------
printf 'B\n' > "${repo}/edited.txt"
: > "${repo}/.git/index.lock" # git writes no index while another process holds its lock
run "${repo}"
rm -f "${repo}/.git/index.lock"
[[ ${RC} -ne 0 ]] || fail "case 2: a restore git refused (index.lock held) exited 0: ${OUT}"
! grep -q "${DONE_LINE}" <<<"${OUT}" || fail "case 2: a restore git refused said the task is discarded: ${OUT}"
[[ "$(cat "${repo}/edited.txt")" == "B" ]] || fail "control: the refused restore changed edited.txt"

# --- Case 3 — outside a repository ------------------------------------------------------------
mkdir -p "${workdir}/not-a-repo"
set +e
OUT="$(cd "${workdir}/not-a-repo" && PROTECTED_BRANCHES="main" bash "${RESET}" --yes 2>&1)"
RC=$?
set -e
[[ ${RC} -ne 0 ]] || fail "case 3: outside a repository it exited 0: ${OUT}"
! grep -q "${DONE_LINE}" <<<"${OUT}" || fail "case 3: outside a repository it said the task is discarded: ${OUT}"

# --- Case 4 — under core.autocrlf true ----------------------------------------------------------
crlf="${workdir}/crlf"
make_repo "${crlf}"
git -C "${crlf}" config core.autocrlf true
git -C "${crlf}" config core.safecrlf false # no warning for each file git will convert
dirty "${crlf}"
run "${crlf}"
discarded "${crlf}" "case 4"
# The datum reached the program: git restored edited.txt with CRLF — the setting took hold.
# git counts the line ends; a grep for a carriage return does not see them on Git Bash.
git -C "${crlf}" ls-files --eol -- edited.txt | grep -q 'w/crlf' \
  || fail "case 4: core.autocrlf true did not take hold — edited.txt was not restored with CRLF"

echo "PASS (reset-task): a change only staged, a staged change edited again, a change in the working tree and an untracked file discarded, commits and branch untouched — under core.autocrlf true too; a restore git refuses and a run outside a repository reported as failures, never as a discard."
