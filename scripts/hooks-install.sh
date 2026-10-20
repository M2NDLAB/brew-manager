#!/usr/bin/env bash
# Installs the framework's local git hooks:
#   - pre-commit : secret scanning (gitleaks) — ALWAYS
#   - commit-msg : Conventional Commits (commitlint) — ALWAYS
#   - pre-push   : the push boundary — refuses a push launched from a Claude Code
#                  session (docs/04, "Enforcement of the execution boundary") — ALWAYS
#   - pre-commit : automatic code formatting — EXAMPLE to adapt to your stack
# Idempotent on its OWN hooks (recognised by the marker in the generated file); if
# one of its own hooks contains local changes (e.g. an adapted formatting block),
# it first saves a .bak copy instead of destroying them.
# Pre-existing hooks of OTHER origin (incl. a hook manager's symlink): the script
# STOPS instead of overwriting them; explicit override with FORCE_OVERWRITE=1, which
# first saves a .bak copy (a dangling symlink, with no content, is removed without a
# .bak). If core.hooksPath is set (e.g. husky), it stops: git would ignore .git/hooks
# and these hooks would end up installed but inert.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The hooks live in the repository's COMMON git directory, shared by all its worktrees:
# in a linked worktree `.git` is a file, so "${REPO_ROOT}/.git/hooks" cannot exist there.
# `--path-format=absolute` (git 2.31+) keeps the path independent of the caller's working
# directory; `--git-common-dir` rather than `--git-path hooks`, which would follow
# core.hooksPath (refused below in any case). The script never creates a .git of its own:
# outside a repository, or with an older git (which echoes the unknown option back instead
# of a path), it stops. It also stops when its copy is not at the top level of the
# repository it sits in — a copy inside someone else's working tree would otherwise install
# the hooks into THAT repository.
if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not installed." >&2
  exit 1
fi
git_common_dir="$(git -C "${REPO_ROOT}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
# An absolute path in either form: on Windows git prints C:/… where Git Bash names the same
# directory /c/… (measured in the CI on Windows). An older git echoes the option instead.
if [[ ( "${git_common_dir}" != /* && "${git_common_dir}" != [A-Za-z]:[/\\]* ) || ! -d "${git_common_dir}" ]]; then
  echo "ERROR: ${REPO_ROOT} is not inside a git repository, or git is older than 2.31." >&2
  echo "  The hooks are installed into the repository that contains this script: run it" >&2
  echo "  from the project's copy (make hooks-install), with git 2.31 or later." >&2
  exit 1
fi
top_level="$(git -C "${REPO_ROOT}" rev-parse --show-toplevel)"
# Compared by identity (-ef), never as strings: the two forms above name one directory.
if [[ ! "${top_level}" -ef "${REPO_ROOT}" ]]; then
  echo "ERROR: ${REPO_ROOT} is not the top level of its git repository (${top_level})." >&2
  echo "  The framework's scripts/ belongs at the repository's root: the hooks would be" >&2
  echo "  installed into ${top_level}, for every project in it." >&2
  exit 1
fi
HOOKS_DIR="${git_common_dir}/hooks"

# --- Prerequisites ----------------------------------------------------------
# The prerequisite check, for what the hooks need (--hooks: make is not among it), each tool
# RUN, not only found, from the repository's top level, where it reads the line ends. A tool
# missing or not starting stops the install before any hook is written — gitleaks is rule 1
# of the method's core, not optional —, and so does a gitleaks below its security minimum or whose
# version cannot be read; any other version below its minimum is shown, and the install
# goes on.
if [[ ! -f "${REPO_ROOT}/scripts/check-prerequisites.sh" ]]; then
  echo "ERROR: scripts/check-prerequisites.sh is missing: it belongs next to this script" >&2
  echo "  (the framework's scripts/ is copied whole)." >&2
  exit 1
fi
if ! (cd "${REPO_ROOT}" && bash scripts/check-prerequisites.sh --hooks); then
  echo "ERROR: a tool the hooks need is missing or does not start (the FAIL lines above)." >&2
  exit 1
fi
# commitlint's version is pinned in one place, scripts/check-prerequisites.sh: the commit-msg
# hook runs its two packages at that version, never npx's latest. Their own dependencies
# follow the ranges they declare, so a release of one of those can still reach a project.
# The pin is an exact version, x.y.z: "21" would be a range to npx, which runs its newest.
commitlint="$(bash "${REPO_ROOT}/scripts/check-prerequisites.sh" --commitlint-version 2>/dev/null || true)"
if [[ ! "${commitlint}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: commitlint's pin cannot be read from scripts/check-prerequisites.sh as an exact" >&2
  echo "  version, x.y.z (read: '${commitlint}'); the check belongs next to this script (the" >&2
  echo "  framework's scripts/ is copied whole)." >&2
  exit 1
fi

# --- Guards for a repo with pre-existing hooks (graft onto an existing project) --
# 1. core.hooksPath active (e.g. husky): git does NOT read .git/hooks, so the hooks
#    written below would NEVER run — installed but inert. Better to stop and let the
#    user decide than to give false confidence. This check runs at install time only: a
#    hook manager sets core.hooksPath again at its next run (husky at every npm install,
#    unless HUSKY=0), and the hooks then stop running without a word (docs/04).
hooks_path="$(git -C "${REPO_ROOT}" config --get core.hooksPath || true)"
if [[ -n "${hooks_path}" ]]; then
  echo "ERROR: core.hooksPath is set to '${hooks_path}': git ignores .git/hooks," >&2
  echo "  so the framework hooks would never run. Choose one:" >&2
  echo "  - integrate these hooks' commands into your hook manager (e.g. husky) — the durable" >&2
  echo "    choice: a hook manager sets core.hooksPath again at its next run (husky at every" >&2
  echo "    npm install, unless HUSKY=0), and from then on these hooks do not run; or" >&2
  echo "  - remove the override and re-run. FIRST find out where it comes from (local," >&2
  echo "    global or system): git config --show-origin --get core.hooksPath" >&2
  echo "    then: git config --unset core.hooksPath   (add --global if it comes from there)" >&2
  exit 1
fi

# 2. Pre-existing hooks NOT generated by this script: they are not overwritten
#    blindly — they may belong to the host project's pipeline. A SYMLINK is always
#    "of other origin" (hook managers link .git/hooks elsewhere): writing through it
#    would corrupt the target file OUTSIDE .git/hooks.
#    With FORCE_OVERWRITE=1 it proceeds: .bak backup of the content (skipped if the
#    symlink is dangling — nothing to save), then removal of the file/symlink so that
#    the write creates a regular file.
#    The marker recognised is the ENGLISH one; the Italian one stays accepted as
#    LEGACY, otherwise a hook installed by an earlier version of the framework would
#    be mistaken for a foreign one and the script would stop on a healthy graft.
MARKER="Hook generated by scripts/hooks-install.sh"
LEGACY_MARKER="Hook generato da scripts/hooks-install.sh"
for hook in pre-commit commit-msg pre-push; do
  target="${HOOKS_DIR}/${hook}"
  if [[ -L "${target}" ]] || { [[ -f "${target}" ]] && ! grep -qF -e "${MARKER}" -e "${LEGACY_MARKER}" "${target}"; }; then
    if [[ "${FORCE_OVERWRITE:-0}" == "1" ]]; then
      # A DANGLING symlink (non-existent target) would make `cp -L` fail under
      # `set -e`, aborting BEFORE the removal — but it has no content to save.
      # `-e` follows the link → FALSE only on a dangling one (TRUE on a valid symlink
      # and on a foreign regular file): the backup happens where it makes sense, the
      # removal of the link is common to both branches so that the write then creates
      # a regular file.
      if [[ -e "${target}" ]]; then
        cp -L "${target}" "${target}.bak"
        echo "WARNING: pre-existing hook '${hook}' saved to ${target}.bak (FORCE_OVERWRITE=1)." >&2
      else
        echo "WARNING: hook '${hook}' was a dangling symlink (no content to save): removed (FORCE_OVERWRITE=1)." >&2
      fi
      rm -f "${target}"
    else
      echo "ERROR: a hook '${hook}' not installed by this script already exists." >&2
      if [[ "${hook}" == "pre-push" ]]; then
        # A merged-by-hand pre-push would be stopped or overwritten by the next run:
        # the generated one runs pre-push.local instead (e.g. git-lfs's), after its check.
        echo "  Rename it to ${HOOKS_DIR}/pre-push.local and re-run: the generated" >&2
        echo "  pre-push runs pre-push.local after the push-boundary check." >&2
      else
        echo "  Merge its commands with the framework's by hand, or re-run with" >&2
        echo "  FORCE_OVERWRITE=1 to overwrite it (it is saved to ${hook}.bak first)." >&2
      fi
      exit 1
    fi
  fi
done

mkdir -p "${HOOKS_DIR}"

# Installs a generated hook: if the target exists (it is necessarily OURS, foreign
# ones are handled above) but the content differs, it is either another release's hook
# or one customised locally (e.g. the adapted formatting block, as the hook's own comments
# ask for) — a difference this script measures, and cannot tell the cause of. A .bak of it
# is saved before rewriting, so that a re-run destroys no customisation.
install_generated() {
  local target="$1"
  if [[ -f "${target}" ]] && ! cmp -s "${target}" "${target}.new"; then
    cp "${target}" "${target}.bak"
    echo "WARNING: ${target##*/} differs from the hook this version generates (another release's, or a local change): saved to ${target}.bak before rewriting." >&2
  fi
  mv "${target}.new" "${target}"
  chmod +x "${target}"
}

# --- pre-commit -------------------------------------------------------------
# `gitleaks protect --staged` scans the staged changes in every release from 8.0.0, and
# safely from 8.18.2, the security minimum the prerequisite check requires. 8.19.0 hid it
# from `--help` for `gitleaks git`, whose `--staged` works only from 8.20.0: the hook keeps
# `protect` until gitleaks announces its removal.
cat > "${HOOKS_DIR}/pre-commit.new" <<'HOOK'
#!/usr/bin/env bash
# Hook generated by scripts/hooks-install.sh — do not edit by hand.
set -euo pipefail

# 1. Secret scanning on the staged files (rule 1: no secret committed). ALWAYS.
#    gitleaks scans what a `git diff` it runs prints, and the user's git configuration can
#    change that: a colour forced to "always" (color.ui, color.diff) leaves it nothing to read
#    (gitleaks#2281), and a textconv driver shows it a conversion instead of the staged text.
#    Either lets a secret through. git's documented environment configuration, after any the
#    caller set, turns the colour off and each configured textconv into `cat` for the hook's
#    git commands, so the scan reads what is committed. Only a `git -c` naming one of these
#    settings on the command line still wins.
case "${GIT_CONFIG_COUNT:-0}" in
  *[!0-9]*)
    echo "pre-commit: GIT_CONFIG_COUNT is not a number (${GIT_CONFIG_COUNT})." >&2
    exit 1 ;;
esac
export GIT_CONFIG_COUNT="$((10#${GIT_CONFIG_COUNT:-0}))"
add_config() {
  export "GIT_CONFIG_KEY_${GIT_CONFIG_COUNT}=$1" "GIT_CONFIG_VALUE_${GIT_CONFIG_COUNT}=$2" \
    "GIT_CONFIG_COUNT=$((GIT_CONFIG_COUNT + 1))"
}
add_config color.diff never
while IFS= read -r -d '' key; do
  add_config "${key}" cat
done < <(git config -z --name-only --get-regexp '^diff\..*\.textconv$' || true)
#    The files git shows as binary reach gitleaks as "Binary files differ", unread. One binary
#    by its content stays unread: gitleaks reads text. One that only an attribute or a diff
#    driver makes binary (`binary`, `-diff`, `binary = true`) still holds text — a private key
#    in a `*.key binary`, for one —, and is scanned apart, as a file: copied from the index,
#    what is committed, into a directory only the user can read, removed when the hook ends.
#    bash runs the EXIT trap on an error and on Ctrl-C, TERM or HUP alike; only a SIGKILL,
#    which no process can catch, leaves the directory behind. It is made under TMPDIR, or
#    /tmp, by an explicit template: without one, macOS's mktemp ignores TMPDIR.
tmp_root="${TMPDIR:-/tmp}"
scan_dir=''
remove_scan_dir() { if [[ -n "${scan_dir}" ]]; then rm -rf -- "${scan_dir}"; fi; }
trap remove_scan_dir EXIT
while IFS= read -r -d '' entry; do
  [[ "${entry}" == $'-\t-\t'* ]] || continue
  path="${entry#$'-\t-\t'}"
  # Binary by its content, as git judges it: a NUL in the first 8000 bytes. git may die of
  # the pipe closed after them, which is no error.
  nuls="$({ git cat-file blob ":0:${path}" || true; } | head -c 8000 | LC_ALL=C tr -dc '\000' | wc -c)"
  [[ "${nuls}" -eq 0 ]] || continue
  if [[ -z "${scan_dir}" ]]; then scan_dir="$(mktemp -d "${tmp_root%/}/pre-commit-scan.XXXXXXXX")"; fi
  mkdir -p "${scan_dir}/$(dirname "${path}")"
  git cat-file blob ":0:${path}" > "${scan_dir}/${path}"
done < <(git diff --cached --numstat -z --no-renames --diff-filter=ACM)
if [[ -n "${scan_dir}" ]]; then
  # The project's .gitleaks.toml and .gitleaksignore, as protect reads them from the top
  # level — unless GITLEAKS_CONFIG names the configuration, which gitleaks reads itself.
  top="${PWD}"
  if [[ -z "${GITLEAKS_CONFIG:-}" && -f "${top}/.gitleaks.toml" ]]; then
    (cd "${scan_dir}" && exec gitleaks detect --no-git --source . --redact -v \
      --gitleaks-ignore-path "${top}" --config "${top}/.gitleaks.toml")
  else
    (cd "${scan_dir}" && exec gitleaks detect --no-git --source . --redact -v \
      --gitleaks-ignore-path "${top}")
  fi
fi

gitleaks protect --staged --redact -v

# 2. AUTOMATIC FORMATTING — prepared but NOT active in this project
#    (decision taken at the framework graft: shfmt/shellcheck not installed; if
#    shfmt is adopted in the future, uncomment the block and make sure the initial
#    reformatting diff is a dedicated commit). The idea: apply the formatter to the
#    staged files ONLY and re-stage them, so no drift accumulates and no
#    formatting-only commits are needed.
#
#    # --- Example for this project: shfmt on the staged zsh scripts ---
#    # (shfmt has no native zsh dialect: -ln bash is an acceptable approximation
#    #  for this code; check the diff before adopting it.)
#    # staged="$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.sh$' || true)"
#    # if [[ -n "${staged}" ]]; then
#    #   echo "${staged}" | xargs shfmt -w -i 4 -ln bash
#    #   echo "${staged}" | xargs git add                 # re-stage the reformatted files
#    # fi
#
#    Note: the linter (for shell: shellcheck) stays out of the hook — here we only
#    do formatting (fast, deterministic). Manual syntax check: zsh -n.
HOOK
install_generated "${HOOKS_DIR}/pre-commit"

# --- commit-msg -------------------------------------------------------------
# Unquoted: the pin read above goes into the hook; the hook's own $1 is escaped.
cat > "${HOOKS_DIR}/commit-msg.new" <<HOOK
#!/usr/bin/env bash
# Hook generated by scripts/hooks-install.sh — do not edit by hand.
# Conventional Commits, config in commitlint.config.cjs. commitlint's two packages at the
# version scripts/check-prerequisites.sh pins; make hooks-install writes the hook again when
# the pin moves.
set -euo pipefail
npx --yes --package @commitlint/cli@${commitlint} --package @commitlint/config-conventional@${commitlint} \\
  commitlint --edit "\$1"
HOOK
install_generated "${HOOKS_DIR}/commit-msg"

# --- pre-push ---------------------------------------------------------------
# The push boundary (docs/04, "Enforcement of the execution boundary"). A permission
# rule matches command TEXT, so `git -C <dir> push`, an alias or a script slip past a
# `Bash(git push:*)` deny. This hook runs inside git itself, for every push, however it
# was spelled: it refuses when the environment carries the Claude Code session markers,
# which every process the agent starts inherits. The human pushes from their own
# terminal, where they are unset.
cat > "${HOOKS_DIR}/pre-push.new" <<'HOOK'
#!/usr/bin/env bash
# Hook generated by scripts/hooks-install.sh — do not edit by hand.
# The push boundary (docs/04, "Enforcement of the execution boundary"): shared history
# is the human's. A push launched from a Claude Code session is refused, whatever form
# it took (git -C, an alias, sh -c, a script, a make target): the session's markers are
# inherited by every process the agent starts. AGENT_GIT_BOUNDARY is set by the `env`
# key of .claude/settings.json; CLAUDECODE, set by Claude Code itself and documented in its
# environment-variable reference, is the fallback. Deliberate evasion (--no-verify, hooks disabled, plumbing) is outside
# this layer's threat model. A project's own pre-push (e.g. git-lfs's) lives in
# pre-push.local, next to this file: it runs after the check, with the same arguments
# and stdin.
set -euo pipefail
if [[ -n "${AGENT_GIT_BOUNDARY:-}" || -n "${CLAUDECODE:-}" ]]; then
  echo "pre-push: REFUSED — this push was launched from a Claude Code session" >&2
  echo "  (AGENT_GIT_BOUNDARY or CLAUDECODE is set). Shared history is the human's:" >&2
  echo "  run the push from your own terminal (docs/04, Execution boundary)." >&2
  exit 1
fi
local_hook="$(dirname "$0")/pre-push.local"
if [[ -x "${local_hook}" ]]; then
  exec "${local_hook}" "$@"
fi
exit 0
HOOK
install_generated "${HOOKS_DIR}/pre-push"

echo "OK: pre-commit (gitleaks), commit-msg (commitlint) and pre-push (push boundary) hooks installed"
echo "    in ${HOOKS_DIR}."
# The formatting slot is open while the generated pre-commit still carries its marker; an
# answer — a formatter, or none — removes the marker, and the reminder with it. The marker
# is matched in a split form, so this line is no slot of its own.
if grep -qE 'TO BE DEFINED A[T] SETUP|DA DEFINIRE A[L] SETUP' "${HOOKS_DIR}/pre-commit"; then
  echo "    Remember to enable automatic formatting in the pre-commit hook (see comments)."
fi
