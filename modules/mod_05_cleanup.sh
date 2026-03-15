#!/bin/zsh
# =============================================================================
# modules/mod_05_cleanup.sh — Cache and orphan dependency cleanup
# =============================================================================

_module_5() {
    _section "5" "Cache and Orphan Dependency Cleanup"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Frees disk space by removing two categories of unnecessary files:${NC}"
    echo ""
    printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_GRAY}%-22s${NC}  %s\n" "Orphan dependencies"  "Formulae installed as deps but no longer needed by any package"
    printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_GRAY}%-22s${NC}  %s\n" "Old versions + cache"  "Previous versions of upgraded packages and download cache"
    echo ""
    echo -e "  ${C_GRAY}brew autoremove removes orphans. brew cleanup -s removes old versions${NC}"
    echo -e "  ${C_GRAY}and the download cache. Both operations are safe — current versions${NC}"
    echo -e "  ${C_GRAY}are never touched. Cache size is measured before and after.${NC}"
    _hline "·" "$C_GRAY"
    du_before=$(du -sh "$(brew --cache)" 2>/dev/null | cut -f1 || echo "n/a")
    _stat_row "Cache before cleanup" "$du_before" "$C_YELLOW"

    _info "Removing orphan dependencies"
    autoremove_out=$(brew autoremove 2>&1)
    if echo "$autoremove_out" | grep -q "Nothing to uninstall"; then
        _ok "No orphan dependencies found"
    else
        _ok "Dependencies removed"
        echo "$autoremove_out" | grep -v "^$" | while IFS= read -r line; do
            _item "$line"
        done
    fi

    _info "Removing old versions and cache"
    brew cleanup -s 2>&1 | while IFS= read -r line; do
        [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
    done
    _ok "Cleanup completed"

    DU_AFTER=$(du -sh "$(brew --cache)" 2>/dev/null | cut -f1 || echo "n/a")
    _stat_row "Cache after cleanup" "$DU_AFTER" "$C_GREEN_B"
}