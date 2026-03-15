#!/bin/zsh
# =============================================================================
# modules/mod_bk_brewfile.sh — Brewfile + Agents backup and restore
# Uses brew bundle for Homebrew packages and a custom agents bundle format
# for LaunchAgent configurations. Both can be backed up and restored together.
# Invoked as: ./brew_manager.sh bk
# =============================================================================

_module_14() {
    _section "bk" "Brewfile & Agents Backup and Restore"

    local brewfile_dir="$BREW_MANAGER_SCRIPT_DIR/backups"
    local brewfile_path="$brewfile_dir/Brewfile"
    local brewfile_lock="$brewfile_dir/Brewfile.lock.json"
    local agents_bundle="$brewfile_dir/agents_bundle.conf"
    local agents_dir="$BREW_MANAGER_SCRIPT_DIR/agents"

    mkdir -p "$brewfile_dir" 2>/dev/null

    # ── About ──
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Creates and manages portable snapshots of your entire setup:${NC}"
    echo ""
    printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_GRAY}%-14s${NC}  %s\n" "Brewfile"       "Declarative list of all Homebrew formulae, casks, and taps"
    printf "  ${C_CYAN}${SYM_LOCK}${NC}  ${C_GRAY}%-14s${NC}  %s\n" "Agents bundle"  "All LaunchAgent schedules (label, time, modules)"
    echo ""
    echo -e "  ${C_GRAY}Both can be backed up, previewed, and restored independently or together.${NC}"
    echo -e "  ${C_GRAY}On a new Mac: copy backups/ into the brew-manager folder and run restore.${NC}"
    echo ""
    printf "  ${C_CYAN_B}%-4s${NC}  ${C_GRAY}Preview (2/2a/2b)${NC}  %s\n" "" "See what would be saved — no disk writes"
    printf "  ${C_GREEN_B}%-4s${NC}  ${C_GRAY}Backup  (1/1a/1b)${NC}  %s\n" "" "Save Brewfile and/or agents bundle to backups/"
    printf "  ${C_YELLOW}%-4s${NC}  ${C_GRAY}Restore (3/3a/3b)${NC}  %s\n" "" "Reinstall packages and/or reload agents from saved files"
    printf "  ${C_GRAY}%-4s${NC}  ${C_GRAY}Check   (4)       ${NC}  %s\n" "" "Verify all Brewfile dependencies are currently installed"
    printf "  ${C_CYAN_B}%-4s${NC}  ${C_GRAY}View    (5)       ${NC}  %s\n" "" "Show saved Brewfile contents with color-coded categories"
    printf "  ${C_RED}%-4s${NC}  ${C_GRAY}Delete  (6)       ${NC}  %s\n" "" "Remove Brewfile and/or agents bundle from backups/"
    _hline "·" "$C_GRAY"

    # ── Helper: show current status ──
    _show_bk_status() {
        echo ""
        # Brewfile status
        if [[ -f "$brewfile_path" ]]; then
            local _bmod="$(stat -f "%Sm" -t "%a %b %d %Y %H:%M" "$brewfile_path" 2>/dev/null)"
            local _blines="$(wc -l < "$brewfile_path" | tr -d ' ')"
            _stat_row "Brewfile"           "$brewfile_path"  "$C_GRAY"
            _stat_row "Last backup"        "$_bmod"          "$C_CYAN_B"
            _stat_row "Entries"            "$_blines"        "$C_WHITE"
        else
            _stat_row "Brewfile"           "not found"       "$C_RED"
        fi
        echo ""
        # Agents bundle status
        if [[ -f "$agents_bundle" ]]; then
            local _amod="$(stat -f "%Sm" -t "%a %b %d %Y %H:%M" "$agents_bundle" 2>/dev/null)"
            local _acount="$(grep -c "^agent=" "$agents_bundle" 2>/dev/null || echo 0)"
            _stat_row "Agents bundle"      "$agents_bundle"  "$C_GRAY"
            _stat_row "Last agents backup" "$_amod"          "$C_CYAN_B"
            _stat_row "Agents in bundle"   "$_acount"        "$C_WHITE"
        else
            _stat_row "Agents bundle"      "not found"       "$C_YELLOW"
        fi
        echo ""
    }

    # ── Helper: backup agents to bundle file ──
    _backup_agents() {
        setopt nullglob
        local _cfg_files=("$agents_dir"/agent_*.conf)
        unsetopt nullglob

        if (( ${#_cfg_files[@]} == 0 )); then
            _info "No agents configured — agents bundle skipped"
            return
        fi

        local ts="$(date '+%Y-%m-%d %H:%M')"
        echo "# brew-manager agents bundle" > "$agents_bundle"
        echo "# Generated: $ts" >> "$agents_bundle"
        echo "# Restore with: ./brew_manager.sh bk → option 3 (Restore agents)" >> "$agents_bundle"
        echo "" >> "$agents_bundle"

        for cfg in "${_cfg_files[@]}"; do
            local _label="$(grep "^label=" "$cfg" | cut -d= -f2-)"
            local _schedule="$(grep "^schedule=" "$cfg" | cut -d= -f2-)"
            local _modules="$(grep "^modules=" "$cfg" | cut -d= -f2-)"
            echo "agent=label=${_label}|schedule=${_schedule}|modules=${_modules}" >> "$agents_bundle"
        done

        _ok "Agents bundle saved: ${#_cfg_files[@]} agent(s) → $agents_bundle"
    }

    # ── Helper: restore agents from bundle ──
    _restore_agents() {
        if [[ ! -f "$agents_bundle" ]]; then
            _err "No agents bundle found at $agents_bundle — backup agents first"
            return
        fi

        local _plist_dir="$HOME/Library/LaunchAgents"
        mkdir -p "$_plist_dir" "$agents_dir"

        local _restored=0
        while IFS= read -r line; do
            [[ "$line" != agent=* ]] && continue
            local _data="${line#agent=}"
            local _label="$(echo "$_data" | tr '|' '\n' | grep "^label=" | cut -d= -f2-)"
            local _schedule="$(echo "$_data" | tr '|' '\n' | grep "^schedule=" | cut -d= -f2-)"
            local _modules="$(echo "$_data" | tr '|' '\n' | grep "^modules=" | cut -d= -f2-)"

            if [[ -z "$_label" || -z "$_modules" ]]; then continue; fi

            # Parse schedule back to hour/minute/weekday
            local _hour=9 _minute=0 _weekday=""
            if echo "$_schedule" | grep -q "^daily"; then
                _hour="$(echo "$_schedule" | awk '{print $2}' | cut -d: -f1)"
                _minute="$(echo "$_schedule" | awk '{print $2}' | cut -d: -f2)"
            else
                local _day_name="$(echo "$_schedule" | awk '{print $1}')"
                _hour="$(echo "$_schedule" | awk '{print $2}' | cut -d: -f1)"
                _minute="$(echo "$_schedule" | awk '{print $2}' | cut -d: -f2)"
                local _days_map=(Sun Mon Tue Wed Thu Fri Sat)
                for i in {0..6}; do
                    [[ "${_days_map[$i]}" == "$_day_name" ]] && _weekday="$i" && break
                done
            fi

            local _plist="$_plist_dir/${_label}.plist"
            local _log_out="$BREW_MANAGER_SCRIPT_DIR/logs/agent_stdout_${_label}.log"
            local _log_err="$BREW_MANAGER_SCRIPT_DIR/logs/agent_stderr_${_label}.log"

            local _cal_block
            if [[ -n "$_weekday" ]]; then
                _cal_block="        <dict>
            <key>Weekday</key><integer>${_weekday}</integer>
            <key>Hour</key><integer>${_hour}</integer>
            <key>Minute</key><integer>${_minute}</integer>
        </dict>"
            else
                _cal_block="        <dict>
            <key>Hour</key><integer>${_hour}</integer>
            <key>Minute</key><integer>${_minute}</integer>
        </dict>"
            fi

            cat > "$_plist" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${_label}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>${BREW_MANAGER_SCRIPT_DIR}/brew_manager.sh</string>
        <string>${_modules}</string>
        <string>--yes</string>
    </array>
    <key>StartCalendarInterval</key>
${_cal_block}
    <key>StandardOutPath</key>
    <string>${_log_out}</string>
    <key>StandardErrorPath</key>
    <string>${_log_err}</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
PLIST_EOF

            launchctl unload "$_plist" 2>/dev/null
            launchctl load "$_plist" 2>/dev/null

            # Save conf
            local _ts="$(date '+%Y-%m-%d %H:%M')"
            cat > "$agents_dir/agent_${_label}.conf" << EOF
# brew-manager LaunchAgent configuration
# Restored from bundle: $agents_bundle
label=$_label
schedule=$_schedule
modules=$_modules
plist=$_plist
created=$_ts
EOF
            _ok "Restored agent: $_label  ($_schedule  modules: $_modules)"
            (( _restored++ ))
        done < "$agents_bundle"

        echo ""
        _stat_row "Agents restored" "$_restored" "$C_GREEN_B"
    }

    # ── Main menu loop ──
    while true; do
        _show_bk_status
        echo -e "  ${C_WHITE}What do you want to do?${NC}"
        echo ""
        printf "  ${C_GREEN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[1]" "Backup all"      "Backup Brewfile + agents bundle together"
        printf "  ${C_GREEN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[1b]" "Backup Brewfile" "Backup Homebrew packages only (no agents)"
        printf "  ${C_GREEN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[1a]" "Backup agents"  "Backup LaunchAgent schedules only (no Brewfile)"
        printf "  ${C_CYAN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[2]"  "Preview all"    "Preview Brewfile + agents bundle (no save)"
        printf "  ${C_CYAN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[2b]" "Preview brew"   "Preview Homebrew packages only"
        printf "  ${C_CYAN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[2a]" "Preview agents" "Preview configured LaunchAgents"
        printf "  ${C_YELLOW}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[3]"  "Restore all"    "Reinstall Homebrew packages + reload agents"
        printf "  ${C_YELLOW}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[3b]" "Restore brew"   "Restore Homebrew packages only"
        printf "  ${C_YELLOW}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[3a]" "Restore agents" "Reload LaunchAgents from bundle only"
        printf "  ${C_GRAY}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[4]"  "Check"          "Verify all Brewfile dependencies are satisfied"
        printf "  ${C_CYAN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[5]"  "View"           "Show current Brewfile contents"
        printf "  ${C_RED}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[6]"  "Delete"         "Delete Brewfile and/or agents bundle"
        printf "  ${C_GRAY}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[n]"  "Skip"           "Exit this module"
        echo ""
        printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[1/1a/1b/2/2a/2b/3/3a/3b/4/5/6/n, default: n]${NC}: "
        read -r bf_choice

        case "${bf_choice:-n}" in

            1)  # BACKUP ALL
                if (( BREW_MANAGER_DRY_RUN )); then
                    _info "Dry-run — skipping write"
                else
                    _info "Generating Brewfile"
                    brew bundle dump --file="$brewfile_path" --force --describe 2>&1 | \
                        while IFS= read -r line; do
                            [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
                        done
                    if [[ -f "$brewfile_path" ]]; then
                        local _count="$(wc -l < "$brewfile_path" | tr -d ' ')"
                        _ok "Brewfile saved ($_count entries)"
                    fi
                    echo ""
                    _backup_agents
                    echo ""
                    echo -e "  ${C_GRAY}Restore on any Mac with:${NC}"
                    echo -e "  ${C_CYAN}  ./brew_manager.sh bk  → option 3${NC}"
                fi
                ;;

            1b)  # BACKUP BREWFILE ONLY
                if (( BREW_MANAGER_DRY_RUN )); then
                    _info "Dry-run — skipping write"
                else
                    _info "Generating Brewfile (packages only)"
                    brew bundle dump --file="$brewfile_path" --force --describe 2>&1 | \
                        while IFS= read -r line; do
                            [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
                        done
                    if [[ -f "$brewfile_path" ]]; then
                        local _count="$(wc -l < "$brewfile_path" | tr -d ' ')"
                        _ok "Brewfile saved ($_count entries)"
                    fi
                fi
                ;;

            1a)  # BACKUP AGENTS ONLY
                if (( BREW_MANAGER_DRY_RUN )); then
                    _info "Dry-run — skipping write"
                else
                    _backup_agents
                fi
                ;;

            2)  # PREVIEW ALL
                _info "Preview Brewfile:"
                echo ""
                brew bundle dump --file=/dev/stdout --describe 2>/dev/null | \
                    while IFS= read -r line; do
                        [[ "$line" == tap* ]]  && printf "  ${C_BLUE}${SYM_DOT}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        [[ "$line" == brew* ]] && printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        [[ "$line" == cask* ]] && printf "  ${C_GREEN}${SYM_APP}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        [[ "$line" == mas* ]]  && printf "  ${C_PURPLE_B}${SYM_APP}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        [[ "$line" == \#* ]]   && printf "  ${C_GRAY}%s${NC}\n" "$line"
                    done
                echo ""
                _info "Preview agents bundle:"
                echo ""
                setopt nullglob
                local _pa_cfgs=("$agents_dir"/agent_*.conf)
                unsetopt nullglob
                if (( ${#_pa_cfgs[@]} == 0 )); then
                    _info "No agents configured"
                else
                    printf "  ${C_GRAY}%-36s  %-16s  %s${NC}\n" "Label" "Schedule" "Modules"
                    printf "  ${C_GRAY}%-36s  %-16s  %s${NC}\n" "────────────────────────────────────" "────────────────" "────────"
                    for _pac in "${_pa_cfgs[@]}"; do
                        local _pal="$(grep "^label=" "$_pac" | cut -d= -f2-)"
                        local _pas="$(grep "^schedule=" "$_pac" | cut -d= -f2-)"
                        local _pam="$(grep "^modules=" "$_pac" | cut -d= -f2-)"
                        printf "  ${C_CYAN}${SYM_ARR}${NC}  ${C_WHITE}%-36s${NC}  ${C_GRAY}%-16s${NC}  ${C_CYAN_B}%s${NC}\n" "$_pal" "$_pas" "$_pam"
                    done
                fi
                ;;

            2b)  # PREVIEW BREWFILE ONLY
                _info "Preview — Homebrew packages that would be written to Brewfile:"
                echo ""
                brew bundle dump --file=/dev/stdout --describe 2>/dev/null | \
                    while IFS= read -r line; do
                        [[ "$line" == tap* ]]  && printf "  ${C_BLUE}${SYM_DOT}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        [[ "$line" == brew* ]] && printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        [[ "$line" == cask* ]] && printf "  ${C_GREEN}${SYM_APP}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        [[ "$line" == mas* ]]  && printf "  ${C_PURPLE_B}${SYM_APP}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        [[ "$line" == \#* ]]   && printf "  ${C_GRAY}%s${NC}\n" "$line"
                    done
                ;;

            2a)  # PREVIEW AGENTS ONLY
                _info "Preview — configured LaunchAgents:"
                echo ""
                setopt nullglob
                local _poa_cfgs=("$agents_dir"/agent_*.conf)
                unsetopt nullglob
                if (( ${#_poa_cfgs[@]} == 0 )); then
                    _info "No agents configured"
                else
                    printf "  ${C_GRAY}%-36s  %-16s  %s${NC}\n" "Label" "Schedule" "Modules"
                    printf "  ${C_GRAY}%-36s  %-16s  %s${NC}\n" "────────────────────────────────────" "────────────────" "────────"
                    for _poac in "${_poa_cfgs[@]}"; do
                        local _poal="$(grep "^label=" "$_poac" | cut -d= -f2-)"
                        local _poas="$(grep "^schedule=" "$_poac" | cut -d= -f2-)"
                        local _poam="$(grep "^modules=" "$_poac" | cut -d= -f2-)"
                        printf "  ${C_CYAN}${SYM_ARR}${NC}  ${C_WHITE}%-36s${NC}  ${C_GRAY}%-16s${NC}  ${C_CYAN_B}%s${NC}\n" "$_poal" "$_poas" "$_poam"
                    done
                fi
                ;;

            3)  # RESTORE ALL
                echo ""
                _warn "This will install all packages from Brewfile AND reload agents"
                if _ask "Proceed with full restore?" "n"; then
                    echo ""
                    if [[ -f "$brewfile_path" ]]; then
                        _info "Restoring Homebrew packages"
                        brew bundle install --file="$brewfile_path" 2>&1 | \
                            while IFS= read -r line; do
                                [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
                            done
                        _ok "Homebrew restore completed"
                    else
                        _warn "No Brewfile found — skipping packages restore"
                    fi
                    echo ""
                    _info "Restoring agents"
                    _restore_agents
                fi
                break
                ;;

            3b)  # RESTORE HOMEBREW ONLY
                if [[ ! -f "$brewfile_path" ]]; then
                    _err "No Brewfile found — run backup first"
                elif _ask "Restore Homebrew packages from Brewfile?" "n"; then
                    echo ""
                    _info "Restoring Homebrew packages"
                    brew bundle install --file="$brewfile_path" 2>&1 | \
                        while IFS= read -r line; do
                            [[ -n "$line" ]] && echo -e "  ${C_GRAY}  $line${NC}"
                        done
                    _ok "Homebrew restore completed"
                fi
                ;;

            3a)  # RESTORE AGENTS ONLY
                if (( BREW_MANAGER_DRY_RUN )); then
                    _info "Dry-run — skipping agents restore"
                else
                    _restore_agents
                fi
                ;;

            4)  # CHECK
                if [[ ! -f "$brewfile_path" ]]; then
                    _err "No Brewfile found — run backup first"
                else
                    _info "Checking Brewfile dependencies"
                    if brew bundle check --file="$brewfile_path" 2>/dev/null; then
                        _ok "All Brewfile dependencies are satisfied"
                    else
                        _warn "Some dependencies missing — run restore to fix"
                        brew bundle check --file="$brewfile_path" --verbose 2>/dev/null | \
                            grep -v "^The Brewfile" | while IFS= read -r line; do
                                [[ -n "$line" ]] && echo -e "  ${C_YELLOW}  ${SYM_DOT} ${line}${NC}"
                            done
                    fi
                fi
                ;;

            5)  # VIEW — Brewfile + agents with index numbers for delete
                echo ""

                # ── Backup files inventory with numbers ──
                declare -a _bk_items=()
                declare -a _bk_labels=()

                if [[ -f "$brewfile_path" ]]; then
                    _bk_items+=("brewfile")
                    local _bf_mod="$(stat -f "%Sm" -t "%a %b %d %Y %H:%M" "$brewfile_path" 2>/dev/null)"
                    local _bf_lines="$(wc -l < "$brewfile_path" | tr -d ' ')"
                    _bk_labels+=("Brewfile  (${_bf_lines} entries, ${_bf_mod})")
                fi
                if [[ -f "$agents_bundle" ]]; then
                    _bk_items+=("agents")
                    local _ab_mod="$(stat -f "%Sm" -t "%a %b %d %Y %H:%M" "$agents_bundle" 2>/dev/null)"
                    local _ab_count="$(grep -c "^agent=" "$agents_bundle" 2>/dev/null || echo 0)"
                    _bk_labels+=("Agents bundle  (${_ab_count} agent(s), ${_ab_mod})")
                fi

                if (( ${#_bk_items[@]} == 0 )); then
                    _warn "No backup files found in $brewfile_dir — run backup first"
                else
                    echo -e "  ${C_CYAN_B}Backed up files:${NC}"
                    echo ""
                    for _bi in {1..${#_bk_items[@]}}; do
                        printf "  ${C_CYAN_B}[%s]${NC}  ${C_WHITE}%s${NC}\n" "$_bi" "${_bk_labels[$_bi]}"
                    done
                fi

                # ── Brewfile contents ──
                if [[ -f "$brewfile_path" ]]; then
                    echo ""
                    echo -e "  ${C_CYAN_B}Brewfile contents:${NC}  ${C_GRAY}($brewfile_path)${NC}"
                    echo ""
                    while IFS= read -r line; do
                        if [[ "$line" == tap* ]]; then
                            printf "  ${C_BLUE}${SYM_DOT}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        elif [[ "$line" == brew* ]]; then
                            printf "  ${C_YELLOW}${SYM_PKG}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        elif [[ "$line" == cask* ]]; then
                            printf "  ${C_GREEN}${SYM_APP}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        elif [[ "$line" == mas* ]]; then
                            printf "  ${C_PURPLE_B}${SYM_APP}${NC}  ${C_WHITE}%s${NC}\n" "$line"
                        elif [[ "$line" == \#* || -z "$line" ]]; then
                            printf "  ${C_GRAY}%s${NC}\n" "$line"
                        else
                            printf "  ${C_WHITE}%s${NC}\n" "$line"
                        fi
                    done < "$brewfile_path"
                    echo ""
                    local _tap_count="$(grep -c "^tap"  "$brewfile_path" 2>/dev/null || echo 0)"
                    local _brew_count="$(grep -c "^brew" "$brewfile_path" 2>/dev/null || echo 0)"
                    local _cask_count="$(grep -c "^cask" "$brewfile_path" 2>/dev/null || echo 0)"
                    local _mas_count="$(grep -c  "^mas"  "$brewfile_path" 2>/dev/null || echo 0)"
                    _hline "·" "$C_GRAY"
                    _stat_row "Taps"      "$_tap_count"   "$C_BLUE"
                    _stat_row "Formulae"  "$_brew_count"  "$C_YELLOW"
                    _stat_row "Casks"     "$_cask_count"  "$C_GREEN"
                    _stat_row "MAS apps"  "$_mas_count"   "$C_PURPLE_B"
                fi

                # ── Agents bundle contents ──
                if [[ -f "$agents_bundle" ]]; then
                    echo ""
                    echo -e "  ${C_CYAN_B}Agents bundle contents:${NC}  ${C_GRAY}($agents_bundle)${NC}"
                    echo ""
                    printf "  ${C_GRAY}%-36s  %-16s  %s${NC}\n" "Label" "Schedule" "Modules"
                    printf "  ${C_GRAY}%-36s  %-16s  %s${NC}\n" "────────────────────────────────────" "────────────────" "────────"
                    while IFS= read -r line; do
                        [[ "$line" != agent=* ]] && continue
                        local _vd="${line#agent=}"
                        local _vl="$(echo "$_vd" | tr '|' '\n' | grep "^label=" | cut -d= -f2-)"
                        local _vs="$(echo "$_vd" | tr '|' '\n' | grep "^schedule=" | cut -d= -f2-)"
                        local _vm="$(echo "$_vd" | tr '|' '\n' | grep "^modules=" | cut -d= -f2-)"
                        printf "  ${C_CYAN}${SYM_ARR}${NC}  ${C_WHITE}%-36s${NC}  ${C_GRAY}%-16s${NC}  ${C_CYAN_B}%s${NC}\n" "$_vl" "$_vs" "$_vm"
                    done < "$agents_bundle"
                fi
                ;;

            6)  # DELETE — select by number from the inventory shown in [5]
                if (( BREW_MANAGER_DRY_RUN )); then
                    _info "Dry-run — nothing deleted"
                else
                    # Build inventory same as [5]
                    declare -a _di_items=()
                    declare -a _di_labels=()
                    declare -a _di_paths=()
                    if [[ -f "$brewfile_path" ]]; then
                        _di_items+=("brewfile")
                        _di_labels+=("Brewfile")
                        _di_paths+=("$brewfile_path")
                    fi
                    if [[ -f "$brewfile_lock" ]]; then
                        _di_items+=("lock")
                        _di_labels+=("Brewfile.lock.json")
                        _di_paths+=("$brewfile_lock")
                    fi
                    if [[ -f "$agents_bundle" ]]; then
                        _di_items+=("agents")
                        _di_labels+=("Agents bundle")
                        _di_paths+=("$agents_bundle")
                    fi

                    if (( ${#_di_items[@]} == 0 )); then
                        _warn "No backup files to delete"
                    else
                        echo ""
                        echo -e "  ${C_WHITE}Select what to delete:${NC}"
                        echo ""
                        for _dii in {1..${#_di_items[@]}}; do
                            printf "  ${C_RED}[%s]${NC}  ${C_WHITE}%s${NC}\n" "$_dii" "${_di_labels[$_dii]}"
                        done
                        printf "  ${C_RED}[all]${NC} ${C_WHITE}%s${NC}\n" "Delete all backup files"
                        printf "  ${C_GRAY}[n]${NC}   ${C_WHITE}%s${NC}\n" "Cancel"
                        echo ""
                        printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[number, all, or n]${NC}: "
                        read -r del_choice

                        case "${del_choice:-n}" in
                            all|ALL)
                                for _dp in "${_di_paths[@]}"; do
                                    rm -f "$_dp" && _ok "Deleted: $(basename "$_dp")"
                                done
                                ;;
                            [0-9]*)
                                IFS=',' read -rA _del_nums <<< "$del_choice"
                                for _dn in "${_del_nums[@]}"; do
                                    _dn=$(echo "$_dn" | tr -d ' ')
                                    local _dp="${_di_paths[$_dn]}"
                                    local _dl="${_di_labels[$_dn]}"
                                    if [[ -n "$_dp" && -f "$_dp" ]]; then
                                        rm -f "$_dp" && _ok "Deleted: $_dl"
                                    else
                                        _warn "[$_dn] not found — skipped"
                                    fi
                                done
                                ;;
                            n|N|*) _info "Cancelled" ;;
                        esac
                    fi
                fi
                ;;

            n|N|*)
                _info "Skipped"
                break
                ;;
        esac
    done
}