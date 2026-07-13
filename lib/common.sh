#!/bin/zsh
# =============================================================================
# lib/common.sh — Shared colors, symbols and TUI utilities
# Sourced by brew_manager.sh and all modules
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# COLORS & SYMBOLS
# ─────────────────────────────────────────────────────────────────────────────

NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

C_WHITE='\033[1;37m'
C_CYAN='\033[0;36m'
C_CYAN_B='\033[1;36m'
C_GREEN='\033[0;32m'
C_GREEN_B='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_BLUE='\033[0;34m'
C_PURPLE='\033[0;35m'
C_PURPLE_B='\033[1;35m'
C_GRAY='\033[0;90m'
C_ORANGE='\033[0;33m'

SYM_OK="✓"
SYM_WARN="⚠"
SYM_ERR="✗"
SYM_INFO="›"
SYM_DOT="•"
SYM_ARR="→"
SYM_PKG="⬡"
SYM_APP="⬢"
SYM_LOCK="◈"
SYM_STAR="★"

# ─────────────────────────────────────────────────────────────────────────────
# TERMINAL WIDTH
# ─────────────────────────────────────────────────────────────────────────────

# Strip any non-numeric chars — tput cols can return garbage inside script(1)
TERM_WIDTH=$(tput cols 2>/dev/null | tr -cd '[:digit:]')
[[ "$TERM_WIDTH" =~ ^[0-9]+$ ]] || TERM_WIDTH=80
(( TERM_WIDTH < 60 )) && TERM_WIDTH=60
(( TERM_WIDTH > 100 )) && TERM_WIDTH=100

# ─────────────────────────────────────────────────────────────────────────────
# TUI UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

_hline() {
    local char="${1:-─}" color="${2:-$C_GRAY}" line=""
    for (( i=0; i<TERM_WIDTH; i++ )); do line+="$char"; done
    echo -e "${color}${line}${NC}"
}

_header_main() {
    local title="$1" subtitle="$2" subline="$3"
    echo ""
    _hline "═" "$C_CYAN"
    printf "${C_CYAN_B}  %-$((TERM_WIDTH-4))s  ${NC}\n" ""
    printf "${C_CYAN_B}  %-$((TERM_WIDTH-4))s  ${NC}\n" "$title"
    [[ -n "$subtitle" ]]  && printf "${C_CYAN}  %-$((TERM_WIDTH-4))s  ${NC}\n" "$subtitle"
    [[ -n "$subline" ]]   && printf "${C_GRAY}  %-$((TERM_WIDTH-4))s  ${NC}\n" "$subline"
    printf "${C_CYAN_B}  %-$((TERM_WIDTH-4))s  ${NC}\n" ""
    _hline "═" "$C_CYAN"
    echo ""
}

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

_spinner() {
    local pid=$1 msg="$2"
    if [[ -n "$BREW_MANAGER_RECORDING" ]]; then
        wait "$pid" 2>/dev/null
        return
    fi
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${C_CYAN}${frames[$((i % ${#frames[@]}))]}${NC}  ${msg}..."
        (( i++ ))
        sleep 0.1
    done
    printf "\r%-${TERM_WIDTH}s\r" " "
}

_ask() {
    local question="$1"
    local default="${2:-n}"  # second arg sets default: y or n
    # Non-interactive / --yes mode: use default without prompting
    if (( BREW_MANAGER_YES )); then
        echo -e "\n  ${C_CYAN_B}?${NC}  ${C_WHITE}${question}${NC} ${C_GRAY}[auto: ${default}]${NC}"
        [[ "$default" == "y" ]] && return 0 || return 1
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
    # Non-interactive: use default
    if (( BREW_MANAGER_YES )); then
        echo -e "  ${C_CYAN}${SYM_ARR}${NC}  ${prompt} ${C_GRAY}[auto: ${default}]${NC}" >&2
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