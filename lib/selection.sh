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
#   MODULE_DESC          — id/name → one-line description; its keys are also the
#                          single source of truth for which numbered ids exist
#   MODULE_NAME          — id/name → short display name for the menu card (BM-11,
#                          presentation-only: never feeds the resolver)
#   MODULE_DRYRUN        — id/name → 1 if a --dry-run session changes nothing by
#                          running it (BM-12; honesty of the run summary)
#   MODULE_IDS           — the numbered modules, in the 'go' sequence order
#   _resolve_selection   — parse a selection spec into MODULES_TO_RUN
#   _resolve_cli         — strict non-interactive selection (spec + --only/--skip),
#                          used by positional CLI dispatch (BM-08b)
#   RESOLVE_INVALID      — global set by both: the unknown tokens seen, so a
#                          caller can be strict (CLI) or lenient (interactive)
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# MODULE REGISTRY
# ─────────────────────────────────────────────────────────────────────────────

# -g: these are global on purpose — the menu, the dispatcher and the summary in
# brew_manager.sh all read them, and so does _resolve_selection below. The named
# modules (log/bk/las/mas) live in MODULE_DESC but NOT in MODULE_IDS: they are
# reachable by name but never part of the 'go' sequence.
# Description TEXTS are presentation (the menu card's subtitle, the summary):
# they can be reworded freely, but the KEYS are the public selection contract
# (frozen — docs/04). Layout invariant, pinned by tests/test_menu_registry.zsh:
# every description is ASCII-only and at most 46 columns, so the menu row
# (indent+badge+id+name+description) never exceeds 78 columns and the layout
# holds on an 80-column terminal (roadmap §4.4). ASCII because a multibyte
# glyph would break printf %-*s column math in a non-UTF-8 locale.
typeset -gA MODULE_DESC=(
    [0]="audit /Applications, adopt into Homebrew"
    [1]="brew doctor and environment diagnostics"
    [2]="brew update (metadata only, no upgrades)"
    [3]="installed casks and formulae"
    [4]="upgrade outdated casks and formulae"
    [5]="autoremove orphans and prune old cache"
    [6]="shared dependency analysis"
    [7]="Homebrew services status"
    [8]="/usr/local/bin not owned by brew"
    [9]="/usr/local/bin owned by brew"
    [10]="casks with auto_updates (--greedy)"
    [11]="duplicate and conflicting formulae"
    [12]="broken deps, pinned, non-HTTPS, deprecated"
    [13]="per-package disk usage, sorted by size"
    [log]="browse and prune session logs"
    [bk]="backup / restore packages and agents"
    [las]="LaunchAgent auto-run setup"
    [mas]="Mac App Store integration (mas)"
)

# MODULE_NAME — short display name for the menu card and the summary (BM-11).
# One entry for EVERY MODULE_DESC key, presentation-only like MODULE_RISK: the
# resolver never reads it, so renaming here can never change what a selection
# runs. Names are ASCII-only and at most 17 columns — the menu's fixed name
# column — pinned by tests/test_menu_registry.zsh together with the 46-column
# description cap above.
typeset -gA MODULE_NAME=(
    [0]="Unmanaged apps"    [1]="System health"     [2]="Database update"
    [3]="Package report"    [4]="Available updates" [5]="Cleanup"
    [6]="Dependency map"    [7]="Services"          [8]="Untracked bins"
    [9]="Brew-owned bins"   [10]="Greedy upgrades"  [11]="Conflicts"
    [12]="Security audit"   [13]="Disk usage"
    [log]="Log manager"     [bk]="Brewfile backup"  [las]="Scheduler"
    [mas]="App Store"
)

# MODULE_DRYRUN — id → 1 when a `--dry-run` session provably changes NOTHING by
# running this module, 0 when it can still act. This is NOT a risk level
# (MODULE_RISK is): it is a factual statement about what the module's code does
# under BREW_MANAGER_DRY_RUN, and the run summary uses it to decide whether it
# may attest "previewed, nothing changed" for that module.
#
# Read-only modules are 1 by construction — they never mutate. Mutating modules
# are 1 only when EVERY acting path is behind the dry-run gate:
#   [mas] 0 — `brew install mas` is behind _ask_danger but NOT behind the gate;
#             the gate only covers `mas upgrade` (mod_mas_mas.sh:41 vs :114)
# Overstating dry-run coverage here is a security bug of the same class as a
# risk badge that understates blast radius (docs/03): both make the session log
# claim a safety property the run did not have. Kept honest by
# tests/test_run_summary.zsh, which greps each module marked 1 for the gate, and
# by tests/test_dryrun_gates.zsh, which runs the modules against a mock brew and
# proves the commands are never invoked.
typeset -gA MODULE_DRYRUN=(
    [0]=1   [1]=1   [2]=1   [3]=1   [4]=1
    [5]=1   [6]=1   [7]=1   [8]=1   [9]=1
    [10]=1  [11]=1  [12]=1  [13]=1
    [log]=1 [bk]=1  [las]=1 [mas]=0
)

typeset -ga MODULE_IDS=(0 1 2 3 4 5 6 7 8 9 10 11 12 13)

# MODULE_RISK — id → risk level, one entry for EVERY MODULE_DESC key. It is the
# single source of truth for the risk BADGE the menu and each module's "About"
# block show (BM-10). A module's level is the HIGHEST any of its code paths can
# reach — a badge that understates risk is a security bug (docs/03) — so it was
# set from an adversarially-verified per-module audit (workflow, 2026-07-20):
#   ro     — only reads/reports, changes nothing.
#   write  — mutates only metadata/cache or the tool's OWN files (logs/, backups/,
#            agents/); installs/removes nothing on the system.
#   danger — can remove/install/adopt packages, or persist/load a LaunchAgent.
# Kept in lockstep with MODULE_DESC: tests/test_risk_badges.zsh fails if any id is
# missing, carries a level outside {ro,write,danger}, or the sensitive modules
# (docs/03: 0,5,bk,las) are not 'danger'. A gate on the SELECTION contract, not
# the risk one, so this array is presentation-only: it never feeds the resolver.
typeset -gA MODULE_RISK=(
    [0]=danger  [1]=ro      [2]=write   [3]=ro      [4]=danger
    [5]=danger  [6]=ro      [7]=ro      [8]=ro      [9]=ro
    [10]=danger [11]=ro     [12]=ro     [13]=ro
    [log]=write [bk]=danger [las]=danger [mas]=danger
)

# _about_risk <id> — print, at the standard indent, the risk badge followed by its
# caption, for a module's "About this module" block. An unknown id degrades to the
# neutral badge/caption instead of crashing a module's intro. Uses the pure
# renderers and TUI_INDENT from lib/common.sh (sourced before this file); resolved
# at call time, so the registry above is already populated.
_about_risk() {
    local level="${MODULE_RISK[$1]:-unknown}"
    printf '%s%s  %s\n' "$TUI_INDENT" "$(_risk_badge "$level")" "$(_risk_caption "$level")"
}

# ─────────────────────────────────────────────────────────────────────────────
# SELECTION RESOLVER
# ─────────────────────────────────────────────────────────────────────────────

# _resolve_selection <spec> [invalid_mode]
# Parse a raw selection spec into the canonical run list.
#
# Populates the global array MODULES_TO_RUN (reset on entry) and the global
# RESOLVE_INVALID (reset on entry) with every unknown token seen. Behaviour of
# the resolution itself is a faithful move of the former inline parser — no
# semantic change:
#   - ""|go|GO   → every MODULE_IDS entry, in order
#   - a lone     → that single named module. Matched case-insensitively ONLY in
#     special      its exact upper/lower forms (log|LOG, bk|BK, …), exactly as
#     token        the old `case` arms did.
#   - otherwise  → comma-split; each token stripped of spaces:
#                    empty token (stray/adjacent comma, `0,4,`) → ignored;
#                    numeric AND present in MODULE_DESC → kept;
#                    lowercase special (log|bk|las|mas) → kept;
#                    anything else → recorded in RESOLVE_INVALID.
#   Duplicates and order are preserved verbatim (1,1,2 → 1 1 2; 5,2,0 → 5 2 0).
#
# invalid_mode (default "warn") controls ONLY how unknown tokens are surfaced —
# not what ends up in MODULES_TO_RUN:
#   - "warn"    → emit `_warn "…invalid — skipped"` per unknown token (the
#                 interactive default).
#   - "collect" → stay silent; the caller inspects RESOLVE_INVALID and decides
#                 (used by _resolve_cli to be strict).
#
# Quirks preserved on purpose (they were parity-moved from the original parser
# and are NOT security-relevant): mixed-case whole tokens like `Log` do NOT match
# (only `log`/`LOG` do); a special inside a comma list is case-SENSITIVE (`0,LOG`
# drops LOG); `go` inside a comma list (`0,go`) is invalid.
# Hardened in BM-08b (gate finding): tokens are split and space-stripped with
# parameter expansion, never `echo`/`read -rA <<<`, so a token can no longer be
# reinterpreted through backslash-escape expansion or truncated at a newline —
# both were fail-OPEN paths that could run a DIFFERENT module than requested.
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
    local _spec="$1" _invalid_mode="${2:-warn}"
    local _n
    local -a _raw_nums
    MODULES_TO_RUN=()
    RESOLVE_INVALID=()

    case "${_spec:-go}" in
        log|LOG) MODULES_TO_RUN=("log") ;;
        bk|BK)   MODULES_TO_RUN=("bk")  ;;
        las|LAS) MODULES_TO_RUN=("las") ;;
        mas|MAS) MODULES_TO_RUN=("mas") ;;
        go|GO|"")
            MODULES_TO_RUN=(${MODULE_IDS[@]})
            ;;
        *)
            # Split on comma with parameter expansion, NOT `read -rA <<<`: a
            # here-string is one "line", so read would truncate a token that
            # contains a newline (dropping everything after it silently). (@s:,:)
            # keeps every field, empties included, and preserves embedded newlines
            # so a bogus token like $'5\n9' is validated (and rejected) whole.
            _raw_nums=("${(@s:,:)_spec}")
            for _n in "${_raw_nums[@]}"; do
                _n="${_n// /}"                       # strip spaces via param expansion:
                                                     # echo would interpret \e/\0NN escapes,
                                                     # remapping a bogus token onto a real
                                                     # module id (a fail-open bypass).
                [[ -z "$_n" ]] && continue           # a stray/adjacent comma yields an empty
                                                     # token — ignore it, don't call it invalid
                if [[ "$_n" =~ ^[0-9]+$ ]] && [[ -n "${MODULE_DESC[$_n]}" ]]; then
                    MODULES_TO_RUN+=("$_n")
                elif [[ "$_n" == "log" || "$_n" == "bk" || "$_n" == "las" || "$_n" == "mas" ]]; then
                    MODULES_TO_RUN+=("$_n")
                else
                    RESOLVE_INVALID+=("$_n")
                    [[ "$_invalid_mode" == "warn" ]] && _warn "Module '$_n' is invalid — skipped"
                fi
            done
            ;;
    esac

    (( ${#MODULES_TO_RUN[@]} > 0 ))
}

# _collect_module_tokens <csv>
# Validate a plain comma-separated list of module tokens, for the --only/--skip
# filters. Unlike _resolve_selection there is NO 'go'/whole-string special
# handling — a filter names concrete modules — so each token must be numeric and
# present in MODULE_DESC, or one of log|bk|las|mas.
# Populates the global FILTER_TOKENS (valid tokens, in order) and APPENDS every
# unknown token to RESOLVE_INVALID (which it does NOT reset — the caller owns it).
_collect_module_tokens() {
    local _csv="$1"
    local _t _valid
    local -a _toks
    FILTER_TOKENS=()
    [[ -z "$_csv" ]] && return 0
    _toks=("${(@s:,:)_csv}")                 # same safe split as _resolve_selection
    for _t in "${_toks[@]}"; do
        _t="${_t// /}"                       # strip spaces (param expansion: no echo escapes)
        [[ -z "$_t" ]] && continue           # tolerate stray/adjacent commas (0,4, / 5,,2)
        _valid=0
        if [[ "$_t" =~ ^[0-9]+$ ]] && [[ -n "${MODULE_DESC[$_t]}" ]]; then
            _valid=1
        elif [[ "$_t" == "log" || "$_t" == "bk" || "$_t" == "las" || "$_t" == "mas" ]]; then
            _valid=1
        fi
        if (( _valid )); then
            FILTER_TOKENS+=("$_t")
        else
            RESOLVE_INVALID+=("$_t")
        fi
    done
}

# _resolve_cli <spec> <only_csv> <skip_csv>
# Build a NON-INTERACTIVE selection, STRICTLY. Resolve <spec> (default 'go'),
# then — when given — keep only the modules also in <only_csv> (intersection,
# preserving base order and duplicates), then remove those in <skip_csv>.
#
# Strict: any unknown token anywhere (spec, only, skip) is recorded in
# RESOLVE_INVALID and makes the call fail — nothing is silently skipped, unlike
# the lenient interactive path. <only_csv>/<skip_csv> are plain module-token
# lists: they do NOT accept 'go' or the whole-string specials (a bare 'go' in a
# filter is an unknown token).
#
# Populates MODULES_TO_RUN. Returns:
#   2  → at least one invalid token (caller reports RESOLVE_INVALID and aborts)
#   1  → all tokens valid but the result is empty (e.g. --skip removed everything)
#   0  → a non-empty selection
_resolve_cli() {
    local _spec="$1" _only="$2" _skip="$3"
    local _m
    local -a _base _only_set _skip_set _kept

    # Base resolution in collect mode: silent, base invalids land in RESOLVE_INVALID
    # (which _resolve_selection resets), so it must run before the filters below.
    _resolve_selection "${_spec:-go}" collect
    _base=("${MODULES_TO_RUN[@]}")

    _collect_module_tokens "$_only"; _only_set=("${FILTER_TOKENS[@]}")
    _collect_module_tokens "$_skip"; _skip_set=("${FILTER_TOKENS[@]}")

    # --only: intersection, keeping base order and duplicates
    if [[ -n "$_only" ]]; then
        _kept=()
        for _m in "${_base[@]}"; do
            (( ${_only_set[(Ie)$_m]} )) && _kept+=("$_m")
        done
        _base=("${_kept[@]}")
    fi

    # --skip: removal of every occurrence
    if [[ -n "$_skip" ]]; then
        _kept=()
        for _m in "${_base[@]}"; do
            (( ${_skip_set[(Ie)$_m]} )) || _kept+=("$_m")
        done
        _base=("${_kept[@]}")
    fi

    MODULES_TO_RUN=("${_base[@]}")

    (( ${#RESOLVE_INVALID[@]} > 0 )) && return 2
    (( ${#MODULES_TO_RUN[@]} > 0 ))
}

# _selection_is_valid <spec>
# Predicate: 0 (true) iff <spec> resolves to a NON-EMPTY selection with NO unknown
# tokens — i.e. exactly what a stored agent selection (mod_las_scheduler) may run.
# Delegates to _resolve_cli so there is ONE grammar; runs it in a SUBSHELL so the
# resolver's global side effects (MODULES_TO_RUN / RESOLVE_INVALID / FILTER_TOKENS)
# do NOT leak to the caller (it is called mid-run, at agent install time).
# NB: this is the install-time gate; the agent RUN itself goes through the same
# _resolve_cli via positional dispatch, so a value that passes here also runs.
_selection_is_valid() {
    [[ -z "$1" ]] && return 1        # an empty stored selection is not valid:
                                     # the caller must fall back to an explicit 'go'
    ( _resolve_cli "$1" "" "" ) >/dev/null 2>&1
}
