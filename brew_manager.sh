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

# Auto-detect non-interactive (running as LaunchAgent or piped)
if [[ ! -t 0 ]]; then
    YES_MODE=1
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
export BREW_MANAGER_YES=$YES_MODE
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
    clear
    echo ""
    echo -e "\033[1;36m  🍺  BREW MANAGER\033[0m"
    echo ""
    echo -e "\033[0;31m  ✗  Homebrew is not installed on this system.\033[0m"
    echo ""
    echo -e "\033[0;90m  Homebrew is required for brew-manager to work.\033[0m"
    echo -e "\033[0;90m  It is the macOS package manager that this tool is built around.\033[0m"
    echo ""
    echo -e "\033[1;37m  Install Homebrew now?\033[0m \033[0;90m(y/N)\033[0m"
    echo ""
    printf "  \033[0;36m→\033[0m  Choice: "
    read -r _brew_install_choice

    if [[ "$_brew_install_choice" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "  \033[0;36m›\033[0m  Installing Homebrew..."
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
            echo -e "  \033[1;32m  ✓  Homebrew installed successfully — launching brew-manager...\033[0m"
            sleep 1
            # Re-exec the script now that brew is available
            exec zsh "$0" "$@"
        else
            echo ""
            echo -e "  \033[0;31m  ✗  Homebrew installation failed or brew not found in PATH.\033[0m"
            echo -e "  \033[0;90m  Try opening a new terminal and running brew_manager.sh again.\033[0m"
            echo ""
            exit 1
        fi
    else
        echo ""
        echo -e "  \033[0;90m  Homebrew not installed — brew-manager cannot continue.\033[0m"
        echo -e "  \033[0;90m  Install manually: https://brew.sh\033[0m"
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
    # Strip ANSI escape codes and carriage returns from the saved log
    _tmp="$(mktemp)"
    sed $'s/\x1b\[[0-9;?]*[a-zA-Z]//g; s/\x1b[()][AB012]//g; s/\x1b[DMEH]//g; s/\r//g; s/^[[:space:]]*$//g' \
        "$LOG_FILE" > "$_tmp" && mv "$_tmp" "$LOG_FILE"
    exit $?
fi

clear

_header_main \
    "🍺  BREW MANAGER v${BREW_MANAGER_VERSION} — Audit, Cleanup & Unmanaged App Report" \
    "macOS · zsh · $(date '+%a %b %d %Y %H:%M') · Log: $LOG_FILE"

# The module registry (MODULE_DESC / MODULE_IDS) now lives in lib/selection.sh,
# sourced above — the menu, dispatcher and summary read it as before.

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
# ── Interactive menu. Left un-indented so the diff shows the new control flow,
#    not a wholesale re-indent; the branch ends at the matching 'fi' below. ──
echo -e "  ${C_GRAY}CLI usage:  ./brew_manager.sh [modules] [--only=ids] [--skip=ids] [options]${NC}"
echo -e "  ${C_GRAY}  go                   run all modules in sequence${NC}"
echo -e "  ${C_GRAY}  go --yes             run all modules, skip all prompts${NC}"
echo -e "  ${C_GRAY}  go --dry-run         read-only — no changes made${NC}"
echo -e "  ${C_GRAY}  0,4 --adopt=all      run modules 0 and 4, adopt all${NC}"
echo -e "  ${C_GRAY}  4 --upgrade=y        run module 4, upgrade without asking${NC}"
echo -e "  ${C_GRAY}  go --skip=5,10       run every module except 5 and 10${NC}"
echo -e "  ${C_GRAY}  log                  open log manager${NC}"
echo ""
echo -e "  ${C_CYAN_B}Available modules:${NC}"
echo ""
printf "  ${C_GRAY}%-6s  %-45s${NC}\n" "Module" "Description"
printf "  ${C_GRAY}%-6s  %-45s${NC}\n" "──────" "─────────────────────────────────────────────"
for mid in "${MODULE_IDS[@]}"; do
    if (( mid < 10 )); then
        printf "  ${C_CYAN_B}[%s]${NC}   ${C_WHITE}%-45s${NC}\n" "$mid" "${MODULE_DESC[$mid]}"
    else
        printf "  ${C_CYAN_B}[%s]${NC}  ${C_WHITE}%-45s${NC}\n" "$mid" "${MODULE_DESC[$mid]}"
    fi
done

_hline "·" "$C_GRAY"
printf "  ${C_YELLOW}[%s]${NC}   ${C_WHITE}%-45s${NC}\n" "log" "${MODULE_DESC[log]}"
printf "  ${C_YELLOW}[%s]${NC}   ${C_WHITE}%-45s${NC}\n" "bk " "${MODULE_DESC[bk]}"
printf "  ${C_YELLOW}[%s]${NC}   ${C_WHITE}%-45s${NC}\n" "las" "${MODULE_DESC[las]}"
printf "  ${C_YELLOW}[%s]${NC}   ${C_WHITE}%-45s${NC}\n" "mas" "${MODULE_DESC[mas]}"
echo ""
echo -e "  ${C_GRAY}Valid input examples:${NC}"
echo -e "  ${C_GRAY}  go           → runs all modules in sequence (0→13)${NC}"
echo -e "  ${C_GRAY}  0,1,5        → runs only modules 0, 1 and 5 in this order${NC}"
echo -e "  ${C_GRAY}  5,2,0        → runs 5, then 2, then 0 (free order)${NC}"
echo -e "  ${C_GRAY}  1,1,2,1      → modules can be repeated freely${NC}"
echo -e "  ${C_GRAY}  log          → open log manager (never runs with go)${NC}"
echo -e "  ${C_GRAY}  bk           → Brewfile backup/restore${NC}"
echo -e "  ${C_GRAY}  las          → LaunchAgent scheduler${NC}"
echo -e "  ${C_GRAY}  mas          → Mac App Store integration${NC}"
echo ""
echo -e "  ${C_GRAY}Note: pressing Ctrl+C at any time exits the session. The log is always${NC}"
echo -e "  ${C_GRAY}saved automatically — even if the run was interrupted.${NC}"
echo ""
printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[go / comma-separated numbers, default: go]${NC}: "
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
    echo -e "  ${C_CYAN}${SYM_INFO}${NC}  ${C_GRAY}Non-interactive mode — all prompts use built-in defaults${NC}"
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
    printf "  ${C_GRAY}  ${SYM_ARR}${NC}  ${C_CYAN_B}%2s${NC}  ${C_WHITE}%s${NC}\n" "$_m" "${MODULE_DESC[$_m]}"
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