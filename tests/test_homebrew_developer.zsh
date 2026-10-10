#!/bin/zsh
# =============================================================================
# tests/test_homebrew_developer.zsh — brew-manager never leaves Homebrew in
# developer mode (STATE Attenzione #30, CLAUDE.md: Homebrew's configuration
# belongs to the user)
#
# Running ANY Homebrew developer command as a non-developer turns Homebrew's
# developer mode on: brew.sh writes `homebrew.devcmdrun true` into the git
# config of Homebrew's repository, and from then on `brew update` follows
# Homebrew's `main` branch instead of its stable releases. Module 1 did exactly
# that with `brew ruby --version` from v1.1.0 on — also under --dry-run.
#
# 1. Prevention (static): no developer command appears in the code. The list
#    is pinned below from Homebrew 7.0.8 (identical in 6.0.21) and, when a
#    Homebrew is installed at a standard prefix, widened with the names in its
#    own dev-cmd/ directory — read as a directory listing, never by running
#    brew, so the suite stays hermetic and can only get stricter.
#
# Zero external deps; run by `make test`. Exits non-zero unless every check
# passed AND at least one ran (anti-vacuity).
# =============================================================================

_ROOT="${0:A:h:h}"

typeset -i TESTS_RUN=0 TESTS_FAILED=0
_pass() { (( TESTS_RUN += 1 ));                          print -r -- "  ok    $1"; }
_fail() { (( TESTS_RUN += 1 )); (( TESTS_FAILED += 1 )); print -r -- "  FAIL  $1"; }

_SANDBOX="$(mktemp -d)" || { print -r -- "FAIL: mktemp"; exit 1; }
cleanup() { rm -rf "$_SANDBOX"; }
trap 'cleanup; trap - EXIT; exit 130' INT TERM
trap cleanup EXIT

# ─────────────────────────────────────────────────────────────────────────────
# 1. Prevention: no Homebrew developer command in the code
# ─────────────────────────────────────────────────────────────────────────────
# The files of Library/Homebrew/dev-cmd/ in Homebrew 7.0.8 (2026-10-10; the
# same 68 names as 6.0.21), plus the two aliases that resolve to one of them
# (commands.rb: lc → livecheck, tc → typecheck). brew.sh decides "developer
# command" by the presence of dev-cmd/<name>.rb|.sh, so this IS the list.
typeset -a _DEVCMDS=(
    advisory-match audit benchmark bottle bump bump-cask-pr
    bump-compatibility-version bump-formula-pr bump-python-resources-pr
    bump-revision bump-unversioned-casks cask-ci cat contributions create
    debugger determine-test-runners dispatch-build-bottle edit extract
    find-appcast formula formula-analytics formula-python-resources
    generate-advisories-api generate-analytics-api generate-bottle-ci-matrix
    generate-cask-api generate-cask-ci-matrix generate-cask-token
    generate-formula-api generate-internal-api generate-man-completions
    generate-vulns-advisories generate-zap install-bundler-gems irb lgtm
    linkage livecheck pr-automerge pr-publish pr-pull pr-upload prof release
    rubocop ruby rubydoc sh style tap-new test test-bot tests typecheck
    unbottled unpack update-license-data update-maintainers
    update-perl-resources update-portable-ruby update-python-resources
    update-sponsors update-test vendor-gems verify which-update
    lc tc
)
_PINNED_COUNT=${#_DEVCMDS[@]}
# Widen with an installed Homebrew's own list (a newer Homebrew may add one).
for _dir in /opt/homebrew/Library/Homebrew/dev-cmd /usr/local/Homebrew/Library/Homebrew/dev-cmd; do
    [[ -d "$_dir" ]] || continue
    for _f in "$_dir"/*.(rb|sh)(N); do
        _DEVCMDS+=("${${_f:t}%.*}")
    done
done
_DEVCMDS=(${(u)_DEVCMDS})

# _scan_devcmds <file...> — print "file:line:text" for every line that RUNS
# `brew <developer command>`: `brew` in command position (the start of a line,
# after `$(`, `;`, `|`, `&`, `(`, `{` or a backquote, after if/then/do/else/
# elif/while/until/!/command/exec/time/nohup, or as xargs' command), options
# allowed before the command name, which must be a whole word. Comment lines
# are skipped, and so is a mention inside a string ("brew formula" is mod_09's
# label for a binary's source, not a call).
_scan_devcmds() {
    local _alt="${(j:|:)_DEVCMDS}"
    local _pre='(^|[;&|({`]|\$\(|(^|[[:space:]])(if|then|do|else|elif|while|until|!|command|exec|time|nohup)[[:space:]]|xargs[^|;]*[[:space:]])'
    grep -nE "${_pre}[[:space:]]*brew[[:space:]]+(-[^[:space:]]+[[:space:]]+)*(${_alt})([[:space:]]|\$|[;|&)\"'\`])" "$@" 2>/dev/null \
        | grep -vE '^([^:]+:)?[0-9]+:[[:space:]]*#'
}

(( _PINNED_COUNT >= 60 )) && _pass "devcmd: the pinned list has $_PINNED_COUNT names" \
                          || _fail "devcmd: the pinned list is too short ($_PINNED_COUNT)"

# The matcher has teeth: it finds a call in $(...), an alias, a condition, an
# xargs command and a call with an option first; it ignores mentions in
# strings, regular commands, comments and the word inside "homebrew".
cat > "$_SANDBOX/probe.sh" <<'EOF'
_v="$(brew ruby --version 2>/dev/null)"
    brew tc
if brew test foo; then :; fi
brew list --formula | xargs -I {} brew audit {}
brew --verbose livecheck x
_info "run 'brew audit' to check"
_source="brew formula"
brew config | grep Ruby
brew developer state
# brew ruby in a comment is not a call
echo "homebrew test suite"
EOF
_hits="$(_scan_devcmds "$_SANDBOX/probe.sh" | cut -d: -f1 | tr '\n' ' ')"
[[ "$_hits" == "1 2 3 4 5 " ]] && _pass "devcmd: the matcher catches every call form, and no mention, regular command or comment" \
                               || _fail "devcmd: the matcher caught lines [$_hits], expected [1 2 3 4 5 ]"

# The scan reads real code: brew_manager.sh, lib/ and every module. Anti-vacuity:
# it must see plenty of ordinary brew invocations, or it scanned nothing.
typeset -a _CODE=("$_ROOT/brew_manager.sh" "$_ROOT"/lib/*.sh(N) "$_ROOT"/modules/*.sh(N))
_calls="$(grep -cE '(^|[^[:alnum:]_./-])brew[[:space:]]+[a-z-]+' "${_CODE[@]}" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')"
(( ${#_CODE[@]} >= 10 && _calls >= 30 )) && _pass "devcmd: the scan covers ${#_CODE[@]} files and $_calls brew invocations" \
                                         || _fail "devcmd: the scan saw ${#_CODE[@]} files and $_calls invocations — too few"
_found="$(_scan_devcmds "${_CODE[@]}")"
if [[ -z "$_found" ]]; then
    _pass "devcmd: no Homebrew developer command in the code (${#_DEVCMDS[@]} names checked)"
else
    _fail "devcmd: developer command(s) in the code — running one turns developer mode on:"
    print -r -- "$_found" | sed "s|^$_ROOT/|        |"
fi

# ─────────────────────────────────────────────────────────────────────────────
# verdict + anti-vacuity
# ─────────────────────────────────────────────────────────────────────────────
print -r -- ""
if (( TESTS_RUN == 0 )); then
    print -r -- "FAIL: no checks executed (anti-vacuity guard)"
    exit 1
fi
if (( TESTS_FAILED > 0 )); then
    print -r -- "FAIL: ${TESTS_FAILED}/${TESTS_RUN} checks failed"
    exit 1
fi
print -r -- "ok: all ${TESTS_RUN} checks passed"
exit 0
