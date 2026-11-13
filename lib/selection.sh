#!/bin/zsh
# =============================================================================
# lib/selection.sh — Module registry and selection resolver
#
# Sourced by brew_manager.sh (right after lib/common.sh, which provides _warn)
# and sourceable in isolation by tests/ — it has NO side effects at source time
# (it only defines data and a function), so a test can pull it in without
# starting the TUI.
#
# Owns the "selection" concern, kept in one place so the SAME resolver backs
# the interactive menu and the positional CLI dispatch (BM-08b). Before this
# extraction the parser lived inline in brew_manager.sh and could not be reused
# or tested.
#
# Provides:
#   MODULE_DESC          — id → one-line description; its keys are also the
#                          single source of truth for which ids exist
#   MODULE_NAME          — id → short display name for the menu card (BM-11,
#                          presentation-only: never feeds the resolver)
#   MODULE_DRYRUN        — id → 1 if a --dry-run session changes nothing by
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
# brew_manager.sh all read them, and so does _resolve_selection below. Every
# module is numbered and in the 'go' sequence: the modules selected by name
# (bk, las, log, mas) were removed in 2.0.0, with module 10, and their ids stay
# reserved — never given to another module.
# Description TEXTS are presentation (the menu card's subtitle, the summary):
# they can be reworded freely, but the KEYS are the public selection contract
# (frozen — CLAUDE.md, Public contract). Layout invariant, pinned by tests/test_menu_registry.zsh:
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
    [11]="duplicate and conflicting formulae"
    [12]="broken deps, pinned, non-HTTPS, deprecated"
    [13]="per-package disk usage, sorted by size"
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
    [9]="Brew-owned bins"   [11]="Conflicts"
    [12]="Security audit"   [13]="Disk usage"
)

# MODULE_DRYRUN — id → 1 when a `--dry-run` session provably changes NOTHING by
# running this module, 0 when it can still act. This is NOT a risk level
# (MODULE_RISK is): it is a factual statement about what the module's code does
# under BREW_MANAGER_DRY_RUN, and the run summary uses it to decide whether it
# may attest "previewed, nothing changed" for that module.
#
# Read-only modules are 1 by construction — they never mutate. Mutating modules
# are 1 only when EVERY acting path is behind the dry-run gate:
#   [1]   0 — its developer-mode restore IS gated, but under --dry-run it still
#             writes brew doctor's output to the fixed /tmp/brew_doctor.log and,
#             before its dry-run check, runs a plain `git status` in Homebrew's
#             repository, which may rewrite that repository's index file. It
#             was 1 as a read-only module, and stayed 1 when the restore made it
#             `write`: tests/test_run_summary.zsh found the restore's gate by
#             grep. Task 4 of the 2.0.0 plan removes both writes and flips it
#             back (STATE #3, #11, #14).
# A 0 is declared, never hidden: bk and las were 1 — declared, never verified —
# until fix/dryrun-mod02-mas checked the whole registry against the code and
# found both acting under --dry-run; they stayed 0, honestly, until their
# removal in 2.0.0. Understating is honest, overstating is not.
#
# Overstating dry-run coverage here is a security bug of the same class as a
# risk badge that understates blast radius (docs/03): both make the session log
# claim a safety property the run did not have. Kept honest by
# tests/test_run_summary.zsh, which greps each module marked 1 for the gate and
# pins the set of ungated modules so it cannot grow in silence, and by
# tests/test_dryrun_gates.zsh, which runs mod_02 — once ungated — against a mock
# brew and proves its command is never invoked.
typeset -gA MODULE_DRYRUN=(
    [0]=1   [1]=0   [2]=1   [3]=1   [4]=1
    [5]=1   [6]=1   [7]=1   [8]=1   [9]=1
    [11]=1  [12]=1  [13]=1
)

# The 'go' sequence. No 10: module 10 (greedy upgrades) was retired in 2.0.0
# and its number is reserved, never given to another module (decision D3 of
# the 2.0.0 plan; CLAUDE.md, Public contract) — a 1.x script or agent that still
# passes 10 must be refused, not run something else.
typeset -ga MODULE_IDS=(0 1 2 3 4 5 6 7 8 9 11 12 13)

# MODULE_RISK — id → risk level, one entry for EVERY MODULE_DESC key. It is the
# single source of truth for the risk BADGE the menu and each module's "About"
# block show (BM-10). A module's level is the HIGHEST any of its code paths can
# reach — a badge that understates risk is a security bug (docs/03) — so it was
# set from an adversarially-verified per-module audit (workflow, 2026-07-20):
#   ro     — only reads/reports, changes nothing.
#   write  — mutates only metadata/cache, Homebrew's own settings and code (module 1's
#            developer-mode restore, module 2's brew update) or the tool's OWN files
#            (logs/); installs/removes nothing on the system.
#   danger — can remove/install/upgrade/adopt packages.
# Module 1 is `write` since it can restore Homebrew from developer mode (`brew
# developer off` + `brew update`, after a confirmation): Homebrew's own setting
# and code, like module 2's `brew update` — no package installed or removed.
# Kept in lockstep with MODULE_DESC: tests/test_risk_badges.zsh fails if any id is
# missing, carries a level outside {ro,write,danger}, or the sensitive modules
# that delete or install (CLAUDE.md, Sensitive components: 0, 4, 5) are not
# 'danger'. A gate on the SELECTION contract, not the risk one, so this array is
# presentation-only: it never feeds the resolver.
typeset -gA MODULE_RISK=(
    [0]=danger  [1]=write   [2]=write   [3]=ro      [4]=danger
    [5]=danger  [6]=ro      [7]=ro      [8]=ro      [9]=ro
    [11]=ro     [12]=ro     [13]=ro
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
# RESOLVE_INVALID (reset on entry) with every unknown token seen. The grammar is
# the former inline parser's, moved verbatim (BM-08a), less the names bk, las,
# log and mas: removed in 2.0.0, they are unknown tokens like any other, in any
# case and any position, so nothing here maps a name onto a module any more:
#   - ""|go|GO   → every MODULE_IDS entry, in order
#   - otherwise  → comma-split; each token stripped of spaces:
#                    empty token (stray/adjacent comma, `0,4,`) → ignored;
#                    numeric AND present in MODULE_DESC → kept;
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
# Quirk preserved on purpose (parity-moved from the original parser, NOT
# security-relevant): `go` inside a comma list (`0,go`) is invalid.
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
# filters. Unlike _resolve_selection there is NO 'go' handling — a filter names
# concrete modules — so each token must be numeric and present in MODULE_DESC
# (a removed name such as bk is an unknown token here too).
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
# lists: they do NOT accept 'go' (a bare 'go' in a filter is an unknown token).
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
