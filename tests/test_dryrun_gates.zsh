#!/bin/zsh
# =============================================================================
# tests/test_dryrun_gates.zsh — --dry-run really stops the mutating commands
#
# The registry check in test_run_summary.zsh only greps a module for the string
# BREW_MANAGER_DRY_RUN: it proves a gate is MENTIONED, not that the command is
# skipped. These checks close that gap for the two modules that used to act in
# a preview session (STATE Attenzione #3/#14) by running them for real against
# a mock `brew` that records every invocation:
#
#   dry run  → the tripwire must NOT contain the mutating verb, and the module
#              must still have run (other verbs recorded) — an empty tripwire
#              would mean the module died early and proved nothing.
#   wet run  → the SAME module must record the verb. Without this the dry-run
#              assertion would also pass on a module that no longer does
#              anything at all (a test with no teeth).
#
# Isolation: PATH is cut down to the mock dir plus the system bins, so `brew` is
# always the mock and `mas` is absent whether or not the developer has it
# installed — which is what puts mod_mas on its install path.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"
source "$_ROOT/lib/common.sh"    || { print -r -- "cannot source lib/common.sh"; exit 1; }
source "$_ROOT/lib/selection.sh" || { print -r -- "cannot source lib/selection.sh"; exit 1; }
source "$_ROOT/modules/mod_02_update.sh" || { print -r -- "cannot source mod_02"; exit 1; }
source "$_ROOT/modules/mod_mas_mas.sh"  || { print -r -- "cannot source mod_mas"; exit 1; }

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }

_SANDBOX="$(mktemp -d)" || { print -r -- "FAIL: mktemp"; exit 1; }
# mod_02 writes brew update's output to a FIXED path (/tmp/brew_update.log,
# STATE #11): the wet check below would clobber whatever a real session left
# there, so it is moved aside and restored — including on INT/TERM, where the
# exit also stops zsh from running the remaining checks against a deleted
# sandbox.
_M02LOG="/tmp/brew_update.log"
_M02SAVE="$_SANDBOX/brew_update.log.saved"
[[ -f "$_M02LOG" ]] && cp -p "$_M02LOG" "$_M02SAVE" 2>/dev/null
cleanup() {
    if [[ -f "$_M02SAVE" ]]; then
        cp -p "$_M02SAVE" "$_M02LOG" 2>/dev/null
    else
        rm -f "$_M02LOG"
    fi
    rm -rf "$_SANDBOX"
}
trap 'cleanup; trap - EXIT; exit 130' INT TERM
trap cleanup EXIT

# ── Mock brew: records the sub-command, answers the read-only queries the
#    modules make. `install` and `update` do nothing but leave their trace.
_MOCKDIR="$_SANDBOX/mock"
mkdir -p "$_MOCKDIR"
cat > "$_MOCKDIR/brew" <<EOF
#!/bin/zsh
print -r -- "\$1" >> "$_MOCKDIR/brew_calls"
case "\$1" in
    --cache)      print -r -- "$_SANDBOX/cache" ;;
    --repository) print -r -- "$_SANDBOX/repo" ;;
    tap)          ;;   # no extra taps
esac
exit 0
EOF
chmod +x "$_MOCKDIR/brew"
mkdir -p "$_SANDBOX/cache/api" "$_SANDBOX/repo"
print -r -- "stale index" > "$_SANDBOX/cache/api/formula_names.txt"

_SAFE_PATH="$_MOCKDIR:/usr/bin:/bin:/usr/sbin:/sbin"

# Plain ASCII, no colour, no tty: the assertions match on the text, and the
# spinner must not animate into the captured output.
TUI_COLOR_LEVEL=0; _init_palette; TUI_UNICODE=0; _init_symbols; TUI_TTY=0

# _tripwire_reset / _tripwire → the recorded brew sub-commands, one per line.
_tripwire_reset() { : > "$_MOCKDIR/brew_calls"; }
_tripwire()       { cat "$_MOCKDIR/brew_calls" 2>/dev/null; }
# _saw <verb> → true when the mock recorded that sub-command this round.
_saw() { _tripwire | grep -qx -- "$1"; }

# _run_module <module-fn> <dry> <yes> [noninteractive] → run it in a subshell
# with the sandbox PATH and the safety flags, capturing everything it printed.
# A subshell so neither the flags nor PATH leak into the next check. Redirect
# stdin at the call site to answer an interactive prompt.
_run_module() {
    local _fn="$1" _dry="$2" _yes="$3" _ni="${4:-1}"
    (
        PATH="$_SAFE_PATH"
        BREW_MANAGER_DRY_RUN=$_dry
        BREW_MANAGER_YES=$_yes
        BREW_MANAGER_NONINTERACTIVE=$_ni
        "$_fn" 2>&1
    )
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. mod_02 — `brew update` must not run under --dry-run, not even with --yes
# ─────────────────────────────────────────────────────────────────────────────
_tripwire_reset
_out="$(_run_module _module_2 1 1)"

_saw update && _fail "mod_02 dry-run: brew update WAS invoked" \
             || _pass "mod_02 dry-run: brew update never invoked"
# The module really executed (it queried brew) — otherwise the check above is
# vacuous: a module that crashed on line 1 also records no 'update'.
[[ -n "$(_tripwire)" ]] && _pass "mod_02 dry-run: module ran (brew queried: $(_tripwire | tr '\n' ' '))" \
                        || _fail "mod_02 dry-run: no brew call at all — module did not run"
[[ "$_out" == *"skipping brew update"* ]] && _pass "mod_02 dry-run: says it skipped" \
                                          || _fail "mod_02 dry-run: no skip notice"
[[ "$_out" == *"Would run"*"brew update"* ]] && _pass "mod_02 dry-run: previews the command" \
                                             || _fail "mod_02 dry-run: no preview of the command"
[[ "$_out" == *"would be refreshed"* ]] && _pass "mod_02 dry-run: previews the repositories" \
                                        || _fail "mod_02 dry-run: no repository preview"
# The preview must not claim the index was refreshed
[[ "$_out" == *"Database updated"* ]] && _fail "mod_02 dry-run: claims the database was updated" \
                                      || _pass "mod_02 dry-run: claims no update happened"

# ── teeth: the same module, wet, DOES invoke it ──────────────────────────────
_tripwire_reset
_out_wet="$(_run_module _module_2 0 1)"
_saw update && _pass "mod_02 wet: brew update invoked (dry-run check has teeth)" \
            || _fail "mod_02 wet: brew update NOT invoked — the dry-run check proves nothing"

# ── the age helper degrades instead of fabricating a figure ──────────────────
_age="$( PATH="$_SAFE_PATH" _mod02_index_age )"
[[ -n "$_age" ]] && _pass "index age: reported ($_age)" || _fail "index age: empty"
_age_missing="$( PATH="/usr/bin:/bin" _mod02_index_age )"   # no brew on PATH
[[ "$_age_missing" == "unknown" ]] && _pass "index age: unknown without brew" \
                                   || _fail "index age: '$_age_missing' without brew (expected unknown)"

# ─────────────────────────────────────────────────────────────────────────────
# 2. mas — `brew install mas` must not run under --dry-run, even when the user
#    would have said yes. --yes alone never reaches it (the prompt's default is
#    "n"), so the path that actually installed despite --dry-run was the
#    INTERACTIVE one: both checks below therefore answer "y" from the same
#    stdin file, leaving --dry-run as the only variable between them.
# ─────────────────────────────────────────────────────────────────────────────
print -r -- "y" > "$_SANDBOX/yes.txt"

# Guard: with mas absent from the sandbox PATH the module takes its install
# path. If a developer's mas leaked in, every assertion below would be vacuous.
if PATH="$_SAFE_PATH" command -v mas >/dev/null 2>&1; then
    _fail "mas sandbox: mas is reachable — the install path is not exercised"
else
    _pass "mas sandbox: mas absent, module takes its install path"
fi

_tripwire_reset
_out="$(_run_module _module_16 1 0 0 < "$_SANDBOX/yes.txt")"

_saw install && _fail "mas dry-run: brew install mas WAS invoked" \
              || _pass "mas dry-run: brew install mas never invoked"
[[ "$_out" == *"skipping install"* ]] && _pass "mas dry-run: says it skipped" \
                                      || _fail "mas dry-run: no skip notice"
[[ "$_out" == *"Would run"*"brew install mas"* ]] && _pass "mas dry-run: previews the command" \
                                                  || _fail "mas dry-run: no preview of the command"
# The gate must come BEFORE the confirmation: a preview session must not even
# ask (asking, then ignoring the answer, is how consent bugs start).
[[ "$_out" == *"Install mas now?"* ]] && _fail "mas dry-run: asked for confirmation anyway" \
                                      || _pass "mas dry-run: never asks for consent"

# ── teeth: same module, same "y" on stdin, wet — it DOES invoke the install ──
_tripwire_reset
_out_wet="$(_run_module _module_16 0 0 0 < "$_SANDBOX/yes.txt")"
_saw install && _pass "mas wet: brew install mas invoked (dry-run check has teeth)" \
             || _fail "mas wet: install NOT invoked — the dry-run check proves nothing"

# ─────────────────────────────────────────────────────────────────────────────
# 3. Verdict + anti-vacuity
# ─────────────────────────────────────────────────────────────────────────────
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
