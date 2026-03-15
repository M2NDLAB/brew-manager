#!/bin/zsh
# =============================================================================
# modules/mod_03_packages.sh — Installed packages report
# =============================================================================

_module_3() {
    _section "3" "Installed Packages Report"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Lists all packages currently installed by Homebrew, split into:${NC}"
    echo ""
    printf "  ${C_GREEN}${SYM_APP}${NC}  ${C_GRAY}%-12s${NC}  %s\n" "Casks [A]/[M]"  "GUI apps — [A]=self-updates, [M]=managed by brew upgrade"
    printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_GRAY}%-12s${NC}  %s\n" "Formulae"       "CLI tools and libraries — always managed by brew upgrade"
    echo ""
    echo -e "  ${C_GRAY}Descriptions are fetched live from brew info --json=v2 --installed${NC}"
    echo -e "  ${C_GRAY}(one fast call for all formulae — no per-package queries).${NC}"
    _hline "·" "$C_GRAY"

    CASK_COUNT=$(brew list --cask | wc -l | tr -d ' ')
    FORMULA_COUNT=$(brew list --formula | wc -l | tr -d ' ')
    local total=$(( CASK_COUNT + FORMULA_COUNT ))

    echo ""
    printf "  ${C_GRAY}%-32s  %-10s${NC}\n" "Category" "Count"
    printf "  ${C_GRAY}%-32s  %-10s${NC}\n" "────────────────────────────────" "──────────"
    printf "  ${C_GREEN}${SYM_APP}${NC}  ${C_CYAN_B}%-28s${NC}  ${C_CYAN_B}%s${NC}\n" "Applications (Casks)" "$CASK_COUNT"
    printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_YELLOW}%-28s${NC}  ${C_YELLOW}%s${NC}\n" "Formulae / Libraries" "$FORMULA_COUNT"
    printf "  ${C_GRAY}%-32s  %-10s${NC}\n" "────────────────────────────────" "──────────"
    printf "  ${C_WHITE}${SYM_STAR}${NC}  ${C_WHITE}%-28s${NC}  ${C_WHITE}%s${NC}\n" "Total packages" "$total"

    echo ""
    echo -e "  ${C_CYAN_B}Installed applications (Casks)${NC}"
    echo ""
    # Legend: explain update flags
    printf "  ${C_GRAY}%-6s  %-12s  %s${NC}\n" "Flag" "Meaning" "Description"
    printf "  ${C_GRAY}%-6s  %-12s  %s${NC}\n" "──────" "────────────" "───────────────────────────────────────────────────"
    printf "  ${C_CYAN_B}%-6s${NC}  ${C_GRAY}%-12s  %s${NC}\n" "[A]" "auto_updates" "App self-updates — brew upgrade skips it (use --greedy)"
    printf "  ${C_GREEN_B}%-6s${NC}  ${C_GRAY}%-12s  %s${NC}\n" "[M]" "manual"       "brew upgrade manages this app directly"
    echo ""
    _hline "·" "$C_GRAY"
    while IFS= read -r app; do
        # Parse full brew info once per cask
        local _raw="$(brew info --cask "$app" 2>/dev/null)"

        # Extract description from first line: "==> name: desc" or fallback
        _cdesc="$(echo "$_raw" | head -1 | sed 's/^==> [^:]*: //' | xargs 2>/dev/null)"
        if [[ -z "$_cdesc" ]] || [[ "$_cdesc" == *"://"* ]]; then
            _cdesc="$(echo "$_raw" | grep -m1 "^[A-Z]" | xargs 2>/dev/null)"
        fi
        [[ "$_cdesc" == *"://"* ]] && _cdesc=""

        # Detect update flag
        if echo "$_raw" | head -1 | grep -q "auto_updates"; then
            _flag="${C_CYAN_B}[A]${NC}"
            _flag_plain="[A]"
        else
            _flag="${C_GREEN_B}[M]${NC}"
            _flag_plain="[M]"
        fi

        if [[ -n "$_cdesc" ]]; then
            printf "  ${C_GREEN}${SYM_APP}${NC} ${_flag}  ${C_WHITE}%-28s${NC}  ${C_GRAY}%s${NC}\n" "$app" "$_cdesc"
        else
            printf "  ${C_GREEN}${SYM_APP}${NC} ${_flag}  ${C_WHITE}%s${NC}\n" "$app"
        fi
    done < <(brew list --cask)

    echo ""
    echo -e "  ${C_YELLOW}Formulae and libraries${NC}"
    _hline "·" "$C_GRAY"

    # Fetch descriptions dynamically from brew info.
    # brew info --json=v2 --installed gives all installed formulae in one call — fast.
    _formula_json=$(brew info --json=v2 --installed 2>/dev/null)

    brew list --formula | while IFS= read -r formula; do
        local desc=""
        # Extract desc from the JSON payload (one network-free call for all formulae)
        if [[ -n "$_formula_json" ]]; then
            desc=$(echo "$_formula_json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
name = sys.argv[1]
for f in data.get('formulae', []):
    if f.get('name') == name or f.get('full_name') == name:
        print(f.get('desc', ''))
        break
" "$formula" 2>/dev/null)
        fi
        # Fallback: plain brew info if JSON parse failed or returned empty
        if [[ -z "$desc" ]]; then
            desc=$(brew info "$formula" 2>/dev/null | sed -n '2p' | sed 's/^[^:]*: //' | xargs)
        fi
        [[ -z "$desc" ]] && desc="System library"
        printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_WHITE}%-28s${NC}  ${C_GRAY}%s${NC}\n" "$formula" "$desc"
    done
}