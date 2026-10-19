#!/usr/bin/env bash
# Self-test of scripts/repo-snapshot.sh (docs/04, "Delegated agents and the shared
# working tree").
#
# Contract under test: (1) taking the snapshot is READ-ONLY — it never rewrites
# .git/index, while a plain `git status` does (the control proves the check is not
# vacuous); (2) every trace an agent could leave in the shared repository changes the
# fingerprint: an untracked file, a new branch, a new commit, a switched branch, a tag,
# a stash, a worktree; (3) undoing the change gives back the same fingerprint;
# (4) outside a repository it fails loudly and prints nothing.
#
# HERMETIC: a throwaway repository under mktemp; nothing outside it is touched.
set -euo pipefail

# Hermetic against the user's own git configuration: a global tag.gpgSign or
# commit.gpgSign, for one, would make the throwaway repository's tags and commits ask for
# a signature (git 2.32+ reads GIT_CONFIG_GLOBAL; older ones ignore it). And against the
# caller's git environment: run from a git hook, GIT_DIR or GIT_INDEX_FILE would point the
# throwaway commands at the REAL repository.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
unset $(git rev-parse --local-env-vars) GIT_TEMPLATE_DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAPSHOT="${SCRIPT_DIR}/repo-snapshot.sh"

fail() {
  echo "FAIL (repo snapshot): $*" >&2
  exit 1
}

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

repo="${workdir}/repo"
git init -q "${repo}"
g() { git -C "${repo}" "$@"; }
g config user.name self-test
g config user.email self-test@example.invalid
echo one > "${repo}/tracked.txt"
g add tracked.txt
g commit -q -m "chore: base"

snap() { bash "${SNAPSHOT}" "${repo}"; }
base="$(snap)"
[[ "$(snap)" == "${base}" ]] || fail "two snapshots of an unchanged repository differ"

# --- 1. Read-only, with a control ------------------------------------------------------------
index_sum() { cksum < "${repo}/.git/index"; }
touch -t 202001010000 "${repo}/tracked.txt" # new mtime, same content: the index is now stale
before="$(index_sum)"
snap >/dev/null
[[ "$(index_sum)" == "${before}" ]] || fail "taking the snapshot rewrote .git/index"
g status >/dev/null
[[ "$(index_sum)" != "${before}" ]] \
  || fail "control: a plain git status did not rewrite .git/index — the read-only check proves nothing"

# --- 2-3. Each trace changes the fingerprint; undoing it restores the fingerprint ------------
# detects <label> <change command> <undo command>
kinds=0
detects() {
  kinds=$((kinds + 1))
  eval "$2"
  [[ "$(snap)" != "${base}" ]] || fail "not detected: $1"
  eval "$3"
  [[ "$(snap)" == "${base}" ]] || fail "fingerprint not restored after undoing: $1"
}
detects "an untracked file"  'echo x > "${repo}/stray.tar"'          'rm "${repo}/stray.tar"'
detects "a new branch"       'g branch other'                         'g branch -q -d other'
detects "a new commit"       'g commit -q --allow-empty -m "chore: x"' 'g reset -q --soft HEAD~1'
detects "a switched branch"  'g switch -q -c side'                    'g switch -q - && g branch -q -d side'
detects "a tag"              'g tag v0.0.1'                           'g tag -d v0.0.1 >/dev/null'
detects "a stash"            'echo two > "${repo}/tracked.txt" && g stash push -q' 'g stash drop -q'
detects "a worktree"         'g worktree add -q --detach "${workdir}/wt"' 'g worktree remove "${workdir}/wt"'

# --- 4. Outside a repository: loud failure, empty output -------------------------------------
mkdir -p "${workdir}/not-a-repo"
set +e
out="$(bash "${SNAPSHOT}" "${workdir}/not-a-repo" 2>/dev/null)"
rc=$?
set -e
[[ ${rc} -ne 0 && -z "${out}" ]] || fail "outside a repository it must fail and print nothing (rc=${rc})"

echo "PASS (repo snapshot): read-only (control: plain status rewrites the index), ${kinds} kinds of trace detected and restored, loud outside a repository."
