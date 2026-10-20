#!/usr/bin/env bash
# Self-test of scripts/agent-git-guard.mjs AND of its wiring in .claude/settings.json
# (docs/04, "Delegated agents and the shared working tree").
#
# Contract under test: a delegated agent (hook input carrying agent_id) is read-only on
# git; in every session that runs the project's hooks, the main one included, the git
# forms that take a hook out and the ones an allow rule would let past a prompt and auto
# mode's classifier are refused (section 3), the main session's ordinary work next to them
# passes (3b, 3c), and the limits docs/04 declares pass as declared (3d). When the guard
# itself FAILS — a crash, a missing
# guard file, a missing `node` — the wiring blocks a delegated agent (exit 2, fail-closed)
# and, in the main session, exits 1: a non-blocking error that Claude Code shows in the
# transcript with the FIRST line of stderr, which the wiring makes its own clear message.
# The main session's push boundary is the pre-push, not the guard. Claude Code treats a
# PreToolUse hook's non-zero exit other than 2 as "proceed" (measured on 2.1.283: exit 1,
# exit 127, a timeout), so the wiring, not the guard, decides the failure case.
#
# It FAILS if the guard stops blocking a write or starts blocking a read — through Bash,
# PowerShell or Monitor —, stops refusing one of section 3's forms in either session or
# starts refusing the main session's ordinary work — a local commit's amend among it
# (section 3c) —, if the wiring disappears from
# settings.json or the PowerShell tool is no longer off there, if a broken guard lets an
# agent through, blocks the main session or stays silent there, or if the first line of a
# failure is not the wiring's own message.
#
# HERMETIC: the wired command is READ from .claude/settings.json (never retyped here) and
# run by /bin/sh in a clean environment against JSON inputs. No repository of the user's is
# touched: the guard reads command text — and, for the amend and the implicit no-index, the
# throwaway repositories section 3c builds.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "FAIL (agent git guard): $*" >&2
  exit 1
}

NODE="$(command -v node || true)"
[[ -n "${NODE}" ]] || fail "node not found: the guard needs Node.js (a framework prerequisite); without it delegated agents are blocked"
GIT="$(command -v git || true)"
[[ -n "${GIT}" ]] || fail "git not found: the guard reads the repository for the amend and the implicit no-index (section 3c)"

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

# --- The wiring, as settings.json declares it ------------------------------------------------
wired="$("${NODE}" -e '
const settings = require(process.argv[1]);
const tools = (group) => (group.matcher ?? "").split("|");
const hook = (settings.hooks?.PreToolUse ?? [])
  .filter((group) => ["Bash", "PowerShell", "Monitor"].every((t) => tools(group).includes(t)))
  .flatMap((group) => group.hooks ?? [])
  .find((h) => /scripts\/agent-git-guard\.mjs/.test(h.command ?? ""));
if (!hook) process.exit(3);
process.stdout.write(hook.command);
' "${REPO_ROOT}/.claude/settings.json")" \
  || fail "no PreToolUse hook on Bash, PowerShell and Monitor runs scripts/agent-git-guard.mjs in .claude/settings.json"
# The PowerShell tool off: on Windows the framework's shell is Git Bash's.
"${NODE}" -e '
if (require(process.argv[1]).env?.CLAUDE_CODE_USE_POWERSHELL_TOOL !== "0") process.exit(3);
' "${REPO_ROOT}/.claude/settings.json" || fail "settings.json does not keep the PowerShell tool off (env CLAUDE_CODE_USE_POWERSHELL_TOOL=0)"
# The checkpoint on the boundary's own files (an accidental edit would change it at once).
"${NODE}" -e '
const ask = require(process.argv[1]).permissions?.ask ?? [];
const missing = ["Edit(/.claude/settings.json)", "Edit(/scripts/agent-git-guard.mjs)"].filter((r) => !ask.includes(r));
if (missing.length) { console.error(missing.join(", ")); process.exit(3); }
' "${REPO_ROOT}/.claude/settings.json" || fail "settings.json lacks the ask rule(s) above on the boundary's own files"

# The hook input for a command; "agent" as the second argument adds agent_id/agent_type;
# the third names the tool (default Bash). hook_input_json takes the command as the body of
# a JSON string, escapes included (section 2d).
# The command travels on stdin, as Claude Code hands the hook its input: on Windows, Git
# Bash rewrites an ARGUMENT that looks like a POSIX path (/usr/bin/git becomes
# C:/Program Files/Git/usr/bin/git) before node.exe sees it — measured in the CI.
hook_input() { make_input text "$@"; }
hook_input_json() { make_input json "$@"; }
make_input() {
  printf '%s' "$2" | "${NODE}" -e '
const [form, who, tool] = process.argv.slice(1);
const text = require("fs").readFileSync(0, "utf8");
const command = form === "json" ? JSON.parse(`"${text}"`) : text;
const input = { session_id: "self-test", hook_event_name: "PreToolUse", tool_name: tool || "Bash",
  tool_input: { command }, cwd: process.cwd() };
if (who === "agent") Object.assign(input, { agent_id: "a-self-test", agent_type: "general-purpose" });
process.stdout.write(JSON.stringify(input));
' "$1" "${3:-}" "${4:-}"
}

# Runs the wired command as Claude Code would (sh -c, CLAUDE_PROJECT_DIR set) and prints
# its exit code. Arguments: project dir, hook input, PATH (default: node's and git's dirs +
# system). The user's git configuration stays out of the guard's reads of section 3c's
# repositories; SYSTEMROOT and WINDIR, where Windows sets them, pass, as Claude Code's
# environment passes them to its hooks.
run_wired() {
  local rc
  set +e
  printf '%s' "$2" | env -i HOME="${HOME}" PATH="${3:-$(dirname "${NODE}"):$(dirname "${GIT}"):/usr/bin:/bin}" \
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 ${SYSTEMROOT:+"SYSTEMROOT=${SYSTEMROOT}"} \
    ${WINDIR:+"WINDIR=${WINDIR}"} CLAUDE_PROJECT_DIR="$1" /bin/sh -c "${wired}" >/dev/null 2>"${workdir}/stderr"
  rc=$?
  set -e
  echo "${rc}"
}

expect() { # expect <code> <label> <project dir> <hook input> [PATH]
  local rc
  rc="$(run_wired "$3" "$4" "${5:-}")"
  [[ "${rc}" == "$1" ]] || fail "$2 — expected exit $1, got ${rc}: $(head -c 300 "${workdir}/stderr")"
}
first_line() { # first_line <prefix> <label>: the transcript shows only stderr's first line
  [[ "$(head -n 1 "${workdir}/stderr")" == "$1"* ]] \
    || fail "$2 — stderr's first line is not '$1…': $(head -n 1 "${workdir}/stderr")"
}
# blocked <label> <hook input>: exit 2 from the guard's own verdict. A crash also ends in
# exit 2 for an agent, through the wiring, but under another first line.
blocked() {
  expect 2 "$1" "${REPO_ROOT}" "$2"
  first_line "agent-git-guard: BLOCKED" "$1"
}

# --- 1. Delegated agent: every write is refused (exit 2) -------------------------------------
AGENT_WRITES=(
  'git switch -c sub-x'
  'git checkout main'
  'git -C . checkout p01'
  'git -c core.pager=cat --git-dir=.git --work-tree=. switch main'
  'cd /tmp && git restore .'
  'git reset --hard HEAD~1'
  'git commit -m "wip"'
  'git branch new-branch'
  'git branch -D old-branch'
  'git branch -f other HEAD~1'
  'git tag v9.9.9'
  'git stash'
  'git stash push -m wip'
  'git worktree add ../wt HEAD'
  'git config user.email someone@example.invalid'
  'git archive -o out.tar HEAD'
  'git diff HEAD~1 --output=d.txt'
  'git status'
  'git status --short'
  'git push origin main'
  'git -C "$PWD" push origin main'
  "git 'switch' main"
  'GIT_TRACE=1 git checkout main'
  'env GIT_TRACE=1 git checkout main'
  'timeout 30 git checkout main'
  'echo main | xargs git checkout'
  'v=$(git switch main)'
  'git log -1 && git merge feature'
  '/usr/bin/git rebase main'
  'git -c alias.co=checkout co main'
  'git fetch origin'
  'git pull'
  'git gc --prune=now'
  'git remote add other file:///tmp/other'
  # the review's forms (2026-10-07): line continuations, substitutions inside double
  # quotes, flags that do not mean "list", stuck options, redirections, shell keywords
  $'cd /tmp && \\\n  git checkout main'
  $'git log -1 && \\\ngit reset --hard HEAD~1'
  $'GIT_TRACE=1 \\\n  git switch main'
  'echo "$(git switch main)"'
  'out="$(git checkout main 2>&1)"; echo "$out"'
  'echo "`git stash`"'
  'git branch -v newbranch'
  'git branch --sort=refname newbranch'
  'git tag --sort=refname newtag'
  'git archive -oout.tar HEAD'
  'git remote -v add other file:///tmp/other'
  '2>/dev/null git branch other'
  'if true; then git switch main; fi'
  'git symbolic-ref HEAD refs/heads/other'
  # the gate's forms (2026-10-18): a substitution inside double quotes is read up to the `)`
  # that closes it, past the double quotes nested in it
  'cd "$(dirname "$(git rev-parse --git-dir)")" && git checkout main'
  # a heredoc whose delimiter is quoted with a backslash ends at its line (the gate's round 2)
  $'cat <<\\EOF\nit\'s here\nEOF\ngit checkout main'
  $'echo $\'it\\\'s\' && git checkout main'
)
for c in "${AGENT_WRITES[@]}"; do
  blocked "agent write not blocked: ${c}" "$(hook_input "${c}" agent)"
done

# --- 2. Delegated agent: reads go through (exit 0) — a guard that blocks reads gets disabled --
AGENT_READS=(
  'git --no-optional-locks status'
  'GIT_OPTIONAL_LOCKS=0 git status --short'
  'git log --oneline -5'
  'git -C . diff HEAD~1..HEAD'
  'git show HEAD:CLAUDE.md'
  'git branch'
  "git branch --list 'feat/*'"
  'git branch --show-current'
  'git tag -l'
  'git tag --contains HEAD'
  'git stash list'
  'git worktree list'
  'git config --get user.name'
  'git config user.name'
  'git remote -v'
  'git rev-parse --abbrev-ref HEAD'
  'git archive HEAD | tar -t'
  'git ls-files | wc -l'
  'git blame -L 1,5 CLAUDE.md'
  'git --version'
  'ls -la && cat CLAUDE.md'
  'grep -rn "git checkout" .'
  'echo "git switch main"'
  "cat <<'EOF'
git switch main
EOF"
  $'git --no-pager \\\n  log -1'
  'git -c core.pager=cat log -1'
  "git tag -n5 'v*'"
  'git branch -a --contains HEAD'
  'git branch -v'
  'git symbolic-ref --short HEAD'
  'echo "branch: $(git rev-parse --abbrev-ref HEAD)"'
  'echo "$((1 + 2))"'
  '2>/dev/null git log -1'
  # a quoted heredoc's body is data, a `)` in it closes nothing (2026-10-18)
  $'echo "$(cat <<\'EOF\'\nsee (x)\n`git checkout main`\nEOF\n)"'
  # an option's value is not an option (2026-10-18)
  'git log -S --output --oneline'
  'git branch --sort -committerdate'
  'git ls-files | tree --fromfile'
)
for c in "${AGENT_READS[@]}"; do
  expect 0 "agent read blocked: ${c}" "${REPO_ROOT}" "$(hook_input "${c}" agent)"
done

# --- 2b. The Monitor tool runs shell commands too: same rule --------------------------------
blocked "agent Monitor write not blocked" "$(hook_input 'while true; do git pull; sleep 30; done' agent Monitor)"
expect 0 "agent Monitor read blocked" "${REPO_ROOT}" "$(hook_input 'tail -f app.log | grep --line-buffered ERROR' agent Monitor)"

# --- 2c. The PowerShell tool, if a developer turns it on: same rule, PowerShell's syntax ----
PS_WRITES=(
  'git checkout main'
  '& git commit -m "x"'
  'git.exe switch main'
  'Git checkout main'
  "& 'C:\\Program Files\\Git\\cmd\\git.exe' commit -m x"
  'cd C:\repo; git stash'
  $'git `\n  checkout main'
  'if ($ready) { git reset --hard HEAD~1 }'
  '$out = $(git switch main)'
  # the review's forms (2026-10-11): an assignment, script blocks, dot-sourcing, a
  # here-string and a block comment whose apostrophe opens no quote
  '$out = git checkout main'
  '$out=git checkout main'
  '[string]$s = git checkout main'
  '$log += git stash'
  '${out} = git checkout main'
  'try { git checkout main } catch { Write-Error $_ }'
  $'\'main\' | ForEach-Object { git checkout $_ }'
  'if($x){git checkout dev}'
  '& {git checkout main}'
  '. git checkout main'
  $'$m = @\'\ndon\'t\n\'@\ngit commit -m $m'
  $'@\'\n\'@\ngit checkout main'
  $'$m = @"\nFix "x\n"@\ngit commit -m $m'
  $'Write-Output @"\n$(git checkout main)\n"@'
  $'<# don\'t touch the index #>\ngit checkout main'
)
for c in "${PS_WRITES[@]}"; do
  blocked "agent PowerShell write not blocked: ${c}" "$(hook_input "${c}" agent PowerShell)"
done
PS_READS=(
  'git log -1'
  'git --no-optional-locks status'
  'git.exe diff HEAD~1'
  $'git log `\n  -1'
  'Get-ChildItem -Recurse | Select-String "git checkout"'
  "Write-Output 'git switch main'"
  '$sha = git rev-parse HEAD'
  'git rev-parse HEAD@{1}'
  $'$m = @\'\ngit checkout main\n\'@\nWrite-Output $m'
  $'<#\ngit checkout main is forbidden here\n#>\ngit log -1'
)
for c in "${PS_READS[@]}"; do
  expect 0 "agent PowerShell read blocked: ${c}" "${REPO_ROOT}" "$(hook_input "${c}" agent PowerShell)"
done
# Through Bash too (Git Bash on Windows), git may be spelled git.exe, Git or a Windows path —
# double-quoted too, where bash keeps a backslash before an ordinary character.
for c in 'git.exe checkout main' 'GIT checkout main' '/c/Program\ Files/Git/cmd/git.exe switch main' \
  '"C:\Program Files\Git\cmd\git.exe" checkout main'; do
  blocked "agent write not blocked: ${c}" "$(hook_input "${c}" agent)"
done

# --- 2d. CRLF line ends, written as Claude Code sends them: JSON escapes --------------------
# The hook input is JSON, where a \r is the escape \r: Node rebuilds it, and it never exists
# as a byte in bash or in a pipe. So these commands are written as the body of a JSON
# string, the same way on every platform (in the CI on Windows, a \r the test wrote with
# bash's $'…' did not reach node). Not vacuous: each case first goes, through the same
# wiring, to a probe in the guard's place, which fails unless node finds the \r.
mkdir -p "${workdir}/probe/scripts"
printf '%s\n' 'import { readFileSync } from "node:fs";' \
  'const { command } = JSON.parse(readFileSync(0, "utf8")).tool_input;' \
  'if (!command.includes("\r\n")) {' \
  '  console.error("node received the command without its \\r");' \
  '  process.exit(2);' \
  '}' > "${workdir}/probe/scripts/agent-git-guard.mjs"
crlf_cases=0
crlf_case() { # crlf_case <blocked|allowed> <tool> <command, JSON-escaped>
  local input
  input="$(hook_input_json "$3" agent "$2")"
  expect 0 "a CRLF case reached node without its \\r, so it proves nothing: $3" "${workdir}/probe" "${input}"
  if [[ "$1" == blocked ]]; then
    blocked "agent $2 CRLF write not blocked: $3" "${input}"
  else
    expect 0 "agent $2 CRLF read blocked: $3" "${REPO_ROOT}" "${input}"
  fi
  crlf_cases=$((crlf_cases + 1))
}
crlf_case blocked PowerShell 'git log -1\r\ngit merge feature'
crlf_case allowed PowerShell 'git log\r\ngit --no-optional-locks status\r\n'
# Bash keeps a \r as a character: before CRLF, a backslash escapes the \r, and the line ends.
crlf_case blocked Bash 'git log -1 \\\r\ngit checkout main'

# --- 3. Every session, the main one included: the forms that take a hook out, and the ones --
# an allow rule would let run with no prompt and, in auto mode, past the classifier, which
# never sees what an allow rule approved (docs/04, "Permission configuration"). Each one is
# refused for the main session and for an agent alike, a long option also as a prefix git
# takes (measured on git 2.54.0: `--no-veri`, `--forc`, `--mov`).
EVERY_SESSION_REFUSED=(
  'git commit -n -m x'
  'git commit -an -m x'
  'git commit -nm x'
  'git commit --no-verify -m x'
  'git commit -m x --no-veri'
  'git push --no-verify origin main'
  'git -C . push --no-verify origin main'
  'git merge --no-verify feature'
  'git -c core.hooksPath=/dev/null commit -m x'
  'git -c CORE.HOOKSPATH=/dev/null commit -m x'
  'git --config-env=core.hooksPath=HOOKS commit -m x'
  'GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null git commit -m x'
  'git config core.hooksPath /dev/null'
  'git config --local core.hooksPath .husky'
  'git config set core.hooksPath /dev/null'
  'git branch -D old'
  'git branch -d -f old'
  'git branch -df old'
  'git branch --delete --force old'
  'git branch --dele --forc old'
  'git branch -f other HEAD~1'
  'git branch --force other HEAD~1'
  'git branch -m old new'
  'git branch -M old new'
  'git branch --move old new'
  'git branch --mov old new'
  'git branch -C old new'
  'git diff --output=d.txt'
  'git diff --output d.txt'
  'git log -1 -p --output=../x'
  'git show --output=.claude/settings.json HEAD'
  'git diff --no-index /etc/hosts /dev/null'
  'tree -o out.txt'
  'tree -ao out.txt .'
  'tree -L 2 -R'
  'tree --fromfile list.txt'
  'tree --fromtabfile list.txt'
  'git status && git commit -n -m x'
  'timeout 30 git commit --no-verify -m x'
  'echo "$(git diff --output=x)"'
  'cd sub && tree -o ../out.txt'
  '/usr/bin/git commit -n -m x'
  # a substitution inside double quotes ends at its own `)`, past nested double quotes and
  # quoted text (the gate's round 1, 2026-10-18)
  'cd "$(dirname "$(git rev-parse --git-dir)")" && git commit -n -m x'
  $'echo "$(echo \')\'; git commit -n -m x)"'
  $'git commit -n -m "$(cat <<\'EOF\'\nfix(guard): a subject\nEOF\n)"'
  # a heredoc's delimiter quoted in any part — `\EOF`, `E"OF"` — is quoted all the same: its
  # body is data, an apostrophe there opens nothing (the gate's round 2, 2026-10-18)
  $'git commit -m "$(cat <<\\EOF\nfix(guard): it\'s the scope\nEOF\n)" --no-verify'
  $'git commit -m "$(cat <<E"OF"\nfix(guard): it\'s the scope\nEOF\n)" --no-verify'
  $'cat <<\\EOF\nit\'s here\nEOF\ngit commit -n -m x'
  # ANSI-C quoting: inside `$'…'` a backslash escapes, `\'` included (the gate's round 2)
  $'git commit -m $\'it\\\'s a fix\' --no-verify'
  $'echo $\'it\\\'s\' && git commit -n -m x'
  $'git commit -m x $\'--no-verify\''
  $'git commit -m x $\'\\x2d\\x2dno-verify\''
  # the string ends where the shell ends it, `\c` before its quote included (the gate's round 3)
  $'git commit -m x $\'\\c\' --no-verify #\''
  $'git commit -m x $\'a\\c\' -n #\''
  $'git commit -m x $\'\\c\\\\\' --no-verify #\''
  # a file .gitignore leaves out, staged — a secret's way into a commit (rule 1); measured on
  # git 2.54.0: each of these staged an ignored file, a plain `git add` refused it
  'git add -f token.txt'
  'git add --force token.txt'
  'git add --f token.txt'
  'git add -fA'
  'git add -Af'
  'git add -vf token.txt'
  'git -C . add -f token.txt'
  'git stage -f token.txt'
  # an option after another's value is still read (2026-10-18)
  'git log -S foo --output=x'
  'git log --grep foo --output x'
  'git branch --sort refname -m a b'
  'git commit -m x --no-verify'
  'git commit --mess x -n'
  'tree -I x -o out.txt'
  'tree -L2 -o out.txt'
  'tree -La 1 -o out.txt'
  'tree -Lo 1 out.txt'
  # `--fromfile` given a path reads that file, past a value and a `.` (2026-10-18)
  'tree --fromfile . list.txt'
  'tree --fromfile -L 2 /etc/hosts'
  'tree -L2 --fromfile /etc/hosts'
  # the HTML intro and outro print the file they name — measured on tree 2.3.2 (2026-10-18)
  'tree -H . --hintro=../secret.txt -L 1 .'
  'tree -H . --houtro ../secret.txt'
  # a directory the text does not resolve, and an operand written as a path outside (2026-10-18)
  'git -C "${FW:?}" diff /etc/hosts /dev/null'
  'cd "$X" && git diff ../outside.txt token.txt'
  'cd "$X" && git diff ~/.ssh/config /dev/null'
)
for c in "${EVERY_SESSION_REFUSED[@]}"; do
  blocked "main session not refused: ${c}" "$(hook_input "${c}")"
  blocked "agent not refused: ${c}" "$(hook_input "${c}" agent)"
done
for c in 'git commit -n -m x' 'git push --no-verify' 'git diff --output=d.txt'; do
  blocked "main session not refused (PowerShell): ${c}" "$(hook_input "${c}" '' PowerShell)"
done

# --- 3b. The main session's ordinary work goes through, next to those forms ----------------
# (pushes are the pre-push hook's job, not this one).
MAIN_ALLOWED=(
  'git switch -c feat/x'
  'git add scripts/agent-git-guard.mjs'
  'git add -A'
  'git add -u'
  'git add -- -f'
  'git commit -m "x"'
  'git commit -am x'
  "git commit -m '-n is the message here'"
  'git commit -mn'
  'git commit -F msg.txt'
  'git branch feat/x'
  'git branch -d merged'
  'git branch --delete merged'
  'git branch -c old copy'
  'git branch -uorigin/main'
  "git branch --format='%(refname)' --list"
  'git push origin main'
  'git push -n origin main'
  'git log -n 5 --oneline'
  "git grep -n -e '--no-verify' -- docs"
  'git diff --stat'
  'git diff --name-only origin/main...HEAD'
  'git config core.hooksPath'
  'git config --show-origin --get core.hooksPath'
  'git config --unset core.hooksPath'
  'tree -L 2'
  'tree -a -I node_modules'
  'git status'
  # Claude Code's own commit and PR forms: a quoted heredoc in a substitution, a `)` in the
  # scope, refused forms quoted in the body — data, not commands (the gate's round 1)
  $'git commit -m "$(cat <<\'EOF\'\nfix(guard): refuse the forms\n\nThe agent\'s `git commit -n` is now refused.\nEOF\n)"'
  $'gh pr create --title x --body "$(cat <<\'EOF\'\n## Summary (the guard)\n- refuses `git branch -D old` and `tree -o x`\nEOF\n)"'
  # the same with the delimiter quoted another way: the body still data (the gate's round 2)
  $'git commit -m "$(cat <<\\EOF\nfix(guard): it\'s the form\n\nThe agent\'s `git commit -n` is now refused.\nEOF\n)"'
  $'git commit -m "$(cat <<E"OF"\nfix(guard): it\'s the form\n\n`git branch -D old` is refused.\nEOF\n)"'
  # an ANSI-C quoted message is one word, its escaped quote inside it
  $'git commit -m $\'it\\\'s -n here\''
  # an option's value is not an option — measured on git 2.54.0 and tree 2.3.2: each sorted,
  # searched or ran its hook with the word as its value, and wrote no file (2026-10-18)
  'git branch --sort -committerdate'
  'git log -S --output --oneline'
  'git log --grep --output -1'
  'git diff -G --output HEAD~1'
  'git commit -m --no-verify'
  'git commit --message --no-verify'
  "tree -I '-o*' -L 2"
  'tree -P -R'
  # `tree --fromfile` reading stdin — the fallback of the TREE.md template, as it ships —
  # passes; measured on tree 2.3.2: each listed the paths piped to it (2026-10-18)
  'git ls-files | tree --fromfile'
  'git ls-files | tree --fromfile .'
  'git ls-files | tree --fromfile -L 2 --dirsfirst'
  'tree -H . -T title -L 1'
  # two revisions where the text does not say which directory: the upgrade's own form passes
  # (the rehearsal, 2026-10-18: the guard had refused it)
  'git -C "${FW:?}" diff v1.2.0 v4.1.0'
  'git -C "$S/fw" diff --stat HEAD~1 HEAD'
)
for c in "${MAIN_ALLOWED[@]}"; do
  expect 0 "main session blocked: ${c}" "${REPO_ROOT}" "$(hook_input "${c}")"
done
for c in 'git switch -c feat/x' 'git commit -m "x"' 'git push origin main'; do
  expect 0 "main session blocked (PowerShell): ${c}" "${REPO_ROOT}" "$(hook_input "${c}" '' PowerShell)"
done

# --- 3c. The forms decided on the repository, not on the text: the guard reads it ----------
# `git commit --amend` is refused where HEAD is already in its upstream or in a
# remote-tracking branch, and where the guard cannot tell — a `cd` the text does not resolve,
# no repository —; a local commit's amend passes. `git diff` with two paths is refused where
# git would compare them as files, below. Throwaway repositories, built with the user's git
# configuration out (a global commit.gpgSign would ask for a signature) and with no push:
# the remote-tracking refs come from a fetch. Each case's directory reaches the guard as the
# hook's `cwd`, in node's own form of the path — on Windows, not Git Bash's.
amend="${workdir}/amend"
mkdir -p "${amend}/none"
ga() { GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c user.name=self-test \
  -c user.email=self-test@example.invalid -c commit.gpgSign=false "$@"; }
ga init -q -b main "${amend}/pushed"
ga -C "${amend}/pushed" commit -q --allow-empty -m one
ga clone -q --bare "${amend}/pushed" "${amend}/remote.git"
ga -C "${amend}/pushed" remote add origin "${amend}/remote.git"
ga -C "${amend}/pushed" fetch -q origin
ga -C "${amend}/pushed" branch -q -u origin/main          # HEAD is its upstream's tip
ga clone -q "${amend}/remote.git" "${amend}/ahead"
ga -C "${amend}/ahead" commit -q --allow-empty -m two     # a local commit on top of it
ga clone -q "${amend}/remote.git" "${amend}/fresh"
ga -C "${amend}/fresh" switch -q -c feat                  # no upstream, HEAD on origin/main
ga init -q -b main "${amend}/local"
ga -C "${amend}/local" commit -q --allow-empty -m one     # no remote at all
ga init -q -b main "${amend}/localup"
ga -C "${amend}/localup" commit -q --allow-empty -m one
ga -C "${amend}/localup" switch -q -c topic --track main  # a local upstream that holds HEAD
native() { (cd "$1" && "${NODE}" -e 'process.stdout.write(process.cwd())'); }
pushed="$(native "${amend}/pushed")"
ahead="$(native "${amend}/ahead")"
repo_cases=0
repo_case() { # repo_case <code> <label> <directory> <command>
  expect "$1" "$2" "${REPO_ROOT}" "$(cd "$3" && hook_input "$4")"
  if [[ "$1" == 2 ]]; then first_line "agent-git-guard: BLOCKED" "$2"; fi
  repo_cases=$((repo_cases + 1))
}
repo_case 2 "main session not refused: the amend of a HEAD its upstream holds" "${amend}/pushed" 'git commit --amend --no-edit'
repo_case 2 "main session not refused: the amend written as a prefix" "${amend}/pushed" 'git commit --amen --no-edit'
repo_case 2 "main session not refused: the amend on a new branch at a pushed tip" "${amend}/fresh" 'git commit --amend --no-edit'
repo_case 2 "main session not refused: the amend of a HEAD its local upstream holds" "${amend}/localup" 'git commit --amend --no-edit'
repo_case 2 "main session not refused: the amend through -C" "${amend}/none" "git -C '${pushed}' commit --amend --no-edit"
repo_case 2 "main session not refused: the amend after a cd" "${amend}/none" "cd '${pushed}' && git commit --amend --no-edit"
repo_case 2 "main session not refused: the amend after a cd the text cannot resolve" "${amend}/ahead" 'cd "$REPO" && git commit --amend --no-edit'
repo_case 2 "main session not refused: the amend outside a repository" "${amend}/none" 'git commit --amend --no-edit'
repo_case 0 "main session blocked: a local commit's amend" "${amend}/ahead" 'git commit --amend --no-edit'
repo_case 0 "main session blocked: an amend with no remote" "${amend}/local" 'git commit --amend --no-edit'
repo_case 0 "main session blocked: a local commit's amend through -C" "${amend}/none" "git -C '${ahead}' commit --amend --no-edit"
repo_case 0 "main session blocked: a local commit's amend after a cd" "${amend}/none" "cd '${ahead}' && git commit --amend --no-edit"
repo_case 0 "main session blocked: a plain commit where HEAD is pushed" "${amend}/pushed" 'git commit -m x'
# The implicit no-index, git-diff(1)'s own rule (builtin/diff.c, git 2.54.0): two paths
# after the options, one outside the work tree, or any two outside a repository, and git
# compares the files themselves — measured: an ignored file and an outside one printed their
# lines (2026-10-18). git's count does not skip an option's value: `-S x a b` is three words.
printf 'token.txt\n' > "${amend}/local/.gitignore"
printf 'TOKEN=self-test\n' > "${amend}/local/token.txt"
printf 'OUTSIDE=self-test\n' > "${amend}/outside.txt"
printf 'one\n' > "${amend}/none/p1.txt"
printf 'two\n' > "${amend}/none/p2.txt"
mkdir -p "${amend}/local/sub"
outside="$(native "${amend}")/outside.txt"
local_dir="$(native "${amend}/local")"
repo_case 2 "main session not refused: an ignored file against /dev/null" "${amend}/local" 'git diff token.txt /dev/null'
repo_case 2 "main session not refused: the same after --" "${amend}/local" 'git diff -- token.txt /dev/null'
repo_case 2 "main session not refused: a relative path outside the work tree" "${amend}/local" 'git diff ../outside.txt token.txt'
repo_case 2 "main session not refused: an absolute path outside the work tree" "${amend}/local" "git diff '${outside}' token.txt"
repo_case 2 "main session not refused: a path outside, from a subdirectory" "${amend}/local/sub" 'git diff ../../outside.txt ../token.txt'
repo_case 2 "main session not refused: two paths outside a repository" "${amend}/none" 'git diff p1.txt p2.txt'
repo_case 2 "main session not refused: two paths outside a repository, past a value" "${amend}/none" 'git diff -S one p1.txt p2.txt'
repo_case 2 "main session not refused: the implicit no-index through -C" "${amend}/none" "git -C '${local_dir}' diff token.txt /dev/null"
repo_case 0 "main session blocked: two paths inside the work tree" "${amend}/local" 'git diff token.txt .gitignore'
repo_case 0 "main session blocked: two revisions" "${amend}/local" 'git diff HEAD HEAD'
repo_case 0 "main session blocked: two paths inside, from a subdirectory" "${amend}/local/sub" 'git diff ../token.txt ../.gitignore'
repo_case 0 "main session blocked: three words in git's own count" "${amend}/local" 'git diff -S x token.txt /dev/null'
# An operand the guard cannot place is refused as one outside; a range in one operand passes
# (the gate's round 2, 2026-10-18).
repo_case 2 "main session not refused: an operand the guard cannot place" "${amend}/pushed" 'git diff @{u} HEAD'
repo_case 0 "main session blocked: a range in one operand" "${amend}/pushed" 'git diff @{u}..HEAD'

# --- 3d. The limits the row *No hook taken out* declares, held as declared ------------------
# docs/04's last column, both ways: a form it says passes, passes; a form it says is misread,
# is refused. A guard that starts refusing one, or letting one through, fails here until the
# row says so (docs/02, a bidirectional allow-list).
DECLARED_OUTSIDE=(
  'export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null && git commit -m x'
  'chmod -x .git/hooks/pre-commit'
  'mv .git/hooks/pre-commit /tmp/pre-commit.off'
  "printf 'x\\n' >> .gitleaksignore"
  "sh -c 'git commit -n -m x'"
  'git -c alias.ci=commit ci -n -m x'
  'git update-index --add token.txt'
  'git commit -F /etc/hosts'
  'echo "$(case x in x) git commit -n -m y;; esac)"'
  'cd "$X" && git diff a.txt b.txt'
  'sudo git commit -n -m x'
  'tree --infofile token.txt'
  'tree -X --gitfile=token.txt'
  # quoting forms Claude Code does not write, declared by the user's rule (the gate's round 3):
  # `$$'…'` read as zsh reads it, a NUL in `$'…'`, and three heredocs the reader ends wrongly
  $'git commit -m x $$\'a\\\' --no-verify #\''
  $'git commit -m x $\'--no-verify\\0\''
  $'cat <<\'EOF\'\n\tEOF\nit\'s\nEOF\ngit commit -n -m x'
  $'cat <<\\\nEOF\nit\'s\nEOF\ngit commit -n -m x'
  $'echo $((1<<2))\ngit commit --no-verify -m x'
)
for c in "${DECLARED_OUTSIDE[@]}"; do
  expect 0 "a limit docs/04 declares is no longer one — update the row: ${c}" "${REPO_ROOT}" "$(hook_input "${c}")"
done
# The limits read in a repository: a directory changed by `env -C`, a `cd` inside a subshell
# followed as if it lasted, and brace expansion, which makes two operands of one word — each
# passes, as the row declares (the gate's round 2, 2026-10-18).
declared_in_repos=0
declared_case() { # declared_case <directory> <command>
  expect 0 "a limit docs/04 declares is no longer one — update the row: $2" "${REPO_ROOT}" "$(cd "$1" && hook_input "$2")"
  declared_in_repos=$((declared_in_repos + 1))
}
declared_case "${amend}/ahead" "env -C '${pushed}' git commit --amend --no-edit"
declared_case "${amend}/pushed" "x=\$(cd '${ahead}' && pwd); git commit --amend --no-edit"
declared_case "${amend}/local" 'git diff {token.txt,/dev/null}'
DECLARED_MISREAD=(
  'git merge -m --no-verify feature'
  'tree --fromfile -'
)
for c in "${DECLARED_MISREAD[@]}"; do
  blocked "a misreading docs/04 declares is no longer one — update the row: ${c}" "$(hook_input "${c}")"
done

# --- 4. A broken guard: fail-CLOSED for a delegated agent, open for the main session ------
mkdir -p "${workdir}/empty" "${workdir}/broken/scripts" "${workdir}/no-node" "${workdir}/no-cat"
echo 'throw new Error("simulated crash");' > "${workdir}/broken/scripts/agent-git-guard.mjs"
# A PATH with the wiring's `cat` and no `node`: `cat` is a wrapper, not a link — Git Bash's
# `ln -s` copies the binary away from the DLL it loads (measured in the CI on Windows).
printf '#!/bin/sh\nexec "%s" "$@"\n' "$(command -v cat)" > "${workdir}/no-node/cat"
chmod +x "${workdir}/no-node/cat"
ln -s "${NODE}" "${workdir}/no-cat/node"           # a PATH with `node` and no `cat`
for who in agent main; do
  if [[ "${who}" == agent ]]; then want=2; mark=agent; else want=1; mark=""; fi
  expect "${want}" "node missing (${who})"       "${REPO_ROOT}"      "$(hook_input 'git log -1' "${mark}")" "${workdir}/no-node"
  first_line "agent-git-guard: cannot run" "node missing (${who})"
  expect "${want}" "guard file missing (${who})" "${workdir}/empty"  "$(hook_input 'git log -1' "${mark}")"
  first_line "agent-git-guard: cannot run" "guard file missing (${who})"
  expect "${want}" "guard crash (${who})"        "${workdir}/broken" "$(hook_input 'git log -1' "${mark}")"
  first_line "agent-git-guard: cannot run" "guard crash (${who})"
done
# A healthy block keeps the guard's own message first.
expect 2 "agent write, healthy guard" "${REPO_ROOT}" "$(hook_input 'git switch main' agent)"
first_line "agent-git-guard: BLOCKED" "agent write, healthy guard"
# When the guard fails, the wiring classifies the call by the text `"agent_id"` in the raw
# input. A quote INSIDE a value arrives JSON-escaped, so a main-session command quoting the
# key stays the main session's. (A value that ENDS in `"agent_id` would still match while
# the guard is broken: a false positive that blocks, i.e. fails safe — accepted.)
expect 1 "a main-session command quoting \"agent_id\" (broken guard)" "${workdir}/empty" \
  "$(hook_input 'echo "\"agent_id\": x"')"
expect 2 "unreadable input carrying agent_id must block" "${REPO_ROOT}" '{"agent_id":"a-self-test","tool_name":"Bash", truncated'
expect 1 "unreadable input without agent_id: not blocked, but shown (it cannot be told from the main session)" "${REPO_ROOT}" 'not json'
# The wiring cannot even read its input (no `cat`): it cannot classify the call, so it blocks.
expect 2 "an unreadable stdin blocks (agent)" "${REPO_ROOT}" "$(hook_input 'git log -1' agent)" "${workdir}/no-cat"
expect 2 "an unreadable stdin blocks (main)"  "${REPO_ROOT}" "$(hook_input 'git log -1')"       "${workdir}/no-cat"
# A HEALTHY guard's verdict stands whatever the spelling of the key: here agent_id is written
# with a JSON escape, so the raw-text test would miss it — the guard's exit 2 must survive.
expect 2 "a healthy guard's block stands (escaped agent_id key)" "${REPO_ROOT}" \
  '{"tool_name":"Bash","tool_input":{"command":"git commit -m x"},"cwd":"/tmp","agent\u005fid":"a1","agent_type":"general-purpose"}'
# A main session started with --agent carries agent_type but no agent_id: the main session.
expect 1 "a main session with agent_type only (broken guard)" "${workdir}/empty" \
  '{"tool_name":"Bash","tool_input":{"command":"git log -1"},"cwd":"/tmp","agent_type":"reviewer"}'

echo "PASS (agent git guard): ${#AGENT_WRITES[@]} agent writes blocked, ${#AGENT_READS[@]} reads allowed, through PowerShell ${#PS_WRITES[@]} and ${#PS_READS[@]}, ${crlf_cases} CRLF cases whose CR node received; ${#EVERY_SESSION_REFUSED[@]} forms refused in every session, the main one included, and ${#MAIN_ALLOWED[@]} of the main session's commands next to them allowed; ${repo_cases} cases of the amend and the implicit no-index read from throwaway repositories; $((${#DECLARED_OUTSIDE[@]} + declared_in_repos)) declared limits passing and ${#DECLARED_MISREAD[@]} declared misreadings refused, as docs/04 says; a broken guard (node missing / file missing / crash / bad input) blocks agents and shows a non-blocking error to the main session."
