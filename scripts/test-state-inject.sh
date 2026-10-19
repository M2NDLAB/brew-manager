#!/usr/bin/env bash
# Self-test of scripts/state-inject.sh AND of its wiring in .claude/settings.json (docs/00,
# *Selective loading*). Nine cases:
#   1. a STATE.md in the template's form, built here — the repository's own is a project's
#      memory —: the banner, then *Caution & open issues*, no HTML comment, no cut;
#   2. titles of another form — an older language's, or none at all —: one line says the
#      section is missing, and every line of the file follows;
#   3. over the budget — a long *Progress*, then a *Caution* of 37,000 characters on two
#      lines, then the same with accented and astral characters —: the open issues first,
#      the characters not shown counted exactly in UTF-16 units, as Node.js counts them, and
#      the whole output at most 9,000 characters, under the hook's cap of 10,000;
#   4. CRLF line ends: the same output as LF;
#   5. a missing file: the banner, then the line that says the memory is not initialised; an
#      unreadable one: the banner, the line that says so and the line to Read it — skipped,
#      said aloud, where the user reads a mode-000 file (root, Windows);
#   6. a comment never closed, and one inside a code fence: kept as they are;
#   7. the script's own processing failing (an awk that cannot run), in a PATH that holds only
#      head and that awk: the banner, a notice, the file's first 8,000 bytes and the line to
#      Read it — a long file held to the cap too —, so the fallback needs nothing beyond bash
#      and head; and with a head that cannot read the file either, as an ACL refuses a read
#      the -r test passed: the banner, a line saying so and the line to Read it, never a
#      notice of bytes that do not follow;
#   8. the wiring, read from settings.json: a SessionStart hook with no matcher runs the
#      script from the project's directory — in its Windows form too, where cygpath exists —
#      and falls back to the file's first 8,000 bytes and the line to Read it when the script
#      is missing, or to a line saying STATE.md could not be read when it is missing too; the
#      ask rule on it;
#   9. a file that is not UTF-8 — stray continuation bytes, Windows-1252 —: counted one unit
#      per byte, cut with its notice, the output held to the cap.
# Every case exits 0: the hook never fails a session.
#
# HERMETIC: throwaway files under mktemp; the wired command is READ from settings.json, never
# retyped, and run by /bin/sh as Claude Code runs a hook's command.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INJECT="${SCRIPT_DIR}/state-inject.sh"
BANNER='=== PROJECT MEMORY (STATE.md) ==='
READ_IT='=== Read .claude/memory/STATE.md whole before acting on what it holds. ==='
CAP=9000

fail() {
  echo "FAIL (state inject): $*" >&2
  exit 1
}

NODE="$(command -v node || true)"
[[ -n "${NODE}" ]] || fail "node not found: this test counts characters as Claude Code does, with Node.js"

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

# A STATE.md in the template's form, built here: in a project the repository's own STATE.md
# is the project's memory — any size, any content —, never the template (found by v4.0.0's
# rehearsal, where a populated STATE.md failed this test's first case).
TEMPLATE="${workdir}/template.md"
{
  printf -- '---\ntype: state\nupdated: YYYY-MM-DD\nbranch: <integration branch>\ntags: [state]\n---\n'
  printf '# STATE — [PROJECT NAME]\n\n> **What this file is.** The entry point of the memory.\n>\n> Delete this block when you initialise the project.\n\n'
  printf '> Updated: YYYY-MM-DD | Last: **<last thing completed>** | Index: [[INDEX]]\n\n'
  printf '## Progress\n<!-- Checklist of goals.\n     Tick what is done. -->\n- [ ] 01 — <first block of work> ← NEXT\n\n'
  printf '## What exists now\n<!-- What has been built. -->\n- Directory tree: see [[TREE]].\n\n'
  printf '## Decisions made (not obvious from the code)\n- <decision> → reason.\n\n'
  printf '## Documentation debt\n- <section to write>\n\n'
  printf '## Caution & open issues\n<!-- Known traps, with their TRIGGER. -->\n- <open issue> — <reason> → <trigger>\n\n'
  printf '## Active branches\n- **<integration branch>** = integration.\n'
} > "${TEMPLATE}"

# run <file>: the script's output for a file; the exit code must be 0.
run() {
  local out rc
  set +e
  out="$(bash "${INJECT}" "$1")"
  rc=$?
  set -e
  [[ ${rc} -eq 0 ]] || fail "exit ${rc} on $1: the hook must never fail a session"
  printf '%s\n' "${out}"
}
# units: the UTF-16 length of stdin, as Claude Code's own JavaScript measures a string.
units() { "${NODE}" -e 'let s = ""; process.stdin.setEncoding("utf8"); process.stdin.on("data", (d) => { s += d }).on("end", () => console.log(s.length))'; }
under_cap() {
  local n
  n="$(printf '%s\n' "$1" | units)"
  [[ ${n} -le ${CAP} ]] || fail "$2: ${n} characters printed, over ${CAP}"
}
# cut_line: the last line, if it is the notice of a cut.
cut_line() { printf '%s\n' "$1" | grep -E '^=== STATE\.md: [0-9]+ of [0-9]+ characters not shown' || true; }

# --- Case 1 — the shipped template ------------------------------------------------------------
out1="$(run "${TEMPLATE}")"
[[ "$(printf '%s\n' "${out1}" | sed -n 1p)" == "${BANNER}" ]] || fail "the template: the first line is not the banner"
[[ "$(printf '%s\n' "${out1}" | sed -n 2p)" == "## Caution & open issues" ]] || fail "the template: Caution & open issues does not come right after the banner"
! printf '%s\n' "${out1}" | grep -q '<!--' || fail "the template: an HTML comment was printed"
[[ -z "$(cut_line "${out1}")" ]] || fail "the template: a cut, for a file under the budget"
for t in '## Progress' '## Active branches' '## What exists now' '## Decisions made (not obvious from the code)' '## Documentation debt' '> Updated: YYYY-MM-DD'; do
  printf '%s\n' "${out1}" | grep -qxF -- "${t}" || printf '%s\n' "${out1}" | grep -qF -- "${t}" || fail "the template: '${t}' is missing"
done
under_cap "${out1}" "the template"

# --- Case 2 — titles of another form, or none ---------------------------------------------------
printf '# STATE\n\n## Attenzione / problemi aperti\n- a debt\n\n## Branch attivi\n- main\n' > "${workdir}/legacy.md"
out2="$(run "${workdir}/legacy.md")"
printf '%s\n' "${out2}" | sed -n 2p | grep -q 'no "## Caution & open issues" section' || fail "titles of another form: no line says the section is missing"
for t in '# STATE' '## Attenzione / problemi aperti' '- a debt' '## Branch attivi' '- main'; do
  printf '%s\n' "${out2}" | grep -qxF -- "${t}" || fail "titles of another form: '${t}' is missing"
done
printf 'Just a few lines.\nNo titles at all.\n' > "${workdir}/plain.md"
out2b="$(run "${workdir}/plain.md")"
printf '%s\n' "${out2b}" | grep -q 'no "## Caution & open issues" section' || fail "no titles: no line says the section is missing"
printf '%s\n' "${out2b}" | grep -qxF 'No titles at all.' || fail "no titles: the text is missing"

# --- Case 3 — over the budget -----------------------------------------------------------------
# check_cut <label> <file> <output>: the notice's two numbers against Node.js's own count — the
# characters not shown plus those printed (the banner, the notices and the comments aside)
# make the file's characters.
check_cut() {
  local line shown total want printed
  line="$(cut_line "$3")"
  [[ -n "${line}" ]] || fail "$1: no notice of the cut"
  shown="$(printf '%s\n' "${line}" | sed -E 's/^=== STATE\.md: ([0-9]+) of ([0-9]+) .*/\1/')"
  total="$(printf '%s\n' "${line}" | sed -E 's/^=== STATE\.md: ([0-9]+) of ([0-9]+) .*/\2/')"
  want="$(tr -d '\r' < "$2" | units)"
  [[ "${total}" -eq "${want}" ]] || fail "$1: the notice counts ${total} characters, Node.js ${want}"
  printed="$(printf '%s\n' "$3" | grep -vxF "${BANNER}" | grep -v '^=== STATE\.md: ' | grep -v 'no "## Caution & open issues" section' | units)"
  [[ $((printed + shown)) -eq "${total}" ]] || fail "$1: ${printed} printed + ${shown} not shown != ${total}"
  printf '%s\n' "${line}" | grep -q 'Read \.claude/memory/STATE\.md whole' || fail "$1: the notice does not say to Read the file"
}
{
  printf '# STATE\n\n> Updated: 2026-10-16 | Last: **x**\n\n## Progress\n'
  for i in $(seq 1 600); do printf -- '- [x] %03d — a step of the work, done and committed long ago\n' "${i}"; done
  printf '\n## Caution & open issues\n- the one debt that matters → trigger: before the release\n\n## Active branches\n- **main** = integration.\n'
} > "${workdir}/long-progress.md"
out3="$(run "${workdir}/long-progress.md")"
[[ "$(printf '%s\n' "${out3}" | sed -n 2p)" == "## Caution & open issues" ]] || fail "a long Progress: the open issues are not first"
printf '%s\n' "${out3}" | grep -qF -- '- the one debt that matters' || fail "a long Progress: the open issue is not shown"
printf '%s\n' "${out3}" | grep -qxF -- '- **main** = integration.' || fail "a long Progress: Active branches is not shown before Progress"
printf '%s\n' "$(cut_line "${out3}")" | grep -q 'from ## Progress on' || fail "a long Progress: the notice does not name Progress"
check_cut "a long Progress" "${workdir}/long-progress.md" "${out3}"
under_cap "${out3}" "a long Progress"
# Both notices at once — no Caution section, and a cut —: the longest output there is.
grep -v -e '^## Caution & open issues$' -e 'the one debt that matters' "${workdir}/long-progress.md" > "${workdir}/no-caution.md"
out3d="$(run "${workdir}/no-caution.md")"
printf '%s\n' "${out3d}" | sed -n 2p | grep -q 'no "## Caution & open issues" section' || fail "a long file with no Caution: no line says the section is missing"
check_cut "a long file with no Caution" "${workdir}/no-caution.md" "${out3d}"
under_cap "${out3d}" "a long file with no Caution"
# The same, the cut's section titled past the 80 characters its notice quotes: the longest.
{ printf '# STATE\n\n## %s\n' "$(printf 'A%.0s' $(seq 1 120))"; sed -n '/^- \[x\]/p' "${workdir}/no-caution.md"; } > "${workdir}/long-title.md"
out3e="$(run "${workdir}/long-title.md")"
printf '%s\n' "$(cut_line "${out3e}")" | grep -q 'AAAA\.\.\. on\.' || fail "a long title: the notice does not cut it at 80 characters"
under_cap "${out3e}" "a long title"
# A Caution of 37,000 characters in two entries, each one line: its head is shown.
long_line() { local s=''; for _ in $(seq 1 "$2"); do s="${s}$1"; done; printf '%s' "${s}"; }
entry="$(long_line 'an open issue described at length, with its history; ' 340)"
{
  printf '# STATE\n\n## Caution & open issues\n- %s\n- %s\n\n## Progress\n- [ ] next\n' "${entry}" "${entry}"
} > "${workdir}/long-caution.md"
out3b="$(run "${workdir}/long-caution.md")"
printf '%s\n' "${out3b}" | sed -n 3p | grep -q '^- an open issue described at length' || fail "a long Caution: its first entry's head is not shown"
check_cut "a long Caution" "${workdir}/long-caution.md" "${out3b}"
under_cap "${out3b}" "a long Caution"
# The same, its text accented and astral: two bytes, three, and a surrogate pair each.
entry="$(long_line 'an open issue, naïve café résumé — 𝄞 ' 1100)"
{
  printf '# STATE\n\n## Caution & open issues\n- %s\n- %s\n' "${entry}" "${entry}"
} > "${workdir}/multibyte.md"
out3c="$(run "${workdir}/multibyte.md")"
check_cut "a multibyte Caution" "${workdir}/multibyte.md" "${out3c}"
under_cap "${out3c}" "a multibyte Caution"
printf '%s\n' "${out3c}" | "${NODE}" -e 'const c = []; process.stdin.on("data", (d) => c.push(d)).on("end", () => { new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(c)) })' \
  || fail "a multibyte Caution: the cut split a UTF-8 sequence"
printf 'x\xc3\n' | "${NODE}" -e 'const c = []; process.stdin.on("data", (d) => c.push(d)).on("end", () => { new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(c)) })' 2>/dev/null \
  && fail "control: a split UTF-8 sequence passed the decoder — the check above proves nothing"

# --- Case 4 — CRLF line ends --------------------------------------------------------------------
sed 's/$/\r/' "${TEMPLATE}" > "${workdir}/crlf.md"
# The CR counted by Node, on the bytes: Git Bash's grep does not see a line-ending CR (measured
# in the CI on Windows, here and in v1.5.0).
has_cr() { "${NODE}" -e 'process.exit(require("fs").readFileSync(process.argv[1]).includes(13) ? 0 : 1)' "$1"; }
has_cr "${workdir}/crlf.md" || fail "CRLF: the test's file has no CR (the case would prove nothing)"
! has_cr "${TEMPLATE}" || fail "control: the LF template holds a CR — the check above proves nothing"
[[ "$(run "${workdir}/crlf.md")" == "${out1}" ]] || fail "CRLF: the output differs from LF's"

# --- Case 5 — a missing file --------------------------------------------------------------------
out5="$(run "${workdir}/absent.md")"
[[ "$(printf '%s\n' "${out5}" | sed -n 1p)" == "${BANNER}" ]] || fail "a missing file: the first line is not the banner"
printf '%s\n' "${out5}" | sed -n 2p | grep -q '^Memory not initialised' || fail "a missing file: no line says the memory is not initialised"
printf '## Caution & open issues\n- x\n' > "${workdir}/unreadable.md"
chmod 000 "${workdir}/unreadable.md"
case5="a missing or unreadable file"
if [[ -r "${workdir}/unreadable.md" ]]; then
  # chmod 000 takes no read permission away under Git Bash on Windows (its noacl mount, as the
  # platform's records say; not measured here), and root reads anything: the case is skipped,
  # said aloud, and the PASS line below does not claim it.
  echo "SKIP (unreadable file): this user reads a mode-000 file — root, or Windows, where chmod takes no read permission away"
  case5="a missing file (the unreadable one skipped)"
else
  out5b="$(run "${workdir}/unreadable.md")"
  [[ "$(printf '%s\n' "${out5b}" | sed -n 1p)" == "${BANNER}" ]] || fail "an unreadable file: the first line is not the banner"
  printf '%s\n' "${out5b}" | grep -q 'cannot be read' || fail "an unreadable file: no line says so"
  [[ "$(printf '%s\n' "${out5b}" | tail -n 1)" == "${READ_IT}" ]] || fail "an unreadable file: the last line does not say to Read it"
fi
chmod 600 "${workdir}/unreadable.md"

# --- Case 6 — a comment never closed, and one in a code fence -----------------------------------
printf '## Caution & open issues\n- x\n```\n<!-- inside a fence -->\n```\n<!-- never closed\n- y\n' > "${workdir}/comments.md"
out6="$(run "${workdir}/comments.md")"
printf '%s\n' "${out6}" | grep -qxF '<!-- inside a fence -->' || fail "a comment in a code fence was left out"
printf '%s\n' "${out6}" | grep -qxF '<!-- never closed' || fail "a comment never closed was left out"
printf '%s\n' "${out6}" | grep -qxF -- '- y' || fail "the text after a comment never closed was left out"

# --- Case 7 — the processing fails: the file's first 8,000 bytes ------------------------------------
# A PATH that holds only head and an awk that cannot run, each a script, the way the guard's
# self-test fakes a missing node: not a link, since Git Bash's `ln -s` copies a binary away
# from the DLLs it loads (measured in the CI on Windows, scripts/test-agent-git-guard.sh). The
# script runs by bash's own path, so the fallback is held to bash and head alone. A second
# PATH has a head that cannot read the file either.
BASH_BIN="$(command -v bash)"
mkdir -p "${workdir}/only" "${workdir}/no-read"
printf '#!/bin/sh\necho "awk: error while loading shared libraries" >&2\nexit 127\n' > "${workdir}/only/awk"
printf '#!/bin/sh\nexec "%s" "$@"\n' "$(command -v head)" > "${workdir}/only/head"
cp "${workdir}/only/awk" "${workdir}/no-read/awk"
printf '#!/bin/sh\necho "head: cannot open for reading: Permission denied" >&2\nexit 1\n' > "${workdir}/no-read/head"
chmod +x "${workdir}/only/awk" "${workdir}/only/head" "${workdir}/no-read/awk" "${workdir}/no-read/head"
# fallback <PATH> <file>: the script run with that PATH and nothing else on it.
fallback() {
  local out rc
  set +e
  out="$(PATH="$1" "${BASH_BIN}" "${INJECT}" "$2")"
  rc=$?
  set -e
  [[ ${rc} -eq 0 ]] || fail "no awk: exit ${rc} on $2"
  [[ "$(printf '%s\n' "${out}" | sed -n 1p)" == "${BANNER}" ]] || fail "no awk: the first line is not the banner"
  [[ "$(printf '%s\n' "${out}" | tail -n 1)" == "${READ_IT}" ]] || fail "no awk: the last line does not say to Read the file"
  printf '%s\n' "${out}"
}
out7="$(fallback "${workdir}/only" "${TEMPLATE}")"
printf '%s\n' "${out7}" | sed -n 2p | grep -q 'could not process the file: its first 8000 bytes follow' || fail "no awk: no notice of the bytes that follow"
[[ "$(printf '%s\n' "${out7}" | sed -n '3,$p' | sed '$d')" == "$(cat "${TEMPLATE}")" ]] || fail "no awk: a file under 8,000 bytes is not printed whole"
out7b="$(fallback "${workdir}/only" "${workdir}/long-progress.md")"
[[ "$(printf '%s\n' "${out7b}" | sed -n 3p)" == "$(sed -n 1p "${workdir}/long-progress.md")" ]] || fail "no awk, a long file: its head does not follow the notice"
under_cap "${out7b}" "no awk, a long file"
out7c="$(fallback "${workdir}/no-read" "${TEMPLATE}")"
printf '%s\n' "${out7c}" | sed -n 2p | grep -q 'nor read it' || fail "no awk, no read: no line says the file cannot be read"
! printf '%s\n' "${out7c}" | grep -q 'follow' || fail "no awk, no read: a notice says bytes follow, and none do"
[[ "$(printf '%s\n' "${out7c}" | wc -l | tr -d ' ')" -eq 3 ]] || fail "no awk, no read: more than the banner, its line and the line to Read it"

# --- Case 8 — the wiring --------------------------------------------------------------------------
wired="$("${NODE}" -e '
const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
const groups = (s.hooks && s.hooks.SessionStart) || [];
const hits = groups.filter((g) => !("matcher" in g)).flatMap((g) => g.hooks || [])
  .filter((h) => h.type === "command" && /scripts\/state-inject\.sh/.test(h.command || ""));
if (hits.length !== 1) process.exit(1);
console.log(hits[0].command);
' "${REPO_ROOT}/.claude/settings.json")" \
  || fail "no SessionStart hook without a matcher runs scripts/state-inject.sh in .claude/settings.json"
"${NODE}" -e '
const s = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
process.exit(((s.permissions || {}).ask || []).includes("Edit(/scripts/state-inject.sh)") ? 0 : 1);
' "${REPO_ROOT}/.claude/settings.json" || fail "settings.json lacks the ask rule Edit(/scripts/state-inject.sh)"
project="${workdir}/project"
mkdir -p "${project}/scripts" "${project}/.claude/memory"
cp "${INJECT}" "${project}/scripts/"
cp "${workdir}/long-progress.md" "${project}/.claude/memory/STATE.md"
# hook <project dir>: the wired command as Claude Code runs it, from another directory.
hook() { (cd "${workdir}" && CLAUDE_PROJECT_DIR="$1" /bin/sh -c "${wired}"); }
out8="$(hook "${project}")"
[[ "${out8}" == "$(run "${project}/.claude/memory/STATE.md")" ]] || fail "the wiring: its output is not the script's"
if command -v cygpath >/dev/null 2>&1; then
  [[ "$(hook "$(cygpath -w "${project}")")" == "${out8}" ]] || fail "the wiring: the project's path in its Windows form gives another output"
fi
rm "${project}/scripts/state-inject.sh"
out8b="$(hook "${project}" 2>/dev/null)" || fail "the wiring: it fails when the script is missing"
[[ "$(printf '%s\n' "${out8b}" | sed -n 1p)" == "${BANNER}" ]] || fail "the wiring, the script missing: the first line is not the banner"
[[ "$(printf '%s\n' "${out8b}" | sed -n 3p)" == "$(sed -n 1p "${workdir}/long-progress.md")" ]] || fail "the wiring, the script missing: the file's head is not printed"
[[ "$(printf '%s\n' "${out8b}" | tail -n 1)" == "${READ_IT}" ]] || fail "the wiring, the script missing: the last line does not say to Read the file"
under_cap "${out8b}" "the wiring, the script missing"
rm "${project}/.claude/memory/STATE.md"
out8c="$(hook "${project}" 2>/dev/null)" || fail "the wiring: it fails when the script and STATE.md are both missing"
[[ "$(printf '%s\n' "${out8c}" | sed -n 1p)" == "${BANNER}" ]] || fail "the wiring, nothing to read: the first line is not the banner"
printf '%s\n' "${out8c}" | sed -n 2p | grep -q 'could not be read' || fail "the wiring, nothing to read: no line says STATE.md could not be read"
! printf '%s\n' "${out8c}" | grep -q 'follow' || fail "the wiring, nothing to read: a notice says bytes follow, and none do"
[[ "$(printf '%s\n' "${out8c}" | tail -n 1)" == "${READ_IT}" ]] || fail "the wiring, nothing to read: the last line does not say to Read the file"

# --- Case 9 — not UTF-8 ---------------------------------------------------------------------------
# A Caution of stray continuation bytes, lines of NBSP bytes, then Windows-1252 punctuation: a
# decoder makes a replacement character of each, which the UTF-8 count would have taken for 0.
"${NODE}" -e '
const p = [Buffer.from("## Caution & open issues\n- x"), Buffer.alloc(60000, 0x80), Buffer.from("\n")];
for (let i = 0; i < 400; i++) p.push(Buffer.from("- issue "), Buffer.alloc(200, 0xa0), Buffer.from("\n"));
for (let i = 0; i < 600; i++) p.push(Buffer.from("- caf"), Buffer.from([0xe9, 0x20, 0x97, 0x20, 0xab, 0x20, 0xbb, 0x20, 0xb0, 0x0a]));
process.stdout.write(Buffer.concat(p));
' > "${workdir}/not-utf8.md"
out9="$(run "${workdir}/not-utf8.md")"
[[ "$(printf '%s\n' "${out9}" | sed -n 2p)" == "## Caution & open issues" ]] || fail "not UTF-8: the open issues are not first"
[[ -n "$(cut_line "${out9}")" ]] || fail "not UTF-8: no notice of the cut"
under_cap "${out9}" "not UTF-8"
for _ in $(seq 1 12); do tail -n 600 "${workdir}/not-utf8.md"; done > "${workdir}/cp1252.md"
out9b="$(run "${workdir}/cp1252.md")"
[[ -n "$(cut_line "${out9b}")" ]] || fail "Windows-1252: no notice of the cut"
under_cap "${out9b}" "Windows-1252"

echo "PASS (state inject): the template and the titles of other forms printed with the open issues first or their absence said, the cut counted in UTF-16 units and the output held to ${CAP} characters, CRLF, ${case5}, the comments, a failed run held to 8,000 bytes with nothing beyond bash and head and no notice of bytes that do not follow, the wiring read from settings.json and its fallback as true, and a file that is not UTF-8."
