#!/bin/zsh
# =============================================================================
# lib/selection.sh — Module registry and selection resolver
#
# Sourced by brew_manager.sh (right after lib/common.sh, which provides _warn)
# and sourceable in isolation by tests/ — it has NO side effects at source time
# (it only defines data and a function), so a test can pull it in without
# starting the TUI.
#
# Owns the "selection" concern, kept in one place so the SAME resolver can back
# the interactive menu today and — planned — positional CLI dispatch (BM-08b)
# and scheduled agents (BM-08c). Before this extraction the parser lived inline
# in brew_manager.sh and could not be reused or tested.
#
# Provides:
#   MODULE_DESC         — id/name → human description; its keys are also the
#                         single source of truth for which numbered ids exist
#   MODULE_IDS          — the numbered modules, in the 'go' sequence order
#   _resolve_selection  — parse a selection spec into MODULES_TO_RUN
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# MODULE REGISTRY
# ─────────────────────────────────────────────────────────────────────────────

# -g: these are global on purpose — the menu, the dispatcher and the summary in
# brew_manager.sh all read them, and so does _resolve_selection below. The named
# modules (log/bk/las/mas) live in MODULE_DESC but NOT in MODULE_IDS: they are
# reachable by name but never part of the 'go' sequence.
typeset -gA MODULE_DESC=(
    [0]="Audit unmanaged apps (not in Homebrew)"
    [1]="Homebrew system health"
    [2]="Formula database update"
    [3]="Installed packages report"
    [4]="Available updates"
    [5]="Cache and orphan dependency cleanup"
    [6]="Shared dependency analysis"
    [7]="Homebrew services"
    [8]="Untracked binaries in /usr/local/bin"
    [9]="Brew-tracked binaries in /usr/local/bin"
    [10]="Auto-update casks (skipped by brew upgrade)"
    [11]="Duplicate and conflicting formulae"
    [12]="Security audit"
    [13]="Disk usage breakdown"
    [log]="Log file manager (not in go sequence)"
    [bk]="Brewfile backup and restore"
    [las]="LaunchAgent scheduler (auto-run)"
    [mas]="Mac App Store (MAS) integration"
)

typeset -ga MODULE_IDS=(0 1 2 3 4 5 6 7 8 9 10 11 12 13)

# ─────────────────────────────────────────────────────────────────────────────
# SELECTION RESOLVER
# ─────────────────────────────────────────────────────────────────────────────

# _resolve_selection <spec>
# Parse a raw selection spec into the canonical run list.
#
# Populates the global array MODULES_TO_RUN (reset on entry). Behaviour is a
# faithful move of the former inline parser — no semantic change:
#   - ""|go|GO   → every MODULE_IDS entry, in order
#   - a lone     → that single named module. Matched case-insensitively ONLY in
#     special      its exact upper/lower forms (log|LOG, bk|BK, …), exactly as
#     token        the old `case` arms did.
#   - otherwise  → comma-split; each token stripped of spaces:
#                    numeric AND present in MODULE_DESC → kept;
#                    lowercase special (log|bk|las|mas) → kept;
#                    anything else → _warn "…invalid — skipped".
#   Duplicates and order are preserved verbatim (1,1,2 → 1 1 2; 5,2,0 → 5 2 0).
#
# Quirks preserved ON PURPOSE — this is a parity refactor, not a fix (fixing
# them is a separate, later task so this change stays provably behaviour-neutral):
#   - mixed-case whole tokens like `Log` do NOT match (only `log`/`LOG` do);
#   - a special token inside a comma list is case-SENSITIVE (`0,LOG` drops LOG);
#   - `go` inside a comma list (e.g. `0,go`) is dropped with a warning.
#
# Requires: MODULE_DESC / MODULE_IDS (above) and _warn (lib/common.sh).
# Returns:  0 if MODULES_TO_RUN ended up non-empty, 1 if empty. The caller owns
#           the empty-is-fatal policy (the interactive path exits 1, as before).
#
# Note on the output contract: the result is returned via the global array, NOT
# printed, because _warn writes to stdout — capturing stdout would mix warnings
# into the result. The array contract also keeps the warnings interleaved in the
# TUI exactly as before.
_resolve_selection() {
    local _spec="$1"
    local _n
    local -a _raw_nums
    MODULES_TO_RUN=()

    case "${_spec:-go}" in
        log|LOG) MODULES_TO_RUN=("log") ;;
        bk|BK)   MODULES_TO_RUN=("bk")  ;;
        las|LAS) MODULES_TO_RUN=("las") ;;
        mas|MAS) MODULES_TO_RUN=("mas") ;;
        go|GO|"")
            MODULES_TO_RUN=(${MODULE_IDS[@]})
            ;;
        *)
            IFS=',' read -rA _raw_nums <<< "$_spec"
            for _n in "${_raw_nums[@]}"; do
                _n=$(echo "$_n" | tr -d ' ')
                if [[ "$_n" =~ ^[0-9]+$ ]] && [[ -n "${MODULE_DESC[$_n]}" ]]; then
                    MODULES_TO_RUN+=("$_n")
                elif [[ "$_n" == "log" || "$_n" == "bk" || "$_n" == "las" || "$_n" == "mas" ]]; then
                    MODULES_TO_RUN+=("$_n")
                else
                    _warn "Module '$_n' is invalid — skipped"
                fi
            done
            ;;
    esac

    (( ${#MODULES_TO_RUN[@]} > 0 ))
}
