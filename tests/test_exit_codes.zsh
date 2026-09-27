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
# The minimal-environment checks reproduce what launchd gives a job (env -i,
# PATH=/usr/bin:/bin:/usr/sbin:/sbin, no terminal): Homebrew found at a
# standard prefix, or exit 69 with no installer prompt (STATE Attenzione #23).
# Each clause of the no-terminal guard is exercised on its own, the exit order
# of docs/04 is pinned, a `brew` that is only a shell function or alias does not
# count as Homebrew, and the failed-install exit is pinned statically (a test
# must never confirm the installer).
#
# Isolation (gate finding, LOW): the binary runs from a symlink "farm" in a
# temp dir — SCRIPT_DIR resolves to the farm, so session logs land in the
# farm's logs/, never in the repo's (cleanup can't race a concurrent real
# session). A mock `brew` on PATH keeps the happy path off the real system;
# every run is non-interactive without --yes (fail-closed) and the happy path
# adds --dry-run, so nothing can mutate. The no-Homebrew runs put a tripwire
# `curl` first on PATH and point the proxies at a closed port, so even a missed
# tripwire could not reach the network. Every run goes through a watchdog that
# kills its whole process group: a regression that blocks cannot hang the suite
# or leave script(1) children behind.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }
# _check <label> <command...>: pass when the command succeeds.
_check() { local _l="$1"; shift; if "$@"; then _pass "$_l"; else _fail "$_l"; fi; }

_SANDBOX="$(mktemp -d)" || { print -r -- "FAIL: mktemp"; exit 1; }
cleanup() { rm -rf "$_SANDBOX"; }
# On INT/TERM: clean up and STOP — without the exit, zsh would keep running
# the remaining checks against a deleted sandbox (gate finding, INFO).
trap 'cleanup; trap - EXIT; exit 130' INT TERM
trap cleanup EXIT

# _guarded <seconds> <command...>: run the command in its own process group and
# return its exit status; after <seconds> kill the whole group and return 124.
# A plain `alarm; exec` would kill only the direct child and orphan script(1)'s
# session (gate finding): the group kill, plus a sweep of anything still running
# from this sandbox's unique path, leaves nothing behind.
_guarded() {
    local _secs="$1" _rc; shift
    /usr/bin/perl -e '
        my $t = shift;
        my $pid = fork() // die "fork: $!";
        if ($pid == 0) { setpgrp(0, 0); exec @ARGV or exit 127 }
        local $SIG{ALRM} = sub { kill "KILL", -$pid; waitpid($pid, 0); exit 124 };
        alarm $t;
        waitpid($pid, 0);
        my $st = $?;
        alarm 0;
        kill "KILL", -$pid;
        exit($st & 127 ? 128 + ($st & 127) : $st >> 8);
    ' "$_secs" "$@"
    _rc=$?
    (( _rc == 124 )) && pkill -KILL -f -- "$_SANDBOX" 2>/dev/null
    return $_rc
}

# Symlink farm: the entry point resolves SCRIPT_DIR from dirname($0) (cd+pwd,
# which does NOT follow file symlinks), so running the linked script from here
# keeps every path — including logs/ — inside the sandbox.
_FARM="$_SANDBOX/farm"
mkdir -p "$_FARM"
for _f in brew_manager.sh VERSION lib modules; do
    ln -s "$_ROOT/$_f" "$_FARM/$_f" || { print -r -- "FAIL: farm link $_f"; exit 1; }
done

# _mock_brew <path> <dir>: a mock brew with enough surface for a read-only module
# (mod_08 uses --prefix and list) and the summary footer. Every call appends its
# first argument to <dir>/brew_calls and the PATH it saw to <dir>/path_seen, so
# the suite can prove WHICH brew ran and with which PATH.
_mock_brew() {
    local _path="$1" _dir="$2"
    mkdir -p "${_path:h}" "$_dir"
    cat > "$_path" <<EOF
#!/bin/zsh
print -r -- "\$1" >> "$_dir/brew_calls"
print -r -- "\$PATH" >> "$_dir/path_seen"
case "\$1" in
    --prefix) print -r -- "/usr/local" ;;
    --cache)  print -r -- "/tmp" ;;
esac
exit 0
EOF
    chmod +x "$_path"
}

_MOCKDIR="$_SANDBOX/mock"
_mock_brew "$_MOCKDIR/brew" "$_MOCKDIR"

# assert_exit <expected_rc> <label> <args...>: run the farm binary end-to-end
# (parent + script(1) re-exec) with the mock brew first on PATH, stdin closed.
assert_exit() {
    local _exp="$1" _label="$2"; shift 2
    local _rc
    PATH="$_MOCKDIR:$PATH" _guarded 60 zsh "$_FARM/brew_manager.sh" "$@" </dev/null >/dev/null 2>&1
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

# ── static pins of the startup contract (STATE Attenzione #23) ───────────────
# The production candidates, the exit code and the "69 on every way out" rule
# are pinned on the source: a typo in a candidate would reopen #23 on every Mac
# of that kind, and the failed-install exit cannot be exercised end-to-end
# without confirming the installer.
_BM="$_ROOT/brew_manager.sh"
_check "the standard prefixes are the probe's candidates, in order" \
    [ "$(grep -cx 'BREW_BIN_CANDIDATES=(/opt/homebrew/bin/brew /usr/local/bin/brew)' "$_BM")" = 1 ]
_check "no other code line names a Homebrew prefix (the probe has one source)" \
    [ "$(grep -nE '/opt/homebrew|/usr/local/bin/brew' "$_BM" | grep -vE '^[0-9]+:[[:space:]]*#' | grep -vc 'BREW_BIN_CANDIDATES=')" = 0 ]
_check "EXIT_ENV_UNAVAILABLE is 69 (sysexits EX_UNAVAILABLE)" \
    [ "$(grep -cx 'EXIT_ENV_UNAVAILABLE=69' "$_BM")" = 1 ]
# Every exit of the Homebrew-check block, from its `if` to the matching
# top-level `fi`, is the dedicated code — and there are at least five of them
# (dry-run, no terminal, download failed, install failed, declined).
_BLOCK_EXITS="$(awk '/^if ! _brew_bootstrap_path; then$/{p=1} p && /^fi$/{exit} p' "$_BM" \
    | grep -E '(^|[^_[:alnum:]])exit([^_[:alnum:]]|$)' | grep -vE '^[[:space:]]*#')"
_check "every exit of the Homebrew check is exit \$EXIT_ENV_UNAVAILABLE (>= 5 exits)" \
    [ "$(print -r -- "$_BLOCK_EXITS" | grep -c .)" -ge 5 \
      -a "$(print -r -- "$_BLOCK_EXITS" | grep -vc 'exit \$EXIT_ENV_UNAVAILABLE')" = 0 ]

# ── minimal environment: the launchd / GUI-app case (STATE Attenzione #23) ───
# launchd gives a job PATH=/usr/bin:/bin:/usr/sbin:/sbin and nothing else, and a
# non-login zsh never reads ~/.zprofile. The probe of the standard Homebrew
# prefixes is exercised through a COPY of the entry point whose candidate
# constant points into the sandbox: production code carries no test hook, and
# the substitution itself is asserted (a renamed constant must fail the suite,
# not silently probe the real /opt/homebrew).
_LAUNCHD_PATH=/usr/bin:/bin:/usr/sbin:/sbin
mkdir -p "$_SANDBOX/home"

# Two prefixes. PA has the Apple Silicon layout (a real bin/brew). PI has the
# Intel layout: bin/brew is a SYMLINK to ../Homebrew/bin/brew, so a probe that
# resolved the link before taking the prefix would put the wrong dir on PATH.
_PA="$_SANDBOX/pa"
_mock_brew "$_PA/bin/brew" "$_PA/log"
mkdir -p "$_PA/sbin"
_PI="$_SANDBOX/pi"
_mock_brew "$_PI/Homebrew/bin/brew" "$_PI/log"
mkdir -p "$_PI/bin" "$_PI/sbin"
ln -s ../Homebrew/bin/brew "$_PI/bin/brew"

# _farm_with_candidates <dir> <candidate...>: a farm whose brew_manager.sh is a
# copy with BREW_BIN_CANDIDATES rewritten to the given list. Fails unless
# exactly one line changed and that line is the rewritten constant.
_farm_with_candidates() {
    local _dir="$1" _f; shift
    local _cand="$*"
    mkdir -p "$_dir" || return 1
    for _f in VERSION lib modules; do ln -s "$_ROOT/$_f" "$_dir/$_f" || return 1; done
    sed "s|^BREW_BIN_CANDIDATES=(.*)\$|BREW_BIN_CANDIDATES=($_cand)|" \
        "$_ROOT/brew_manager.sh" > "$_dir/brew_manager.sh" || return 1
    [[ "$(diff "$_ROOT/brew_manager.sh" "$_dir/brew_manager.sh" | grep -c '^>')" == 1 ]] \
        && grep -qxF "BREW_BIN_CANDIDATES=($_cand)" "$_dir/brew_manager.sh"
}

# The sandbox HOME the minimal-environment runs get. A check that needs its own
# ~/.zshenv sets it for one call (`_HOME_DIR=<dir> _run_minimal ...`, scoped to
# that call by zsh), so no dotfile is ever written into, or removed from, the
# HOME the other checks share.
_HOME_DIR="$_SANDBOX/home"

# _run_minimal <farm> <out> <args...>: launchd's environment — env -i, launchd's
# PATH, a sandbox HOME, stdin closed — with the output kept for content checks.
_run_minimal() {
    local _farm="$1" _out="$2"; shift 2
    _guarded 60 env -i HOME="$_HOME_DIR" PATH="$_LAUNCHD_PATH" \
        /bin/zsh "$_farm/brew_manager.sh" "$@" </dev/null >"$_out" 2>&1
}
# _first_path <log dir>: the first PATH entry the mock brew saw on its first call.
_first_path()  { head -1 "$1/path_seen" 2>/dev/null | cut -d: -f1; }
_second_path() { head -1 "$1/path_seen" 2>/dev/null | cut -d: -f2; }

# Homebrew only at a probed prefix: the run must start, and the CHILD (after the
# script(1) re-exec) must run the probed brew with that prefix's bin and sbin in
# front of PATH — exactly what `brew shellenv` does for PATH.
if _farm_with_candidates "$_SANDBOX/farm_found" "$_PA/bin/brew"; then
    _pass "probe farm: only the candidate constant differs"
    _run_minimal "$_SANDBOX/farm_found" "$_SANDBOX/out_found" 8 --dry-run
    _rc=$?
    _check "minimal env, brew at a probed prefix: rc=0 (got ${_rc})" [ "$_rc" = 0 ]
    _check "minimal env, brew at a probed prefix: the run started" \
        grep -q 'Running modules: 8' "$_SANDBOX/out_found"
    _check "the probed brew ran in the child, with its bin then sbin first on PATH" \
        [ -s "$_PA/log/brew_calls" -a "$(_first_path "$_PA/log")" = "$_PA/bin" \
          -a "$(_second_path "$_PA/log")" = "$_PA/sbin" ]
else
    _fail "probe farm: the candidate constant was not substituted"
fi

# The second candidate (the Intel fallback): the first is skipped when missing,
# and the prefix comes from the candidate's path, not from its symlink target.
if _farm_with_candidates "$_SANDBOX/farm_second" "$_SANDBOX/nowhere/bin/brew" "$_PI/bin/brew"; then
    _run_minimal "$_SANDBOX/farm_second" "$_SANDBOX/out_second" 8 --dry-run
    _rc=$?
    _check "missing first candidate: the second one is used, rc=0 (got ${_rc})" \
        [ "$_rc" = 0 -a -s "$_PI/log/brew_calls" ]
    _check "Intel layout (bin/brew is a symlink): PATH gets the prefix's bin, not the link target's" \
        [ "$(_first_path "$_PI/log")" = "$_PI/bin" ]
else
    _fail "second-candidate farm: the candidate constant was not substituted"
fi

# Order: with both prefixes present, the first candidate wins.
: > "$_PI/log/brew_calls"
: > "$_PA/log/brew_calls"
if _farm_with_candidates "$_SANDBOX/farm_order" "$_PA/bin/brew" "$_PI/bin/brew"; then
    _run_minimal "$_SANDBOX/farm_order" "$_SANDBOX/out_order" 8 --dry-run
    _check "both prefixes present: the first candidate wins" \
        [ -s "$_PA/log/brew_calls" -a ! -s "$_PI/log/brew_calls" ]
else
    _fail "order farm: the candidate constant was not substituted"
fi

# ── no Homebrew anywhere: every way out exits 69, never 0 ─────────────────────
# The runs put a tripwire `curl` first on PATH (launchd's PATH plus that one
# directory) and point every proxy at a closed port: the installer must never
# download anything here.
_TRIP="$_SANDBOX/trip"
mkdir -p "$_TRIP"
cat > "$_TRIP/curl" <<EOF
#!/bin/sh
echo "curl \$*" >> "$_SANDBOX/curl_calls"
exit 0
EOF
chmod +x "$_TRIP/curl"
_NOPROXY=(https_proxy=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 ALL_PROXY=http://127.0.0.1:9)
_NB_FARM="$_SANDBOX/farm_missing/brew_manager.sh"

# _run_no_brew <out> <args...>: no terminal (stdin closed, output to a file).
_run_no_brew() {
    local _out="$1"; shift
    _guarded 30 env -i HOME="$_HOME_DIR" PATH="$_TRIP:$_LAUNCHD_PATH" "${_NOPROXY[@]}" \
        /bin/zsh "$_NB_FARM" "$@" </dev/null >"$_out" 2>&1
}
# _run_no_brew_tty <out> <env assignments...> -- <args...>: the same run on a
# pseudo-terminal (script(1)) whose stdin is at EOF — script(1) forwards that as
# Ctrl-D, so a prompt reads an empty answer. Extra env assignments go before --.
_run_no_brew_tty() {
    local _out="$1"; shift
    local -a _extra=()
    while (( $# )) && [[ "$1" != -- ]]; do _extra+=("$1"); shift; done
    shift
    _guarded 30 /usr/bin/script -q /dev/null \
        env -i HOME="$_SANDBOX/home" PATH="$_TRIP:$_LAUNCHD_PATH" "${_NOPROXY[@]}" "${_extra[@]}" \
        /bin/zsh "$_NB_FARM" "$@" </dev/null >"$_out" 2>&1
}
_no_prompt() { ! grep -q -e 'Install Homebrew now' -e 'Choice:' "$1"; }

if _farm_with_candidates "$_SANDBOX/farm_missing" "$_SANDBOX/nowhere/bin/brew"; then
    # (1) no terminal at all — the LaunchAgent shape, with and without --yes
    _run_no_brew "$_SANDBOX/nb_plain" 8
    _rc=$?
    _check "no Homebrew, no terminal: rc=69 (got ${_rc})" [ "$_rc" = 69 ]
    _check "no Homebrew, no terminal: 'not found', 'No terminal', no prompt, no run" \
        eval 'grep -q "Homebrew was not found" "$_SANDBOX/nb_plain" && grep -q "No terminal" "$_SANDBOX/nb_plain" && _no_prompt "$_SANDBOX/nb_plain" && ! grep -q "Running modules" "$_SANDBOX/nb_plain"'
    _run_no_brew "$_SANDBOX/nb_yes" 8 --yes
    _rc=$?
    _check "no Homebrew, an agent's argv (8 --yes), no terminal: rc=69, no prompt (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && grep -q "No terminal" "$_SANDBOX/nb_yes" && _no_prompt "$_SANDBOX/nb_yes"'

    # (2) --dry-run, without and WITH a terminal: the DRY_RUN gate alone must
    #     stop the prompt at a terminal
    _run_no_brew "$_SANDBOX/nb_dry" 8 --dry-run
    _rc=$?
    _check "no Homebrew, --dry-run: rc=69, the installer is not offered (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && grep -q "the Homebrew installer is not offered" "$_SANDBOX/nb_dry" && _no_prompt "$_SANDBOX/nb_dry"'
    _run_no_brew_tty "$_SANDBOX/nb_dry_tty" -- 8 --dry-run
    _rc=$?
    _check "no Homebrew, --dry-run at a terminal: rc=69, no prompt (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && grep -q "the Homebrew installer is not offered" "$_SANDBOX/nb_dry_tty" && _no_prompt "$_SANDBOX/nb_dry_tty"'

    # (3) each clause of the no-terminal guard on its own
    #   stdin a pipe carrying "y", stdout a terminal (NON_INTERACTIVE alone):
    #   the pre-fix code took that "y" as consent and installed unattended
    _guarded 30 /usr/bin/script -q /dev/null /bin/zsh -c \
        'printf "y\n" | env -i HOME="$1" PATH="$2" https_proxy="$3" HTTPS_PROXY="$3" ALL_PROXY="$3" /bin/zsh "$4" 8' \
        _ "$_SANDBOX/home" "$_TRIP:$_LAUNCHD_PATH" http://127.0.0.1:9 "$_NB_FARM" \
        </dev/null >"$_SANDBOX/nb_pipe_y" 2>&1
    _rc=$?
    _check "no Homebrew, 'y' piped on stdin, stdout a terminal: rc=69, no prompt (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && grep -q "No terminal" "$_SANDBOX/nb_pipe_y" && _no_prompt "$_SANDBOX/nb_pipe_y"'
    #   stdin a terminal, stdout redirected (the `! -t 1` clause alone)
    _guarded 30 /usr/bin/script -q /dev/null /bin/zsh -c \
        'env -i HOME="$1" PATH="$2" https_proxy="$3" HTTPS_PROXY="$3" ALL_PROXY="$3" /bin/zsh "$4" 8 >"$5" 2>&1' \
        _ "$_SANDBOX/home" "$_TRIP:$_LAUNCHD_PATH" http://127.0.0.1:9 "$_NB_FARM" "$_SANDBOX/nb_out_piped" \
        </dev/null >/dev/null 2>&1
    _rc=$?
    _check "no Homebrew, stdin a terminal, stdout redirected: rc=69, no prompt (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && grep -q "No terminal" "$_SANDBOX/nb_out_piped" && _no_prompt "$_SANDBOX/nb_out_piped"'
    #   a terminal, but BREW_MANAGER_RECORDING inherited (the recorded-child clause alone)
    _run_no_brew_tty "$_SANDBOX/nb_recording" BREW_MANAGER_RECORDING=1 BREW_MANAGER_NONINTERACTIVE=0 -- 8
    _rc=$?
    _check "no Homebrew, a terminal, BREW_MANAGER_RECORDING inherited: rc=69, no prompt (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && grep -q "No terminal" "$_SANDBOX/nb_recording" && _no_prompt "$_SANDBOX/nb_recording"'

    # (4) a person at a terminal: the prompt IS shown (the teeth of every
    #     no-prompt check above), and an empty answer (EOF) declines it
    _run_no_brew_tty "$_SANDBOX/nb_tty" -- 8
    _rc=$?
    _check "no Homebrew, a terminal, EOF on the prompt: rc=69 (got ${_rc})" [ "$_rc" = 69 ]
    _check "no Homebrew, a terminal: the prompt is shown and declined" \
        eval 'grep -q "Install Homebrew now" "$_SANDBOX/nb_tty" && grep -q "cannot continue" "$_SANDBOX/nb_tty"'
    _run_no_brew_tty "$_SANDBOX/nb_tty_yes" -- 8 --yes
    _rc=$?
    _check "no Homebrew, a terminal, --yes: the default is No, rc=69 (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && grep -q "auto: n" "$_SANDBOX/nb_tty_yes"'
    _run_no_brew_tty "$_SANDBOX/nb_env_yes" BREW_MANAGER_YES=1 -- 8
    _rc=$?
    _check "no Homebrew, a terminal, BREW_MANAGER_YES injected without --yes: asked, not auto (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && grep -qF "(y/N)" "$_SANDBOX/nb_env_yes" && ! grep -q "auto:" "$_SANDBOX/nb_env_yes"'

    # (5) precedence (docs/04): --version answers first (0), even next to an
    #     unknown flag; then an unknown flag is rejected (2); then the Homebrew
    #     precondition (69) comes before the module selection (2 or 1)
    _run_no_brew "$_SANDBOX/nb_ver" --version
    _rc=$?
    _check "no Homebrew, --version: rc=0, the version and nothing else (got ${_rc})" \
        eval '[ "$_rc" = 0 ] && head -1 "$_SANDBOX/nb_ver" | grep -q "^brew-manager " && ! grep -q "Homebrew was not found" "$_SANDBOX/nb_ver"'
    _run_no_brew "$_SANDBOX/nb_ver_flag" --dryrun -V
    _rc=$?
    _check "no Homebrew, an unknown flag next to -V: --version still wins, rc=0 (got ${_rc})" \
        eval '[ "$_rc" = 0 ] && head -1 "$_SANDBOX/nb_ver_flag" | grep -q "^brew-manager "'
    _run_no_brew "$_SANDBOX/nb_flag" --dryrun
    _rc=$?
    _check "no Homebrew, an unknown flag: still 2 (got ${_rc})" [ "$_rc" = 2 ]
    _run_no_brew "$_SANDBOX/nb_99" 99
    _rc=$?
    _check "no Homebrew, an unknown module token: 69 comes first (got ${_rc})" [ "$_rc" = 69 ]
    _run_no_brew "$_SANDBOX/nb_empty" 8 --skip=8
    _rc=$?
    _check "no Homebrew, a selection that resolves empty: 69 comes first (got ${_rc})" [ "$_rc" = 69 ]

    # (6) a `brew` that is only a shell function or an alias (here defined in
    #     ~/.zshenv, which zsh reads even as launchd's non-login shell, around a
    #     brew that is neither on PATH nor a candidate) is not Homebrew: the probe
    #     asks for the executable (`whence -p`), so the run still exits 69. With
    #     `command -v` the wrapper would satisfy the check (gate finding, LOW).
    _WRAP="$_SANDBOX/custom"
    _mock_brew "$_WRAP/brew" "$_WRAP/log"
    mkdir -p "$_SANDBOX/home_fn" "$_SANDBOX/home_alias"
    print -r -- "brew() { \"$_WRAP/brew\" \"\$@\"; }" > "$_SANDBOX/home_fn/.zshenv"
    print -r -- "alias brew=\"$_WRAP/brew\"" > "$_SANDBOX/home_alias/.zshenv"
    _HOME_DIR="$_SANDBOX/home_fn" _run_no_brew "$_SANDBOX/nb_wrap_fn" 8
    _rc=$?
    _check "no Homebrew, brew only a ~/.zshenv function: rc=69, no run, the wrapper never called (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && ! grep -q "Running modules" "$_SANDBOX/nb_wrap_fn" && [ ! -e "$_WRAP/log/brew_calls" ]'
    _HOME_DIR="$_SANDBOX/home_alias" _run_no_brew "$_SANDBOX/nb_wrap_alias" 8
    _rc=$?
    _check "no Homebrew, brew only a ~/.zshenv alias: rc=69, no run, the wrapper never called (got ${_rc})" \
        eval '[ "$_rc" = 69 ] && ! grep -q "Running modules" "$_SANDBOX/nb_wrap_alias" && [ ! -e "$_WRAP/log/brew_calls" ]'

    _check "the installer's curl was never called" [ ! -e "$_SANDBOX/curl_calls" ]
else
    _fail "missing farm: the candidate constant was not substituted"
fi

# The same function wrapper with Homebrew at a probed prefix: the wrapper does
# not stop the probe, so the prefix still goes in front of PATH. The user's
# wrapper keeps running the commands (a function beats PATH), and the PATH it
# sees proves the probe ran.
if [[ -d "$_SANDBOX/farm_found" ]]; then
    _HOME_DIR="$_SANDBOX/home_fn" _run_minimal "$_SANDBOX/farm_found" "$_SANDBOX/out_wrap_found" 8 --dry-run
    _rc=$?
    _check "brew a ~/.zshenv function, Homebrew at a probed prefix: rc=0, the prefix first on PATH (got ${_rc})" \
        [ "$_rc" = 0 -a -s "$_WRAP/log/brew_calls" -a "$(_first_path "$_WRAP/log")" = "$_PA/bin" ]
else
    _fail "wrapper check: the probe farm is missing"
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
