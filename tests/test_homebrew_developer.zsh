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
# `brew <developer command>`. `brew` must be in command position: the start of a
# line, after `$(`, `;`, `|`, `&`, `(`, `{` or a backquote, after if/then/do/
# else/elif/while/until/!, or as xargs' command — optionally behind variable
# assignments (`HOMEBREW_NO_AUTO_UPDATE=1 brew …`) and a wrapper (env, sudo,
# timeout, arch, nice, nohup, time, command, exec, with their arguments). `brew`
# may be a path (`/opt/homebrew/bin/brew`) or a variable named after it
# (`"$_brew_bin"`); options may come before the command name, which may be
# quoted and must be a whole word. Comment lines are skipped, and so is a mention
# inside a string ("brew formula" is mod_09's label for a binary's source).
_scan_devcmds() {
    local _alt="${(j:|:)_DEVCMDS}"
    local _pre='(^|[;&|({`]|\$\(|(^|[[:space:]])(if|then|do|else|elif|while|until|!)[[:space:]]|xargs[^|;]*[[:space:]])'
    local _asg='([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'
    local _wrap='((env|sudo|timeout|arch|nice|nohup|time|command|exec)([[:space:]]+[^[:space:]]+)*[[:space:]]+)?'
    local _bin='("?\$\{?[A-Za-z0-9_]*brew[A-Za-z0-9_]*\}?"?|([^[:space:]"'"'"'`;|&()]*/)?brew)'
    grep -nE "${_pre}[[:space:]]*${_asg}${_wrap}${_asg}${_bin}[[:space:]]+(-[^[:space:]]+[[:space:]]+)*[\"']?(${_alt})[\"']?([[:space:]]|\$|[;|&)\"'\`])" "$@" 2>/dev/null \
        | grep -vE '^([^:]+:)?[0-9]+:[[:space:]]*#'
}

(( _PINNED_COUNT >= 60 )) && _pass "devcmd: the pinned list has $_PINNED_COUNT names" \
                          || _fail "devcmd: the pinned list is too short ($_PINNED_COUNT)"

# The matcher has teeth: it finds every call form above (lines 1-14) and ignores
# mentions in strings, regular commands, comments and the word inside "homebrew".
cat > "$_SANDBOX/probe.sh" <<'EOF'
_v="$(brew ruby --version 2>/dev/null)"
    brew tc
if brew test foo; then :; fi
brew list --formula | xargs -I {} brew audit {}
brew --verbose livecheck x
HOMEBREW_NO_AUTO_UPDATE=1 brew ruby -e 1
env HOMEBREW_X=1 brew audit foo
/opt/homebrew/bin/brew ruby -e 1
"$_brew_bin" ruby -e 1
timeout 10 brew livecheck x
arch -arm64 brew test x
sudo -u me brew edit x
brew "ruby" -e 1
brew 'tc'
_info "run 'brew audit' to check"
_source="brew formula"
brew config | grep Ruby
brew developer state
HOMEBREW_NO_AUTO_UPDATE=1 brew list --formula
# brew ruby in a comment is not a call
echo "homebrew test suite"
EOF
_hits="$(_scan_devcmds "$_SANDBOX/probe.sh" | cut -d: -f1 | tr '\n' ' ')"
[[ "$_hits" == "1 2 3 4 5 6 7 8 9 10 11 12 13 14 " ]] \
    && _pass "devcmd: the matcher catches every call form (14), and no mention, regular command or comment" \
    || _fail "devcmd: the matcher caught lines [$_hits], expected [1 … 14]"

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
# A git repository with a local change, for the "brew update stashes it" notice.
mkdir -p "$_SANDBOX/dirtyrepo"
git -C "$_SANDBOX/dirtyrepo" init -q 2>/dev/null && print -r -- x > "$_SANDBOX/dirtyrepo/local-change"
# The mock plays Homebrew's developer mode from the state file — env-aware as
# Homebrew is: "env" and "both" print the variable's message only while
# HOMEBREW_DEVELOPER is set (otherwise "disabled" / the setting's message), and
# "pinned" adds the HOMEBREW_UPDATE_TO_TAG line.
cat > "$_MOCKDIR/brew" <<EOF
#!/bin/zsh
print -r -- "\$*" >> "$_CALLS"
_dev='Developer mode is enabled because HOMEBREW_DEVELOPER is set.'
_set='Developer mode is enabled because a developer command or \`brew developer on\` was run.'
case "\$1" in
    developer)
        case "\$2" in
            ""|state)
                [[ -n "\$MOCK_STATE_FAIL" ]] && exit 1
                case "\$(cat "$_STATEF")" in
                    off)     print -r -- "Developer mode is disabled."
                             print -r -- "\\\`brew update\\\` will update to the latest stable tag." ;;
                    setting) print -r -- "\$_set"
                             print -r -- "\\\`brew update\\\` will update to the latest commit on the \\\`main\\\` branch." ;;
                    pinned)  print -r -- "\$_set"
                             print -r -- "However, \\\`brew update\\\` will update to the latest stable tag because HOMEBREW_UPDATE_TO_TAG is set." ;;
                    env)     if [[ -n "\$HOMEBREW_DEVELOPER" ]]; then print -r -- "\$_dev"; else print -r -- "Developer mode is disabled."; fi ;;
                    both)    if [[ -n "\$HOMEBREW_DEVELOPER" ]]; then print -r -- "\$_dev"; else print -r -- "\$_set"; fi ;;
                    *)       print -r -- "Something Homebrew never said." ;;
                esac ;;
            off)
                [[ -n "\$MOCK_OFF_FAIL" ]] && { print -r -- "Error: cannot write the setting"; exit 1; }
                [[ "\$(cat "$_STATEF")" == (setting|pinned) ]] && print -r -- off > "$_STATEF" ;;
        esac ;;
    update)
        [[ -n "\$MOCK_UPDATE_FAIL" ]] && { print -r -- "Error: network down"; exit 1; }
        print -r -- "Updated Homebrew from 6.0.21-70-g2316567 to 7.0.8." ;;
    --version)    print -r -- "Homebrew \${MOCK_VERSION:-7.0.8}" ;;
    config)       print -r -- "HOMEBREW_VERSION: 7.0.8"
                  print -r -- "Homebrew Ruby: 9.9.9 => /mock/ruby" ;;
    --prefix)     print -r -- "$_SANDBOX/prefix" ;;
    --repository) print -r -- "\${MOCK_REPO:-$_SANDBOX/repo}" ;;
    doctor)       print -r -- "Your system is ready to brew." ;;
esac
exit 0
EOF
chmod +x "$_MOCKDIR/brew"
_SAFE_PATH="$_MOCKDIR:/usr/bin:/bin:/usr/sbin:/sbin"

# _dev_case <state> <dry> <yes> <noninteractive> [VAR=value ...] → the output of
# _m01_developer_mode; the calls it made are in $_CALLS. Feed stdin at the call
# site to answer the prompt. No version argument: the function asks the mock.
_dev_case() {
    local _st="$1" _dry="$2" _yes="$3" _ni="$4"; shift 4
    print -r -- "$_st" > "$_STATEF"; : > "$_CALLS"
    (
        PATH="$_SAFE_PATH"
        unset HOMEBREW_DEVELOPER HOMEBREW_DEV_CMD_RUN HOMEBREW_UPDATE_TO_TAG
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
_READ='developer state | --version | --repository'           # the setting, read-only part
_RESTORE="$_READ | developer off | update | developer state | --version"

# (a) off on a release: green, nothing offered; off NOT on a release: yellow advice
_out="$(_dev_case off 0 1 1 </dev/null)"
[[ "$(_calls)" == "developer state | --version" && "$_out" == *"off — Homebrew 7.0.8, a stable release"* ]] \
    && _pass "off on a release: green, only read" \
    || _fail "off: calls [$(_calls)], output: $_out"
_out="$(_dev_case off 0 1 1 MOCK_VERSION=6.0.21-70-g2316567 </dev/null)"
[[ "$(_calls)" == "developer state | --version" && "$_out" == *"not a release — run brew update"* ]] \
    && _pass "off but on a main-branch commit: reported, advice only, nothing run" \
    || _fail "off, not a release: calls [$(_calls)], output: $_out"

# (b) the setting, --dry-run (with --yes too): a preview, no confirmation, nothing changed
_out="$(_dev_case setting 1 1 1 </dev/null)"
if [[ "$(_calls)" == "$_READ" && "$_out" == *"set by a developer command or 'brew developer on'"* \
      && "$_out" == *"would run: brew developer off, then brew update"* \
      && "$_out" != *"Restore Homebrew's stable releases"* && "$_out" != *"[auto:"* \
      && "$(<"$_STATEF")" == setting ]]; then
    _pass "setting + --dry-run --yes: a preview, no confirmation box, no off, no update"
else
    _fail "setting + --dry-run: calls [$(_calls)], state $(<"$_STATEF"), output: $_out"
fi
_out="$(print -r -- y | _dev_case setting 1 0 0)"
[[ "$(_calls)" == "$_READ" && "$_out" != *"(y/N)"* && "$(<"$_STATEF")" == setting ]] \
    && _pass "setting + --dry-run at a prompt with 'y' typed: never asked, nothing run" \
    || _fail "setting + --dry-run at a prompt: calls [$(_calls)], output: $_out"

# (c) the setting, no terminal, no --yes: declined (fail-closed)
_out="$(_dev_case setting 0 0 1 </dev/null)"
[[ "$(_calls)" == "$_READ" && "$_out" == *"left on"* && "$(<"$_STATEF")" == setting ]] \
    && _pass "setting, no terminal, no --yes: declined, nothing run" \
    || _fail "setting, no terminal: calls [$(_calls)], output: $_out"

# (d) the setting, --yes: shown (from → to), then off, update, re-read — in order
_out="$(_dev_case setting 0 1 1 </dev/null)"
if [[ "$(_calls)" == "$_RESTORE" && "$(<"$_STATEF")" == off \
      && "$_out" == *"From: Homebrew 7.0.8"* && "$_out" == *"off — Homebrew 7.0.8, a stable release"* ]]; then
    _pass "setting + --yes: shown, then brew developer off, brew update, re-read: off on a release"
else
    _fail "setting + --yes: calls [$(_calls)], state $(<"$_STATEF"), output: $_out"
fi

# (e) the setting at a prompt: an explicit "y" restores; Enter declines
_out="$(print -r -- y | _dev_case setting 0 0 0)"
[[ "$(_calls)" == "$_RESTORE" ]] \
    && _pass "setting at a prompt, answer 'y': restored" \
    || _fail "setting at a prompt, 'y': calls [$(_calls)]"
_out="$(print -r -- "" | _dev_case setting 0 0 0)"
[[ "$(_calls)" == "$_READ" && "$(<"$_STATEF")" == setting ]] \
    && _pass "setting at a prompt, Enter: declined (the default is shown as N)" \
    || _fail "setting at a prompt, Enter: calls [$(_calls)]"

# (f) the environment: reported, never "fixed", even under --yes — HOMEBREW_DEVELOPER,
#     HOMEBREW_DEV_CMD_RUN (Homebrew's `state` would say "disabled"), and the variable
#     together with the setting (the advice names both)
_out="$(_dev_case env 0 1 1 HOMEBREW_DEVELOPER=1 </dev/null)"
[[ "$(_calls)" == "developer state | developer state" && "$_out" == *"HOMEBREW_DEVELOPER is set in your environment"* \
      && "$_out" == *"shell profile"* && "$_out" != *"setting is on as well"* ]] \
    && _pass "HOMEBREW_DEVELOPER + --yes: reported, the environment left alone, nothing run" \
    || _fail "HOMEBREW_DEVELOPER: calls [$(_calls)], output: $_out"
_out="$(_dev_case off 0 1 1 HOMEBREW_DEV_CMD_RUN=1 </dev/null)"
[[ "$(_calls)" == "developer state" && "$_out" == *"HOMEBREW_DEV_CMD_RUN is set in your environment"* ]] \
    && _pass "HOMEBREW_DEV_CMD_RUN + --yes: reported as on although 'state' says disabled, nothing run" \
    || _fail "HOMEBREW_DEV_CMD_RUN: calls [$(_calls)], output: $_out"
_out="$(_dev_case both 0 1 1 HOMEBREW_DEVELOPER=1 </dev/null)"
[[ "$(_calls)" == "developer state | developer state" && "$_out" == *"setting is on as well"* && "$(<"$_STATEF")" == both ]] \
    && _pass "HOMEBREW_DEVELOPER and the setting: both named, nothing run" \
    || _fail "variable + setting: calls [$(_calls)], output: $_out"

# (g) an unreadable state (an unknown message, or a failed call): reported, never acted on
_out="$(_dev_case reworded 0 1 1 </dev/null)"
_out2="$(_dev_case setting 0 1 1 MOCK_STATE_FAIL=1 </dev/null)"
[[ "$_out" == *"could not be read"* && "$_out2" == *"could not be read"* && "$(_calls)" == "developer state" ]] \
    && _pass "unknown state (reworded or failed): reported, nothing offered, nothing run" \
    || _fail "unknown state: calls [$(_calls)], outputs: $_out / $_out2"

# (h) a failed `developer off` stops before the update; a failed update is reported
_out="$(_dev_case setting 0 1 1 MOCK_OFF_FAIL=1 </dev/null)"
[[ "$(_calls)" == "$_READ | developer off" && "$_out" == *"brew developer off failed (exit status 1)"* ]] \
    && _pass "developer off fails: reported, brew update not run" \
    || _fail "developer off fails: calls [$(_calls)], output: $_out"
_out="$(_dev_case setting 0 1 1 MOCK_UPDATE_FAIL=1 </dev/null)"
[[ "$(_calls)" == "$_READ | developer off | update" && "$_out" == *"brew update failed (exit status 1)"* ]] \
    && _pass "brew update fails: reported, nothing claimed" \
    || _fail "brew update fails: calls [$(_calls)], output: $_out"

# (j) HOMEBREW_UPDATE_TO_TAG with the setting: no false "follows main"; local
#     changes in Homebrew's repository: the stash is announced (preview and box)
_out="$(_dev_case pinned 1 0 1 </dev/null)"
[[ "$_out" == *"still follows stable releases here (HOMEBREW_UPDATE_TO_TAG"* && "$_out" != *"follows Homebrew's main branch"* ]] \
    && _pass "setting + HOMEBREW_UPDATE_TO_TAG: reported as still on stable, no false claim" \
    || _fail "pinned: output: $_out"
_out="$(_dev_case setting 1 0 1 MOCK_REPO="$_SANDBOX/dirtyrepo" </dev/null)"
_out2="$(_dev_case setting 0 0 1 MOCK_REPO="$_SANDBOX/dirtyrepo" </dev/null)"
[[ "$_out" == *"would stash them and not restore them"* && "$_out2" == *"stashes them and does not restore them"* ]] \
    && _pass "local changes in Homebrew's repository: announced in the preview and in the confirmation box" \
    || _fail "dirty repository: outputs: $_out / $_out2"

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
