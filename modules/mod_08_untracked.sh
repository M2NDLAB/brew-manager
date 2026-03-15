#!/bin/zsh
# =============================================================================
# modules/mod_08_untracked.sh — Untracked binaries in /usr/local/bin
# =============================================================================

_module_8() {
    _section "8" "Untracked Binaries in /usr/local/bin"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    echo ""
    echo -e "  ${C_GRAY}Scans /usr/local/bin for executables that are NOT managed by Homebrew.${NC}"
    echo -e "  ${C_GRAY}These are binaries placed there manually, by installers, or by SDKs${NC}"
    echo -e "  ${C_GRAY}that bypass the package manager — they won't be updated by brew upgrade.${NC}"
    echo ""
    echo -e "  ${C_GRAY}Each untracked binary shows its symlink target so you can identify its${NC}"
    echo -e "  ${C_GRAY}origin (e.g. a manually installed tool, an SDK, or a leftover).${NC}"
    _hline "·" "$C_GRAY"
    _info "Comparing /usr/local/bin against brew-managed symlinks"
    echo ""

    brew_prefix=$(brew --prefix)
    declare -a untracked_bins=()
    _brew_bins="$(brew list 2>/dev/null)"

    for bin_path in /usr/local/bin/*; do
        [[ ! -e "$bin_path" ]] && continue
        bin_name="$(basename "$bin_path")"
        _tgt="$(readlink "$bin_path" 2>/dev/null || echo 'binary')"
        if [[ -L "$bin_path" ]]; then
            if [[ "$_tgt" == *"$brew_prefix"* ]] || [[ "$_tgt" == *"/Applications/"* ]] || [[ "$_tgt" == *"Cellar"* ]]; then
                continue
            fi
        fi
        echo "$_brew_bins" | grep -q "^${bin_name}$" && continue
        untracked_bins+=("$bin_name|$_tgt")
    done

    if (( ${#untracked_bins[@]} == 0 )); then
        _ok "All binaries are tracked by brew or managed apps"
    else
        for entry in "${untracked_bins[@]}"; do
            local bin_name="${entry%%|*}"
            local target="${entry##*|}"
            printf "  ${C_YELLOW}${SYM_DOT}${NC}  ${C_WHITE}%-25s${NC} ${C_GRAY}→ %s${NC}\n" "$bin_name" "$target"
        done
    fi
}