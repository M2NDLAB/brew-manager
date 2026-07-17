#!/bin/zsh
# =============================================================================
# tests/test_selection.zsh — parity tests for _resolve_selection (BM-08a)
#
# The project's first tests. Zero external dependencies (no bats): a plain zsh
# harness, run by `make test` or `zsh tests/test_selection.zsh`. Exit code is 0
# only if every check passed AND at least one check ran (anti-vacuity guard) —
# so a broken source or an emptied battery fails the build instead of passing
# silently.
#
# These lock the BEHAVIOUR the refactor had to preserve: the resolver is a
# straight move of the old inline parser, and this battery is the proof.
# =============================================================================

# Resolve the repo root from this script's own location (:A absolute, :h dir).
_ROOT="${0:A:h:h}"
source "$_ROOT/lib/common.sh"    || { print -r -- "cannot source lib/common.sh"; exit 1; }
source "$_ROOT/lib/selection.sh" || { print -r -- "cannot source lib/selection.sh"; exit 1; }

typeset -i TESTS_RUN=0 TESTS_FAILED=0

_pass() { (( TESTS_RUN += 1 ));                       print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }

# assert_list <spec> <expected>: resolve <spec>, join MODULES_TO_RUN with single
# spaces, compare to <expected>. Warnings (_warn → stdout) are silenced here;
# the list is read from the global the resolver populates, so the call must NOT
# run in a subshell.
assert_list() {
    local _spec="$1" _expected="$2" _got
    _resolve_selection "$_spec" >/dev/null 2>&1
    _got="${(j: :)MODULES_TO_RUN}"
    if [[ "$_got" == "$_expected" ]]; then
        _pass "spec='${_spec}' → [${_got}]"
    else
        _fail "spec='${_spec}' → got [${_got}], expected [${_expected}]"
    fi
}

# assert_warns <spec> <needle>: the resolver must emit a message containing
# <needle> for <spec>. Captured in a subshell (output only — the array result
# is irrelevant to this assertion).
assert_warns() {
    local _spec="$1" _needle="$2" _out
    _out="$(_resolve_selection "$_spec" 2>&1)"
    if [[ "$_out" == *"$_needle"* ]]; then
        _pass "spec='${_spec}' warns ('${_needle}')"
    else
        _fail "spec='${_spec}' expected a warning containing '${_needle}', got: ${_out}"
    fi
}

# assert_rc <spec> <expected>: the resolver returns 0 when MODULES_TO_RUN ended
# up non-empty and 1 when empty. This contract is NOT load-bearing on the
# interactive path today (which reads the array length), but BM-08b/c will wire
# the return code into CLI / scheduled dispatch — so pin it now.
assert_rc() {
    local _spec="$1" _expected="$2" _rc
    _resolve_selection "$_spec" >/dev/null 2>&1
    _rc=$?
    if (( _rc == _expected )); then
        _pass "rc(spec='${_spec}') = ${_rc}"
    else
        _fail "rc(spec='${_spec}') = ${_rc}, expected ${_expected}"
    fi
}

# assert_warn_count <spec> <n>: exactly <n> invalid-token warnings must appear —
# one line per invalid token, never deduped or collapsed. grep -c counts lines,
# and each _warn emits exactly one line.
assert_warn_count() {
    local _spec="$1" _expected="$2" _count
    _count="$(_resolve_selection "$_spec" 2>&1 | grep -c 'invalid')"
    if (( _count == _expected )); then
        _pass "warn_count(spec='${_spec}') = ${_count}"
    else
        _fail "warn_count(spec='${_spec}') = ${_count}, expected ${_expected}"
    fi
}

_ALL="0 1 2 3 4 5 6 7 8 9 10 11 12 13"   # the full 'go' sequence (MODULE_IDS)

# ── go / empty → full sequence ──────────────────────────────────────────────
assert_list "go"  "$_ALL"
assert_list "GO"  "$_ALL"
assert_list ""    "$_ALL"

# ── comma lists: order, dups and spaces preserved ───────────────────────────
assert_list "0,4,5"    "0 4 5"
assert_list "5,2,0"    "5 2 0"     # free order
assert_list "1,1,2,1"  "1 1 2 1"   # duplicates allowed
assert_list "0, 4, 5"  "0 4 5"     # inner spaces stripped
assert_list "10,13"    "10 13"     # two-digit ids

# ── named modules as a lone token ───────────────────────────────────────────
assert_list "log" "log"
assert_list "bk"  "bk"
assert_list "las" "las"
assert_list "mas" "mas"
assert_list "LOG" "log"            # whole-token uppercase special is accepted
assert_list "0,log,4" "0 log 4"    # lowercase special inside a list is kept

# ── invalid tokens are dropped ──────────────────────────────────────────────
assert_list "14"     ""            # numeric but not in the registry
assert_list "99"     ""
assert_list "0,99,4" "0 4"         # out-of-range id skipped, valid ones kept
assert_list "0,foo,4" "0 4"        # non-numeric junk skipped

# ── quirks preserved on purpose (parity, NOT fixes) ─────────────────────────
assert_list "Log"    ""            # mixed-case whole token does NOT match
assert_list "0,go"   "0"           # 'go' inside a list is dropped, 0 kept
assert_list "0,LOG,4" "0 4"        # special inside a list is case-SENSITIVE

# ── the drop must be observable, not silent ─────────────────────────────────
assert_warns "0,99,4"  "invalid"
assert_warns "0,foo,4" "invalid"

# ─────────────────────────────────────────────────────────────────────────────
# Parity hardening — closes the test-adequacy findings of the BM-08a security
# gate (2026-07-17). Each expected value was confirmed against the live resolver
# before being pinned here.
# ─────────────────────────────────────────────────────────────────────────────

# return-code contract: 0 when non-empty, 1 when empty
assert_rc "go"     0
assert_rc "0,4,5"  0
assert_rc "0,foo"  0            # one valid token kept → non-empty → 0
assert_rc "14"     1
assert_rc "99"     1
assert_rc "Log"    1
assert_rc " "      1           # lone space → empty

# whole-string leading/trailing whitespace: padding is literal, NOT trimmed —
# " go " does not expand to the full sequence (locks parity for future callers)
assert_list  " go " ""
assert_list  " "    ""
assert_warns " go " "invalid"

# empty tokens inside comma lists are dropped with a warning
assert_list  "0,,4" "0 4"
assert_list  "0,"   "0"        # trailing empty token
assert_list  ",0"   "0"        # leading empty token
assert_warns "0,,4" "invalid"

# warning fidelity: the offending token is NAMED, one warning per invalid token
assert_warns      "0,foo,4" "'foo'"
assert_warn_count "foo,bar" 2
assert_warn_count "0,4,5"   0

# uppercase named specials — the |BK/|LAS/|MAS case arms (only LOG was covered)
assert_list "BK"  "bk"
assert_list "LAS" "las"
assert_list "MAS" "mas"

# ── verdict + anti-vacuity ──────────────────────────────────────────────────
print -r -- ""
if (( TESTS_RUN == 0 )); then
    print -r -- "FAIL: no checks executed (anti-vacuity guard)"
    exit 1
fi
if (( TESTS_FAILED > 0 )); then
    print -r -- "FAIL: ${TESTS_FAILED}/${TESTS_RUN} checks failed"
    exit 1
fi
print -r -- "ok: all ${TESTS_RUN} checks passed"
exit 0
