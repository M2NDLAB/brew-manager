#!/bin/zsh
# =============================================================================
# modules/mod_05_cleanup.sh — Cache and orphan dependency cleanup
# =============================================================================

_module_5() {
    _section "5" "Cache and Orphan Dependency Cleanup"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    _about_risk "5"
    echo ""
    echo -e "  ${C_GRAY}Frees disk space by removing two categories of unnecessary files:${NC}"
    echo ""
    printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_GRAY}%-22s${NC}  %s\n" "Orphan dependencies"  "Formulae installed as deps but no longer needed by any package"
    printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_GRAY}%-22s${NC}  %s\n" "Old versions + cache"  "Previous versions of upgraded packages and download cache"
    echo ""
    echo -e "  ${C_GRAY}brew autoremove removes orphans. brew cleanup -s removes old versions${NC}"
    echo -e "  ${C_GRAY}and the download cache. Both operations are safe — current versions${NC}"
    echo -e "  ${C_GRAY}are never touched. Cache size is measured before and after.${NC}"
    echo -e "  ${C_GRAY}Runs only after confirmation (auto-confirmed in --yes runs).${NC}"
    echo -e "  ${C_GRAY}With --dry-run you get a preview only.${NC}"
    _hline "·" "$C_GRAY"
    du_before=$(du -sh "$(brew --cache)" 2>/dev/null | cut -f1 || echo "n/a")
    _stat_row "Cache before cleanup" "$du_before" "$C_YELLOW"

    # --dry-run: preview via brew's own --dry-run flags — the real autoremove
    # and cleanup must never run on this path
    if (( BREW_MANAGER_DRY_RUN )); then
        _info "Dry-run mode — preview only, nothing will be removed"
        # brew output is DATA: print it with %s (never echo -e) so stray escape
        # sequences in cache filenames can't reach the terminal or the log
        autoremove_out=$(brew autoremove --dry-run 2>&1)
        autoremove_rc=$?
        if (( autoremove_rc != 0 )); then
            _warn "Orphan-dependency preview failed (brew exit ${autoremove_rc})"
            echo "$autoremove_out" | grep -v "^$" | while IFS= read -r line; do
                printf "  ${C_GRAY}  %s${NC}\n" "$line"
            done
        # brew autoremove --dry-run prints nothing when there are no orphans
        elif [[ -z "$autoremove_out" ]] || echo "$autoremove_out" | grep -q "Nothing to uninstall"; then
            _ok "No orphan dependencies to remove"
        else
            echo "$autoremove_out" | grep -v "^$" | while IFS= read -r line; do
                printf "  ${C_GRAY}${SYM_DOT}${NC}  %s\n" "$line"
            done
        fi
        cleanup_out=$(brew cleanup -s -n 2>&1)
        cleanup_rc=$?
        (( cleanup_rc != 0 )) && _warn "Cache-cleanup preview failed (brew exit ${cleanup_rc})"
        echo "$cleanup_out" | while IFS= read -r line; do
            [[ -n "$line" ]] && printf "  ${C_GRAY}  %s${NC}\n" "$line"
        done
        if (( autoremove_rc == 0 && cleanup_rc == 0 )); then
            _ok "Dry-run complete — nothing was removed"
        else
            _warn "Dry-run finished with preview errors — nothing was removed"
        fi
        DU_AFTER=$(du -sh "$(brew --cache)" 2>/dev/null | cut -f1 || echo "n/a")
        _stat_row "Cache after (unchanged)" "$DU_AFTER" "$C_GREEN_B"
        return 0
    fi

    # Default "y" keeps automated runs (--yes / LaunchAgents) behaving as before;
    # interactively _ask still requires an explicit y — Enter aborts
    if ! _ask_danger "Cache & orphan cleanup" "Proceed with autoremove and cleanup now?" "y" \
        "brew autoremove  - remove orphaned dependencies" \
        "brew cleanup -s  - remove old versions and the download cache"; then
        _warn "Cleanup skipped — nothing was removed"
        DU_AFTER=$(du -sh "$(brew --cache)" 2>/dev/null | cut -f1 || echo "n/a")
        _stat_row "Cache after (unchanged)" "$DU_AFTER" "$C_GREEN_B"
        return 0
    fi

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
