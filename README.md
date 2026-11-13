<div align="center">

# 🍺 brew-manager

**A modular, interactive TUI tool for macOS that gives you complete visibility and control over your Homebrew installation.**

[![macOS](https://img.shields.io/badge/macOS-12%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![zsh](https://img.shields.io/badge/shell-zsh-green)](https://www.zsh.org/)
[![Homebrew](https://img.shields.io/badge/Homebrew-4.x%2B-orange?logo=homebrew)](https://brew.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

*Developed by [M2NDLAB](https://github.com/M2NDLAB/brew-manager)*

</div>

---

## Why this exists

If you use Homebrew regularly, you know the feeling: your Mac accumulates apps installed manually that could be managed by brew, packages that haven't been updated in months because they self-update and `brew upgrade` silently skips them, orphan libraries taking up gigabytes of disk space, and binaries in `/usr/local/bin` placed there by some installer you don't remember.

The standard Homebrew CLI is excellent for installing and updating software — but it doesn't give you a clear picture of the state of your system. You have to run a dozen commands and mentally connect the output.

**brew-manager** was built to fill that gap.

It is a single shell script that runs entirely in your terminal, requires nothing beyond what macOS already has installed, and captures every session to a log file. Every module starts with a plain-language explanation of what it does and why — so you always know what you are running before it runs.

It is **not** a replacement for Homebrew. It is a maintenance and audit layer on top of it.

---

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| macOS | 12 Monterey or later | Apple Silicon (M-series) and Intel both supported |
| zsh | 5.8 or later | Default shell on macOS since Catalina (2019) |
| Homebrew | 4.x or later | Uses JSON API — no local core/cask clone needed |
| Python 3 | any | Pre-installed on macOS — used for fast JSON parsing in module 3 |

brew-manager finds Homebrew on your `PATH` or, when the `PATH` lacks it — a job started
by launchd, an app started from the Finder — at its standard prefix: `/opt/homebrew`
(Apple Silicon) is tried first, then `/usr/local` (Intel); a `brew` executable already
on your `PATH` is always used as it is. A shell function or alias named `brew` does not
count as Homebrew being installed, but if `~/.zshenv` defines one, brew-manager's
commands still go through it. A run started by launchd does not read your shell
profiles, so `HOMEBREW_*` settings exported in `~/.zprofile` or `~/.zshrc` (such as
`HOMEBREW_NO_ANALYTICS`) do not reach it: put those in `~/.zshenv`, or use a
persistent setting such as `brew analytics off`. If Homebrew is missing altogether, the tool
offers to install it only at an interactive terminal and only after you confirm —
never under `--dry-run`, never without a terminal — and otherwise exits with status
`69` without running anything.

---

## Installation

```bash
git clone https://github.com/M2NDLAB/brew-manager.git
cd brew-manager
chmod +x brew_manager.sh
```

> **Note:** only `brew_manager.sh` needs to be executable. All files in `lib/` and `modules/` are sourced by the main script at runtime — they do not need `chmod`.

The script resolves its own location automatically, so you can run it from any working directory:

```bash
# From inside the project folder
./brew_manager.sh

# From anywhere on your system
~/Dev/brew-manager/brew_manager.sh

# Or add it to your PATH in ~/.zshrc
export PATH="$PATH:$HOME/Dev/brew-manager"
```

---

## Upgrading from 1.x

2.0.0 makes brew-manager a personal terminal tool for one Mac. It removes the four modules that were selected by name — `bk` (Brewfile backup and restore), `las` (the LaunchAgent scheduler), `log` (the log manager) and `mas` (Mac App Store) — and retires module `10` (greedy upgrades of the casks that update themselves). The ids `bk`, `las`, `log`, `mas` and `10` are reserved: they are never given to another module, and a selection that names one exits `2` without running anything, with a pointer to the [CHANGELOG](CHANGELOG.md).

**Remove your scheduled agents first, before you update past the `v1.5.0` tag.** 2.0.0 has no scheduler, so nothing in brew-manager can list or remove the LaunchAgents that `las` installed. Before you update, run `./brew_manager.sh las` and remove the agents you no longer want (option `5`). An agent you keep goes on running after the update: one whose selection names a removed id fails at every run with status `2`, and one that runs `go --yes` — as the weekly and daily presets do — still runs every module: `brew update`, module `5`'s cleanup and, where a developer command left Homebrew's developer mode on (1.x's module `1` did, at every run), module `1`'s restore of Homebrew's stable releases.

**If you have already updated**, go back to 1.5.0 for that one step, from the brew-manager folder: `git checkout v1.5.0`, then `./brew_manager.sh las`, then `git checkout main`. Or check what is left with these two read-only commands:

```bash
ls ~/Library/LaunchAgents | grep '^com\.m2ndlab\.brew-manager\.'
launchctl list | grep 'com\.m2ndlab\.brew-manager\.'
```

Only if the first one listed something, stop each agent and delete its plist (`rm -i` asks before each deletion):

```bash
for p in ~/Library/LaunchAgents/com.m2ndlab.brew-manager.*.plist(N); do launchctl bootout gui/$(id -u) "$p"; rm -i -- "$p"; done
```

Only if the second one listed a label whose plist is already gone:

```bash
launchctl list | awk '$3 ~ /^com\.m2ndlab\.brew-manager\./ {print $3}' | while read -r l; do launchctl bootout "gui/$(id -u)/$l"; done
```

`(N)` is zsh syntax, the default shell on macOS: with no plist left, the first loop does nothing. The loop stops each agent before it deletes its plist; the second command is for a label that is still loaded after its plist is gone.

**Leftover files.** The commands in this paragraph run from the brew-manager folder. brew-manager no longer reads or writes `agents/` (the agents' configurations and activity log) or `backups/` (the Brewfile backups), and it never deletes them for you. A Brewfile in `backups/` is still a snapshot of your packages, and `brew bundle install --file=backups/Brewfile` installs and upgrades everything it lists — read the file first: it is Ruby code, which Homebrew runs as it is. That command also updates Homebrew itself first (unless `HOMEBREW_NO_AUTO_UPDATE` is set), upgrades what is already installed unless you add `--no-upgrade`, and turns the file's `trusted:` options into entries of Homebrew's trust store. The agents wrote their output to `logs/agent_stdout_*.log` and `logs/agent_stderr_*.log`. Look at what is there with `ls -la agents backups`, then remove what you no longer need by hand — for example `rm -ri -- agents backups`, which asks before each deletion. Both folders stay in `.gitignore`, so a leftover one is never committed by mistake. If you updated by copying the new files over the old folder rather than with `git pull`, the five old module files are still in `modules/` — `mod_bk_brewfile.sh`, `mod_las_scheduler.sh`, `mod_log_manager.sh`, `mod_mas_mas.sh` and `mod_10_greedy.sh` — and brew-manager loads every `modules/mod_*.sh` file it finds: delete those five too.

**What replaces the removed modules:** `brew bundle dump --file=<path>` writes a Brewfile of what is installed, `brew upgrade --cask --greedy` re-syncs the casks whose apps updated themselves, the App Store app (or the third-party `mas` tool) updates App Store apps, and the session logs are plain files you browse and prune yourself (see [Session logging](#session-logging)).

---

## Usage

### Interactive TUI

```bash
./brew_manager.sh
```

Launches a full-screen terminal interface showing all available modules. Type `go` to run the complete audit sequence, or enter specific module numbers to run only what you need.

At the top of each module you will see an **About this module** section explaining in plain language what the module does, what it checks, and what actions it can take — before anything runs.

Every module also carries a **risk badge** that makes its blast radius visible at a glance — shown beside the module in the menu and in its About section:

| Badge | Meaning |
|-------|---------|
| `[RO]` | **Read-only** — inspects and reports, changes nothing. |
| `[W]`  | **Writes metadata, cache or Homebrew's settings** — refreshes Homebrew's index, changes a Homebrew setting after you confirm (module `1`), or writes the tool's own files; never installs or removes a package. |
| `[!]`  | **Can change your system** — removes packages/cache, installs or upgrades packages, or adopts apps. |

Before a `[!]` action actually runs, brew-manager draws a **framed danger box** that names the exact command and spells out what it will do, then asks you to confirm. Under `--dry-run` you get a preview instead and are never asked; in an unattended run consent still comes only from `--yes` (see [Available flags](#available-flags)).

While a long operation is in flight (`brew doctor`, `brew update`) a **spinner** shows it is still working, with the seconds elapsed. It only animates on a real terminal: piped output and runs without a terminal get a single static line per operation instead, so the log stays clean.

### The session summary

Every run ends with a **session summary**: one row per module in the order it ran, with the time it took, then the totals the modules collected, the Homebrew cache before and after, and the path of the session log.

A real `./brew_manager.sh 1,2,5,7 --dry-run`, the rows and the disk line:

```
  ⚠      1  System health          3s   ran anyway (no --dry-run gate)
  ↷      2  Database update        1s   preview (--dry-run)
  ↷      5  Cleanup                3s   preview (--dry-run)
  ✓      7  Services               0s

  ✓    completed    ↷    previewed, nothing changed    ⚠    acted despite --dry-run
  Disk   cache 3.7G → 3.7G  (grew ~8K)
```

| Mark | Meaning |
|------|---------|
| `✓` (`[OK]`) | The module ran to completion. |
| `↷` (`[--]`) | `--dry-run`: the module previewed its actions and changed nothing. |
| `⚠` (`[!]`) | `--dry-run` was requested, but this module has no dry-run gate and acted anyway. |

Read-only modules show `✓` even under `--dry-run` — they only inspect, so a dry run is their normal work.

One module still carries the `⚠` mark, and the summary says so rather than claiming a preview that did not happen:

- **`1`** — it writes the output of `brew doctor` to a scratch file, `/tmp/brew_doctor.log`, and when a developer command or `brew developer on` left Homebrew's developer mode on, it runs `git status` in Homebrew's repository, which may rewrite that repository's index file. The developer-mode restore itself is only previewed.

Every other module stops at a preview: nothing is installed, removed, upgraded or overwritten. A dry run also sets `HOMEBREW_NO_AUTO_UPDATE`, because Homebrew otherwise refreshes its package index by itself before commands such as `brew outdated` — so even the modules that only *list* packages used to leave the index rewritten behind them.

Without a UTF-8 terminal the marks degrade to `[OK]` / `[--]` / `[!]`. The disk line appears only when a module measured the cache (today, module `5`); the "after" figure is taken at the end of the run, so later modules that download into the cache are reflected in it. Even a dry run can show the cache grow by a few kilobytes, as in the example: Homebrew keeps its own Ruby compile cache in there, and any `brew` command may update it.

### Choosing what to run

You can choose the modules **on the command line** or **interactively** — whichever fits.

**On the command line** — pass the selection as a positional argument. The run is then non-interactive and skips the menu:

```bash
./brew_manager.sh go            # every module, 0 to 13 (there is no 10)
./brew_manager.sh 1,4,5         # only these, in this order
./brew_manager.sh 5,2,0         # any order, duplicates allowed
```

Refine a selection with `--only` (keep only these) or `--skip` (remove these):

```bash
./brew_manager.sh go --skip=5,13    # every module except 5 and 13
./brew_manager.sh go --only=0,4     # only 0 and 4 out of the full sequence
```

An unknown module token is **rejected with an error and a non-zero exit** — nothing runs, never silently skipped — so a typo can't run a different set of modules than you intended. A module removed in 2.0.0 (`bk`, `las`, `log`, `mas`, `10`) is an unknown token like any other, and the error adds a line that points to the CHANGELOG. (Inside the interactive prompt an unknown token is instead warned about and skipped.)

**Interactively** — start the script with no selection and type your choice at the `Choice` prompt:

```
→  Choice [go / numbers, default: go]: go       # every module, 0 to 13 (there is no 10)
→  Choice [go / numbers, default: go]: 1,4,5    # only these, in this order
```

Flags change **how** the run behaves and combine with either form:

```bash
# Preview the full sequence: nothing is installed, removed, upgraded or adopted
./brew_manager.sh go --dry-run

# Unattended full run: every question is auto-answered with its built-in default
./brew_manager.sh go --yes

# Run modules 0 and 4, pre-answering their adoption/upgrade prompts
./brew_manager.sh 0,4 --adopt=all --upgrade=y

# Print the version and exit
./brew_manager.sh --version
```

> What makes a run non-interactive is a **selection**: a positional spec, or a `--only` / `--skip` filter (which imply a `go` base — e.g. `./brew_manager.sh --skip=5` runs everything except module 5, unattended). A behaviour-only flag such as `--dry-run` or `--yes` on its own, with no selection, still drops to the interactive menu.

### Available flags

| Flag | What it does |
|------|--------------|
| `--yes` / `-y` | Skips all interactive prompts and uses each prompt's built-in default. Almost all action defaults are conservative: adoption and upgrades happen only if you opt in with `--adopt=` / `--upgrade=`. Two prompts deliberately default to *yes*: module `5`'s cleanup, so that a run you start with `--yes` frees disk space, and module `1`'s developer-mode restore (`brew developer off`, then `brew update`, which stashes any local change in Homebrew's repository), offered only when a developer command or `brew developer on` left developer mode on. Add `--skip=1,5` (or `--dry-run`) if you don't want them. |
| `--dry-run` | Preview mode: shows what would happen, and installs, removes, upgrades and adopts nothing. Overrides `--yes` — even combined with it, a dry run only previews. It also sets `HOMEBREW_NO_AUTO_UPDATE` for the session, so Homebrew does not refresh its index behind your back while you are only looking. Module `1` still writes a scratch file and may rewrite the index of Homebrew's own repository — see [the session summary](#the-session-summary). |
| `--adopt=n\|all\|1,2` | Pre-answers the adoption prompt in module `0`. In an unattended run (`--yes`) this is the only way to have apps adopted. |
| `--upgrade=y\|n` | Pre-answers the upgrade prompt in module `4`. Pass `y` to upgrade without interaction. |
| `--only=ids` | Keeps only the listed modules from the selection (e.g. `go --only=0,4`). Applied after the positional selection. |
| `--skip=ids` | Removes the listed modules from the selection (e.g. `go --skip=5,13`). Applied after `--only`. |
| `--version` / `-V` | Prints the version and exits. Inside a git work tree it also shows the distance from the latest release tag. |

An unknown flag (a typo such as `--dryrun`) is rejected with an error and a non-zero exit status — it is never ignored, because silently continuing would run the tool in a mode you did not ask for. The same strictness applies to an unknown **module** token: `./brew_manager.sh 99` exits `2` without running anything, rather than a partial, unexpected selection.

> **Non-interactive runs:** pass the module selection as an argument and add `--yes` (from a script, cron, or a launchd job you set up yourself). Consent is explicit: without `--yes`, a run with no terminal attached is **fail-closed** — every confirmation prompt is automatically declined (the session banner says so), so it can inspect and report but never modify anything. The exit status reflects how the run ended (invalid selection → `2`, nothing to run → `1`, Homebrew unavailable → `69`, interrupted by a signal → the signal number), so launchd, scripts and CI can detect a failed start; a module that fails while running does not change it yet. `--version` answers before anything else, even next to an unknown flag; then an unknown flag is rejected, then a missing Homebrew, then the module selection. Piping input to drive the *interactive* prompt is not supported — the session recorder owns the script's standard input — so the command-line selection is the way to run unattended.

> **Ctrl+C:** if you interrupt a session, the log file is still saved. The ANSI stripping and cleanup step runs in the parent process, independently of how the child session ended.

---

## Modules

Every module has a number, and `go` runs them all.

### The modules — all run with `go`

These run in sequence (0 → 13; there is no `10`, retired in 2.0.0 — see [Upgrading from 1.x](#upgrading-from-1x)) when you type `go`. They are pure audit and maintenance operations with no persistent side effects beyond what you explicitly confirm.

---

#### `0` — Audit: unmanaged apps

Scans `/Applications` and `~/Applications` and compares every `.app` bundle against your installed Homebrew casks. Each app is classified into one of three categories:

- **Managed by brew** — already installed and tracked via `brew cask`, nothing to do
- **Adoptable** — the app exists on disk but brew doesn't track it; a matching cask exists and you can run `brew install --adopt` to bring it under brew's management
- **No cask found** — installed outside brew with no known cask; brew cannot manage it

Apple system apps (Safari, Mail, iMovie, Keynote, etc.) are detected dynamically by reading their bundle identifier via `mdfind`. There is no hardcoded list that would go stale with macOS updates.

Adoptable apps are listed with a number. Enter the numbers you want (`1,3`), `all`, or `n` for none. Before each adoption the exact target is echoed back (`Adopt Firefox.app → firefox now?`) and confirmed, because adopting the wrong app links a cask to a bundle it does not own. Under `--dry-run` the adoptions are only previewed; with `--yes` they are auto-confirmed, so use `--adopt=` to say exactly what an unattended run may adopt.

---

#### `1` — Health: system diagnostic

Runs a full diagnostic of your Homebrew installation and the underlying system:

- Homebrew version, prefix path, the date of Homebrew's own code, and the Ruby it uses
- Xcode Command Line Tools status (required for building formulae from source)
- Prefix write permissions (checks that brew can install to its directory)
- Free disk space on the volume containing the brew prefix
- Homebrew's **developer mode**. When it is on, `brew update` follows Homebrew's `main` branch instead of its stable releases. If a developer command left it on, the module offers to turn it off and update Homebrew back to its latest stable release (`brew developer off`, then `brew update`). It shows what it would run under `--dry-run` and runs it only after you confirm, or with `--yes`. If `HOMEBREW_DEVELOPER` is set in your environment, the module only reports it: your shell profile is yours to change.
- Active tap repositories (official JSON API + any extra taps you have added)
- `brew doctor` — Homebrew's own diagnostic that checks PATH, symlinks, permissions, and known problem patterns. Warnings from `brew doctor` are informational and rarely block normal usage.

---

#### `2` — Update: formula database

Runs `brew update` to fetch the latest package definitions from Homebrew's JSON API. This is **not** the same as upgrading packages — it only refreshes the list of what is available and what versions exist. Actual package upgrades happen in module `4`.

Since Homebrew 4.x, `brew update` fetches lightweight JSON files rather than cloning Git repositories, so this step completes in seconds.

Under `--dry-run` nothing is fetched: the module lists the repositories that would be refreshed and how long ago the local index was last updated.

---

#### `3` — Packages: installed packages report

Lists every package currently installed by Homebrew, split into two sections:

**Applications (Casks)** — GUI apps installed via `brew install --cask`. Each cask is tagged:
- `[A]` — the app has its own auto-updater (e.g. Docker, Firefox, VS Code). `brew upgrade` skips it by default to avoid conflicts with the app's built-in update mechanism. `brew upgrade --cask --greedy`, run by hand, upgrades these too.
- `[M]` — the app is fully managed by `brew upgrade`. No built-in updater.

**Formulae and libraries** — CLI tools and libraries. Descriptions are fetched live from `brew info --json=v2 --installed` in a single fast call — no per-package queries.

---

#### `4` — Updates: available updates

Shows every installed cask and formula that has a newer version available, with a version diff table. Before asking whether to upgrade, displays a `brew upgrade --dry-run` preview so you can see exactly what will change.

A cask tagged `[A]` (auto_updates) whose app has already updated itself is left out here: to sync it, run `brew upgrade --cask --greedy` by hand.

---

#### `5` — Cleanup: free disk space

Removes two categories of files that Homebrew accumulates over time:

- **Orphan dependencies** — formulae that were installed as dependencies of something you removed, but are no longer needed by any installed package. Removed via `brew autoremove`.
- **Old versions and download cache** — previous versions of upgraded packages and the downloaded archives used to install them. Removed via `brew cleanup -s`.

Nothing is removed until you confirm: interactively the module requires an explicit `y`, and `--dry-run` previews what `brew autoremove` and `brew cleanup -s` would delete (including the space that would be freed) without touching anything. In a `--yes` run this prompt is deliberately auto-confirmed — an explicit `--yes` is your consent to the cleanup; leave `5` out of the selection (or `--skip=5`) if you don't want that.

Cache size is measured before and after so you can see exactly how much space was freed.

---

#### `6` — Dependencies: shared dependency analysis

Analyzes the dependency graph of all installed formulae and shows the 10 packages that are depended upon by the most other installed packages. Useful before removing or changing a shared library — it tells you immediately how many things rely on it.

Bar lengths are normalized to the actual maximum count — the longest bar always represents the most-shared package, others are proportional.

---

#### `7` — Services: Homebrew background services

Lists all background services installed by Homebrew formulae (e.g. PostgreSQL, Redis, Nginx, MySQL) and their current status:

- `started` — service is running and will restart automatically at login
- `stopped` — service is installed but not currently running
- other — error state, check `brew services` for details

---

#### `8` — Untracked: binaries outside brew

Scans `/usr/local/bin` for executables that are **not** managed by Homebrew. These are binaries placed there by manual installations, SDK installers, or other package managers — they will not be updated by `brew upgrade`. Each untracked binary shows its symlink target so you can identify its origin.

---

#### `9` — Tracked: brew-managed binaries

Companion to module `8` — lists binaries in `/usr/local/bin` that **are** managed by Homebrew, either as formula symlinks pointing into the Cellar, or as binaries exposed by cask apps (e.g. `docker`, `kubectl`, `code`). Shows the symlink target and whether the source is a formula or a specific app.

---

#### `11` — Conflicts: duplicates and deprecated packages

Detects three categories of potential problems:

- **Version duplicates** — multiple versions of the same formula installed (e.g. `openjdk` and `openjdk@21`)
- **Keg-only formulae** — installed but intentionally not linked to avoid conflicts with macOS-bundled versions (e.g. `sqlite`, `readline`, `openssl`)
- **Deprecated or disabled casks** — casks flagged by Homebrew maintainers as unsafe or unmaintained; these should be replaced

---

#### `12` — Security: security audit

Runs security-focused checks that are fast and directly actionable:

- **`brew missing`** — finds broken dependencies: packages that reference other formulae that are no longer installed. Reports exactly which formula to reinstall to fix each issue.
- **Non-HTTPS homepages** — formulae whose upstream project URL uses plain HTTP instead of HTTPS
- **Pinned formulae** — packages frozen at a specific version via `brew pin`; they will not receive security updates until unpinned
- **Deprecated/disabled casks** — casks flagged as unsafe or abandoned by Homebrew

---

#### `13` — Disk: disk usage breakdown

Measures how much disk space each installed formula and cask occupies, sorted from largest to smallest. Useful when deciding what to uninstall or before running module `5` to understand where the space is going.

Shows three totals: Cellar (formulae), Caskroom (cask metadata), and download cache.

---

## Project structure

```
brew-manager/
│
├── brew_manager.sh           ← entry point: menu, flags, dispatch, summary
├── VERSION                   ← the version — single source of truth
│
├── lib/
│   ├── common.sh             ← colors, symbols, TUI utilities, _ask, _read_choice
│   ├── log.sh                ← session log menu and support footer
│   └── selection.sh          ← module registry and selection resolver
│
├── modules/
│   ├── mod_00_audit.sh       ← [0]   unmanaged app audit
│   ├── mod_01_health.sh      ← [1]   system health + brew doctor
│   ├── mod_02_update.sh      ← [2]   formula database update
│   ├── mod_03_packages.sh    ← [3]   installed packages report
│   ├── mod_04_updates.sh     ← [4]   available updates + upgrade
│   ├── mod_05_cleanup.sh     ← [5]   cache and orphan cleanup
│   ├── mod_06_deps.sh        ← [6]   shared dependency analysis
│   ├── mod_07_services.sh    ← [7]   homebrew services
│   ├── mod_08_untracked.sh   ← [8]   untracked binaries in /usr/local/bin
│   ├── mod_09_tracked.sh     ← [9]   brew-tracked binaries in /usr/local/bin
│   ├── mod_11_conflicts.sh   ← [11]  duplicates and conflicts
│   ├── mod_12_security.sh    ← [12]  security audit
│   └── mod_13_disk.sh        ← [13]  disk usage breakdown
│
├── logs/                     ← auto-created at first run, git-ignored
│   └── brew_report_*.log     ← one per run
│
├── .gitignore                ← excludes logs/ (and backups/, agents/, left by 1.x)
├── CHANGELOG.md              ← what changed in each release
├── LICENSE                   ← MIT
├── README.md
└── SECURITY.md               ← security policy: what the tool does to your
                                 system, and how to report a vulnerability
```

> `logs/` is created automatically and is excluded from git: it holds session data and local paths that should not be committed. So are `backups/` and `agents/`, which 1.x created and 2.0.0 no longer uses (see [Upgrading from 1.x](#upgrading-from-1x)).

The repository also carries the development tooling used to maintain the project (`CLAUDE.md`, `.claude/`, `Makefile`, `scripts/`, and the test suites in `tests/`). None of it is needed to *run* brew-manager — the script only requires itself, `VERSION`, `lib/` and `modules/`.

---

## Session logging

Every run of `brew_manager.sh` is fully captured to a timestamped log file in `logs/` using macOS `script(1)`. The log captures the complete terminal output of the session. ANSI escape codes and carriage returns are stripped automatically after the session ends, leaving clean plain text ready for archiving or sharing.

The log file is always saved — even if you interrupt the session with **Ctrl+C**. The ANSI stripping step runs in the parent process, independently of how the child session ended.

At the end of each interactive session you are presented with three choices:

- **Keep** — the log stays in `logs/` exactly as captured
- **Open** — the log is opened in your default editor for review (file is saved regardless)
- **Delete** — the log file is removed

The logs are plain text files in `logs/`, one per run, and brew-manager never prunes them on its own. Browse them with `ls -lt logs/` and any editor or pager. To prune old ones, list them first, then delete them by hand — for example, from the brew-manager folder, the logs older than 90 days:

```bash
find logs -name 'brew_report_*.log' -mtime +90 -print
find logs -name 'brew_report_*.log' -mtime +90 -delete
```

---

## Terminal rendering

brew-manager adapts its output to what your terminal can actually display, and degrades cleanly when it can't — no garbled escape codes, no unreadable glyphs.

- **Color depth is detected automatically.** A truecolor terminal (`COLORTERM=truecolor`) gets the full 24-bit palette; a 256-color terminal gets 256-color hues; anything poorer falls back to the classic 16 colors. The palette is *semantic* — one tint per state (green = safe/read-only, yellow = writes metadata, red = destructive) — so the meaning of an action is legible at a glance rather than decorative.
- **`NO_COLOR` is honored.** Set `NO_COLOR=1` (see [no-color.org](https://no-color.org)) and the output is plain text with no ANSI sequences at all.
- **Piped or non-interactive output is clean at the source.** When standard output is not a terminal — a pipe, a redirect, a job started by launchd — no color or cursor-control sequences are emitted in the first place, and the progress spinner is replaced by one static line per operation. This complements the ANSI stripping of the saved log: a piped report is clean text you can `grep` or archive directly.
- **Non-UTF-8 locales fall back to ASCII.** In a UTF-8 locale the interface uses rounded boxes and Unicode symbols (`✓ ⚠ ✗ → ─`); otherwise it uses ASCII equivalents (`+ ! x -> -`), so it stays readable in a `LANG=C` environment.

All of this is driven from `lib/common.sh`, so every module inherits it — there is nothing to configure.

---

## Adding a new module

brew-manager's dispatch system is designed to make adding modules trivial. Every module is numbered and runs in `go`:

1. Create `modules/mod_NN_name.sh` (`NN` is the next free number, two digits) containing a function named `_module_N()` (the number without the leading zero). Never reuse a retired id: `10`, `bk`, `las`, `log` and `mas` stay reserved for good, because scripts and agents written for 1.x may still pass them.
2. Register it in `lib/selection.sh` — four entries, one per registry: `MODULE_DESC` (one-line description, plain ASCII, max 46 chars), `MODULE_NAME` (short menu name, plain ASCII, max 17 chars), `MODULE_RISK` (`ro`, `write` or `danger` — drives the risk badge) and `MODULE_DRYRUN` (`1` only if a `--dry-run` run of the module changes nothing; a `0` must also be listed, with its reason, in `_KNOWN_UNGATED` of `tests/test_run_summary.zsh`).
3. Add the number to the `MODULE_IDS` array: it is the `go` sequence, and the menu draws its rows from it.
4. Update the two deliberate pins of `tests/test_menu_registry.zsh` — the frozen id set and the `MODULE_IDS` count — since the module ids are part of the public contract.

The source glob, the menu rows and the range in the menu's header, the dispatch, the "Valid modules" error and the summary then pick the module up from the registries. `make test` fails if a registry entry is missing or over its column cap, if a registered id has no module file or no `_module_N()` function, or if a module file is not registered (`tests/test_menu_registry.zsh`, `tests/test_risk_badges.zsh`, `tests/test_run_summary.zsh`).

> The selection is parsed by `_resolve_selection` (`lib/selection.sh`) from **either** a command-line spec **or** what the user types at the `Choice` prompt — the same code path backs both. `--only` / `--skip` then filter the result.

**Anything a module does to the system must honour the two safety flags:** `BREW_MANAGER_DRY_RUN` (preview only, never execute) and `BREW_MANAGER_YES` (unattended: take the default answer, and let the default be the safe one). Use `_ask` / `_read_choice` from `lib/common.sh` for every prompt rather than reading input directly — they implement both flags for you.

---

## Contributing

This project is open to contributions of any kind. If you find a bug, want to propose a new module, improve the documentation, or refactor something:

1. **Fork** the repository on GitHub
2. **Create a branch** for your change: `git checkout -b fix/something` or `git checkout -b feat/new-module`
3. **Make your changes** — keep one module per file, comment non-obvious decisions
4. **Open a pull request** with a clear description of what changed and why

There is no minimum size for contributions. A one-line fix, a documentation improvement, or a module idea filed as an issue are all equally welcome.

---

## License

This project is released under the MIT License — see [LICENSE](LICENSE) for the full text.

In plain language: use it freely, modify it, include it in your own projects. The only requirement is that the license text stays attached. No fees, no attribution required (though appreciated).

---

<div align="center">

*brew-manager is a macOS-only tool.*
*It relies on macOS-specific features — Caskroom, bundle identifiers, mdfind, script(1) — that do not exist on Linux.*

</div>
