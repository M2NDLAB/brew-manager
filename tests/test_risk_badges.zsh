#!/bin/zsh
# =============================================================================
# tests/test_risk_badges.zsh — risk badge registry & renderers (BM-10)
#
# The badge makes a module's blast radius visible; a badge that UNDERSTATES risk
# (says [RO] on a module that removes/installs/adopts) is a security bug. These
# checks pin: every module has a level, the level set matches the adversarially-
# audited classification, the docs/03 sensitive modules are all [!], the badge
# degrades to plain ASCII at level 0 (no ANSI when piped / NO_COLOR) and keeps a
# constant width, and the "About this module" line composes badge + caption.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"
source "$_ROOT/lib/common.sh"    || { print -r -- "cannot source lib/common.sh"; exit 1; }
source "$_ROOT/lib/selection.sh" || { print -r -- "cannot source lib/selection.sh"; exit 1; }

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }
# has_esc <string> → 0 (true) if it contains a raw ESC byte (0x1b).
has_esc() { printf '%s' "$1" | LC_ALL=C grep -q $'\x1b'; }

# ─────────────────────────────────────────────────────────────────────────────
# 1. Completeness — MODULE_RISK covers every MODULE_DESC id, valid level, no phantom
# ─────────────────────────────────────────────────────────────────────────────
typeset -a _missing=() _bad=() _phantom=()
for _k in "${(k)MODULE_DESC[@]}"; do
    _lvl="${MODULE_RISK[$_k]}"
    if [[ -z "$_lvl" ]]; then
        _missing+=("$_k")
    elif [[ "$_lvl" != (ro|write|danger) ]]; then
        _bad+=("$_k=$_lvl")
    fi
done
for _k in "${(k)MODULE_RISK[@]}"; do
    [[ -n "${MODULE_DESC[$_k]}" ]] || _phantom+=("$_k")
done
# anti-vacuity: without a populated registry this whole battery is meaningless
(( ${#MODULE_DESC[@]} >= 18 )) && _pass "registry: MODULE_DESC has ${#MODULE_DESC[@]} modules" \
                               || _fail "registry: MODULE_DESC too small (${#MODULE_DESC[@]})"
(( ${#_missing[@]} == 0 )) && _pass "registry: every module has a risk level" \
                           || _fail "registry: no risk level for: ${_missing[*]}"
(( ${#_bad[@]} == 0 ))     && _pass "registry: every level is ro|write|danger" \
                           || _fail "registry: invalid level(s): ${_bad[*]}"
(( ${#_phantom[@]} == 0 )) && _pass "registry: no MODULE_RISK id absent from MODULE_DESC" \
                           || _fail "registry: phantom risk id(s): ${_phantom[*]}"

# ─────────────────────────────────────────────────────────────────────────────
# 2. Exact classification — pins the adversarially-audited levels (a future flip
#    of, say, mod_05 to 'ro' must break the build, not ship a silent under-warning)
# ─────────────────────────────────────────────────────────────────────────────
_expect_level() {
    local id="$1" exp="$2" got="${MODULE_RISK[$1]}"
    [[ "$got" == "$exp" ]] && _pass "level: $id = $exp" \
                           || _fail "level: $id = $got, expected $exp"
}
for _id in 1 3 6 7 8 9 11 12 13; do _expect_level "$_id" ro;     done
for _id in 2 log;               do _expect_level "$_id" write;  done
for _id in 0 4 5 10 bk las mas; do _expect_level "$_id" danger; done

# ─────────────────────────────────────────────────────────────────────────────
# 3. docs/03 sensitive modules MUST be danger (non-regression: sensibili = [!])
# ─────────────────────────────────────────────────────────────────────────────
for _id in 0 5 bk las; do
    [[ "${MODULE_RISK[$_id]}" == danger ]] \
        && _pass "sensitive: module $_id is [!]" \
        || _fail "sensitive: module $_id is '${MODULE_RISK[$_id]}', must be danger"
done

# ─────────────────────────────────────────────────────────────────────────────
# 4. Badge degradation & constant width at level 0 (piped / NO_COLOR)
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=0; _init_palette
for _pair in 'ro:[RO]' 'write:[W] ' 'danger:[!] ' 'bogus:[?] '; do
    _lvl="${_pair%%:*}"; _exp="${_pair#*:}"; _got="$(_risk_badge "$_lvl")"
    if [[ "$_got" == "$_exp" ]] && ! has_esc "$_got" && (( ${#_got} == 4 )); then
        _pass "badge L0: $_lvl → '$_got' (plain ASCII, 4 columns)"
    else
        _fail "badge L0: $_lvl → '$_got' (want '$_exp', no ESC, width 4)"
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
# 5. Positive control — at a colour tier the badge DOES emit ANSI (non-vacuous)
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=2; _init_palette
if has_esc "$(_risk_badge danger)"; then
    _pass "badge L2: emits ANSI when the tier has colour"
else
    _fail "badge L2: emitted no ANSI (the L0 checks would be vacuous)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. _about_risk — composes badge + caption; plain at L0
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=0; _init_palette
_about5="$(_about_risk 5)"      # danger module
_about1="$(_about_risk 1)"      # ro module
if [[ "$_about5" == *'[!]'* && "$_about5" == *'system'* ]] && ! has_esc "$_about5"; then
    _pass "_about_risk: danger module shows [!] + caption, plain at L0"
else
    _fail "_about_risk: danger About line wrong: '$_about5'"
fi
if [[ "$_about1" == *'[RO]'* && "$_about1" == *'Read-only'* ]]; then
    _pass "_about_risk: ro module shows [RO] + Read-only caption"
else
    _fail "_about_risk: ro About line wrong: '$_about1'"
fi

# ─────────────────────────────────────────────────────────────────────────────
# verdict + anti-vacuity
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
