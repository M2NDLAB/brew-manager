#!/bin/zsh
# =============================================================================
# tests/test_guardrails.zsh — consent guard-rails of _ask / _read_choice
#
# The tool's core safety property (BM-08c gate finding): "non-interactive" (no
# usable stdin — a LaunchAgent, a pipe, cron, `ssh host cmd`) must NOT imply
# consent. Only an explicit --yes (BREW_MANAGER_YES=1) authorizes taking a
# prompt's built-in default. A non-interactive run WITHOUT --yes
# (BREW_MANAGER_NONINTERACTIVE=1) DECLINES every _ask — so a destructive default
# like mod_05's cleanup ("…now?" default y) never runs unattended.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"
source "$_ROOT/lib/common.sh" || { print -r -- "cannot source lib/common.sh"; exit 1; }

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }

# assert_ask <yes> <noninteractive> <default> <exp_rc>: _ask's return under the
# given consent state. Neither the --yes nor the non-interactive branch reads
# stdin, so this is deterministic. The safety-critical row is yes=0 ni=1 def=y →
# 1: a destructive default is DECLINED, never auto-confirmed.
assert_ask() {
    local _y="$1" _ni="$2" _def="$3" _exp="$4" _rc
    BREW_MANAGER_YES=$_y BREW_MANAGER_NONINTERACTIVE=$_ni _ask "test?" "$_def" >/dev/null 2>&1
    _rc=$?
    if (( _rc == _exp )); then
        _pass "_ask(yes=${_y} ni=${_ni} def=${_def}) rc=${_rc}"
    else
        _fail "_ask(yes=${_y} ni=${_ni} def=${_def}) rc=${_rc}, expected ${_exp}"
    fi
}

# assert_rc_choice <yes> <ni> <default> <expected>: _read_choice returns the
# (safe) default under --yes / non-interactive WITHOUT reading a dead stdin.
assert_rc_choice() {
    local _y="$1" _ni="$2" _def="$3" _exp="$4" _got
    _got="$(BREW_MANAGER_YES=$_y BREW_MANAGER_NONINTERACTIVE=$_ni _read_choice "p" "$_def" 2>/dev/null)"
    if [[ "$_got" == "$_exp" ]]; then
        _pass "_read_choice(yes=${_y} ni=${_ni} def=${_def}) = ${_got}"
    else
        _fail "_read_choice(yes=${_y} ni=${_ni} def=${_def}) = ${_got}, expected ${_exp}"
    fi
}

# ── --yes (explicit consent): take the built-in default ─────────────────────
assert_ask 1 0 y 0
assert_ask 1 0 n 1

# ── non-interactive WITHOUT --yes: DECLINE even a default-'y' prompt (CRITICAL,
#    this is what keeps mod_05 cleanup / mod_00 adopt from running unattended) ─
assert_ask 0 1 y 1
assert_ask 0 1 n 1

# ── an agent is BOTH non-interactive AND --yes → still takes the default, so
#    scheduled maintenance (e.g. cleanup) runs as intended ────────────────────
assert_ask 1 1 y 0
assert_ask 1 1 n 1

# ── a plain interactive session (both flags 0) is NOT exercised here: it reads
#    stdin. The two non-interactive branches above are the safety-relevant ones.

# ── _read_choice returns the default under --yes / non-interactive, never
#    blocking on a dead stdin (the value a --yes run would use) ───────────────
assert_rc_choice 1 0 all all
assert_rc_choice 0 1 all all
assert_rc_choice 0 1 n   n

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
