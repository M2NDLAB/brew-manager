#!/bin/zsh
# =============================================================================
# tests/test_exit_codes.zsh — end-to-end exit status of ./brew_manager.sh
#
# The tool re-execs itself under script(1) for session logging. The exit code
# a caller (launchd, a shell script, CI) observes is the PARENT's, so these
# checks invoke the real binary end-to-end: asserting the child's rc alone
# proved nothing — that gap is exactly how the "unknown token exits non-zero"
# claim shipped while the parent actually exited 0 (rc lost in the ANSI-strip
# step; see STATE Attenzione #4b and IMP-002).
#
# A mock `brew` on PATH keeps the happy path off the real system; every run is
# non-interactive without --yes (fail-closed: prompts declined) and the happy
# path adds --dry-run, so nothing can mutate. NOTE: module failures at
# runtime still exit 0 by design — that half of #4b is out of scope here.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }

# Mock brew: enough surface for a read-only module (mod_08 uses --prefix and
# list) and the summary footer. Anything else succeeds silently.
_MOCKDIR="$(mktemp -d)" || { print -r -- "FAIL: mktemp"; exit 1; }
# Timestamp reference: lets the cleanup delete ONLY the session logs these
# runs create, not pre-existing ones.
_T0="$_MOCKDIR/t0"; : > "$_T0"
cleanup() {
    find "$_ROOT/logs" -name 'brew_report_*.log' -newer "$_T0" -delete 2>/dev/null
    rm -rf "$_MOCKDIR"
}
trap cleanup EXIT INT TERM

cat > "$_MOCKDIR/brew" <<'EOF'
#!/bin/zsh
case "$1" in
    --prefix) print -r -- "/usr/local" ;;
    --cache)  print -r -- "/tmp" ;;
    list)     ;;  # empty: no packages installed
    *)        ;;
esac
exit 0
EOF
chmod +x "$_MOCKDIR/brew"

# assert_exit <expected_rc> <label> <args...>: run the real binary end-to-end
# (parent + script(1) re-exec) with the mock brew first on PATH, stdin closed.
assert_exit() {
    local _exp="$1" _label="$2"; shift 2
    local _rc
    PATH="$_MOCKDIR:$PATH" zsh "$_ROOT/brew_manager.sh" "$@" </dev/null >/dev/null 2>&1
    _rc=$?
    if (( _rc == _exp )); then
        _pass "${_label}: rc=${_rc}"
    else
        _fail "${_label}: rc=${_rc}, expected ${_exp}"
    fi
}

# ── failures must be visible to the caller (the #4b parent-side fix) ─────────
assert_exit 2 "unknown module token (99)"        99
assert_exit 2 "unknown flag (--dryrun)"          --dryrun
assert_exit 1 "selection resolves empty (8 --skip=8)" 8 --skip=8

# ── and a healthy run must NOT become a false failure ────────────────────────
assert_exit 0 "happy path (8 --dry-run)"         8 --dry-run

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
