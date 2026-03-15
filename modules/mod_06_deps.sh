#!/bin/zsh
# =============================================================================
# modules/mod_06_deps.sh — Shared dependency analysis
# =============================================================================

_module_6() {
    _section "6" "Most Shared Dependencies"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Analyzes which formulae are depended upon by the most other installed${NC}"
    echo -e "  ${C_GRAY}packages. Useful for understanding the core of your dependency graph${NC}"
    echo -e "  ${C_GRAY}before removing or changing shared libraries.${NC}"
    echo ""
    echo -e "  ${C_GRAY}Bars are normalized to the actual maximum count — the longest bar always${NC}"
    echo -e "  ${C_GRAY}represents the most-shared formula, others are proportional to it.${NC}"
    _hline "·" "$C_GRAY"
    _info "Computing shared dependencies among installed formulae"
    echo ""

    # Collect top 10 into an array first so we know the max for normalization
    declare -a dep_data=()
    local max_count=1
    while read -r count formula; do
        (( count > 1 )) || continue
        dep_data+=("$count|$formula")
        (( count > max_count )) && max_count=$count
    done < <(brew list --formula | xargs -I {} brew uses --installed {} 2>/dev/null         | sort | uniq -c | sort -nr | head -10)

    if (( ${#dep_data[@]} == 0 )); then
        _info "No shared dependencies found"
        return
    fi

    # Print with bar normalized on actual max (30 chars = max_count)
    local bar_max=30
    for entry in "${dep_data[@]}"; do
        local count="${entry%%|*}"
        local formula="${entry##*|}"
        local bar="" bar_len=$(( count * bar_max / max_count ))
        (( bar_len < 1 )) && bar_len=1
        for (( i=0; i<bar_len; i++ )); do bar+="█"; done
        printf "  ${C_CYAN}%-20s${NC} ${C_CYAN_B}%-4d${NC} ${C_GRAY}%s${NC}\n" "$formula" "$count" "$bar"
    done
}