#!/bin/zsh
# =============================================================================
# modules/mod_las_scheduler.sh — LaunchAgent scheduler
# Installs/manages macOS LaunchAgents that run brew-manager automatically.
# LaunchAgents run as the current user — no sudo needed.
# Configurations saved to agents/ directory for audit and modification.
# =============================================================================

_module_15() {
    _section "15" "LaunchAgent Scheduler"

    local label_base="com.m2ndlab.brew-manager"
    local plist_dir="$HOME/Library/LaunchAgents"
    local agents_dir="$BREW_MANAGER_SCRIPT_DIR/agents"
    mkdir -p "$agents_dir" "$plist_dir"

    # Scheduler is inherently interactive — skip whenever we cannot prompt
    # (--yes OR no usable stdin), so an agent never tries to manage agents.
    if (( BREW_MANAGER_YES || BREW_MANAGER_NONINTERACTIVE )); then
        _info "Scheduler module skipped in non-interactive mode"
        _info "Run brew_manager.sh manually to configure agents"
        return
    fi

    # ── Explanation ──
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}A LaunchAgent is a macOS-native scheduler built into the OS (launchd).${NC}"
    echo -e "  ${C_GRAY}It runs programs automatically on your schedule, as YOUR user — no sudo,${NC}"
    echo -e "  ${C_GRAY}no admin password. It starts at login and macOS keeps it active.${NC}"
    echo ""
    echo -e "  ${C_GRAY}Installing a brew-manager agent tells macOS to run brew_manager.sh${NC}"
    echo -e "  ${C_GRAY}automatically at the chosen time, even if you are not at your desk.${NC}"
    echo -e "  ${C_GRAY}Output goes to a dedicated log in logs/ for later review.${NC}"
    echo ""
    printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_GRAY}%-14s${NC}  %s\n" "1/2/3"  "Install weekly, daily, or custom schedule"
    printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_GRAY}%-14s${NC}  %s\n" "4"      "Modify schedule or modules without reinstalling"
    printf "  ${C_RED}${SYM_ERR}${NC}  ${C_GRAY}%-14s${NC}  %s\n"    "5"      "Remove agent — unloads from macOS and deletes conf"
    printf "  ${C_YELLOW}${SYM_LOCK}${NC}  ${C_GRAY}%-14s${NC}  %s\n" "6"      "Integrity check — finds agents deleted outside brew-manager"
    echo ""
    echo -e "  ${C_GRAY}Important: always remove agents via option [5] — deleting the .plist or${NC}"
    echo -e "  ${C_GRAY}.conf file manually leaves orphans. Use [6] to detect and fix them.${NC}"
    _hline "·" "$C_GRAY"

    # ── List existing agents ──
    _list_agents() {
        local _cfg_files
        setopt nullglob
        _cfg_files=("$agents_dir"/agent_*.conf)
        unsetopt nullglob

        if (( ${#_cfg_files[@]} == 0 )); then
            echo ""
            _info "No brew-manager agents configured"
            return 1
        fi

        echo ""
        echo -e "  ${C_CYAN_B}Configured agents:${NC}"
        echo ""
        printf "  ${C_GRAY}%-4s  %-28s  %-14s  %-14s  %-18s  %s${NC}\n" \
            "No." "Label" "Schedule" "Modules" "Created" "Status"
        printf "  ${C_GRAY}%-4s  %-28s  %-14s  %-14s  %-18s  %s${NC}\n" \
            "────" "────────────────────────────" "──────────────" "──────────────" "──────────────────" "──────"

        local _idx=1
        for cfg in "${_cfg_files[@]}"; do
            local _label="$(grep "^label=" "$cfg" | cut -d= -f2-)"
            local _schedule="$(grep "^schedule=" "$cfg" | cut -d= -f2-)"
            local _modules="$(grep "^modules=" "$cfg" | cut -d= -f2-)"
            local _created="$(grep "^created=" "$cfg" | cut -d= -f2-)"
            local _plist="$plist_dir/${_label}.plist"

            local _status_str="loaded"
            local _status_color="$C_YELLOW"
            if [[ ! -f "$_plist" ]]; then
                _status_str="missing"
                _status_color="$C_RED"
            elif launchctl list "$_label" &>/dev/null; then
                _status_str="active ✓"
                _status_color="$C_GREEN_B"
            fi

            printf "  ${C_CYAN_B}[%s]${NC}  ${C_WHITE}%-28s${NC}  ${C_GRAY}%-14s${NC}  ${C_CYAN}%-14s${NC}  ${C_GRAY}%-18s${NC}  ${_status_color}%s${NC}\n" \
                "$_idx" "$_label" "$_schedule" "$_modules" "$_created" "$_status_str"
            (( _idx++ ))
        done
        echo ""
        return 0
    }

    # ── Save agent config and log ──
    _save_agent_config() {
        local label="$1" schedule="$2" modules="$3" plist_path="$4"
        local cfg_file="$agents_dir/agent_${label}.conf"
        local ts="$(date '+%Y-%m-%d %H:%M')"
        cat > "$cfg_file" << EOF
# brew-manager LaunchAgent configuration
# Generated: $ts
label=$label
schedule=$schedule
modules=$modules
plist=$plist_path
created=$ts
EOF
        local log_file="$agents_dir/agents_activity.log"
        printf "[%s] INSTALLED  label=%-36s  schedule=%-16s  modules=%s\n" \
            "$ts" "$label" "$schedule" "$modules" >> "$log_file"
    }

    _log_agent_event() {
        local event="$1" label="$2" note="${3:-}"
        local ts="$(date '+%Y-%m-%d %H:%M')"
        printf "[%s] %-10s  label=%-36s  %s\n" \
            "$ts" "$event" "$label" "$note" >> "$agents_dir/agents_activity.log"
    }

    # ── Modules normalizer for the re-register CONF/listing only. The
    # authoritative gate that decides what reaches a PLIST is _install_agent,
    # which validates via _selection_is_valid and REFUSES an invalid value (no
    # 'go' substitution). Here — adopting an orphan plist into tracking, where the
    # plist is NOT rewritten — an unrecoverable value is displayed as 'go' as a
    # placeholder. NOTE: this can make the conf listing disagree with a mangled
    # plist's real argv (tracked as a known divergence in STATE); it never affects
    # what an agent EXECUTES. Validity uses the single source of truth,
    # _selection_is_valid (lib/selection.sh) ──
    _sanitize_agent_modules() {
        local m="$1"
        if _selection_is_valid "$m"; then
            printf '%s\n' "$m"
        else
            printf '%s\n' "go"
        fi
    }

    # ── Weekday (0=Sun … 6=Sat, launchd convention) → day name.
    # zsh arrays are 1-based: index with weekday+1, NEVER with the raw value ──
    _weekday_name() {
        local _wd_names=(Sun Mon Tue Wed Thu Fri Sat)
        printf '%s\n' "${_wd_names[$(( $1 + 1 ))]}"
    }

    # ── First <integer> value for a plist key: handles both same-line
    # (<key>Weekday</key><integer>N</integer>) and key-then-value-line layouts.
    # Anchored on <key>…</key> so decoy <string> content can't match. A bare
    # 'grep -Ax | tr -cd 0-9' concatenates neighbouring integers ('2'+'9'→'29')
    # — that was the root of the mangled re-register data ──
    _plist_int() {
        grep -A1 "<key>$1</key>" "$2" 2>/dev/null | grep -oE '<integer>[0-9]+</integer>' \
            | head -1 | tr -cd '0-9'
    }

    # ── Number of Weekday entries in a plist: >1 means a multi-interval agent
    # that single-day tooling (re-register, migration) must NOT rewrite —
    # collapsing it would silently drop firing days ──
    _plist_weekday_count() {
        grep -c "<key>Weekday</key>" "$1" 2>/dev/null
    }

    # ── Install helper ──
    _install_agent() {
        local label="$1" plist_path="$2"
        local weekday="$3" hour="$4" minute="$5" modules="$6"

        # Weekday must be 0-6 or empty (daily), hour 0-23, minute 0-59:
        # garbage here becomes a plist that launchd rejects or never fires
        if [[ -n "$weekday" && ! "$weekday" =~ ^[0-6]$ ]]; then
            _err "Invalid weekday '$weekday' (0=Sun … 6=Sat, empty=daily) — agent not installed"
            return 1
        fi
        if [[ ! "$hour" =~ ^([0-9]|1[0-9]|2[0-3])$ ]]; then
            _err "Invalid hour '$hour' (0-23) — agent not installed"
            return 1
        fi
        if [[ ! "$minute" =~ ^([0-9]|[1-5][0-9])$ ]]; then
            _err "Invalid minute '$minute' (0-59) — agent not installed"
            return 1
        fi
        # REFUSE an invalid selection — do NOT substitute 'go'. Falling back to
        # 'go' would silently turn a typo (or a mangled legacy value on the
        # migration path) into the FULL sequence, including the destructive
        # mod_05 cleanup, running unattended under --yes. Validated against the
        # same _resolve_cli the agent run uses, so what installs is what runs.
        if ! _selection_is_valid "$modules"; then
            _err "Modules value '$modules' is not a valid selection — agent not installed"
            _err "Use 'go', module ids 0-13, or a named module (log/bk/las/mas)"
            return 1
        fi

        if (( BREW_MANAGER_DRY_RUN )); then
            _info "Dry-run — would install LaunchAgent: $label"
            return
        fi

        local cal_block
        if [[ -n "$weekday" ]]; then
            cal_block="        <dict>
            <key>Weekday</key><integer>${weekday}</integer>
            <key>Hour</key><integer>${hour}</integer>
            <key>Minute</key><integer>${minute}</integer>
        </dict>"
        else
            cal_block="        <dict>
            <key>Hour</key><integer>${hour}</integer>
            <key>Minute</key><integer>${minute}</integer>
        </dict>"
        fi

        local log_out="$BREW_MANAGER_SCRIPT_DIR/logs/agent_stdout_${label}.log"
        local log_err="$BREW_MANAGER_SCRIPT_DIR/logs/agent_stderr_${label}.log"

        cat > "$plist_path" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${label}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>${BREW_MANAGER_SCRIPT_DIR}/brew_manager.sh</string>
        <string>${modules}</string>
        <string>--yes</string>
    </array>
    <key>StartCalendarInterval</key>
${cal_block}
    <key>StandardOutPath</key>
    <string>${log_out}</string>
    <key>StandardErrorPath</key>
    <string>${log_err}</string>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
PLIST_EOF

        launchctl unload "$plist_path" 2>/dev/null
        if launchctl load "$plist_path" 2>/dev/null; then
            local _schedule
            if [[ -n "$weekday" ]]; then
                _schedule="$(_weekday_name "$weekday") ${hour}:$(printf '%02d' $minute)"
            else
                _schedule="daily ${hour}:$(printf '%02d' $minute)"
            fi

            _save_agent_config "$label" "$_schedule" "$modules" "$plist_path"

            echo ""
            _ok "LaunchAgent installed and active"
            echo ""
            _stat_row "Label"      "$label"                                   "$C_WHITE"
            _stat_row "Schedule"   "$_schedule"                               "$C_CYAN_B"
            _stat_row "Modules"    "$modules"                                 "$C_WHITE"
            _stat_row "Plist"      "$plist_path"                              "$C_GRAY"
            _stat_row "Stdout log" "$log_out"                                 "$C_GRAY"
            _stat_row "Config"     "$agents_dir/agent_${label}.conf"          "$C_GRAY"
        else
            _err "Failed to load LaunchAgent — check plist syntax"
            _log_agent_event "FAILED" "$label"
            return 1
        fi
    }

    # ── Main menu loop ──
    while true; do
        _list_agents
        echo -e "  ${C_WHITE}What do you want to do?${NC}"
        echo ""
        printf "  ${C_GREEN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[1]" "Install weekly"  "Every Sunday at 09:00 — runs go (all modules)"
        printf "  ${C_CYAN_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[2]" "Install daily"   "Every day at 09:00 — runs go (all modules)"
        printf "  ${C_PURPLE_B}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[3]" "Custom agent"    "Choose name, day, time and modules"
        printf "  ${C_YELLOW}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[4]" "Modify agent"    "Change schedule or modules without recreating"
        printf "  ${C_RED}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[5]" "Remove agent"    "Unload and delete a configured agent"
        printf "  ${C_YELLOW}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[6]" "Integrity check" "Find agents deleted outside brew-manager"
        printf "  ${C_GRAY}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[v]" "View activity"   "Show agents install/modify/remove history"
        # [c] always shown — behavior depends on whether agents exist
        setopt nullglob
        local _chk_cfgs=("$agents_dir"/agent_*.conf)
        unsetopt nullglob
        if (( ${#_chk_cfgs[@]} == 0 )); then
            printf "  ${C_RED}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
                "[c]" "Clear logs"     "Delete all agent logs (no agents installed)"
        else
            printf "  ${C_GRAY}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
                "[c]" "Clear logs"     "Not available — remove all agents first"
        fi
        printf "  ${C_GRAY}%-4s${NC}  ${C_WHITE}%-16s${NC}  ${C_GRAY}%s${NC}\n" \
            "[n]" "Exit"            "Leave this module"
        echo ""
        printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[default: n]${NC}: "
        read -r sched_choice

        case "${sched_choice:-n}" in

            1)
                local _label="${label_base}.weekly"
                local _plist="$plist_dir/${_label}.plist"
                local _cfg_check="$agents_dir/agent_${_label}.conf"
                if [[ -f "$_cfg_check" ]]; then
                    _warn "Agent 'weekly' already exists — use [4] Modify to change it"
                else
                    _install_agent "$_label" "$_plist" "0" "9" "0" "go"
                fi
                ;;

            2)
                local _label="${label_base}.daily"
                local _plist="$plist_dir/${_label}.plist"
                local _cfg_check="$agents_dir/agent_${_label}.conf"
                if [[ -f "$_cfg_check" ]]; then
                    _warn "Agent 'daily' already exists — use [4] Modify to change it"
                else
                    _install_agent "$_label" "$_plist" "" "9" "0" "go"
                fi
                ;;

            3)
                echo ""
                echo -e "  ${C_CYAN_B}Custom agent:${NC}"
                echo ""
                while true; do
                    printf "  ${C_CYAN}${SYM_ARR}${NC}  Name suffix ${C_GRAY}(e.g. 'weekly', 'nightly', 'work')${NC}: "
                    read -r _suffix
                    _suffix="${_suffix:-custom}"
                    # The suffix lands inside the plist XML and in filenames:
                    # restrict it to a safe shape
                    if [[ ! "$_suffix" =~ ^[A-Za-z0-9._-]+$ ]]; then
                        _warn "Suffix may only contain letters, digits, dot, dash, underscore"
                        continue
                    fi
                    local _label="${label_base}.${_suffix}"
                    local _plist="$plist_dir/${_label}.plist"
                    local _cfg_check="$agents_dir/agent_${_label}.conf"
                    if [[ -f "$_cfg_check" ]]; then
                        _warn "Agent '${_suffix}' already exists — choose a different name"
                    else
                        break
                    fi
                done
                printf "  ${C_CYAN}${SYM_ARR}${NC}  Weekday ${C_GRAY}[0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat, empty=every day]${NC}: "
                read -r _wd
                printf "  ${C_CYAN}${SYM_ARR}${NC}  Hour ${C_GRAY}[0-23, default: 9]${NC}: "
                read -r _hr
                printf "  ${C_CYAN}${SYM_ARR}${NC}  Minute ${C_GRAY}[0-59, default: 0]${NC}: "
                read -r _mn
                printf "  ${C_CYAN}${SYM_ARR}${NC}  Modules ${C_GRAY}[e.g. go or 1,2,4,5, default: go]${NC}: "
                read -r _mods
                _install_agent "$_label" "$_plist" \
                    "${_wd:-}" "${_hr:-9}" "${_mn:-0}" "${_mods:-go}"
                ;;

            4)
                local _cfg_files
                setopt nullglob
                _cfg_files=("$agents_dir"/agent_*.conf)
                unsetopt nullglob
                if (( ${#_cfg_files[@]} == 0 )); then
                    _warn "No agents to modify — install one first"
                    continue
                fi
                echo ""
                printf "  ${C_CYAN}${SYM_ARR}${NC}  Agent number to modify: "
                read -r _midx
                # zsh arrays are 1-based: the [N] listed IS the index — the old
                # N-1 made [1] invalid and [2] modify the WRONG agent
                [[ "$_midx" =~ ^[0-9]+$ ]] || { _warn "Invalid selection"; continue; }
                local _cfg="${_cfg_files[$_midx]}"
                if [[ ! -f "$_cfg" ]]; then _warn "Invalid selection"; continue; fi
                local _label="$(grep "^label=" "$_cfg" | cut -d= -f2-)"
                local _cur_modules="$(grep "^modules=" "$_cfg" | cut -d= -f2-)"
                local _cur_schedule="$(grep "^schedule=" "$_cfg" | cut -d= -f2-)"
                local _plist="$plist_dir/${_label}.plist"
                echo ""
                echo -e "  ${C_GRAY}Current schedule: ${C_WHITE}${_cur_schedule}${NC}  modules: ${C_WHITE}${_cur_modules}${NC}"
                echo ""
                printf "  ${C_CYAN}${SYM_ARR}${NC}  New weekday ${C_GRAY}[0-6, empty=daily]${NC}: "
                read -r _wd
                printf "  ${C_CYAN}${SYM_ARR}${NC}  New hour ${C_GRAY}[0-23, default: 9]${NC}: "
                read -r _hr
                printf "  ${C_CYAN}${SYM_ARR}${NC}  New minute ${C_GRAY}[0-59, default: 0]${NC}: "
                read -r _mn
                printf "  ${C_CYAN}${SYM_ARR}${NC}  New modules ${C_GRAY}[Enter to keep: ${_cur_modules}]${NC}: "
                read -r _mods
                [[ -z "$_mods" ]] && _mods="$_cur_modules"
                # No rm of the old conf here: _save_agent_config overwrites the
                # same path on success, and if the install is rejected (invalid
                # input) or the load fails, the previous conf must survive.
                # The MODIFIED log line is also a write: skip it in dry-run
                (( ! BREW_MANAGER_DRY_RUN )) && \
                    _log_agent_event "MODIFIED" "$_label" "prev_schedule=${_cur_schedule} prev_modules=${_cur_modules}"
                _install_agent "$_label" "$_plist" \
                    "${_wd:-}" "${_hr:-9}" "${_mn:-0}" "$_mods"
                ;;

            5)
                setopt nullglob
                local _cfg_files=("$agents_dir"/agent_*.conf)
                unsetopt nullglob
                if (( ${#_cfg_files[@]} == 0 )); then _warn "No agents to remove"; continue; fi
                echo ""
                printf "  ${C_CYAN}${SYM_ARR}${NC}  Agent number(s) to remove ${C_GRAY}[e.g. 1 or 1,2,3 or all]${NC}: "
                read -r _ridx_raw
                # Build list of indices to remove
                declare -a _to_remove=()
                case "${_ridx_raw:-}" in
                    all|ALL)
                        for (( _ri=1; _ri<=${#_cfg_files[@]}; _ri++ )); do
                            _to_remove+=("$_ri")
                        done
                        ;;
                    *)
                        IFS=',' read -rA _ridx_parts <<< "$_ridx_raw"
                        for _rp in "${_ridx_parts[@]}"; do
                            _rp=$(echo "$_rp" | tr -d ' ')
                            [[ "$_rp" =~ ^[0-9]+$ ]] && _to_remove+=("$_rp")
                        done
                        ;;
                esac
                if (( ${#_to_remove[@]} == 0 )); then _warn "Invalid selection"; continue; fi
                if (( BREW_MANAGER_DRY_RUN )); then
                    _info "Dry-run — would remove ${#_to_remove[@]} agent(s)"
                    continue
                fi
                local _removed_count=0
                for _ri in "${_to_remove[@]}"; do
                    # 1-based index: the old N-1 REMOVED THE WRONG AGENT for
                    # any N >= 2 and rejected [1]
                    local _cfg="${_cfg_files[$_ri]}"
                    [[ ! -f "$_cfg" ]] && _warn "Agent [$_ri] not found — skipped" && continue
                    local _label="$(grep "^label=" "$_cfg" | cut -d= -f2-)"
                    local _plist="$plist_dir/${_label}.plist"
                    launchctl unload "$_plist" 2>/dev/null
                    rm -f "$_plist" "$_cfg"
                    _log_agent_event "REMOVED" "$_label"
                    _ok "Removed: $_label"
                    (( _removed_count++ ))
                done
                echo ""
                _stat_row "Agents removed" "$_removed_count" "$C_GREEN_B"
                ;;

            6)
                # ── Integrity check ──
                # Scans ~/Library/LaunchAgents for brew-manager plists not tracked
                # in agents/ conf files, and agents/ confs pointing to missing plists.
                local _plist_dir="$HOME/Library/LaunchAgents"
                local _label_prefix="com.m2ndlab.brew-manager"

                echo ""
                echo -e "  ${C_CYAN_B}Integrity check:${NC}"
                echo ""

                # 1. Find plists in ~/Library/LaunchAgents not tracked in agents/
                declare -a _orphan_plists=()
                setopt nullglob
                local _system_plists=("$_plist_dir"/${_label_prefix}.*.plist)
                unsetopt nullglob

                for _sp in "${_system_plists[@]}"; do
                    local _sp_label="$(basename "$_sp" .plist)"
                    local _sp_conf="$agents_dir/agent_${_sp_label}.conf"
                    if [[ ! -f "$_sp_conf" ]]; then
                        _orphan_plists+=("$_sp_label|$_sp")
                    fi
                done

                # 2. Find confs in agents/ pointing to missing plists
                declare -a _dangling_confs=()
                setopt nullglob
                local _all_confs=("$agents_dir"/agent_*.conf)
                unsetopt nullglob

                for _ac in "${_all_confs[@]}"; do
                    local _ac_label="$(grep "^label=" "$_ac" | cut -d= -f2-)"
                    local _ac_plist="$_plist_dir/${_ac_label}.plist"
                    if [[ ! -f "$_ac_plist" ]]; then
                        _dangling_confs+=("$_ac_label|$_ac")
                    fi
                done

                # 3. Find TRACKED pairs (conf + plist both present) with legacy or
                # corrupt data: modules mangled by the old tag-stripping ('--ye',
                # 'o' — flag-shaped values now make the agent exit 2 on every
                # run), or a conf day name that disagrees with the plist Weekday
                # (written shifted by the old 0-based day mapping)
                declare -a _legacy_pairs=()   # label|conf|plist|reason
                for _ac in "${_all_confs[@]}"; do
                    local _lp_label="$(grep "^label=" "$_ac" | cut -d= -f2-)"
                    local _lp_plist="$_plist_dir/${_lp_label}.plist"
                    [[ -f "$_lp_plist" ]] || continue
                    # Multi-day agents ('Mon+Wed+Fri' confs / multi-interval
                    # plists) are out of scope for single-day migration:
                    # flagging them would lead [r] to collapse real schedules
                    local _lp_cday_probe="$(grep "^schedule=" "$_ac" | cut -d= -f2- | awk '{print $1}')"
                    if [[ "$_lp_cday_probe" == *+* ]] || (( $(_plist_weekday_count "$_lp_plist") > 1 )); then
                        continue
                    fi
                    local _lp_reasons=""
                    # (i) conf modules corrupt / flag-shaped / empty
                    local _lp_cmods="$(grep "^modules=" "$_ac" | cut -d= -f2-)"
                    if [[ -z "$_lp_cmods" || "$_lp_cmods" == -* ]]; then
                        _lp_reasons+="conf modules '$_lp_cmods' invalid; "
                    fi
                    # (ii) plist argv modules flag-shaped (legacy re-register wrote
                    # the mangled value into ProgramArguments)
                    local _lp_pmods="$(grep -A1 "brew_manager.sh" "$_lp_plist" 2>/dev/null | tail -1 | sed -E 's/<[^>]*>//g' | tr -d ' \t')"
                    if [[ -z "$_lp_pmods" || "$_lp_pmods" == -* ]]; then
                        _lp_reasons+="plist modules '$_lp_pmods' invalid (agent exits 2 every run); "
                    fi
                    # (iii) conf day name vs plist Weekday integer
                    local _lp_pwd="$(_plist_int "Weekday" "$_lp_plist")"
                    [[ "$_lp_pwd" =~ ^[0-6]$ ]] || _lp_pwd=""
                    local _lp_cday="$(grep "^schedule=" "$_ac" | cut -d= -f2- | awk '{print $1}')"
                    if [[ -n "$_lp_pwd" && "$_lp_cday" != "daily" ]]; then
                        local _lp_expected="$(_weekday_name "$_lp_pwd")"
                        if [[ "$_lp_cday" != "$_lp_expected" ]]; then
                            _lp_reasons+="conf says '$_lp_cday' but plist fires on ${_lp_expected}; "
                        fi
                    elif [[ -z "$_lp_pwd" && "$_lp_cday" != "daily" ]]; then
                        _lp_reasons+="conf says '$_lp_cday' but plist is daily; "
                    fi
                    if [[ -n "$_lp_reasons" ]]; then
                        _legacy_pairs+=("$_lp_label|$_ac|$_lp_plist|$_lp_reasons")
                    fi
                done

                if (( ${#_orphan_plists[@]} == 0 && ${#_dangling_confs[@]} == 0 && ${#_legacy_pairs[@]} == 0 )); then
                    _ok "All agents are consistent — no orphans, missing plists or legacy data found"
                    continue
                fi

                # ── Orphan plists: active in macOS but not tracked by brew-manager ──
                if (( ${#_orphan_plists[@]} > 0 )); then
                    echo -e "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_WHITE}Agents active in macOS but missing from brew-manager tracking:${NC}"
                    echo ""
                    printf "  ${C_GRAY}%-4s  %-38s${NC}\n" "No." "Label"
                    printf "  ${C_GRAY}%-4s  %-38s${NC}\n" "────" "──────────────────────────────────────"
                    local _oi=1
                    for _op in "${_orphan_plists[@]}"; do
                        local _op_label="${_op%%|*}"
                        printf "  ${C_YELLOW}[%s]${NC}  ${C_WHITE}%s${NC}\n" "$_oi" "$_op_label"
                        (( _oi++ ))
                    done
                    echo ""
                    echo -e "  ${C_GRAY}These agents are running in macOS but brew-manager has no record of them.${NC}"
                    echo -e "  ${C_GRAY}They may have been installed by a previous version or another tool.${NC}"
                    echo ""

                    if (( ! BREW_MANAGER_DRY_RUN )); then
                        echo -e "  ${C_WHITE}What do you want to do with orphan plists?${NC}"
                        echo ""
                        printf "  ${C_GREEN_B}%-4s${NC}  ${C_WHITE}%s${NC}\n" "[r]" "Re-register them — create conf files so brew-manager tracks them"
                        printf "  ${C_RED}%-4s${NC}  ${C_WHITE}%s${NC}\n"    "[d]" "Remove them — unload and delete the plist files"
                        printf "  ${C_GRAY}%-4s${NC}  ${C_WHITE}%s${NC}\n"   "[s]" "Skip — leave them as is"
                        echo ""
                        printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[r/d/s, default: s]${NC}: "
                        read -r _orphan_choice

                        case "${_orphan_choice:-s}" in
                            r|R)
                                for _op in "${_orphan_plists[@]}"; do
                                    local _op_label="${_op%%|*}"
                                    local _op_plist="${_op##*|}"
                                    # Multi-interval plists can't be represented by a
                                    # single-day conf: writing one would lie about the
                                    # real schedule — leave them to manual handling
                                    if (( $(_plist_weekday_count "$_op_plist") > 1 )); then
                                        _warn "$_op_label fires on multiple weekdays — re-register it manually, skipped"
                                        continue
                                    fi
                                    # Extract schedule from plist (validated against
                                    # launchd ranges: out-of-range leftovers degrade
                                    # to defaults, not garbage)
                                    local _op_hour="$(_plist_int "Hour" "$_op_plist")"
                                    local _op_min="$(_plist_int "Minute" "$_op_plist")"
                                    local _op_wd="$(_plist_int "Weekday" "$_op_plist")"
                                    [[ "$_op_wd" =~ ^[0-6]$ ]] || _op_wd=""
                                    [[ "$_op_hour" =~ ^([0-9]|1[0-9]|2[0-3])$ ]] || _op_hour=""
                                    [[ "$_op_min" =~ ^([0-9]|[1-5][0-9])$ ]] || _op_min=""
                                    # Modules = the argv entry after brew_manager.sh.
                                    # Strip the XML tags with sed: the old tr -d set
                                    # deleted single characters and mangled the value
                                    # ('go'→'o', '--yes'→'--ye')
                                    local _op_mods="$(grep -A1 "brew_manager.sh" "$_op_plist" 2>/dev/null | tail -1 | sed -E 's/<[^>]*>//g' | tr -d ' \t')"
                                    _op_mods="$(_sanitize_agent_modules "$_op_mods")"

                                    local _op_schedule
                                    if [[ -n "$_op_wd" ]]; then
                                        _op_schedule="$(_weekday_name "$_op_wd") ${_op_hour:-9}:$(printf '%02d' ${_op_min:-0})"
                                    else
                                        _op_schedule="daily ${_op_hour:-9}:$(printf '%02d' ${_op_min:-0})"
                                    fi

                                    local _ts="$(date '+%Y-%m-%d %H:%M')"
                                    cat > "$agents_dir/agent_${_op_label}.conf" << EOF
# brew-manager LaunchAgent configuration
# Re-registered by integrity check: $_ts
label=$_op_label
schedule=$_op_schedule
modules=$_op_mods
plist=$_op_plist
created=$_ts
EOF
                                    _log_agent_event "REGISTERED" "$_op_label" "via integrity check"
                                    _ok "Re-registered: $_op_label"
                                done
                                ;;
                            d|D)
                                for _op in "${_orphan_plists[@]}"; do
                                    local _op_label="${_op%%|*}"
                                    local _op_plist="${_op##*|}"
                                    launchctl unload "$_op_plist" 2>/dev/null
                                    rm -f "$_op_plist"
                                    _log_agent_event "REMOVED" "$_op_label" "via integrity check cleanup"
                                    _ok "Removed: $_op_label"
                                done
                                ;;
                            *) _info "Orphan plists left unchanged" ;;
                        esac
                    fi
                fi

                # ── Dangling confs: tracked by brew-manager but plist missing ──
                if (( ${#_dangling_confs[@]} > 0 )); then
                    echo ""
                    echo -e "  ${C_RED}${SYM_ERR}${NC}  ${C_WHITE}Agents tracked by brew-manager but plist missing from macOS:${NC}"
                    echo ""
                    printf "  ${C_GRAY}%-4s  %-38s${NC}\n" "No." "Label"
                    printf "  ${C_GRAY}%-4s  %-38s${NC}\n" "────" "──────────────────────────────────────"
                    local _di=1
                    for _dc in "${_dangling_confs[@]}"; do
                        printf "  ${C_RED}[%s]${NC}  ${C_WHITE}%s${NC}\n" "$_di" "${_dc%%|*}"
                        (( _di++ ))
                    done
                    echo ""
                    echo -e "  ${C_GRAY}These confs exist in agents/ but the plist was deleted outside brew-manager.${NC}"
                    echo ""

                    if (( ! BREW_MANAGER_DRY_RUN )); then
                        echo -e "  ${C_WHITE}What do you want to do?${NC}"
                        echo ""
                        printf "  ${C_GREEN_B}%-4s${NC}  ${C_WHITE}%s${NC}\n" "[r]" "Recreate the plists and reload them in macOS"
                        printf "  ${C_RED}%-4s${NC}  ${C_WHITE}%s${NC}\n"    "[d]" "Delete the stale conf files from agents/"
                        printf "  ${C_GRAY}%-4s${NC}  ${C_WHITE}%s${NC}\n"   "[s]" "Skip — leave them as is"
                        echo ""
                        printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[r/d/s, default: s]${NC}: "
                        read -r _dangle_choice

                        case "${_dangle_choice:-s}" in
                            r|R)
                                for _dc in "${_dangling_confs[@]}"; do
                                    local _dc_label="${_dc%%|*}"
                                    local _dc_conf="${_dc##*|}"
                                    local _dc_schedule="$(grep "^schedule=" "$_dc_conf" | cut -d= -f2-)"
                                    local _dc_modules="$(grep "^modules=" "$_dc_conf" | cut -d= -f2-)"
                                    # Parse schedule into hour/minute/weekday
                                    local _dc_hour=9 _dc_min=0 _dc_wd=""
                                    if echo "$_dc_schedule" | grep -q "^daily"; then
                                        _dc_hour="$(echo "$_dc_schedule" | awk '{print $2}' | cut -d: -f1)"
                                        _dc_min="$(echo "$_dc_schedule" | awk '{print $2}' | cut -d: -f2)"
                                    else
                                        local _dc_dayname="$(echo "$_dc_schedule" | awk '{print $1}')"
                                        # Multi-day conf: recreating it single-day
                                        # would silently turn it into a DAILY agent
                                        # (fires 7x instead of 2x) — leave it alone
                                        if [[ "$_dc_dayname" == *+* ]]; then
                                            _warn "$_dc_label has a multi-day schedule ($_dc_schedule) — recreate it manually, skipped"
                                            continue
                                        fi
                                        _dc_hour="$(echo "$_dc_schedule" | awk '{print $2}' | cut -d: -f1)"
                                        _dc_min="$(echo "$_dc_schedule" | awk '{print $2}' | cut -d: -f2)"
                                        # zsh arrays are 1-based: _dmap[i] is day i-1
                                        # in launchd terms (old {0..6} loop shifted
                                        # every day by one and lost Saturday)
                                        local _dmap=(Sun Mon Tue Wed Thu Fri Sat)
                                        for _dmi in {1..7}; do
                                            [[ "${_dmap[$_dmi]}" == "$_dc_dayname" ]] && _dc_wd="$(( _dmi - 1 ))" && break
                                        done
                                    fi
                                    _install_agent "$_dc_label" "$_plist_dir/${_dc_label}.plist"                                         "$_dc_wd" "$_dc_hour" "$_dc_min" "$_dc_modules"
                                done
                                ;;
                            d|D)
                                for _dc in "${_dangling_confs[@]}"; do
                                    local _dc_conf="${_dc##*|}"
                                    local _dc_label="${_dc%%|*}"
                                    rm -f "$_dc_conf"
                                    _log_agent_event "CLEANED" "$_dc_label" "stale conf removed by integrity check"
                                    _ok "Removed stale conf: $(basename "$_dc_conf")"
                                done
                                ;;
                            *) _info "Dangling confs left unchanged" ;;
                        esac
                    fi
                fi

                # ── Legacy tracked agents: conf+plist present but data corrupt/shifted ──
                if (( ${#_legacy_pairs[@]} > 0 )); then
                    echo ""
                    echo -e "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_WHITE}Tracked agents with legacy or corrupt data (migration available):${NC}"
                    echo ""
                    local _li=1
                    for _lp in "${_legacy_pairs[@]}"; do
                        local _lp_label="${_lp%%|*}"
                        local _lp_reason="${_lp##*|}"
                        printf "  ${C_YELLOW}[%s]${NC}  ${C_WHITE}%-38s${NC}\n" "$_li" "$_lp_label"
                        printf "        ${C_GRAY}%s${NC}\n" "$_lp_reason"
                        (( _li++ ))
                    done
                    echo ""
                    echo -e "  ${C_GRAY}Written by older versions: the day mapping was shifted and the modules${NC}"
                    echo -e "  ${C_GRAY}value could be mangled ('--ye'), which now makes the agent exit 2 on${NC}"
                    echo -e "  ${C_GRAY}every scheduled run. Migration regenerates conf+plist from the plist's${NC}"
                    echo -e "  ${C_GRAY}own schedule (source of truth) with a sanitized modules value.${NC}"
                    echo ""

                    if (( ! BREW_MANAGER_DRY_RUN )); then
                        echo -e "  ${C_WHITE}Migrate these agents now?${NC}"
                        echo ""
                        printf "  ${C_GREEN_B}%-4s${NC}  ${C_WHITE}%s${NC}\n" "[r]" "Repair — regenerate conf and plist, reload in launchd"
                        printf "  ${C_GRAY}%-4s${NC}  ${C_WHITE}%s${NC}\n"   "[s]" "Skip — leave them as is"
                        echo ""
                        printf "  ${C_CYAN}${SYM_ARR}${NC}  Choice ${C_GRAY}[r/s, default: s]${NC}: "
                        read -r _legacy_choice

                        case "${_legacy_choice:-s}" in
                            r|R)
                                for _lp in "${_legacy_pairs[@]}"; do
                                    local _lp_label="${_lp%%|*}"
                                    local _lp_rest="${_lp#*|}"
                                    local _lp_conf="${_lp_rest%%|*}"
                                    local _lp_plist="$_plist_dir/${_lp_label}.plist"
                                    # Source of truth: the plist launchd actually fires
                                    local _mg_hour="$(_plist_int "Hour" "$_lp_plist")"
                                    local _mg_min="$(_plist_int "Minute" "$_lp_plist")"
                                    local _mg_wd="$(_plist_int "Weekday" "$_lp_plist")"
                                    [[ "$_mg_wd" =~ ^[0-6]$ ]] || _mg_wd=""
                                    [[ "$_mg_hour" =~ ^([0-9]|1[0-9]|2[0-3])$ ]] || _mg_hour="9"
                                    [[ "$_mg_min" =~ ^([0-9]|[1-5][0-9])$ ]] || _mg_min="0"
                                    # Modules: prefer a valid plist argv value, then a
                                    # valid conf value, else fall back to 'go'
                                    local _mg_mods="$(grep -A1 "brew_manager.sh" "$_lp_plist" 2>/dev/null | tail -1 | sed -E 's/<[^>]*>//g' | tr -d ' \t')"
                                    if [[ -z "$_mg_mods" || "$_mg_mods" == -* ]]; then
                                        _mg_mods="$(grep "^modules=" "$_lp_conf" | cut -d= -f2-)"
                                    fi
                                    # Pass the extracted value RAW: _install_agent
                                    # validates it and REFUSES if invalid, so a
                                    # doubly-mangled legacy agent fails migration
                                    # loudly instead of being silently rewritten to
                                    # the destructive 'go' sequence.
                                    # Log MIGRATED only on success: a failed reload
                                    # must not be recorded as a repaired agent
                                    if _install_agent "$_lp_label" "$_lp_plist" \
                                        "$_mg_wd" "$_mg_hour" "$_mg_min" "$_mg_mods"; then
                                        _log_agent_event "MIGRATED" "$_lp_label" "legacy data repaired by integrity check"
                                    else
                                        _warn "Migration failed for $_lp_label — see messages above"
                                    fi
                                done
                                ;;
                            *) _info "Legacy agents left unchanged" ;;
                        esac
                    fi
                fi
                ;;

            v|V)
                local _log="$agents_dir/agents_activity.log"
                echo ""
                if [[ -f "$_log" ]]; then
                    echo -e "  ${C_CYAN_B}Agents activity log:${NC}"
                    echo ""
                    while IFS= read -r line; do
                        if echo "$line" | grep -q "INSTALLED"; then
                            echo -e "  ${C_GREEN_B}${line}${NC}"
                        elif echo "$line" | grep -q "REMOVED"; then
                            echo -e "  ${C_RED}${line}${NC}"
                        elif echo "$line" | grep -q "MODIFIED"; then
                            echo -e "  ${C_YELLOW}${line}${NC}"
                        elif echo "$line" | grep -q "FAILED"; then
                            echo -e "  ${C_RED}${line}${NC}"
                        else
                            echo -e "  ${C_GRAY}${line}${NC}"
                        fi
                    done < "$_log"
                else
                    _info "No activity yet — install an agent first"
                fi
                echo ""
                ;;

            c|C)
                setopt nullglob
                local _del_cfgs=("$agents_dir"/agent_*.conf)
                unsetopt nullglob
                if (( ${#_del_cfgs[@]} > 0 )); then
                    _warn "Cannot clear logs while agents are installed"
                    _info "Remove all agents first with option [5], then clear logs"
                else
                    # Delete activity log + all stdout/stderr agent logs
                    local _deleted=0
                    local _activity_log="$agents_dir/agents_activity.log"
                    setopt nullglob
                    local _agent_logs=("$BREW_MANAGER_SCRIPT_DIR/logs"/agent_*.log)
                    unsetopt nullglob
                    [[ -f "$_activity_log" ]] && rm -f "$_activity_log" && (( _deleted++ ))
                    for _al in "${_agent_logs[@]}"; do
                        rm -f "$_al" && (( _deleted++ ))
                    done
                    if (( _deleted > 0 )); then
                        _ok "$_deleted log file(s) deleted"
                    else
                        _info "No agent logs found to delete"
                    fi
                fi
                ;;

            n|N|*)
                _info "Exiting scheduler module"
                break
                ;;
        esac
    done
}