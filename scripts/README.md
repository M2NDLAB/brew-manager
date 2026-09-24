# scripts/ — process scripts

Only **working-method** scripts, stack-agnostic. The project's build/run scripts
(compilation, tests, startup) do NOT live here: each project adds its own.

| Script | What it does |
|---|---|
| `hooks-install.sh` | Installs the local git hooks: secret scanning (gitleaks, pre-commit) and Conventional Commits (commitlint, commit-msg), always active. Automatic code formatting is included as a **commented-out example** to adapt to the project's language. Idempotent on its own hooks (if you have customised them, a re-run saves a `.bak` first); faced with pre-existing hooks of ANOTHER origin — including the symlinks of hook managers — it stops (override: `FORCE_OVERWRITE=1`, with a `.bak` backup), and it also stops if `core.hooksPath` is active (e.g. husky: `.git/hooks` would be ignored and the hooks would be inert). |
| `reset-task.sh` | SURGICAL cleanup of an interrupted task: it discards ONLY the uncommitted work and preserves the branch and the previous commits. It is the cleanup of the task planning protocol (`.claude/docs/01-task-planning.md`). It refuses to operate on shared branches. |
| `test-hooks-install.sh` | Hermetic self-test of `hooks-install.sh` (stubs for `gitleaks`/`npx` + a throwaway git repo): it runs the REAL script end-to-end and demonstrates the contract of the `FORCE_OVERWRITE=1` branch on the dangling-symlink case, without touching the real repo. Launch it with `make test-scripts`. |

## Typical use

```bash
make hooks-install      # or: bash scripts/hooks-install.sh
make test-scripts       # self-test of the scripts (hermetic: does not touch the real repo)
./scripts/reset-task.sh # after an interruption, before resuming a plan
```

Prerequisites of `hooks-install.sh`: `gitleaks` and `npx` (Node.js) installed.
