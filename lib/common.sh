#!/bin/zsh
# =============================================================================
# lib/common.sh — Shared colors, symbols and TUI utilities
# Sourced by brew_manager.sh and all modules
#
# Rendering is CAPABILITY-AWARE (BM-09): the palette and glyphs adapt to what
# the terminal can actually show and degrade to plain ASCII when they can't.
#   - non-tty / piped / NO_COLOR  → no ANSI at all (clean output at the source)
#   - poor terminal (16 colors)   → the historical palette, unchanged
#   - 256 / truecolor             → the semantic palette (one tint = one state)
#   - non-UTF-8 locale            → ASCII box glyphs (+-|) instead of round ones
# Every module writes through the ${C_*}/${SYM_*} constants below, so this one
# file drives the whole app's degradation — no module needs to know about it.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# CAPABILITY DETECTION
# ─────────────────────────────────────────────────────────────────────────────

# _tui_color_level <is_tty> <ncolors> → 0|1|2|3
#   0 = no ANSI · 1 = 16 colors · 2 = 256 colors · 3 = truecolor
# Kept pure (tty state and color count as ARGS, only the two user/terminal
# preferences NO_COLOR and COLORTERM read from the environment) so it is
# unit-testable without a real terminal. Mirrors the design in
# .claude/memory/plans/roadmap-v2.md §4.2.
_tui_color_level() {
    local is_tty="$1" ncolors="$2"
    [[ "$ncolors" == <-> ]] || ncolors=0                       # non-numeric → none
    [[ -n "$NO_COLOR" ]]     && { print -r -- 0; return; }     # user opted out
    (( is_tty ))             || { print -r -- 0; return; }     # non-tty/pipe → clean
    [[ "$COLORTERM" == (truecolor|24bit) ]] && { print -r -- 3; return; }
    (( ncolors >= 256 ))     && { print -r -- 2; return; }
    (( ncolors >= 8 ))       && { print -r -- 1; return; }
    print -r -- 0                                              # a tty that claims no color
}

# _tui_unicode → 1 if the locale is UTF-8 (round box glyphs are safe to emit),
# else 0 (fall back to ASCII +-|).
# Honors POSIX character-type precedence — LC_ALL overrides LC_CTYPE overrides
# LANG (first non-empty wins), NOT a union of all three. `LC_ALL=C` must force
# the ASCII fallback even when LANG carries a UTF-8 value (a common CI/cron/
# `env`-wrapper combo): otherwise the round glyphs render as mojibake AND, in a C
# locale, zsh counts a 3-byte '─' as 3 columns, so _box's border-width math
# misaligns. (Union matching missed this — gate finding BM-09.)
_tui_unicode() {
    local eff="${LC_ALL:-${LC_CTYPE:-$LANG}}"
    [[ "$eff" == *(UTF-8|utf-8|UTF8|utf8)* ]] && print -r -- 1 || print -r -- 0
}

# _detect_capabilities: populate TUI_COLOR_LEVEL / TUI_UNICODE.
#
# The tool re-execs itself under script(1) for session logging, and script(1)
# hands the child a PTY — so inside the re-exec `-t 1` is TRUE and `tput colors`
# reflects the pty, NOT the real destination the parent was launched from. We
# therefore detect ONCE on the first launch (from the real stdout) and hand the
# result to the child through the environment, exactly like the NON_INTERACTIVE
# consent handoff in brew_manager.sh. A fresh (non-recording) run ALWAYS
# re-detects and re-exports, so a stale BREW_MANAGER_TUI_* value in the
# environment can never mis-color an interactive session.
_detect_capabilities() {
    if [[ -n "$BREW_MANAGER_RECORDING" ]]; then
        # Inside the script(1) re-exec: trust the parent's handoff. Missing
        # handoff defaults to the SAFE choice (no color / ASCII), never garbage.
        TUI_COLOR_LEVEL="${BREW_MANAGER_TUI_LEVEL:-0}"
        TUI_UNICODE="${BREW_MANAGER_TUI_UNICODE:-0}"
        TUI_TTY="${BREW_MANAGER_TUI_TTY:-0}"
        return
    fi
    local is_tty=0; [[ -t 1 ]] && is_tty=1
    local ncolors; ncolors="$(tput colors 2>/dev/null || echo 0)"
    TUI_COLOR_LEVEL="$(_tui_color_level "$is_tty" "$ncolors")"
    TUI_UNICODE="$(_tui_unicode)"
    # TUI_TTY records whether the REAL destination is a terminal (independent of
    # color): screen-control like `clear` gates on this so a piped/agent run
    # stays free of cursor sequences even when a NO_COLOR terminal would still
    # want them. Handed off across the re-exec for the same pty reason as above.
    TUI_TTY="$is_tty"
    export BREW_MANAGER_TUI_LEVEL="$TUI_COLOR_LEVEL"
    export BREW_MANAGER_TUI_UNICODE="$TUI_UNICODE"
    export BREW_MANAGER_TUI_TTY="$TUI_TTY"
}

# ─────────────────────────────────────────────────────────────────────────────
# PALETTE — semantic, one tint = one state (BM-09, roadmap §4.3)
# ─────────────────────────────────────────────────────────────────────────────

# _init_palette: assign the color constants for the detected tier. The values
# are stored as the literal "\033[…m" strings the whole codebase already relies
# on (rendered by `echo -e` / `printf`), so behavior is byte-identical to the
# historical output at the 16-color baseline. Level 0 makes every constant an
# empty string — that is what strips ANSI at the SOURCE for pipes / NO_COLOR,
# not just from the saved log.
_init_palette() {
    local L="$TUI_COLOR_LEVEL"

    if (( L == 0 )); then
        NC='' BOLD='' DIM=''
        C_WHITE='' C_CYAN='' C_CYAN_B='' C_GREEN='' C_GREEN_B='' C_YELLOW='' \
        C_RED='' C_BLUE='' C_PURPLE='' C_PURPLE_B='' C_GRAY='' C_ORANGE=''
        C_HEADING='' C_OK='' C_WARN='' C_DANGER='' C_INFO='' C_BRAND='' C_ACCENT=''
        return
    fi

    # Base = 16 colors: the historical palette, kept exactly as-is so a poor
    # terminal renders precisely what it always did.
    NC='\033[0m'; BOLD='\033[1m'; DIM='\033[2m'
    C_WHITE='\033[1;37m'
    C_CYAN='\033[0;36m';   C_CYAN_B='\033[1;36m'
    C_GREEN='\033[0;32m';  C_GREEN_B='\033[1;32m'
    C_YELLOW='\033[1;33m'
    C_RED='\033[0;31m'
    C_BLUE='\033[0;34m'
    C_PURPLE='\033[0;35m'; C_PURPLE_B='\033[1;35m'
    C_GRAY='\033[0;90m'
    C_ORANGE='\033[0;33m'

    # 256-color semantic hues. Structural colors (cyan/blue/purple) are left on
    # the base palette on purpose — only the STATE colors gain a richer hue, so
    # the visual language stays "one tint = one state". (Collapsing the
    # structural colors is a menu-redesign decision, BM-11, not the foundation.)
    if (( L >= 2 )); then
        C_WHITE='\033[1;38;5;231m'
        C_GREEN='\033[38;5;71m';  C_GREEN_B='\033[1;38;5;71m'
        C_YELLOW='\033[38;5;178m'
        C_RED='\033[1;38;5;167m'
        C_GRAY='\033[38;5;245m'
        C_ORANGE='\033[38;5;214m'
    fi

    # Truecolor semantic hues (hex from the design palette, roadmap §4.3).
    if (( L >= 3 )); then
        C_WHITE='\033[1;38;2;255;255;255m'
        C_GREEN='\033[38;2;95;175;95m';  C_GREEN_B='\033[1;38;2;95;175;95m'
        C_YELLOW='\033[38;2;215;175;0m'
        C_RED='\033[1;38;2;215;95;95m'
        C_GRAY='\033[38;2;138;138;138m'
        C_ORANGE='\033[38;2;215;135;0m'
    fi

    # Semantic aliases — derived AFTER the tier overrides so they follow the hue.
    # New code (badges, boxes, summaries) uses these names; the legacy C_* names
    # above ARE the same palette, so old and new output stay coherent.
    C_HEADING="$C_WHITE"     # bold white  — titles / headings
    C_OK="$C_GREEN_B"        # green       — success / read-only / safe
    C_WARN="$C_YELLOW"       # yellow      — attention / writes metadata|cache
    C_DANGER="$C_RED"        # red (bold)  — destructive: removes/installs/loads
    C_INFO="$C_GRAY"         # dim         — secondary information
    C_BRAND="$C_ORANGE"      # 🍺 accent   — the single brand tint
    C_ACCENT="$C_CYAN_B"     # cyan        — structural accent (rules/headers)
}

# ─────────────────────────────────────────────────────────────────────────────
# SYMBOLS & BOX GLYPHS — UTF-8 or ASCII fallback (BM-09, roadmap §4.4)
# ─────────────────────────────────────────────────────────────────────────────

_init_symbols() {
    if (( TUI_UNICODE )); then
        SYM_OK='✓'; SYM_WARN='⚠'; SYM_ERR='✗'; SYM_INFO='›'; SYM_DOT='•'
        SYM_ARR='→'; SYM_PKG='⬡'; SYM_APP='⬢'; SYM_LOCK='◈'; SYM_STAR='★'
        BOX_TL='╭'; BOX_TR='╮'; BOX_BL='╰'; BOX_BR='╯'; BOX_H='─'; BOX_V='│'
    else
        SYM_OK='+'; SYM_WARN='!'; SYM_ERR='x'; SYM_INFO='>'; SYM_DOT='*'
        SYM_ARR='->'; SYM_PKG='#'; SYM_APP='@'; SYM_LOCK='#'; SYM_STAR='*'
        BOX_TL='+'; BOX_TR='+'; BOX_BL='+'; BOX_BR='+'; BOX_H='-'; BOX_V='|'
    fi
}

# Run detection + init at source time (as TERM_WIDTH below always has been).
_detect_capabilities
_init_palette
_init_symbols

# ─────────────────────────────────────────────────────────────────────────────
# TERMINAL WIDTH
# ─────────────────────────────────────────────────────────────────────────────

# Strip any non-numeric chars — tput cols can return garbage inside script(1)
TERM_WIDTH=$(tput cols 2>/dev/null | tr -cd '[:digit:]')
[[ "$TERM_WIDTH" =~ ^[0-9]+$ ]] || TERM_WIDTH=80
(( TERM_WIDTH < 60 )) && TERM_WIDTH=60
(( TERM_WIDTH > 100 )) && TERM_WIDTH=100

# Standard left indent for boxed / padded content (roadmap §4.4: 2 spaces).
TUI_INDENT="  "

# ─────────────────────────────────────────────────────────────────────────────
# TUI UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

# _repeat <n> <char> → a string of <char> repeated <n> times (n<=0 → empty).
# Built char-by-char so a multibyte glyph (─) counts as one, not as its bytes.
_repeat() {
    local n="$1" ch="$2" out="" i
    for (( i=0; i<n; i++ )); do out+="$ch"; done
    printf '%s' "$out"
}

_hline() {
    local char="${1:-─}" color="${2:-$C_GRAY}" line=""
    # ASCII fallback: without a UTF-8 locale the heavy/light rule glyphs render
    # as garbage — map the known ones so a rule stays a rule everywhere, and
    # coerce any other non-ASCII char to '-'.
    if (( ! TUI_UNICODE )); then
        case "$char" in
            ═)      char='=' ;;
            ─|━|┄)  char='-' ;;
            ·)      char='.' ;;
            *)      [[ "$char" == [[:ascii:]] ]] || char='-' ;;
        esac
    fi
    for (( i=0; i<TERM_WIDTH; i++ )); do line+="$char"; done
    echo -e "${color}${line}${NC}"
}

# _box <frame_color> <title> [line ...]
# Draws a bordered block at the standard 2-space indent — a rounded box in
# UTF-8, +--+ in ASCII, no borders/color when degraded. The FRAME is colored;
# the TITLE and content lines are rendered as literal DATA (printf %s / %-*s,
# never `echo -e`), so a caller-supplied title/line — a module name, a package,
# a path — cannot expand backslash escapes or inject terminal control sequences
# (the "echo on data" trap; gate-hardened for the BM-10/BM-11 consumers). Pass
# plain text for correct alignment; a line longer than the inner field is NOT
# truncated — never hide content such as what a destructive action will remove —
# it simply overflows the right border.
_box() {
    local color="$1" title="$2"; shift 2
    local inner=$(( TERM_WIDTH - 4 ))         # span between the two border columns
    (( inner < 10 )) && inner=10              # floor for very narrow terminals
    local field=$(( inner - 2 ))              # text field (one space of pad each side)

    local top
    if [[ -n "$title" ]]; then
        local head="${BOX_H} ${title} "
        local fill=$(( inner - ${#head} ))
        (( fill < 0 )) && fill=0
        top="${BOX_TL}${head}$(_repeat $fill "$BOX_H")${BOX_TR}"
    else
        top="${BOX_TL}$(_repeat $inner "$BOX_H")${BOX_TR}"
    fi
    # %b renders the trusted color/NC escapes; %s keeps the border+title literal.
    printf '%s%b%s%b\n' "$TUI_INDENT" "$color" "$top" "$NC"

    local line
    for line in "$@"; do
        printf '%s%b%s%b %-*s %b%s%b\n' \
            "$TUI_INDENT" "$color" "$BOX_V" "$NC" "$field" "$line" "$color" "$BOX_V" "$NC"
    done

    printf '%s%b%s%b\n' "$TUI_INDENT" "$color" "${BOX_BL}$(_repeat $inner "$BOX_H")${BOX_BR}" "$NC"
}

# _pad <text> → the text indented by the standard 2 spaces.
_pad() { printf '%s%s\n' "$TUI_INDENT" "${1-}"; }

# _clear: clear the screen only when the real destination is a terminal. Piped
# or non-interactive output must stay free of cursor-control sequences — the
# same source-level cleanliness reason color is suppressed — so a captured or
# scheduled-agent run produces plain text a log/pipe can consume as-is.
_clear() { (( TUI_TTY )) && clear; }

# NOTE: _header_main (the boxed ═══ main banner) was removed with BM-11 — its
# only call-site, the brew_manager.sh startup banner, now renders a flat brand
# line inline (the same dead-code hygiene as BM-07).

_section() {
    local num="$1" title="$2"
    echo ""
    _hline "─" "$C_GRAY"
    echo -e "${C_PURPLE_B}  ${num}. ${title}${NC}"
    _hline "─" "$C_GRAY"
}

_ok()   { local msg="$1"; echo -e "  ${C_GREEN_B}${SYM_OK}${NC}  ${msg}"; }
_warn() { local msg="$1"; echo -e "  ${C_YELLOW}${SYM_WARN}${NC}  ${msg}"; }
_err()  { local msg="$1"; echo -e "  ${C_RED}${SYM_ERR}${NC}  ${msg}"; }
_info() { local msg="$1"; echo -e "  ${C_BLUE}${SYM_INFO}${NC}  ${msg}"; }
_item() { local msg="$1"; echo -e "  ${C_GRAY}${SYM_DOT}${NC}  ${msg}"; }

# _spinner <pid> <label> — progress indicator for a long-running background
# command (BM-12, roadmap §4.6). Returns the child's exit status via wait, so a
# caller CAN branch on it (today's callers read a log file instead — that stays
# valid).
#
# Gated on TUI_TTY, not on RECORDING (IMP-005): the recorded child inherits the
# parent's real tty-ness through the BM-09 handoff, so an interactive session
# finally SEES the spinner, while a piped/agent run emits no \r and no cursor
# control — one static status line says what is running, then we just wait.
# The \r frames in interactive runs are already stripped from the saved log by
# the end-of-session sed. Frames degrade to ASCII | / - \ without UTF-8; the
# elapsed-seconds counter tells a stuck operation from a slow one. The label is
# caller DATA: printf %s only, never echo -e (IMP-003).
_spinner() {
    local pid=$1 msg="$2"
    if (( ! TUI_TTY )); then
        printf '%s%s  %s... (running)\n' "$TUI_INDENT" "$SYM_INFO" "$msg"
        wait "$pid" 2>/dev/null
        return $?
    fi
    local -a frames
    if (( TUI_UNICODE )); then
        frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    else
        frames=('|' '/' '-' '\')
    fi
    # zsh arrays are 1-based: the +1 keeps index 0 from selecting an empty
    # frame (an off-by-one the old spinner carried, invisible only because it
    # never ran under the always-on recorder).
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r%s%b%s%b  %s... %ss' "$TUI_INDENT" "$C_ACCENT" \
            "${frames[$(( i % ${#frames[@]} + 1 ))]}" "$NC" "$msg" "$(( i / 10 ))"
        (( i++ ))
        sleep 0.1
    done
    printf '\r%-*s\r' "$TERM_WIDTH" " "
    wait "$pid" 2>/dev/null
    return $?
}

# ─────────────────────────────────────────────────────────────────────────────
# RUN-SUMMARY RENDERERS (BM-12) — pure, level-driven, no global state mutated.
# The per-module status itself is assigned by the dispatch loop in
# brew_manager.sh; these only render it.
# ─────────────────────────────────────────────────────────────────────────────

# _run_glyph <status> → the per-module outcome glyph at a CONSTANT visible
# width (4 columns), same discipline as _risk_badge so the summary columns
# never move when colour or Unicode is off:
#   done     ✓ / [OK]  (green)   — module ran to completion
#   preview  ↷ / [--]  (yellow)  — dry-run: mutating actions were previewed only
#   failed   ✗ / [!!]  (red)     — RESERVED: no caller assigns it until module
#                                  return codes get a contract (BM-18 — today's
#                                  returns are noise, see STATE #4b)
_run_glyph() {
    local color text text_u text_a
    case "$1" in
        done)    color="$C_OK"     ; text_u='✓   ' ; text_a='[OK]' ;;
        preview) color="$C_WARN"   ; text_u='↷   ' ; text_a='[--]' ;;
        failed)  color="$C_DANGER" ; text_u='✗   ' ; text_a='[!!]' ;;
        *)       color="$C_INFO"   ; text_u='?   ' ; text_a='[??]' ;;
    esac
    (( TUI_UNICODE )) && text="$text_u" || text="$text_a"
    printf '%b%s%b' "$color" "$text" "$NC"
}

# _fmt_secs <n> → compact human duration: "42s", "1m 12s". Minutes never roll
# over into hours — a brew session measured in hours is a problem the summary
# should show loudly, not compress.
_fmt_secs() {
    local s="${1:-0}"
    if (( s < 60 )); then
        printf '%ss' "$s"
    else
        printf '%sm %ss' "$(( s / 60 ))" "$(( s % 60 ))"
    fi
}

# _fmt_kb <kb> → human size from kilobytes, ASCII only: "512K", "1.5M", "1.2G".
# One decimal above the unit boundary — enough for a cache-size delta, and the
# output stays short for a fixed summary column.
_fmt_kb() {
    local kb="${1:-0}"
    if (( kb < 1024 )); then
        printf '%sK' "$kb"
    elif (( kb < 1048576 )); then
        printf '%d.%dM' "$(( kb / 1024 ))" "$(( (kb % 1024) * 10 / 1024 ))"
    else
        printf '%d.%dG' "$(( kb / 1048576 ))" "$(( (kb % 1048576) * 10 / 1048576 ))"
    fi
}

# _fmt_kb_or_na <kb> → _fmt_kb of the value, or "n/a" when the measurement is
# missing. Lets a caller keep ONE measurement (the KB twin the summary
# subtracts) and still print a human string, instead of running `du` twice over
# a cache that can hold thousands of files.
_fmt_kb_or_na() { [[ -n "${1-}" ]] && _fmt_kb "$1" || printf 'n/a'; }

# _du_kb <path> → the path's disk usage in KB, or the empty string when it
# cannot be measured (missing path, permissions): the caller must treat "" as
# "no measurement", never as zero — a 0 would render as a fake "freed" delta.
_du_kb() {
    local kb
    kb=$(du -sk "$1" 2>/dev/null | cut -f1)
    [[ "$kb" == <-> ]] && printf '%s' "$kb"
}

_ask() {
    local question="$1"
    local default="${2:-n}"  # second arg sets default: y or n
    # Explicit consent (--yes): take the built-in default without prompting.
    if (( BREW_MANAGER_YES )); then
        echo -e "\n  ${C_CYAN_B}?${NC}  ${C_WHITE}${question}${NC} ${C_GRAY}[auto: ${default}]${NC}"
        [[ "$default" == "y" ]] && return 0 || return 1
    fi
    # Non-interactive WITHOUT --yes: NEVER auto-confirm — decline (fail-closed),
    # rather than read a dead stdin. This is what keeps a destructive default
    # (e.g. mod_05's cleanup, default y) from running unattended: consent to take
    # a default comes only from an explicit --yes, never from "there's no tty".
    if (( BREW_MANAGER_NONINTERACTIVE )); then
        echo -e "\n  ${C_CYAN_B}?${NC}  ${C_WHITE}${question}${NC} ${C_GRAY}[non-interactive: no]${NC}"
        return 1
    fi
    echo -e "\n  ${C_CYAN_B}?${NC}  ${C_WHITE}${question}${NC} ${C_GRAY}(y/N)${NC} "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# _read_choice: reads user input or returns default in non-interactive mode.
# Callers capture the VALUE with $(...): everything informational (auto-answer
# notice, interactive prompt) must go to stderr, or it pollutes the captured
# value and the selection silently never matches (bug fixed in BM-04).
_read_choice() {
    local prompt="$1"
    local default="$2"
    local varname="$3"   # optional: env var override (e.g. BREW_MANAGER_ADOPT)
    # Check env var override first
    if [[ -n "$varname" ]]; then
        local override="${(P)varname}"
        if [[ -n "$override" ]]; then
            echo -e "  ${C_CYAN}${SYM_ARR}${NC}  ${prompt} ${C_GRAY}[auto: ${override}]${NC}" >&2
            printf '%s\n' "$override"
            return
        fi
    fi
    # Explicit consent (--yes): use the default without prompting.
    if (( BREW_MANAGER_YES )); then
        echo -e "  ${C_CYAN}${SYM_ARR}${NC}  ${prompt} ${C_GRAY}[auto: ${default}]${NC}" >&2
        printf '%s\n' "$default"
        return
    fi
    # Non-interactive WITHOUT --yes: use the (safe) default instead of reading a
    # dead stdin — the same value a --yes run takes, but a per-item _ask still
    # declines, so nothing is auto-confirmed.
    if (( BREW_MANAGER_NONINTERACTIVE )); then
        echo -e "  ${C_CYAN}${SYM_ARR}${NC}  ${prompt} ${C_GRAY}[non-interactive: ${default}]${NC}" >&2
        printf '%s\n' "$default"
        return
    fi
    printf "  ${C_CYAN}${SYM_ARR}${NC}  %s: " "$prompt" >&2
    local _rc_response
    read -r _rc_response
    # printf %s: the value is DATA — zsh echo would expand backslash escapes
    printf '%s\n' "${_rc_response:-$default}"
}

_stat_row() {
    local label="$1" value="$2" color="${3:-$C_WHITE}"
    printf "  ${C_GRAY}%-30s${NC} ${color}%s${NC}\n" "$label" "$value"
}

# ─────────────────────────────────────────────────────────────────────────────
# RISK BADGES (BM-10) — one glyph = one risk level, sharing the semantic palette
# ─────────────────────────────────────────────────────────────────────────────
#
# The badge makes a module's blast radius visible BEFORE the action: [RO] reads
# only, [W] writes metadata/cache, [!] can change the system (remove/install/
# adopt/schedule). The level classification lives in MODULE_RISK (lib/selection.sh),
# adversarially audited so it never UNDERSTATES risk (a low badge is a security
# bug, docs/03). These renderers are PURE (level in → string out) and colour
# through the BM-09 palette, so a piped / NO_COLOR run degrades them to plain
# ASCII at the source like every other glyph. _ask_danger (below) reuses the same
# C_DANGER tint for the destructive-confirmation frame.

# _risk_badge <level> → a colour-coded badge of CONSTANT visible width (4 columns:
# "[RO]" / "[W] " / "[!] "), so menu columns stay aligned whether or not colour is
# on. An unrecognised level renders a neutral "[?] " rather than misleading the
# reader. The colour is a trusted palette constant (rendered with %b); the bracket
# text is a fixed literal and no caller data reaches it, so there is no
# echo-on-data risk (IMP-003) here.
_risk_badge() {
    local color text
    case "$1" in
        ro)     color="$C_OK";     text='[RO]' ;;
        write)  color="$C_WARN";   text='[W] ' ;;
        danger) color="$C_DANGER"; text='[!] ' ;;
        *)      color="$C_GRAY";   text='[?] ' ;;
    esac
    printf '%b%s%b' "$color" "$text" "$NC"
}

# _risk_caption <level> → one plain-English line explaining the badge, for the
# "About this module" block. Generic by level ON PURPOSE: the SPECIFIC actions a
# destructive module will take are spelt out in its danger box at action time
# (_ask_danger), not here, so this caption cannot drift out of sync with behaviour.
_risk_caption() {
    case "$1" in
        ro)     printf '%s' 'Read-only: inspects and reports, changes nothing.' ;;
        write)  printf '%s' 'Writes metadata/cache only; installs and removes nothing.' ;;
        danger) printf '%s' 'Can change your system: removes, installs, adopts, or schedules.' ;;
        *)      printf '%s' 'Risk level unknown.' ;;
    esac
}

# _ask_danger <title> <question> <default> [detail ...]  → _ask's exit status.
# The danger-styled confirmation for a DESTRUCTIVE action: it draws a red-framed
# box (the C_DANGER tint) naming the action and spelling out exactly what it will
# do (the [detail] lines), THEN delegates the actual consent to _ask, UNCHANGED.
# That split is deliberate and load-bearing: the box is pure presentation; _ask
# alone decides — interactive prompt, --yes auto-default, or non-interactive
# fail-closed — so the consent semantics stay byte-for-byte identical to calling
# _ask directly (the guard-rail invariant of BM-08c/BM-09 is preserved; the
# danger box only makes the risk VISIBLE, it never grants or withholds consent).
# Call it on the REAL execution path only: the per-module --dry-run branch shows
# its own preview and must never reach a confirmation. Detail lines are rendered
# by _box as literal DATA (printf %s), so a caller string cannot inject escapes.
_ask_danger() {
    local title="$1" question="$2" default="$3"; shift 3
    _box "$C_DANGER" "[!] $title" "$@"
    _ask "$question" "$default"
}
