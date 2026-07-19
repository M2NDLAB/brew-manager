#!/bin/zsh
# =============================================================================
# tests/test_capabilities.zsh — TUI capability detection & degradation (BM-09)
#
# The rendering foundation must degrade WITHOUT breaking: a piped/NO_COLOR run
# emits zero ANSI at the SOURCE (not just stripped from the saved log), a poor
# terminal keeps the historical 16-color palette, and a non-UTF-8 locale falls
# back to ASCII box glyphs. These checks pin those invariants.
#
# The pure detectors (_tui_color_level / _tui_unicode) are exercised in
# command-substitution subshells so per-case NO_COLOR/COLORTERM/LANG never leak
# into the ambient environment (which here already carries COLORTERM=truecolor).
# The end-to-end block runs the REAL binary piped through the script(1) re-exec
# — the only place that proves the parent→child capability handoff actually
# suppresses color when the true destination is a pipe.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"
source "$_ROOT/lib/common.sh" || { print -r -- "cannot source lib/common.sh"; exit 1; }

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }

# has_esc <string> → 0 (true) if the string contains an ESC byte (0x1b). Uses a
# C-locale grep so it sees raw bytes, not decoded characters.
has_esc() { printf '%s' "$1" | LC_ALL=C grep -q $'\x1b'; }
# has_nonascii <string> → 0 (true) if any byte is outside printable ASCII.
has_nonascii() { printf '%s' "$1" | LC_ALL=C grep -q '[^ -~]'; }

# ─────────────────────────────────────────────────────────────────────────────
# 1. _tui_color_level — is_tty + ncolors + NO_COLOR/COLORTERM → tier 0..3
# ─────────────────────────────────────────────────────────────────────────────
# _lvl <label> <exp> <is_tty> <ncolors> <NO_COLOR> <COLORTERM>
_lvl() {
    local label="$1" exp="$2" tty="$3" ncol="$4" nc="$5" ct="$6" got
    got="$(NO_COLOR="$nc" COLORTERM="$ct" _tui_color_level "$tty" "$ncol")"
    [[ "$got" == "$exp" ]] && _pass "level: ${label} = ${got}" \
                           || _fail "level: ${label} = ${got}, expected ${exp}"
}
_lvl "tty+256 → 256"            2  1 256 ""  ""
_lvl "tty+16  → 16"             1  1 16  ""  ""
_lvl "tty+8   → 16"            1  1 8   ""  ""
_lvl "tty+0   → none (dumb)"    0  1 0   ""  ""
_lvl "non-tty+256 → none"       0  0 256 ""  ""
_lvl "COLORTERM=truecolor → 3"  3  1 16  ""  truecolor
_lvl "COLORTERM=24bit → 3"      3  1 8   ""  24bit
_lvl "NO_COLOR beats truecolor" 0  1 256 1   truecolor
_lvl "non-numeric ncolors → 0"  0  1 xyz ""  ""
_lvl "empty ncolors → 0"        0  1 ""  ""  ""

# ─────────────────────────────────────────────────────────────────────────────
# 2. _tui_unicode — locale precedence
# ─────────────────────────────────────────────────────────────────────────────
# _uni <label> <exp> <LANG> <LC_ALL> <LC_CTYPE>
_uni() {
    local label="$1" exp="$2" got
    got="$(LANG="$3" LC_ALL="$4" LC_CTYPE="$5" _tui_unicode)"
    [[ "$got" == "$exp" ]] && _pass "unicode: ${label} = ${got}" \
                           || _fail "unicode: ${label} = ${got}, expected ${exp}"
}
_uni "LANG UTF-8 → 1"           1  en_US.UTF-8 "" ""
_uni "LANG utf8 → 1"            1  en_US.utf8  "" ""
_uni "LANG=C → 0"              0  C           "" ""
_uni "LC_ALL UTF-8 wins → 1"    1  C           en_US.UTF-8 ""
_uni "LC_ALL=C beats UTF-8 LANG → 0" 0  en_US.UTF-8 C ""
_uni "LC_CTYPE UTF-8 → 1"       1  C           "" it_IT.UTF-8
_uni "LC_ALL=C beats LC_CTYPE UTF-8 → 0" 0 "" C it_IT.UTF-8
_uni "all empty → 0"            0  ""          "" ""

# ─────────────────────────────────────────────────────────────────────────────
# 3. _init_palette — degradation ladder
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=0; _init_palette
if [[ -z "$NC$C_GREEN$C_RED$C_GRAY$C_DANGER$C_OK$C_BRAND$BOLD" ]]; then
    _pass "palette L0: every color constant is empty (clean ASCII)"
else
    _fail "palette L0: a color constant leaked a value"
fi

TUI_COLOR_LEVEL=1; _init_palette
# Assert every tier-overridden state color (green/red/gray/yellow/orange/white)
# still equals its historical 16-color code — a poor terminal must be unchanged.
if [[ "$C_GREEN" == '\033[0;32m' && "$C_RED" == '\033[0;31m' \
   && "$C_GRAY" == '\033[0;90m' && "$C_YELLOW" == '\033[1;33m' \
   && "$C_ORANGE" == '\033[0;33m' && "$C_WHITE" == '\033[1;37m' \
   && "$C_GREEN_B" == '\033[1;32m' ]]; then
    _pass "palette L1: 16-color values match the historical palette"
else
    _fail "palette L1: 16-color baseline drifted (C_GREEN=$C_GREEN C_ORANGE=$C_ORANGE)"
fi

TUI_COLOR_LEVEL=2; _init_palette
if [[ -n "$C_GRAY" && "$C_GRAY" != '\033[0;90m' \
   && "$C_OK" == "$C_GREEN_B" && "$C_WARN" == "$C_YELLOW" \
   && "$C_DANGER" == "$C_RED" && "$C_INFO" == "$C_GRAY" \
   && "$C_HEADING" == "$C_WHITE" && "$C_BRAND" == "$C_ORANGE" ]]; then
    _pass "palette L2: 256 hues applied and semantic aliases stay coherent"
else
    _fail "palette L2: semantic aliasing incoherent"
fi

TUI_COLOR_LEVEL=3; _init_palette
# The constants store the LITERAL "\033[…m" string (rendered to a real ESC only
# by echo -e/printf), so match the truecolor signature, not a raw ESC byte.
if [[ "$C_GREEN" == *'38;2;'* && "$C_WHITE" == *'38;2;'* && "$C_ORANGE" == *'38;2;'* ]]; then
    _pass "palette L3: truecolor sequences applied"
else
    _fail "palette L3: truecolor not applied (C_GREEN=$C_GREEN)"
fi

# positive control: at a color tier, a helper actually emits an ESC (proves the
# 'no ESC when piped' checks below aren't vacuous because output is always bare)
TUI_COLOR_LEVEL=2; _init_palette; TUI_UNICODE=1; _init_symbols
if has_esc "$(_ok 'hello')"; then
    _pass "control: _ok emits ANSI when the tier has color"
else
    _fail "control: _ok emitted no ANSI at L2"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 4. _init_symbols — UTF-8 vs ASCII fallback
# ─────────────────────────────────────────────────────────────────────────────
TUI_UNICODE=1; _init_symbols
if [[ "$SYM_OK" == "✓" && "$BOX_H" == "─" && "$BOX_TL" == "╭" ]] \
   && has_nonascii "$SYM_OK$BOX_H"; then
    _pass "symbols: UTF-8 glyphs selected"
else
    _fail "symbols: UTF-8 set wrong"
fi

TUI_UNICODE=0; _init_symbols
_ascii_all="${SYM_OK}${SYM_WARN}${SYM_ERR}${SYM_INFO}${SYM_DOT}${SYM_ARR}"
_ascii_all+="${SYM_PKG}${SYM_APP}${SYM_LOCK}${SYM_STAR}"
_ascii_all+="${BOX_TL}${BOX_TR}${BOX_BL}${BOX_BR}${BOX_H}${BOX_V}"
if [[ "$BOX_H" == "-" && "$BOX_TL" == "+" ]] && ! has_nonascii "$_ascii_all"; then
    _pass "symbols: ASCII fallback is pure ASCII (no garbage in poor locales)"
else
    _fail "symbols: ASCII fallback leaked a non-ASCII byte"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. _hline / _box — ASCII fallback renders without non-ASCII bytes
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=0; _init_palette; TUI_UNICODE=0; _init_symbols; TERM_WIDTH=40
_rule_out="$(_hline '═' '')"
if ! has_nonascii "$_rule_out" && [[ "$_rule_out" == *'='* ]]; then
    _pass "_hline: heavy rule maps to ASCII '=' in a non-UTF-8 locale"
else
    _fail "_hline: ASCII rule fallback wrong"
fi
_box_out="$(_box '' 'CLEANUP' 'removes orphans' 'clears cache')"
if ! has_nonascii "$_box_out" && ! has_esc "$_box_out" \
   && [[ "$_box_out" == *'+'* && "$_box_out" == *'CLEANUP'* ]]; then
    _pass "_box: ASCII+no-color box is pure ASCII, no ANSI"
else
    _fail "_box: ASCII/no-color box fallback wrong"
fi
# echo-on-data guard: a title carrying a literal backslash escape must be printed
# verbatim, NOT expanded into a real ESC — the box renders DATA through printf %s,
# never `echo -e`. With no color (L0) the only possible ESC source is the title.
_box_evil="$(_box '' 'A\033[31mEVIL' 'x')"
if ! has_esc "$_box_evil" && [[ "$_box_evil" == *'\033[31m'* ]]; then
    _pass "_box: title backslash-escapes are printed literally (no echo-on-data)"
else
    _fail "_box: title escape leaked a real ESC (echo-on-data regression)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. END-TO-END — piped run emits NO ANSI through the script(1) re-exec
# ─────────────────────────────────────────────────────────────────────────────
# Symlink farm keeps SCRIPT_DIR (and logs/) inside a sandbox; a mock brew keeps
# the run off the real system. The run is piped (stdin+stdout not a tty) and
# --dry-run, so the parent must detect level 0 and hand it to the recorded
# child — whose output (captured here as script(1)'s stdout) must be ESC-free.
_SANDBOX="$(mktemp -d)" || { print -r -- "FAIL: mktemp"; exit 1; }
cleanup() { rm -rf "$_SANDBOX"; }
trap 'cleanup; trap - EXIT; exit 130' INT TERM
trap cleanup EXIT

_FARM="$_SANDBOX/farm"; mkdir -p "$_FARM"
for _f in brew_manager.sh VERSION lib modules; do
    ln -s "$_ROOT/$_f" "$_FARM/$_f" || { print -r -- "FAIL: farm link $_f"; exit 1; }
done
_MOCKDIR="$_SANDBOX/mock"; mkdir -p "$_MOCKDIR"
print -r -- '#!/bin/zsh'                              >  "$_MOCKDIR/brew"
print -r -- 'case "$1" in'                            >> "$_MOCKDIR/brew"
print -r -- '  --prefix) print -r -- "/usr/local" ;;' >> "$_MOCKDIR/brew"
print -r -- '  --cache)  print -r -- "/tmp" ;;'       >> "$_MOCKDIR/brew"
print -r -- 'esac; exit 0'                            >> "$_MOCKDIR/brew"
chmod +x "$_MOCKDIR/brew"

# run_piped <NO_COLOR value> → captures the binary's piped stdout
run_piped() {
    NO_COLOR="$1" PATH="$_MOCKDIR:$PATH" \
        zsh "$_FARM/brew_manager.sh" 8 --dry-run </dev/null 2>/dev/null
}

_e2e_plain="$(run_piped "")"
if [[ -n "$_e2e_plain" ]] && ! has_esc "$_e2e_plain"; then
    _pass "e2e: piped run produced output with zero ANSI (source-level clean)"
else
    _fail "e2e: piped run empty or leaked ANSI"
fi

_e2e_nocolor="$(run_piped "1")"
if [[ -n "$_e2e_nocolor" ]] && ! has_esc "$_e2e_nocolor"; then
    _pass "e2e: NO_COLOR piped run produced output with zero ANSI"
else
    _fail "e2e: NO_COLOR run empty or leaked ANSI"
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
