#!/bin/zsh
# =============================================================================
# modules/mod_07_services.sh — Homebrew services
# =============================================================================

_module_7() {
    _section "7" "Homebrew Services"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    _about_risk "7"
    echo ""
    echo -e "  ${C_GRAY}Shows all Homebrew-managed background services (daemons) and their${NC}"
    echo -e "  ${C_GRAY}current status. Services are LaunchAgents/LaunchDaemons installed by${NC}"
    echo -e "  ${C_GRAY}formulae like postgresql, redis, nginx, mysql.${NC}"
    echo ""
    printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_GRAY}%-10s${NC}  %s\n" "started"   "Service is running and will restart at login"
    printf "  ${C_GRAY}${SYM_DOT}${NC}  ${C_GRAY}%-10s${NC}  %s\n" "stopped"   "Service is installed but not currently running"
    printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_GRAY}%-10s${NC}  %s\n" "other"     "Error state — check brew services for details"
    _hline "·" "$C_GRAY"
    services_raw=$(brew services list 2>/dev/null)
    if [[ -z "$services_raw" ]] || echo "$services_raw" | grep -q "No services"; then
        _info "No Homebrew services configured"
    else
        echo ""
        echo "$services_raw" | tail -n +2 | while IFS= read -r line; do
            if echo "$line" | grep -q "started"; then
                printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_WHITE}%s${NC}\n" "$line"
            elif echo "$line" | grep -q "stopped"; then
                printf "  ${C_GRAY}${SYM_DOT}${NC}  ${C_GRAY}%s${NC}\n" "$line"
            else
                printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%s${NC}\n" "$line"
            fi
        done
    fi
}
