#!/bin/zsh
# =============================================================================
# modules/mod_01_health.sh — Homebrew system health check
# =============================================================================

_module_1() {
    _section "1" "Homebrew System Health"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Runs a full diagnostic of your Homebrew installation. Checks:${NC}"
    echo ""
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Homebrew version"    "Current version and last DB update time"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Xcode CLI Tools"     "Required for building formulae from source"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Prefix permissions"  "Checks that brew can write to its install directory"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Disk space"          "Free space on the volume containing brew prefix"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "Taps"                "Lists active formula repositories"
    printf "  ${C_GREEN}${SYM_OK}${NC}  ${C_GRAY}%-24s${NC}  %s\n" "brew doctor"         "Official Homebrew diagnostics — flags known issues"
    echo ""
    echo -e "  ${C_GRAY}brew doctor checks PATH, symlinks, permissions, and known problem patterns.${NC}"
    echo -e "  ${C_GRAY}Warnings are informational — they rarely block normal usage.${NC}"
    _hline "·" "$C_GRAY"

    echo ""
    local _brew_ver _brew_prefix _brew_repo _macos_ver _arch _ruby_ver
    _brew_ver="$(brew --version 2>/dev/null | head -1 | awk '{print $2}')"
    _brew_prefix="$(brew --prefix 2>/dev/null)"
    _brew_repo="$(brew --repository 2>/dev/null)"
    _macos_ver="$(sw_vers -productVersion 2>/dev/null)"
    _arch="$(uname -m)"
    _ruby_ver="$(brew ruby --version 2>/dev/null | awk '{print $2}' || echo 'n/a')"
    _last_update="$(cd "$_brew_repo" 2>/dev/null && git log -1 --format='%ar' 2>/dev/null || echo 'n/a')"
    _cask_count="$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')"
    _formula_count="$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')"

    _hline "·" "$C_CYAN"
    printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%-26s${NC}  ${C_CYAN_B}%-20s${NC}  ${C_WHITE}%s${NC}\n" \
        "Homebrew" "$_brew_ver" "Prefix" "$_brew_prefix"
    printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%-26s${NC}  ${C_CYAN_B}%-20s${NC}  ${C_WHITE}%s${NC}\n" \
        "macOS" "$_macos_ver" "Arch" "$_arch"
    printf "  ${C_CYAN_B}%-26s${NC}  ${C_WHITE}%-26s${NC}  ${C_CYAN_B}%-20s${NC}  ${C_WHITE}%s${NC}\n" \
        "Last DB update" "$_last_update" "Ruby (internal)" "$_ruby_ver"
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