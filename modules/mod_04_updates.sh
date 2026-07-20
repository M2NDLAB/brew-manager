#!/bin/zsh
# =============================================================================
# modules/mod_04_updates.sh — Available updates
# =============================================================================

_module_4() {
    _section "4" "Available Updates"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    _about_risk "4"
    echo ""
    echo -e "  ${C_GRAY}Checks every installed cask and formula against the latest available${NC}"
    echo -e "  ${C_GRAY}version using brew outdated. Outdated packages are highlighted in yellow.${NC}"
    echo ""
    echo -e "  ${C_GRAY}Before upgrading, shows a brew upgrade --dry-run preview so you can see${NC}"
    echo -e "  ${C_GRAY}exactly what will change before committing. Auto-update casks (marked [A]${NC}"
    echo -e "  ${C_GRAY}in module 3) are handled separately in module 10 via brew upgrade --greedy.${NC}"
    _hline "·" "$C_GRAY"

    outdated_raw=$(brew outdated --verbose 2>/dev/null)
    OUTDATED_COUNT=$(echo "$outdated_raw" | grep -c . 2>/dev/null || echo 0)
    [[ -z "$outdated_raw" ]] && OUTDATED_COUNT=0

    _all_pkgs=$(brew list --versions 2>/dev/null)

    echo ""
    printf "  ${C_GRAY}%-4s  %-28s  %-10s  %-14s${NC}\n" \
        "No." "Package" "Type" "Version"
    printf "  ${C_GRAY}%-4s  %-28s  %-10s  %-14s${NC}\n" \
        "────" "────────────────────────────" "──────────" "──────────────"

    _idx=1
    while IFS= read -r pkg; do
        _ver="$(brew list --versions --cask "$pkg" 2>/dev/null | awk '{print $2}')"
        _is_outdated=0
        echo "$outdated_raw" | grep -q "^$pkg " && _is_outdated=1
        if (( _is_outdated )); then
            _new_ver="$(echo "$outdated_raw" | grep "^$pkg " | awk '{print $NF}')"
            printf "  ${C_YELLOW}%-4s${NC}  ${C_YELLOW}%-28s${NC}  ${C_GRAY}%-10s${NC}  ${C_YELLOW}%-14s${NC}  ${C_YELLOW}→ %s${NC}\n" \
                "$_idx" "$pkg" "cask" "${_ver:-n/a}" "$_new_ver"
        else
            printf "  ${C_GREEN_B}${SYM_OK}${NC}   ${C_WHITE}%-28s${NC}  ${C_GRAY}%-10s${NC}  ${C_GRAY}%-14s${NC}\n" \
                "$pkg" "cask" "${_ver:-n/a}"
        fi
        (( _idx++ ))
    done < <(brew list --cask 2>/dev/null)

    while IFS= read -r pkg; do
        _ver="$(echo "$_all_pkgs" | grep "^$pkg " | awk '{print $2}')"
        _is_outdated=0
        echo "$outdated_raw" | grep -q "^$pkg " && _is_outdated=1
        if (( _is_outdated )); then
            _new_ver="$(echo "$outdated_raw" | grep "^$pkg " | awk '{print $NF}')"
            printf "  ${C_YELLOW}%-4s${NC}  ${C_YELLOW}%-28s${NC}  ${C_GRAY}%-10s${NC}  ${C_YELLOW}%-14s${NC}  ${C_YELLOW}→ %s${NC}\n" \
                "$_idx" "$pkg" "formula" "${_ver:-n/a}" "$_new_ver"
        else
            printf "  ${C_GREEN_B}${SYM_OK}${NC}   ${C_WHITE}%-28s${NC}  ${C_GRAY}%-10s${NC}  ${C_GRAY}%-14s${NC}\n" \
                "$pkg" "formula" "${_ver:-n/a}"
        fi
        (( _idx++ ))
    done < <(brew leaves 2>/dev/null)

    echo ""
    if (( OUTDATED_COUNT == 0 )); then
        _ok "All packages are up to date"
    else
        _warn "${OUTDATED_COUNT} updates available — packages in yellow have a new version"
        echo ""

        # Show dry-run preview of what would change
        _info "Preview of changes (brew upgrade --dry-run):"
        echo ""
        brew upgrade --dry-run 2>/dev/null | while IFS= read -r line; do
            [[ -n "$line" ]] && printf "  ${C_GRAY}  %s${NC}\n" "$line"
        done
        echo ""

        if (( BREW_MANAGER_DRY_RUN )); then
            _info "Dry-run mode — skipping actual upgrade"
        elif _ask "Proceed with upgrade now?" "${BREW_MANAGER_UPGRADE:-n}"; then
            echo ""
            _info "Updating packages"
            brew upgrade 2>&1 | while IFS= read -r line; do
                [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
            done
            _ok "Update completed"
        fi
    fi
}
