#!/bin/zsh
# =============================================================================
# modules/mod_10_greedy.sh — Casks with auto_updates (skipped by brew upgrade)
# Brew skips casks marked auto_updates=true during normal `brew upgrade`.
# This module finds them and offers a --greedy upgrade.
# =============================================================================

_module_10() {
    _section "10" "Auto-update Casks (skipped by brew upgrade)"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Some casks (Docker, Firefox, Discord, VS Code...) are marked auto_updates=true${NC}"
    echo -e "  ${C_GRAY}because they have their own built-in updater. Homebrew intentionally skips${NC}"
    echo -e "  ${C_GRAY}them during brew upgrade to avoid conflicts with the app's own update.${NC}"
    echo ""
    echo -e "  ${C_GRAY}This module finds those casks and checks if they are actually outdated${NC}"
    echo -e "  ${C_GRAY}using brew upgrade --greedy. If the app has not self-updated (e.g. you${NC}"
    echo -e "  ${C_GRAY}disabled auto-update), this module lets you force a brew update instead.${NC}"
    _hline "·" "$C_GRAY"
    _info "Finding casks marked auto_updates — not upgraded by default"
    echo ""

    declare -a auto_update_casks=()
    declare -a outdated_greedy=()

    # Find all installed casks with auto_updates flag
    while IFS= read -r cask; do
        if brew info --cask "$cask" 2>/dev/null | grep -q "auto_updates: true"; then
            auto_update_casks+=("$cask")
        fi
    done < <(brew list --cask 2>/dev/null)

    # Check which ones are actually outdated (requires --greedy)
    _greedy_raw=$(brew outdated --greedy --verbose 2>/dev/null)
    for cask in "${auto_update_casks[@]}"; do
        echo "$_greedy_raw" | grep -q "^$cask " && outdated_greedy+=("$cask")
    done

    _stat_row "Casks with auto_updates flag"    "${#auto_update_casks[@]}"   "$C_CYAN_B"
    _stat_row "Outdated despite auto_updates"   "${#outdated_greedy[@]}"     "${#outdated_greedy[@]:+$C_YELLOW}"

    if (( ${#auto_update_casks[@]} == 0 )); then
        echo ""
        _ok "No auto_updates casks found"
        return
    fi

    echo ""
    printf "  ${C_GRAY}%-28s  %-14s  %-8s${NC}\n" "Cask" "Version" "Status"
    printf "  ${C_GRAY}%-28s  %-14s  %-8s${NC}\n" "────────────────────────────" "──────────────" "────────"

    for cask in "${auto_update_casks[@]}"; do
        _ver="$(brew list --versions --cask "$cask" 2>/dev/null | awk '{print $2}')"
        if echo "$_greedy_raw" | grep -q "^$cask "; then
            _new_ver="$(echo "$_greedy_raw" | grep "^$cask " | awk '{print $NF}')"
            printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-28s${NC}  ${C_YELLOW}%-14s${NC}  ${C_YELLOW}→ %s${NC}\n" \
                "$cask" "${_ver:-n/a}" "$_new_ver"
        else
            printf "  ${C_GREEN_B}${SYM_OK}${NC}   ${C_WHITE}%-28s${NC}  ${C_GRAY}%-14s${NC}  ${C_GRAY}%s${NC}\n" \
                "$cask" "${_ver:-n/a}" "up to date"
        fi
    done

    if (( ${#outdated_greedy[@]} > 0 )); then
        echo ""
        if _ask "Run brew upgrade --greedy to update ${#outdated_greedy[@]} cask(s)?"; then
            echo ""
            _info "Running brew upgrade --greedy"
            brew upgrade --greedy 2>&1 | while IFS= read -r line; do
                [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
            done
            _ok "Greedy upgrade completed"
        fi
    fi
}