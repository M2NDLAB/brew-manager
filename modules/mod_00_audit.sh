#!/bin/zsh
# =============================================================================
# modules/mod_00_audit.sh — Audit apps not managed by Homebrew
# =============================================================================

_module_0() {
    _section "0" "AUDIT — Apps not managed by Homebrew"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Scans /Applications/ and ~/Applications/ and compares every .app against${NC}"
    echo -e "  ${C_GRAY}your installed Homebrew casks. Identifies three categories:${NC}"
    echo ""
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-20s${NC}  %s\n" "Managed by brew"   "Already installed via brew cask — nothing to do"
    printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_GRAY}%-20s${NC}  %s\n" "Cask available"    "App exists on disk but brew does not track it — can adopt"
    printf "  ${C_RED}${SYM_ERR}${NC}  ${C_GRAY}%-20s${NC}  %s\n" "No cask found"     "App installed outside brew with no known cask"
    echo ""
    echo -e "  ${C_GRAY}For adoptable apps, brew --adopt links the existing .app to Homebrew${NC}"
    echo -e "  ${C_GRAY}so future updates are managed by brew upgrade.${NC}"
    echo -e "  ${C_GRAY}Apple system apps are detected dynamically via bundle ID and excluded.${NC}"
    _hline "·" "$C_GRAY"
    _info "Comparing /Applications/ and ~/Applications/ against brew list --cask"

    typeset -A BREW_CASKS
    while IFS= read -r cask; do
        BREW_CASKS[$cask]=1
    done < <(brew list --cask 2>/dev/null)

    # Detect Apple/system apps dynamically via bundle ID (com.apple.*) and /System/Applications
    typeset -A APPLE_APPS

    # Apps in /System/Applications are always Apple system apps
    for app_path in /System/Applications/*.app /System/Applications/**/*.app; do
        [[ -e "$app_path" ]] && APPLE_APPS[$(basename "$app_path" .app)]=1
    done

    # Any app in /Applications with a com.apple.* bundle identifier is Apple-owned
    # Use mdfind batch query instead of per-app mdls calls — much faster
    local _apple_bundle_apps
    _apple_bundle_apps="$(mdfind -onlyin /Applications         "kMDItemCFBundleIdentifier == 'com.apple.*'" 2>/dev/null)"
    while IFS= read -r app_path; do
        [[ -z "$app_path" ]] && continue
        APPLE_APPS[$(basename "$app_path" .app)]=1
    done <<< "$_apple_bundle_apps"

    # Also mark apps signed by Apple Inc. via codesign (catches edge cases)
    # Skipped by default — too slow for large /Applications dirs.
    # Uncomment to enable: for app_path in /Applications/*.app; do ...

    _check_brew_available() {
        local app_name="$1"
        local normalized="$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/\.app$//')"
        brew info --cask "$normalized" &>/dev/null && echo "$normalized" || echo ""
    }

    _scan_dir() {
        local dir="$1" label="$2"
        [[ ! -d "$dir" ]] && return
        for app_path in "$dir"/*.app; do
            [[ ! -e "$app_path" ]] && continue
            local app_name="$(basename "$app_path" .app)"
            local normalized="$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/ /-/g')"
            [[ -n "${BREW_CASKS[$normalized]}" ]] && continue
            if [[ -n "${APPLE_APPS[$app_name]}" ]]; then
                UNMANAGED_APPLE+=("$app_name")
                continue
            fi
            local cask_name="$(_check_brew_available "$app_name")"
            if [[ -n "$cask_name" ]]; then
                UNMANAGED_WITH_CASK+=("$app_name|$cask_name|$label")
            else
                UNMANAGED_NO_CASK+=("$app_name|$label")
            fi
        done
    }

    _scan_dir "/Applications" "/Applications"
    _scan_dir "$HOME/Applications" "~/Applications"

    echo ""
    _brew_managed=$(brew list --cask | wc -l | tr -d ' ')
    _stat_row "Apps already managed by brew"  "$_brew_managed"               "$C_GREEN_B"
    _stat_row "Apple/system apps (skipped)"   "${#UNMANAGED_APPLE[@]}"       "$C_GRAY"
    _stat_row "Unmanaged — cask available"    "${#UNMANAGED_WITH_CASK[@]}"   "$C_YELLOW"
    _stat_row "Unmanaged — no cask found"     "${#UNMANAGED_NO_CASK[@]}"     "$C_RED"

    # Table: apps already managed by brew
    echo ""
    echo -e "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_GRAY}Apps already managed by brew (${_brew_managed}):${NC}"
    echo ""
    printf "  ${C_GRAY}%-3s  %-28s${NC}\n" "" "App"
    printf "  ${C_GRAY}%-3s  %-28s${NC}\n" "   " "────────────────────────────"
    local _ci=1
    while IFS= read -r _cask; do
        printf "  ${C_GRAY}%-3s  %-28s${NC}\n" "$_ci" "$_cask"
        (( _ci++ ))
    done < <(brew list --cask)

    if (( ${#UNMANAGED_APPLE[@]} > 0 )); then
        echo ""
        echo -e "  ${C_GRAY}${SYM_INFO}${NC}  ${C_GRAY}Apple/system apps excluded from audit (${#UNMANAGED_APPLE[@]}):${NC}"
        echo ""
        printf "  ${C_GRAY}%-28s${NC}\n" "App"
        printf "  ${C_GRAY}%-28s${NC}\n" "────────────────────────────"
        for _aapp in "${UNMANAGED_APPLE[@]}"; do
            printf "  ${C_GRAY}%-28s${NC}\n" "$_aapp"
        done
    fi

    if (( ${#UNMANAGED_WITH_CASK[@]} > 0 )); then
        echo ""
        echo -e "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_WHITE}Apps adoptable with brew --adopt:${NC}"
        echo ""
        printf "  ${C_GRAY}%-6s  %-28s  %-22s  %-14s${NC}\n" "No." "App" "Brew cask" "Location"
        printf "  ${C_GRAY}%-6s  %-28s  %-22s  %-14s${NC}\n" "──────" "────────────────────────────" "──────────────────────" "──────────────"
        local idx=1
        for entry in "${UNMANAGED_WITH_CASK[@]}"; do
            local app_name="${entry%%|*}"
            local rest="${entry#*|}"
            local cask_name="${rest%%|*}"
            local source="${rest##*|}"
            printf "  ${C_CYAN_B}[%s]${NC}   ${C_WHITE}%-28s${NC}  ${C_YELLOW}%-22s${NC}  ${C_GRAY}%-14s${NC}\n" \
                "$idx" "$app_name" "$cask_name" "$source"
            (( idx++ ))
        done
        echo ""
    fi

    if (( ${#UNMANAGED_NO_CASK[@]} > 0 )); then
        echo ""
        echo -e "  ${C_RED}${SYM_ERR}${NC}  ${C_GRAY}Unmanaged apps — no brew cask found:${NC}"
        echo ""
        printf "  ${C_GRAY}%-28s  %-15s${NC}\n" "App" "Location"
        printf "  ${C_GRAY}%-28s  %-15s${NC}\n" "────────────────────────────" "───────────────"
        for entry in "${UNMANAGED_NO_CASK[@]}"; do
            local app_name="${entry%%|*}"
            local source="${entry##*|}"
            printf "  ${C_GRAY}%-28s  %-15s${NC}\n" "$app_name" "$source"
        done
        echo ""
    fi

    if (( ${#UNMANAGED_WITH_CASK[@]} > 0 )); then
        echo ""
        echo -e "  ${C_CYAN_B}Which apps do you want to adopt with brew --adopt?${NC}"
        echo -e "  ${C_GRAY}Comma-separated numbers, 'all' for all, 'n' for none (default: n)${NC}"
        echo -e "  ${C_GRAY}Example: 1,3  or  all  or  n${NC}"
        echo -e "  ${C_GRAY}CLI override: --adopt=all  or  --adopt=1,2${NC}"
        echo ""
        adopt_choice="$(_read_choice "Choice" "n" "BREW_MANAGER_ADOPT")"

        declare -a TO_ADOPT=()
        case "${adopt_choice:-n}" in
            n|N|"") _info "No adoption performed" ;;
            all|ALL) TO_ADOPT=("${UNMANAGED_WITH_CASK[@]}") ;;
            *)
                IFS=',' read -rA selected_nums <<< "$adopt_choice"
                for num in "${selected_nums[@]}"; do
                    num=$(echo "$num" | tr -d ' ')
                    if [[ "$num" =~ ^[0-9]+$ ]]; then
                        local real_idx=$(( num - 1 ))
                        if (( real_idx >= 0 && real_idx < ${#UNMANAGED_WITH_CASK[@]} )); then
                            TO_ADOPT+=("${UNMANAGED_WITH_CASK[$real_idx]}")
                        else
                            _warn "Number $num is invalid — skipped"
                        fi
                    fi
                done
                ;;
        esac

        if (( ${#TO_ADOPT[@]} > 0 )); then
            echo ""
            for entry in "${TO_ADOPT[@]}"; do
                local cask_name="${entry#*|}"
                cask_name="${cask_name%%|*}"
                local app_name="${entry%%|*}"
                echo -e "  ${C_CYAN}${SYM_ARR}${NC}  Adopting ${C_WHITE}${app_name}${NC} ${C_GRAY}(${cask_name})${NC}..."
                if brew install --cask "$cask_name" --adopt 2>/tmp/brew_adopt_err.log; then
                    _ok "Adopted: $app_name"
                else
                    _warn "Failed: $app_name — $(tail -1 /tmp/brew_adopt_err.log)"
                fi
            done
        fi
    fi
}