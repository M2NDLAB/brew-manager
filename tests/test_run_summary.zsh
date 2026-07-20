#!/bin/zsh
# =============================================================================
# tests/test_run_summary.zsh — spinner + run-summary renderers (BM-12)
#
# Pins the BM-12 presentation primitives:
#   - _spinner: gated on TUI_TTY (IMP-005) — a non-TTY run must emit NO \r and
#     NO ANSI (one static status line only), a TTY run animates; in BOTH modes
#     the child's exit status is returned (wait), never swallowed.
#   - _run_glyph: constant 4-column outcome glyph (done/preview/failed), plain
#     ASCII at level 0 — same discipline as _risk_badge.
#   - _fmt_secs / _fmt_kb: pure ASCII formatters for durations and disk sizes.
#   - _du_kb: "" (not 0) when a path cannot be measured — 0 would render a
#     fake "freed" delta in the summary.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"
source "$_ROOT/lib/common.sh" || { print -r -- "cannot source lib/common.sh"; exit 1; }

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }
# has_esc <s> → true if it contains a raw ESC byte; has_cr <s> → a raw \r.
has_esc()      { printf '%s' "$1" | LC_ALL=C grep -q $'\x1b'; }
has_cr()       { printf '%s' "$1" | LC_ALL=C grep -q $'\r'; }
has_nonascii() { printf '%s' "$1" | LC_ALL=C grep -q '[^ -~]'; }
# strip_ansi <s> → the string without CSI color sequences (visible width check)
strip_ansi()   { printf '%s' "$1" | sed $'s/\x1b\[[0-9;]*m//g'; }

# ─────────────────────────────────────────────────────────────────────────────
# 1. Formatters — pure, ASCII-only
# ─────────────────────────────────────────────────────────────────────────────
[[ "$(_fmt_secs 0)"    == "0s"     ]] && _pass "fmt_secs: 0 -> 0s"        || _fail "fmt_secs: 0 -> $(_fmt_secs 0)"
[[ "$(_fmt_secs 42)"   == "42s"    ]] && _pass "fmt_secs: 42 -> 42s"      || _fail "fmt_secs: 42 -> $(_fmt_secs 42)"
[[ "$(_fmt_secs 72)"   == "1m 12s" ]] && _pass "fmt_secs: 72 -> 1m 12s"   || _fail "fmt_secs: 72 -> $(_fmt_secs 72)"
[[ "$(_fmt_secs 3725)" == "62m 5s" ]] && _pass "fmt_secs: 3725 -> 62m 5s" || _fail "fmt_secs: 3725 -> $(_fmt_secs 3725)"

[[ "$(_fmt_kb 512)"     == "512K" ]] && _pass "fmt_kb: 512 -> 512K"      || _fail "fmt_kb: 512 -> $(_fmt_kb 512)"
[[ "$(_fmt_kb 1536)"    == "1.5M" ]] && _pass "fmt_kb: 1536 -> 1.5M"     || _fail "fmt_kb: 1536 -> $(_fmt_kb 1536)"
[[ "$(_fmt_kb 1572864)" == "1.5G" ]] && _pass "fmt_kb: 1572864 -> 1.5G"  || _fail "fmt_kb: 1572864 -> $(_fmt_kb 1572864)"
[[ "$(_fmt_kb 2097152)" == "2.0G" ]] && _pass "fmt_kb: 2097152 -> 2.0G"  || _fail "fmt_kb: 2097152 -> $(_fmt_kb 2097152)"
has_nonascii "$(_fmt_kb 1572864)$(_fmt_secs 72)" \
    && _fail "formatters: output must be plain ASCII" \
    || _pass "formatters: output is plain ASCII"

# _du_kb: a real dir yields digits; a missing path yields EMPTY, never 0
_du_real="$(_du_kb "$_ROOT/lib")"
[[ "$_du_real" == <-> && -n "$_du_real" ]] && _pass "du_kb: real dir -> a number ($_du_real)" \
                                           || _fail "du_kb: real dir -> '$_du_real'"
_du_missing="$(_du_kb "$_ROOT/does-not-exist-$$")"
[[ -z "$_du_missing" ]] && _pass "du_kb: missing path -> empty (not 0)" \
                        || _fail "du_kb: missing path -> '$_du_missing'"

# ─────────────────────────────────────────────────────────────────────────────
# 2. _run_glyph — constant visible width, level-0 purity, Unicode variants
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=0; _init_palette; TUI_UNICODE=0; _init_symbols
for _st in done preview failed unknown; do
    _g="$(_run_glyph "$_st")"
    has_esc "$_g" && _fail "glyph($_st) L0: contains ANSI" || _pass "glyph($_st) L0: no ANSI"
    (( ${#_g} == 4 )) && _pass "glyph($_st) L0: width 4" || _fail "glyph($_st) L0: width ${#_g}"
done
[[ "$(_run_glyph done)"    == "[OK]" ]] && _pass "glyph ascii: done -> [OK]"    || _fail "glyph ascii: done -> $(_run_glyph done)"
[[ "$(_run_glyph preview)" == "[--]" ]] && _pass "glyph ascii: preview -> [--]" || _fail "glyph ascii: preview -> $(_run_glyph preview)"
[[ "$(_run_glyph failed)"  == "[!!]" ]] && _pass "glyph ascii: failed -> [!!]"  || _fail "glyph ascii: failed -> $(_run_glyph failed)"

TUI_COLOR_LEVEL=2; _init_palette; TUI_UNICODE=1; _init_symbols
for _st in done preview failed; do
    _plain="$(strip_ansi "$(_run_glyph "$_st")")"
    (( ${#_plain} == 4 )) && _pass "glyph($_st) unicode: visible width 4" \
                          || _fail "glyph($_st) unicode: visible width ${#_plain}"
done
[[ "$(strip_ansi "$(_run_glyph done)")"    == "✓   " ]] && _pass "glyph unicode: done -> check mark" || _fail "glyph unicode: done wrong"
[[ "$(strip_ansi "$(_run_glyph preview)")" == "↷   " ]] && _pass "glyph unicode: preview -> arrow"   || _fail "glyph unicode: preview wrong"

# ─────────────────────────────────────────────────────────────────────────────
# 3. _spinner — non-TTY: static line, no \r, no ANSI, child rc returned
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=0; _init_palette; TUI_UNICODE=0; _init_symbols; TUI_TTY=0
_out=$( { (sleep 0.2; exit 7) & } ; _spinner $! "fake operation" ); _rc=$?
(( _rc == 7 ))                 && _pass "spinner non-tty: child rc 7 returned" || _fail "spinner non-tty: rc $_rc (expected 7)"
has_cr  "$_out"                && _fail "spinner non-tty: contains \\r"        || _pass "spinner non-tty: no \\r"
has_esc "$_out"                && _fail "spinner non-tty: contains ANSI"       || _pass "spinner non-tty: no ANSI"
[[ "$_out" == *"fake operation... (running)"* ]] \
                               && _pass "spinner non-tty: static status line"  || _fail "spinner non-tty: no status line: '$_out'"

# ─────────────────────────────────────────────────────────────────────────────
# 4. _spinner — TTY: animates with \r, ASCII frames without UTF-8, rc returned
# ─────────────────────────────────────────────────────────────────────────────
TUI_TTY=1
_out=$( { (sleep 0.35; exit 3) & } ; _spinner $! "tty op" ); _rc=$?
(( _rc == 3 ))       && _pass "spinner tty: child rc 3 returned" || _fail "spinner tty: rc $_rc (expected 3)"
has_cr "$_out"       && _pass "spinner tty: redraws via \\r"     || _fail "spinner tty: no \\r seen"
[[ "$_out" == *"tty op..."* ]] && _pass "spinner tty: shows label" || _fail "spinner tty: label missing"
# \r is the animation itself — strip it, then require printable ASCII only
printf '%s' "$_out" | tr -d '\r' | LC_ALL=C grep -q '[^ -~]' \
                     && _fail "spinner tty ascii: multibyte frame leaked" \
                     || _pass "spinner tty ascii: frames are plain ASCII"
TUI_TTY=0

# ─────────────────────────────────────────────────────────────────────────────
# Verdict (anti-vacuity: at least one check must have run)
# ─────────────────────────────────────────────────────────────────────────────
print -r -- ""
if (( TESTS_RUN > 0 && TESTS_FAILED == 0 )); then
    print -r -- "test_run_summary: ${TESTS_RUN} checks passed"
    exit 0
else
    print -r -- "test_run_summary: ${TESTS_FAILED}/${TESTS_RUN} checks FAILED"
    exit 1
fi
