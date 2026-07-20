#!/bin/zsh
# =============================================================================
# tests/test_menu_registry.zsh — menu name/description registry (BM-11)
#
# The redesigned menu is a fixed-column layout: badge(4) + id(3) + name(17) +
# description(<=46) inside 78 columns, stable on an 80-column terminal. That
# stability is a DATA invariant, not a rendering one: it holds only while every
# MODULE_NAME fits its column and every MODULE_DESC fits the remainder, both in
# plain ASCII (a multibyte glyph would break printf %-*s column math in a
# non-UTF-8 locale). These checks re-apply the invariant by construction over
# every registry entry — adding module 14 with a 30-column name must break the
# build here, not silently wrap the menu.
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

# Column caps — must match the menu row printf in brew_manager.sh.
typeset -i NAME_MAX=17 DESC_MAX=46

# is_ascii <string> → 0 (true) if every byte is printable ASCII (space..tilde).
# Byte-wise on purpose (LC_ALL=C): a UTF-8 locale would class multibyte glyphs
# as printable, which is exactly what this invariant must reject.
is_ascii() { ! printf '%s' "$1" | LC_ALL=C grep -q '[^ -~]'; }

# ─────────────────────────────────────────────────────────────────────────────
# 1. Completeness — MODULE_NAME covers every MODULE_DESC id, and nothing more
# ─────────────────────────────────────────────────────────────────────────────
typeset -a _missing=() _phantom=()
for _k in "${(k)MODULE_DESC[@]}"; do
    [[ -n "${MODULE_NAME[$_k]}" ]] || _missing+=("$_k")
done
for _k in "${(k)MODULE_NAME[@]}"; do
    [[ -n "${MODULE_DESC[$_k]}" ]] || _phantom+=("$_k")
done
# anti-vacuity: an empty registry would vacuously pass every per-entry loop
(( ${#MODULE_DESC[@]} >= 18 )) && _pass "registry: MODULE_DESC has ${#MODULE_DESC[@]} modules" \
                               || _fail "registry: MODULE_DESC too small (${#MODULE_DESC[@]})"
(( ${#_missing[@]} == 0 )) && _pass "registry: every module has a display name" \
                           || _fail "registry: no display name for: ${_missing[*]}"
(( ${#_phantom[@]} == 0 )) && _pass "registry: no MODULE_NAME id absent from MODULE_DESC" \
                           || _fail "registry: phantom name id(s): ${_phantom[*]}"

# ─────────────────────────────────────────────────────────────────────────────
# 2. Layout invariant — every name/description fits its column, ASCII-only
# ─────────────────────────────────────────────────────────────────────────────
typeset -a _long_name=() _long_desc=() _nonascii=()
for _k in "${(k)MODULE_DESC[@]}"; do
    _n="${MODULE_NAME[$_k]}" _d="${MODULE_DESC[$_k]}"
    (( ${#_n} <= NAME_MAX )) || _long_name+=("$_k(${#_n})")
    (( ${#_d} <= DESC_MAX )) || _long_desc+=("$_k(${#_d})")
    is_ascii "$_n" && is_ascii "$_d" || _nonascii+=("$_k")
done
(( ${#_long_name[@]} == 0 )) && _pass "layout: every name fits ${NAME_MAX} columns" \
                             || _fail "layout: name over ${NAME_MAX} cols: ${_long_name[*]}"
(( ${#_long_desc[@]} == 0 )) && _pass "layout: every description fits ${DESC_MAX} columns" \
                             || _fail "layout: description over ${DESC_MAX} cols: ${_long_desc[*]}"
(( ${#_nonascii[@]} == 0 ))  && _pass "layout: every name/description is plain ASCII" \
                             || _fail "layout: non-ASCII text in: ${_nonascii[*]}"

# ─────────────────────────────────────────────────────────────────────────────
# 3. Selection contract untouched — the frozen id set is exactly the registry
#    keys (docs/04: numbers 0-13 + go + log/bk/las/mas; renames must never
#    add/remove/renumber a selectable id)
# ─────────────────────────────────────────────────────────────────────────────
typeset -a _expected=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 log bk las mas)
typeset -a _keys=("${(k)MODULE_DESC[@]}")
_sorted_expected="${(j:,:)${(o)_expected[@]}}"
_sorted_keys="${(j:,:)${(o)_keys[@]}}"
[[ "$_sorted_keys" == "$_sorted_expected" ]] \
    && _pass "contract: MODULE_DESC keys are exactly the frozen id set" \
    || _fail "contract: key drift — got: $_sorted_keys"
(( ${#MODULE_IDS[@]} == 14 )) && _pass "contract: MODULE_IDS still has 14 numbered modules" \
                              || _fail "contract: MODULE_IDS count changed (${#MODULE_IDS[@]})"

# ─────────────────────────────────────────────────────────────────────────────
# Verdict (anti-vacuity: at least one check must have run)
# ─────────────────────────────────────────────────────────────────────────────
print -r -- ""
if (( TESTS_RUN > 0 && TESTS_FAILED == 0 )); then
    print -r -- "test_menu_registry: ${TESTS_RUN} checks passed"
    exit 0
else
    print -r -- "test_menu_registry: ${TESTS_FAILED}/${TESTS_RUN} checks FAILED"
    exit 1
fi
