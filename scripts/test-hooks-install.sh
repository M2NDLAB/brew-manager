#!/usr/bin/env bash
# Self-test of scripts/hooks-install.sh. Eight cases:
#   1. "dangling symlink + FORCE_OVERWRITE=1": a leftover link never aborts the install —
#      below; skipped, said aloud, where `ln -s` cannot make a dangling link (Git Bash);
#      the commit-msg hook it installs runs commitlint at the version
#      scripts/check-prerequisites.sh pins;
#   2. the generated pre-push is the push boundary (docs/04): a push launched with a Claude
#      Code session marker is REFUSED in every form, a push without markers (the human's
#      terminal) goes through — see "Case 2";
#   3. where the hooks land: the repository's common git directory, from a linked worktree
#      or from a subdirectory; outside any repository, or from a copy below the top level of
#      the repository it sits in, a refusal — see "Case 3";
#   4. the prerequisites: the install runs the prerequisite check first — a gitleaks that
#      does not start stops it before any hook is written; a make that does not start does
#      not, the hooks never run make; a commitlint pin that is not an exact version — 21,
#      a range npx would resolve to its newest 21.x — stops it too — see "Case 4";
#   5. the git gitleaks reads through the generated pre-commit: the colour off and each
#      textconv driver turned into `cat`, after the caller's own environment configuration,
#      which stays; a GIT_CONFIG_COUNT that is not a number stops the hook before gitleaks —
#      see "Case 5";
#   6. the files git shows as binary although they hold text, scanned apart: copied from the
#      index into a directory only the user can read, the project's gitleaks configuration
#      passed on, a file binary by its content left out, and the directory gone when the hook
#      ends — passing, refused, or stopped by a signal — see "Case 6";
#   7. a re-run: over its own hooks unchanged, nothing saved and nothing said; over a hook
#      that differs — an earlier release's, untouched by the user — a .bak of it, and a
#      message that says what was measured, a difference, not a local change; the reminder
#      to enable formatting while the slot is open, and none once a copy answers it — both
#      states built from the copy under test, which a project has answered — see "Case 7";
#   8. core.hooksPath set — a hook manager's, husky's for one: the install stops before
#      writing any hook, and its message says that such a manager sets it again at its next
#      run, so integrating the commands into it is the durable choice — see "Case 8" at the
#      end.
#
# Case 1.
# Defect (RED, before the fix): in the FORCE_OVERWRITE=1 branch, a pre-existing hook that is a
# DANGLING symlink (non-existent target) makes `cp -L "${target}" "${target}.bak"` fail
# (cp dereferences the link → target absent → error); under `set -euo pipefail` the script
# ABORTS with exit!=0 BEFORE the backup and the `rm`, diverging from the header comment that
# promises "we proceed: backup then removal". No data loss (a dangling link has no
# content), but the declared contract is violated and the error is cryptic.
#
# Expected (GREEN, after the fix): the script skips the vacuous backup with a dedicated warning,
# removes the link anyway and installs the generated hook, exiting 0.
#
# The test is HERMETIC: stubs for gitleaks/npx (the prerequisites are unrelated to the logic under
# test) and a throwaway git repo. It runs the REAL script end-to-end (smoke, not just the isolated unit).
set -euo pipefail

# Hermetic against the user's own git configuration: a global tag.gpgSign or
# commit.gpgSign, for one, would make the throwaway repository's tags and commits ask for
# a signature (git 2.32+ reads GIT_CONFIG_GLOBAL; older ones ignore it). And against the
# caller's git environment: run from a git hook, GIT_DIR or GIT_INDEX_FILE would point the
# throwaway commands at the REAL repository.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
unset $(git rev-parse --local-env-vars) GIT_TEMPLATE_DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_INSTALL="${SCRIPT_DIR}/hooks-install.sh"
# hooks-install.sh reads commitlint's pin from the prerequisite check, next to it in every
# copy of the framework's scripts/.
CHECK_PREREQ="${SCRIPT_DIR}/check-prerequisites.sh"

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

# --- Prerequisite stubs: they isolate the FORCE logic from the gitleaks/npx checks ----------
# Each answers its version command as the prerequisite check asks it, and does nothing else:
# gitleaks as its releases from 8.19.0 do — the check asks --version first.
stub_bin="${workdir}/bin"
mkdir -p "${stub_bin}"
printf '#!/usr/bin/env bash\ncase "${1:-}" in\n  --version) echo "gitleaks version 8.30.1" ;;\n  version) echo 8.30.1 ;;\nesac\nexit 0\n' > "${stub_bin}/gitleaks"
printf '#!/usr/bin/env bash\n[[ "${1:-}" == --version ]] && echo 10.9.2\nexit 0\n' > "${stub_bin}/npx"
chmod +x "${stub_bin}/gitleaks" "${stub_bin}/npx"
export PATH="${stub_bin}:${PATH}"

# --- Throwaway repo with a COPY of the script (REPO_ROOT derives from the script's location)
repo="${workdir}/repo"
mkdir -p "${repo}/scripts"
git init -q "${repo}"
cp "${HOOKS_INSTALL}" "${repo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${repo}/scripts/check-prerequisites.sh"

# --- Case 1 — a dangling symlink and FORCE_OVERWRITE=1 -------------------------------------
# Plant a DANGLING symlink as the pre-existing pre-commit hook. Git Bash cannot make one —
# `ln -s` to a missing target fails there (measured in the CI on Windows) —: the case is
# then SKIPPED, said aloud, and the install below still runs, for the cases after it.
dangling=yes
if ! ln -s "/path/that/does/not/exist/xyz" "${repo}/.git/hooks/pre-commit" 2>"${workdir}/ln.err"; then
  dangling=no
  echo "SKIP (dangling symlink): this platform cannot make a dangling symlink — $(head -n 1 "${workdir}/ln.err")"
elif [[ ! -L "${repo}/.git/hooks/pre-commit" || -e "${repo}/.git/hooks/pre-commit" ]]; then
  echo "SETUP FAILED: the dangling symlink was not created as expected" >&2
  exit 1
fi

# --- Run the script under test with FORCE_OVERWRITE=1 ---------------------------------------
set +e
FORCE_OVERWRITE=1 bash "${repo}/scripts/hooks-install.sh" >"${workdir}/out.log" 2>&1
rc=$?
set -e

fail() {
  echo "FAIL (dangling symlink): $1" >&2
  echo "--- script output (rc=${rc}) ---" >&2
  cat "${workdir}/out.log" >&2
  exit 1
}

# --- GREEN assertions -----------------------------------------------------------------------
target="${repo}/.git/hooks/pre-commit"
[[ ${rc} -eq 0 ]]      || fail "expected exit code 0, got ${rc} (did cp -L on the dangling link abort the script?)"
[[ ! -L "${target}" ]] || fail "the dangling symlink was not removed"
[[ -f "${target}" ]]   || fail "the generated hook was not installed in place of the link"
grep -q "Hook generated by scripts/hooks-install.sh" "${target}" \
                       || fail "the installed pre-commit is not the one generated by the framework"
[[ ! -e "${target}.bak" ]] \
                       || fail "a dangling link has no content: it must not create a vacuous .bak"
# The commit-msg hook runs commitlint's two packages at the pinned version, never npx's latest.
pin="$(bash "${CHECK_PREREQ}" --commitlint-version)"
grep -qF -- "--package @commitlint/cli@${pin} --package @commitlint/config-conventional@${pin}" \
  "${repo}/.git/hooks/commit-msg" || fail "the commit-msg hook does not run commitlint at the pin, ${pin}"

[[ ${dangling} == no ]] \
  || echo "PASS (dangling symlink): dangling + FORCE_OVERWRITE=1 → no abort, link removed, hook installed, no vacuous .bak."

# --- Case 2 — the pre-push push boundary --------------------------------------------------
# The pre-push installed above must refuse every push that carries a session marker
# (AGENT_GIT_BOUNDARY, or the CLAUDECODE fallback), whatever form launched it, and let a
# push without markers through. The remote is a LOCAL bare repo reached via file:// only
# (every other transport disabled): nothing ever leaves the machine. The test controls the
# markers explicitly, so it gives the same answer inside or outside a Claude Code session.
fail2() {
  echo "FAIL (push boundary): $1" >&2
  [[ -f "${workdir}/push.log" ]] && { echo "--- last push output ---" >&2; cat "${workdir}/push.log" >&2; }
  exit 1
}
pre_push="${repo}/.git/hooks/pre-push"
[[ -x "${pre_push}" ]] || fail2 "the pre-push hook was not installed (or is not executable)"
grep -q "Hook generated by scripts/hooks-install.sh" "${pre_push}" || fail2 "the installed pre-push is not the generated one"

remote="${workdir}/remote.git"
git init -q --bare "${remote}"
git -C "${repo}" config user.name self-test
git -C "${repo}" config user.email self-test@example.invalid
git -C "${repo}" config protocol.allow never
git -C "${repo}" config protocol.file.allow always
git -C "${repo}" remote add origin "file://${remote}"
git -C "${repo}" commit -q --allow-empty -m "chore: self-test commit"

landed() { git -C "${remote}" rev-parse -q --verify "refs/heads/$1" >/dev/null; }

# try_push <branch> <marker assignment, or ""> <form>: one push of a fresh branch, from a
# clean environment plus the marker under test.
try_push() {
  local branch="$1" marker="$2" form="$3"
  local -a cmd
  git -C "${repo}" branch "${branch}"
  case "${form}" in
    direct) cmd=(git push -q origin "${branch}") ;;
    dash-C) cmd=(git -C "${repo}" push -q origin "${branch}") ;;
    sh-c)   cmd=(sh -c "git push -q origin ${branch}") ;;
    script) printf 'git push -q origin %s\n' "${branch}" > "${workdir}/push.sh"; cmd=(sh "${workdir}/push.sh") ;;
  esac
  ( cd "${repo}" && env -u AGENT_GIT_BOUNDARY -u CLAUDECODE ${marker:+"${marker}"} "${cmd[@]}" ) \
    >"${workdir}/push.log" 2>&1 || true
}

for form in direct dash-C sh-c script; do
  try_push "agent-${form}" AGENT_GIT_BOUNDARY=1 "${form}"
  ! landed "agent-${form}" || fail2 "a push with AGENT_GIT_BOUNDARY=1 (${form}) reached the remote"
  grep -q "pre-push: REFUSED" "${workdir}/push.log" || fail2 "the ${form} push was not refused BY THE pre-push hook"
done
try_push claudecode-direct CLAUDECODE=1 direct
! landed claudecode-direct || fail2 "a push with only CLAUDECODE=1 (the fallback marker) reached the remote"
grep -q "pre-push: REFUSED" "${workdir}/push.log" || fail2 "the CLAUDECODE push was not refused BY THE pre-push hook"
try_push human-direct "" direct
landed human-direct || fail2 "a push WITHOUT markers (the human's terminal) was refused: the boundary blocks the human too"

# A project's own pre-push (e.g. git-lfs's) lives in pre-push.local: it runs, with git's
# stdin, after the check — for the human's push only. It records what it received.
cat > "${repo}/.git/hooks/pre-push.local" <<HOOK
#!/usr/bin/env bash
cat > "${workdir}/local-hook.ran"
HOOK
chmod +x "${repo}/.git/hooks/pre-push.local"
try_push agent-with-local AGENT_GIT_BOUNDARY=1 direct
[[ ! -e "${workdir}/local-hook.ran" ]] || fail2 "pre-push.local ran for an agent-session push (it must come AFTER the refusal)"
try_push human-with-local "" direct
landed human-with-local || fail2 "the human's push did not land with a pre-push.local present"
grep -q "refs/heads/human-with-local" "${workdir}/local-hook.ran" 2>/dev/null \
  || fail2 "pre-push.local did not run, or did not receive git's ref list on stdin"

echo "PASS (push boundary): pre-push refuses agent-session pushes (direct, -C, sh -c, script; CLAUDECODE fallback), lets the human's push through, and chains pre-push.local after the check."

# --- Case 3 — where the hooks land: the repository's COMMON git directory ------------------
# In a linked worktree `.git` is a FILE, and the hooks of every worktree live in the main
# repository's `.git/hooks` (git's common directory). The script must install there when it
# runs from a linked worktree — an upgrade on its own worktree, for one; must not create a
# stray `.git/hooks` under a working directory other than the repository root; and must
# refuse to run outside a repository instead of creating a `.git` there.
fail3() {
  echo "FAIL (hooks directory): $1" >&2
  [[ -f "${workdir}/out3.log" ]] && { echo "--- script output ---" >&2; cat "${workdir}/out3.log" >&2; }
  exit 1
}
# Keeps git from discovering a repository ABOVE the throwaway ones (case 3c).
export GIT_CEILING_DIRECTORIES="${workdir}"
wt_repo="${workdir}/wt-repo"
git init -q "${wt_repo}"
git -C "${wt_repo}" -c user.name=self-test -c user.email=self-test@example.invalid \
  commit -q --allow-empty -m "chore: self-test commit"
git -C "${wt_repo}" worktree add -q --detach "${workdir}/wt"
mkdir -p "${workdir}/wt/scripts" "${wt_repo}/scripts"
cp "${HOOKS_INSTALL}" "${workdir}/wt/scripts/hooks-install.sh"
cp "${HOOKS_INSTALL}" "${wt_repo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${workdir}/wt/scripts/check-prerequisites.sh"
cp "${CHECK_PREREQ}" "${wt_repo}/scripts/check-prerequisites.sh"

# 3a. From a linked worktree: every hook the generator lists lands in the main repository's
# .git/hooks — the list read from the generator's own loop, so a hook added there is checked.
set +e
bash "${workdir}/wt/scripts/hooks-install.sh" >"${workdir}/out3.log" 2>&1
rc=$?
set -e
[[ ${rc} -eq 0 ]] || fail3 "from a linked worktree: expected exit 0, got ${rc}"
hooks="$(sed -n 's/^for hook in \(.*\); do$/\1/p' "${HOOKS_INSTALL}")"
[[ -n "${hooks}" ]] || fail3 "no hook list found in scripts/hooks-install.sh"
for hook in ${hooks}; do
  grep -qF "Hook generated by scripts/hooks-install.sh" "${wt_repo}/.git/hooks/${hook}" 2>/dev/null \
    || fail3 "from a linked worktree: ${hook} is not installed in the common hooks directory"
done
[[ -f "${workdir}/wt/.git" ]] || fail3 "from a linked worktree: the worktree's .git file was replaced"

# 3b. From a subdirectory of the repository: nothing created under the working directory.
set +e
( cd "${wt_repo}/scripts" && bash ./hooks-install.sh ) >"${workdir}/out3.log" 2>&1
rc=$?
set -e
[[ ${rc} -eq 0 ]] || fail3 "from a subdirectory: expected exit 0, got ${rc}"
[[ ! -e "${wt_repo}/scripts/.git" ]] || fail3 "from a subdirectory: a stray .git was created under the working directory"

# 3c. Outside any repository: a refusal that says why, and no .git created.
norepo="${workdir}/norepo"
mkdir -p "${norepo}/scripts"
cp "${HOOKS_INSTALL}" "${norepo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${norepo}/scripts/check-prerequisites.sh"
set +e
bash "${norepo}/scripts/hooks-install.sh" >"${workdir}/out3.log" 2>&1
rc=$?
set -e
[[ ${rc} -ne 0 ]] || fail3 "outside a repository: expected a refusal, got exit 0"
[[ ! -e "${norepo}/.git" ]] || fail3 "outside a repository: a stray .git was created"
grep -q "not inside a git repository" "${workdir}/out3.log" || fail3 "outside a repository: the refusal does not say why"

# 3d. A copy that is not at the top level of the repository it sits in (inside someone
# else's working tree): a refusal, and no hook installed into that repository.
nested="${wt_repo}/vendor/framework"
mkdir -p "${nested}/scripts"
cp "${HOOKS_INSTALL}" "${nested}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${nested}/scripts/check-prerequisites.sh"
rm -f "${wt_repo}/.git/hooks/pre-commit" "${wt_repo}/.git/hooks/commit-msg" "${wt_repo}/.git/hooks/pre-push"
set +e
bash "${nested}/scripts/hooks-install.sh" >"${workdir}/out3.log" 2>&1
rc=$?
set -e
[[ ${rc} -ne 0 ]] || fail3 "a copy below the top level: expected a refusal, got exit 0"
[[ ! -e "${wt_repo}/.git/hooks/pre-commit" ]] || fail3 "a copy below the top level: hooks were installed into the enclosing repository"
grep -q "not the top level of its git repository" "${workdir}/out3.log" || fail3 "a copy below the top level: the refusal does not say why"

echo "PASS (hooks directory): from a linked worktree the hooks land in the common .git/hooks; no stray .git from a subdirectory; outside a repository or below its top level, a refusal."

# --- Case 4 — the prerequisites: the install runs the prerequisite check first ---------------
# A gitleaks that is installed but does not start stops the install before any hook is
# written, the check's own line naming it; a make that does not start does not: the hooks
# never run make, and `bash scripts/hooks-install.sh` needs none.
fail4() {
  echo "FAIL (prerequisites): $1" >&2
  [[ -f "${workdir}/out4.log" ]] && { echo "--- script output ---" >&2; cat "${workdir}/out4.log" >&2; }
  exit 1
}
broken="${workdir}/broken-bin"
mkdir -p "${broken}"
printf '#!/usr/bin/env bash\necho "gitleaks: cannot execute binary file" >&2\nexit 126\n' > "${broken}/gitleaks"
chmod +x "${broken}/gitleaks"
pq_repo="${workdir}/pq-repo"
git init -q "${pq_repo}"
mkdir -p "${pq_repo}/scripts"
cp "${HOOKS_INSTALL}" "${pq_repo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${pq_repo}/scripts/check-prerequisites.sh"
set +e
PATH="${broken}:${PATH}" bash "${pq_repo}/scripts/hooks-install.sh" >"${workdir}/out4.log" 2>&1
rc=$?
set -e
[[ ${rc} -ne 0 ]] || fail4 "a gitleaks that does not start: expected a refusal, got exit 0"
grep -q '^FAIL  *gitleaks is installed but does not start' "${workdir}/out4.log" \
  || fail4 "a gitleaks that does not start: the refusal does not name it"
[[ ! -e "${pq_repo}/.git/hooks/pre-commit" ]] || fail4 "a hook was written although a prerequisite does not start"
printf '#!/usr/bin/env bash\necho "make: error while loading shared libraries" >&2\nexit 127\n' > "${broken}/make"
chmod +x "${broken}/make"
rm "${broken}/gitleaks"
set +e
PATH="${broken}:${PATH}" bash "${pq_repo}/scripts/hooks-install.sh" >"${workdir}/out4.log" 2>&1
rc=$?
set -e
[[ ${rc} -eq 0 ]] || fail4 "a make that does not start stopped the install, which needs no make: exit ${rc}"
# A pin that is not x.y.z: "21" is a range to npx, which would run the newest 21.x.
pin_repo="${workdir}/pin-repo"
git init -q "${pin_repo}"
mkdir -p "${pin_repo}/scripts"
cp "${HOOKS_INSTALL}" "${pin_repo}/scripts/hooks-install.sh"
sed 's/^COMMITLINT=.*/COMMITLINT=21/' "${CHECK_PREREQ}" > "${pin_repo}/scripts/check-prerequisites.sh"
grep -qx 'COMMITLINT=21' "${pin_repo}/scripts/check-prerequisites.sh" || fail4 "the pin was not set to 21"
set +e
bash "${pin_repo}/scripts/hooks-install.sh" >"${workdir}/out4.log" 2>&1
rc=$?
set -e
[[ ${rc} -ne 0 ]] || fail4 "a commitlint pin of 21: expected a refusal, got exit 0"
grep -q "commitlint's pin" "${workdir}/out4.log" || fail4 "a commitlint pin of 21: the refusal does not name the pin"
[[ ! -e "${pin_repo}/.git/hooks/commit-msg" ]] || fail4 "a commitlint pin of 21: the commit-msg hook was written"

echo "PASS (prerequisites): the install runs the prerequisite check first — a gitleaks that does not start stops it before any hook is written; a broken make does not, the hooks never run it; a commitlint pin that is not x.y.z stops it."

# --- Case 5 — the git gitleaks reads through the generated pre-commit ----------------------
# gitleaks scans what `git diff` prints, which the user's git configuration can empty (a
# forced colour) or replace (a textconv driver). The pre-commit adds git's documented
# environment configuration after the caller's: a stub gitleaks reports what git then reads.
fail5() {
  echo "FAIL (pre-commit environment): $1" >&2
  [[ -f "${workdir}/out5.log" ]] && { echo "--- hook output ---" >&2; cat "${workdir}/out5.log" >&2; }
  exit 1
}
probe="${workdir}/probe-bin"
mkdir -p "${probe}"
cat > "${probe}/gitleaks" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  version) echo 8.30.1 ;;
  protect)
    echo "color.diff=$(git config --get color.diff || true)"
    echo "textconv=$(git config --get diff.mask.textconv || true)"
    echo "quotepath=$(git config --get core.quotepath || true)"
    echo "count=${GIT_CONFIG_COUNT:-}" ;;
esac
exit 0
STUB
chmod +x "${probe}/gitleaks"
git -C "${repo}" config diff.mask.textconv "sed -e 's/=.*/= ***/'"
set +e
(cd "${repo}" && PATH="${probe}:${PATH}" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.quotepath \
  GIT_CONFIG_VALUE_0=false bash .git/hooks/pre-commit) >"${workdir}/out5.log" 2>&1
rc=$?
set -e
[[ ${rc} -eq 0 ]] || fail5 "the hook failed: exit ${rc}"
grep -qx 'color.diff=never' "${workdir}/out5.log" || fail5 "gitleaks' git does not have the colour off"
grep -qx 'textconv=cat' "${workdir}/out5.log" || fail5 "gitleaks' git still runs the project's textconv"
grep -qx 'quotepath=false' "${workdir}/out5.log" || fail5 "the caller's own environment configuration was lost"
grep -qx 'count=3' "${workdir}/out5.log" || fail5 "the entries are not added after the caller's one"
set +e
(cd "${repo}" && PATH="${probe}:${PATH}" GIT_CONFIG_COUNT='1; x' bash .git/hooks/pre-commit) \
  >"${workdir}/out5.log" 2>&1
rc=$?
set -e
[[ ${rc} -ne 0 ]] || fail5 "a GIT_CONFIG_COUNT that is not a number: the hook went on"
grep -q 'GIT_CONFIG_COUNT is not a number' "${workdir}/out5.log" \
  || fail5 "a GIT_CONFIG_COUNT that is not a number: the refusal does not say so"
! grep -q '^color.diff=' "${workdir}/out5.log" \
  || fail5 "a GIT_CONFIG_COUNT that is not a number: gitleaks ran anyway"

echo "PASS (pre-commit environment): gitleaks' git reads the colour off and each textconv as cat, after the caller's own environment configuration, which stays; a GIT_CONFIG_COUNT that is not a number stops the hook before gitleaks."

# --- Case 6 — the files git shows as binary, scanned apart ----------------------------------
# A file only an attribute makes binary still holds text, and `git diff` shows it gitleaks as
# "Binary files differ". The generated pre-commit copies it from the index into a directory of
# its own and runs `gitleaks detect --no-git` there. A stub gitleaks reports what it finds;
# TMPDIR is the case's own, so that a directory left behind shows. k.key is larger than a
# pipe's buffer, so that git dies of the closed pipe after the first 8000 bytes.
fail6() {
  echo "FAIL (binary files): $1" >&2
  local f
  for f in "${workdir}/out6.log" "${workdir}/probe6.log"; do
    if [[ -f "${f}" ]]; then echo "--- ${f##*/} ---" >&2; cat "${f}" >&2; fi
  done
  exit 1
}
probe6="${workdir}/probe6-bin"
mkdir -p "${probe6}"
cat > "${probe6}/gitleaks" <<'STUB'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo "gitleaks version 8.30.1" ;;
  version) echo 8.30.1 ;;
  detect)
    {
      echo "cwd=${PWD}"
      echo "mode=$(ls -ld . | cut -c1-10)"
      echo "files=$(find . -type f | sort | tr '\n' ' ')"
      echo "k.key=$(cksum < k.key 2>/dev/null || true)"
      echo "args=$*"
    } > "${PROBE6_LOG}"
    case "${PROBE6_MODE}" in
      leak) exit 1 ;;
      hang)
        echo "$$ ${PPID}" > "${PROBE6_PIDS}"
        exec sleep 30 ;;
    esac ;;
esac
exit 0
STUB
chmod +x "${probe6}/gitleaks"
bin_repo="${workdir}/bin-repo"
git init -q "${bin_repo}"
mkdir -p "${bin_repo}/scripts"
cp "${HOOKS_INSTALL}" "${bin_repo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${bin_repo}/scripts/check-prerequisites.sh"
bash "${bin_repo}/scripts/hooks-install.sh" >"${workdir}/out6.log" 2>&1 || fail6 "the hooks were not installed"
printf '*.key binary\n' > "${bin_repo}/.gitattributes"
{ printf 'a key file, text\n'; head -c 204800 /dev/zero | tr '\000' 'k'; printf '\n'; } > "${bin_repo}/k.key"
printf 'a\000binary\000file\n' > "${bin_repo}/real.bin"
git -C "${bin_repo}" add .gitattributes k.key real.bin
[[ "$(git -C "${bin_repo}" diff --staged --numstat -- k.key)" == $'-\t-\tk.key' ]] \
  || fail6 "k.key is not shown as binary, so the case would prove nothing"
staged_sum="$(git -C "${bin_repo}" cat-file blob :0:k.key | cksum)"
scan_tmp="${workdir}/tmp6"
mkdir -p "${scan_tmp}"
export PROBE6_LOG="${workdir}/probe6.log" PROBE6_PIDS="${workdir}/probe6.pids"
# run6 <mode>: the hook, the stub first on PATH, TMPDIR the case's own.
run6() {
  rm -f "${PROBE6_LOG}"
  set +e
  (cd "${bin_repo}" && PROBE6_MODE="$1" TMPDIR="${scan_tmp}" PATH="${probe6}:${PATH}" \
    bash .git/hooks/pre-commit) >"${workdir}/out6.log" 2>&1
  rc=$?
  set -e
}
left_behind() { [[ -n "$(ls -A "${scan_tmp}")" ]]; }
run6 pass
[[ ${rc} -eq 0 ]] || fail6 "a scan that finds nothing: the hook refused, exit ${rc}"
[[ -f "${PROBE6_LOG}" ]] || fail6 "the file only an attribute makes binary was not scanned apart"
cwd6="$(sed -n 's/^cwd=//p' "${PROBE6_LOG}")"
[[ "${cwd6}" == "${scan_tmp}"/* ]] || fail6 "the scan did not run in a directory of its own under TMPDIR: ${cwd6}"
grep -qx 'files=./k.key ' "${PROBE6_LOG}" \
  || fail6 "the scan directory does not hold k.key alone — a file binary by its content was copied, or nothing"
grep -qxF "k.key=${staged_sum}" "${PROBE6_LOG}" || fail6 "the file scanned is not the staged content"
grep -qxF "args=detect --no-git --source . --redact -v --gitleaks-ignore-path ${bin_repo}" "${PROBE6_LOG}" \
  || fail6 "gitleaks was not run as detect --no-git on the directory, with the project's .gitleaksignore"
case "$(uname -s)" in
  MINGW* | MSYS*)
    echo "NOTE (binary files): the directory's mode is not checked under Git Bash, whose /tmp — the user's own %TEMP% — shows no POSIX modes" ;;
  *)
    grep -qx 'mode=drwx------' "${PROBE6_LOG}" || fail6 "the scan directory can be read by others than the user" ;;
esac
! left_behind || fail6 "a scan that finds nothing: the scan directory was left behind"
# The project's .gitleaks.toml goes to the scan, as protect reads it — unless GITLEAKS_CONFIG
# names another configuration, which gitleaks then reads itself.
printf '[extend]\nuseDefault = true\n' > "${bin_repo}/.gitleaks.toml"
run6 pass
grep -qxF "args=detect --no-git --source . --redact -v --gitleaks-ignore-path ${bin_repo} --config ${bin_repo}/.gitleaks.toml" \
  "${PROBE6_LOG}" || fail6 "the project's .gitleaks.toml was not passed to the scan"
export GITLEAKS_CONFIG="${workdir}/elsewhere.toml"
run6 pass
unset GITLEAKS_CONFIG
grep -qxF "args=detect --no-git --source . --redact -v --gitleaks-ignore-path ${bin_repo}" "${PROBE6_LOG}" \
  || fail6 "with GITLEAKS_CONFIG set, the scan was given another configuration"
rm "${bin_repo}/.gitleaks.toml"
run6 leak
[[ ${rc} -ne 0 ]] || fail6 "a scan that finds a leak: the hook let the commit through"
! left_behind || fail6 "a scan that finds a leak: the scan directory was left behind"
# Stopped by Ctrl-C while gitleaks runs: INT to the hook's process group, as a terminal sends
# it. Job control gives the background hook a group of its own, where it does not ignore INT,
# as a script's background job otherwise does. The stub records the hook's pid, and waits.
rm -f "${PROBE6_PIDS}"
set +e
(
  set -m
  (cd "${bin_repo}" && PROBE6_MODE=hang TMPDIR="${scan_tmp}" PATH="${probe6}:${PATH}" \
    exec bash .git/hooks/pre-commit) >"${workdir}/out6.log" 2>&1 &
  hook=$!
  for _ in $(seq 1 100); do
    [[ -s "${PROBE6_PIDS}" ]] && break
    sleep 0.1
  done
  [[ -s "${PROBE6_PIDS}" ]] || exit 3
  read -r _ parent < "${PROBE6_PIDS}"
  [[ "${parent}" == "${hook}" ]] || exit 4
  kill -INT -- "-${hook}"
  wait "${hook}"
) 2>"${workdir}/jobs6.log"
rc=$?
set -e
[[ ${rc} -ne 3 ]] || fail6 "the stub's scan never started"
[[ ${rc} -ne 4 ]] || fail6 "the scan's parent is not the hook"
[[ ${rc} -eq 130 ]] || fail6 "stopped by Ctrl-C: expected exit 130, got ${rc}"
! left_behind || fail6 "stopped by Ctrl-C: the scan directory was left behind"
# Nothing shown as binary but a file binary by its content: no scan apart.
git -C "${bin_repo}" rm -q --cached k.key
run6 pass
[[ ! -f "${PROBE6_LOG}" ]] || fail6 "a file binary by its content was scanned apart"

echo "PASS (binary files): a file only an attribute makes binary is scanned apart — copied from the index into a directory of its own that only the user can read, the project's .gitleaks.toml and .gitleaksignore passed on —, a file binary by its content is not, and the directory is gone when the hook passes, refuses or is stopped by Ctrl-C."

# --- Case 7 — a re-run over the hooks in place ---------------------------------------------
# The installer cannot tell an earlier release's hook from one the user edited: both only
# differ from what it generates. It saves the hook and says so — and claims no local change,
# which it did not measure.
fail7() {
  echo "FAIL (re-run): $1" >&2
  [[ -f "${workdir}/out7.log" ]] && { echo "--- script output ---" >&2; cat "${workdir}/out7.log" >&2; }
  exit 1
}
rerun_repo="${workdir}/rerun-repo"
git init -q "${rerun_repo}"
mkdir -p "${rerun_repo}/scripts"
cp "${HOOKS_INSTALL}" "${rerun_repo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${rerun_repo}/scripts/check-prerequisites.sh"
bash "${rerun_repo}/scripts/hooks-install.sh" >"${workdir}/out7.log" 2>&1 || fail7 "the first install failed"
hooks7="${rerun_repo}/.git/hooks"
bash "${rerun_repo}/scripts/hooks-install.sh" >"${workdir}/out7.log" 2>&1 || fail7 "a re-run over its own hooks failed"
! grep -q '^WARNING' "${workdir}/out7.log" || fail7 "a re-run over its own unchanged hooks warned"
! ls "${hooks7}"/*.bak >/dev/null 2>&1 || fail7 "a re-run over its own unchanged hooks saved a .bak"
# An earlier release's commit-msg: the generated hook with another pin, nobody's edit.
sed 's/@commitlint\/cli@[0-9.]*/@commitlint\/cli@20.0.0/' "${hooks7}/commit-msg" > "${workdir}/earlier-commit-msg"
! cmp -s "${workdir}/earlier-commit-msg" "${hooks7}/commit-msg" || fail7 "the earlier hook was not made different"
cp "${workdir}/earlier-commit-msg" "${hooks7}/commit-msg"
bash "${rerun_repo}/scripts/hooks-install.sh" >"${workdir}/out7.log" 2>&1 || fail7 "a re-run over an earlier hook failed"
cmp -s "${hooks7}/commit-msg.bak" "${workdir}/earlier-commit-msg" || fail7 "the .bak is not the earlier hook"
grep -q '^WARNING: commit-msg differs from the hook this version generates' "${workdir}/out7.log" \
  || fail7 "the message does not say what was measured, a difference from the generated hook"
! grep -q 'local changes' "${workdir}/out7.log" || fail7 "the message claims local changes it did not measure"
# The formatting reminder follows the slot, not the copy this test runs against: a project
# answers the slot, and runs this test against its own copy. So both states are built from
# that copy — the slot opened by a marker line after the gitleaks call, the slot answered by
# every marker replaced with "none" — and each is checked to have reached the generated
# pre-commit before the reminder, or its absence, counts. The marker is written split, so
# this test is no slot of its own.
marker7="TO BE DEFINED"
marker7="${marker7} AT SETUP"
open_repo="${workdir}/open-repo"
git init -q "${open_repo}"
mkdir -p "${open_repo}/scripts"
awk -v m="${marker7}" '{ print }
  /^gitleaks protect --staged --redact -v$/ && !done { print "# 2. AUTOMATIC FORMATTING — [" m "]."; done = 1 }' \
  "${HOOKS_INSTALL}" > "${open_repo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${open_repo}/scripts/check-prerequisites.sh"
bash "${open_repo}/scripts/hooks-install.sh" >"${workdir}/out7.log" 2>&1 || fail7 "an install with the formatting slot open failed"
grep -qE 'TO BE DEFINED A[T] SETUP' "${open_repo}/.git/hooks/pre-commit" \
  || fail7 "the opened slot did not reach the generated pre-commit"
grep -q 'Remember to enable automatic formatting' "${workdir}/out7.log" \
  || fail7 "with the formatting slot open, the install does not remind of it"
answered_repo="${workdir}/answered-repo"
git init -q "${answered_repo}"
mkdir -p "${answered_repo}/scripts"
sed -E 's/TO BE DEFINED A[T] SETUP|DA DEFINIRE A[L] SETUP/none: no formatter in this project/g' \
  "${HOOKS_INSTALL}" > "${answered_repo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${answered_repo}/scripts/check-prerequisites.sh"
bash "${answered_repo}/scripts/hooks-install.sh" >"${workdir}/out7.log" 2>&1 || fail7 "an install with the formatting slot answered failed"
[[ -f "${answered_repo}/.git/hooks/pre-commit" ]] || fail7 "the answered copy generated no pre-commit"
! grep -qE 'TO BE DEFINED A[T] SETUP|DA DEFINIRE A[L] SETUP' "${answered_repo}/.git/hooks/pre-commit" \
  || fail7 "the answered copy's generated pre-commit still carries the marker"
! grep -q 'Remember to enable automatic formatting' "${workdir}/out7.log" \
  || fail7 "with the formatting slot answered, the install still reminds of it"

echo "PASS (re-run): over its own unchanged hooks a re-run saves and says nothing; over an earlier release's hook it saves a .bak and says the hook differs from the one it generates, claiming no local change; the formatting reminder only while its slot is open."

# --- Case 8 — core.hooksPath set, as a hook manager sets it --------------------------------
# git then reads another directory, and the hooks written to .git/hooks would never run. The
# install refuses, and since the check runs at install time only, its message must say that a
# hook manager sets core.hooksPath again at its next run: removing it and re-running lasts
# until then.
fail8() {
  echo "FAIL (core.hooksPath): $1" >&2
  [[ -f "${workdir}/out8.log" ]] && { echo "--- script output ---" >&2; cat "${workdir}/out8.log" >&2; }
  exit 1
}
hp_repo="${workdir}/hookspath-repo"
git init -q "${hp_repo}"
mkdir -p "${hp_repo}/scripts"
cp "${HOOKS_INSTALL}" "${hp_repo}/scripts/hooks-install.sh"
cp "${CHECK_PREREQ}" "${hp_repo}/scripts/check-prerequisites.sh"
git -C "${hp_repo}" config core.hooksPath .husky/_
set +e
bash "${hp_repo}/scripts/hooks-install.sh" >"${workdir}/out8.log" 2>&1
rc=$?
set -e
[[ ${rc} -ne 0 ]] || fail8 "core.hooksPath set: the install went on"
[[ ! -e "${hp_repo}/.git/hooks/pre-commit" ]] || fail8 "core.hooksPath set: a hook was written where git does not read it"
grep -q "core.hooksPath is set to '.husky/_'" "${workdir}/out8.log" || fail8 "the refusal does not name the setting"
grep -q 'sets core.hooksPath again at its next run' "${workdir}/out8.log" \
  || fail8 "the message does not say that a hook manager sets core.hooksPath again"

echo "PASS (core.hooksPath): with core.hooksPath set the install stops before writing a hook, and says a hook manager sets it again at its next run, the durable choice being to integrate the commands into it."
