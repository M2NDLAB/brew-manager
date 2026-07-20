#!/bin/zsh
# =============================================================================
# modules/mod_11_conflicts.sh — Duplicate and conflicting formulae
# Finds: multiple versions of the same formula, keg-only conflicts,
# and formulae that provide overlapping binaries.
# =============================================================================

_module_11() {
    _section "11" "Duplicate and Conflicting Formulae"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    _about_risk "11"
    echo ""
    echo -e "  ${C_GRAY}Detects three categories of potential conflicts in your install:${NC}"
    echo ""
    printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Version duplicates"    "e.g. openjdk and openjdk@21 both installed"
    printf "  ${C_BLUE}${SYM_INFO}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Keg-only formulae"    "Installed but not linked — may shadow system tools if forced"
    printf "  ${C_RED}${SYM_WARN}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Deprecated casks"      "Casks marked deprecated or disabled by Homebrew maintainers"
    echo ""
    echo -e "  ${C_GRAY}Keg-only formulae are intentionally not linked to avoid conflicts with${NC}"
    echo -e "  ${C_GRAY}macOS-bundled versions (e.g. sqlite, readline, openssl).${NC}"
    _hline "·" "$C_GRAY"
    _info "Scanning for version duplicates and keg-only conflicts"
    echo ""

    # ── Multiple versions installed (e.g. openjdk + openjdk@21) ──
    declare -a multi_version=()
    declare -A base_names=()

    while IFS= read -r formula; do
        # Strip @version suffix to get base name
        local base="${formula%%@*}"
        if [[ -n "${base_names[$base]}" ]]; then
            multi_version+=("${base_names[$base]}|$formula")
        else
            base_names[$base]="$formula"
        fi
    done < <(brew list --formula 2>/dev/null | sort)

    if (( ${#multi_version[@]} > 0 )); then
        echo -e "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_WHITE}Multiple versions of the same formula:${NC}"
        echo ""
        printf "  ${C_GRAY}%-28s  %-28s${NC}\n" "Version A" "Version B"
        printf "  ${C_GRAY}%-28s  %-28s${NC}\n" "────────────────────────────" "────────────────────────────"
        for pair in "${multi_version[@]}"; do
            local va="${pair%%|*}"
            local vb="${pair##*|}"
            printf "  ${C_YELLOW}${SYM_DOT}${NC}  ${C_WHITE}%-28s${NC}  ${C_YELLOW}%-28s${NC}\n" "$va" "$vb"
        done
        echo ""
    else
        _ok "No duplicate formula versions found"
    fi

    # ── Keg-only formulae that shadow system tools ──
    echo ""
    echo -e "  ${C_CYAN_B}Keg-only formulae (not linked, may shadow system tools):${NC}"
    echo ""

    declare -a keg_only=()
    while IFS= read -r formula; do
        local _finfo="$(brew info "$formula" 2>/dev/null)"
        if echo "$_finfo" | grep -q "keg-only"; then
            local _reason="$(echo "$_finfo" | grep -A1 "keg-only" | tail -1 | xargs)"
            keg_only+=("$formula|$_reason")
        fi
    done < <(brew list --formula 2>/dev/null)

    if (( ${#keg_only[@]} > 0 )); then
        printf "  ${C_GRAY}%-22s  %-40s${NC}\n" "Formula" "Reason"
        printf "  ${C_GRAY}%-22s  %-40s${NC}\n" "──────────────────────" "────────────────────────────────────────"
        for entry in "${keg_only[@]}"; do
            local fname="${entry%%|*}"
            local reason="${entry##*|}"
            printf "  ${C_BLUE}${SYM_INFO}${NC}  ${C_WHITE}%-22s${NC}  ${C_GRAY}%s${NC}\n" "$fname" "$reason"
        done
    else
        _ok "No keg-only formulae installed"
    fi

    # ── Deprecated or disabled casks ──
    echo ""
    echo -e "  ${C_CYAN_B}Deprecated or disabled casks:${NC}"
    echo ""

    declare -a deprecated_casks=()
    while IFS= read -r cask; do
        local _cinfo="$(brew info --cask "$cask" 2>/dev/null)"
        if echo "$_cinfo" | grep -qE "deprecated|disabled"; then
            local _cstatus="$(echo "$_cinfo" | grep -oE "deprecated|disabled" | head -1)"
            deprecated_casks+=("$cask|$_cstatus")
        fi
    done < <(brew list --cask 2>/dev/null)

    if (( ${#deprecated_casks[@]} > 0 )); then
        printf "  ${C_GRAY}%-28s  %-12s${NC}\n" "Cask" "Status"
        printf "  ${C_GRAY}%-28s  %-12s${NC}\n" "────────────────────────────" "────────────"
        for entry in "${deprecated_casks[@]}"; do
            local cname="${entry%%|*}"
            local _cstatus="${entry##*|}"
            local color="$C_YELLOW"
            [[ "$_cstatus" == "disabled" ]] && color="$C_RED"
            printf "  ${color}${SYM_WARN}${NC}  ${C_WHITE}%-28s${NC}  ${color}%s${NC}\n" "$cname" "$_cstatus"
        done
        echo ""
        _warn "Consider replacing deprecated/disabled casks — they may stop working"
    else
        _ok "No deprecated or disabled casks found"
    fi

    _stat_row "Formula version conflicts"    "${#multi_version[@]}"      "$C_YELLOW"
    _stat_row "Keg-only formulae"            "${#keg_only[@]}"           "$C_BLUE"
    _stat_row "Deprecated/disabled casks"   "${#deprecated_casks[@]}"   "$C_RED"
}
