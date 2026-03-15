#!/bin/zsh
# =============================================================================
# modules/mod_02_update.sh — Formula database update
# =============================================================================

_module_2() {
    _section "2" "Formula Database Update"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Runs brew update, which fetches the latest package definitions (formulae${NC}"
    echo -e "  ${C_GRAY}and casks) from Homebrew's JSON API. This is NOT the same as upgrading${NC}"
    echo -e "  ${C_GRAY}packages — it only updates the list of what is available and what versions${NC}"
    echo -e "  ${C_GRAY}exist. Upgrading packages happens in module 4.${NC}"
    echo ""
    echo -e "  ${C_GRAY}Since Homebrew 4.x, core and cask repos are fetched as JSON files${NC}"
    echo -e "  ${C_GRAY}rather than Git clones — brew update is fast (seconds, not minutes).${NC}"
    _hline "·" "$C_GRAY"
    _info "Updating formula and cask index"
    { brew update > /tmp/brew_update.log 2>&1; } &
    _spinner $! "brew update"

    local _already_up
    grep -q "Already up-to-date" /tmp/brew_update.log 2>/dev/null && _already_up=1

    echo ""
    if [[ -n "$_already_up" ]]; then
        _ok "Database already up to date"
    else
        _ok "Database updated"
    fi

    echo ""
    printf "  ${C_GRAY}%-36s  %-20s${NC}\n" "Repository" "Status"
    printf "  ${C_GRAY}%-36s  %-20s${NC}\n" "────────────────────────────────────" "────────────────────"
    printf "  ${C_GREEN_B}${SYM_OK}${NC}   ${C_WHITE}%-36s${NC}  ${C_GRAY}%s${NC}\n" "homebrew/core" "updated via JSON API"
    printf "  ${C_GREEN_B}${SYM_OK}${NC}   ${C_WHITE}%-36s${NC}  ${C_GRAY}%s${NC}\n" "homebrew/cask" "updated via JSON API"

    _extra_taps="$(brew tap 2>/dev/null)"
    if [[ -n "$_extra_taps" ]]; then
        while IFS= read -r tap; do
            _tap_updated="$(cd "$(brew --repository)" 2>/dev/null && git log --format="%ar" -1 -- "Library/Taps/$tap" 2>/dev/null || echo "n/a")"
            printf "  ${C_CYAN}${SYM_OK}${NC}   ${C_WHITE}%-36s${NC}  ${C_GRAY}%s${NC}\n" "$tap" "${_tap_updated:-updated}"
        done <<< "$_extra_taps"
    fi

    echo ""
    _new_formulae=$(grep -E "^New (Formulae|Casks):" /tmp/brew_update.log 2>/dev/null)
    if [[ -n "$_new_formulae" ]]; then
        echo "$_new_formulae" | while IFS= read -r line; do _info "$line"; done
    fi
}