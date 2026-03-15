#!/bin/zsh
# =============================================================================
# modules/mod_09_tracked.sh — Brew-tracked binaries in /usr/local/bin
# =============================================================================

_module_9() {
    _section "9" "Brew-tracked Binaries in /usr/local/bin"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Companion to module 8 — lists binaries in /usr/local/bin that ARE${NC}"
    echo -e "  ${C_GRAY}managed by Homebrew, either as formula symlinks or as binaries exposed${NC}"
    echo -e "  ${C_GRAY}by cask apps (e.g. docker, kubectl, code from VS Code).${NC}"
    echo ""
    printf "  ${C_GREEN_B}${SYM_OK}${NC}  ${C_GRAY}%-14s${NC}  %s\n" "brew formula"  "Symlink points into Homebrew Cellar"
    printf "  ${C_CYAN}${SYM_OK}${NC}  ${C_GRAY}%-14s${NC}  %s\n" "app: AppName"  "Symlink points into a .app bundle in /Applications"
    _hline "·" "$C_GRAY"
    _info "Scanning brew-managed or brew-app symlinks"
    echo ""

    brew_prefix=$(brew --prefix)
    _brew_bins="$(brew list 2>/dev/null)"
    declare -a tracked_bins=()

    for bin_path in /usr/local/bin/*; do
        [[ ! -e "$bin_path" ]] && continue
        local bin_name="$(basename "$bin_path")"
        local _tgt="$(readlink "$bin_path" 2>/dev/null || echo 'binary')"
        local _source=""

        if [[ -L "$bin_path" ]]; then
            if [[ "$_tgt" == *"$brew_prefix"* ]] || [[ "$_tgt" == *"Cellar"* ]]; then
                _source="brew formula"
            elif [[ "$_tgt" == *"/Applications/"* ]]; then
                _app_name=$(echo "$_tgt" | sed 's|.*/Applications/\([^/]*\)\.app.*|\1|')
                _source="app: $_app_name"
            fi
        fi

        if [[ -z "$_source" ]]; then
            echo "$_brew_bins" | grep -q "^${bin_name}$" && _source="brew formula"
        fi

        [[ -z "$_source" ]] && continue
        tracked_bins+=("$bin_name|$_tgt|$_source")
    done

    if (( ${#tracked_bins[@]} == 0 )); then
        _info "No tracked binaries found in /usr/local/bin"
    else
        printf "  ${C_GRAY}%-4s  %-22s  %-14s  %-36s${NC}\n" \
            "No." "Binary" "Managed by" "Target"
        printf "  ${C_GRAY}%-4s  %-22s  %-14s  %-36s${NC}\n" \
            "────" "──────────────────────" "──────────────" "────────────────────────────────────"
        local _idx=1
        for entry in "${tracked_bins[@]}"; do
            local bin_name="${entry%%|*}"
            local rest="${entry#*|}"
            local _tgt="${rest%%|*}"
            local _source="${rest##*|}"
            local _color="$C_GREEN_B"
            [[ "$_source" == app:* ]] && _color="$C_CYAN"
            printf "  ${_color}${SYM_OK}${NC}   ${C_WHITE}%-22s${NC}  ${C_GRAY}%-14s${NC}  ${C_GRAY}%s${NC}\n" \
                "$bin_name" "$_source" "$_tgt"
            (( _idx++ ))
        done
        echo ""
        _stat_row "Total tracked binaries" "$_idx" "$C_GREEN_B"
    fi
}