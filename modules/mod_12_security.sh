#!/bin/zsh
# =============================================================================
# modules/mod_12_security.sh — Security audit
# Checks: brew missing (broken deps), pinned formulae, non-HTTPS homepages,
# deprecated/disabled casks, and brew doctor warnings summary.
# =============================================================================

_module_12() {
    _section "12" "Security Audit"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Runs security-focused checks on your Homebrew installation:${NC}"
    echo ""
    printf "  ${C_RED}${SYM_ERR}${NC}  ${C_GRAY}%-26s${NC}  %s\n" "brew missing"           "Broken dependencies — packages that reference missing formulae"
    printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_GRAY}%-26s${NC}  %s\n" "Non-HTTPS homepages"    "Formulae whose upstream URL uses plain HTTP (no encryption)"
    printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_GRAY}%-26s${NC}  %s\n" "Pinned formulae"        "Packages frozen at an old version — won't receive security fixes"
    printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_GRAY}%-26s${NC}  %s\n" "Deprecated casks"       "Casks flagged by Homebrew as unsafe or unmaintained"
    echo ""
    echo -e "  ${C_GRAY}brew missing is fast and directly actionable — it tells you exactly${NC}"
    echo -e "  ${C_GRAY}which formula to reinstall to fix a broken dependency.${NC}"
    _hline "·" "$C_GRAY"

    # ── brew missing: broken/missing dependencies (fast, actionable) ──
    _info "Checking for missing or broken dependencies"
    _missing_raw="$(brew missing 2>/dev/null)"
    echo ""
    if [[ -z "$_missing_raw" ]]; then
        _ok "No missing or broken dependencies"
    else
        _warn "Missing dependencies detected — run \'brew install\' for each:"
        echo ""
        echo "$_missing_raw" | while IFS= read -r line; do
            echo -e "  ${C_RED}  ${line}${NC}"
        done
    fi

    # ── Packages without HTTPS homepage ──
    echo ""
    echo -e "  ${C_CYAN_B}Formulae with non-HTTPS homepage:${NC}"
    echo ""
    declare -a no_https=()
    while IFS= read -r formula; do
        local _hp="$(brew info "$formula" 2>/dev/null | grep -m1 "^https\?://" | xargs)"
        if [[ "$_hp" == http://* ]]; then
            no_https+=("$formula|$_hp")
        fi
    done < <(brew list --formula 2>/dev/null)

    if (( ${#no_https[@]} > 0 )); then
        printf "  ${C_GRAY}%-22s  %-40s${NC}\n" "Formula" "Homepage"
        printf "  ${C_GRAY}%-22s  %-40s${NC}\n" "──────────────────────" "────────────────────────────────────────"
        for entry in "${no_https[@]}"; do
            printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_WHITE}%-22s${NC}  ${C_GRAY}%s${NC}\n" "${entry%%|*}" "${entry##*|}"
        done
    else
        _ok "All formula homepages use HTTPS"
    fi

    # ── Pinned formulae ──
    echo ""
    echo -e "  ${C_CYAN_B}Pinned formulae (blocked from upgrades):${NC}"
    echo ""
    _pinned="$(brew list --pinned 2>/dev/null)"
    if [[ -z "$_pinned" ]]; then
        _ok "No pinned formulae"
    else
        echo "$_pinned" | while IFS= read -r f; do
            printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_WHITE}%s${NC}  ${C_GRAY}(pinned — will not receive security updates)${NC}\n" "$f"
        done
    fi

    # ── Deprecated/disabled casks ──
    echo ""
    echo -e "  ${C_CYAN_B}Deprecated or disabled casks:${NC}"
    echo ""
    declare -a dep_casks=()
    while IFS= read -r cask; do
        local _ci="$(brew info --cask "$cask" 2>/dev/null)"
        if echo "$_ci" | grep -qE "^This cask (is deprecated|has been disabled)"; then
            local _cs="$(echo "$_ci" | grep -oE "deprecated|disabled" | head -1)"
            dep_casks+=("$cask|$_cs")
        fi
    done < <(brew list --cask 2>/dev/null)

    if (( ${#dep_casks[@]} > 0 )); then
        printf "  ${C_GRAY}%-28s  %-12s${NC}\n" "Cask" "Status"
        printf "  ${C_GRAY}%-28s  %-12s${NC}\n" "────────────────────────────" "────────────"
        for entry in "${dep_casks[@]}"; do
            local _cn="${entry%%|*}" _cs="${entry##*|}"
            local _cc="$C_YELLOW"
            [[ "$_cs" == "disabled" ]] && _cc="$C_RED"
            printf "  ${_cc}${SYM_WARN}${NC}  ${C_WHITE}%-28s${NC}  ${_cc}%s${NC}\n" "$_cn" "$_cs"
        done
    else
        _ok "No deprecated or disabled casks"
    fi

    # ── Summary ──
    echo ""
    local _missing_count=0
    [[ -n "$_missing_raw" ]] && _missing_count=$(echo "$_missing_raw" | grep -c .)
    local _missing_color="$C_GREEN_B"
    (( _missing_count > 0 )) && _missing_color="$C_RED"
    local _pinned_count=0
    [[ -n "$_pinned" ]] && _pinned_count=$(echo "$_pinned" | grep -c .)
    local _pinned_color="$C_GREEN_B"
    (( _pinned_count > 0 )) && _pinned_color="$C_RED"

    _stat_row "Missing/broken dependencies"  "$_missing_count"       "$_missing_color"
    _stat_row "Non-HTTPS homepages"          "${#no_https[@]}"       "$C_YELLOW"
    _stat_row "Pinned (upgrade-blocked)"     "$_pinned_count"        "$_pinned_color"
    _stat_row "Deprecated/disabled casks"   "${#dep_casks[@]}"      "$C_YELLOW"
}