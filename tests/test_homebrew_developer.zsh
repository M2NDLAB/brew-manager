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
# 2. Detection and restore in module 1, against a mock brew
# ─────────────────────────────────────────────────────────────────────────────
# The mock records every call with its arguments, plays Homebrew's developer
# mode from a state file (off | setting | env | anything else), and flips the
# setting to off on `developer off`, as Homebrew does. MOCK_* variables make a
# step fail. Each case runs in a subshell with the sandbox PATH and the safety
# flags, so nothing leaks into the next one; every case also proves that no
# developer command was ever called (the runtime half of section 1).
source "$_ROOT/lib/common.sh"           || { print -r -- "cannot source lib/common.sh"; exit 1; }
source "$_ROOT/lib/selection.sh"        || { print -r -- "cannot source lib/selection.sh"; exit 1; }
source "$_ROOT/modules/mod_01_health.sh" || { print -r -- "cannot source mod_01"; exit 1; }
TUI_COLOR_LEVEL=0; _init_palette; TUI_UNICODE=0; _init_symbols; TUI_TTY=0

_MOCKDIR="$_SANDBOX/mock"; _STATEF="$_SANDBOX/devstate"; _CALLS="$_MOCKDIR/brew_calls"
mkdir -p "$_MOCKDIR" "$_SANDBOX/prefix" "$_SANDBOX/repo"
cat > "$_MOCKDIR/brew" <<EOF
#!/bin/zsh
print -r -- "\$*" >> "$_CALLS"
case "\$1" in
    developer)
        case "\$2" in
            ""|state)
                [[ -n "\$MOCK_STATE_FAIL" ]] && exit 1
                case "\$(cat "$_STATEF")" in
                    off)     print -r -- "Developer mode is disabled."
                             print -r -- "\\\`brew update\\\` will update to the latest stable tag." ;;
                    setting) print -r -- "Developer mode is enabled because a developer command or \\\`brew developer on\\\` was run."
                             print -r -- "\\\`brew update\\\` will update to the latest commit on the \\\`main\\\` branch." ;;
                    env)     print -r -- "Developer mode is enabled because HOMEBREW_DEVELOPER is set." ;;
                    *)       print -r -- "Something Homebrew never said." ;;
                esac ;;
            off)
                [[ -n "\$MOCK_OFF_FAIL" ]] && { print -r -- "Error: cannot write the setting"; exit 1; }
                [[ "\$(cat "$_STATEF")" == setting ]] && print -r -- off > "$_STATEF" ;;
        esac ;;
    update)
        [[ -n "\$MOCK_UPDATE_FAIL" ]] && { print -r -- "Error: network down"; exit 1; }
        print -r -- "Updated Homebrew from 6.0.21-70-g2316567 to 7.0.8." ;;
    --version)    print -r -- "Homebrew 7.0.8" ;;
    config)       print -r -- "HOMEBREW_VERSION: 7.0.8"
                  print -r -- "Homebrew Ruby: 9.9.9 => /mock/ruby" ;;
    --prefix)     print -r -- "$_SANDBOX/prefix" ;;
    --repository) print -r -- "$_SANDBOX/repo" ;;
    doctor)       print -r -- "Your system is ready to brew." ;;
esac
exit 0
EOF
chmod +x "$_MOCKDIR/brew"
_SAFE_PATH="$_MOCKDIR:/usr/bin:/bin:/usr/sbin:/sbin"

# _dev_case <state> <dry> <yes> <noninteractive> [VAR=value ...] → the output of
# _m01_developer_mode; the calls it made are in $_CALLS. Feed stdin at the call
# site to answer the prompt.
_dev_case() {
    local _st="$1" _dry="$2" _yes="$3" _ni="$4"; shift 4
    print -r -- "$_st" > "$_STATEF"; : > "$_CALLS"
    (
        PATH="$_SAFE_PATH"
        BREW_MANAGER_DRY_RUN=$_dry BREW_MANAGER_YES=$_yes BREW_MANAGER_NONINTERACTIVE=$_ni
        (( $# )) && export "$@"
        _m01_developer_mode 2>&1
    )
}
# _calls → the recorded calls on one line, separated by " | ".
_calls() { [[ -s "$_CALLS" ]] && print -r -- "${(j: | :)${(f)$(<"$_CALLS")}}"; }
# _no_devcmd_called — no recorded call starts with a developer command name.
_no_devcmd_called() {
    local _c
    for _c in ${(f)"$(<"$_CALLS")"}; do
        (( ${_DEVCMDS[(Ie)${_c%% *}]} )) && return 1
    done
    return 0
}

# (a) off: a green row, nothing offered, only the read
_out="$(_dev_case off 0 1 1 </dev/null)"
[[ "$(_calls)" == "developer state" && "$_out" == *"Developer mode"*"off"* ]] \
    && _pass "off: reported as off, only 'brew developer state' was called" \
    || _fail "off: calls [$(_calls)], output: $_out"

# (b) the setting, --dry-run (with --yes too): a preview, nothing changed
_out="$(_dev_case setting 1 1 1 </dev/null)"
if [[ "$(_calls)" == "developer state" && "$_out" == *"ON"* && "$_out" == *"would run: brew developer off, then brew update"* \
      && "$(<"$_STATEF")" == setting ]]; then
    _pass "setting + --dry-run --yes: a preview, no off, no update, the setting untouched"
else
    _fail "setting + --dry-run: calls [$(_calls)], state $(<"$_STATEF"), output: $_out"
fi

# (c) the setting, no terminal, no --yes: declined (fail-closed)
_out="$(_dev_case setting 0 0 1 </dev/null)"
[[ "$(_calls)" == "developer state" && "$_out" == *"left on"* && "$(<"$_STATEF")" == setting ]] \
    && _pass "setting, no terminal, no --yes: declined, nothing run" \
    || _fail "setting, no terminal: calls [$(_calls)], output: $_out"

# (d) the setting, --yes: off, then update, then the re-read — in that order
_out="$(_dev_case setting 0 1 1 </dev/null)"
if [[ "$(_calls)" == "developer state | developer off | update | developer state | --version" \
      && "$(<"$_STATEF")" == off && "$_out" == *"off — Homebrew 7.0.8"* ]]; then
    _pass "setting + --yes: brew developer off, then brew update, then re-read: off, Homebrew 7.0.8"
else
    _fail "setting + --yes: calls [$(_calls)], state $(<"$_STATEF"), output: $_out"
fi

# (e) the setting at a prompt: an explicit "y" restores; Enter declines
_out="$(print -r -- y | _dev_case setting 0 0 0)"
[[ "$(_calls)" == "developer state | developer off | update | developer state | --version" ]] \
    && _pass "setting at a prompt, answer 'y': restored" \
    || _fail "setting at a prompt, 'y': calls [$(_calls)]"
_out="$(print -r -- "" | _dev_case setting 0 0 0)"
[[ "$(_calls)" == "developer state" && "$(<"$_STATEF")" == setting ]] \
    && _pass "setting at a prompt, Enter: declined (the default is shown as N)" \
    || _fail "setting at a prompt, Enter: calls [$(_calls)]"

# (f) HOMEBREW_DEVELOPER: reported, never "fixed", even under --yes
_out="$(_dev_case env 0 1 1 </dev/null)"
[[ "$(_calls)" == "developer state" && "$_out" == *"HOMEBREW_DEVELOPER is set"* && "$_out" == *"shell profile"* ]] \
    && _pass "HOMEBREW_DEVELOPER + --yes: reported, the user's environment left alone, nothing run" \
    || _fail "HOMEBREW_DEVELOPER: calls [$(_calls)], output: $_out"

# (g) an unreadable state (an unknown message, or a failed call): reported, never acted on
_out="$(_dev_case reworded 0 1 1 </dev/null)"
_out2="$(_dev_case setting 0 1 1 MOCK_STATE_FAIL=1 </dev/null)"
[[ "$_out" == *"could not be read"* && "$_out2" == *"could not be read"* && "$(_calls)" == "developer state" ]] \
    && _pass "unknown state (reworded or failed): reported, nothing offered, nothing run" \
    || _fail "unknown state: calls [$(_calls)], outputs: $_out / $_out2"

# (h) a failed `developer off` stops before the update; a failed update is reported
_out="$(_dev_case setting 0 1 1 MOCK_OFF_FAIL=1 </dev/null)"
[[ "$(_calls)" == "developer state | developer off" && "$_out" == *"brew developer off failed (exit status 1)"* ]] \
    && _pass "developer off fails: reported, brew update not run" \
    || _fail "developer off fails: calls [$(_calls)], output: $_out"
_out="$(_dev_case setting 0 1 1 MOCK_UPDATE_FAIL=1 </dev/null)"
[[ "$(_calls)" == "developer state | developer off | update" && "$_out" == *"brew update failed (exit status 1)"* ]] \
    && _pass "brew update fails: reported, nothing claimed" \
    || _fail "brew update fails: calls [$(_calls)], output: $_out"

# (i) the whole module 1 under --dry-run, with the setting on: the check is wired
#     in, the preview shows, Ruby comes from `brew config`, and no developer
#     command and no change happen. Module 1 still writes brew doctor's output to
#     the fixed /tmp/brew_doctor.log (STATE #11): it is moved aside and restored,
#     and a symlink there makes the suite refuse, as in test_dryrun_gates.zsh.
_DOCLOG=/tmp/brew_doctor.log
if [[ -L "$_DOCLOG" ]]; then
    _fail "module 1: $_DOCLOG is a symlink — refusing to run module 1"
else
    [[ -f "$_DOCLOG" ]] && cp -p "$_DOCLOG" "$_SANDBOX/doctor.saved"
    print -r -- setting > "$_STATEF"; : > "$_CALLS"
    _out="$( PATH="$_SAFE_PATH"; BREW_MANAGER_DRY_RUN=1 BREW_MANAGER_YES=1 BREW_MANAGER_NONINTERACTIVE=1 _module_1 2>&1 </dev/null )"
    if [[ -f "$_SANDBOX/doctor.saved" ]]; then cp -p "$_SANDBOX/doctor.saved" "$_DOCLOG"; else rm -f "$_DOCLOG"; fi
    if [[ "$_out" == *"would run: brew developer off"* && "$_out" == *"9.9.9"* && "$_out" == *"Homebrew code dated"* \
          && "$(<"$_STATEF")" == setting ]] && ! grep -qxE 'developer off|update' "$_CALLS"; then
        _pass "module 1 --dry-run: the check runs, the preview shows, Ruby from brew config, nothing changed"
    else
        _fail "module 1 --dry-run: calls [$(_calls)], state $(<"$_STATEF")"
    fi
    _no_devcmd_called && _pass "module 1: no developer command called at run time" \
                      || _fail "module 1: a developer command was called: [$(_calls)]"
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
