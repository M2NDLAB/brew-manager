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
source "$_ROOT/lib/common.sh"    || { print -r -- "cannot source lib/common.sh"; exit 1; }
source "$_ROOT/lib/selection.sh" || { print -r -- "cannot source lib/selection.sh"; exit 1; }

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

[[ "$(_fmt_kb_or_na 1536)" == "1.5M" ]] && _pass "fmt_kb_or_na: value -> human" \
                                        || _fail "fmt_kb_or_na: 1536 -> $(_fmt_kb_or_na 1536)"
[[ "$(_fmt_kb_or_na "")"   == "n/a"  ]] && _pass "fmt_kb_or_na: empty -> n/a" \
                                        || _fail "fmt_kb_or_na: empty -> $(_fmt_kb_or_na "")"

# ─────────────────────────────────────────────────────────────────────────────
# 1b. Wiring invariant — the summary's disk line reads DU_BEFORE_KB/DU_AFTER_KB,
#     which ONLY mod_05 populates. A future edit that sets the human string
#     without its KB twin would silently drop the line (the exact gap this
#     check was written after finding). Enforced by construction over the
#     source, in the spirit of IMP-004: close the class, not one instance.
# ─────────────────────────────────────────────────────────────────────────────
_M05="$_ROOT/modules/mod_05_cleanup.sh"
_n_after=$(grep -c '^[[:space:]]*DU_AFTER=' "$_M05")
_n_after_kb=$(grep -c '^[[:space:]]*DU_AFTER_KB=' "$_M05")
(( _n_after > 0 )) && _pass "wiring: mod_05 sets DU_AFTER ($_n_after sites)" \
                   || _fail "wiring: no DU_AFTER assignment found in mod_05"
(( _n_after == _n_after_kb )) && _pass "wiring: every DU_AFTER site has its KB twin" \
                              || _fail "wiring: DU_AFTER x$_n_after vs DU_AFTER_KB x$_n_after_kb"
grep -q '^[[:space:]]*DU_BEFORE_KB=' "$_M05" && _pass "wiring: mod_05 sets DU_BEFORE_KB" \
                                             || _fail "wiring: DU_BEFORE_KB never set in mod_05"
grep -q 'du -sh' "$_M05" && _fail "wiring: mod_05 still runs a second du -sh pass" \
                         || _pass "wiring: cache measured once (no du -sh left)"
# The core must still declare both twins (empty = not measured this run)
grep -q '^DU_BEFORE_KB=""' "$_ROOT/brew_manager.sh" && _pass "wiring: core declares DU_BEFORE_KB empty" \
                                                    || _fail "wiring: core lost the DU_BEFORE_KB declaration"

# ─────────────────────────────────────────────────────────────────────────────
# 2. _run_glyph — constant visible width, level-0 purity, Unicode variants
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=0; _init_palette; TUI_UNICODE=0; _init_symbols
for _st in done preview ran failed unknown; do
    _g="$(_run_glyph "$_st")"
    has_esc "$_g" && _fail "glyph($_st) L0: contains ANSI" || _pass "glyph($_st) L0: no ANSI"
    (( ${#_g} == 4 )) && _pass "glyph($_st) L0: width 4" || _fail "glyph($_st) L0: width ${#_g}"
done
[[ "$(_run_glyph done)"    == "[OK]" ]] && _pass "glyph ascii: done -> [OK]"    || _fail "glyph ascii: done -> $(_run_glyph done)"
[[ "$(_run_glyph preview)" == "[--]" ]] && _pass "glyph ascii: preview -> [--]" || _fail "glyph ascii: preview -> $(_run_glyph preview)"
[[ "$(_run_glyph ran)"     == "[!] " ]] && _pass "glyph ascii: ran -> [!]"      || _fail "glyph ascii: ran -> $(_run_glyph ran)"
[[ "$(_run_glyph failed)"  == "[!!]" ]] && _pass "glyph ascii: failed -> [!!]"  || _fail "glyph ascii: failed -> $(_run_glyph failed)"

TUI_COLOR_LEVEL=2; _init_palette; TUI_UNICODE=1; _init_symbols
for _st in done preview ran failed; do
    _plain="$(strip_ansi "$(_run_glyph "$_st")")"
    (( ${#_plain} == 4 )) && _pass "glyph($_st) unicode: visible width 4" \
                          || _fail "glyph($_st) unicode: visible width ${#_plain}"
done
[[ "$(strip_ansi "$(_run_glyph done)")"    == "✓   " ]] && _pass "glyph unicode: done -> check mark" || _fail "glyph unicode: done wrong"
[[ "$(strip_ansi "$(_run_glyph preview)")" == "↷   " ]] && _pass "glyph unicode: preview -> arrow"   || _fail "glyph unicode: preview wrong"

# ─────────────────────────────────────────────────────────────────────────────
# 2b. _run_status — the truth table the summary's honesty rests on. The rule:
#     only claim "preview" when a dry run provably changed nothing. Deriving it
#     from risk alone labelled ungated mutators (mod_02) as "preview" — a false
#     safety claim in the session log, which is what these cases pin.
# ─────────────────────────────────────────────────────────────────────────────
_expect_status() {
    local got="$(_run_status "$1" "$2" "$3")"
    [[ "$got" == "$4" ]] && _pass "status: dry=$1 risk=$2 gated=$3 -> $4" \
                         || _fail "status: dry=$1 risk=$2 gated=$3 -> $got (expected $4)"
}
# not a dry run: always 'done', whatever the module is
_expect_status 0 ro     1 done
_expect_status 0 danger 1 done
_expect_status 0 danger 0 done
# dry run: read-only modules do their normal work
_expect_status 1 ro     1 done
# dry run: a mutator that honours the gate previewed and changed nothing
_expect_status 1 danger 1 preview
_expect_status 1 write  1 preview
# dry run: a mutator WITHOUT the gate acted anyway — never claim 'preview'
_expect_status 1 write  0 ran
_expect_status 1 danger 0 ran
# defensive defaults: unknown inputs must not fabricate a 'preview' claim
[[ "$(_run_status 1 write)" == "ran" ]] && _pass "status: missing capability -> ran (fail-safe)" \
                                        || _fail "status: missing capability -> $(_run_status 1 write)"

# ─────────────────────────────────────────────────────────────────────────────
# 2c. MODULE_DRYRUN registry — complete, binary, and HONEST: every module
#     marked 'gated' must really contain the dry-run gate in its source. This
#     is the invariant that stops the summary from claiming "nothing changed"
#     for a module that acts (IMP-004: close the class, not the instance).
# ─────────────────────────────────────────────────────────────────────────────
typeset -a _dr_missing=() _dr_bad=() _dr_lying=()
for _k in "${(k)MODULE_DESC[@]}"; do
    _v="${MODULE_DRYRUN[$_k]}"
    if [[ -z "$_v" ]]; then
        _dr_missing+=("$_k")
    elif [[ "$_v" != (0|1) ]]; then
        _dr_bad+=("$_v")
    fi
done
(( ${#MODULE_DESC[@]} >= 18 )) && _pass "dryrun: registry has ${#MODULE_DESC[@]} modules to check" \
                               || _fail "dryrun: registry too small"
(( ${#_dr_missing[@]} == 0 )) && _pass "dryrun: every module declares dry-run capability" \
                              || _fail "dryrun: undeclared: ${_dr_missing[*]}"
(( ${#_dr_bad[@]} == 0 ))     && _pass "dryrun: every value is 0 or 1" \
                              || _fail "dryrun: invalid values: ${_dr_bad[*]}"
# A MUTATING module marked gated must reference BREW_MANAGER_DRY_RUN in its file
for _k in "${(k)MODULE_DESC[@]}"; do
    [[ "${MODULE_RISK[$_k]}" == "ro" ]] && continue
    (( ${MODULE_DRYRUN[$_k]:-0} )) || continue
    _f=("$_ROOT"/modules/mod_${(l:2::0:)_k}_*.sh(N) "$_ROOT"/modules/mod_${_k}_*.sh(N))
    if (( ${#_f[@]} == 0 )); then
        _dr_lying+=("$_k:nofile")
    elif ! grep -q 'BREW_MANAGER_DRY_RUN' "${_f[1]}"; then
        _dr_lying+=("$_k")
    fi
done
(( ${#_dr_lying[@]} == 0 )) && _pass "dryrun: every gated mutator really has the gate" \
                            || _fail "dryrun: claims a gate it does not have: ${_dr_lying[*]}"
# mod_02 now skips `brew update` under --dry-run: flipping it back to 0 would
# re-introduce the "ran anyway" row for a module that no longer acts. That the
# gate really stops the command (not just mentions it) is proven end-to-end
# against a mock brew by tests/test_dryrun_gates.zsh.
[[ "${MODULE_DRYRUN[2]}"   == "1" ]] && _pass "dryrun: mod_02 gated (brew update skipped)" \
                                     || _fail "dryrun: mod_02 honours --dry-run — registry must say 1"
[[ "${MODULE_DRYRUN[mas]}" == "1" ]] && _pass "dryrun: mas gated (install skipped)" \
                                     || _fail "dryrun: mas honours --dry-run — registry must say 1"

# Class invariant (IMP-004: close the class, not the instance). With every
# mutator gated, no module can produce a "ran anyway" row any more — so assert
# it over the WHOLE registry rather than over the two modules just fixed. A
# future module that mutates without the gate has to be declared 0, and fails
# HERE instead of surfacing as a warning in a user's dry-run session.
typeset -a _acts_in_dry=()
for _k in "${(k)MODULE_DESC[@]}"; do
    [[ "$(_run_status 1 "${MODULE_RISK[$_k]}" "${MODULE_DRYRUN[$_k]}")" == "ran" ]] && _acts_in_dry+=("$_k")
done
(( ${#_acts_in_dry[@]} == 0 )) && _pass "dryrun: no module acts under --dry-run (whole registry)" \
                               || _fail "dryrun: acts despite --dry-run: ${_acts_in_dry[*]}"

# ─────────────────────────────────────────────────────────────────────────────
# 3. _spinner — non-TTY: static line, no \r, no ANSI, child rc returned.
#    Palette is POPULATED here on purpose: at level 0 the colour constants are
#    empty, so a "no ANSI" assertion would pass even if the code emitted them
#    from the wrong branch — it would be testing _init_palette, not the gate.
#    Level 2 + TUI_TTY=0 is a real combination (a recorded child reads the
#    colour level and the tty flag from independent handoff variables).
# ─────────────────────────────────────────────────────────────────────────────
TUI_COLOR_LEVEL=2; _init_palette; TUI_UNICODE=0; _init_symbols; TUI_TTY=0
[[ -n "$C_ACCENT" ]] && _pass "spinner non-tty: palette is populated (test has teeth)" \
                     || _fail "spinner non-tty: palette empty — assertions would be vacuous"
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
# \r is the animation and the colour escapes are expected here (the palette is
# populated on purpose); strip both, then require printable ASCII — what is
# left must contain no multibyte frame.
printf '%s' "$(strip_ansi "$_out")" | tr -d '\r' | LC_ALL=C grep -q '[^ -~]' \
                     && _fail "spinner tty ascii: multibyte frame leaked" \
                     || _pass "spinner tty ascii: frames are plain ASCII"

# UTF-8 terminal: the braille frames must actually be used (this path was
# previously never exercised — the section inherited TUI_UNICODE=0).
TUI_UNICODE=1; _init_symbols
_out=$( { (sleep 0.35; exit 0) & } ; _spinner $! "utf8 op" )
printf '%s' "$_out" | LC_ALL=C grep -q $'\xe2\xa0' \
    && _pass "spinner tty utf8: braille frames used" \
    || _fail "spinner tty utf8: no braille frame in output"
TUI_UNICODE=0; _init_symbols
TUI_TTY=0

# ─────────────────────────────────────────────────────────────────────────────
# 4b. Session-log strip — the saved log must show what the TERMINAL showed, not
#     every spinner frame concatenated. The expression is read FROM the core so
#     this exercises the real one, not a copy that could drift away from it.
# ─────────────────────────────────────────────────────────────────────────────
# Comments are excluded: the comment above the sed quotes the OLD rule to
# explain why it was wrong, and matching that text would fail the check.
_CORE="$_ROOT/brew_manager.sh"
_CORE_CODE="$(grep -v '^[[:space:]]*#' "$_CORE")"
printf '%s' "$_CORE_CODE" | grep -q 's/\\r//g' \
    && _fail "log strip: core still deletes CRs wholesale (frames would pile up)" \
    || _pass "log strip: core no longer uses s/\\r//g"
printf '%s' "$_CORE_CODE" | grep -q 's/\.\*\\r//' \
    && _pass "log strip: core applies carriage-return semantics" \
    || _fail "log strip: core lost the s/.*\\r// rule"

# Functional check on a script(1)-shaped sample: CRLF lines plus one animated
# line. Extract the sed program from the core so a future edit is re-tested.
_sedprog="$(grep -o "\$'s/.x1b.*'" "$_CORE" | head -1)"
if [[ -n "$_sedprog" ]]; then
    _pass "log strip: sed program extracted from the core"
    _sample="${TMPDIR:-/tmp}/bm_logsample_$$"
    {
        printf 'plain line one\r\n'
        printf '\r  | doctor... 0s\r  / doctor... 1s\r%-30s\r' ' '
        printf 'line after spinner\r\n'
        printf 'plain line two\r\n'
    } > "$_sample"
    _stripped="$(eval "sed $_sedprog" < "$_sample")"
    [[ "$_stripped" == *"plain line one"* && "$_stripped" == *"plain line two"* ]] \
        && _pass "log strip: ordinary CRLF lines survive intact" \
        || _fail "log strip: ordinary lines were eaten: '$_stripped'"
    [[ "$_stripped" == *"doctor..."* ]] \
        && _fail "log strip: spinner frames still land in the log" \
        || _pass "log strip: spinner frames collapse away"
    [[ "$_stripped" == *"line after spinner"* ]] \
        && _pass "log strip: output after the spinner is kept" \
        || _fail "log strip: output after the spinner was lost"
    rm -f "$_sample"
else
    _fail "log strip: could not extract the sed program from the core"
fi
# The strip is the only step that can destroy the session's audit artefact:
# it must refuse to replace a non-empty log with an empty one.
printf '%s' "$_CORE_CODE" | grep -q '\[\[ -s "\$_tmp" \]\]' \
    && _pass "log strip: refuses to replace a log with an empty one" \
    || _fail "log strip: lost the emptiness guard on the saved log"

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
