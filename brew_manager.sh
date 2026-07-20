#!/bin/zsh
# =============================================================================
# brew_manager.sh — Homebrew Audit, Cleanup & Unmanaged App Report
# Compatible: macOS + zsh (tested on Apple Silicon M-series)
# Developed by M2NDLAB — https://github.com/M2NDLAB/brew-manager
#
# Structure:
#   VERSION               ← the version, single source of truth
#   brew_manager.sh       ← this file (entry point, menu, dispatch, summary)
#   lib/common.sh         ← colors, symbols, TUI utilities
#   lib/log.sh            ← session log management
#   modules/mod_NN_*.sh   ← one file per numbered module
#   modules/mod_<name>_*.sh ← one file per named module (bk, las, log, mas)
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

# Resolve absolute script directory
# Works with: ./relative/path, /absolute/path, symlinks, script(1) relaunch
if [[ -n "$BREW_MANAGER_SCRIPT_DIR" ]]; then
    SCRIPT_DIR="$BREW_MANAGER_SCRIPT_DIR"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    export BREW_MANAGER_SCRIPT_DIR="$SCRIPT_DIR"
fi

# ─────────────────────────────────────────────────────────────────────────────
# VERSION — single source of truth
# ─────────────────────────────────────────────────────────────────────────────

# The VERSION file is authoritative: it ships with the code and works
# everywhere (git clone, GitHub tarball, plain copy). 'git describe' only
# ENRICHES it when a work tree is present, showing how far we are from the
# tag. 'make version-check' keeps the file aligned with the tags, so the
# drift this replaces (constant stuck at 1.1.0 while tags were at v1.1.2)
# cannot silently come back.
BREW_MANAGER_VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')"
[[ -z "$BREW_MANAGER_VERSION" ]] && BREW_MANAGER_VERSION="unknown"

_version_string() {
    local _git_desc=""
    if [[ -d "$SCRIPT_DIR/.git" ]] && command -v git &>/dev/null; then
        # Release tags only (vX.Y.Z, no suffix): a helper tag like
        # v1.1.2-baseline would otherwise be picked as the nearest tag and
        # make the reported version misleading
        _git_desc="$(git -C "$SCRIPT_DIR" describe --tags --dirty \
            --match 'v[0-9]*.[0-9]*.[0-9]*' --exclude '*-*' 2>/dev/null)"
    fi
    if [[ -n "$_git_desc" ]]; then
        printf 'brew-manager %s (%s)\n' "$BREW_MANAGER_VERSION" "$_git_desc"
    else
        printf 'brew-manager %s\n' "$BREW_MANAGER_VERSION"
    fi
}

# --version must answer before anything else: no logs/ directory, no Homebrew
# check, no TUI
for _arg in "$@"; do
    case "$_arg" in
        --version|-V) _version_string; exit 0 ;;
    esac
done

# Ensure logs/ directory exists and is writable — never fail silently
_LOGS_DIR="$SCRIPT_DIR/logs"
if [[ ! -d "$_LOGS_DIR" ]]; then
    mkdir -p "$_LOGS_DIR" 2>/dev/null || {
        # Fallback: use a temp directory if logs/ cannot be created
        _LOGS_DIR="$(mktemp -d)"
        echo "WARNING: could not create $SCRIPT_DIR/logs — using $_LOGS_DIR instead" >&2
    }
elif [[ ! -w "$_LOGS_DIR" ]]; then
    # Directory exists but is not writable — fall back to temp
    _LOGS_DIR="$(mktemp -d)"
    echo "WARNING: $SCRIPT_DIR/logs is not writable — using $_LOGS_DIR instead" >&2
fi
LOG_FILE="$_LOGS_DIR/brew_report_$(date +%Y%m%d_%H%M%S).log"

# ─────────────────────────────────────────────────────────────────────────────
# FLAGS
# ─────────────────────────────────────────────────────────────────────────────

# Parse the CLI flags AND the optional positional module selection. A bare
# argument (e.g. 0,4,5 or 'go') selects modules non-interactively; --only/--skip
# filter that selection. When any of these is present the menu is skipped (see
# the CLI SELECTION branch below). With none, selection comes from the interactive
# Choice prompt, exactly as before.
# Usage: ./brew_manager.sh [modules] [--only=ids] [--skip=ids] [--dry-run] [--yes|-y] [--adopt=n|all|1,2] [--upgrade=y|n] [--version|-V]
DRY_RUN=0
YES_MODE=0       # --yes: skip all prompts using built-in defaults
ADOPT_ANSWER=""  # --adopt=n|all|1,2,3
UPGRADE_ANSWER="" # --upgrade=y|n
ONLY_ANSWER=""   # --only=<ids>: keep only these modules from the selection
SKIP_ANSWER=""   # --skip=<ids>: drop these modules from the selection
typeset -a _POSITIONAL=()  # bare module spec tokens (joined with commas below)

# NON_INTERACTIVE marks a run with no usable stdin (a LaunchAgent, a pipe, cron,
# `ssh host cmd` without -t). Its ONLY job is to keep _ask / _read_choice from
# blocking on a dead stdin — it is NOT consent. Consent to auto-confirm a
# prompt's built-in default comes ONLY from an explicit --yes (parsed below): a
# non-interactive run WITHOUT --yes DENIES every _ask (fail-closed), so a
# destructive default (e.g. mod_05's cleanup) is never taken unattended.
#
# The script re-execs itself under script(1) for logging, and script(1) gives the
# child a pty (a TTY) — so `! -t 0` is false in the child. We therefore detect on
# the FIRST launch from the real stdin and, in the re-exec'd child (RECORDING
# set), trust the parent's internal handoff BREW_MANAGER_NONINTERACTIVE instead.
# That handoff never grants consent and is only read inside the re-exec, so a
# stale value in the environment cannot silence prompts on a fresh interactive run.
NON_INTERACTIVE=0
if [[ -z "$BREW_MANAGER_RECORDING" ]]; then
    [[ ! -t 0 ]] && NON_INTERACTIVE=1
else
    [[ "${BREW_MANAGER_NONINTERACTIVE:-0}" == "1" ]] && NON_INTERACTIVE=1
fi

for _arg in "$@"; do
    case "$_arg" in
        --dry-run)              DRY_RUN=1 ;;
        --yes|-y)               YES_MODE=1 ;;
        --adopt=*)              ADOPT_ANSWER="${_arg#--adopt=}" ;;
        --upgrade=*)            UPGRADE_ANSWER="${_arg#--upgrade=}" ;;
        --only=*)               ONLY_ANSWER="${_arg#--only=}" ;;
        --skip=*)               SKIP_ANSWER="${_arg#--skip=}" ;;
        --version|-V)           ;;  # already handled above, before any side effect
        -*|–*|—*|−*)
            # A mistyped flag must never run with defaults silently:
            # --dryrun would execute the REAL cleanup believing it is a dry-run.
            # Unicode dash lookalikes (en/em dash, minus) come from smart-dash
            # copy-paste and would otherwise slip through as positionals
            echo "ERROR: unknown flag: ${_arg}" >&2
            echo "Accepted flags: [modules] --only=ids --skip=ids --dry-run --yes|-y --adopt=n|all|1,2 --upgrade=y|n --version|-V" >&2
            exit 2
            ;;
        *)  # A bare (non-flag) argument is a module selection token. Collected
            # here; validated only later, once lib/selection.sh has defined the
            # registry (the CLI SELECTION branch below).
            _POSITIONAL+=("$_arg")
            ;;
    esac
done

# Join the bare arguments into one selection spec: both `0,4,5` (one arg) and
# `0 4 5` (three args) become "0,4,5". CLI_SELECTION marks a non-interactive run.
SELECTION_SPEC="${(j:,:)_POSITIONAL}"
CLI_SELECTION=0
[[ -n "$SELECTION_SPEC" || -n "$ONLY_ANSWER" || -n "$SKIP_ANSWER" ]] && CLI_SELECTION=1

export BREW_MANAGER_DRY_RUN=$DRY_RUN
# Overwrite any inherited value: ONLY an explicit --yes on THIS invocation sets it,
# so a stale BREW_MANAGER_YES in the environment can never auto-confirm prompts.
export BREW_MANAGER_YES=$YES_MODE
export BREW_MANAGER_NONINTERACTIVE=$NON_INTERACTIVE
# Export RAW values (empty when the flag was not passed): a non-empty default
# here would make _read_choice's override branch always fire, killing the
# interactive prompt. Consumers apply their own 'n' default (${VAR:-n}).
export BREW_MANAGER_ADOPT="$ADOPT_ANSWER"
export BREW_MANAGER_UPGRADE="$UPGRADE_ANSWER"

# ─────────────────────────────────────────────────────────────────────────────
# SOURCE LIBRARY
# ─────────────────────────────────────────────────────────────────────────────

source "$SCRIPT_DIR/lib/common.sh"    || { echo "ERROR: lib/common.sh not found"; exit 1; }
source "$SCRIPT_DIR/lib/log.sh"       || { echo "ERROR: lib/log.sh not found"; exit 1; }
# selection.sh defines the module registry (MODULE_DESC/MODULE_IDS) and the
# _resolve_selection parser; sourcing it here keeps that data available to the
# menu, the dispatcher and the summary below.
source "$SCRIPT_DIR/lib/selection.sh" || { echo "ERROR: lib/selection.sh not found"; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# HOMEBREW CHECK
# ─────────────────────────────────────────────────────────────────────────────

if ! command -v brew &>/dev/null; then
    _clear
    echo ""
    echo -e "${C_CYAN_B}  🍺  BREW MANAGER${NC}"
    echo ""
    echo -e "${C_RED}  ${SYM_ERR}  Homebrew is not installed on this system.${NC}"
    echo ""
    echo -e "${C_GRAY}  Homebrew is required for brew-manager to work.${NC}"
    echo -e "${C_GRAY}  It is the macOS package manager that this tool is built around.${NC}"
    echo ""
    echo -e "${C_WHITE}  Install Homebrew now?${NC} ${C_GRAY}(y/N)${NC}"
    echo ""
    printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice: "
    read -r _brew_install_choice

    if [[ "$_brew_install_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "  ${C_CYAN}${SYM_INFO}${NC}  Installing Homebrew..."
        echo ""
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo ""

        # After install, add brew to PATH for current session (Apple Silicon path)
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -f /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        if command -v brew &>/dev/null; then
            echo ""
            echo -e "  ${C_GREEN_B}  ${SYM_OK}  Homebrew installed successfully — launching brew-manager...${NC}"
            sleep 1
            # Re-exec the script now that brew is available
            exec zsh "$0" "$@"
        else
            echo ""
            echo -e "  ${C_RED}  ${SYM_ERR}  Homebrew installation failed or brew not found in PATH.${NC}"
            echo -e "  ${C_GRAY}  Try opening a new terminal and running brew_manager.sh again.${NC}"
            echo ""
            exit 1
        fi
    else
        echo ""
        echo -e "  ${C_GRAY}  Homebrew not installed — brew-manager cannot continue.${NC}"
        echo -e "  ${C_GRAY}  Install manually: https://brew.sh${NC}"
        echo ""
        exit 0
    fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# SOURCE ALL MODULES
# ─────────────────────────────────────────────────────────────────────────────

for _mod_file in "$SCRIPT_DIR/modules"/mod_*.sh; do
    source "$_mod_file" || { echo "ERROR: failed to source $_mod_file"; exit 1; }
done

# ─────────────────────────────────────────────────────────────────────────────
# FULL SESSION LOG via script(1)
# Re-launches itself inside script(1) to capture all terminal output.
# On second run BREW_MANAGER_RECORDING=1 is set — skip re-launch.
# ─────────────────────────────────────────────────────────────────────────────

if [[ -z "$BREW_MANAGER_RECORDING" ]]; then
    export BREW_MANAGER_RECORDING=1
    export BREW_MANAGER_VERSION
    script -q "$LOG_FILE" zsh "$SCRIPT_DIR/brew_manager.sh" "$@"
    # Capture the child's status BEFORE the ANSI strip: script(1) propagates
    # it, but sed/mv would overwrite $? — and automation (launchd agents,
    # shell scripts) reads THIS process's exit code, not the child's.
    _run_rc=$?
    # Strip ANSI escape codes and carriage returns from the saved log. A failed
    # strip must not replace the run's rc (the contract with callers) — but it
    # must not be silent either: say why the log was left raw.
    _tmp="$(mktemp)"
    sed $'s/\x1b\[[0-9;?]*[a-zA-Z]//g; s/\x1b[()][AB012]//g; s/\x1b[DMEH]//g; s/\r//g; s/^[[:space:]]*$//g' \
        "$LOG_FILE" > "$_tmp" && mv "$_tmp" "$LOG_FILE" || {
        echo "WARNING: log cleanup failed — raw log kept at $LOG_FILE" >&2
        rm -f "$_tmp"
    }
    exit $_run_rc
fi

_clear

# ── Banner (BM-11, flat variant approved 2026-07-20): brand + version on the
# left, host context right-aligned, over one full-width rule, then the session
# log path. The beer glyph and the middle-dot separator are Unicode-gated so a
# C-locale terminal gets clean ASCII instead of mojibake bytes; _tui_dot is
# reused by the menu footer below.
if (( TUI_UNICODE )); then _tui_glyph="🍺  "; _tui_dot=" · "; else _tui_glyph=""; _tui_dot=" - "; fi
_bm_left="${_tui_glyph}brew-manager v${BREW_MANAGER_VERSION}"
_bm_right="macOS${_tui_dot}zsh${_tui_dot}$(date '+%a %b %d %Y %H:%M')"
# ${#} counts characters, but the beer glyph occupies TWO terminal columns —
# subtract one extra so the right edge lands exactly on TERM_WIDTH.
_bm_pad=$(( TERM_WIDTH - 2 - ${#_bm_left} - ${#_bm_right} ))
(( TUI_UNICODE )) && (( _bm_pad -= 1 ))
(( _bm_pad < 2 )) && _bm_pad=2
echo ""
printf '  %b%s%b%*s%b%s%b\n' "$C_BRAND" "$_bm_left" "$NC" "$_bm_pad" "" "$C_INFO" "$_bm_right" "$NC"
_hline "─" "$C_GRAY"
# Home shortened to ~ so the usual log path fits an 80-column line (display
# only — $LOG_FILE itself stays absolute for script(1) and the log manager).
printf '  %bSession log: %s%b\n' "$C_INFO" "${LOG_FILE/#$HOME/~}" "$NC"

# The module registry (MODULE_DESC / MODULE_NAME / MODULE_IDS) lives in
# lib/selection.sh, sourced above — the menu, dispatcher and summary read it.

# ─────────────────────────────────────────────────────────────────────────────
# MODULE SELECTION — command line (non-interactive) OR interactive menu
# ─────────────────────────────────────────────────────────────────────────────

if (( CLI_SELECTION )); then
    # Non-interactive: the selection came from the command line. _resolve_cli is
    # STRICT — an unknown token aborts (exit 2) instead of being silently
    # skipped, so a typo never runs a different set of modules than intended.
    # DRY_RUN / YES_MODE are already applied from the flags above.
    _resolve_cli "$SELECTION_SPEC" "$ONLY_ANSWER" "$SKIP_ANSWER"
    _sel_rc=$?
    if (( _sel_rc == 2 )); then
        _err "Unknown module token(s): ${RESOLVE_INVALID[*]}"
        _err "Valid modules: 0-13, log, bk, las, mas. Base 'go' runs the full sequence."
        exit 2
    fi
    if (( ${#MODULES_TO_RUN[@]} == 0 )); then
        _err "The selection resolved to no modules. Exiting."
        exit 1
    fi
else
# ── Interactive menu (BM-11 redesign — flat cards + 3-line footer, approved
#    2026-07-20). Left un-indented so the diff shows the new control flow,
#    not a wholesale re-indent; the branch ends at the matching 'fi' below. ──

# _menu_section <title> <hint> — section heading with the hint right-aligned.
# ${#} matches visible width for both arguments: they are ASCII except SYM_ARR,
# whose char count equals its column count in both charsets (→ 1/1, -> 2/2).
_menu_section() {
    local _pad=$(( TERM_WIDTH - 2 - ${#1} - ${#2} ))
    (( _pad < 2 )) && _pad=2
    printf '  %b%s%b%*s%b%s%b\n' "$C_HEADING" "$1" "$NC" "$_pad" "" "$C_INFO" "$2" "$NC"
}

# _menu_row <id> — one aligned card row: badge(4) · id(3, right-aligned) ·
# name(17) · description. That is 32 columns before the description; with the
# 46-column description cap (pinned by tests/test_menu_registry.zsh) a row is
# at most 78 columns — stable on an 80-column terminal (roadmap §4.4). The
# badge keeps a constant 4-column width (BM-10), so colour on/off never moves
# the columns. Registry values go through printf %s fields, never echo -e
# (IMP-003: no echo on data).
_menu_row() {
    printf '  %s  %b%3s%b  %b%-17s%b  %b%s%b\n' \
        "$(_risk_badge "${MODULE_RISK[$1]}")" \
        "$C_CYAN_B" "$1" "$NC" \
        "$C_WHITE" "${MODULE_NAME[$1]}" "$NC" \
        "$C_GRAY" "${MODULE_DESC[$1]}" "$NC"
}

echo ""
_menu_section "AUDIT & MAINTENANCE" "go = run the full sequence 0${SYM_ARR}13"
echo ""
for mid in "${MODULE_IDS[@]}"; do
    _menu_row "$mid"
done
echo ""
_hline "─" "$C_GRAY"
echo ""
# The named tools live below their own rule: they are selected by NAME and
# never run as part of the 'go' sequence — the visual split mirrors the
# MODULE_IDS vs named-modules split in the registry.
_menu_section "TOOLS" "select by name"
echo ""
for tid in log bk las mas; do
    _menu_row "$tid"
done
echo ""
_hline "─" "$C_GRAY"
# Footer — 3 lines by design decision (2026-07-20): risk legend, input and
# flag examples, interrupt note. The full CLI reference lives in the README.
printf '  %bRisk%b   %s %bread-only%b   %s %bwrites cache/metadata%b   %s %bchanges your system%b\n' \
    "$C_INFO" "$NC" "$(_risk_badge ro)"     "$C_INFO" "$NC" \
                    "$(_risk_badge write)"  "$C_INFO" "$NC" \
                    "$(_risk_badge danger)" "$C_INFO" "$NC"
printf '  %bInput  go%s0,1,5%sgo --skip=5,10%sbk        Flags  --dry-run%s--yes%b\n' \
    "$C_INFO" "$_tui_dot" "$_tui_dot" "$_tui_dot" "$_tui_dot" "$NC"
printf '  %bCtrl+C exits at any time; the session log is always saved%b\n' "$C_INFO" "$NC"
echo ""
printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[go / numbers / name, default: go]${NC}: "
read -r module_choice

# ─────────────────────────────────────────────────────────────────────────────
# PARSE SELECTION
# ─────────────────────────────────────────────────────────────────────────────

# The parser lives in lib/selection.sh (_resolve_selection): it populates the
# MODULES_TO_RUN array and returns non-zero when the selection is empty. The
# empty-is-fatal policy stays here — the interactive session must not proceed
# with nothing to run.
_resolve_selection "$module_choice"

if (( ${#MODULES_TO_RUN[@]} == 0 )); then
    _err "No valid module selected. Exiting."
    exit 1
fi
fi  # end MODULE SELECTION (CLI vs interactive)

echo ""
echo -e "  ${C_GREEN_B}${SYM_OK}${NC}  Running modules: ${C_CYAN_B}${MODULES_TO_RUN[*]}${NC}"
if (( DRY_RUN )); then
    echo ""
    echo -e "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}DRY-RUN mode — no changes will be made to your system${NC}"
fi
if (( YES_MODE )); then
    echo ""
    echo -e "  ${C_CYAN}${SYM_INFO}${NC}  ${C_GRAY}Non-interactive mode (--yes) — all prompts use built-in defaults${NC}"
elif (( NON_INTERACTIVE )); then
    echo ""
    echo -e "  ${C_CYAN}${SYM_INFO}${NC}  ${C_GRAY}Non-interactive, no --yes — every prompt is declined, nothing is modified${NC}"
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# SHARED STATE (populated by modules, read by summary)
# ─────────────────────────────────────────────────────────────────────────────

CASK_COUNT=0
FORMULA_COUNT=0
OUTDATED_COUNT=0
DU_AFTER="n/a"
typeset -a UNMANAGED_WITH_CASK=()
typeset -a UNMANAGED_NO_CASK=()
typeset -a UNMANAGED_APPLE=()

# ─────────────────────────────────────────────────────────────────────────────
# DISPATCH
# ─────────────────────────────────────────────────────────────────────────────

for _mod in "${MODULES_TO_RUN[@]}"; do
    case "$_mod" in
        log) _module_log  ;;
        bk)  _module_14   ;;
        las) _module_15   ;;
        mas) _module_16   ;;
        *)   "_module_${_mod}" ;;
    esac
done

# ─────────────────────────────────────────────────────────────────────────────
# FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

echo ""
_hline "═" "$C_CYAN"
echo -e "${C_CYAN_B}  SUMMARY${NC}"
_hline "═" "$C_CYAN"
echo ""

echo -e "  ${C_CYAN_B}Modules executed:${NC}"
echo ""
for _m in "${MODULES_TO_RUN[@]}"; do
    printf "  ${C_GRAY}  ${SYM_ARR}${NC}  ${C_CYAN_B}%3s${NC}  ${C_WHITE}%-17s${NC}  ${C_GRAY}%s${NC}\n" \
        "$_m" "${MODULE_NAME[$_m]}" "${MODULE_DESC[$_m]}"
done
echo ""
_hline "·" "$C_GRAY"
echo ""

_stat_row "Installed casks"             "$CASK_COUNT"                   "$C_CYAN_B"
_stat_row "Installed formulae"          "$FORMULA_COUNT"                "$C_YELLOW"
_stat_row "Apps adoptable via --adopt"  "${#UNMANAGED_WITH_CASK[@]}"    "$C_YELLOW"
_stat_row "Apps without brew cask"      "${#UNMANAGED_NO_CASK[@]}"      "$C_GRAY"
_stat_row "Available updates"           "${OUTDATED_COUNT}"             "${OUTDATED_COUNT:+$C_YELLOW}"
_stat_row "Homebrew cache"              "$DU_AFTER"                     "$C_GREEN_B"
_stat_row "Homebrew prefix"             "$(brew --prefix)"              "$C_GRAY"
_stat_row "Total time"                  "${SECONDS}s"                   "$C_GRAY"

echo ""
_hline "═" "$C_CYAN"
printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%s${NC}\n" "BREW MANAGER" "$(date '+%a %d %b %Y %H:%M:%S %Z')"
printf "  ${C_GRAY}%-26s${NC}  ${C_WHITE}%s${NC}\n"   "Host"         "$(hostname)"
printf "  ${C_GRAY}%-26s${NC}  ${C_WHITE}%s${NC}\n"   "User"         "$(whoami)"
printf "  ${C_GRAY}%-26s${NC}  ${C_WHITE}%s${NC}\n"   "macOS"        "$(sw_vers -productVersion 2>/dev/null)"
printf "  ${C_GRAY}%-26s${NC}  ${C_WHITE}%s${NC}\n"   "Arch"         "$(uname -m)"
printf "  ${C_GRAY}%-26s${NC}  ${C_WHITE}%s${NC}\n"   "Log"          "$LOG_FILE"
_hline "═" "$C_CYAN"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# LOG MANAGEMENT (lib/log.sh)
# ─────────────────────────────────────────────────────────────────────────────

_handle_log "$LOG_FILE"

# ─────────────────────────────────────────────────────────────────────────────
# CLEANUP TEMP FILES
# ─────────────────────────────────────────────────────────────────────────────

rm -f /tmp/brew_doctor.log /tmp/brew_update.log /tmp/brew_cleanup.log \
      /tmp/brew_adopt_err.log /tmp/brew_audit.log

exit 0