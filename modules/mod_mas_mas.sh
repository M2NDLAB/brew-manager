#!/bin/zsh
# =============================================================================
# modules/mod_mas_mas.sh — Mac App Store integration
# Requires: mas (brew install mas)
# Shows installed MAS apps, available updates, and integrates with Brewfile.
# =============================================================================

_module_16() {
    _section "16" "Mac App Store (MAS) Integration"

    # ── What this module does ──
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    _about_risk "mas"
    echo ""
    echo -e "  ${C_GRAY}mas (Mac App Store CLI) is an open-source command-line tool that lets${NC}"
    echo -e "  ${C_GRAY}you manage App Store apps from the terminal — the same apps you installed${NC}"
    echo -e "  ${C_GRAY}via the App Store GUI (Xcode, Amphetamine, etc.).${NC}"
    echo ""
    echo -e "  ${C_GRAY}This module can:${NC}"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-16s${NC}  %s\n" "List apps"    "Show all apps installed from the Mac App Store"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-16s${NC}  %s\n" "Check updates" "Find MAS apps with a newer version available"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-16s${NC}  %s\n" "Upgrade"      "Run mas upgrade to update all outdated MAS apps"
    echo ""
    echo -e "  ${C_GRAY}Requires: you must be signed into the App Store with your Apple ID.${NC}"
    echo -e "  ${C_GRAY}mas is separate from brew — it only talks to the App Store, not Homebrew.${NC}"
    _hline "·" "$C_GRAY"
    echo ""

    # ── Check if mas is installed ──
    if ! command -v mas &>/dev/null; then
        echo ""
        _warn "mas is not installed — required for Mac App Store management"
        echo ""
        printf "  ${C_GRAY}Install with:${NC}  ${C_CYAN}brew install mas${NC}\n"
        echo ""
        if _ask "Install mas now?"; then
            echo ""
            _info "Installing mas"
            brew install mas 2>&1 | while IFS= read -r line; do
                [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
            done
            if ! command -v mas &>/dev/null; then
                _err "Installation failed — skipping MAS module"
                return
            fi
            _ok "mas installed"
        else
            _info "Skipped — install mas to use this module"
            return
        fi
    fi

    local _mas_ver
    _mas_ver="$(mas version 2>/dev/null)"
    _ok "mas ${_mas_ver} detected"
    echo ""

    # ── Installed MAS apps ──
    echo -e "  ${C_CYAN_B}Installed Mac App Store apps:${NC}"
    echo ""

    local _installed_raw
    _installed_raw="$(mas list 2>/dev/null)"

    if [[ -z "$_installed_raw" ]]; then
        _info "No Mac App Store apps found (or not signed in to App Store)"
        echo ""
    else
        local _app_count
        _app_count=$(echo "$_installed_raw" | grep -c .)
        _stat_row "MAS apps installed" "$_app_count" "$C_GREEN_B"
        echo ""

        printf "  ${C_GRAY}%-12s  %-38s  %-10s${NC}\n" "App ID" "Name" "Version"
        printf "  ${C_GRAY}%-12s  %-38s  %-10s${NC}\n" "────────────" "──────────────────────────────────────" "──────────"
        while IFS= read -r line; do
            local _id="$(echo "$line" | awk '{print $1}')"
            local _ver="$(echo "$line" | awk '{print $NF}' | tr -d '()')"
            local _name="$(echo "$line" | awk '{$1=$NF=""; print $0}' | xargs)"
            printf "  ${C_GREEN}${SYM_APP}${NC}  ${C_GRAY}%-12s${NC}  ${C_WHITE}%-38s${NC}  ${C_GRAY}%s${NC}\n" \
                "$_id" "$_name" "$_ver"
        done <<< "$_installed_raw"
        echo ""
    fi

    # ── Available updates ──
    echo -e "  ${C_CYAN_B}Available MAS updates:${NC}"
    echo ""

    local _outdated_raw
    _outdated_raw="$(mas outdated 2>/dev/null)"

    if [[ -z "$_outdated_raw" ]]; then
        _ok "All Mac App Store apps are up to date"
    else
        local _outdated_count
        _outdated_count=$(echo "$_outdated_raw" | grep -c .)
        _warn "${_outdated_count} MAS update(s) available:"
        echo ""

        printf "  ${C_GRAY}%-12s  %-38s  %-10s${NC}\n" "App ID" "Name" "Version"
        printf "  ${C_GRAY}%-12s  %-38s  %-10s${NC}\n" "────────────" "──────────────────────────────────────" "──────────"
        while IFS= read -r line; do
            local _id="$(echo "$line" | awk '{print $1}')"
            local _ver="$(echo "$line" | awk '{print $NF}' | tr -d '()')"
            local _name="$(echo "$line" | awk '{$1=$NF=""; print $0}' | xargs)"
            printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-12s${NC}  ${C_YELLOW}%-38s${NC}  ${C_YELLOW}%s${NC}\n" \
                "$_id" "$_name" "$_ver"
        done <<< "$_outdated_raw"
        echo ""

        if (( BREW_MANAGER_DRY_RUN )); then
            _info "Dry-run mode — skipping upgrade"
        elif _ask "Update all MAS apps now?"; then
            echo ""
            _info "Running mas upgrade"
            mas upgrade 2>&1 | while IFS= read -r line; do
                [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
            done
            _ok "MAS upgrade completed"
        fi
    fi

    # ── Summary ──
    echo ""
    local _app_count_final=0
    [[ -n "$_installed_raw" ]] && _app_count_final=$(echo "$_installed_raw" | grep -c .)
    local _outdated_count_final=0
    [[ -n "$_outdated_raw" ]] && _outdated_count_final=$(echo "$_outdated_raw" | grep -c .)
    local _upd_color="$C_GREEN_B"
    (( _outdated_count_final > 0 )) && _upd_color="$C_YELLOW"

    _stat_row "MAS apps installed"  "$_app_count_final"      "$C_CYAN_B"
    _stat_row "Updates available"   "$_outdated_count_final" "$_upd_color"
    _stat_row "mas version"         "$_mas_ver"              "$C_GRAY"
}
