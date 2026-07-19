#!/bin/zsh
# =============================================================================
# lib/log.sh — Session log management
# Called at end of every brew_manager.sh run
# =============================================================================

_handle_log() {
    local log_file="$1"

    echo ""
    _hline "─" "$C_GRAY"
    echo -e "  ${C_CYAN_B}Log saved to:${NC} ${C_WHITE}${log_file}${NC}"
    echo ""
    echo -e "  ${C_WHITE}What do you want to do with the log?${NC}"
    echo ""
    printf "  ${C_GREEN}%-4s${C_WHITE}%-10s${NC}  ${C_GRAY}%s${NC}\n" "[1]" "Keep" "Save the log to $log_file"
    printf "  ${C_WHITE}%-4s${C_WHITE}%-10s${NC}  ${C_GRAY}%s${NC}\n" "[2]" "Open" "Log is saved — opens editor to view it"
    printf "  ${C_RED}%-4s${C_WHITE}%-10s${NC}  ${C_GRAY}%s${NC}\n" "[3]" "Delete" "Discard the log — session data lost"
    echo ""
    printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[1/2/3, default: 1]${NC}: "
    read -r log_choice

    case "${log_choice:-1}" in
        1) _ok "Log kept at: $log_file" ;;
        2) _info "Opening log"; open "$log_file"; _ok "Log opened" ;;
        3) rm -f "$log_file"; _ok "Log deleted" ;;
        *) _warn "Invalid choice — log kept for safety" ;;
    esac

    _hline "─" "$C_GRAY"
    echo ""

    # Footer — support / repo
    _hline "═" "$C_CYAN"
    printf "  ${C_CYAN}⌥${NC}  ${C_WHITE}%-18s${NC}  ${C_CYAN_B}%s${NC}\n"         "Support:" "M2NDLAB · https://github.com/M2NDLAB/brew-manager"
    _hline "═" "$C_CYAN"
    echo ""
}