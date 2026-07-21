#!/bin/zsh
# =============================================================================
# modules/mod_02_update.sh — Formula database update
# =============================================================================

# _mod02_repo_table <mark> <state> — the "Repository / Status" table, shared by
# the real run and the --dry-run preview: the set of repositories `brew update`
# would refresh is the same either way, and reading it (brew tap + git log) never
# writes. Only the leading mark and the state column differ, so the executed
# path keeps rendering byte-for-byte what it always did.
# <mark> is interpolated into the printf FORMAT (like every other line here), so
# the palette's literal "\033[…m" is expanded exactly as before; it is code, not
# caller data — no user string ever reaches it (IMP-003).
# NOTE: the second local is `state`, not `status` — `status` is read-only in zsh
# (it aliases $?), and assigning it aborts the function mid-render.
_mod02_repo_table() {
    local mark="$1" state="$2"

    echo ""
    printf "  ${C_GRAY}%-36s  %-20s${NC}\n" "Repository" "Status"
    printf "  ${C_GRAY}%-36s  %-20s${NC}\n" "────────────────────────────────────" "────────────────────"
    printf "  ${mark}   ${C_WHITE}%-36s${NC}  ${C_GRAY}%s${NC}\n" "homebrew/core" "$state"
    printf "  ${mark}   ${C_WHITE}%-36s${NC}  ${C_GRAY}%s${NC}\n" "homebrew/cask" "$state"

    _extra_taps="$(brew tap 2>/dev/null)"
    if [[ -n "$_extra_taps" ]]; then
        while IFS= read -r tap; do
            _tap_updated="$(cd "$(brew --repository)" 2>/dev/null && git log --format="%ar" -1 -- "Library/Taps/$tap" 2>/dev/null || echo "n/a")"
            printf "  ${C_CYAN}${SYM_OK}${NC}   ${C_WHITE}%-36s${NC}  ${C_GRAY}%s${NC}\n" "$tap" "${_tap_updated:-updated}"
        done <<< "$_extra_taps"
    fi
}

# _mod02_index_age → how long ago the local package index was last refreshed,
# as "12m ago" / "3h ago" / "2d ago", or "unknown" when it cannot be told.
# Read from the mtime of the newest file in Homebrew's api cache, which
# `brew update` rewrites on every refresh: it is the closest thing to "how
# stale is what this module would refresh" that costs no network call. Every
# failure mode (no brew, no cache dir, empty dir, unreadable stat) degrades to
# "unknown" rather than printing a fabricated age.
_mod02_index_age() {
    local cache mtime now age
    cache="$(brew --cache 2>/dev/null)"
    [[ -n "$cache" && -d "$cache/api" ]] || { printf 'unknown'; return; }

    # (.om[1]N): regular files, newest first, take one, empty if none.
    local -a newest=( "$cache"/api/*(.om[1]N) )
    (( ${#newest[@]} )) || { printf 'unknown'; return; }

    mtime="$(stat -f %m "${newest[1]}" 2>/dev/null)"
    now="$(date +%s 2>/dev/null)"
    [[ "$mtime" == <-> && "$now" == <-> ]] || { printf 'unknown'; return; }

    age=$(( now - mtime ))
    (( age < 0 )) && { printf 'unknown'; return; }   # clock skew: say nothing
    if   (( age < 3600 ));  then printf '%dm ago' $(( age / 60 ))
    elif (( age < 86400 )); then printf '%dh ago' $(( age / 3600 ))
    else                         printf '%dd ago' $(( age / 86400 ))
    fi
}

_module_2() {
    _section "2" "Formula Database Update"
    echo ""
    echo -e "  ${C_CYAN_B}About this module:${NC}"
    _about_risk "2"
    echo ""
    echo -e "  ${C_GRAY}Runs brew update, which fetches the latest package definitions (formulae${NC}"
    echo -e "  ${C_GRAY}and casks) from Homebrew's JSON API. This is NOT the same as upgrading${NC}"
    echo -e "  ${C_GRAY}packages — it only updates the list of what is available and what versions${NC}"
    echo -e "  ${C_GRAY}exist. Upgrading packages happens in module 4.${NC}"
    echo ""
    echo -e "  ${C_GRAY}Since Homebrew 4.x, core and cask repos are fetched as JSON files${NC}"
    echo -e "  ${C_GRAY}rather than Git clones — brew update is fast (seconds, not minutes).${NC}"
    _hline "·" "$C_GRAY"

    # --dry-run gate. `brew update` rewrites Homebrew's local index, so it is a
    # mutation like any other and must not run in a preview session — this module
    # used to run it unconditionally, which made the session summary flag it as
    # "ran anyway" (STATE Attenzione #3/#14). The gate sits BEFORE any execution
    # and before any confirmation, so --dry-run outranks --yes: an unattended dry
    # run has no path back to the command. What follows is read-only.
    if (( BREW_MANAGER_DRY_RUN )); then
        _info "Dry-run mode — skipping brew update"
        echo ""
        _item "Would run: ${C_CYAN}brew update${NC}"
        _mod02_repo_table "${C_GRAY}${SYM_DOT}${NC}" "would be refreshed"
        echo ""
        _stat_row "Local index last refreshed" "$(_mod02_index_age)" "$C_GRAY"
        return
    fi

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

    _mod02_repo_table "${C_GREEN_B}${SYM_OK}${NC}" "updated via JSON API"

    echo ""
    _new_formulae=$(grep -E "^New (Formulae|Casks):" /tmp/brew_update.log 2>/dev/null)
    if [[ -n "$_new_formulae" ]]; then
        echo "$_new_formulae" | while IFS= read -r line; do _info "$line"; done
    fi
}
