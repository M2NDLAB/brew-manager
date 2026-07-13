#!/bin/zsh
# =============================================================================
# brew_manager.sh — Homebrew Audit, Cleanup & Unmanaged App Report
# Compatible: macOS + zsh (tested on Apple Silicon M-series)
# Developed by M2NDLAB — https://github.com/M2NDLAB/brew-manager
#
# Structure:
#   brew_manager.sh       ← this file (entry point, menu, dispatch, summary)
#   lib/common.sh         ← colors, symbols, TUI utilities
#   lib/log.sh            ← session log management
#   modules/mod_NN_*.sh   ← one file per module
# =============================================================================

BREW_MANAGER_VERSION="1.1.0"

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

# Parse flags and module options from CLI args
# Usage: ./brew_manager.sh [go|modules] [--dry-run] [--yes] [--adopt=n|all|1,2] [--upgrade=y|n]
DRY_RUN=0
YES_MODE=0       # --yes: skip all prompts using built-in defaults
ADOPT_ANSWER=""  # --adopt=n|all|1,2,3
UPGRADE_ANSWER="" # --upgrade=y|n

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
        -*|–*|—*|−*)
            # A mistyped flag must never run with defaults silently:
            # --dryrun would execute the REAL cleanup believing it is a dry-run.
            # Unicode dash lookalikes (en/em dash, minus) come from smart-dash
            # copy-paste and would otherwise slip through as positionals
            echo "ERROR: unknown flag: ${_arg}" >&2
            echo "Accepted flags: --dry-run, --yes | -y, --adopt=n|all|1,2, --upgrade=y|n" >&2
            exit 2
            ;;
        # Non-flag args (e.g. module lists from LaunchAgent plists) are still
        # ignored here: positional selection is a separate, planned feature
    esac
done

export BREW_MANAGER_DRY_RUN=$DRY_RUN
export BREW_MANAGER_YES=$YES_MODE
export BREW_MANAGER_ADOPT="${ADOPT_ANSWER:-n}"
export BREW_MANAGER_UPGRADE="${UPGRADE_ANSWER:-n}"

# ─────────────────────────────────────────────────────────────────────────────
# SOURCE LIBRARY
# ─────────────────────────────────────────────────────────────────────────────

source "$SCRIPT_DIR/lib/common.sh" || { echo "ERROR: lib/common.sh not found"; exit 1; }
source "$SCRIPT_DIR/lib/log.sh"    || { echo "ERROR: lib/log.sh not found"; exit 1; }

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
    "🍺  BREW MANAGER — Audit, Cleanup & Unmanaged App Report" \
    "macOS · zsh · $(date '+%a %b %d %Y %H:%M') · Log: $LOG_FILE"

# ─────────────────────────────────────────────────────────────────────────────
# MODULE DEFINITIONS
# ─────────────────────────────────────────────────────────────────────────────

typeset -A MODULE_DESC=(
    [0]="Audit unmanaged apps (not in Homebrew)"
    [1]="Homebrew system health"
    [2]="Formula database update"
    [3]="Installed packages report"
    [4]="Available updates"
    [5]="Cache and orphan dependency cleanup"
    [6]="Shared dependency analysis"
    [7]="Homebrew services"
    [8]="Untracked binaries in /usr/local/bin"
    [9]="Brew-tracked binaries in /usr/local/bin"
    [10]="Auto-update casks (skipped by brew upgrade)"
    [11]="Duplicate and conflicting formulae"
    [12]="Security audit"
    [13]="Disk usage breakdown"
    [log]="Log file manager (not in go sequence)"
    [bk]="Brewfile backup and restore"
    [las]="LaunchAgent scheduler (auto-run)"
    [mas]="Mac App Store (MAS) integration"
)

MODULE_IDS=(0 1 2 3 4 5 6 7 8 9 10 11 12 13)

# ─────────────────────────────────────────────────────────────────────────────
# MODULE SELECTION MENU
# ─────────────────────────────────────────────────────────────────────────────

echo -e "  ${C_GRAY}CLI usage:  ./brew_manager.sh [modules] [options]${NC}"
echo -e "  ${C_GRAY}  go                   run all modules in sequence${NC}"
echo -e "  ${C_GRAY}  go --yes             run all modules, skip all prompts${NC}"
echo -e "  ${C_GRAY}  go --dry-run         read-only — no changes made${NC}"
echo -e "  ${C_GRAY}  0,4 --adopt=all      run modules 0 and 4, adopt all${NC}"
echo -e "  ${C_GRAY}  4 --upgrade=y        run module 4, upgrade without asking${NC}"
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

declare -a MODULES_TO_RUN=()
case "${module_choice:-go}" in
    log|LOG) MODULES_TO_RUN=("log") ;;
    bk|BK)   MODULES_TO_RUN=("bk")  ;;
    las|LAS) MODULES_TO_RUN=("las") ;;
    mas|MAS) MODULES_TO_RUN=("mas") ;;
    go|GO|"")
        MODULES_TO_RUN=(${MODULE_IDS[@]})
        ;;
    *)
        IFS=',' read -rA _raw_nums <<< "$module_choice"
        for _n in "${_raw_nums[@]}"; do
            _n=$(echo "$_n" | tr -d ' ')
            if [[ "$_n" =~ ^[0-9]+$ ]] && [[ -n "${MODULE_DESC[$_n]}" ]]; then
                MODULES_TO_RUN+=("$_n")
            elif [[ "$_n" == "log" || "$_n" == "bk" || "$_n" == "las" || "$_n" == "mas" ]]; then
                MODULES_TO_RUN+=("$_n")
            else
                _warn "Module '$_n' is invalid — skipped"
            fi
        done
        ;;
esac

if (( ${#MODULES_TO_RUN[@]} == 0 )); then
    _err "No valid module selected. Exiting."
    exit 1
fi

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