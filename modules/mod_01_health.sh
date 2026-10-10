#!/bin/zsh
# =============================================================================
# modules/mod_01_health.sh — Homebrew system health check
# =============================================================================

# _m01_dev_mode_state — Homebrew's developer mode, read READ-ONLY. Prints one
# word: off | setting | pinned | env | unknown.
# `brew developer state` is a regular command (cmd/developer.rb, not dev-cmd/),
# so running it never turns developer mode on; it only prints (checked on
# Homebrew 6.0.21 and 7.0.8 — the same source — with Homebrew's .git/config
# untouched). Its exit status is always 0, so the FIRST LINE is matched:
#   "Developer mode is disabled."                           → off
#   "... enabled because HOMEBREW_DEVELOPER is set."        → env (the user's
#        environment: brew-manager reports it and never touches it)
#   "... enabled because a developer command or `brew developer on` was run."
#                                                           → setting (the
#        `devcmdrun` key in Homebrew's repository, which `brew developer off`
#        removes) — or "pinned" when its second line says HOMEBREW_UPDATE_TO_TAG
#        keeps `brew update` on the stable tag anyway
# HOMEBREW_DEV_CMD_RUN in the environment is "env" too, before asking: Homebrew
# never unsets it and `brew update` then skips the stable tag, while `state`
# reads only the git config and would say "disabled" (gate finding).
# Anything else — a failed call, a message reworded by a later Homebrew — is
# "unknown", and nothing is offered on it: a guess must never lead to a change.
_m01_dev_mode_state() {
    [[ -n "$HOMEBREW_DEV_CMD_RUN" ]] && { print -r -- env; return 0; }
    local _out _first
    _out="$(brew developer state 2>/dev/null)" || { print -r -- unknown; return 0; }
    _first="${_out%%$'\n'*}"
    case "$_first" in
        "Developer mode is disabled."*)                           print -r -- off ;;
        "Developer mode is enabled because"*HOMEBREW_DEVELOPER*)  print -r -- env ;;
        "Developer mode is enabled because a developer command"*)
            if [[ "$_out" == *HOMEBREW_UPDATE_TO_TAG* ]]; then print -r -- pinned
            else print -r -- setting; fi ;;
        *)                                                        print -r -- unknown ;;
    esac
}

# _m01_off_row <homebrew version> — the row for developer mode OFF. Green only when
# Homebrew is on a release (a plain X.Y.Z): with the setting off, Homebrew can
# still sit on a main-branch commit — after a failed `brew update`, or with a
# remote that has no tags — and then the row says so and advises `brew update`.
# Reported only: no action is taken from here.
_m01_off_row() {
    if [[ "$1" == <->.<->.<-> ]]; then
        printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_WHITE}%-30s${NC}  ${C_GRAY}%s${NC}\n" \
            "Developer mode" "off — Homebrew $1, a stable release"
    else
        printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-30s${NC}  ${C_GRAY}%s${NC}\n" \
            "Developer mode" "off, but Homebrew is at ${1:-an unknown version}, not a release — run brew update"
    fi
}

# _m01_developer_mode [<homebrew version>] — report Homebrew's developer mode in the
# system checks and, when brew-manager can undo it, offer to. With developer mode
# on, `brew update` follows Homebrew's main branch instead of its stable releases
# (STATE #30: this tool itself used to turn it on).
# Homebrew's configuration belongs to the user (CLAUDE.md, IMP-031): the undo is
# shown first and runs only after a confirmation — `_ask_danger` with default `y`,
# so an explicit --yes proceeds, Enter at the prompt declines, and a run with no
# terminal and no --yes declines — and never under --dry-run, which previews it.
# The undo is `brew developer off` (it removes the devcmdrun setting), then `brew
# update`, which without developer mode checks Homebrew out at its latest release
# tag (Homebrew's cmd/update.sh) — possibly an OLDER commit than the main-branch
# one it is on — and stashes any local change in Homebrew's repository without
# restoring it; both are shown before the confirmation. Each status is read: a
# failed `off` stops before the update. Developer mode from the environment
# (HOMEBREW_DEVELOPER, HOMEBREW_DEV_CMD_RUN) is only reported — the environment is
# the user's — and so is an unreadable state. brew output is relayed with printf
# %s, never echoed (CLAUDE.md). The version argument saves a brew call when the
# caller already has it.
_m01_developer_mode() {
    local _state _line _rc _ver="$1" _repo _why _dirty=0
    _state="$(_m01_dev_mode_state)"
    case "$_state" in
        off)
            [[ -n "$_ver" ]] || _ver="$(brew --version 2>/dev/null | head -1 | awk '{print $2}')"
            _m01_off_row "$_ver"
            return 0 ;;
        unknown)
            printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-30s${NC}  ${C_GRAY}%s${NC}\n" \
                "Developer mode" "could not be read (brew developer state)"
            return 0 ;;
        env)
            if [[ -n "$HOMEBREW_DEVELOPER" ]]; then _why=HOMEBREW_DEVELOPER; else _why=HOMEBREW_DEV_CMD_RUN; fi
            printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-30s${NC}  ${C_GRAY}%s${NC}\n" \
                "Developer mode" "ON — $_why is set in your environment"
            _info "brew update follows Homebrew's main branch, not its stable releases."
            _info "$_why comes from your environment, which brew-manager does not change:"
            _info "remove it from your shell profile to turn developer mode off."
            # Homebrew names the variable first, so the setting may be on as well:
            # ask the same read-only command without the variables.
            if [[ "$(env -u HOMEBREW_DEVELOPER -u HOMEBREW_DEV_CMD_RUN brew developer state 2>/dev/null | head -1)" \
                  == "Developer mode is enabled because a developer command"* ]]; then
                _info "The developer-mode setting is on as well: after that, run module 1 again to turn it off."
            fi
            return 0 ;;
    esac

    printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-30s${NC}  ${C_GRAY}%s${NC}\n" \
        "Developer mode" "ON — set by a developer command or 'brew developer on'"
    if [[ "$_state" == pinned ]]; then
        _info "brew update still follows stable releases here (HOMEBREW_UPDATE_TO_TAG is set); other developer behaviour is on."
    else
        _info "brew update follows Homebrew's main branch instead of its stable releases."
    fi
    # What `brew update` will meet, read-only: a local change in Homebrew's
    # repository is stashed and, for a non-developer, not restored.
    [[ -n "$_ver" ]] || _ver="$(brew --version 2>/dev/null | head -1 | awk '{print $2}')"
    _repo="$(brew --repository 2>/dev/null)"
    [[ -n "$_repo" && -n "$(git -C "$_repo" status --untracked-files=all --porcelain 2>/dev/null | head -1)" ]] && _dirty=1
    if (( BREW_MANAGER_DRY_RUN )); then
        _info "Dry-run — would run: brew developer off, then brew update (back to the latest stable release)."
        (( _dirty )) && _info "Homebrew's repository has local changes: brew update would stash them and not restore them."
        return 0
    fi
    typeset -a _details=(
        "From: Homebrew ${_ver:-?} — to its latest release tag (it can be older than a main-branch commit)"
        "Runs: brew developer off  (removes the developer-mode setting)"
        "Then: brew update"
    )
    (( _dirty )) && _details+=("Homebrew's repository has local changes: brew update stashes them and does not restore them")
    if ! _ask_danger "Restore Homebrew's stable releases" \
            "Turn developer mode off and update Homebrew to its latest stable release?" "y" \
            "${_details[@]}"; then
        _info "Developer mode left on. To restore it by hand: brew developer off, then brew update"
        return 0
    fi

    brew developer off 2>&1 | while IFS= read -r _line; do printf '    %s\n' "$_line"; done
    _rc=${pipestatus[1]}
    if (( _rc != 0 )); then
        _err "brew developer off failed (exit status $_rc) — brew update was not run."
        return 0
    fi
    _info "Updating Homebrew to its latest stable release"
    brew update 2>&1 | while IFS= read -r _line; do printf '    %s\n' "$_line"; done
    _rc=${pipestatus[1]}
    if (( _rc != 0 )); then
        _err "brew update failed (exit status $_rc) — developer mode is off; run brew update again later."
        return 0
    fi

    _state="$(_m01_dev_mode_state)"
    _ver="$(brew --version 2>/dev/null | head -1 | awk '{print $2}')"
    if [[ "$_state" == off ]]; then
        _m01_off_row "$_ver"
    else
        printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-30s${NC}  ${C_GRAY}%s${NC}\n" \
            "Developer mode" "still reads '$_state' after the restore — check brew developer state"
    fi
    return 0
}

_module_1() {
    _section "1" "Homebrew System Health"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    _about_risk "1"
    echo ""
    echo -e "  ${C_GRAY}Runs a full diagnostic of your Homebrew installation. Checks:${NC}"
    echo ""
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Homebrew version"    "Current version and the date of Homebrew's code"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Xcode CLI Tools"     "Required for building formulae from source"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Prefix permissions"  "Checks that brew can write to its install directory"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Disk space"          "Free space on the volume containing brew prefix"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Developer mode"      "Off keeps brew update on stable releases; offers to turn it off"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Taps"                "Lists active formula repositories"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "brew doctor"         "Official Homebrew diagnostics — flags known issues"
    echo ""
    echo -e "  ${C_GRAY}brew doctor checks PATH, symlinks, permissions, and known problem patterns.${NC}"
    echo -e "  ${C_GRAY}Warnings are informational — they rarely block normal usage.${NC}"
    _hline "·" "$C_GRAY"

    echo ""
    local _brew_ver _brew_prefix _brew_repo _macos_ver _arch _ruby_ver _code_date
    _brew_ver="$(brew --version 2>/dev/null | head -1 | awk '{print $2}')"
    _brew_prefix="$(brew --prefix 2>/dev/null)"
    _brew_repo="$(brew --repository 2>/dev/null)"
    _macos_ver="$(sw_vers -productVersion 2>/dev/null)"
    _arch="$(uname -m)"
    # NOTE: never `brew ruby` — it is a Homebrew DEVELOPER command, and running one
    # turns Homebrew's developer mode on (`brew update` then follows Homebrew's
    # main branch instead of its releases). This line did exactly that from v1.1.0
    # on, even under --dry-run (STATE #30); `brew config` is a regular command and
    # reports the same Ruby. tests/test_homebrew_developer.zsh keeps developer
    # commands out of the code.
    _ruby_ver="$(brew config 2>/dev/null | awk -F': ' '/^Homebrew Ruby:/ {split($2, a, " "); print a[1]; exit}')"
    [[ -n "$_ruby_ver" ]] || _ruby_ver="n/a"
    # The date of Homebrew's own code (its repository's last commit: the release
    # date on a stable tag). Not the package index: since Homebrew 4 that comes
    # from the JSON API, so the old "Last DB update" label was wrong.
    _code_date="$(cd "$_brew_repo" 2>/dev/null && git log -1 --format='%ar' 2>/dev/null)"
    [[ -n "$_code_date" ]] || _code_date="n/a"
    _cask_count="$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')"
    _formula_count="$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')"

    _hline "·" "$C_CYAN"
    printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%-26s${NC}  ${C_CYAN_B}%-20s${NC}  ${C_WHITE}%s${NC}\n" \
        "Homebrew" "$_brew_ver" "Prefix" "$_brew_prefix"
    printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%-26s${NC}  ${C_CYAN_B}%-20s${NC}  ${C_WHITE}%s${NC}\n" \
        "macOS" "$_macos_ver" "Arch" "$_arch"
    printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%-26s${NC}  ${C_CYAN_B}%-20s${NC}  ${C_WHITE}%s${NC}\n" \
        "Homebrew code dated" "$_code_date" "Ruby (internal)" "$_ruby_ver"
    printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%-26s${NC}  ${C_CYAN_B}%-20s${NC}  ${C_WHITE}%s${NC}\n" \
        "Repository (core+cask)" "API JSON" "Installed casks" "$_cask_count"
    printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%s${NC}\n" \
        "Installed formulae" "$_formula_count"
    _hline "·" "$C_CYAN"

    echo ""
    echo -e "  ${C_CYAN_B}System checks:${NC}"
    echo ""

    if xcode-select -p &>/dev/null; then
        _xcode_path="$(xcode-select -p 2>/dev/null)"
        printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_WHITE}%-30s${NC}  ${C_GRAY}%s${NC}\n" "Xcode CLI Tools" "$_xcode_path"
    else
        printf "  ${C_RED}${SYM_ERR}${NC}  ${C_RED}%-30s${NC}  ${C_GRAY}%s${NC}\n" "Xcode CLI Tools" "not installed — run: xcode-select --install"
    fi

    _git_ver="$(git --version 2>/dev/null | awk '{print $3}')"
    if [[ -n "$_git_ver" ]]; then
        printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_WHITE}%-30s${NC}  ${C_GRAY}%s${NC}\n" "Git" "v$_git_ver"
    else
        printf "  ${C_RED}${SYM_ERR}${NC}  ${C_RED}%-30s${NC}\n" "Git not found"
    fi

    if [[ -w "$_brew_prefix" ]]; then
        printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_WHITE}%-30s${NC}  ${C_GRAY}%s${NC}\n" "Prefix permissions" "writable by current user"
    else
        printf "  ${C_YELLOW}${SYM_WARN}${NC}  ${C_YELLOW}%-30s${NC}  ${C_GRAY}%s${NC}\n" "Prefix permissions" "not writable — possible issues"
    fi

    _disk_free="$(df -h "$_brew_prefix" 2>/dev/null | tail -1 | awk '{print $4}')"
    if [[ -n "$_disk_free" ]]; then
        printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_WHITE}%-30s${NC}  ${C_GRAY}%s free${NC}\n" "Disk space" "$_disk_free"
    fi

    # Developer mode (STATE #30): reported read-only; the restore is offered only
    # for the devcmdrun setting, previewed under --dry-run, run after a
    # confirmation. Before brew doctor, so the doctor sees the restored Homebrew.
    _m01_developer_mode "$_brew_ver"

    # Taps — since Homebrew 4.x, core and cask use JSON API, not local repos
    echo ""
    echo -e "  ${C_CYAN_B}Formula repositories:${NC}"
    echo ""
    _tap_list="$(brew tap 2>/dev/null)"
    printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_WHITE}%-32s${NC}  ${C_GRAY}%s${NC}\n" \
        "homebrew/core" "JSON API — no local clone (brew 4.x+)"
    printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_WHITE}%-32s${NC}  ${C_GRAY}%s${NC}\n" \
        "homebrew/cask" "JSON API — no local clone (brew 4.x+)"
    if [[ -n "$_tap_list" ]]; then
        while IFS= read -r tap; do
            printf "  ${C_CYAN}${SYM_OK}${NC}  ${C_WHITE}%-32s${NC}  ${C_GRAY}%s${NC}\n" "$tap" "extra tap"
        done <<< "$_tap_list"
    fi

    echo ""
    _info "Running brew doctor"
    { brew doctor > /tmp/brew_doctor.log 2>&1; } &
    _spinner $! "brew doctor"
    echo ""

    if grep -q "Your system is ready to brew" /tmp/brew_doctor.log 2>/dev/null; then
        _ok "Homebrew system is healthy — no issues found"
    else
        _warn "Warnings detected by brew doctor:"
        echo ""
        grep -v "^$" /tmp/brew_doctor.log | while IFS= read -r line; do
            echo -e "  ${C_GRAY}  ${line}${NC}"
        done
    fi
}
