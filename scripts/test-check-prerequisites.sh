#!/usr/bin/env bash
# Self-test of scripts/check-prerequisites.sh. Five cases:
#   1. every tool present, at or above its minimum: exit 0 and an OK line for each tool the
#      check lists, a version equal to its minimum included; asked for commitlint's pin, it
#      prints the version it defines — see "Case 1";
#   2. a tool missing, one installed that does not start, a userland tool missing: exit 1, a
#      FAIL line for each with where to install it, and the other tools still checked; with
#      --hooks, a make that does not start is left out — the hooks never run make. gitleaks
#      below its minimum, a security minimum, or with a version that cannot be read: a FAIL
#      too — its version read as each of its command lines gives it, and a line that is not
#      a version not read as one;
#   3. any other version below its minimum — compared number by number: 22.9 is below 22.12 —
#      and one that cannot be read: a WARN line each, exit 0;
#   4. the platform, against the images the framework's CI runs, read from the check's own
#      CI_IMAGES: macOS of the macos- image's release on arm64 (sw_vers) and Ubuntu of the
#      ubuntu- image's release on x86_64 (os-release, in each of its quotings) said to be
#      verified; another release, distribution or architecture, WSL, a release unread, Cygwin
#      and another system said not to be; Windows through Git Bash on x86_64 given the
#      windows- image's name and no verdict;
#   5. line ends: core.autocrlf true — the highest level's value, a global `input` under a
#      repository's `true` included — with nothing holding the framework's files to LF warns —
#      true as git reads it: 2, or the key without a value, too; held to LF — read from a
#      subdirectory too —, or core.autocrlf not true, input included, it does not; outside a
#      repository, not checked.
#
# HERMETIC: the tools are stubs in a PATH of the test's own, beside wrappers for the real
# tools the check itself runs — wrappers, not links: Git Bash's `ln -s` copies a binary away
# from the DLL it loads (measured in the CI on Windows). git's stub answers --version and
# hands every other call to the real git, on throwaway repositories only.
set -euo pipefail

# Hermetic against the user's own git configuration and the caller's git environment, as the
# other self-tests are: a system core.autocrlf (Git for Windows sets one) would change case 5.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
unset $(git rev-parse --local-env-vars) GIT_TEMPLATE_DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHECK="${SCRIPT_DIR}/check-prerequisites.sh"

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT
# Keeps git from finding a repository above the throwaway ones (case 5, outside).
export GIT_CEILING_DIRECTORIES="${workdir}"
out="${workdir}/out"
rc=-

fail() {
  echo "FAIL (prerequisite check): $1" >&2
  if [[ -f "${out}" ]]; then
    echo "--- its output (exit ${rc}) ---" >&2
    cat "${out}" >&2
  fi
  exit 1
}

# The real tools the check runs on its own account, and the userland it probes, as wrappers;
# echo for xargs, which GNU's runs once on empty input. `type -P`: the program, not a builtin.
REAL_GIT="$(type -P git)"
real="${workdir}/real"
mkdir -p "${real}"
for tool in awk sed grep find xargs sort diff cmp tr uname echo; do
  printf '#!/bin/sh\nexec "%s" "$@"\n' "$(type -P "${tool}")" > "${real}/${tool}"
  chmod +x "${real}/${tool}"
done

# stub <dir> <tool> <first line> [exit code]: a tool that prints its line and exits — on
# stderr when the exit code says it did not start.
stub() {
  mkdir -p "$1"
  if [[ "${4:-0}" == 0 ]]; then
    printf '#!/bin/sh\necho %s\n' "'$3'" > "$1/$2"
  else
    printf '#!/bin/sh\necho %s >&2\nexit %s\n' "'$3'" "$4" > "$1/$2"
  fi
  chmod +x "$1/$2"
}
# git_stub <dir> <first line>: git answering --version itself and handing the rest on.
git_stub() {
  mkdir -p "$1"
  printf '#!/bin/sh\nif [ "$1" = --version ]; then echo %s; exit 0; fi\nexec "%s" "$@"\n' \
    "'$2'" "${REAL_GIT}" > "$1/git"
  chmod +x "$1/git"
}
# gitleaks_stub <dir> <version> <command line>: gitleaks as its source shows each of its
# command lines. 7 — 7.x, go-flags: `--version` prints v<version>; any other word is read as
# nothing, and `gitleaks version` scans the working directory, its first line a log line
# with a timestamp (v7.6.1's options.go and scan.go). 8 — 8.0.0 to 8.18.x, cobra: the
# `version` subcommand only; `--version` is an unknown flag. 8.19 — from 8.19.0: both, and
# `--version` prints "gitleaks version <version>". misread — the answer the review measured:
# `--version` refused, and a scan's log line where `version` should print the version.
gitleaks_stub() {
  mkdir -p "$1"
  local scan_line='echo "time=\"2026-10-12T21:43:30+02:00\" level=info msg=\"opening .\"" >&2'
  case "$3" in
    7) printf '#!/bin/sh\nif [ "$1" = --version ]; then echo v%s; exit 0; fi\n%s\nexit 0\n' "$2" "${scan_line}" ;;
    8) printf '#!/bin/sh\nif [ "$1" = version ]; then echo %s; exit 0; fi\necho "Error: unknown flag: $1" >&2\nexit 1\n' "$2" ;;
    8.19) printf '#!/bin/sh\ncase "$1" in --version) echo "gitleaks version %s" ;; version) echo %s ;; *) exit 1 ;; esac\n' "$2" "$2" ;;
    misread) printf '#!/bin/sh\nif [ "$1" = --version ]; then echo "Error: unknown flag: --version" >&2; exit 1; fi\n%s\nexit 0\n' "${scan_line}" ;;
  esac > "$1/gitleaks"
  chmod +x "$1/gitleaks"
}
# good <dir>: every tool present; git, gitleaks and node exactly at their minimums.
good() {
  git_stub "$1" 'git version 2.31.0'
  stub "$1" bash 'GNU bash, version 3.2.57(1)-release (arm64-apple-darwin26)'
  stub "$1" make 'GNU Make 3.81'
  gitleaks_stub "$1" 8.18.2 8
  stub "$1" node 'v22.12.0'
  stub "$1" npx '10.9.2'
}
# run <stub dir> <working directory> [userland dir]: the check, with only these on PATH.
run() {
  set +e
  (cd "$2" && PATH="$1:${3:-${real}}" "${BASH}" "${CHECK}") >"${out}" 2>&1
  rc=$?
  set -e
}
has() { grep -qE -e "$1" "${out}" || fail "$2"; }
lacks() { ! grep -qE -e "$1" "${out}" || fail "$2"; }

lf_repo="${workdir}/lf"
git init -q "${lf_repo}"

# --- Case 1 — every tool present, at or above its minimum --------------------------------------
# The tools are read from the check's own list, so a tool added there without a stub here fails.
tools="$(sed -n "/^PREREQUISITES='/,/'\$/p" "${CHECK}" | sed "s/^PREREQUISITES='//" | cut -d'|' -f1)"
[[ "$(printf '%s\n' "${tools}" | grep -c .)" -ge 6 ]] || fail "fewer than six tools read from the check's PREREQUISITES: the extraction is wrong"
good "${workdir}/case1"
run "${workdir}/case1" "${lf_repo}"
[[ ${rc} -eq 0 ]] || fail "every tool present: expected exit 0, got ${rc}"
for tool in ${tools}; do
  has "^OK +${tool} " "every tool present: no OK line for ${tool}"
done
has '^OK +git 2\.31\.0 \(2\.31 or later\)$' "git exactly at its minimum is not OK"
has '^OK +node 22\.12\.0 \(22\.12 or later\)$' "node exactly at its minimum is not OK"
has '^OK +bash 3\.2\.57 \(3\.2 or later\)$' "bash above its minimum is not OK"
has '^OK +make 3\.81$' "make, which has no minimum, is not a plain OK line"
has '^OK +gitleaks 8\.18\.2 \(8\.18\.2 or later\)$' "gitleaks exactly at its minimum, through its version subcommand, is not OK"
has '^OK +npx 10\.9\.2$' "npx, which has no minimum, is not a plain OK line"
has '^OK +the POSIX userland: ' "the userland present is not OK"
lacks '^(WARN|FAIL) ' "every tool present: a WARN or a FAIL line"
has '^check-prerequisites: 0 FAIL, 0 WARN$' "every tool present: the summary is not 0 FAIL, 0 WARN"
# A gitleaks from 8.19.0 on answers --version as "gitleaks version <version>".
gitleaks_stub "${workdir}/case1" 8.30.1 8.19
run "${workdir}/case1" "${lf_repo}"
has '^OK +gitleaks 8\.30\.1 \(8\.18\.2 or later\)$' "a gitleaks from 8.19.0 on, through --version, is not OK"
# Asked for commitlint's pin, it prints the version its own COMMITLINT line defines, alone.
pin="$(sed -n 's/^COMMITLINT=//p' "${CHECK}")"
[[ -n "${pin}" ]] || fail "no COMMITLINT= line read from the check: the extraction is wrong"
[[ "$("${BASH}" "${CHECK}" --commitlint-version)" == "${pin}" ]] \
  || fail "--commitlint-version does not print the pin alone, ${pin}"

# --- Case 2 — a tool missing, one that does not start, a userland tool missing -----------------
good "${workdir}/case2"
rm "${workdir}/case2/gitleaks"
stub "${workdir}/case2" node 'dyld[4242]: Library not loaded: @rpath/libnode.127.dylib' 134
no_cmp="${workdir}/no-cmp"
mkdir -p "${no_cmp}"
cp "${real}"/* "${no_cmp}/"
rm "${no_cmp}/cmp"
run "${workdir}/case2" "${lf_repo}" "${no_cmp}"
[[ ${rc} -eq 1 ]] || fail "tools missing or not starting: expected exit 1, got ${rc}"
has '^FAIL +gitleaks not found: .*https://github\.com/gitleaks/gitleaks#installing$' \
  "a missing gitleaks: no FAIL line with where to install it"
has '^FAIL +node is installed but does not start: dyld\[4242\]: Library not loaded.*https://nodejs\.org/' \
  "a node that does not start: no FAIL line with its error and where to install it"
has '^FAIL +the POSIX userland lacks cmp,' "a missing cmp: no FAIL line naming it"
has '^OK +npx 10\.9\.2$' "after a failure, the tools listed after it were not checked"
has '^check-prerequisites: 3 FAIL, 0 WARN$' "tools missing or not starting: the summary is not 3 FAIL, 0 WARN"
# --hooks, as hooks-install.sh runs it: make is not the hooks', even when it does not start.
good "${workdir}/case2-hooks"
stub "${workdir}/case2-hooks" make 'make: error while loading shared libraries' 127
set +e
(cd "${lf_repo}" && PATH="${workdir}/case2-hooks:${real}" "${BASH}" "${CHECK}" --hooks) >"${out}" 2>&1
rc=$?
set -e
[[ ${rc} -eq 0 ]] || fail "--hooks with a make that does not start: expected exit 0, got ${rc}"
lacks '^(OK|FAIL) +make' "--hooks checked make, which the hooks never run"
has '^OK +gitleaks ' "--hooks left out gitleaks, which the pre-commit hook runs"
# gitleaks' minimum is a security minimum: below it, or unread, the scan cannot be trusted.
# gitleaks_fails <version> <command line> <the FAIL line's pattern> <what it is>
gitleaks_fails() {
  good "${workdir}/case2-gitleaks"
  gitleaks_stub "${workdir}/case2-gitleaks" "$1" "$2"
  run "${workdir}/case2-gitleaks" "${lf_repo}"
  [[ ${rc} -eq 1 ]] || fail "$4: expected exit 1, got ${rc}"
  has "$3" "$4: no FAIL line with where to install it"
  has '^check-prerequisites: 1 FAIL, 0 WARN$' "$4: the summary is not 1 FAIL, 0 WARN"
}
gitleaks_fails 8.18.1 8 \
  '^FAIL +gitleaks 8\.18\.1 is below 8\.18\.2, the security minimum of .*https://github\.com/gitleaks/gitleaks#installing$' \
  "gitleaks 8.18.1, just below its security minimum"
gitleaks_fails 7.6.1 7 '^FAIL +gitleaks 7\.6\.1 is below 8\.18\.2, the security minimum of ' \
  "gitleaks 7.6.1, read through --version"
# A scan's log line where the version should be: its timestamp is not read as a version.
gitleaks_fails '' misread \
  '^FAIL +gitleaks: its version cannot be read \("time=.*8\.18\.2 or later is the security minimum of .*https://github\.com/gitleaks/gitleaks#installing$' \
  "gitleaks answering with a log line"

# --- Case 3 — below a minimum, or a version that cannot be read: warnings only -----------------
good "${workdir}/case3"
git_stub "${workdir}/case3" 'git version unknown'
stub "${workdir}/case3" bash 'GNU bash, version 3.1.17(1)-release (x86_64-pc-linux-gnu)'
stub "${workdir}/case3" node 'v22.9.0'
run "${workdir}/case3" "${lf_repo}"
[[ ${rc} -eq 0 ]] || fail "below a minimum: expected exit 0 (a warning, never a failure), got ${rc}"
has '^WARN +bash 3\.1\.17 is below 3\.2, needed by .*https://www\.gnu\.org/software/bash/$' \
  "bash below its minimum: no WARN line with where to install it"
has '^WARN +node 22\.9\.0 is below 22\.12, needed by ' "node 22.9.0 is not below 22.12: the comparison is not number by number"
has '^WARN +git: its version cannot be read \("git version unknown"\); 2\.31 or later is needed' \
  "git's version unread: no WARN line"
lacks '^FAIL ' "below a minimum: a FAIL line"
has '^check-prerequisites: 0 FAIL, 3 WARN$' "below a minimum: the summary is not 0 FAIL, 3 WARN"

# --- Case 4 — the platform, against the images the framework's CI runs ---------------------------
# The images are read from the check's own CI_IMAGES, so the cases follow the list.
images="$(sed -n "s/^CI_IMAGES='\([^']*\)'\$/\1/p" "${CHECK}")"
mac_release='' ubuntu_release='' windows_images=''
for image in ${images}; do
  if [[ "${image}" =~ ^macos-([0-9]+)$ && -z "${mac_release}" ]]; then mac_release="${BASH_REMATCH[1]}"; fi
  if [[ "${image}" =~ ^ubuntu-([0-9]+\.[0-9]+)$ && -z "${ubuntu_release}" ]]; then ubuntu_release="${BASH_REMATCH[1]}"; fi
  if [[ "${image}" =~ ^windows-[0-9]+$ ]]; then windows_images="${windows_images:+${windows_images} }${image}"; fi
done
[[ -n "${mac_release}" && -n "${ubuntu_release}" && -n "${windows_images}" ]] \
  || fail "no macos-, ubuntu- or windows- image read from the check's CI_IMAGES (\"${images}\"): the extraction is wrong"
# The os-release file the check reads in place of /etc/os-release.
export CHECK_OS_RELEASE="${workdir}/os-release"
# platform_is <uname -s> <uname -m> <uname -r> <the release: sw_vers's on Darwin, the
#   os-release file's lines elsewhere; - for none> <what the first line must say>
platform_is() {
  local dir="${workdir}/case4"
  good "${dir}"
  printf '#!/bin/sh\ncase "$1" in -s) echo %s ;; -m) echo %s ;; -r) echo %s ;; esac\n' \
    "'$1'" "'$2'" "'$3'" > "${dir}/uname"
  chmod +x "${dir}/uname"
  rm -f "${dir}/sw_vers" "${CHECK_OS_RELEASE}"
  if [[ "$4" != - && "$1" == Darwin ]]; then
    printf '#!/bin/sh\n[ "$1" = -productVersion ] && echo %s\n' "'$4'" > "${dir}/sw_vers"
    chmod +x "${dir}/sw_vers"
  elif [[ "$4" != - ]]; then
    printf '%b\n' "$4" > "${CHECK_OS_RELEASE}"
  fi
  run "${dir}" "${lf_repo}"
  [[ "$(sed -n 1p "${out}")" == "check-prerequisites: $5" ]] \
    || fail "uname $1, $2, $3, release \"$4\": the first line is not \"check-prerequisites: $5\""
}
verified="verified by the framework's CI on"
not_verified="not verified by the framework's CI, which runs ${images}"
ubuntu_file="PRETTY_NAME=\"Ubuntu ${ubuntu_release}.5 LTS\"\nNAME=\"Ubuntu\"\nVERSION_ID=\"${ubuntu_release}\"\nVERSION=\"${ubuntu_release}.5 LTS\"\nID=ubuntu\nID_LIKE=debian"
platform_is Darwin arm64 25.6.0 "${mac_release}.6.2" "macOS ${mac_release}.6.2 (arm64), ${verified} macos-${mac_release}"
platform_is Darwin arm64 27.0.0 "$((mac_release + 1)).0.1" "macOS $((mac_release + 1)).0.1 (arm64), ${not_verified}"
platform_is Darwin x86_64 25.6.0 "${mac_release}.6.2" "macOS ${mac_release}.6.2 (x86_64), ${not_verified}"
platform_is Darwin arm64 25.6.0 - "macOS (arm64), ${not_verified}"
platform_is Linux x86_64 6.11.0-1018-azure "${ubuntu_file}" "Linux, ubuntu ${ubuntu_release} (x86_64), ${verified} ubuntu-${ubuntu_release}"
platform_is Linux x86_64 6.11.0-1018-azure "ID='ubuntu'\nVERSION_ID=${ubuntu_release}" "Linux, ubuntu ${ubuntu_release} (x86_64), ${verified} ubuntu-${ubuntu_release}"
platform_is Linux x86_64 6.8.0-45-generic 'ID=ubuntu\nVERSION_ID="16.04"' "Linux, ubuntu 16.04 (x86_64), ${not_verified}"
platform_is Linux x86_64 6.8.0-45-generic "ID=linuxmint\nID_LIKE=\"ubuntu debian\"\nVERSION_ID=\"${ubuntu_release}\"" "Linux, linuxmint ${ubuntu_release} (x86_64), ${not_verified}"
platform_is Linux x86_64 6.1.0-25-amd64 'ID=debian\nVERSION_ID="12"' "Linux, debian 12 (x86_64), ${not_verified}"
platform_is Linux x86_64 6.11.0-1018-azure - "Linux (x86_64), ${not_verified}"
platform_is Linux aarch64 6.8.0-1009-raspi "${ubuntu_file}" "Linux, ubuntu ${ubuntu_release} (aarch64), ${not_verified}"
platform_is Linux x86_64 5.15.167.4-microsoft-standard-WSL2 "${ubuntu_file}" "Linux under WSL (x86_64), ${not_verified}"
platform_is MINGW64_NT-10.0-26100 x86_64 3.5.4-0bc1222b.x86_64 - "Windows, Git Bash (x86_64): the framework's CI runs ${windows_images} — this check does not tell Windows releases apart"
platform_is MSYS_NT-10.0-26100 x86_64 3.5.4-0bc1222b.x86_64 - "Windows, Git Bash (x86_64): the framework's CI runs ${windows_images} — this check does not tell Windows releases apart"
platform_is MINGW64_NT-10.0-26100 aarch64 3.5.4-0bc1222b.aarch64 - "Windows, Git Bash (aarch64), ${not_verified}"
platform_is CYGWIN_NT-10.0-26100 x86_64 3.5.4-1.x86_64 - "Windows, Cygwin (x86_64), ${not_verified}"
platform_is FreeBSD amd64 14.1-RELEASE - "FreeBSD (amd64), ${not_verified}"
unset CHECK_OS_RELEASE

# --- Case 5 — line ends ------------------------------------------------------------------------
good "${workdir}/case5"
crlf_repo="${workdir}/crlf"
git init -q "${crlf_repo}"
git -C "${crlf_repo}" config core.autocrlf true
held_repo="${workdir}/held"
git init -q "${held_repo}"
git -C "${held_repo}" config core.autocrlf true
cp "${REPO_ROOT}/.gitattributes" "${held_repo}/.gitattributes"
outside="${workdir}/outside"
mkdir -p "${outside}"

run "${workdir}/case5" "${crlf_repo}"
[[ ${rc} -eq 0 ]] || fail "core.autocrlf true, nothing holding LF: expected exit 0 (a warning), got ${rc}"
has '^WARN +line ends: core\.autocrlf is true and nothing holds the framework.s files to LF' \
  "core.autocrlf true with nothing holding the framework's files to LF: no WARN line"
has '^check-prerequisites: 0 FAIL, 1 WARN$' "core.autocrlf true, nothing holding LF: the summary is not 0 FAIL, 1 WARN"
# True as git reads it, beyond the words: a number other than 0, and the key without a value.
for value in 2 bare; do
  odd_repo="${workdir}/autocrlf-${value}"
  git init -q "${odd_repo}"
  if [[ ${value} == bare ]]; then
    printf '[core]\n\tautocrlf\n' >> "${odd_repo}/.git/config"
  else
    git -C "${odd_repo}" config core.autocrlf "${value}"
  fi
  [[ "$(git -C "${odd_repo}" config --type=bool --get core.autocrlf)" == true ]] \
    || fail "core.autocrlf ${value}: git does not read it as true, so the case would prove nothing"
  run "${workdir}/case5" "${odd_repo}"
  has '^WARN +line ends: core\.autocrlf is true and nothing holds' \
    "core.autocrlf ${value}, true for git: no WARN line"
done
input_repo="${workdir}/autocrlf-input"
git init -q "${input_repo}"
git -C "${input_repo}" config core.autocrlf input
run "${workdir}/case5" "${input_repo}"
has '^OK +line ends: core\.autocrlf is not true$' "core.autocrlf input: not read as not true"
[[ ${rc} -eq 0 ]] || fail "core.autocrlf input: expected exit 0, got ${rc}"
run "${workdir}/case5" "${held_repo}"
has '^OK +line ends: core\.autocrlf is true, and \.gitattributes holds' \
  "core.autocrlf true with the framework's .gitattributes: no OK line for the line ends"
lacks '^WARN ' "core.autocrlf true with the framework's .gitattributes: a WARN line"
# From a subdirectory: the framework's attributes are anchored at the top level, where the
# check must read them (measured: from below, git check-attr names another path).
mkdir -p "${held_repo}/sub"
run "${workdir}/case5" "${held_repo}/sub"
lacks '^WARN ' "core.autocrlf true with the framework's .gitattributes, run from a subdirectory: a WARN line"
run "${workdir}/case5" "${lf_repo}"
has '^OK +line ends: core\.autocrlf is not true$' "core.autocrlf unset: no OK line for the line ends"
run "${workdir}/case5" "${outside}"
has '^SKIP +line ends: not inside a git repository$' "outside a repository: the line ends not said to be unchecked"
[[ ${rc} -eq 0 ]] || fail "outside a repository: expected exit 0, got ${rc}"
# Under the configurations users have, the hermetic baseline aside: the value that counts is the
# highest level's. A global `input` under a repository's `true` — the rehearsal's own case
# (2026-10-18), where `git config --type=bool --get` refuses as a whole — is true; a global
# `true` under a repository's `input` is not.
printf '[core]\n\tautocrlf = input\n' > "${workdir}/global-input.cfg"
printf '[core]\n\tautocrlf = true\n' > "${workdir}/global-true.cfg"
export GIT_CONFIG_GLOBAL="${workdir}/global-input.cfg"
! git -C "${crlf_repo}" config --type=bool --get core.autocrlf >/dev/null 2>&1 \
  || fail "a global input under a local true: git reads it as one boolean, so the case would prove nothing"
run "${workdir}/case5" "${crlf_repo}"
has '^WARN +line ends: core\.autocrlf is true and nothing holds' \
  "a global core.autocrlf input under the repository's true, nothing holding LF: no WARN line"
run "${workdir}/case5" "${held_repo}"
has '^OK +line ends: core\.autocrlf is true, and \.gitattributes holds' \
  "a global core.autocrlf input under the repository's true, with the framework's .gitattributes: no OK line"
run "${workdir}/case5" "${odd_repo}"
has '^WARN +line ends: core\.autocrlf is true and nothing holds' \
  "a global core.autocrlf input under the repository's key without a value: no WARN line"
export GIT_CONFIG_GLOBAL="${workdir}/global-true.cfg"
run "${workdir}/case5" "${input_repo}"
has '^OK +line ends: core\.autocrlf is not true$' "a global core.autocrlf true under the repository's input: not read as not true"
export GIT_CONFIG_GLOBAL=/dev/null

echo "PASS (prerequisite check): every tool run and held against its minimum number by number — a FAIL for a tool missing or not starting and for gitleaks below its security minimum or unread, a WARN for any other version below its minimum or unread —, the platform verified only on the release and architecture of an image the CI runs, Windows given its image's name and no verdict, the line ends warned about only where git would write CRLF."
