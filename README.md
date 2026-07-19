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

If you use Homebrew regularly, you know the feeling: your Mac accumulates apps installed manually that could be managed by brew, packages that haven't been updated in months because they self-update and `brew upgrade` silently skips them, orphan libraries taking up gigabytes of disk space, binaries in `/usr/local/bin` placed there by some installer you don't remember, and no clean way to reproduce your exact setup if you get a new machine.

The standard Homebrew CLI is excellent for installing and updating software — but it doesn't give you a clear picture of the state of your system. You have to run a dozen commands and mentally connect the output.

**brew-manager** was built to fill that gap.

It is a single shell script that runs entirely in your terminal, requires nothing beyond what macOS already has installed, captures every session to a log file, and can run fully automatically via macOS LaunchAgents. Every module starts with a plain-language explanation of what it does and why — so you always know what you are running before it runs.

It is **not** a replacement for Homebrew. It is a maintenance and audit layer on top of it.

---

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| macOS | 12 Monterey or later | Apple Silicon (M-series) and Intel both supported |
| zsh | 5.8 or later | Default shell on macOS since Catalina (2019) |
| Homebrew | 4.x or later | Uses JSON API — no local core/cask clone needed |
| Python 3 | any | Pre-installed on macOS — used for fast JSON parsing in module 3 |

**Optional:**
- `mas` — required for module `mas` (Mac App Store integration). If not installed, the module will offer to install it for you. Install manually with `brew install mas`.

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

## Usage

### Interactive TUI

```bash
./brew_manager.sh
```

Launches a full-screen terminal interface showing all available modules. Type `go` to run the complete audit sequence, or enter specific module numbers or names to run only what you need.

At the top of each module you will see an **About this module** section explaining in plain language what the module does, what it checks, and what actions it can take — before anything runs.

### Choosing what to run

You can choose the modules **on the command line** or **interactively** — whichever fits.

**On the command line** — pass the selection as a positional argument. The run is then non-interactive and skips the menu:

```bash
./brew_manager.sh go            # all standard modules, 0 to 13
./brew_manager.sh 1,4,5         # only these, in this order
./brew_manager.sh 5,2,0         # any order, duplicates allowed
./brew_manager.sh log           # a named module: log, bk, las, mas
```

Refine a selection with `--only` (keep only these) or `--skip` (remove these):

```bash
./brew_manager.sh go --skip=5,10    # every module except 5 and 10
./brew_manager.sh go --only=0,4     # only 0 and 4 out of the full sequence
```

An unknown module token is **rejected with an error and a non-zero exit** — nothing runs, never silently skipped — so a typo can't run a different set of modules than you intended. (Inside the interactive prompt an unknown token is instead warned about and skipped.)

**Interactively** — start the script with no selection and type your choice at the `Choice` prompt:

```
→  Choice [go / comma-separated numbers, default: go]: go       # all standard modules, 0 to 13
→  Choice [go / comma-separated numbers, default: go]: 1,4,5    # only these, in this order
→  Choice [go / comma-separated numbers, default: go]: log      # a named module: log, bk, las, mas
```

Flags change **how** the run behaves and combine with either form:

```bash
# Read-only inspection of the full sequence — nothing on your system is modified
./brew_manager.sh go --dry-run

# Unattended full run: every question is auto-answered with its built-in safe default
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
| `--yes` / `-y` | Skips all interactive prompts and uses each prompt's built-in default. Almost all action defaults are conservative: adoption and upgrades happen only if you opt in with `--adopt=` / `--upgrade=`, and force-upgrades (module `10`), Mac App Store updates and restores stay off. The one deliberate exception is module `5`, whose cleanup prompt defaults to *yes* so a scheduled maintenance run can actually free disk space — add `--skip=5` (or `--dry-run`) if you don't want that. |
| `--dry-run` | Read-only mode: previews what would happen and executes nothing. Overrides `--yes` — a dry run never modifies anything, even when combined with it. |
| `--adopt=n\|all\|1,2` | Pre-answers the adoption prompt in module `0`. In an unattended run (`--yes`) this is the only way to have apps adopted. |
| `--upgrade=y\|n` | Pre-answers the upgrade prompt in module `4`. Pass `y` to upgrade without interaction. |
| `--only=ids` | Keeps only the listed modules from the selection (e.g. `go --only=0,4`). Applied after the positional selection. |
| `--skip=ids` | Removes the listed modules from the selection (e.g. `go --skip=5,10`). Applied after `--only`. |
| `--version` / `-V` | Prints the version and exits. Inside a git work tree it also shows the distance from the latest release tag. |

An unknown flag (a typo such as `--dryrun`) is rejected with an error and a non-zero exit status — it is never ignored, because silently continuing would run the tool in a mode you did not ask for. The same strictness applies to an unknown **module** token: `./brew_manager.sh 99` exits `2` without running anything, rather than a partial, unexpected selection.

> **Non-interactive runs:** pass the module selection as an argument and add `--yes` (this is what the LaunchAgents installed by the `las` module do). Consent is explicit: without `--yes`, a run with no terminal attached is **fail-closed** — every confirmation prompt is automatically declined (the session banner says so), so it can inspect and report but never modify anything. The exit status reflects how the run ended (invalid selection → `2`, nothing to run → `1`, interrupted by a signal → the signal number), so launchd, scripts and CI can detect a failed start. Piping input to drive the *interactive* prompt is not supported — the session recorder owns the script's standard input — so the command-line selection is the way to run unattended.

> **Ctrl+C:** if you interrupt a session, the log file is still saved. The ANSI stripping and cleanup step runs in the parent process, independently of how the child session ended.

---

## Modules

brew-manager has two categories of modules:

### Standard modules — run with `go`

These run in sequence (0 → 13) when you type `go`. They are pure audit and maintenance operations with no persistent side effects beyond what you explicitly confirm.

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

- Homebrew version, prefix path, and last database update time
- Xcode Command Line Tools status (required for building formulae from source)
- Prefix write permissions (checks that brew can install to its directory)
- Free disk space on the volume containing the brew prefix
- Active tap repositories (official JSON API + any extra taps you have added)
- `brew doctor` — Homebrew's own diagnostic that checks PATH, symlinks, permissions, and known problem patterns. Warnings from `brew doctor` are informational and rarely block normal usage.

---

#### `2` — Update: formula database

Runs `brew update` to fetch the latest package definitions from Homebrew's JSON API. This is **not** the same as upgrading packages — it only refreshes the list of what is available and what versions exist. Actual package upgrades happen in module `4`.

Since Homebrew 4.x, `brew update` fetches lightweight JSON files rather than cloning Git repositories, so this step completes in seconds.

---

#### `3` — Packages: installed packages report

Lists every package currently installed by Homebrew, split into two sections:

**Applications (Casks)** — GUI apps installed via `brew install --cask`. Each cask is tagged:
- `[A]` — the app has its own auto-updater (e.g. Docker, Firefox, VS Code). `brew upgrade` skips it by default to avoid conflicts with the app's built-in update mechanism. Module `10` handles these.
- `[M]` — the app is fully managed by `brew upgrade`. No built-in updater.

**Formulae and libraries** — CLI tools and libraries. Descriptions are fetched live from `brew info --json=v2 --installed` in a single fast call — no per-package queries.

---

#### `4` — Updates: available updates

Shows every installed cask and formula that has a newer version available, with a version diff table. Before asking whether to upgrade, displays a `brew upgrade --dry-run` preview so you can see exactly what will change.

Casks tagged `[A]` (auto_updates) are listed but not upgraded here — use module `10` for those.

---

#### `5` — Cleanup: free disk space

Removes two categories of files that Homebrew accumulates over time:

- **Orphan dependencies** — formulae that were installed as dependencies of something you removed, but are no longer needed by any installed package. Removed via `brew autoremove`.
- **Old versions and download cache** — previous versions of upgraded packages and the downloaded archives used to install them. Removed via `brew cleanup -s`.

Nothing is removed until you confirm: interactively the module requires an explicit `y`, and `--dry-run` previews what `brew autoremove` and `brew cleanup -s` would delete (including the space that would be freed) without touching anything. In an unattended `--yes` run this prompt is deliberately auto-confirmed — freeing space is what a scheduled maintenance run is for; leave `5` out of the selection (or `--skip=5`) if you don't want that.

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

#### `10` — Greedy: auto-update cask check

Homebrew marks certain casks as `auto_updates: true` because they have a built-in update mechanism. `brew upgrade` intentionally skips these to avoid version conflicts. This module finds them, checks which are actually outdated, and offers to force an update.

**Only the casks listed in the confirmation are upgraded** — no formulae and no other casks. Each one is upgraded on its own, its exit status is reported, and a cask that turns out not to have changed version (these apps update themselves, so one may have done so while you were reading the prompt) is reported as *no change* rather than as upgraded. Use module `4` for formulae and regular casks. Under `--dry-run` you get a preview and nothing is upgraded.

Common examples: Docker, Firefox, Discord, VS Code, Telegram, Chrome.

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

### Special modules — call by name

These are excluded from `go` because they are interactive configuration and management tools, not audits. Call them directly by name.

---

#### `log` — Session log manager

```bash
./brew_manager.sh          # then type `log` at the Choice prompt
```

Manages all log files in the `logs/` directory. Logs are color-coded by type in the file list:

| Type | Color | Description |
|------|-------|-------------|
| `brew_report_*` | Cyan | Full session logs — one per run of brew_manager.sh |
| `agent_stdout_*` | Green | Output from scheduled LaunchAgent runs |
| `agent_stderr_*` | Yellow | Errors from scheduled LaunchAgent runs |

Options: **View** (print log contents), **Delete** (by number, list, or `all`), **Purge old** (delete logs older than N days).

---

#### `bk` — Brewfile and agents backup/restore

```bash
./brew_manager.sh          # then type `bk` at the Choice prompt
```

Creates and manages portable snapshots of your entire setup — both Homebrew packages and LaunchAgent schedules. Each operation can be run independently or on the full set:

| Option | What it does |
|--------|--------------|
| `1` — Backup all | Generates Brewfile + agents bundle in `backups/` |
| `1b` — Backup Brewfile | Homebrew packages only |
| `1a` — Backup agents | LaunchAgent schedules only |
| `2` — Preview all | Shows what would be saved without writing anything |
| `2b` — Preview brew | Lists packages that would go into the Brewfile |
| `2a` — Preview agents | Lists configured LaunchAgent schedules |
| `3` — Restore all | Installs all Brewfile packages + reloads all agents (asks first) |
| `3b` — Restore brew | Restores Homebrew packages only (asks first) |
| `3a` — Restore agents | Recreates and reloads LaunchAgents from bundle (asks first) |
| `4` — Check | Verifies all Brewfile dependencies are currently satisfied |
| `5` — View | Shows saved Brewfile contents with color-coded categories + agents bundle |
| `6` — Delete | Removes Brewfile, lock file, and/or agents bundle (selectable) |

All three restore options ask for confirmation before writing anything, so in an unattended run (`--yes`) they do nothing: a restore is a deliberate act. Under `--dry-run` they show exactly what would be installed and which agents would be loaded, without executing. When agents are restored, each stored module selection is validated first: an entry that no longer resolves to real modules is skipped with a warning — never silently replaced with the full sequence.

**To move your setup to a new Mac:**

```bash
# On the old Mac — backup everything
./brew_manager.sh bk   # option 1

# Copy the backups/ folder to your new Mac
cp -r backups/ /path/to/new/mac/brew-manager/backups/

# On the new Mac — restore everything
./brew_manager.sh bk   # option 3
```

---

#### `las` — LaunchAgent scheduler

```bash
./brew_manager.sh          # then type `las` at the Choice prompt
```

Installs, modifies, and removes macOS LaunchAgents that run brew-manager automatically on a schedule. Uses macOS `launchd` natively — no cron, no sudo, no third-party tools. Runs as your user account and starts automatically at login.

All scheduled runs pass `--yes` automatically so they complete without interaction. Output goes to `logs/agent_stdout_*.log`, errors to `logs/agent_stderr_*.log`.

> **What a scheduled agent actually runs:** exactly the module selection you configured — the agent's plist invokes `brew_manager.sh <your modules> --yes`, so an agent installed for `8,9` runs modules 8 and 9 and nothing else. The selection is validated whenever an agent is written (install, modify, re-register): a value that does not resolve to real modules is refused — and skipped on restore from a backup — never silently replaced with the full sequence. Scheduled runs are unattended, so each prompt is auto-answered with its built-in default: conservative everywhere except module `5`'s cleanup (see *Available flags*) — schedule `5` only if you want the agent to actually free disk space.

| Option | What it does |
|--------|--------------|
| `1` | Install weekly agent — every Sunday at 09:00 |
| `2` | Install daily agent — every day at 09:00 |
| `3` | Custom agent — choose name, day, hour and minute |
| `4` | Modify agent — change the schedule without reinstalling |
| `5` | Remove agent — unloads from macOS and deletes plist + conf |
| `6` | **Integrity check** — see below |
| `v` | View activity log — color-coded history of installs/modifications/removals |
| `c` | Clear logs — only available when no agents are installed |

**Option 6 — Integrity check:**

If you delete a `.plist` or `.conf` file manually instead of using option `5`, the system can get out of sync. The integrity check finds three types of problems:

- **Orphan plists** — agents active in `~/Library/LaunchAgents/` with the brew-manager label prefix but no corresponding `.conf` in `agents/`. brew-manager has no record of them but they are still running.
- **Dangling confs** — `.conf` files in `agents/` that reference plists that no longer exist in `~/Library/LaunchAgents/`. brew-manager thinks they exist but macOS does not.
- **Legacy or corrupted agents** — a tracked agent whose stored data no longer matches the schedule macOS actually uses, or whose module list was mangled by an older version. Such an agent can fail on every scheduled run.

For the first two you can **re-register** (create the missing file and bring everything back in sync) or **remove** (clean up completely). For the third, the **repair** option regenerates both files from the schedule launchd really uses. Agents that fire on several weekdays are left untouched by these repairs — rewriting them as a single day would silently change when they run.

> Always use option `[5]` to remove agents. If you delete files manually, run the integrity check with option `[6]` to restore consistency.

---

#### `mas` — Mac App Store integration

```bash
./brew_manager.sh          # then type `mas` at the Choice prompt
```

Manages apps installed from the Mac App Store using [`mas`](https://github.com/mas-cli/mas), an open-source CLI tool. If `mas` is not installed, this module will offer to install it via `brew install mas`.

Shows all installed App Store apps with their App ID, name, and version. Checks for available updates and offers to run `mas upgrade` to update them all. Requires that you are signed into the App Store with your Apple ID.

Note: `mas` is completely separate from Homebrew — it only communicates with the Mac App Store and does not interact with brew at all.

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
│   └── log.sh                ← session log menu and support footer
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
│   ├── mod_10_greedy.sh      ← [10]  auto-update casks (greedy check)
│   ├── mod_11_conflicts.sh   ← [11]  duplicates and conflicts
│   ├── mod_12_security.sh    ← [12]  security audit
│   ├── mod_13_disk.sh        ← [13]  disk usage breakdown
│   ├── mod_bk_brewfile.sh    ← [bk]  Brewfile + agents backup/restore
│   ├── mod_las_scheduler.sh  ← [las] LaunchAgent scheduler
│   ├── mod_mas_mas.sh        ← [mas] Mac App Store integration
│   └── mod_log_manager.sh    ← [log] session log manager
│
├── logs/                     ← auto-created at first run, git-ignored
│   ├── brew_report_*.log     ← one per interactive session
│   ├── agent_stdout_*.log    ← stdout from each scheduled LaunchAgent run
│   └── agent_stderr_*.log    ← stderr from each scheduled LaunchAgent run
│
├── backups/                  ← auto-created by module bk, git-ignored
│   ├── Brewfile              ← declarative snapshot of all installed packages
│   ├── Brewfile.lock.json    ← Homebrew lock file for reproducible restores
│   └── agents_bundle.conf    ← snapshot of all LaunchAgent configurations
│
├── agents/                   ← auto-created by module las, git-ignored
│   ├── agent_*.conf          ← one configuration file per installed agent
│   └── agents_activity.log   ← timestamped install/modify/remove history
│
├── .gitignore                ← excludes logs/, backups/, agents/
├── CHANGELOG.md              ← what changed in each release
├── LICENSE                   ← MIT
├── README.md
└── SECURITY.md               ← security policy: what the tool does to your
                                 system, and how to report a vulnerability
```

> `logs/`, `backups/`, and `agents/` are created automatically and are excluded from git. They contain session data and local paths that should not be committed.

The repository also carries the development tooling used to maintain the project (`CLAUDE.md`, `.claude/`, `Makefile`, `scripts/`). None of it is needed to *run* brew-manager — the script only requires itself, `VERSION`, `lib/` and `modules/`.

---

## Session logging

Every run of `brew_manager.sh` is fully captured to a timestamped log file in `logs/` using macOS `script(1)`. The log captures the complete terminal output of the session. ANSI escape codes and carriage returns are stripped automatically after the session ends, leaving clean plain text ready for archiving or sharing.

The log file is always saved — even if you interrupt the session with **Ctrl+C**. The ANSI stripping step runs in the parent process, independently of how the child session ended.

At the end of each interactive session you are presented with three choices:

- **Keep** — the log stays in `logs/` exactly as captured
- **Open** — the log is opened in your default editor for review (file is saved regardless)
- **Delete** — the log file is removed

To manage all session logs at once:
```bash
./brew_manager.sh          # then type `log` at the Choice prompt
```

---

## Terminal rendering

brew-manager adapts its output to what your terminal can actually display, and degrades cleanly when it can't — no garbled escape codes, no unreadable glyphs.

- **Color depth is detected automatically.** A truecolor terminal (`COLORTERM=truecolor`) gets the full 24-bit palette; a 256-color terminal gets 256-color hues; anything poorer falls back to the classic 16 colors. The palette is *semantic* — one tint per state (green = safe/read-only, yellow = writes metadata, red = destructive) — so the meaning of an action is legible at a glance rather than decorative.
- **`NO_COLOR` is honored.** Set `NO_COLOR=1` (see [no-color.org](https://no-color.org)) and the output is plain text with no ANSI sequences at all.
- **Piped or non-interactive output is clean at the source.** When standard output is not a terminal — a pipe, a redirect, a scheduled LaunchAgent — no color or cursor-control sequences are emitted in the first place. This complements the ANSI stripping of the saved log: a piped report is clean text you can `grep` or archive directly.
- **Non-UTF-8 locales fall back to ASCII.** In a UTF-8 locale the interface uses rounded boxes and Unicode symbols (`✓ ⚠ ✗ → ─`); otherwise it uses ASCII equivalents (`+ ! x -> -`), so it stays readable in a `LANG=C` environment.

All of this is driven from `lib/common.sh`, so every module inherits it — there is nothing to configure.

---

## Adding a new module

brew-manager's dispatch system is designed to make adding modules trivial.

**Numbered module (included in `go`):**

1. Create `modules/mod_NN_name.sh` containing a function named `_module_NN()`
2. Add an entry to `MODULE_DESC` in `lib/selection.sh`: `[NN]="Description of module"`
3. Add `NN` to the `MODULE_IDS` array
4. Done — the source glob, dispatch loop, and summary pick it up automatically

**Named module (excluded from `go`, selected by name at the prompt):**

1. Create `modules/mod_KEYNAME_*.sh` with a function (any number is fine internally)
2. Add the key to `MODULE_DESC` in `lib/selection.sh`: `[keyname]="Description"`
3. In `lib/selection.sh`, teach the resolver the new key: add a whole-token `case` arm to `_resolve_selection` (`keyname|KEYNAME) MODULES_TO_RUN=("keyname") ;;`) and include `keyname` in the lowercase-special checks so it is also accepted inside comma lists and `--only`/`--skip`
4. Add a `case` entry in the dispatch loop in `brew_manager.sh`: `keyname) _module_function ;;`
5. Add a display line in the menu below the `·` separator

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
*It relies on macOS-specific features — Caskroom, LaunchAgents, bundle identifiers, mdfind, script(1) — that do not exist on Linux.*

</div>
