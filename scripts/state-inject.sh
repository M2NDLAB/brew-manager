#!/usr/bin/env bash
# scripts/state-inject.sh — what the SessionStart hook prints of the memory's STATE.md
# (wired in .claude/settings.json; docs/00, *Selective loading*).
#
# Why it exists: Claude Code caps a hook's plain stdout at 10,000 characters. Past the cap
# it hands Claude a file path and a 2,000-character preview, and does not ask Claude to
# read the file (its hooks page, read on 2026-10-16): a STATE.md over the cap would reach
# the session as its first 2,000 characters — the preamble and the progress, rarely the open
# issues. So the file is printed within a budget, the open issues first, and whatever is
# left out is said, never dropped in silence.
#
# What it prints, in this order:
#   - the banner `=== PROJECT MEMORY (STATE.md) ===`, which the method's core checks for;
#   - the section `## Caution & open issues`, or one line saying the file has none;
#   - the lines before the first `## ` title (the frontmatter, the title, the status line),
#     `## Active branches`, `## Progress`, then every other section in the file's order;
#   - all of it within BUDGET characters, block-level HTML comments left out as Claude
#     Code leaves them out of an imported file; past the budget, one last line saying how
#     many characters were not shown, from which section on, and to Read the file — both
#     numbers count what it would show, the comments left out, not the file's size.
# Characters are counted as Claude Code's own JavaScript counts them, in UTF-16 units (a
# character outside the Basic Multilingual Plane counts two), on the bytes in the C locale,
# so the count is the same in every locale on UTF-8 text, with the awks it has run with —
# macOS's and those of the CI's Linux and Windows images; busybox's never ran. A line that
# is not valid UTF-8 counts one unit per byte, never less than a decoder makes of it; a NUL
# byte ends a line for some awks (BSD awk drops the rest of it): STATE.md is UTF-8 text,
# as Claude's file tools write it. CRLF line ends are read as LF.
# The budget leaves the banner, the notices and the margin under the 10,000: the self-test
# holds the whole output to 9,000 at most (scripts/test-state-inject.sh).
#
# It never fails the session: it exits 0 whatever happens. A missing or unreadable file
# gets the banner and one line saying so; if its own processing fails it prints the banner
# and, once head has read the file, its first BUDGET bytes as they are — never more units
# than bytes —, or else one line saying it cannot be read; then the line to Read it. That
# fallback needs nothing beyond bash and head.
#
# Usage: bash scripts/state-inject.sh [<path of STATE.md>]
#   default: "$CLAUDE_PROJECT_DIR/.claude/memory/STATE.md", or the relative path without it.
set -u

readonly BUDGET=8000
readonly BANNER='=== PROJECT MEMORY (STATE.md) ==='

state="${1:-${CLAUDE_PROJECT_DIR:-.}/.claude/memory/STATE.md}"

readonly READ_IT='=== Read .claude/memory/STATE.md whole before acting on what it holds. ==='

# The banner comes first on every path: the core reads its absence as hooks that did not run.
if [ ! -f "${state}" ]; then
  printf '%s\n' "${BANNER}" 'Memory not initialised: .claude/memory/STATE.md is missing (the framework setup guide copies it at step 1 and fills it at step 4)'
  exit 0
fi
if [ ! -r "${state}" ]; then
  printf '%s\n' "${BANNER}" '(STATE.md exists but cannot be read: check its permissions.)' "${READ_IT}"
  exit 0
fi

# The awk program: the lines read (CR dropped), the block comments taken out, the sections
# split on "## " outside code fences, then printed in their order within the budget.
# shellcheck disable=SC2016 # the program is awk's, not the shell's
program='
function units(s,   t, cont, astral) {
  # A line that is not valid UTF-8 — Windows-1252, a stray byte — counts one unit per byte:
  # a decoder makes one replacement character of each invalid byte at most.
  if (s ~ /[\200-\377]/) {
    t = s
    gsub(/[\302-\337][\200-\277]|\340[\240-\277][\200-\277]|[\341-\354\356\357][\200-\277][\200-\277]|\355[\200-\237][\200-\277]|\360[\220-\277][\200-\277][\200-\277]|[\361-\363][\200-\277][\200-\277][\200-\277]|\364[\200-\217][\200-\277][\200-\277]/, "", t)
    if (t ~ /[\200-\377]/) return length(s)
  }
  t = s; cont = gsub(/[\200-\277]/, "", t)
  t = s; astral = gsub(/[\360-\367]/, "", t)
  return length(s) - cont + astral
}
# The longest prefix of s within n units that does not split a UTF-8 sequence.
function prefix(s, n,   p, k) {
  p = substr(s, 1, n)
  while (length(p) > 0 && units(p) > n) p = substr(p, 1, length(p) - 1)
  # Back off a split sequence: at most three bytes, as many as follow a lead byte — a run of
  # stray continuation bytes is not one sequence.
  for (k = 0; k < 3 && length(p) > 0 && length(p) < length(s) && substr(s, length(p) + 1, 1) ~ /[\200-\277]/; k++) p = substr(p, 1, length(p) - 1)
  return p
}
{ sub(/\r$/, ""); raw[NR] = $0 }
END {
  # Block-level HTML comments out; one never closed is kept as it is.
  n = 0; incomment = 0; fence = 0
  for (i = 1; i <= NR; i++) {
    l = raw[i]
    if (!incomment && l ~ /^[ \t]*(```|~~~)/) fence = !fence
    if (!incomment && !fence && l ~ /^[ \t]*<!--/) { incomment = 1; from = i; keptat = n }
    if (incomment) {
      if (index(l, "-->")) {
        incomment = 0
        rest = l; sub(/^.*-->/, "", rest)
        if (rest ~ /[^ \t]/) line[++n] = rest
      }
      continue
    }
    line[++n] = l
  }
  if (incomment) { n = keptat; for (i = from; i <= NR; i++) line[++n] = raw[i] }

  # The sections: 0 is the preamble, before the first "## " title.
  s = 0; fence = 0; first[0] = 1
  for (i = 1; i <= n; i++) {
    if (line[i] ~ /^[ \t]*(```|~~~)/) fence = !fence
    if (!fence && line[i] ~ /^## /) { last[s] = i - 1; s++; first[s] = i; title[s] = line[i]; sub(/[ \t]+$/, "", title[s]) }
  }
  last[s] = n
  caution = 0; branches = 0; progress = 0
  for (k = 1; k <= s; k++) {
    if (!caution && title[k] == "## Caution & open issues") caution = k
    if (!branches && title[k] == "## Active branches") branches = k
    if (!progress && title[k] == "## Progress") progress = k
  }
  m = 0
  if (caution) order[++m] = caution
  order[++m] = 0
  if (branches) order[++m] = branches
  if (progress) order[++m] = progress
  for (k = 1; k <= s; k++) if (k != caution && k != branches && k != progress) order[++m] = k

  print banner
  if (!caution) print "(STATE.md has no \"## Caution & open issues\" section: no open issue is shown first. /fw:lint-memory flags it.)"
  used = 0; cut = 0; total = 0; full = 0; cutfrom = ""
  for (j = 1; j <= m; j++) {
    k = order[j]
    for (i = first[k]; i <= last[k]; i++) {
      u = units(line[i]) + 1
      total += u
      if (!full && used + u <= budget) { print line[i]; used += u; continue }
      if (!full) {
        full = 1
        cutfrom = (k == 0) ? "the lines before the first title" : title[k]
        p = prefix(line[i], budget - used - 1)
        if (length(p) > 0) { print p; used += units(p) + 1; cut += u - units(p) - 1; continue }
      }
      cut += u
    }
  }
  if (cut) {
    if (units(cutfrom) > 80) cutfrom = prefix(cutfrom, 80) "..."
    printf "=== STATE.md: %d of %d characters not shown (comments not counted), from %s on. Read .claude/memory/STATE.md whole before acting on what it holds. ===\n", cut, total, cutfrom
  }
}'

if out="$(LC_ALL=C awk -v budget="${BUDGET}" -v banner="${BANNER}" "${program}" "${state}" 2>/dev/null)" && [ -n "${out}" ]; then
  printf '%s\n' "${out}"
elif head -c 1 "${state}" >/dev/null 2>&1; then
  # The notice says bytes follow only once head has read the file: one the -r test passed can
  # still refuse a read — an ACL under Git Bash, whose noacl mount reports the mode bits only.
  printf '%s\n' "${BANNER}" "(scripts/state-inject.sh could not process the file: its first ${BUDGET} bytes follow, as they are.)"
  head -c "${BUDGET}" "${state}"
  printf '\n%s\n' "${READ_IT}"
else
  printf '%s\n' "${BANNER}" '(scripts/state-inject.sh could not process STATE.md, nor read it: check its permissions.)' "${READ_IT}"
fi
exit 0
