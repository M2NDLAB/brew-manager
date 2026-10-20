#!/usr/bin/env bash
# The framework's prerequisites, checked. Each tool is RUN, not only found — a tool can be
# installed and still not start —, its version compared with the minimum below, the platform
# named and held against the images the framework's CI runs, and the line ends git would give
# the framework's files looked at.
#
#   bash scripts/check-prerequisites.sh
#   bash scripts/check-prerequisites.sh --hooks                (what the hooks need: no make)
#   bash scripts/check-prerequisites.sh --commitlint-version   (the pin below, and nothing else)
#
# Runnable without make, from the project's root or from the framework's clone: the working
# directory is the repository whose line ends it reads. It installs NOTHING — installing
# system software stays a human action. Exit 1 when a tool is missing or does not start, and
# when a security minimum is not met (SECURITY_MINIMUMS, below); any other version below its
# minimum, or one it cannot read, is a warning: a minimum is the tool's own requirement read
# from its source, not a release run here.
set -euo pipefail

# --- The prerequisites, in one place ---------------------------------------------------------
# One line per tool: its name | its minimum ("-": none) | what needs it | where to install it.
#   git 2.31        `git rev-parse --path-format`, which hooks-install.sh and the upgrade use
#   bash 3.2        the oldest bash the framework's scripts are written for (macOS's bash)
#   gitleaks 8.18.2 a security minimum (read from gitleaks' source): the first release whose
#                   staged scan runs `git diff --no-ext-diff` — before it a configured
#                   external diff replaces what gitleaks reads —; from 8.4.0 to 8.18.1 a
#                   scan error also ended in "no leaks found" and 0, which 8.18.2 turns
#                   into exit 1; 8.0.0 to 8.1.3 wrote a .gitleaks.toml into the project.
#                   `protect --staged --redact -v`, the pre-commit's scan, exists from 8.0.0
#   node 22.12      the `engines` of commitlint at COMMITLINT, below; the agent git guard
#                   needs less
PREREQUISITES='git|2.31|the hooks and the upgrade (git rev-parse --path-format)|https://git-scm.com/downloads
bash|3.2|the scripts and the hooks|https://www.gnu.org/software/bash/
make|-|the process targets (make hooks-install, make test-scripts, make reset-task)|https://www.gnu.org/software/make/
gitleaks|8.18.2|the secret scan of the pre-commit hook|https://github.com/gitleaks/gitleaks#installing
node|22.12|commitlint at its pin (the commit-msg hook) and the agent git guard|https://nodejs.org/en/download
npx|-|commitlint, which the commit-msg hook runs|https://nodejs.org/en/download'
# commitlint, which the commit-msg hook runs through npx: its two packages, @commitlint/cli
# and @commitlint/config-conventional, at this version — hooks-install.sh reads it from
# here. Their own dependencies follow the ranges they declare. This version's `engines`
# require Node.js 22.12.0 or later (the npm registry): the minimum above.
COMMITLINT=21.2.3
# The POSIX tools the check probes, beyond bash's builtins: part of the userland the scripts
# and the hooks run, not all of it — tr, cut, head, mktemp, cp, mv, chmod and dirname go
# unprobed.
USERLAND='awk sed grep find xargs sort diff cmp'
# The tools the hooks never run: --hooks, which hooks-install.sh passes, leaves them out, so
# `bash scripts/hooks-install.sh` needs no make.
NOT_FOR_HOOKS='make'
# The tools whose minimum is a security minimum: below it the hook they serve can let through,
# in silence, what it exists to refuse. Below it, or with a version that cannot be read, so
# that the minimum cannot be confirmed, the check FAILS — and hooks-install.sh stops.
SECURITY_MINIMUMS='gitleaks'
# The images the framework's CI runs: the matrix of the framework's own workflow,
# .github/workflows/test.yml, which setup does not copy — the framework's documentation check
# fails when the two lists differ. platform(), below, reads each image as GitHub names it.
CI_IMAGES='ubuntu-24.04 macos-26 windows-2025'

skip=''
case "$*" in
  '') ;;
  --hooks) skip="${NOT_FOR_HOOKS}" ;;
  --commitlint-version)
    echo "${COMMITLINT}"
    exit 0 ;;
  *)
    echo "usage: bash scripts/check-prerequisites.sh [--hooks | --commitlint-version]" >&2
    exit 2 ;;
esac

fails=0
warns=0
say() { printf '%-6s %s\n' "$1" "$2"; }
fail() { fails=$((fails + 1)); say FAIL "$1"; }
warn() { warns=$((warns + 1)); say WARN "$1"; }

# first_line <text>: its first line, without the carriage return a Windows program ends it with.
first_line() { printf '%s\n' "$1" | sed -n '1p' | tr -d '\r' || true; }

# version_number <line>: the first dotted number in it — 2.39.5 in "git version 2.39.5 (Apple
# Git-154)", 3.2.57 in "GNU bash, version 3.2.57(1)-release".
version_number() { printf '%s\n' "$1" | sed -n 's/^[^0-9]*\([0-9][0-9]*\(\.[0-9][0-9]*\)*\).*/\1/p' || true; }

# at_least <version> <minimum>: true when the version is at or above the minimum, compared
# number by number — 22.9 is below 22.12, which a comparison of strings gets wrong. No
# `sort -V`: the BSD sort of older macOS releases lacks it.
at_least() {
  awk -v v="$1" -v m="$2" 'BEGIN {
    n = split(v, a, "."); k = split(m, b, ".")
    for (i = 1; i <= (n > k ? n : k); i++) {
      if (a[i] + 0 > b[i] + 0) exit 0
      if (a[i] + 0 < b[i] + 0) exit 1
    }
    exit 0
  }'
}

# version_of <tool>: the tool's version command. gitleaks has two, and before 8.19.0 each
# release answers only one: `--version` in 7.x, the `version` subcommand from 8.0.0 — a word
# 7.x reads as no command at all, scanning the working directory instead. So `--version`
# first, its output kept only when it answers; then `version`.
version_of() {
  local out
  if [[ "$1" != gitleaks ]]; then
    "$1" --version
  elif out="$(gitleaks --version 2>/dev/null)"; then
    printf '%s\n' "${out}"
  else
    gitleaks version
  fi
}

# A gitleaks version line, and nothing else: "8.30.1" and "v7.6.1" as its version commands
# print them, "gitleaks version 8.30.1" as `--version` does from 8.19.0. Any other line is
# not read: a 7.x scan's first line, a log line, holds a timestamp that reads as a number.
GITLEAKS_VERSION_LINE='^(gitleaks version )?v?[0-9]+(\.[0-9]+)+$'

# check_tool <tool> <minimum> <what needs it> <where to install it>
check_tool() {
  local tool="$1" min="$2" why="$3" page="$4" out line version
  if ! command -v "${tool}" >/dev/null 2>&1; then
    fail "${tool} not found: needed by ${why} — install it: ${page}"
    return 0
  fi
  if ! out="$(version_of "${tool}" 2>&1 </dev/null)"; then
    fail "${tool} is installed but does not start: $(first_line "${out}") — install it again: ${page}"
    return 0
  fi
  line="$(first_line "${out}")"
  version="$(version_number "${line}")"
  if [[ "${tool}" == gitleaks && ! "${line}" =~ ${GITLEAKS_VERSION_LINE} ]]; then
    version=''
  fi
  if [[ "${min}" == - ]]; then
    if [[ -n "${version}" ]]; then say OK "${tool} ${version}"; else say OK "${tool} runs"; fi
  elif [[ -n "${version}" ]] && at_least "${version}" "${min}"; then
    say OK "${tool} ${version} (${min} or later)"
  elif [[ " ${SECURITY_MINIMUMS} " == *" ${tool} "* ]]; then
    if [[ -z "${version}" ]]; then
      fail "${tool}: its version cannot be read (\"${line}\"); ${min} or later is the security minimum of ${why} — install a release: ${page}"
    else
      fail "${tool} ${version} is below ${min}, the security minimum of ${why} — install it: ${page}"
    fi
  elif [[ -z "${version}" ]]; then
    warn "${tool}: its version cannot be read (\"${line}\"); ${min} or later is needed by ${why} — ${page}"
  else
    warn "${tool} ${version} is below ${min}, needed by ${why} — ${page}"
  fi
}

# probe <tool>: runs a userland tool on nothing, the same way on GNU and BSD.
probe() {
  case "$1" in
    awk) awk 'BEGIN { exit 0 }' ;;
    sed) sed -n '1p' </dev/null ;;
    grep) printf 'x\n' | grep -q x ;;
    find) find /dev/null -prune ;;
    xargs) xargs </dev/null ;;
    sort) sort </dev/null ;;
    diff) diff /dev/null /dev/null ;;
    cmp) cmp /dev/null /dev/null ;;
  esac
}

check_userland() {
  local tool missing=""
  for tool in ${USERLAND}; do
    probe "${tool}" >/dev/null 2>&1 || missing="${missing} ${tool}"
  done
  if [[ -n "${missing}" ]]; then
    fail "the POSIX userland lacks${missing}, missing or not starting — macOS and Linux ship it; on Windows Git for Windows brings it: https://git-scm.com/downloads"
  else
    say OK "the POSIX userland: ${USERLAND}"
  fi
}

# The os-release file a Linux release is read from; the self-test points CHECK_OS_RELEASE at
# a file of its own.
OS_RELEASE_FILE="${CHECK_OS_RELEASE:-/etc/os-release}"

# os_release <key>: the key's value in the os-release file, its quotes removed; nothing when
# the file or the key is absent. Read, never sourced: the file is data, not a script.
os_release() {
  local line value
  [[ -r "${OS_RELEASE_FILE}" ]] || return 0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" == "$1="* ]] || continue
    value="${line#*=}"
    case "${value}" in
      \"*\" | \'*\') value="${value:1:${#value}-2}" ;;
    esac
    printf '%s\n' "${value}"
    return 0
  done < "${OS_RELEASE_FILE}"
}

# The platform, and whether the framework's CI verifies it: this machine against CI_IMAGES.
# macos-<release> is that major release of macOS on arm64, read from sw_vers; ubuntu-<release>
# is that release of Ubuntu on x86_64, WSL excluded, read from os-release; nothing else is a
# match. On Windows through Git Bash the windows-<year> images are named, never matched: Git
# Bash's uname gives a build number, not the edition an image runs (Windows Server).
platform() {
  local os arch name release id image match='' windows=''
  os="$(uname -s 2>/dev/null || echo unknown)"
  arch="$(uname -m 2>/dev/null || echo unknown)"
  case "${os}" in
    Darwin)
      release="$(first_line "$(sw_vers -productVersion 2>/dev/null || true)")"
      name="macOS${release:+ ${release}}"
      if [[ "${arch}" == arm64 && -n "${release}" ]]; then
        for image in ${CI_IMAGES}; do
          if [[ "${image}" == "macos-${release%%.*}" ]]; then match="${image}"; fi
        done
      fi ;;
    Linux)
      case "$(uname -r 2>/dev/null || true)" in
        *[Mm]icrosoft*) name="Linux under WSL" ;;
        *)
          id="$(os_release ID)"
          release="$(os_release VERSION_ID)"
          name="Linux${id:+, ${id}}${release:+ ${release}}"
          if [[ "${arch}" == x86_64 && "${id}" == ubuntu && -n "${release}" ]]; then
            for image in ${CI_IMAGES}; do
              if [[ "${image}" == "ubuntu-${release}" ]]; then match="${image}"; fi
            done
          fi ;;
      esac ;;
    MINGW* | MSYS*)
      name="Windows, Git Bash"
      if [[ "${arch}" == x86_64 ]]; then
        for image in ${CI_IMAGES}; do
          if [[ "${image}" =~ ^windows-[0-9]+$ ]]; then windows="${windows:+${windows} }${image}"; fi
        done
      fi ;;
    CYGWIN*) name="Windows, Cygwin" ;;
    *) name="${os}" ;;
  esac
  if [[ -n "${match}" ]]; then
    echo "check-prerequisites: ${name} (${arch}), verified by the framework's CI on ${match}"
  elif [[ -n "${windows}" ]]; then
    echo "check-prerequisites: ${name} (${arch}): the framework's CI runs ${windows} — this check does not tell Windows releases apart"
  else
    echo "check-prerequisites: ${name} (${arch}), not verified by the framework's CI, which runs ${CI_IMAGES}"
  fi
}

# Line ends: with core.autocrlf true, git checks text out with CRLF unless an attribute holds
# the file to LF — and bash cannot run a script with CRLF line ends. The test is the one the
# upgrade's line-end step makes: `git check-attr eol` on CLAUDE.md, from the repository's top
# level — the framework's attributes are anchored there, so from a subdirectory the path
# would name another file.
line_ends() {
  local autocrlf eol top
  if ! command -v git >/dev/null 2>&1 \
    || [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null || true)" != true ]]; then
    say SKIP "line ends: not inside a git repository"
    return 0
  fi
  top="$(git rev-parse --show-toplevel)"
  # The value that counts is the highest level's — the last entry `--get-regexp` lists —, never
  # `--type=bool --get`, which refuses as a whole when any level holds `input`, though a higher
  # one overrides it (measured on git 2.54.0: a global `input` under a repository's `true` read
  # as not true, and the warning below went unsaid). That one entry is read as git reads a
  # value: true, yes, on, any number but 0 and the key without a value — listed bare — are true;
  # input is no boolean — git refuses to read it as one — and is not true.
  local last
  last="$(git config --get-regexp '^core\.autocrlf$' 2>/dev/null | sed -n '$p' || true)"
  if [[ "${last}" == core.autocrlf ]]; then
    autocrlf=true
  elif [[ -n "${last}" ]]; then
    autocrlf="$(first_line "$(git -c "fwcheck.autocrlf=${last#core.autocrlf }" config --type=bool --get fwcheck.autocrlf 2>/dev/null || true)")"
  else
    autocrlf=""
  fi
  if [[ "${autocrlf}" != true ]]; then
    say OK "line ends: core.autocrlf is not true"
    return 0
  fi
  eol="$(first_line "$(git -C "${top}" check-attr eol -- CLAUDE.md 2>/dev/null || true)")"
  if [[ "${eol}" == "CLAUDE.md: eol: lf" ]]; then
    say OK "line ends: core.autocrlf is true, and .gitattributes holds the framework's files to LF"
  else
    warn "line ends: core.autocrlf is true and nothing holds the framework's files to LF — a checkout writes them with CRLF, which bash cannot run: bring in the framework's .gitattributes (the framework's SETUP.md, step 1)"
  fi
}

platform
while IFS='|' read -r tool min why page; do
  [[ -n "${tool}" ]] || continue
  case " ${skip} " in *" ${tool} "*) continue ;; esac
  check_tool "${tool}" "${min}" "${why}" "${page}"
done <<EOF
${PREREQUISITES}
EOF
check_userland
line_ends
echo "check-prerequisites: ${fails} FAIL, ${warns} WARN"
exit $((fails > 0))
