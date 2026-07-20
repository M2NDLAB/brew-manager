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
    _about_risk "10"
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

    # Find all installed casks with auto_updates flag.
    # A token that looks like a flag would be parsed by brew as an OPTION, not
    # as a package: with no operands left, 'brew upgrade --cask --greedy'
    # upgrades EVERY greedy cask — exactly the unconfirmed upgrade this module
    # must never do. Shape-check the token before it ever reaches brew.
    while IFS= read -r cask; do
        if [[ ! "$cask" =~ ^[A-Za-z0-9][A-Za-z0-9@._+/-]*$ ]]; then
            _warn "Skipping cask with an unexpected name: $cask"
            continue
        fi
        if brew info --cask -- "$cask" 2>/dev/null | grep -q "auto_updates: true"; then
            auto_update_casks+=("$cask")
        fi
    done < <(brew list --cask 2>/dev/null)

    # Check which ones are actually outdated (requires --greedy).
    # --cask is REQUIRED: without it the list also contains outdated FORMULAE,
    # and a formula sharing a cask's token (e.g. docker) would make the cask
    # look outdated and get force-upgraded for nothing.
    # Match the FIRST FIELD literally: 'grep "^$cask "' treats the cask name as
    # a regex, so a name with '.' or '+' could match a different cask
    _greedy_raw=$(brew outdated --cask --greedy --verbose 2>/dev/null)
    _is_outdated() {
        printf '%s\n' "$_greedy_raw" | awk -v c="$1" '$1 == c { found = 1 } END { exit !found }'
    }
    for cask in "${auto_update_casks[@]}"; do
        _is_outdated "$cask" && outdated_greedy+=("$cask")
    done

    _stat_row "Casks with auto_updates flag"    "${#auto_update_casks[@]}"   "$C_CYAN_B"
    # '${#arr[@]:+color}' does NOT mean "color if non-empty" in zsh: the '#'
    # takes the LENGTH of the whole expansion, so a number was being passed as
    # the color and printed next to the value ("00")
    local _out_color="$C_GRAY"
    (( ${#outdated_greedy[@]} > 0 )) && _out_color="$C_YELLOW"
    _stat_row "Outdated despite auto_updates"   "${#outdated_greedy[@]}"     "$_out_color"

    if (( ${#auto_update_casks[@]} == 0 )); then
        echo ""
        _ok "No auto_updates casks found"
        return
    fi

    echo ""
    printf "  ${C_GRAY}%-28s  %-14s  %-8s${NC}\n" "Cask" "Version" "Status"
    printf "  ${C_GRAY}%-28s  %-14s  %-8s${NC}\n" "────────────────────────────" "──────────────" "────────"

    for cask in "${auto_update_casks[@]}"; do
        _ver="$(brew list --versions --cask -- "$cask" 2>/dev/null | awk '{print $2}')"
        if _is_outdated "$cask"; then
            _new_ver="$(printf '%s\n' "$_greedy_raw" | awk -v c="$cask" '$1 == c { print $NF; exit }')"
            printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-28s${NC}  ${C_YELLOW}%-14s${NC}  ${C_YELLOW}→ %s${NC}\n" \
                "$cask" "${_ver:-n/a}" "$_new_ver"
        else
            printf "  ${C_GREEN_B}${SYM_OK}${NC}   ${C_WHITE}%-28s${NC}  ${C_GRAY}%-14s${NC}  ${C_GRAY}%s${NC}\n" \
                "$cask" "${_ver:-n/a}" "up to date"
        fi
    done

    if (( ${#outdated_greedy[@]} > 0 )); then
        echo ""
        _warn "These casks manage their own updates — forcing a brew upgrade may"
        _warn "conflict with the app's own updater. Only the casks listed below"
        _warn "will be touched: no formulae, no other casks."
        echo ""
        for cask in "${outdated_greedy[@]}"; do
            _item "$cask"
        done

        # --dry-run always wins, even over --yes: preview only
        if (( BREW_MANAGER_DRY_RUN )); then
            echo ""
            _info "Dry-run — preview of the upgrade, nothing will be executed"
            # '--' ends brew's option parsing: the operands after it are always
            # treated as package names, never as flags
            local _dry_out _dry_rc
            _dry_out=$(brew upgrade --cask --greedy --dry-run -- "${outdated_greedy[@]}" 2>&1)
            _dry_rc=$?
            # brew output is DATA: printf %s keeps escape sequences inert
            printf '%s\n' "$_dry_out" | while IFS= read -r line; do
                [[ -n "$line" ]] && printf "  ${C_GRAY}  %s${NC}\n" "$line"
            done
            if (( _dry_rc == 0 )); then
                _ok "Dry-run complete — nothing was upgraded"
                return 0
            fi
            _err "Dry-run preview failed (brew exit ${_dry_rc}) — nothing was upgraded"
            return 1
        fi

        echo ""
        if _ask "Force-upgrade the ${#outdated_greedy[@]} cask(s) listed above?"; then
            echo ""
            local _ok_count=0 _noop_count=0
            declare -a _failed=()
            # One cask at a time: a global 'brew upgrade --greedy' would also
            # upgrade formulae and casks the user never confirmed, and its exit
            # status would say nothing about WHICH cask failed
            for cask in "${outdated_greedy[@]}"; do
                _info "Upgrading $cask"
                local _ver_before _ver_after _rc
                _ver_before="$(brew list --versions --cask -- "$cask" 2>/dev/null | awk '{print $2}')"
                # Piped (not captured) so brew's progress streams live — a cask
                # download can take minutes and a frozen TUI reads as a hang.
                # zsh's $pipestatus keeps brew's own status, which $? would lose
                brew upgrade --cask --greedy -- "$cask" 2>&1 | while IFS= read -r line; do
                    [[ -n "$line" ]] && printf "  ${C_GRAY}  %s${NC}\n" "$line"
                done
                _rc=${pipestatus[1]}
                _ver_after="$(brew list --versions --cask -- "$cask" 2>/dev/null | awk '{print $2}')"

                if (( _rc != 0 )); then
                    _err "Failed: $cask (brew exit ${_rc})"
                    _failed+=("$cask")
                elif [[ "$_ver_before" == "$_ver_after" ]]; then
                    # brew exits 0 for "already up to date" too: these casks
                    # self-update, so one may have updated itself since the scan
                    _item "$cask — no change (the app had already updated itself)"
                    (( ++_noop_count ))
                else
                    _ok "Upgraded: $cask (${_ver_before:-n/a} → ${_ver_after:-n/a})"
                    (( ++_ok_count ))
                fi
            done

            echo ""
            _stat_row "Casks upgraded" "$_ok_count" "$C_GREEN_B"
            (( _noop_count > 0 )) && _stat_row "Casks already current" "$_noop_count" "$C_GRAY"
            if (( ${#_failed[@]} > 0 )); then
                _stat_row "Casks failed"  "${#_failed[@]}" "$C_RED"
                _warn "Failed: ${_failed[*]} — see the messages above or the session log"
                return 1
            fi
        else
            _info "No casks upgraded"
        fi
    fi
}
