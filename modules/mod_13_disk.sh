#!/bin/zsh
# =============================================================================
# modules/mod_13_disk.sh — Disk usage breakdown per formula/cask
# Shows how much each installed package occupies, sorted by size.
# =============================================================================

_module_13() {
    _section "13" "Disk Usage Breakdown"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    _about_risk "13"
    echo ""
    echo -e "  ${C_GRAY}Measures how much disk space each installed formula and cask occupies,${NC}"
    echo -e "  ${C_GRAY}sorted from largest to smallest. Useful before running module 5 cleanup${NC}"
    echo -e "  ${C_GRAY}or when deciding which heavy packages to uninstall.${NC}"
    echo ""
    printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_GRAY}%-12s${NC}  %s\n" "Cellar"    "Homebrew formulas — source builds and binaries"
    printf "  ${C_GREEN}${SYM_APP}${NC}  ${C_GRAY}%-12s${NC}  %s\n" "Caskroom"  "GUI apps installed by brew cask"
    echo ""
    echo -e "  ${C_GRAY}Note: cask sizes show only what brew stores in Caskroom (metadata + pkg).${NC}"
    echo -e "  ${C_GRAY}The actual app in /Applications may be larger.${NC}"
    _hline "·" "$C_GRAY"
    _info "Measuring disk usage per installed package"
    echo ""

    local brew_prefix
    brew_prefix=$(brew --prefix)
    local cellar="$brew_prefix/Cellar"
    local caskroom="$brew_prefix/Caskroom"

    # ── Formulae ──
    echo -e "  ${C_YELLOW}Formulae — sorted by size${NC}"
    _hline "·" "$C_GRAY"

    declare -a formula_sizes=()
    while IFS= read -r formula; do
        local formula_path="$cellar/$formula"
        if [[ -d "$formula_path" ]]; then
            local _fsz="$(du -sh "$formula_path" 2>/dev/null | cut -f1)"
            formula_sizes+=("$_fsz|$formula")
        fi
    done < <(brew list --formula 2>/dev/null)

    # Sort by size (du output with suffixes — sort -h needs GNU sort, use python fallback)
    printf '%s\n' "${formula_sizes[@]}" | sort -t'|' -k1 -rh 2>/dev/null | head -20 | \
    while IFS='|' read -r size name; do
        printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_WHITE}%-28s${NC}  ${C_CYAN_B}%s${NC}\n" "$name" "$size"
    done

    # ── Casks ──
    echo ""
    echo -e "  ${C_GREEN}Casks — sorted by size${NC}"
    _hline "·" "$C_GRAY"

    declare -a cask_sizes=()
    while IFS= read -r cask; do
        local cask_path="$caskroom/$cask"
        if [[ -d "$cask_path" ]]; then
            local _csz="$(du -sh "$cask_path" 2>/dev/null | cut -f1)"
            cask_sizes+=("$_csz|$cask")
        fi
    done < <(brew list --cask 2>/dev/null)

    printf '%s\n' "${cask_sizes[@]}" | sort -t'|' -k1 -rh 2>/dev/null | head -20 | \
    while IFS='|' read -r size name; do
        printf "  ${C_GREEN}${SYM_APP}${NC}  ${C_WHITE}%-28s${NC}  ${C_CYAN_B}%s${NC}\n" "$name" "$size"
    done

    # ── Totals ──
    echo ""
    local total_cellar total_caskroom total_cache
    total_cellar=$(du -sh "$cellar" 2>/dev/null | cut -f1 || echo "n/a")
    total_caskroom=$(du -sh "$caskroom" 2>/dev/null | cut -f1 || echo "n/a")
    total_cache=$(du -sh "$(brew --cache)" 2>/dev/null | cut -f1 || echo "n/a")

    _hline "·" "$C_GRAY"
    _stat_row "Formulae (Cellar)"   "$total_cellar"    "$C_YELLOW"
    _stat_row "Casks (Caskroom)"    "$total_caskroom"  "$C_GREEN"
    _stat_row "Download cache"      "$total_cache"     "$C_GRAY"
}
