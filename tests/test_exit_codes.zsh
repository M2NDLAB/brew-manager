#!/bin/zsh
# =============================================================================
# tests/test_exit_codes.zsh — end-to-end exit status of ./brew_manager.sh
#
# The tool re-execs itself under script(1) for session logging. The exit code
# a caller (launchd, a shell script, CI) observes is the PARENT's, so these
# checks invoke the real binary end-to-end: asserting the child's rc alone
# proved nothing — that gap is exactly how the "unknown token exits non-zero"
# claim shipped while the parent actually exited 0 (rc lost in the ANSI-strip
# step; see STATE Attenzione #4b and IMP-002). NOTE: module failures at
# runtime still exit 0 by design — that half of #4b is out of scope here.
#
# Isolation (gate finding, LOW): the binary runs from a symlink "farm" in a
# temp dir — SCRIPT_DIR resolves to the farm, so session logs land in the
# farm's logs/, never in the repo's (cleanup can't race a concurrent real
# session). A mock `brew` on PATH keeps the happy path off the real system;
# every run is non-interactive without --yes (fail-closed) and the happy path
# adds --dry-run, so nothing can mutate.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }

_SANDBOX="$(mktemp -d)" || { print -r -- "FAIL: mktemp"; exit 1; }
cleanup() { rm -rf "$_SANDBOX"; }
# On INT/TERM: clean up and STOP — without the exit, zsh would keep running
# the remaining checks against a deleted sandbox (gate finding, INFO).
trap 'cleanup; trap - EXIT; exit 130' INT TERM
trap cleanup EXIT

# Symlink farm: the entry point resolves SCRIPT_DIR from dirname($0) (cd+pwd,
# which does NOT follow file symlinks), so running the linked script from here
# keeps every path — including logs/ — inside the sandbox.
_FARM="$_SANDBOX/farm"
mkdir -p "$_FARM"
for _f in brew_manager.sh VERSION lib modules; do
    ln -s "$_ROOT/$_f" "$_FARM/$_f" || { print -r -- "FAIL: farm link $_f"; exit 1; }
done

# Mock brew: enough surface for a read-only module (mod_08 uses --prefix and
# list) and the summary footer. Every call appends to a tripwire file so the
# suite can prove the mock — not the real brew — was exercised.
_MOCKDIR="$_SANDBOX/mock"
mkdir -p "$_MOCKDIR"
cat > "$_MOCKDIR/brew" <<EOF
#!/bin/zsh
print -r -- "\$1" >> "$_MOCKDIR/brew_calls"
case "\$1" in
    --prefix) print -r -- "/usr/local" ;;
    --cache)  print -r -- "/tmp" ;;
esac
exit 0
EOF
chmod +x "$_MOCKDIR/brew"

# assert_exit <expected_rc> <label> <args...>: run the farm binary end-to-end
# (parent + script(1) re-exec) with the mock brew first on PATH, stdin closed.
assert_exit() {
    local _exp="$1" _label="$2"; shift 2
    local _rc
    PATH="$_MOCKDIR:$PATH" zsh "$_FARM/brew_manager.sh" "$@" </dev/null >/dev/null 2>&1
    _rc=$?
    if (( _rc == _exp )); then
        _pass "${_label}: rc=${_rc}"
    else
        _fail "${_label}: rc=${_rc}, expected ${_exp}"
    fi
}

# ── failures must be visible to the caller (the #4b parent-side fix). The two
#    checks below go THROUGH the script(1) wrapper (the propagation itself) ──
assert_exit 2 "unknown module token (99)"        99
assert_exit 1 "selection resolves empty (8 --skip=8)" 8 --skip=8

# ── parent-side guard (rejected BEFORE the re-exec: flag parser regression) ──
assert_exit 2 "unknown flag (--dryrun)"          --dryrun

# ── and a healthy run must NOT become a false failure (non-regression) ───────
assert_exit 0 "happy path (8 --dry-run)"         8 --dry-run

# ── minimal environment: the launchd / GUI-app case (STATE Attenzione #23) ───
# launchd gives a job PATH=/usr/bin:/bin:/usr/sbin:/sbin and nothing else, and a
# non-login zsh never reads ~/.zprofile. The probe of the standard Homebrew
# prefixes is exercised through a COPY of the entry point whose candidate
# constant points into the sandbox: production code carries no test hook, and
# the substitution itself is asserted (a renamed constant must fail the suite,
# not silently probe the real /opt/homebrew).
_LAUNCHD_PATH=/usr/bin:/bin:/usr/sbin:/sbin
_PREFIX="$_SANDBOX/prefix"
mkdir -p "$_PREFIX/bin" "$_PREFIX/sbin" "$_SANDBOX/home"
cat > "$_PREFIX/bin/brew" <<EOF
#!/bin/zsh
print -r -- "\$1" >> "$_PREFIX/brew_calls"
case "\$1" in
    --prefix) print -r -- "/usr/local" ;;
    --cache)  print -r -- "/tmp" ;;
esac
exit 0
EOF
chmod +x "$_PREFIX/bin/brew"

# _farm_with_candidates <dir> <candidate>: a farm whose brew_manager.sh is a copy
# with BREW_BIN_CANDIDATES rewritten to <candidate>. Fails unless exactly one
# line changed and that line is the rewritten constant.
_farm_with_candidates() {
    local _dir="$1" _cand="$2" _f
    mkdir -p "$_dir" || return 1
    for _f in VERSION lib modules; do ln -s "$_ROOT/$_f" "$_dir/$_f" || return 1; done
    sed "s|^BREW_BIN_CANDIDATES=(.*)\$|BREW_BIN_CANDIDATES=($_cand)|" \
        "$_ROOT/brew_manager.sh" > "$_dir/brew_manager.sh" || return 1
    [[ "$(diff "$_ROOT/brew_manager.sh" "$_dir/brew_manager.sh" | grep -c '^>')" == 1 ]] \
        && grep -qxF "BREW_BIN_CANDIDATES=($_cand)" "$_dir/brew_manager.sh"
}

# _run_minimal <farm> <out> <args...>: launchd's environment — env -i, launchd's
# PATH, a sandbox HOME, stdin closed — with the output kept for content checks.
_run_minimal() {
    local _farm="$1" _out="$2"; shift 2
    env -i HOME="$_SANDBOX/home" PATH="$_LAUNCHD_PATH" \
        /bin/zsh "$_farm/brew_manager.sh" "$@" </dev/null >"$_out" 2>&1
}

# Homebrew only at a probed prefix: the run must start and reach it through
# the script(1) re-exec (PATH is exported to the child).
if _farm_with_candidates "$_SANDBOX/farm_found" "$_PREFIX/bin/brew"; then
    _pass "probe farm: only the candidate constant differs"
    _run_minimal "$_SANDBOX/farm_found" "$_SANDBOX/out_found" 8 --dry-run
    _rc=$?
    if (( _rc == 0 )); then _pass "minimal env, brew at a probed prefix: rc=0"
    else _fail "minimal env, brew at a probed prefix: rc=${_rc}, expected 0"; fi
    if grep -q 'Running modules: 8' "$_SANDBOX/out_found"; then
        _pass "minimal env, brew at a probed prefix: the run started"
    else
        _fail "minimal env, brew at a probed prefix: the run did not start"
    fi
    if [[ -s "$_PREFIX/brew_calls" ]]; then
        _pass "the probed brew was used, through script(1)"
    else
        _fail "the probed brew was never called"
    fi
else
    _fail "probe farm: the candidate constant was not substituted"
fi

# Control (the teeth of the checks above): the same run with the candidate
# pointing at nothing must NOT start.
if _farm_with_candidates "$_SANDBOX/farm_missing" "$_SANDBOX/nowhere/bin/brew"; then
    _run_minimal "$_SANDBOX/farm_missing" "$_SANDBOX/out_missing" 8 --dry-run
    if grep -q 'Homebrew is not installed' "$_SANDBOX/out_missing" \
       && ! grep -q 'Running modules' "$_SANDBOX/out_missing"; then
        _pass "minimal env, no Homebrew anywhere: the run does not start"
    else
        _fail "minimal env, no Homebrew anywhere: unexpected output"
    fi
else
    _fail "missing farm: the candidate constant was not substituted"
fi

# ── tripwire: the runs above must have hit the MOCK brew, not the real one ───
if [[ -s "$_MOCKDIR/brew_calls" ]]; then
    _pass "mock brew was exercised ($(wc -l < "$_MOCKDIR/brew_calls" | tr -d ' ') calls)"
else
    _fail "mock brew was never invoked — checks may have run against real brew"
fi

# ── isolation: no session log may have leaked into the repo's logs/ ──────────
if [[ -n "$(find "$_FARM/logs" -name 'brew_report_*.log' 2>/dev/null | head -1)" ]]; then
    _pass "session logs landed in the sandbox farm"
else
    _fail "no logs in the farm — runs may have written to the repo's logs/"
fi

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
